# OME/Web/DBObjRender/__OME_Module.pm
#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:  
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_Module;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_Module - Specialized rendering for Modules

=head1 DESCRIPTION

Provides custom behavior for rendering a Module

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use base qw(OME::Web::DBObjRender);

=head2 getRefSearchField

returns a dropdown list of Module names valued by id.

=cut

sub _getRefSearchField {
	my ($self, $from_type, $to_type, $accessor_to_type, $default) = @_;
	my (undef, undef, $from_formal_name) = OME::Web->_loadTypeAndGetInfo( $from_type );
	my $factory = OME::Session->instance()->Factory();

	# Modules list
	my @modules = $factory->findObjects( "OME::Module" );
	my $module_order = [ '', sort( map( $_->name(), @modules ) ) ];
	my $module_names;
	$module_names->{''} = 'All';

	my $q = $self->CGI();
	$q->param( $accessor_to_type.'.name', $default ) 
		unless defined $q->param( $accessor_to_type.'.name' );
	return ( 
		$q->popup_menu( 
			-name	=> $accessor_to_type.'.name',
			'-values' => $module_order,
			-labels	 =>  $module_names,
			-default  => $default,
	#		-size => "4",
	#		-multiple => 1
		),
		$accessor_to_type.'.name'
	);

}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
