# OME/Web/DBObjRender/__CategoryGroup.pm
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


package OME::Web::DBObjRender::__CategoryGroup;

=pod

=head1 NAME

OME::Web::DBObjRender::__CategoryGroup - Specialized rendering for CategoryGroup

=head1 DESCRIPTION

Provides a list of Categories within this group

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Tasks::ImageManager;
use OME::Tasks::ModuleExecutionManager;
use Carp 'cluck';
use base qw(OME::Web::DBObjRender);

=head2 _renderData

makes virtual fields Categories

=cut

sub _renderData {
	my ($self, $obj, $field_requests, $options) = @_;
	
	my $factory = $obj->Session()->Factory();
	my %record;

	# Categories
	if( exists $field_requests->{ 'Categories' } ) {
		foreach my $request ( @{ $field_requests->{ 'Categories' } } ) {
			my $request_string = $request->{ 'request_string' };
			my @categories = $factory->findObjects( '@Category', { 
				CategoryGroup => $obj
			} );
			my $render_mode = ( $request->{ render } or 'ref_list' );
			$record{ $request_string } = $self->Renderer()->renderArray( 
				\@categories, 
				$render_mode, 
				{ type => '@Category' }
			);
		}
	}
	
	return %record;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
