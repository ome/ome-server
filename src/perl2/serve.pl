#!/usr/bin/perl -w

# serve.pl

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    
#
#-------------------------------------------------------------------------------


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

use CGI::Carp;


# DBObject caching
OME::DBObject->Caching(1);
OME::DBObject->clearCache();

my $CGI = CGI->new();
my $pageClass = $CGI->url_param("Page");

if ($pageClass) {
	logdbg "debug", "Serving package - $pageClass.";
	my $page;
	eval "use $pageClass";
	if ($@) {
		carp "Error loading package - $@.";
		print $CGI->header(-type => 'text/html', -status => "500 Internal Error"),
		      "Error loading package - $@.";

		exit(1);
	};

# XXX This is Marinoh testing code *only* this should not be merged back into HEAD
#	eval {
#		if (not $pageClass->isa("OME::Web")) {
#			carp "Package $pageClass does not inherit from OME::Web.";
#			print $CGI->header(-type => 'text/html', -status => "500 Internal Error"),
#			      "Package $pageClass does not inherit from OME::Web.";
#		} else {
# XXX Uncomment this block before merging back into HEAD
			$page = $pageClass->new(CGI => $CGI);
			if (!$page) {
				carp "Error calling package constructor $pageClass->new().";
				print $CGI->header(-type => 'text/html', -status => "500 Internal Error"),
				      "Error calling package constructor $pageClass->new().";
			} else {
				$page->serve();
			}
#		}
#	};
	
	if ($@) {
		carp "Error serving $pageClass: ", $@ || "no error message available.";
		print $CGI->header(-type => 'text/html', -status => "500 Internal Error"),
		      "<pre>Error serving $pageClass: ", $@ || "no error message available.", "</pre>";

		exit(1);
	}
} else {
	carp "Page not specified.";
	
	print $CGI->header(-type => 'text/html',-status => '404 File not found'),
	      "Page not specified.";

	exit(1);
}

#undef($CGI);
