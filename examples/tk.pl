# vim: ft=perl6
# (actually NQP; the real Perl6 version will be much neater)

# next 6 lines would be 'use' in a real language
pir::load_bytecode('perl5.pbc');
my $comp := pir::compreg__ps('perl5');

my $mod  := $comp.load_module('Tk');
my %exp  := $comp.get_exports($mod);

my $MainWindow := $comp.get_namespace('MainWindow');
my &MainLoop := %exp<sub><MainLoop>;
###

my $mw := $MainWindow.new;

$mw.Label('-text', 'Hello, world!').pack;

# NQP doesn't support named args starting with a dash
$mw.Button(
    '-text',    'Quit',
    '-command', sub (*@_) { exit },
).pack;

&MainLoop();
