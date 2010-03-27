# vim: ft=perl6

plan(4);

pir::load_bytecode("perl5.pir");
ok(1, "loaded blizkost");

my $comp := pir::compreg__ps("perl5");
ok(1, "perl5 compiler found");

my $func := $comp.make_interp("2+2");
ok(1, "interpreter instantiated");

ok($func() == 4, "eval returned correct");
