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

=head2 getDBObjDetail

Makes a table with less whitespace.

=cut

sub getObjDetail {
	my ($self, $object) = @_;

	my $specializedDetail;
	return $specializedDetail->getObjDetail( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	my $q = $self->CGI();

	my $title = $q->font( { -class => 'ome_header_title' },
		OME::Web::DBObjRender->getObjectTitle($object, 'html') );

	my @fieldNames = OME::Web::DBObjRender->getAllFieldNames( $object );
	my %labels  = OME::Web::DBObjRender->getFieldLabels( $object, \@fieldNames, 'html' );
	my %record  = OME::Web::DBObjRender->renderSingle( $object, 'html', \@fieldNames );
	%record = %{ $self->_overrideRecord( \%record ) };

	my $detail .= $q->table( 
		$q->Tr( [
			$q->td( { -align => 'left' },
				$title 
			),
			$q->td( { -align => 'left' },
				join( ', ', map( 
					$q->span( $labels{ $_ }.': ' ).$record{ $_ },
					grep( !m/name|description/, @fieldNames )
				) )
			)
		]
		),
		$q->Tr( 
			$q->td( { -align => 'left'},
				"Name ".$q->textfield( {
						-name => 'name',
						-value => $object->name(),
						-size => 30,
					}
				)
			),
		),
		$q->Tr( 
			$q->td( { -align => 'left'}, 
				"Description"
			)
		),
		$q->Tr(
			$q->td( { -align => 'left' },
				$q->textarea( {
					-name => 'description',
					-value => $object->description(),
					-rows => 3,
					-columns => 50,
				} )
			)
		),
		$q->Tr(
			$q->td( { -align => 'right'}, $q->table( 
				{
					-class => 'ome_table',
					-cellpadding => 3,
				},
				$q->Tr($q->td({style => 'background-color: #D1D7DC'}, 
					$q->a( {
						class => 'ome_widget',
						href => "javascript:document.forms['".$self->{ form_name }."'].action.value='SaveChanges'; document.forms['".$self->{ form_name }."'].submit(); return false;",
					}, 'Save Changes').' | '.
					$q->a( {
						class => 'ome_widget',
						href => "javascript:openRelationships('OME::Dataset', 'OME::Image', " . $object->id() . ");"
					}, 'Add/Remove Images')
				) )
			) )
		)
	);
	
	return $detail;
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


=head2 doLayout

shift layout around

=cut

sub doLayout {
	my ($self,$objDetail, $relationLists, $relationTables) = @_;
	my $q = $self->CGI();

	my $html = 
		$q->table( { -width => '100%', -cellpadding => 5 },
			$q->Tr( 
				$q->td( { -width => '50%', -valign => 'top'}, 
					$objDetail.
					$relationLists->{projects}.
					$relationLists->{module_executions}
				),
				
				$q->td( { -width => '25%', -valign => 'top' }, 
					$relationLists->{images} 
				)
			),
		).
		$relationTables->{projects}.
		$relationTables->{images}.
		$relationTables->{module_executions};
		
	
	return $html;
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

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
