# OME/Web/DBObjDetail.pm

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


package OME::Web::DBObjDetail;

=pod

=head1 NAME

OME::Web::DBObjDetail - Show detailed information on an object

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

{

my $menuText = "DB Detail";
sub getMenuText {
	my $self = shift;
	return $menuText unless ref($self);

	my $specializedDetail;
	return $specializedDetail->getMenuText( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );
	return "$common_name Detail";
}
}

#sub getMenuBuilder { return undef }  # No menu

#sub getHeaderBuilder { return undef }  # No header

sub getPageTitle {
	my $self = shift;
	my $specializedDetail;
	return $specializedDetail->getPageTitle( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );
	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );
    return "$common_name: ".OME::Web::DBObjRender->getObjectLabel($object);
}


sub getPageBody {
	my $self = shift;

	my $specializedDetail;
	return $specializedDetail->getPageBody( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

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

	$self->_takeAction( );

	return ('HTML', $html);
}

sub _takeAction { 
# virtual method
}

sub _getDBObjDetail {
	my ($self, $object) = @_;

	my $specializedDetail;
	return $specializedDetail->_getDBObjDetail( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	my $q = $self->CGI();

	my $table_label = $q->font( { -class => 'ome_header_title' },
		OME::Web::DBObjRender->getObjectLabel($object) );

	my $obj_table;

	my @fieldNames = OME::Web::DBObjRender->getAllFieldNames( $object );
	my %labels  = OME::Web::DBObjRender->getFieldLabels( $object, \@fieldNames, 'html' );
	my %record  = OME::Web::DBObjRender->renderSingle( $object, 'html', \@fieldNames );

	%record = %{ $self->_overrideRecord( \%record ) };

	$obj_table .= $q->table( { -class => 'ome_table' },
		$q->caption( $table_label ),
		$q->Tr(
			# table descriptor
			$q->td( { -class => 'ome_td', -align => 'right', -colspan => 2 }, 
				$self->_tableDescriptor( $object )
			), 
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

sub _tableDescriptor {
	my ($self, $object) = @_;
	my $q = $self->CGI();

	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );

	my $display_type = "Displaying ".
		( $ST ?
			$q->a( { href => 'serve.pl?Page=OME::Web::DBObjDetail&Type=OME::SemanticType&ID='.$ST->id() },
				   $common_name ) :
			$common_name
		);

	return $q->span( { -class => 'ome_widget' }, $display_type )
}

sub _overrideRecord { 
	my ($self, $record) = @_;
	return $record;
}


sub _getManyRelations {
	my ($self, $object) = @_;

	my $specializedDetail;
	return $specializedDetail->_getManyRelations( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	my $q = $self->CGI();
	
	my @relations;

	# print tables for has many relations
	my $iter = OME::Web::DBObjRender->getRelationAccessors( $object ); 
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $q );
	if( $iter->first() ) { do {
		my $type = $iter->return_type();
		my $objects = $iter->getList();
		my $table_name = $iter->name();
		push( @relations, $q->p( $tableMaker->getList( 
			{
				title            => $table_name, 
				embedded_in_form => $self->{ form_name },
				Length           => 5,
				width            => '100%'
			}, 
			$type, 
			$objects
		) ) );
	} while( $iter->next() ); }
	
	return @relations;
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
	$self->{__object} = $factory->loadObject( $formal_name, $id )
		or die "Could not load DBObject $type, id=$id";
	return $self->{__object};
}

=head2 __specialize

	my $specializedPackage = $self->__specialize();
	
returns a specialized package (if one exists) for displaying a
DBObject or Attribute in detail.
returns undef if a specialized prototype does not exist or if it was
called with with a specialized prototype.

=cut

sub __specialize {
	my $self = shift;
	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = 
		$self->_loadTypeAndGetInfo( $object );

	# construct specialized package name
	my $specializedPackage = $formal_name;
	($specializedPackage =~ s/::/_/g or $specializedPackage =~ s/@//);
	$specializedPackage = "OME::Web::DBObjDetail::__".$specializedPackage;

	# obtain package
	eval( "use $specializedPackage" );
	return $specializedPackage->new( CGI => $self->CGI() )
		unless $@ or ref( $self ) eq $specializedPackage;

	return undef;
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
