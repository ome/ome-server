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
use OME::Web::DBObjRender;
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
Subclasses may override one or more of the functions
getMenuText, getPageTitle, getPageBody, _takeAction, getFooter,
_getDBObjDetail, _tableDescriptor, _overrideRecord, _getManyRelations

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
Otherwise, will return the common name of the object type followed by ' Detail'

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

#sub getMenuBuilder { return undef }  # No menu

#sub getHeaderBuilder { return undef }  # No header

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
    return "$common_name: ".OME::Web::DBObjRender->getObjectLabel($object);
}

=head2 getPageBody

calls _takeAction()
prints results of _getDBObjDetail(), _getManyRelations_getManyRelations(
$object ), and getFooter(). All this stuff gets embedded in a form.

If the formatting is acceptable, consider overriding the methods
getPageBody uses instead of getPageBody. It could save you some work and
reduces the possibility of bugs creeping in.

Any subclass that overrides this method is expected to insert the
following lines inside a form in whatever they spit out. (If whatever
they spit out has forms)

	$q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	$q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	$q->hidden({-name => 'action', -default => ''});

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

	$html .= $self->getFooter();

	$html .= $q->endform();

	return ('HTML', $html);
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

=head2 getFooter

virtual method. Override to put a footer on the resultant page. Called
by getPageBody.

Overridable

=cut

sub getFooter { 
# virtual method
}

=head2 _getDBObjDetail

Called by getPageBody. uses OME::Web::DBObjRender services to construct
a detailed object description. Returns a table.

Uses _tableDescriptor() to make a table header. Specifically, it inserts
what is returned from _tableDescriptor in the first row of the table.
This row spans every column in the table.

Overridable

=cut

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

=head2 _tableDescriptor

Called by _getDBObjDetail. Indicates the type of object being displayed.
If the object is a SemanticType, includes a link to the definition of
the Semantic Type

Overridable

=cut

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

=head2 _overrideRecord

	%record = %{ $self->_overrideRecord( \%record ) };

virtual method used by _getDBObjDetail to allow easy overriding of
select portion of records. This should *NOT* be used instead of of
DBObjRender methods.

If you want to do something like make an email field into an active
link, override OME::Web::DBObjRender->renderSingle. Changes there will
be reflected in everything that displays a given type.

If you want to do something like make a field editable by inserting a
text input box, use this method. Changes here will be reflected only in
this OME::Web::DBObjDetail.

Overridable

=cut

sub _overrideRecord { 
	my ($self, $record) = @_;
	return $record;
}


=head2 _getManyRelations

	my @relations = $self->_getManyRelations( $object );

returns an array of html entities, each describing a has-many or
many-to-many relationship the given object has.

Unless overridden, uses OME::Web::DBObjRender->getRelationAccessors to
get data and OME::Web::DBObjTable->getList to make lists.

Overridable

=cut

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
		if( $iter->getDBObjType_ID_and_Accessor() ) {
			my ( $from_type, $from_id, $from_accessor) = $iter->getDBObjType_ID_and_Accessor();
			push( @relations, $q->p( $tableMaker->getList( 
				{
					title            => $iter->name(), 
					embedded_in_form => $self->{ form_name },
					Length           => 5,
					width            => '100%'
				}, 
				$iter->return_type(), 
				{ accessor => [ $from_type, $from_id, $from_accessor ] }
			) ) );
		} else {
			push( @relations, $q->p( $tableMaker->getList( 
				{
					title            => $iter->name(), 
					embedded_in_form => $self->{ form_name },
					Length           => 5,
					width            => '100%'
				}, 
				$iter->return_type(), 
				$iter->getList()
			) ) );
		}
	} while( $iter->next() ); }
	
	return @relations;
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
	return $specializedPackage->new( CGI => $self->CGI() )
		unless $@ or ref( $self ) eq $specializedPackage;

	return undef;
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
