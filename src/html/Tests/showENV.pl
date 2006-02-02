#!/usr/bin/perl -w
use strict;
use CGI;
my $CGI = CGI->new();
print $CGI->header(-type => 'text/plain'),


my ($key,$value);
while ( ($key, $value) = each %ENV)
{
        print "$key = $value\n";
}


1;
