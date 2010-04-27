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
    load_bytecode 'PCT/HLLCompiler.pbc'

    $P2 = split ' ', '$!interp $!requirer $!export-lister'

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
    .local pmc p5i, requirer, exportlister, support
    p5i = getattribute self, "$!interp"
    unless null p5i goto have_interp

    p5i = new 'P5Interpreter'
    setattribute self, "$!interp", p5i

    # unfortunately, the Perl 5 C API only allows making evals in scalar context
    support = p5i(<<"End_Init_Code")
my $req = sub {
    my ($module_name) = @_;
    # Yes, this is portable.
    $module_name =~ s|::|/|g;
    $module_name .= ".pm";
    require $module_name;
};

my $explist = sub {
    my ($module_name, @tags) = @_;
    # should already be loaded
    my @output;

    my %sigils = (SCALAR => '$', ARRAY => '@', HASH => '%', IO => '*');

    %Blizkost::ImportZone:: = ();
    {
        package Blizkost::ImportZone;
        $module_name->import(@tags);
    }

    for my $name (keys %Blizkost::ImportZone::) {
        my $gref = \$Blizkost::ImportZone::{$name};

        # Perl5 has a clever feature where a constant subroutine can be
        # represented by putting a reference in the symbol table instead
        # of an actual symbol table entry, saving memory and time.  Pity
        # we have to undo it.
        if (ref($gref)) {
            my $val = $$gref;
            push @output, 'sub', $name, sub () { $val };
            next;
        }

        my %things;

        for my $type (qw/SCALAR ARRAY HASH IO/) {
            my $ref = *{$gref}{$type};
            next unless defined $ref;

            $things{$type} = $ref;
        }

        if (keys %things > 1) {
            for my $used_type (keys %things) {
                push @output, 'var', ($sigils{$used_type} . $name),
                        $things{$used_type};
            }
        } elsif (keys %things == 1) {
            my $used_type = (keys %things)[0];
            push @output, 'var', $name, $things{$used_type};
        }

        if (defined *{$gref}{CODE}) {
            push @output, 'sub', $name, *{$gref}{CODE};
        }
    }

    return @output;
};

{ requirer => $req, exportlister => $explist };
End_Init_Code

    requirer = support["requirer"]
    exportlister = support["exportlister"]

    setattribute self, "$!requirer", requirer
    setattribute self, "$!export-lister", exportlister

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
    $P1 = newclosure $P1
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

=item load_module(name)

=item get_module(name)

Implements the PDD-31 library loading interface.

=cut

.sub 'load_module' :method
    .param pmc name_str
    .param pmc extra :named :slurpy

    self.'!force'()
    $P0 = getattribute self, '$!requirer'
    $P0(name_str)

    .return (name_str)
.end

.sub 'get_module' :method
    .param pmc name_str

    .return (name_str)
.end

.sub 'get_namespace' :method
    .param pmc name

    self.'!force'()

    $P0 = getattribute self, '$!interp'
    $P0 = $P0.'get_namespace'(name)

    .return($P0)
.end

.sub 'get_exports' :method
    .param pmc module_name
    .param pmc imports :slurpy

    self.'!force'()

    .local pmc expiter, expout

    $P0 = getattribute self, '$!export-lister'
    ($P0 :slurpy) = $P0(module_name, imports :flat)
    expiter = iter $P0

    expout = new 'Hash'
    $P0 = new 'Hash'
    expout["sub"] = $P0
    $P0 = new 'Hash'
    expout["var"] = $P0

  again:
    unless expiter, the_end

    $P1 = shift expiter
    $P0 = expout[$P1]

    $P1 = shift expiter
    $P2 = shift expiter
    $P0[$P1] = $P2

    goto again

  the_end:
    .return(expout)
.end

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

