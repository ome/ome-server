#!/usr/bin/perl -w
use CGI qw (:html3);
use CGI::Carp qw(fatalsToBrowser);
use strict;

use vars qw ($cgi);
use vars qw (@tableRows @tableColumns);

$cgi = new CGI;

print $cgi->header (-type=>'text/html'),
		$cgi->start_html(-title=>'Environment variables - the %ENV Hash');

$tableColumns[0] = "Variable";
$tableColumns[1] = "Value";

@tableRows = $cgi->th (\@tableColumns);

while ( ($tableColumns[0], $tableColumns[1]) = each %ENV)
{
	push (@tableRows,$cgi->td(\@tableColumns));
}

print $cgi->table({-border=>1,-cellspacing=>1,-cellpadding=>1},
		$cgi->Tr(\@tableRows));


