# OME/Web/DBObjCreate/OME_Dataset.pm

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


package OME::Web::DBObjCreate::OME_Dataset;

=pod

=head1 NAME

OME::Web::DBObjDBObjCreate::OME_Dataset

=head1 DESCRIPTION

implements _create. sets experimenter to current user, group to current
user's primary group, and associates the new dataset with the current project.

=cut

use strict;
use OME;
use OME::Dataset;
our $VERSION = $OME::VERSION;

use base qw(OME::Web::DBObjCreate);

sub _create {
	my ( $self ) = @_;
	my $q = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();

	my %data_hash;
	foreach( OME::Dataset->getPublishedCols() ) {
		$data_hash{ $_ } = $q->param( $_ )
			if( $q->param( $_ ) );
	}
	$data_hash{ owner } = $session->User();
	$data_hash{ group } = $session->User()->Group();
	
	my $dataset = $factory->newObject( 'OME::Dataset', \%data_hash );
	my $map=$factory->maybeNewObject("OME::Project::DatasetMap",{
			project => $session->project(),
			dataset => $dataset
		} );
 	$session->commitTransaction();
 	
	return( 'REDIRECT', $self->getObjDetailURL( $dataset ) );
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
