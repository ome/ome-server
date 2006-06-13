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
   if (! ($pageClass =~ m/^OME\:\:.*/)) {  # if pageClass doesn't start with "OME::"
      exit;
   }
   if ($pageClass =~ m/[&;`'\"|*?~<>^\(\)\[\]\{\}\$\n\r]/) {  # If pageClass contains any dangerous characters
      exit;
   }

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
# This block commented-out because the DB handle cleanup doesn't always happen correctly
# There is also the possibility of not processing the SIGALRM correctly by certain drivers.
#				my $timeout = $CGI->url_param("Timeout");
#				$timeout = $page->timeout() unless $timeout;
#				if ($timeout) {
#					# Added timeout handling for user-initiated queries
#					# Timeoout can be passed as a CGI parameter
#					# timeout() defined as 0 (none) by Web.pm
#					# timeout() set to 30 by DBObjTable (first use)
#					# This code from:
#					# http://perl.apache.org/docs/2.0/user/coding/coding.html#Using_Signal_Handlers
#					use POSIX qw(SIGALRM);
#					my $mask      = POSIX::SigSet->new( SIGALRM );
#					my $action    = POSIX::SigAction->new(sub { die "Timeout Exceeded ($timeout s)" }, $mask);
#					my $oldaction = POSIX::SigAction->new();
#					POSIX::sigaction(SIGALRM, $action, $oldaction );
#					eval {
#						alarm ($timeout);
#						$page->serve();
#						alarm 0;
#					};
#					alarm 0;
#					POSIX::sigaction(SIGALRM, $oldaction); # restore original
#					die $@ if $@; # Propagate the error if any
#				} else {
#					$page->serve();
#				}
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

# Free the session's resources.
OME::Session->idle();

#undef($CGI);
