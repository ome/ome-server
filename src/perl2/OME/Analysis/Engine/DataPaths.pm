# OME/Analysis/Engine/DataPaths.pm

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

package OME::Analysis::Engine::DataPaths;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Tasks::ChainManager;

use Carp;

sub __debug { print STDERR @_, "\n"; }

=head1 NAME

OME::Analysis::Engine::DataPaths - creates the data path entries for
an analysis chain

=cut

sub createDataPaths {
    my $class = shift;
    my ($chain) = @_;
    my $factory = OME::Session->instance()->Factory();

    __debug("  Building data paths");

    # A data path is represented by a list of node ID's, starting
    # with a root node and ending with a leaf node.

    my @data_paths;

    # First, we create paths for each root node in the chain

    my $root_nodes = OME::Tasks::ChainManager->getRootNodes($chain);
    foreach my $node (@$root_nodes) {
        __debug("    Found root node ".$node->id());
        my $path = [$node];
        push @data_paths, $path;
    }

    # Then, we iteratively extend each path until it reaches a
    # leaf node.  If at any point, it branches, we create
    # duplicates so that there is one path per branch-point.
    my $continue = 1;
    while ($continue) {
        $continue = 0;
        my @new_paths;
        while (my $data_path = shift(@data_paths)) {
            my $end_node = $data_path->[$#$data_path];
            my $successors = OME::Tasks::ChainManager->
              getNodeSuccessors($end_node);
            my $num_successors = scalar(@$successors);

            if ($num_successors == 0) {
                push @new_paths,$data_path;
            } elsif ($num_successors == 1) {
                # Check for a cycle
                foreach (@$data_path) {
                    die
                      "Cycle! ".join(':',
                                     map {$_->id()} @$data_path,
                                     $successors->[0])
                      if $_->id() eq $successors->[0]->id();
                }

                __debug("    Extending ".
                        join(':',
                             map {$_->id()} @$data_path).
                        " with ".
                        $successors->[0]->id());
                push @$data_path, $successors->[0];
                push @new_paths,$data_path;
                $continue = 1;
            } else {
                foreach my $successor (@$successors) {
                    # Check for a cycle
                    foreach (@$data_path) {
                        die
                          "Cycle! ".join(':',
                                         map {$_->id()} @$data_path,
                                         $successor->id())
                          if $_->id() eq $successor->id();
                    }

                    # make a copy
                    my $new_path = [@$data_path];
                    __debug("    Extending ".
                            join(':',
                                 map {$_->id()} @$new_path)." with ".
                            $successor->id());
                    push @$new_path, $successor;
                    push @new_paths, $new_path;
                }
                $continue = 1;
            }
        }

        @data_paths = @new_paths;
    }

    foreach my $data_path_list (@data_paths) {
        my $data_path = $factory->
          newObject("OME::AnalysisPath",
                    {
                     path_length   => scalar(@$data_path_list),
                     analysis_chain => $chain
                    });
        my $data_pathID = $data_path->id();

        my $order = 0;
        foreach my $node (@$data_path_list) {
            my $path_entry =
              {
               path                => $data_path,
               path_order          => $order,
               analysis_chain_node => $node
              };
            my $db_path_entry = $factory->
              newObject("OME::AnalysisPath::Map",
                        $path_entry);
            $order++;
        }
    }
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


