#! /usr/bin/perl -w
use strict;
use CGI;
CGI->compile(':all');
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Sys::Hostname;
use Fcntl;
use File::Basename;
use OMEpl;
print STDERR "Executed OMEstartup.pl\n";
use vars qw ($OME_TEST);
$OME_TEST = "A wee little test of memory sharing";
1;
