# OME/Web/DBObjCreate.pm

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
# Written by:
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Web::DBObjCreate;

=pod

=head1 NAME

OME::Web::DBObjCreate - Create new DBObjects

=head1 DESCRIPTION

=cut

use strict;
use Carp;

use OME;
use OME::Tasks::ModuleExecutionManager;

our $VERSION = $OME::VERSION;
use base qw(OME::Web);

=pod

=head1 NAME

OME::Web::DBObjCreate - Show detailed information on an object

=head1 DESCRIPTION

DBObjCreate displays detailed information on any DBObject or attribute.
It's default behaviors can be overridden by writing subclasses.

Important!! Subclasses should not be accessed directly. All access 
should go through DBObjCreate. Specialization is completely
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
	
	# _published_create_types gets translated to the 'Create a:' drop-down list
	$self->{ _published_create_types } = [
		'OME::Dataset',
		'OME::Project',
		'@CategoryGroup',
		'@Category',
	];
	
	return $self;
}

=head2 getMenuText

If called from the Package, will return "Other"
If called from an instance that has a type CGI parameter, will return "[common name]"

Overridable.

=cut

sub getMenuText {
	my $self = shift;
	my $menuText = "Other";
	return $menuText unless ref($self);

	my $specializedDetail;
	return $specializedDetail->getMenuText( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	my $q = $self->CGI();
	my $type = $q->param( 'Type' );
	if( $type ) {
 		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
 		$menuText = "$common_name";
 	}
	return $menuText;
}

=head2 getPageTitle

If called from the Package, will return "Create Something"
If called from an instance that has CGI parameters, will return "Create [common name]"

Overridable.

=cut

sub getPageTitle {
	my $self = shift;
	my $pageTitle = "Create Something";
	return $pageTitle unless ref($self);

	my $specializedDetail;
	return $specializedDetail->getPageTitle( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	my $q = $self->CGI();
	my $type = $q->param( 'Type' );
	if( $type ) {
 		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
 		$pageTitle = "Create $common_name";
 	}
	return $pageTitle;
}

=head2 getPageBody

Overridable

=cut

sub getPageBody {
	my $self = shift;

	my $specializedDetail;
	return $specializedDetail->getPageBody( )
		if( $specializedDetail = $self->__specialize( ) and
		    ref( $self ) eq __PACKAGE__ );

	my $q = $self->CGI();
	my $type = $q->param( 'Type' );

	# create?
	if( $q->param( 'create' ) ) {
		return $self->_create( );
	}

	# collect data for type selection
	my $types_data;
	foreach my $formal_name ( @{ $self->{ _published_create_types } } ) {
 		my ($package_name, $common_name, undef, $ST) = $self->_loadTypeAndGetInfo( $formal_name );
 		my $type_data;
 		$type_data->{ formal_name } = $formal_name;
 		$type_data->{ common_name } = $common_name;
		$type_data->{ selected } = 'selected'
			if( $type && $formal_name eq $type );
		push( @$types_data, $type_data );
	}

	# collect html output
	my $html = 
		$q->startform( -onsubmit => 'return validateForm( this, false, true );' ).
		$self->Renderer()->renderType( 
 			$type, 'create',
 			{ validate => 1, types_loop => $types_data } 
 		).
 		$q->endform();
	return ( 'HTML', $html );
}

=head2 _create

overrideable

=cut

sub _create {
	my ( $self ) = @_;
	my $q = $self->CGI();
	my $type = $q->param( 'Type' );
	my $session = $self->Session();
	my $factory = $session->Factory();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );
	my %data_hash;
	foreach( $package_name->getPublishedCols() ) {
		$data_hash{ $_ } = $q->param( $_ )
			if( $q->param( $_ ) );
	}
	
# 	my ($dependence, $target, $mex, $obj);
# 	if( $ST ) {
# 		if( $ST->granularity() eq 'D' ) {
# 			$dependence = 'D';
# 			$target = $data_hash{ dataset };
# 		} elsif( $ST->granularity() eq 'I' ) {
# 			$dependence = 'I';
# 			$target = $data_hash{ image };
# 		}
# 		$mex = OME::Tasks::ModuleExecutionManager->createMEX(
# 			$session->Configuration()->annotation_module_id(),
# 			$dependence,$target);
# 		$data_hash{ module_execution } = $mex;
# 	} 
# 	$obj = $factory->newObject( $formal_name, \%data_hash );
# 	$session->commitTransaction();
# 	
# 	return( 'REDIRECT', $self->getObjDetailURL( $obj ) );
	my $html = "I'm still working the kinks out, and a new $common_name wasn't actually created. But, the data for it is:<br>".join( '<br>', map( $_.' : '.$data_hash{ $_ }, keys %data_hash ) );
	return ( 'HTML', $html );
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
	my $q = $self->CGI();
	my $type = $q->param( 'Type' );
	if( $type ) {
 		my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $type );

		# construct specialized package name
		my $specializedPackage = $formal_name;
		($specializedPackage =~ s/::/_/g or $specializedPackage =~ s/@//);
		$specializedPackage = "OME::Web::DBObjCreate::".$specializedPackage;
	
		# obtain package
		eval( "use $specializedPackage" );
		return $specializedPackage->new( CGI => $self->CGI() )
			unless $@ or ref( $self ) eq $specializedPackage;
	}

	return undef;
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
