# vim: ft=perl6

plan(1);

pir::load_bytecode('perl5.pbc');
my $perl5 := pir::compreg__ps('perl5');

my $module := $perl5.load_module('POSIX');

my $exports := $perl5.get_exports($module);

ok($exports<sub><ENOENT>() != 0, "Export can handle autoexpand constants");
