use v6;
use CGI:from<perl5>;

my $q = CGI.new;
print $q.header,
      $q.start_html('Hello World'),
      $q.h1('Hello World'),
      $q.end_html;
