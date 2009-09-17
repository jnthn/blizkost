print "1..2\n";

eval { require Data::Dumper; };
if ($@) {
    print "not ok 1 # TODO use Data::Dumper : $@\n";
} else {
    ok(1,'use Data::Dumper');
}

eval { require Config; };
if ($@) {
    print "not ok 1 # TODO use Config : $@\n";
} else {
    ok(2,'use Config');
}

sub ok {
    my ($num,$diag) = @_;
    print "ok $num";

    print $diag ? " # $diag\n" : "\n";
}
