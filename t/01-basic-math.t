use strict;
use warnings;

print "1..3\n";
my $t=1;

{
    my $x = 5;
    ok($x==5,"x=$x");
    $x++;
    ok($x==6,"x=$x");
    $x--;
    ok($x==5, "x=$x");
}

sub ok {
    my ($truth,$diag) = @_;
    print $truth ? "ok $t" : "not ok $t";
    $t++;

    print $diag ? " # $diag\n" : "\n";
}
