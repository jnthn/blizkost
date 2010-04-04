/*
Copyright (C) 2009-2010, Jonathan Worthington and friends
$Id$

=head1 NAME

src/pmc/p5marshal.c - wrap P5 and Parrot calling conventions

=head1 DESCRIPTION

=cut

*/

/* Need to know about the interpreter and scalar wrapper. */
#define PARROT_IN_EXTENSION
#define CONST_STRING(i, s) Parrot_str_new_constant((i), s)
#define CONST_STRING_GEN(i, s) Parrot_str_new_constant((i), s)
#include "parrot/parrot.h"
#include "parrot/extend.h"
#include "parrot/dynext.h"

#include "blizkost.h"

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
static CV *blizkost_wrap_callable(PARROT_INTERP, PMC *p5i, PMC *callable);

/*

=item C<SV *blizkost_marshal_arg(PARROT_INTERP, PerlInterpreter *my_perl, PMC *arg)>

Takes a PMC and marshals it into an SV that we can pass to Perl 5.

=cut

*/

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
SV *
blizkost_marshal_arg(PARROT_INTERP, PMC *p5i, PMC *arg) {
    struct sv *result = NULL;
    PerlInterpreter *my_perl;

    GETATTR_P5Interpreter_my_perl(interp, p5i, my_perl);

    /* If it's a P5Scalar PMC, then we just fetch the SV from it - trivial
     * round-tripping. */
    if (VTABLE_isa(interp, arg, CONST_STRING(interp, "P5Scalar"))) {
        GETATTR_P5Scalar_sv(interp, arg, result);
    }

    /* XXX At this point, we should probably wrap it up in a tied Perl 5
     * scalar so we can round-trip Parrot objects to. However, that's hard,
     * so for now we cheat on a few special cases and just panic otherwise. */
    else if (VTABLE_isa(interp, arg, CONST_STRING(interp, "Integer"))) {
        result = sv_2mortal(newSViv(VTABLE_get_integer(interp, arg)));
    }
    else if (VTABLE_isa(interp, arg, CONST_STRING(interp, "Float"))) {
        result = sv_2mortal(newSVnv(VTABLE_get_number(interp, arg)));
    }
    else if (VTABLE_isa(interp, arg, CONST_STRING(interp, "P5Namespace"))) {
        STRING *pkg;
        char *c_str;
        GETATTR_P5Namespace_ns_name(interp, arg, pkg);
        c_str = Parrot_str_to_cstring(interp, pkg);
        result = sv_2mortal(newSVpv(c_str, strlen(c_str)));
    }
    else if (VTABLE_isa(interp, arg, CONST_STRING(interp, "String"))) {
        char *c_str = Parrot_str_to_cstring(interp, VTABLE_get_string(interp, arg));
        result = sv_2mortal(newSVpv(c_str, strlen(c_str)));
    }
    else if (VTABLE_isa(interp, arg, CONST_STRING(interp, "Sub"))) {
        CV *wrapper = blizkost_wrap_callable(interp, p5i, arg);
        result = sv_2mortal(newRV_inc((SV*)wrapper));
    }
    else if ( VTABLE_does(interp, arg, CONST_STRING(interp, "array"))) {
        PMC *iter;
        struct av *array = newAV();
        iter = VTABLE_get_iter(interp, arg);
        while (VTABLE_get_bool(interp, iter)) {
             PMC *item = VTABLE_shift_pmc(interp, iter);
             struct sv *marshaled =
                blizkost_marshal_arg(interp, p5i, item);
             av_push( array, marshaled);
        }
        result = newRV_inc((SV*)array);

    }
    else if ( VTABLE_does(interp, arg, CONST_STRING(interp, "hash"))) {
        PMC *iter = VTABLE_get_iter(interp, arg);
        struct hv *hash = newHV();
        INTVAL n = VTABLE_elements(interp, arg);
        INTVAL i;
        for(i = 0; i < n; i++) {
            STRING *s = VTABLE_shift_string(interp, iter);
            char *c_str = Parrot_str_to_cstring(interp, s);
            struct sv *val = blizkost_marshal_arg(interp, p5i,
                    VTABLE_get_pmc_keyed_str(interp, arg, s));
            hv_store(hash, c_str, strlen(c_str), val, 0);
        }
        result = newRV_inc((SV*)hash);
    }
    else {
        Parrot_ex_throw_from_c_args(interp, NULL, 1,
                "Sorry, we do not support marshaling most things to Perl 5 yet.");
    }

    return result;
}

/*

=item C<PMC *blizkost_wrap_sv(PARROT_INTERP, PMC *p5i, SV *sv)>

Encapsulates a SV so that it can be returned to Parrot.  Will increment
the SV's reference count.

*/

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
PMC *
blizkost_wrap_sv(PARROT_INTERP, PMC *p5i, SV *sv) {
    PMC *pmc = Parrot_pmc_new_noinit(interp, pmc_type(interp,
                string_from_literal(interp, "P5Scalar")));
    PMC_data(pmc) = mem_allocate_zeroed_typed(Parrot_P5Scalar_attributes);
    PObj_custom_mark_SET(pmc);
    PObj_custom_destroy_SET(pmc);

    SETATTR_P5Scalar_p5i(interp, pmc, p5i);
    SETATTR_P5Scalar_sv(interp, pmc, SvREFCNT_inc(sv));
    return pmc;
}

/*

=item C<opcode_t *blizkost_return_from_invoke(PARROT_INTERP, void *next)>

Handles returning from a PCC function; this is less trivial than it could be
because of some tail call considerations.

*/

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
opcode_t *
blizkost_return_from_invoke(PARROT_INTERP, void *next) {
    /* The following code is cargo culted from nci.pmc */
    PMC *cont = interp->current_cont;

    /*
     * If the NCI function was tailcalled, the return result
     * is already passed back to the caller of this frame
     * - see  Parrot_init_ret_nci(). We therefore invoke the
     * return continuation here, which gets rid of this frame
     * and returns the real return address
     */
    if (cont && cont != NEED_CONTINUATION
            && (PObj_get_FLAGS(cont) & SUB_FLAG_TAILCALL)) {
        cont = Parrot_pcc_get_continuation(interp, CURRENT_CONTEXT(interp));
        next = VTABLE_invoke(interp, cont, next);
    }

    return (opcode_t *)next;
}

int
blizkost_slurpy_to_stack(PARROT_INTERP, PMC *p5i, PerlInterpreter *my_perl,
        PMC *positional, PMC *named) {
    int num_pos, i, stkdepth;
    PMC *iter;
    dSP;

    stkdepth = 0;

    /* Stick on positional arguments. */
    num_pos = VTABLE_elements(interp, positional);
    for (i = 0; i < num_pos; i++) {
        PMC *pos_arg = VTABLE_get_pmc_keyed_int(interp, positional, i);
        XPUSHs(blizkost_marshal_arg(interp, p5i, pos_arg));
        stkdepth++;
    }

    /* Stick on named arguments (we unbundle them to a string
     * followed by the argument. */
    iter = VTABLE_get_iter(interp, named);
    while (VTABLE_get_bool(interp, iter)) {
        STRING *arg_name   = VTABLE_shift_string(interp, iter);
        PMC    *arg_value  = VTABLE_get_pmc_keyed_str(interp, named, arg_name);
        char   *c_arg_name = Parrot_str_to_cstring(interp, arg_name);
        XPUSHs(sv_2mortal(newSVpv(c_arg_name, strlen(c_arg_name))));
        XPUSHs(blizkost_marshal_arg(interp, p5i, arg_value));
        stkdepth += 2;
    }
    PUTBACK;
    return stkdepth;
}

void
blizkost_call_in(PARROT_INTERP, PMC *p5i, SV *what, U32 mode, PMC *positp,
        PMC *namedp, PMC **retp) {
    PerlInterpreter *my_perl;
    int num_returns, i;

    GETATTR_P5Interpreter_my_perl(interp, p5i, my_perl);

    {
        /* Set up the stack. */
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

        PUTBACK;
        blizkost_slurpy_to_stack(interp, p5i, my_perl, positp, namedp);

        /* Invoke the methods. */
        num_returns = call_sv(what, mode);
        SPAGAIN;

        /* Build the results PMC array. */
        *retp = pmc_new(interp, enum_class_ResizablePMCArray);
        for (i = 0; i < num_returns; i++) {
            SV *result_sv = POPs;
            PMC *result_pmc = blizkost_wrap_sv(interp, p5i, result_sv);
            VTABLE_unshift_pmc(interp, *retp, result_pmc);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
}

/*

=item C<void blizkost_bind_pmc_to_sv(PerlInterpreter *my_perl, SV *sv,
PARROT_INTERP, PMC *p5i, PMC *target)>

=item C<void blizkost_get_bound_pmc(PerlInterpreter *my_perl, SV *sv,
Parrot_Interp *interpr, PMC **p5ir, PMC **targetr)>

Magically associates PMCs with SVs.  Since the latter function is intended
for use in callbacks from Perl 5, it throws a Perl 5 exception on failure.

=cut

*/

static int
blizkost_delete_binding(PerlInterpreter *my_perl, SV *handle, MAGIC *mg)
{
    Parrot_P5Interpreter_attributes *back
        = (Parrot_P5Interpreter_attributes *)(mg->mg_ptr);

    PMC *targ = (PMC *)(mg->mg_obj);
    Parrot_Interp interp = back->parrot_interp;

    PARROT_CALLIN_START(interp);
    Parrot_pmc_gc_unregister(interp, targ);
    PARROT_CALLIN_END(interp);

    return 0;
}

static MGVTBL blizkost_binder_vtbl = { 0, 0, 0, 0, blizkost_delete_binding,
    0, 0, 0 };

void
blizkost_get_bound_pmc(PerlInterpreter *my_perl, SV *sv,
        Parrot_Interp *interpr, PMC **p5ir, PMC **targetr) {
    MAGIC *mgp;
    Parrot_P5Interpreter_attributes *back;

    if (SvMAGICAL(sv))
        for (mgp = SvMAGIC(sv); mgp; mgp = mgp->mg_moremagic)
            if (mgp->mg_virtual == &blizkost_binder_vtbl)
                goto gotmagic;

    croak("blizkost: expected a bound PMC, got something else");

gotmagic:

    back = (Parrot_P5Interpreter_attributes *)(mgp->mg_ptr);

    *interpr = back->parrot_interp;
    *p5ir    = back->self;
    *targetr = (PMC *)mgp->mg_obj;
}

void
blizkost_bind_pmc_to_sv(PerlInterpreter *my_perl, SV *sv,
        PARROT_INTERP, PMC *p5i, PMC *target) {
    MAGIC *mg;

    mg = sv_magicext(sv, 0, PERL_MAGIC_ext, &blizkost_binder_vtbl, 0, 0);
    mg->mg_ptr = (char*)PARROT_P5INTERPRETER(p5i);
    mg->mg_obj = (SV*)  target;

    Parrot_pmc_gc_register(interp, target);
}

/* can't really use xsubpp here... */
static
XS(blizkost_callable_trampoline)
{
#ifdef dVAR
    dVAR;
#endif
    dXSARGS;
    PMC *callable, *p5i;
    Parrot_Interp interp;
    int i;
    PMC *args, *posret, *namret;

    blizkost_get_bound_pmc(my_perl, (SV *)cv, &interp, &p5i, &callable);

    PERL_UNUSED_VAR(ax);
    SP -= items;
    PUTBACK;

    args = Parrot_pmc_new(interp, enum_class_ResizablePMCArray);
    for (i = 0; i < items; i++) {
        SV *svarg = ST(i);
        PMC *pmcarg = blizkost_wrap_sv(interp, p5i, svarg);
        VTABLE_unshift_pmc(interp, args, pmcarg);
    }

    Parrot_pcc_invoke_sub_from_c_args(interp, callable, "Pf->PsPsn",
            args, &posret, &namret);

    blizkost_slurpy_to_stack(interp, p5i, my_perl, posret, namret);

    SPAGAIN;
}

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
static CV *
blizkost_wrap_callable(PARROT_INTERP, PMC *p5i, PMC *callable) {
    PerlInterpreter *my_perl;
    CV *cv;

    GETATTR_P5Interpreter_my_perl(interp, p5i, my_perl);

    cv = newXS("blizkost_xs_wrapper", blizkost_callable_trampoline,
            "bkmarshal.c");
    blizkost_bind_pmc_to_sv(my_perl, (SV*)cv, interp, p5i, callable);

    return cv;
}
