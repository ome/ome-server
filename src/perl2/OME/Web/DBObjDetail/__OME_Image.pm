# OME/Web/DBObjDetail/__OME_Image.pm

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


package OME::Web::DBObjDetail::__OME_Image;

=pod

=head1 NAME

OME::Web::DBObjDetail::__OME_Image - Show detailed information on an Image

=head1 DESCRIPTION

Displays detailed information on any DBObject or attribute.

=cut

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Log::Agent;

use OME;
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

	return $self;
}

sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();

	my $object = $self->_loadObject();
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	my $html = $q->startform( { -name => $self->{ form_name } } ).
	           $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	           $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	           $q->hidden({-name => 'action', -default => ''});

	my @relations = $self->_getManyRelations( $object );
	my (@col1, @col2, @col3, @col4);
	
	push( @col3, splice( @relations, 0, 2 ) );
	push( @col4, splice( @relations, 0, 2 ) );

	my $r = POSIX::ceil( scalar( @relations) / 4 );
	push( @col1, splice( @relations, 0, $r ) );
	push( @col2, splice( @relations, 0, $r ) );
	push( @col3, splice( @relations, 0, $r ) );
	push( @col4, splice( @relations, 0, $r ) );

	$html .= $q->table( {-width => '100%', -cellpadding => 10 },
		$q->Tr(
			$q->td(  { -colspan => '2', -width => '50%', -valign => 'top', -align => 'center'}, 
				$self->_getDBObjDetail( $object )
			),
			$q->td(  { -rowspan => '2', -width => '25%', -valign => 'top', -align => 'right' }, [
				join( '', @col3 ),
				join( '', @col4 ),
			] )
		),
		$q->Tr( $q->td(  { -width => '25%', -valign => 'top', -align => 'right' }, [
			join( '', @col1 ),
			join( '', @col2 ),
		] ) )
	);

	$html .= $q->endform();
	
	if( $q->param( 'action' ) eq 'SaveChanges' ) {
		$object->description( $q->param( 'description' ) );
		$object->storeObject();
		$self->Session()->commitTransaction();
	}
		
	return ('HTML', $html);
}


sub _getDBObjDetail {
	my ($self, $object) = @_;
	my $q = $self->CGI();

	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );

	my $display_type = "Displaying Image";
	my $table_label = $q->font( { -class => 'ome_header_title' },
		OME::Web::DBObjRender->getObjectLabel($object) );

	my $obj_table;

	my @fieldNames = OME::Web::DBObjRender->getAllFieldNames( $object );
	my %labels  = OME::Web::DBObjRender->getFieldLabels( $object, \@fieldNames );
	my %record  = OME::Web::DBObjRender->renderSingle( $object, 'html', \@fieldNames );

	$record{description} = $q->textarea( {
			-name => 'description',
			-value => $object->description(),
			-rows => 5,
			-columns => 30,
		}
	);
	
	$obj_table .= $q->table( { -class => 'ome_table' },
		$q->caption( $table_label ),
		$q->Tr(
			# table descriptor
			$q->td( { -class => 'ome_td', -align => 'right', -colspan => 2 }, join( ' | ', (
				$q->span( { -class => 'ome_widget' }, $display_type ),
				$q->a( {
					-href => "#",
					-onClick => "document.forms['".$self->{ form_name }."'].action.value='SaveChanges'; document.forms['".$self->{ form_name }."'].submit(); return false",
					}, 
					'Save Changes'
				)
			) ) ), 
		),
		map(
			$q->Tr( 
				$q->td( { -class => 'ome_td', -align => 'left', -valign => 'top' }, $labels{ $_ } ),
				$q->td( { -class => 'ome_td', -align => 'right', -valign => 'top' }, $record{ $_ } ) 
			),
			@fieldNames
		)
	);
	
	return $obj_table;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
