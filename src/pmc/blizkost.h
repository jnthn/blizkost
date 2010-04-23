/*
Copyright (C) 2009-2010, Jonathan Worthington and friends

This file is distributed under the same terms as Parrot itself; see the
file LICENSE in the source root for details.

=head1 NAME

src/pmc/blizkost.h - centralize P5+Parrot header cruft

=head1 DESCRIPTION

Perl5 and Parrot headers like to trample on each other.  This module
does the necessary cruft to import both in the same file.

=cut

*/

#ifndef BLIZKOST_H_GUARD
#define BLIZKOST_H_GUARD

#define PARROT_IN_EXTENSION
#include "parrot/parrot.h"
#include "parrot/extend.h"
#include "parrot/dynext.h"

/* clear out a few macros that Perl wants to define itself */

#undef HASATTRIBUTE_PURE
#undef HASATTRIBUTE_UNUSED
#undef HASATTRIBUTE_NONNULL
#undef HASATTRIBUTE_MALLOC
#undef HASATTRIBUTE_NORETURN
#undef HASATTRIBUTE_UNUSED
#undef HASATTRIBUTE_WARN_UNUSED_RESULT
#undef HASATTRIBUTE_DEPRECATED

#undef _

#undef __attribute__deprecated__
#undef __attribute__format__
#undef __attribute__nonnull__
#undef __attribute__noreturn__
#undef __attribute__pure__
#undef __attribute__unused__
#undef __attribute__warn_unused_result__

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

/* The Perl definition of this runs foul of -Wnested-externs */
#undef dNOOP
#define dNOOP int /*@unused@*/ Perl___notused PERL_UNUSED_DECL

#include "pmc_p5interpreter.h"
#include "pmc_p5invocation.h"
#include "pmc_p5namespace.h"
#include "pmc_p5sv.h"
#include "pmc_p5scalar.h"
#include "pmc_p5hashiter.h"

extern HE blizkost_EMPTY;

#include "bkmarshal.h"

#endif
