# vim: ft=perl6

plan(9);

pir::load_bytecode('perl5.pbc');
my $perl5 := pir::compreg__ps('perl5');

my $module := $perl5.load_module('Text::Tabs');

ok(pir::defined($module), "Text::Tabs loaded OK");

my $exports := $perl5.get_exports($module);

ok(pir::defined($exports), "Got export list");

my $sub := $exports<sub>;
my $var := $exports<var>;

ok(pir::defined($sub), "sub export field exists");
ok(pir::defined($var), "var export field exists");

ok(pir::defined($sub<expand>), "expand sub exported");
ok($sub<expand>("foo\tbar") eq "foo     bar", "expand sub works");

ok(pir::defined($sub<unexpand>), "unexpand sub exported");
ok($sub<unexpand>("foo     bar") eq "foo\tbar", "unexpand sub works");

ok(pir::defined($var<tabstop>), "tabstop var exported");
# TODO: Provide a way to interact with data.

