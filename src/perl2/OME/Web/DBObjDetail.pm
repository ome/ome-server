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

use strict;
use OME;
our $VERSION = $OME::VERSION;
use CGI;
use Log::Agent;
use OME::Web::DBObjTable;
use base qw(OME::Web);

=pod

=head1 NAME

OME::Web::DBObjDetail - Show detailed information on an object

=head1 DESCRIPTION

DBObjDetail displays detailed information on any DBObject or attribute.
It's default behaviors can be overridden by writing subclasses.

Important!! Subclasses should not be accessed directly. All access 
should go through DBObjDetail. Specialization is completely
transparent.

Subclasses follow the naming convention implemented in __specialize.
Subclasses may override one or more of the functions that indicate they
are Overridable.

=head1 METHODS

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	return $self;
}

=head2 getMenuText

If called from the Package, will return "DB Detail"
If called from an instance that has CGI parameters, will return the common name of the
object type followed by ' Detail'

Overridable.

=cut

sub getMenuText {
	my $self = shift;
	my $menuText = "DB Detail";
	return $menuText unless ref($self);

	my $specializedDetail;
	return $specializedDetail->getMenuText( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );
	return "$common_name Detail";
}

=head2 getPageTitle

Return the common name of the object type followed by that object's DBObjRender label

Overridable.

=cut

sub getPageTitle {
	my $self = shift;
	my $specializedDetail;
	return $specializedDetail->getPageTitle( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );
	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );
    return $self->Renderer()->getTitle($object, 'txt');
}

=head2 getPageBody

calls _takeAction() to allow subclasses to respond to form actions
also composites the html by calling doLayout() with the results of getObjDetail(),
getListsOfRelations(), getTablesOfRelations(). All of this gets
embedded in a form.

Strongly consider overriding the methods getPageBody uses instead of getPageBody. It
could save you some work and reduces the possibility of bugs creeping in.

Any subclass that overrides this method is expected to insert the
following lines inside a form in whatever they spit out. (If whatever
they spit out has forms)
	$q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	$q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	$q->hidden({-name => 'action', -default => ''});
This ensures the object in question can be displayed after a form is submitted.

Overridable

=cut

sub getPageBody {
	my $self = shift;

	my $specializedDetail;
	return $specializedDetail->getPageBody( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	$self->_takeAction( );

	my $q = $self->CGI();
	my $object = $self->_loadObject();
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	my $html = $q->startform( { -name => $self->{ form_name } } ).
	           $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	           $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	           $q->hidden({-name => 'action', -default => ''});
	my $objDetail = $self->getObjDetail( $object );
	$html .= $objDetail;
	$html .= $q->endform();

	return ('HTML', $html);
}

=head2 doLayout

	$html = $self->doLayout($objDetail, \%relationLists, \%relationTables );

Lays out the display. Overridable.

=cut

sub doLayout {
	my ($self,$objDetail, $relationLists, $relationTables) = @_;
	my $q = $self->CGI();
	
	my (@col1, @col2, @col3, @col4);
	my @relation_list = ( $relationLists ? map( $relationLists->{$_}, sort( keys %$relationLists ) ): () );
	push( @col3, splice( @relation_list, 0, 2 ) );
	push( @col4, splice( @relation_list, 0, 2 ) );

	my $r = POSIX::ceil( scalar( @relation_list) / 4 );
	push( @col1, splice( @relation_list, 0, $r ) );
	push( @col2, splice( @relation_list, 0, $r ) );
	push( @col3, splice( @relation_list, 0, $r ) );
	push( @col4, splice( @relation_list, 0, $r ) );

	my $html = $q->table( {-width => '100%', -cellpadding => 10 },
		$q->Tr(
			$q->td(  { -colspan => '2', -width => '50%', -valign => 'top', -align => 'center'}, 
				$objDetail
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
	
	$html .= ( $relationTables ? 
		join( '', map( $relationTables->{$_}, sort( keys %$relationTables ) ) ) :
		'' );
	
	return $html;
}

=head2 _takeAction

virtual method. called by getPageBody before anything else. no
parameters (other than $self) are passed in. Override for custom
actions.

Overridable

=cut

sub _takeAction { 
# virtual method
}

=head2 getDBObjDetail

Called by getPageBody. uses OME::Web::DBObjRender services to construct
a detailed object description. Returns a table.

Uses _tableDescriptor() to make a table header. Specifically, it inserts
what is returned from _tableDescriptor in the first row of the table.
This row spans every column in the table.

Overridable

=cut

sub getObjDetail {
	my ($self, $object) = @_;

	my $specializedDetail;
	return $specializedDetail->getObjDetail( $object )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	return $self->Renderer()->render( $object, 'detail' );
}

=head2 getListsOfRelations

	my %relationLists = $self->getListsOfRelations( $object );

returns a hash of html tables, each describing a list of has-many or
many-to-many relationships the given object has. The hash is keyed by the
name of the relationship.

Do Not Override this method.
Override OME::Web::DBObjRender->getRelations() instead.

=cut

sub getListsOfRelations {
	my ($self, $object) = @_;
	my $q = $self->CGI();
	my %relations;
	my ($relations, $names) = $self->Renderer()->getRelations( $object ); 
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $q );
	while( @$relations and @$names ) {
		my ( $options, $type, $renderInstrs ) = @{ shift @$relations };
		my $name = shift @$names;
		$options->{ embedded_in_form } = $self->{ form_name };
		$options->{ anchor }           = $name;
		$relations{ $name } = $q->p( 
			$tableMaker->getList(  $options, $type, $renderInstrs ) );
	}
	return %relations;
}


=head2 getTablesOfRelations

	my %relationTables = $self->getTablesOfRelations( $object );

returns a hash of html tables, each describing a list of has-many or
many-to-many relationships the given object has. The hash is keyed by the
name of the relationship.

Do Not Override this method.
Override OME::Web::DBObjRender->getRelations() instead.

=cut

sub getTablesOfRelations {
	my ($self, $object) = @_;
	my $q = $self->CGI();
	my %relations;
	my ($relations, $names) = $self->Renderer()->getRelations( $object ); 
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $q );
	while( @$relations and @$names ) {
		my ( $options, $type, $renderInstrs ) = @{ shift @$relations };
		my $name = shift @$names;
		$options->{ embedded_in_form } = $self->{ form_name };
		$options->{ anchor }           = $name;
		$relations{ $name } = $q->p( 
			$tableMaker->getTable(  $options, $type, $renderInstrs ) );
	}
	return %relations;
}


=head2 _loadObject

	my $object = $self->_loadObject();

loads an object from CGI params. Should be used in favor of accessing
the CGI params directly.

DO NOT Override

=cut

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

DO NOT Override

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
	return $specializedPackage->new( CGI => $self->CGI(), form_name => $self->{ form_name } )
		unless $@ or ref( $self ) eq $specializedPackage;

	return undef;
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
