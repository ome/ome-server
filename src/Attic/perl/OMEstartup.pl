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

my $dir;
my $apacheUID = getpwnam('www');
my $apacheGrp = getgrnam('www');

$dir = '/var/tmp/OME';
if (not -e $dir) {
	die "Couldn't make directory $dir: $!\n" if system ( "mkdir $dir");
	chown $apacheUID, $apacheGrp, $dir;
	chmod 0700, $dir;
}

$dir = '/var/tmp/OME/lock';
if (not -e $dir) {
	die "Couldn't make directory $dir: $!\n" if system ( "mkdir $dir");
	chown $apacheUID, $apacheGrp, $dir;
	chmod 0700, $dir;
}

$dir = '/var/tmp/OME/sessions';
if (not -e $dir) {
	die "Couldn't make directory $dir: $!\n" if system ( "mkdir $dir");
	chown $apacheUID, $apacheGrp, $dir;
	chmod 0700, $dir;
}

$dir = '/OME/Datasets';
if (not -e $dir) {
	die "Couldn't make directory $dir: $!\n" if system ( "mkdir $dir");
	chown $apacheUID, $apacheGrp, $dir;
	chmod 0755, $dir;
}

1;
