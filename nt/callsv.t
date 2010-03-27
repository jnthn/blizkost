# vim: ft=perl6

plan(1);

my $p5code := 'sub { my $x = shift; return $x ** $x }';

pir::load_bytecode("perl5.pir");
my $p5fun := pir::compreg__ps("perl5").make_interp($p5code)();

ok($p5fun(4) == 256, "can call through p5 subs");
