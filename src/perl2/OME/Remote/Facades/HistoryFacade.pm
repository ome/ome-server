
# OME/Remote/Facades/HistoryFacade.pm

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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Remote::Facades::HistoryFacade;
use OME;
our $VERSION = $OME::VERSION;

use OME::Remote::DTO::GenericAssembler;
use OME::Session;
use OME::AnalysisChainExecution;
use OME::Tasks::HistoryManager;

=head1 NAME

OME::Remote::Facades::HistoryFacade - implementation of remote
facade methods for retrieving data histories.

=cut

use constant DEFAULT_CHEX_SPEC =>
  {
   '.' => ['id','module','inputs','predecessors','timestamp'],
   'module' => ['id','name'],
   'inputs' =>
       ['id','input_module_execution','module_execution','formal_input',
       'formal_output'],
   'inputs.input_module_execution' =>  ['id'],
   'inputs.module_execution' => ['id'],
   'inputs.formal_input' =>
       ['id','name','semantic_type'],
   'inputs.formal_input.semantic_type' =>
       ['id','name'],
   'inputs.formal_output' =>
       ['id','name','semantic_type'],
   'inputs.formal_output.semantic_type' =>
       ['id','name']

  };


=head1 METHODS

=head2 getMexDataHistory

    my @mexes =
          OME::Remote::Facades::HistoryFacade->getMexDataHistory(
              $mex_id,$fields_wanted)


    Returns a list of module executions that reperesent the complete
    data history of the module execution $mex_id. The returned module
    executions will be encoded as DTOs, as necessary for XMLRPC
    transmission. The actual history retrieval is done by
    OME::Tasks::HistoryManager - this facade serves a s a thin
    wrapper.

=head2 getChainDataHistory

    my @mexes =
          OME::Remote::Facades::HistoryFacade->getChainDataHistory(
              $chex_id,$fields_wanted)


    Returns a list of module executions that reperesent the complete
    data history of the chain execution $chex_id. 


    For both calls, the $spec is optional. If no argument is provided,
    a default specification will be used to populate the data fields.

=cut 

sub getMexDataHistory {
    my ($proto,$mex_id,$spec) = @_;

    $spec = DEFAULT_CHEX_SPEC
	unless defined $spec && ref($spec) eq 'HASH';

    my @mexes = OME::Tasks::HistoryManager->getMexDataHistory($mex_id);

    my $dtos =
	OME::Remote::DTO::GenericAssembler->makeDTOList(\@mexes,$spec);

    return $dtos;
}


sub getChainDataHistory {
    my ($proto,$chex_id,$spec) = @_;

    $spec = DEFAULT_CHEX_SPEC
	unless defined $spec && ref($spec) eq 'HASH';

    my @mexes = OME::Tasks::HistoryManager->getChainDataHistory($chex_id);

    my $dtos =
	OME::Remote::DTO::GenericAssembler->makeDTOList(\@mexes,$spec);

    return $dtos;
}
1;

__END__
=head1 AUTHOR

Harry Hochheiser (hsh@nih.gov)

=cut
