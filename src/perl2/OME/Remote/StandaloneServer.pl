#!/usr/bin/perl

# OME/Remote/StandaloneServer.pl

# Copyright (C) 2003 Open Microscopy Environment
# Author:  
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

use warnings;
use strict;
use SOAP::Lite;
use XMLRPC::Lite;
use Getopt::Long;
use POSIX;

# We'd rather not have tracing right now :)
#SOAP::Trace->import('all');

use OME::Remote::Dispatcher;
my @dispatchObjects =
  qw(OME::Remote::Dispatcher);

use SOAP::Transport::HTTP;
use XMLRPC::Transport::HTTP;
$SOAP::Constants::DO_NOT_USE_XML_PARSER = 1;
$XMLRPC::Constants::DO_NOT_USE_XML_PARSER = 1;

#*********
#********* GLOBALS AND DEFINES
#*********

# Command line options
my ($show_calls, $show_results, $show_caching, $verbose, $help, $debug);

# Command line defaults
my $port = 8002;
my $transport = "soap";

#*********
#********* LOCAL SUBROUTINES
#*********

sub usage {
    my $usage = <<USAGE;
OME Standalone server, which implements the OME Remote API via XMLRPC or SOAP.

Usage:
  $0 [options]

Options:
  -s, --show-calls		Show the remote framework calls
  -e, --show-results		Show the result of remote framework calls
  -c, --show-caching		Show caching being done by the server
  -p, --port			Listening port

  -d, --debug			Do not release the controlling terminal (follow
				output from the daemon [sets --verbose])
  -v, --verbose			Verbose output (same as -s,-e,-c)
  -h, --help			This message

Transport options:
  -t, --transport <xmlrpc,soap>	Use either an XMLRPC or SOAP transport

Report bugs to <ome-devel\@mit.edu>.
USAGE

	print STDOUT $usage;
	exit (0);
}

#*********
#********* START OF CODE
#*********


# CLI flag logic

GetOptions ("s|show-calls", \$show_calls,	# Show call generation
	    "d|show-results", \$show_results,	# Show call results
	    "n|show-caching", \$show_caching,	# Show server caching
	    "p|port=s", \$port,			# Listening port
	    "d|debug", \$debug,			# Debug mode
	    "v|verbose", \$verbose,		# Verbose operation
	    "t|transport=s", \$transport,	# Transport
	    "h|help", \$help			# Show usage
	    );

if ($help) { usage () }

if ((lc($transport) ne "xmlrpc") && (lc($transport) ne "soap") ) {
    print "Unknown transport: $transport\n";
    usage ();
}

if ($debug) { $verbose = 1 }
if ($verbose) { $show_calls = 1; $show_results = 1; $show_caching = 1; }
if ($show_calls) { $OME::Remote::Dispatcher::SHOW_CALLS = 1 }
if ($show_results) { $OME::Remote::Dispatcher::SHOW_RESULTS = 1 } 
if ($show_caching) { $OME::Remote::Dispatcher::SHOW_CACHING = 1 }

# Fork once so that the parent can exit unless we're debugging
unless ($debug) {
    # Okay we're not debugging lets fork
    my $pid = fork;
    exit if $pid;
    die "Couldn't fork. $!" unless defined ($pid);

    # Start a new session so we loose our controling terminal
    POSIX::setsid () or die "Can't start a new session. $!";
}

# Ignore SIGPIPE
$SIG{PIPE} = 'IGNORE';

# Let everyone know which Dispatcher we're using
if ($debug) {  # FIXME: This is brain-dead, should use a proper output chooser
    print "Using dispatch objects...\n  \\_ ", join("\n  \\_ ",@dispatchObjects), "\n";
}

my ($transport_class, $style, $daemon);

if (lc($transport) eq "xmlrpc") {
    $transport_class = "XMLRPC::Transport::HTTP::Daemon";

    # Dispatch all method calls to the dispatcher
    # all is "" in dispatch_with()
    $daemon = $transport_class
      ->new(LocalPort => $port)
      ->dispatch_to('OME::Remote::Dispatcher')		
      ->dispatch_with({"", 'OME::Remote::Dispatcher'});
    $style = "XML-RPC";
} elsif (lc($transport) eq "soap") {
    $transport_class = "SOAP::Transport::HTTP::Daemon";

    # Just dispatch the method calls to @dispatchObjects
    $daemon = $transport_class
      ->new(LocalPort => $port)
      ->dispatch_to(@dispatchObjects);
    $style = "SOAP";
} else { 
    die "Woah! Unknown transport type.";
}

#$daemon->on_action(sub { print "A***(",join(',',@_),")\n"; });
#$daemon->on_dispatch(sub { print "D***(",join(',',@_),")\n"; });

if ($debug) {  # FIXME: See previous if ($debug)
    print "Connect to $style server at ", $daemon->url(), ".\n";
}
$daemon->handle();
