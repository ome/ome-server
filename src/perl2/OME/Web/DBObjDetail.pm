# OME/Web/ObjectDetail.pm

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


package OME::Web::ObjectDetail;

=pod

=head1 NAME

OME::Web::ObjectDetail - Show detailed information on an object

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
use OME::Web::RenderData;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION;
use base qw(OME::Web);

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	return $self;
}

sub getMenuBuilder { return undef }  # No menu

sub getHeaderBuilder { return undef }  # No header

sub getPageTitle {
	my $self = shift;
	my $q    = $self->CGI();
	my $id   = $q->param( 'ID' );
	my $type = $q->param( 'Type' )
		or die "Type not specified";
	$type = _getTypeName( $type );
    return "$type ($id)";
}

sub getPageBody {
	my $self = shift;
	my $q    = $self->CGI();
	my $factory = $self->Session()->Factory();
	
	my $type = $q->param( 'Type' )
		or die "Type not specified";
	my $id   = $q->param( 'ID' )
		or die "ID not specified";
	my $object;
	if( $type =~ s/^@// ) {
		$object = $factory->loadAttribute( $type, $id )
			or die "Could not load Attribute $type, id=$id";
	} else {
		$object = $factory->loadObject( $type, $id )
			or die "Could not load DBObject $type, id=$id";
	}

	my $type_name = _getTypeName($type);

	my $html;

	my @fieldNames = OME::Web::RenderData->getAllFieldNames( $object );
	my %labels  = OME::Web::RenderData->getFieldLabels( $object, \@fieldNames );
	my %record  = OME::Web::RenderData->renderSingle( $object, 'html', \@fieldNames );

	
	$html .= $q->table(
		$q->caption( $type_name ),
		map(
			$q->Tr( 
				$q->td( { align => 'left' }, $labels{ $_ } ),
				$q->td( { align => 'right' }, $record{ $_ } ) 
			),
			@fieldNames
		)
	);

	return ('HTML', $html);
}


sub _getTypeName {
	my $type = shift;
	$type =~ s/^@// or
	( $type =~ s/OME::// and $type =~ s/::/ /g );
	return $type;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
