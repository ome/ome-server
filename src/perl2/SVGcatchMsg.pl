use strict;
use CGI;
my $q = new CGI();
print STDERR "Caught message: ".$q->param( 'msg' )."\n";

