#!/usr/bin/perl -w

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;


my $CGI = CGI->new();
my $pageClass = $CGI->url_param("Page");

if ($pageClass) {
	my $page;
	eval "use $pageClass";
	if ($@) {
		print STDERR "Error loading package - $@\n";
		print $CGI->header(-type => 'text/html',-status => '404 File not found');
	}

	eval {
		$page = $pageClass->new(CGI => $CGI);
		if (!$page) {
			print STDERR "Error calling package constructor -\n";
			print $CGI->header(-type => 'text/html',-status => '404 File not found');
		} elsif (! (ref($page) =~ /^OME::Web::/) ) {
			print STDERR "Package ".ref($page)." does not inherit from OME::Web\n";
			print $CGI->header(-type => 'text/html',-status => '404 File not found');
		} else {
			$page->serve();
		}
	};
	
	if ($@) {
		print $CGI->header(-type => 'text/html');
		print "<pre>Error serving $pageClass:\n$@</pre>";
	}
} else {
	print STDERR "Class not specified\n";
	print $CGI->header(-type => 'text/html',-status => '404 File not found');
}

undef($CGI);
