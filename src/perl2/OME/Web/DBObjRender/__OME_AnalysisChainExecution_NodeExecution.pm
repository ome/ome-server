# OME/Web/DBObjRender/__OME_AnalysisChainExecution_NodeExecution.pm
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


package OME::Web::DBObjRender::__OME_AnalysisChainExecution_NodeExecution;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_AnalysisChainExecution_NodeExecution -
Specialized rendering

=head1 DESCRIPTION

Return links to the MEX instead of ref to self.
OME::AnalysisChainExecution::NodeExecution

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Session;
use base qw(OME::Web::DBObjRender);

=head2 _getName

returns name of MEX

=cut

sub _getName {
	my ($self, $obj, $options) = @_;

	return $self->getName( $obj->module_execution() );
}

=head2 _getRef

returns ref of MEX

=cut

sub _getRef {
	my ($self, $obj, $options) = @_;

	return $self->getRef( $obj->module_execution(), 'html' );
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
