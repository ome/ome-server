# OME/Remote/Facades/AnalysisFacade.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Remote::Facades::AnalysisFacade;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Factory;

use OME::Analysis::Engine;
use OME::Remote::DTO::GenericAssembler;

=head1 NAME

OME::Remote::Facades::AnalysisFacade - remote facade methods for
accessing the analysis engine

=cut

sub executeAnalysisChain {
    my ($proto,$chain_id,$dataset_id,$user_inputs) = @_;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $chain = $factory->loadObject('OME::AnalysisChain',$chain_id);
    die "Chain $chain_id doesn't exist" unless defined $chain;

    my $dataset = $factory->loadObject('OME::Dataset',$dataset_id);
    die "Dataset $dataset_id doesn't exist" unless defined $dataset;

    die "User inputs must be a hash, or null"
      if defined $user_inputs && ref($user_inputs) ne 'HASH';

    OME::Analysis::Engine->
        executeChain($chain,$dataset,$user_inputs);

    1;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
