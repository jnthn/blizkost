=head1 TITLE

perl5.pir - A Perl 5 compatibility interface for Parrot.

=head2 Description

This file sets up something that will work with HLLCompiler and
allow us to eval Perl 5 code.

=head2 Functions

=over 4

=item onload()

Creates the compiler using a C<PCT::HLLCompiler> object.

=cut

.loadlib 'blizkost_group'

.namespace [ 'Perl5' ; 'Compiler' ]

.sub 'onload' :anon :load :init
    load_bytecode 'PCT.pbc'

    $P0 = get_root_global ['parrot'], 'P6metaclass'
    $P1 = $P0.'new_class'('Perl5::Compiler', 'parent'=>'PCT::HLLCompiler')
    $P1.'language'('perl5')
    $P0 = split ' ', 'make_interp'
    setattribute $P1, '@stages', $P0
.end


=item main(args :slurpy)  :main

Start compilation by passing any command line C<args>
to the blizkost compiler.

=cut

.sub 'main' :main
    .param pmc args

    $P0 = compreg 'perl5'
    $P1 = $P0.'command_line'(args)
.end


=item make_interp()

=cut

.sub 'make_interp' :method
    .param string source
    .param pmc adverbs      :slurpy :named

    # We maintain a persistent P5Interpreter per Parrot interpreter. Should
    # be a reasonable stratergy, or at least we'll try it until somebody can
    # say why it's wrong and give us a better one.
    .local pmc parrot_interp, p5i
    parrot_interp = getinterp
    p5i = getprop '$!p5i', parrot_interp
    unless null p5i goto have_interp
    p5i = new 'P5Interpreter'
    setprop parrot_interp, '$!p5i', p5i
  have_interp:

    # Set current "to eval" source code, and we're done.
    p5i = source
    .return (p5i)
.end


=item eval

=cut

.sub 'eval' :method
    .param pmc code
    .param pmc args            :slurpy
    .param pmc adverbs         :slurpy :named
    
    $P0 = self.'compile'(code, adverbs :flat :named)
    ($P1 :slurpy, $P2 :slurpy :named)  = $P0()
    .return ($P1 :flat, $P2 :flat :named)
.end


=item !return_value_helper

This is a little helper routine to save us having to mess around with the
Parrot calling conventions to be able to return a value from some eval'd
code.

=cut

.sub '!return_value_helper'
    # Get the attached return value.
    $P0 = getinterp
    $P0 = $P0['sub']
    $P0 = getprop '$!ret_val', $P0
    .return ($P0)
.end


=item !return_value_helper_arr

Like !return_value_helper but takes an array of many return values and
flattens it.

=cut

.sub '!return_value_helper_arr'
    $P0 = getinterp
    $P0 = $P0['sub']
    $P0 = getprop '$!ret_val', $P0
    .return ($P0 :flat)
.end


=item load_library

Implements the HLLCompiler library loading interface.

=cut

.sub 'load_library' :method
    .param pmc name
    .param pmc extra :named :slurpy
    die 'Sorry, library loading from Perl 5 is not yet implemented.'
.end

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

