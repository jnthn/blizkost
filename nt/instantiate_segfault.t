# vim: ft=perl6

plan(1);

pir::load_bytecode('perl5.pbc');
my $exn := 0;
try {
    my $a := pir::new__pk(['P5Scalar']);
    CATCH { $exn := $!; }
}
ok(pir::defined($exn), "attempting to create a P5Scalar directly fails");
