# OME/Web/DBObjDetail/__OME_Dataset.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjDetail::__OME_Dataset;

=pod

=head1 NAME

OME::Web::DBObjDetail::__OME_Dataset - Show detailed information on an Dataset

=head1 DESCRIPTION

Displays detailed information about a Dataset

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;

use CGI;
use Log::Agent;

use OME::Web::DBObjRender;
use OME::Web::DBObjTable;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web::DBObjDetail);

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	bless $self, $class;

	my $object = $self->_loadObject();
	$self->Session()->dataset( $object );
	$self->Session()->storeObject();
	$self->Session()->commitTransaction();
	
	return $self;
}

sub _takeAction {
	my $self = shift;
	my $object = $self->_loadObject();
	my $q = $self->CGI();

	if( $q->param( 'action' ) eq 'SaveChanges' ) {
		$object->description( $q->param( 'description' ) );
		$object->name( $q->param( 'name' ) );
		$object->storeObject();
		$self->Session()->commitTransaction();
	}
}


sub _tableDescriptor {
	my ($self, $object) = @_;
	my $tableDescriptor = $self->SUPER::_tableDescriptor( $object );
	my $q = $self->CGI();
	return $tableDescriptor.' | '.
		$q->a( {
			-href => "#",
			-onClick => "document.forms['".$self->{ form_name }."'].action.value='SaveChanges'; document.forms['".$self->{ form_name }."'].submit(); return false",
			}, 
			'Save Changes'
		);
}

sub _overrideRecord {
	my ($self, $record) = @_;
	my $object = $self->_loadObject();
	my $q = $self->CGI();
	
	$record->{'description'} = $q->textarea( {
			-name => 'description',
			-value => $object->description(),
			-rows => 5,
			-columns => 30,
		}
	);
	$record->{'name'} = $q->textfield( {
			-name => 'name',
			-value => $object->name(),
			-size => 30,
		}
	);
	return $record;
}

sub getFooter { 
	my $self = shift;
	my $object = $self->_loadObject();
	my $q = $self->CGI();
	# Relationship button
	return 
		$q->p() . 
		$q->table( {
				-class => 'ome_table',
				-align => 'center',
				-cellspacing => 1,
				-cellpadding => 4,
			},
			$q->Tr($q->td({style => 'background-color: #D1D7DC'}, $q->a( {
				class => 'ome_widget',
				href => "javascript:openRelationships('OME::Dataset', 'OME::Image', " . $object->id() . ");"
			}, 'Add/Remove Images'))),
		);
}
			
=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
