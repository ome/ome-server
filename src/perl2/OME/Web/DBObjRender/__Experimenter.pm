# OME/Web/RenderData/__Experimenter.pm
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


package OME::Web::RenderData::__Experimenter;

=pod

=head1 NAME

OME::Web::RenderData::__Experimenter - Specialized rendering for Experimenter Attribute

=head1 DESCRIPTION

Provides custom behavior for rendering an Experimenter Attribute

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Session;
use base qw(OME::Web::RenderData);

=head2 getObjectLabel

id. FirstName LastName

=cut

sub getObjectLabel {
	my ($proto,$obj,$format, $doNotSpecialize) = @_;

	return $obj->id().". ".$obj->FirstName." ".$obj->LastName;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
