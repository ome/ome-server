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
	my @saved_params = @_;
	my $class = ref($proto) || $proto;
	
	# try to get a specialized subclass unless this call is coming from a subclass
	unless( $class ne __PACKAGE__ ) {
		my %params = @saved_params;
		my $q    = $params{ CGI };
		if( defined $q && ( my $formal_name = $q->param( 'Type' ) ) ) {
			# construct specialized package name
			my $specializedPackage = $formal_name;
			($specializedPackage =~ s/::/_/g or $specializedPackage =~ s/@//);
			$specializedPackage = "OME::Web::DBObjDetail::__".$specializedPackage;
	
			# obtain package
			eval( "use $specializedPackage" );
			unless ($@ || $specializedPackage eq __PACKAGE__) {
				return $specializedPackage->new( @saved_params );
			}
		}
	}
	
	# either there isn't a specialized class or it's loaded and hasn't overridden this method
	# either way, pass the buck to OME::Web
	my $self  = $class->SUPER::new(@saved_params);

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
	my $object = $self->_loadObject();
	my ($package_name, $common_name, $formal_name, $ST) = $self->_loadTypeAndGetInfo( $object );
    return $common_name.': '.$self->Renderer()->getName($object);
}

=head2 getPageBody

calls _takeAction() to allow subclasses to respond to form actions
A detailed view is acquired from OME::Web::DBObjRender services. This gets
embedded in a form.

Write a template for OME::Web::DBObjRender to change the look of this.

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

	$self->_takeAction( );

	my $q = $self->CGI();
	my $object = $self->_loadObject();
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	my $html = $q->startform( { -name => $self->{ form_name } } ).
	           $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	           $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	           $q->hidden({-name => 'action', -default => ''}).
	           $self->Renderer()->render( $object, 'detail' ).
	           $q->endform();

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

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
