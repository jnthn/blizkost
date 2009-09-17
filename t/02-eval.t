# I am not sure how to execute these tests from harness.
# make test or parrot ./perl5.pir t/02-eval.t or ./blizkost t/02-eval.t

use Test;
BEGIN {
    eval { require v6 };
    if ($@) {
        print "1..1\n";
        print "ok 1 # v6.pm not installed\n";
        exit;
    }
}
plan 5;

ok 1 == eval( '1', :lang<perl5>), 'eval Integer';
ok 1 == eval( '1', :lang<perl5>), 'eval Num';
ok 'a' eq eval( '"a"', :lang<perl5>), 'eval String';
ok 'ok' eq  eval(  'sub A::t {  $_[1]->[0] . $_[1]->[1]  };   bless {}, A', :lang<perl5> ).t( < o k > ),  'eval Array';
ok 'ok' eq eval(  'sub A::t { $_[1]->{a}  };   bless {}, A', :lang<perl5> ).t( { :a<ok> } ), 'eval Hash';
