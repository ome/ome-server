# OME/Tasks/LSIDManager.pm
# This module is used for exporting a list of objects to an XML hierarchy governed by the OME-CA schema.

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
# Written by:    Ilya G. Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Tasks::LSIDManager;


=head1 NAME

OME::Tasks::LSIDManager - Generate LSIDs for OME objects

=head1 SYNOPSIS

	# Get a new or existing LSID for the given object
	my $resolver = new OME::Tasks::LSIDManager (session => $session);
	my $LSID = $resolver->getLSID ($object);
	my $object = $resolver->getObject ($LSID);
	my $object = $resolver->getLocalObject ($LSID);

=head1 DESCRIPTION

This class is used to convert objects to LSIDs and LSIDs into objects. LSIDs are used as GUIDs at the moment, but are URNs and will be supported as such in the future. For more info on LSIDs and URNs, google it up. An explanation of them is out of scope of this manual.

=cut

use strict;
use Carp;
use Log::Agent;
use OME::LSID;

our $AUTHORITY;
our $DB_INSTANCE;

=head1 METHODS

=head2 new

	my $resolver = new OME::Tasks::LSIDManager (session => $session);

This makes a new LSID resolver.  The session parameter is required.

=cut

sub new {
	my ($proto, %params) = @_;
	my $class = ref($proto) || $proto;

	my @fieldsILike = qw(session);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

	if (not defined $AUTHORITY or not defined $DB_INSTANCE) {
    	my $config = OME::Session->instance()->Configuration() or
    		logdie $class.'->new():  Could not get Configuration';
    	$AUTHORITY = $config->lsid_authority();
    	$DB_INSTANCE = $config->db_instance();
    }

	return bless $self, $class;
}

=head2 getLSID

	my $LSID = $resolver->getLSID ($object);

This returns an LSID for the given $object.

=cut

sub getLSID ($) {
my ($self,$object) = @_;
	my $type;
	my $ref = ref ($object);

		if (UNIVERSAL::isa($object,"OME::SemanticType::Superclass") ) {
			$type = $object->semantic_type()->name();
		} elsif ($ref eq 'OME::Project') {
			$type = 'Project';
		} elsif ($ref eq 'OME::Dataset') {
			$type = 'Dataset';
		} elsif ($ref eq 'OME::Image') {
			$type = 'Image';
		} elsif ($ref eq 'OME::Feature') {
			$type = 'Feature';
		} elsif ($ref eq 'OME::Module') {
			$type = 'Module';
		} elsif ($ref eq 'OME::ModuleExecution') {
			$type = 'ModuleExecution';
		} elsif ($ref eq 'OME::SemanticType') {
			$type = 'SemanticType';
		}
	
	return undef unless defined $type;
	
	my @lsid_list = OME::Session->instance()->Factory()->findObjects ( "OME::LSID", {
		object_id => $object->id(),
		namespace => $type });
	return $lsid_list[0]->lsid() if scalar @lsid_list > 0;
	
	my $LSIDstring = "urn:lsid:$AUTHORITY:$type:".$object->id().":$DB_INSTANCE";
	
	$self->setLSID( $object, $LSIDstring );
	
	return $LSIDstring;
}



=head2 setLSID

	$resolver->setLSID ($object, $LSID);

This sets the LSID for the given object.

=cut

sub setLSID ($$) {
my ($self,$object,$LSIDstring) = @_;

	return undef unless $self->checkLSID( $LSIDstring );

	my (undef, undef, undef, $type, undef, undef ) = split( /:/, $LSIDstring );
	my $lsid = OME::Session->instance()->Factory()->newObject( "OME::LSID", { 
		lsid      => $LSIDstring,
		object_id => $object->id(),
		namespace => $type } );
#	$lsid->storeObject();
	
	return $lsid;
}


=head2 getObject

	my $object = $resolver->getObject ($LSID);

This returns an OME object with the given $LSID, or undef if there is no object matching that LSID.
Initially, this method calls C<getLocalObject()> to attempt to resolve this LSID locally.
If that fails, this method calls C<getRemoteObject()>.  If that fails, undef is returned.

=cut

sub getObject ($) {
my ($self,$lsid) = @_;

	return $self->getLocalObject ($lsid) || $self->getRemoteObject ($lsid);
}

=head2 checkLSID

	if( $resolver->checkLSID ($LSID) ) {
		# do something
	}

This determines if an LSID is properly formed. Returns undef if not, $LSID if so.

=cut

sub checkLSID ($) {
my ($self,$lsid) = @_;
	my ($urn,$urnType,$authority,$namespace,$localID,$dbInstance) = split (/:/,$lsid);
	return undef unless defined $authority;
	return undef unless defined $urn and $urn eq 'urn';
	return undef unless defined $urnType and $urnType eq 'lsid';
	return undef unless defined $localID;
	return $lsid;
}


=head2 getLocalObject

	my $object = $resolver->getLocalObject ($LSID);

This returns a localy stored OME object with the given $LSID, or undef if there is no object matching that LSID in the DB.

=cut

sub getLocalObject () {
	my $self = shift;
	my $lsid = $self->checkLSID (shift) || return undef;
    my $factory = OME::Session->instance()->Factory();

	my ($urn,$urnType,$authority,$namespace,$localID,$dbInstance) = split (/:/,$lsid);
	
# FIXME:  This should return a locally stored object even if its got a different authority.
	my $lsid_map = $factory->findObject('OME::LSID', lsid => $lsid );
	unless ($lsid_map) {
		return undef unless defined $authority and $authority eq $AUTHORITY;
		return undef unless defined $dbInstance and $dbInstance eq $DB_INSTANCE;
	} else {
		$localID = $lsid_map->object_id();
	}

	if ($namespace eq 'Project') {
		return $factory->loadObject('OME::Project', $localID);
	} elsif ($namespace eq 'Dataset') {
		return $factory->loadObject('OME::Dataset', $localID);
	} elsif ($namespace eq 'Image') {
		return $factory->loadObject('OME::Image', $localID);
	} elsif ($namespace eq 'Feature') {
		return $factory->loadObject('OME::Feature', $localID);
	} elsif ($namespace eq 'Module') {
		return $factory->loadObject('OME::Module', $localID);
	} elsif ($namespace eq 'ModuleExecution') {
		return $factory->loadObject('OME::ModuleExecution', $localID);
	} elsif ($namespace eq 'SemanticType') {
		return $factory->loadObject('OME::SemanticType', $localID);
	} else {
		return $factory->loadAttribute($namespace, $localID);
	}
}


=head2 getLocalID
	my $object = $resolver->getLocalID ($LSID);

This returns the id of a localy stored OME object with the given $LSID, or undef if there is no object matching that LSID in the DB.

=cut

sub getLocalID () {
	my $self = shift;
	my $lsid = $self->checkLSID (shift) || return undef;

	my $lsid_map = OME::Session->instance()->Factory()->
      findObject('OME::LSID', lsid => $lsid );
	return undef unless $lsid_map;
	return $lsid_map->object_id();
}



=head2 getRemoteObject

	my $object = $resolver->getRemoteObject ($LSID);

This returns an OME object with the given $LSID from a remote authority, or undef on failure.
Note that as of this writing, this method is not implemented.

=cut


# FIXME:  This could use a little implementation.
sub getRemoteObject ($) {
	carp ("OME::Tasks::LSIDManager::getRemoteObject() is not implemented.");
	my $self = shift;
	my $lsid = checkLSID (shift) || return undef;

	my ($urn,$urnType,$authority,$namespace,$localID,$dbInstance) = split (/:/,$lsid);

	return undef;
}



=pod

=head1 AUTHOR

Ilya Goldberg (igg@nih.gov)

=cut


1;
