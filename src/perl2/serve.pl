#!/usr/bin/perl -w

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web;


my $CGI = CGI->new();
my $pageClass = $CGI->url_param("Page");

if ($pageClass) {
    my $page;
    {
	eval "require $pageClass";
	$page = $pageClass->new(CGI => $CGI);
    }
    if ($@) {
	print STDERR "Error loading package - $@\n";
	print $CGI->header(-type => 'text/html',-status => '404 File not found');
    } elsif (!$page->isa("OME::Web")) {
	print STDERR "Package not OME::Web\n";
	print $CGI->header(-type => 'text/html',-status => '404 File not found');
    } else {
	$page->serve();
    }
} else {
    print STDERR "Class not specified\n";
    print $CGI->header(-type => 'text/html',-status => '404 File not found');
}
