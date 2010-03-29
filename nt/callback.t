# vim: ft=perl6

plan(6);

pir::load_bytecode("perl5.pir");

sub p5($code) {
    pir::compreg__ps("perl5").make_interp('sub {' ~ $code ~ '}')();
}

my $f1 := p5('5;');
ok((+$f1(sub(){})) == 5, "can pass subs into p5");

my $f2 := p5('my $f = shift; $f->(); 4');
ok((+$f2(sub(){})) == 4, "can call subs passed into p5");

my $v := 0;
my $f3 := p5('my $f = shift; $f->(5); 2');
$f3(sub(){ $v := 3 });
ok($v == 3, "can pass values into callbacks");

my $f4 := p5('my $f = shift; $f->()');
ok((+$f4(sub(){7})) == 7, "can return values from callbacks");

my $f5 := p5('my ($f,$v) = @_; $f->($v*$v) - 2');
ok((+$f5(sub($x){(+$x)+2}, 16)) == 256, "can do arithmetic with wrapped values");

$v := 0;
my $f6 := p5('my $f = shift; sub { $f->(shift()+1) }');
$f6($f6($f6($f6(sub($a) { $v := +$a }))))(9);
ok($v == 13, "can deeply recurse between p5 and parrot");

