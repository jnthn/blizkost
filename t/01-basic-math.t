print "1..3\n";

{
    my $x = 5;
    print "not " unless ($x == 5);
    ok(1,"x=$x");
    $x++;
    print "not " unless ($x == 6);
    ok(2,"x=$x");
    $x--;
    print "not " unless ($x == 5);
    ok(3, "x=$x");
}

sub ok {
    my ($num,$diag) = @_;
    print "ok $num";

    print $diag ? " # $diag\n" : "\n";
}
