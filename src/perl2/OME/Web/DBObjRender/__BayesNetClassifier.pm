# OME/Web/DBObjRender/__BayesNetClassifier.pm
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


package OME::Web::DBObjRender::__BayesNetClassifier;

=pod

=head1 NAME

OME::Web::DBObjRender::__BayesNetClassifier - specialized rendering of BayesNetClassifier ST

=head1 DESCRIPTION

Turns FileID into an active link for retrieving the file. Assumes only one
repository is in the system, which is an assumption made in the data model.
( e.g. the BayesNetClassifier STD )

=cut

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use base qw(OME::Web::DBObjRender);
use OME::Session;

=head2 _renderData

populates field FileID with a link to download the file from the image server

=cut

sub _renderData {
	my ($proto, $obj, $field_requests, $options) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my %record;
	if( exists $field_requests->{ 'FileID' } ) {
		foreach my $request ( @{ $field_requests->{ 'FileID' } } ) {
			my $request_string = $request->{ 'request_string' };
			my $repository = $factory->findObject( '@Repository' );
			$record{ $request_string } = 
				'<a href="'.
				$repository->ImageServerURL().'?Method=ReadFile&FileID='.$obj->FileID().
				'" title="Download this file">'.$obj->FileID()."</a>";
		}
	}
	return %record;
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
