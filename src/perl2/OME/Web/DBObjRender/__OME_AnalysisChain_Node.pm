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
#	Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjRender::__OME_AnalysisChain_Node;

=pod

=head1 NAME

OME::Web::DBObjRender::__OME_AnalysisChainExecution_NodeExecution - Specialized rendering for OME::AnalysisChainExecution::NodeExecution

=head1 DESCRIPTION

This name will be the name of the module execution it represents.
The reference will contain both links to the MEX and the Node Execution.

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use HTML::Template;
use OME::Tasks::ImageManager;
use OME::Tasks::ModuleExecutionManager;
use Carp 'cluck';
use base qw(OME::Web::DBObjRender);

=head2 _getName

=cut

#sub _getName {

=head2 _getRef

=cut

sub _getRef {
	my ($self,$obj,$format) = @_;
	
	for( $format ) {
		if( /^txt$/ ) {
			return $obj->id();
		}
		if( /^html$/ ) {
			my ($package_name, $common_name, $formal_name, $ST) =
				OME::Web->_loadTypeAndGetInfo( $obj );
			my $id   = $obj->id();
			my $module_name = $obj->module()->name();
			my $module_href = $self->getObjDetailURL( $obj->module() );
			my $obj_href = $self->getObjDetailURL( $obj );
			my $ref = "<a href='$module_href' title='Details on this Module'>$module_name</a> (<a href='$obj_href' title='Details on this Node'>$id</a>)";
			return $ref;
		}
	}
}

=head1 Author

Tom Macura <tmacura@nih.gov>

=cut

1;
