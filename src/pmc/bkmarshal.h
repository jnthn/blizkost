/*
Copyright (C) 2009-2010, Jonathan Worthington and friends

This file is distributed under the same terms as Parrot itself; see the
file LICENSE in the source root for details.

=head1 NAME

src/pmc/bkmarshal.h - wrap P5 and Parrot calling conventions

=head1 DESCRIPTION

=cut

*/

#ifndef BLIZKOST_MARSHAL_H_GUARD
#define BLIZKOST_MARSHAL_H_GUARD

/* Holds all data which ties Perl5 and Parrot together.  We can't store it in
   either's heap without destruction order fiascos. */
typedef struct blizkost_nexus {
    PerlInterpreter *my_perl;
    Parrot_Interp parrot_interp;
    PMC *p5i;
} blizkost_nexus;

#define BLIZKOST_NEXUS blizkost_nexus *nexus
#define BNINTERP (nexus->parrot_interp)
#define dBNPERL PerlInterpreter *const my_perl = nexus->my_perl
#define iBNPERL my_perl = nexus->my_perl
#define dBNINTERP Parrot_Interp const interp = nexus->parrot_interp

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
SV *blizkost_marshal_arg(BLIZKOST_NEXUS, PMC *arg);

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
PMC *blizkost_wrap_sv(BLIZKOST_NEXUS, SV *sv);

PARROT_WARN_UNUSED_RESULT
PARROT_CANNOT_RETURN_NULL
opcode_t *blizkost_return_from_invoke(PARROT_INTERP, void *next);

int blizkost_slurpy_to_stack(BLIZKOST_NEXUS, PMC *positional, PMC *named);

void blizkost_call_in(BLIZKOST_NEXUS, SV *what, U32 mode, PMC *positp,
        PMC *namedp, PMC **retp);

void blizkost_bind_pmc_to_sv(BLIZKOST_NEXUS, SV *sv, PMC *target);

void blizkost_get_bound_pmc(PerlInterpreter *my_perl,
        blizkost_nexus **nexusr, SV *sv, PMC **targetr);

#endif
