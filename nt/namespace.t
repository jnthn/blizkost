# vim: ft=perl6

plan(2);

pir::load_bytecode("perl5.pir");
my $p5 := pir::compreg__ps("perl5");

$p5.make_interp('
    package Foo::Bar;
    sub Method {
        my ($self, $x, $y) = @_;
        return $x + $y;
    }
')();

my $ns := $p5.get_namespace('Foo::Bar');

ok(pir::defined($ns), "can get namespaces for packages");

ok($ns.Method(1,3,7) == 4, "can call package methods");
