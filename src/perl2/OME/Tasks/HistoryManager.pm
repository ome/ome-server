# OME/Tasks/HistoryManager.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2005 Open Microscopy Environment
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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Tasks::HistoryManager;


=head1 NAME

OME::Tasks::HistoryManager - retrieve data history

=head1 SYNOPSIS

	# For a mex id, Retrieve the complete list of predecessor mexes
	my @mex_list = OME::Tasks::HistoryManager->getMexDataHistory( $mex_id );
	# Same thing, but with a ModuleExecution object
	my @mex_list = OME::Tasks::HistoryManager->getMexDataHistory( $mex );

	# For a Chain Execution id, Retrieve the complete list of predecessor mexes
	my @mex_list = OME::Tasks::HistoryManager->getChainDataHistory( $chex_id );
	# Same thing, but with a ChainExecution object
	my @mex_list = OME::Tasks::HistoryManager->getChainDataHistory( $chex );

=head1 DESCRIPTION

The OME::Tasks::HistoryManager is a manager for    retrieving the data
    derivation history of a module execution. Given a module
    exeuction, this manager will return a list containing all of the
    module exeuctions in the data history of that module execution. 

    For each module execution included in the returned list, the
    "inputs" list contains instances of
    OME::ModuleExecution::ActualInput. These items indicate the
    linkages between modules executions in this list. Taken together
    with the module executions themselves, these actual inputs
    provide enough information to specify the entire data history.

    Note that the module execution for which history is being derived
    is itself included in the list that is returned. This is
    necessary because the inputs to that module execution are needed
    for construction of the data history view.  


=head1 METHODS (ALPHABETICAL ORDER)

The following methods are available to a "HistoryManager."

=head2 getMexDataHistory($mex_id)

Retrieve the data history for the specified mex.

=head2 getChainDataHistory($chex_id)

Retrieve the data history for the specified chain execution.

=cut

use strict;
use OME::SetDB;
use OME::DBObject;
use OME::ModuleExecution;
use OME::AnalysisChainExecution::NodeExecution;
use Carp;

use OME;
our $VERSION = $OME::VERSION;

   
sub new{
	my $class=shift;
	my $self={};

	return bless($self,$class);
}

sub getMexDataHistory {
    my ($class,$mex_id)= @_;

    # get factory
    my $session=OME::Session->instance();
    my $factory = $session->Factory();
    
    my $mex;
	if( ref( $mex_id ) eq 'OME::ModuleExecution' ) {
		$mex = $mex_id;
	} else {
		# retrieve the module execution
		$mex= $factory->loadObject('OME::ModuleExecution',$mex_id)
			or confess "Couldn't load module execution $mex_id";
	}

    # return all module executions that we have seen.
    return _getMexClosures($mex);
}

sub getChainDataHistory {
     my ($class,$chex_id) = @_;

    # get factory
    my $session=OME::Session->instance();
    my $factory = $session->Factory();


    # get all of the module executions that I can for this chex
    # first, get node executions
    my @nexes = $factory->findObjects(
	'OME::AnalysisChainExecution::NodeExecution',
        { analysis_chain_execution => $chex_id });

    # then, get module executions for those.
    my @mexes = map { $_->module_execution()} @nexes;

    # filter out anything that's null
    @mexes = grep (($_),@mexes);

    # use these as the input.
    return _getMexClosures(@mexes);
}

sub _getMexClosures {
    my (@mexes) = @_;

    my %mexes;
    my $mex;
    my @preds;

    while (scalar(@mexes) > 0 ) {
	$mex = pop @mexes;
	if (!exists($mexes{$mex->ID()})) {
	    $mexes{$mex->ID()} = $mex;
	    @preds = $mex->predecessors();
	    push @mexes,@preds;
	}
	
    }
    return values %mexes;
}

1;

