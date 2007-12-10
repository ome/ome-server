# OME/Analysis/Engine/DistributedAnalysisEngineClient.pm

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
# Written by:   Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------

package OME::Analysis::Engine::DistributedAnalysisEngineClient;

=head1 NAME

OME::Analysis::Engine::DistributedAnalysisEngineClient - Perl interface reflecting 
	DistributedAnalysisEngineCGI.pl

=head1 SYNOPSIS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use English '-no_match_vars';
use Log::Agent;
use base qw(Class::Accessor Class::Data::Inheritable);

use URI;
use OME::Util::cURL;

our $SHOW_CALLS = 0; # $OME::MESSAGES{OMEIS_DEBUG};

use constant DEFAULT_REMOTE_URL =>
  URI->new('http://localhost/perl2/DistributedAnalysisEngineCGI.pl');
  
my $DistributedAnalysisEngineCGI_URL = DEFAULT_REMOTE_URL;
my $curl;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new();
    
    return $self;
}

=head2 useRemoteAnalysisEngine

	OME::Analysis::Engine::DistributedAnalysisEngineClient->useRemoteAnalysisEngine($url);

Causes the various methods to use the remote Analysis Engine.
The URL to the image server should be given as a parameter; if it is
not given, the DEFAULT_REMOTE_URL constant will be used.

=cut

sub useRemoteAnalysisEngine {
    my $proto = shift;
    my $url = shift || DEFAULT_REMOTE_URL;

    $url = URI->new($url) unless ref($url);
    die "Could not create a URI for the remote image server"
      unless defined($url) && UNIVERSAL::isa($url,"URI");

    $DistributedAnalysisEngineCGI_URL = $url;
}

=head2 RegisterWorker
	$worker_id = OME::Analysis::Engine::DistributedAnalysisEngineClient->
		RegisterWorker($url,$worker_pid);
=cut

sub RegisterWorker {
	my $proto = shift;
	my $url = shift;
	my $worker_pid = shift;
	
	my %params;
	
	$params{'Method'} = 'RegisterWorker';
	$params{'URL'} = $url;
	$params{'PID'} = $worker_pid;

	# return the Worker_ID
	my $result = $proto->__call(%params);
	chomp ($result);
	chomp ($result);
	return ($result);
}

=head2 UnregisterWorker
	OME::Analysis::Engine::DistributedAnalysisEngineClient->
		UnregisterWorker($worker_id);
=cut

sub UnregisterWorker {
	my $proto = shift;
	my $worker_id = shift;
	
	my %params;
	
	$params{'Method'} = 'UnregisterWorker';
	$params{'WorkerID'} = $worker_id;

	# return the Worker_ID
	my $result = $proto->__call(%params);
	chomp ($result);
	chomp ($result);
	return ($result);
}

=head2 FinishedJob
	OME::Analysis::Engine::DistributedAnalysisEngineClient->
		FinishedJob($worker_id);
=cut

sub FinishedJob {
	my $proto = shift;
	my $worker_id = shift;
	
	my %params;
	
	$params{'Method'} = 'FinishedJob';
	$params{'WorkerID'} = $worker_id;

	# return the Worker_ID
	my $result = $proto->__call(%params);
	chomp ($result);
	chomp ($result);
	return ($result);
}

=head2 useRemoteAnalysisEngine
	my ($nex, $DataSource, $DBUser, $DBPassword, $SessionKey) = 
		OME::Analysis::Engine::DistributedAnalysisEngineClient->
			GetJob($worker_id);
=cut

use constant NEW_JOB_REGEXP =>
  qr{NEX=(\d+)\015?\012DataSource=(.+)\015?\012DBUser=(\w+)\015?\012DBPassword=(\w*)\015?\012SessionKey=(\w+)\015?\012}s;

sub GetJob {
	my $proto = shift;
	my $worker_id = shift;
	
	my %params;
	
	$params{'Method'} = 'GetJob';
	$params{'WorkerID'} = $worker_id;

	# return the Worker_ID
	my $result = $proto->__call(%params);
	if ($result =~ NEW_JOB_REGEXP) {
		#	print "MEX=$1\n";
		#	print "DataSource=$2\n";
		#	print "DBUser=$3\n";
		#	print "DBPassword=$4\n";
		#	print "SessionKey=$5\n";
		return ($1,$2,$3,$4,$5);
	} else {
		return (undef,undef,undef,undef,undef);
	}
}


=head2 __call

	my $result = OME::Analysis::Engine::DistributedAnalysisEngineClient->__call(%params);

This method makes a call into the DistributedAnalysisEngineCGI.pl script.

=cut

sub __call {
    my $proto = shift;
    my %params = @_;

	foreach (keys %params) {
		delete $params{$_} unless defined $params{$_};
	}

	my $remote_ae_path = $DistributedAnalysisEngineCGI_URL;
	if ($SHOW_CALLS) {
		logdbg "debug", "Calling remote AnalysisEngine: $remote_ae_path";
		logdbg "debug", "  Params:";
		foreach (keys %params) {
			logdbg "debug", "    '$_' = '$params{$_}'";
		}
	}
	$curl = OME::Util::cURL->new() unless $curl;
	my $response = $curl->POST ($remote_ae_path,\%params);


	if ($curl->status() == 200) {
		return ($response);
	} else {
		croak "Failed to get a successful response from $remote_ae_path: $response:\n";
	}
}

1;

=head1 AUTHORS

=over

Tom Macura <tmacura@nih.gov>

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut