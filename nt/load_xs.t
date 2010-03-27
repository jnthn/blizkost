# vim: ft=perl6

plan(1);

pir::load_bytecode('perl5.pbc');
my $ns := pir::compreg__ps('perl5').load_library(['Scalar','Util'])<namespace>;

ok(1, "Scalar::Util loaded OK");

# TODO: actually call functions

