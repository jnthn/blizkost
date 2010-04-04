/*
Copyright (C) 2009-2010, Jonathan Worthington and friends
$Id$

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

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "pmc_p5interpreter.h"
#include "pmc_p5invocation.h"
#include "pmc_p5namespace.h"
#include "pmc_p5sv.h"
#include "pmc_p5scalar.h"

#include "bkmarshal.h"

#endif
