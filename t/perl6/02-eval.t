#!perl6
# I am not sure how to execute these tests from harness.
# perl6 t/02-eval.t should work

use v6;
use Test;
plan 5;

ok 1 == eval( '1', :lang<perl5>), 'eval Integer';
ok 1 == eval( '1', :lang<perl5>), 'eval Num';
ok 'a' eq eval( '"a"', :lang<perl5>), 'eval String';
ok 'ok' eq  eval(  'sub A::t {  $_[1]->[0] . $_[1]->[1]  };   bless {}, A', :lang<perl5> ).t( < o k > ),  'eval Array';
ok 'ok' eq eval(  'sub A::t { $_[1]->{a}  };   bless {}, A', :lang<perl5> ).t( { :a<ok> } ), 'eval Hash';
