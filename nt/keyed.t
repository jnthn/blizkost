# vim: ft=perl6

plan(3);

my $p5code := '{ foo => 2, bar => 7 }';

pir::load_bytecode("perl5.pir");
my $p5obj := pir::compreg__ps("perl5").make_interp($p5code)();

ok($p5obj<foo> == 2, "can access p5 hashes");
ok($p5obj<bar> == 7, "different keys are distinct");
ok(!pir::defined($p5obj<baz>), "failure is reported");
