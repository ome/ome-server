#!/usr/bin/perl -w

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;
use CGI;
use OME::DBObject;
use Log::Agent;                    # another more complex example
require Log::Agent::Driver::File;  # logging made to file
logconfig(
	-driver    => Log::Agent::Driver::File->make(
		-prefix      => 'serve.pl',
		-showpid     => 1,
# Until Log::Agent is used for all loging, we will be looking at multiple places for output
# for now, everything is going to STDERR
#		-channels    => {
#			 'error'  => '/OME/Logs/OME.err',
#			 'output' => '/OME/Logs/OME.out',
#			 'debug'  => '/OME/Logs/OME.dbg',
#		}
	),
# for now, debug output is on.
	-level    => 'debug'
);


# DBObject caching
OME::DBObject->Caching(1);
OME::DBObject->clearCache();

my $CGI = CGI->new();
my $pageClass = $CGI->url_param("Page");

if ($pageClass) {
	my $page;
	eval "use $pageClass";
	if ($@) {
		print STDERR "Error loading package - $@\n";
		print $CGI->header(-type => 'text/html',-status => "500 Internal Error" );
		print "Error loading package - $@\n";
		exit;
	}

	eval {
            if (!UNIVERSAL::isa($pageClass,"OME::Web")) {
                print STDERR "Package $pageClass does not inherit from OME::Web\n";
                print $CGI->header(-type => 'text/html',-status => "500 Internal Error");
                print "Package $pageClass does not inherit from OME::Web";
            } else {
		$page = $pageClass->new(CGI => $CGI);
		if (!$page) {
                    print STDERR "Error calling package constructor -\n";
                    print $CGI->header(-type => 'text/html',-status => "500 Internal Error" );
                    print "Error calling package constructor -\n";
		} else {
                    $page->serve();
		}
            }
	};
	
	if ($@) {
		print $CGI->header(-type => 'text/html');
		print "<pre>Error serving $pageClass:\n$@</pre>";
		print STDERR "Error serving $pageClass:\n$@\n";
	}
} else {
	print STDERR "Class not specified\n";
	
	print $CGI->header(-type => 'text/html',-status => '404 File not found');
	print "Class not specified\n";
}

undef($CGI);
