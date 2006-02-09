#!/usr/bin/perl

#-------------------------------------------------------------------------------
#
# Copyright (C) 2004 Open Microscopy Environment
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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#-------------------------------------------------------------------------------

use strict;

use LWP::UserAgent;
use HTTP::Request;
use Getopt::Long;

my $uname;
my $password;
my $host="localhost";
my $help;

GetOptions("name|n=s" => \$uname, "pass|p=s"=>
	   \$password,"host:s"=>\$host,"help|h"=>\$help);

if ($help) {
    &usage;
    exit;
}

my $request = "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n". 
    "<methodCall><methodName>createSession</methodName>\n" .
    "<params><param><value>$uname</value></param>\n". 
    "<param><value>$password</value></param></params>\n" .
    "</methodCall>";

my $url="http://$host/shoola";

my $ua = LWP::UserAgent->new;

my $req = HTTP::Request->new(POST =>$url);
#$req->content_type('application/x-www-form-urlencoded');
#$req->content_type('text/xml');
$req->content($request);

my $res = $ua->request($req);


if (!($res->is_success)) {
    print "\n\nRequest Failed: response is \n";
    print "\t\t " . $res->status_line . "\n";
    exit 0;
}

my $response = $res->content;

if ($response =~ m/<name>faultString<\/name><value><string>([^<].*)<\/string>/s) 
    {
	print "XMLRPC worked, but some error was found:";
	if ($1 =~ m/INVALID LOGIN/s) {
	    print "User name and/or password was invalid\n";
	}
	else {
	    print "$1\n";
	}
    }

else {
    $response =~ /<string>([^<].*)<\/string>/;
    print "Login succeeded: Session key is $1\n";
}


sub usage {
    print  << "USAGE";

Usage:
    rpcTest.pl --name <username> --pass <password> [--host <hostName>]

    Tests the rpcServer at the given host by attempting to login with
    the given user name and password. Prints the session key if
    successful, or appropriate error feedback otherwise.

    The host will default to localhost.

USAGE
}
