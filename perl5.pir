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

    $P0 = new 'P5Interpreter'
    $P0 = source
    .return ($P0)
.end


=item eval

=cut

.sub 'eval' :method
    .param pmc code
    .param pmc args            :slurpy
    .param pmc adverbs         :slurpy :named
    
    $P0 = self.'compile'(code, args :flat, adverbs :flat :named)
    $P0()
    .return ("")
.end

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

