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
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
    return "$common_name ($id)";
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
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
	my $typeAttr;
	if( $ST ) {
		$object = $factory->loadAttribute( $ST, $id )
			or die "Could not load Attribute $common_name, id=$id";
	} else {
		$object = $factory->loadObject( $type, $id )
			or die "Could not load DBObject $type, id=$id";
	}

	my $table_name = $common_name."_TABLE";
	my $table_label = ( $ST ?
		$q->a( { href => 'serve.pl?Page=OME::Web::ObjectDetail&Type=OME::SemanticType&ID='.$ST->id() },
		       $common_name ) :
		$common_name
	);

	my $html;

	my @fieldNames = OME::Web::RenderData->getAllFieldNames( $object );
	my %labels  = OME::Web::RenderData->getFieldLabels( $object, \@fieldNames );
	my %record  = OME::Web::RenderData->renderSingle( $object, 'html', \@fieldNames );

	
	$html .= $q->table(
		$q->caption( $table_label ),
		map(
			$q->Tr( 
				$q->td( { align => 'left' }, $labels{ $_ } ),
				$q->td( { align => 'right' }, $record{ $_ } ) 
			),
			@fieldNames
		)
	);

#	my $hasMany = $package_name->getHasManyReferences();
#print STDERR "$package_name has many:\n\t".join(', ', keys %$hasMany)."\n";
	return ('HTML', $html);
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
