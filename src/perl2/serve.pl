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
use OME;
our $VERSION = $OME::VERSION;
# IGG 1/19/06: Emiting xhtml confuses things - we're not compliant with xhtml transitional 1.0
use CGI qw/-no_xhtml/;
use OME::DBObject;
use Log::Agent;
use OME::Tasks::NotificationManager;

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

	eval {
		if (not $pageClass->isa("OME::Web")) {
			carp "Package $pageClass does not inherit from OME::Web.";
			print $CGI->header(-type => 'text/html', -status => "500 Internal Error"),
			      "Package $pageClass does not inherit from OME::Web.";
		} else {
			$page = $pageClass->new(CGI => $CGI);
			if (!$page) {
				carp "Error calling package constructor $pageClass->new().";
				print $CGI->header(-type => 'text/html', -status => "500 Internal Error"),
				      "Error calling package constructor $pageClass->new().";
			} else {
				$page->serve();
			}
		}
	};
	
	if ($@) {
		my $error = $@;
		carp "Error serving $pageClass: ", $error || "no error message available.";
		print $CGI->header(-type => 'text/html', -status => "500 Internal Error"),
		      "<pre>Error serving $pageClass: ", $error || "no error message available.", "</pre>";
		my @tasks = OME::Tasks::NotificationManager->list(process_id => $$);
		foreach (@tasks) {
			$_->died ($error || "no error message available.");
		}

		exit(1);
	}
} else {
	carp "Page not specified.";
	
	print $CGI->header(-type => 'text/html',-status => '404 File not found'),
	      "Page not specified.";

	exit(1);
}
OME::Session->instance()->idle();

#undef($CGI);
