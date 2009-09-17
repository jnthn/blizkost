print "1..3\n";
my $t=1;

eval { require Test; };
if ($@) {
    ok(0,"TODO require Test : $@");
} else {
    ok(1,'require Test');
}

{
    eval { require Data::Dumper; };
    if ($@) {
        ok(0,"TODO require Data::Dumper : $@");
    } else {
        ok(1,'require Data::Dumper');
    }
}

{
    eval { require Config; };
    if ($@) {
        ok(0,"TODO require Config : $@");
    } else {
        ok(1,'require Config');
    }
}

sub ok {
    my ($truth,$diag) = @_;
    print $truth ? "ok $t" : "not ok $t";
    $t++;

    print $diag ? " # $diag\n" : "\n";
}
