# vim: ft=perl6

use Tk:from<perl5>;

# Larry says that in the scope of a use :from<perl5>, a lexical CANDO should
# be installed which allows reference to Perl5 packages (which are trueglobal)
# as variables in scope.  Alternatively, there could be a syntax for binding
# without requiring.
my $mw = eval("'MainWindow'", :lang<perl5>).new;

$mw.Label('-text', 'Hello, world!').pack;

# We can't currently propagate rakudosubs because they don't advertize
# themselves the same way as others - see TT#1597
$mw.Button(
    '-text',    'Quit',
    '-command', (sub (*@_) { pir::exit(0) }).do,
).pack;

MainLoop();
