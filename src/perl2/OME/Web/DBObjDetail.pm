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
use OME::Web::NewTable;

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
	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );
    return "$common_name: ".OME::Web::RenderData->getObjectLabel($object);
}


sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();

	print STDERR "cgi params are\n\t".join( "\n\t", map( $_." => ".$q->param( $_ ), $q->param() ) )."\n";
	my $object = $self->_loadObject();
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	my $html = "\n".$q->startform( { -name => $self->{ form_name } } ).
	           $self->_getObjectDetail( $object )."\n".
	           $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	           $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	           $q->hidden({-name => 'action', -default => ''});

	$html .= $self->_getRelatedTables( $object )
		unless $q->param( 'NoTables' );
	$html .= $q->endform();
	
	print STDERR "cgi params are\n\t".join( "\n\t", map( $_." => ".$q->param( $_ ), $q->param() ) )."\n";
	
	return ('HTML', $html);
}


sub _getObjectDetail {
	my ($self, $object) = @_;
	my $q = $self->CGI();

	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );

	my $table_label = 
		( $ST ?
			$q->a( { href => 'serve.pl?Page=OME::Web::ObjectDetail&Type=OME::SemanticType&ID='.$ST->id()},
				   $q->font( { class => 'ome_header_label' }, $common_name) ):
			$q->font( { class => 'ome_header_label' }, $common_name)
		).
		$q->font( { class => 'ome_header_label' }, ": ").
		$q->font( { class => 'ome_header_title' }, OME::Web::RenderData->getObjectLabel($object) );

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
	
	return $html;
}


sub _getRelatedTables {
	my ($self, $object) = @_;
	my $q = $self->CGI();
	
	my $html;

	# print tables for has many relations
	my $manyRefs = $object->getPublishedManyRefs(); 
	my $tableMaker = OME::Web::NewTable->new( CGI => $q );
	foreach my $accessor (keys %$manyRefs ) {
		my $type = $manyRefs->{ $accessor };
		my @objects = $object->$accessor();
		(my $table_name = $accessor ) =~ s/_/ /g;
		$table_name = uc( $table_name );
		$html .= $q->p( $tableMaker->getTable( 
			{
				title            => $table_name, 
				table_width      => '100%',
				embedded_in_form => $self->{ form_name },
				table_length     => 5
			}, 
			$type, 
			\@objects
		) );
	}

	return $html;
}

sub _loadObject {
	my $self = shift;
	return $self->{__object} if $self->{__object};
	
	my $q    = $self->CGI();
	my $factory = $self->Session()->Factory();
	
	my $type = $q->param( 'Type' )
		or die "Type not specified";
	my $id   = $q->param( 'ID' )
		or die "ID not specified";

	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
	if( $ST ) {
		$self->{__object} = $factory->loadAttribute( $ST, $id )
			or die "Could not load Attribute $common_name, id=$id";
	} else {
		$self->{__object} = $factory->loadObject( $type, $id )
			or die "Could not load DBObject $type, id=$id";
	}
	return $self->{__object};
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
