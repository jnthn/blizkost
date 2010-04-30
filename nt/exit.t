# vim: ft=perl6

plan(0);

my $p5code := 'sub { shift->() }';

pir::load_bytecode("perl5.pir");
my $p5fun := pir::compreg__ps("perl5").make_interp($p5code)();

my &foo := sub () {
    pir::exit(0);
};

$p5fun(&foo);
