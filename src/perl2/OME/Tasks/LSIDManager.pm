# OME/Tasks/HierarchyExport.pm
# This module is used for exporting a list of objects to an XML hierarchy governed by the OME-CA schema.

# Copyright (C) 2002 Open Microscopy Environment
# Author:  Ilya G. Goldberg <igg@nih.gov>
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
package OME::LSID;


=head1 NAME

OME::LSID - Generate LSIDs for OME objects

=head1 SYNOPSIS

	# Get a new or existing LSID for the given object
	my $resolver = new OME::LSID (session => $session);
	my $LSID = $resolver->getLSID ($object);
	my $object = $resolver->getObject ($LSID);

=head1 DESCRIPTION

This class has a single method - new with a single required parameter - an OME object.  If an LSID exists for the object, it is returned.
If it does not exist, it is created
=cut

use strict;
use Carp;
use Log::Agent;

our $AUTHORITY;
our $DB_INSTANCE;

sub new {
	my ($proto, %params) = @_;
	my $class = ref($proto) || $proto;

	my @fieldsILike = qw(session);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

	logdie "I need a session"
	  unless exists $self->{session} &&
			 UNIVERSAL::isa($self->{session},'OME::Session');

	if (not defined $AUTHORITY or not defined $DB_INSTANCE) {
    	my $config = $self->{session}->Factory()->loadObject("OME::Configuration", 1) or
    		logdie $class.'->new():  Could not get OME::Configuration';
    	$AUTHORITY = $config->lsid_authority();
    	$DB_INSTANCE = $config->db_instance();
    }

	return bless $self, $class;
}

sub getLSID ($) {
my ($self,$object) = @_;
	my $type;
	my $ref = ref ($object);

		if (UNIVERSAL::isa($object,"OME::AttributeType::Superclass") ) {
			$type = $object->attribute_type()->name();
		} elsif ($ref eq 'OME::Project') {
			$type = 'Project';
		} elsif ($ref eq 'OME::Dataset') {
			$type = 'Dataset';
		} elsif ($ref eq 'OME::Image') {
			$type = 'Image';
		} elsif ($ref eq 'OME::Feature') {
			$type = 'Feature';
		}
	return undef unless defined $type;
	
	return "urn:lsid:$AUTHORITY:$type:".$object->id().":$DB_INSTANCE";
}

sub getObject ($) {
my ($self,$lsid) = @_;
	return $self->getLocalObject ($lsid) || $self->getRemoteObject ($lsid);
}

sub checkLSID ($) {
my ($self,$lsid) = @_;
	my ($urn,$urnType,$authority,$namespace,$localID,$dbInstance) = split (/:/,$lsid);
	return undef unless defined $authority;
	return undef unless defined $urn and $urn eq 'urn';
	return undef unless defined $urnType and $urnType eq 'lsid';
	return undef unless defined $localID;
	return $lsid;
}

sub getLocalObject () {
	my $self = shift;
	my $lsid = $self->checkLSID (shift) || return undef;

	my ($urn,$urnType,$authority,$namespace,$localID,$dbInstance) = split (/:/,$lsid);
	
# FIXME:  This should return a locally stored object even if its got a different authority.
	return undef unless defined $authority and $authority eq $AUTHORITY;
	return undef unless defined $dbInstance and $dbInstance eq $DB_INSTANCE;

	if ($namespace eq 'Project') {
		return $self->{session}->Factory()->loadObject('OME::Project', $localID);
	} elsif ($namespace eq 'Dataset') {
		return $self->{session}->Factory()->loadObject('OME::Dataset', $localID);
	} elsif ($namespace eq 'Image') {
		return $self->{session}->Factory()->loadObject('OME::Image', $localID);
	} elsif ($namespace eq 'Feature') {
		return $self->{session}->Factory()->loadObject('OME::Feature', $localID);
	} else {
		return $self->{session}->Factory()->loadAttribute($namespace, $localID);
	}
}

# FIXME:  This could use a little implementation.
sub getRemoteObject ($) {
my ($self,$lsid) = @_;
	my $self = shift;
	my $lsid = checkLSID (shift) || return undef;

	my ($urn,$urnType,$authority,$namespace,$localID,$dbInstance) = split (/:/,$lsid);

	return undef;
}

1;