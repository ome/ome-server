#!/usr/bin/perl -w
# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
#
# Methods:
#	$sessionID = OME.Connect($user,$password)
#		Sets remoteAddr, user, password, dataSource in an Apache::Session::File
#		FIXME?:  All of the hash members above are stored in a file as clear text.  The file is chmod 700 and owned by nobody.
#		Authenticates user against database using $user and optionally $password parameters.
#		Should be able to call this parameterless and do the authentication with X.509 certificates retreived from an https call.
#		Cleans up stale session IDs.
#		Returns the session ID as a string.
#
#	@files = OME.GetFileList ($sessionID, $path)
#		Returns an array of structs - The struct has these members:
#			'Name' => A string with the name of the file (no path at all).
#			'isDirectory' => A boolean (0 or 1).
#		The array is sorted by Name in a non-case sensitive way.
#		Returns a fault if can't open $path.
#		FIXME?:  $path should be absolute, but doesn't check.
#		
#	OME.GetEnvironment($sessionID)
#		Returns the %ENV hash.
#
#	echo (*)
#		Returns the parameters as an array
#
#	OME.Disconnect ($sessionID)
#		Cleans up the Apache::Session::File
#
# Other:
#	CleanupSessions()
#		FIXME?:  finds stale sessions using `find /tmp/OMEsessions/ -amin +30`  prbably shouldn't be hard-coded.
#
#	$session = VerifySession ($sessionID)
#		Returns a reference to the tied Apache::Session hash upon success, dies otherwise.
#		This sub is called by all methods that take a $sessionID parameter.

use Frontier::RPC2;
use OMEpl;

use strict;

# FIXME:  Need to add authentication from an https call, or by passing a certificate, etc.
# Also, we should be able to call this with a session ID. This would re-authenticate and compare to the store for $sessionID.
# Eventually, we'll need to sotre everything we need to connect to the database.
# Storing the DB handle itself doesn't seem to work.
#  dbi:DriverName:dbname=database_name;host=hostname;port=port

# Login
# Get a sessionKey by passing a username and password.
# Note that this should be done with an https call, but this isn't enforced.
sub Login {
	my $user = shift;
	my $pass = shift;
	my $OME = OMEpl->new (user => $user, password => $pass);
	return ($OME->sessionKey());
}

# Connect
# Refresh the connection - get a session key using a session key.
# The new key isn't necessarily the same as the old key, but the passed key should ve valid.
sub Connect {
	my $sessionKey = shift;
	my $OME = OMEpl->new (sessionKey => $sessionKey);
	return ($OME->sessionKey());
}

# Finish
# Commit database transaction and set the session key as invalid.
sub Finish (){
	my $sessionKey = shift;
	my $OME = OMEpl->new (sessionKey => $sessionKey);
	return ($OME->Finish());
}

sub GetSelectedDatasets(){
	my $sessionKey = shift;
	my $OME = OMEpl->new (sessionKey => $sessionKey);
	return ($OME->GetSelectedDatasets());
}

sub SetSelectedDatasets(){
	my $sessionKey = shift;
	my $OME = OMEpl->new (sessionKey => $sessionKey);
	return ($OME->SetSelectedDatasets());
}

sub RegisterAnalysis(){
	my $sessionKey = shift;
	my $OME = OMEpl->new (sessionKey => $sessionKey);
	return ($OME->RegisterAnalysis());
}

sub GetFeatures (){
	my $sessionKey = shift;
	my ($featureFields,$featureDbMap) = @_;
	my $OME = OMEpl->new (sessionKey => $sessionKey);
	return ($OME->GetFeatures($featureFields,$featureDbMap));
}

sub WriteFeatures (){
	my $sessionKey = shift;
	my ($analysisID,$features,$featureDBmap) = @_;
	my $OME = OMEpl->new (sessionKey => $sessionKey);
	return ($OME->WriteFeatures($analysisID,$features,$featureDBmap));
}

sub GetFileList {
my $sessionKey = shift;
my $OME = OMEpl->new (sessionKey => $sessionKey);
my $directory = shift;
my ($fullPath,$file,@fileList,@fileStructs);

	opendir (DIR,$directory) or die "can't opendir $directory: $!\n";
	while (defined ($file = readdir (DIR)))
	{
		next if $file =~ /^\..*/; # No files begining with '.'
		push (@fileList,$file);
	}
	closedir (DIR);

	@fileList = sort {uc($a) cmp uc($b)} @fileList;

	foreach $file ( @fileList)
	{
		$fullPath = $directory."/".$file;
		push (@fileStructs,{
			'Name' => $file,
			'isDirectory' => Frontier::RPC2::Boolean->new( (-d $fullPath ? "1":"0") )
# The following don't work:
#			'isDirectory' => Frontier::RPC2::Boolean->new( (-d $fullPath) )
#			'isDirectory' =>  -d $fullPath ? 1:0
#			'isDirectory' =>  (-d $fullPath)
			})
	}

    return \@fileStructs;
}



sub echo {
    return [@_];
}


sub GetEnvironment {
my $sessionKey = shift;
my $OME = OMEpl->new (sessionKey => $sessionKey);
my %myEnv;
my ($key, $value);


	while ( ($key, $value) = each %ENV) {
        $myEnv{$key} = $value;
    };
	
	$myEnv{remoteAddr} = $OME->{remoteAddr};
	$myEnv{user} = $OME->{user};
    return {%myEnv};
}




    process_cgi_call({
		'OME.Login'   => \&Login,
		'OME.Connect'   => \&Connect,
		'OME.Finish'   => \&Finish,
		'OME.GetSelectedDatasets'   => \&GetSelectedDatasets,
		'OME.SetSelectedDatasets'   => \&SetSelectedDatasets,
		'OME.RegisterAnalysis'   => \&RegisterAnalysis,
		'OME.GetFeatures'   => \&GetFeatures,
		'OME.WriteFeatures'   => \&WriteFeatures,
		'OME.GetFileList'   => \&GetFileList,
		'OME.echo'   => \&echo,
		'OME.GetEnvironment'   => \&GetEnvironment
	});
    
    
    #==========================================================================
    #  CGI Support
    #==========================================================================
    #  Simple CGI support for Frontier::RPC2. You can copy this into your CGI
    #  scripts verbatim, or you can package it into a library.
    #  (Based on xmlrpc_cgi.c by Eric Kidd <http://xmlrpc-c.sourceforge.net/>.)
    
    # Process a CGI call.
    sub process_cgi_call ($) {
        my ($methods) = @_;
    
        # Get our CGI request information.
        my $method = $ENV{'REQUEST_METHOD'};
        my $type = $ENV{'CONTENT_TYPE'};
        my $length = $ENV{'CONTENT_LENGTH'};
    
        # Perform some sanity checks.
        http_error(405, "Method Not Allowed") unless $method eq "POST";
        http_error(400, "Bad Request") unless $type eq "text/xml";
        http_error(411, "Length Required") unless $length > 0;
    
        # Fetch our body.
        my $body;
        my $count = read STDIN, $body, $length;
        http_error(400, "Bad Request") unless $count == $length; 
    
        # Serve our request.
        my $coder = Frontier::RPC2->new;
        send_xml($coder->serve($body, $methods));
    }
    
    # Send an HTTP error and exit.
    sub http_error ($$) {
        my ($code, $message) = @_;
		print <<"EOD";
Status: $code $message
Content-type: text/html

<title>$code $message</title>
<h1>$code $message</h1>
<p>Unexpected error processing XML-RPC request.</p>
EOD
        exit 0;
    }
    
    # Send an XML document (but don't exit).
    sub send_xml () {
        my ($xml_string) = @_;
        my $length = length($xml_string);
        print <<"EOD";
Status: 200 OK
Content-type: text/xml
Content-length: $length

EOD
        # We want precise control over whitespace here.
        print $xml_string;
    }

