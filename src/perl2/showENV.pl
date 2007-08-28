#!/usr/bin/perl -w
use strict;
use CGI;
my $CGI = CGI->new();
print $CGI->header(-type => 'text/plain');


my ($key,$value);
while ( ($key, $value) = each %ENV)
{
        print "$key = $value\n";
}
print "\nPerl \@INC:\n";
print "$_\n" foreach (@INC);


1;
