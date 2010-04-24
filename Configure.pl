=head1 NAME

Configure.pl - a configure script for Blizkost

=head1 SYNOPSIS

  perl Configure.pl --help

  perl Configure.pl

  perl Configure.pl --parrot-config=<path_to_parrot>

  perl Configure.pl --gen-parrot [ -- --options-for-configure-parrot ]

=cut

use strict;
use warnings;
use 5.008;
use Config;

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

$config{p5_ldopts} = ldopts(1);
$config{p5_ccopts} = ccopts(1);
$config{p5_perl} = $^X;

#  Create the Makefile using the information we just got
create_makefile('Makefile' => %config);
create_makefile('src/pmc/Makefile' => %config);

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

print <<BYE;
Okay, we're done!

You can now use `make' to build your Blizkost library, or 'make blizkost' to
build the binary.  After that, you can use `make test' to run the test suite.

Happy Hacking,
        The Blizkost Team
BYE

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

