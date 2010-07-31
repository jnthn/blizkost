=head1 NAME

Configure.pl - a configure script for Blizkost

=head1 SYNOPSIS

  perl Configure.pl --help

  perl Configure.pl

  perl Configure.pl --parrot-config=<path_to_parrot_config>

  perl Configure.pl --gen-parrot [ -- --options-for-configure-parrot ]

=cut

# Ideally we'd support back further, but fixing the macro framework back
# in time is not a priority
use 5.010;
use strict;
use warnings;
use Config;
my %Perlconfig = %Config;

use Getopt::Long qw(:config auto_help);

use ExtUtils::Embed;

our ( $opt_parrot_config, $opt_gen_parrot);
GetOptions( 'parrot-config=s', 'gen-parrot' );

print <<HELLO;

Hello, I'm Configure. My job is to poke and prod your system to figure out
how to build Blizkost.

HELLO
#  Update/generate parrot build if needed
if ($opt_gen_parrot) {
    system($^X, 'build/gen_parrot.pl', @ARGV);
}

#  Get a list of parrot-configs to invoke.
my @parrot_config_exe = $opt_parrot_config
                      ? ( $opt_parrot_config )
                      : (
                          'parrot/parrot_config',
                          '../../parrot_config',
                          'parrot_config',
                        );

#  Get configuration information from parrot_config
my %config = read_parrot_config(@parrot_config_exe);
unless (%config) {
    die "Unable to locate parrot_config\n"
        ."Please give me the path to it with the --parrot-config=... option.";
}

my $caution = 0;
sub dubious {
    my ($bool, $msg) = @_;

    if ($bool) {
        print "* * * CONFIGURE HAS DETECTED A POTENTIAL PROBLEM\n";
        print $msg;
        print "\n";

        $caution ||= 1;
    }
}

$config{p5_ldopts} = ldopts(1);
$config{p5_ccopts} = ccopts(1);
$config{p5_perl} = $^X;

#  Create the Makefile using the information we just got
create_makefile('Makefile' => %config);

sub read_parrot_config {
    my @parrot_config_exe = @_;
    my %config = ();
    for my $exe (@parrot_config_exe) {
        no warnings;
        if (open my $PARROT_CONFIG, '-|', "$exe --dump") {
            print "Reading configuration information from $exe\n";
            while (<$PARROT_CONFIG>) {
                $config{$1} = $2 if (/(\w+) => '(.*)'/);
            }
            close $PARROT_CONFIG;
            last if %config;
        }
    }
    %config;
}

#  Generate a Makefile from a configuration
sub create_makefile {
    my ($name, %config) = @_;

    my $maketext = slurp( "build/$name.in" );

    $config{'win32_libparrot_copy'} = $^O eq 'MSWin32' ? 'copy $(PARROT_BIN_DIR)\libparrot.dll .' : '';
    $maketext =~ s{#IF\((\w+)\):(.*\n)}{$config{osname} eq $1 ? $2 : ""}eg;
    $maketext =~ s/@(\w+)@/exists $config{$1} ? $config{$1} : die("No such config var $1")/eg;
    if ($^O eq 'MSWin32') {
        $maketext =~ s{/}{\\}g;
        $maketext =~ s{\\\*}{\\\\*}g;
        $maketext =~ s{http:\S+}{ do {my $t = $&; $t =~ s'\\'/'g; $t} }eg;
    }

    my $outfile = $name;
    print "\nCreating $outfile ...\n";
    open(my $MAKEOUT, '>', $outfile) ||
        die "Unable to write $outfile\n";
    print {$MAKEOUT} $maketext;
    close $MAKEOUT or die $!;

    return;
}

sub slurp {
    my $filename = shift;

    open my $fh, '<', $filename or die "Unable to read $filename\n";
    local $/ = undef;
    my $maketext = <$fh>;
    close $fh or die $!;

    return $maketext;
}

dubious !$Perlconfig{usemultiplicity}, <<MULT;
Your Perl is not configured to allow runtime creation of new interpreters.
Chances of success are quite slim.  You should recompile Perl with the
-Dusemultiplicity configuration option (-Dusethreads implies this).
MULT

dubious !$Perlconfig{useshrplib}, <<SHR;
Your Perl is not built as a dynamic library.  In the best case this will result
in a bloated Blizkost library; other possible results include significantly
slower startup, increased per-process memory usage, and in the worst case
crashes, depending on platform, as using non-dynamic libraries from dynamic
ones is rarely well supported.  If this is a problem in your environment,
reconfigure Perl with -Duseshrplib.
SHR

# cygwin perl uses the gcc alias, but is gcc-4. cygwin parrot uses gcc-4.
$Perlconfig{cc} = 'gcc-4' if $Perlconfig{cc} eq 'gcc'
  and $^O eq 'cygwin'
  and $Perlconfig{gccversion} eq '4.3.4 20090804 (release) 1';

dubious $Perlconfig{cc} ne $config{cc}, <<TWOCC;
Blizkost needs to be built using the same version of the same C compiler as
both Perl and Parrot, in order to have a compatible interpretation of runtime
data layouts.  However, this is not possible, as your Perl and your Parrot are
built with different C compilers (Perl: $Perlconfig{cc}, Parrot: $config{cc})!
Runtime instabilities are the most likely result.  To fix, recompile Parrot or
Perl with the other's compiler.
TWOCC

# XXX: Find a good way to test CPU types, for multiarch systems (it's rarely
# possible to dlopen code for a different CPU, even if both CPU types can be
# interpreted by the hardware)

my $make = $config{make};
print <<BYE;
Okay, we're done!

You can now use `$make' to build your Blizkost library, or '$make blizkost' to
build the binary.  After that, you can use `$make test' to run the test suite.

Happy Hacking,
        The Blizkost Team
BYE

if ($caution) {
    print "\n* * * Proceed with installation at your own risk.\n";
    exit 1;
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

