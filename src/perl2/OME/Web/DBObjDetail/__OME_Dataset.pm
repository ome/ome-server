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

OME::Web::DBObjDetail::__OME_Dataset

=head1 DESCRIPTION

Displays detailed information about a Dataset

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Log::Agent;
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


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
