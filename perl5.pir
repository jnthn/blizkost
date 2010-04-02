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

.include "dlopenflags.pasm"
.namespace [ 'Perl5' ; 'Compiler' ]

.sub 'onload' :anon :load :init
    $P0 = box .Parrot_dlopen_global_FLAG
    $P1 = loadlib 'blizkost_group', $P0
    load_bytecode 'PCT.pbc'

    $P2 = split ' ', '$!interp $!requirer'

    $P0 = get_root_global ['parrot'], 'P6metaclass'
    $P1 = $P0.'new_class'('Perl5::Compiler', 'parent'=>'PCT::HLLCompiler', 'attr'=>$P2)
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

# We maintain one P5Interpreter (Perl heap) per Parrot heap (compreg object),
# to avoid suprising duplication.  TODO: locking.
.sub '!force' :method
    .local pmc p5i, requirer
    p5i = getattribute self, "$!interp"
    unless null p5i goto have_interp

    p5i = new 'P5Interpreter'
    setattribute self, "$!interp", p5i

    requirer = p5i('sub { my ($n) = @_; $n =~ s|::|/|g; $n .= ".pm"; require $n }')
    setattribute self, "$!requirer", requirer

  have_interp:
.end

=item make_interp()

=cut

.sub 'make_interp' :method
    .param pmc source
    .param pmc adverbs      :slurpy :named

    self.'!force'()

    .local pmc p5i
    p5i = getattribute self, "$!interp"

    .lex "$interp", p5i
    .lex "$code", source
    .const 'Sub' $P1 = "interp_stub"
    capture_lex $P1
    .return ($P1)
.end

.sub "interp_stub" :anon :outer("make_interp")
    $P0 = find_lex "$interp"
    $P1 = find_lex "$code"
    .tailcall $P0($P1)
.end

=item eval

=cut

.sub 'eval' :method
    .param pmc code
    .param pmc args            :slurpy
    .param pmc adverbs         :slurpy :named

    $P0 = self.'compile'(code, adverbs :flat :named)
    .tailcall $P0()
.end

=item load_library

Implements the HLLCompiler library loading interface.

=cut

.sub 'load_library' :method
    .param pmc name
    .param pmc extra :named :slurpy

    # Construct a use into some dummy package.
    # XXX Add a number to make it unique per use.
    .local string package_name, name_str
    package_name = 'BLIZKOST::TEMP::IMPORT'
    name_str = join '::', name

    self.'!force'()
    $P0 = getattribute self, '$!requirer'
    $P0(name_str)

    # Make namespace wrapper PMC.
    .local pmc ns_wrapper, p5i
    p5i = getattribute self, "$!interp"
    ns_wrapper = new ['P5Namespace'], p5i
    ns_wrapper = name_str

    # Set up imports. XXX No import symbols yet, todo.
    .local pmc imports
    imports = new ['Hash']
    $P0 = new ['Hash']
    imports['DEFAULT'] = $P0

    # Construct library info hash.
    .local pmc result
    result = new ['Hash']
    result['namespace'] = ns_wrapper
    result['symbols'] = imports
    .return (result)
.end

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

