# OME/Analysis/Engine/FeatureHierarchy.pm

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

package OME::Analysis::Engine::FeatureHierarchy;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;

=head1 NAME

OME::Analysis::Engine::FeatureHierarchy - calculates hierarchy of
features based on an execution of an analysis chain

=cut

sub new {
    my ($proto,$mex,$image) = @_;
    my $class = ref($proto) || $proto;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my %hierarchy_children = ();
    my %hierarchy_parent = ();
    my %hierarchy_roots = ();

    my $self = {
                roots     => \%hierarchy_roots,
                parents   => \%hierarchy_parent,
                children  => \%hierarchy_children,
                mex       => $mex,
                image     => $image,
               };
    bless $self, $class;

    my %mexes_to_examine;
    my %mexes_examined;

    $mexes_to_examine{$mex->id()} = $mex;

    # For every node left to examine:
    #   Find its tags' parents, mark this in the hierarchy.
    #   Add its predecessor mexes to the list of mexes to examine.
    my $continue = 1;
    while ($continue) {
        $continue = 0;
        foreach my $this_mexID (keys %mexes_to_examine) {
            next if (exists $mexes_examined{$this_mexID});
            my $this_mex = $mexes_to_examine{$this_mexID};

            my %this_tags;

            my @actual_inputs = $factory->
              findObjects("OME::ModuleExecution::ActualInput",
                          {
                           module_execution => $this_mex,
                           'formal_input.semantic_type.granularity' => 'F',
                          });

            foreach my $actual_input (@actual_inputs) {
                my $formal_input = $actual_input->formal_input();
                my $semantic_type = $formal_input->semantic_type();

                my %tags;
                my $pred_mex = $actual_input->input_module_execution();
                my $pred_mexID = $pred_mex->id();
                my $pred_iterator = $pred_mex->iterator_tag() || '[Image]';

                # This could be done better, maybe with a DISTINCT query
                my $attributes = $factory->
                  findAttributes($semantic_type,
                                 {
                                  module_execution => $pred_mex,
                                  'target.image'   => $image,
                                 });
                while (my $attribute = $attributes->next()) {
                    $tags{$attribute->target()->tag()} = 1;
                }

                foreach my $tag (keys %tags) {
                    # Each of the tags that were found must either
                    # a) match the iterator tag of the predecessor
                    # mex, or b) must be a child of the
                    # predecessor iterator.

                    #__debug("          Found tag $tag");

                    if ($pred_iterator eq '[Image]') {
                        #__debug("            $tag is a child of <Image>");
                        $hierarchy_parent{$tag} = undef;
                        $hierarchy_roots{$tag} = 1;
                    } elsif ($tag eq $pred_iterator) {
                        #__debug("            $tag is propagating");
                        # No more parents can be determined at
                        # this point.
                    } else {
                        #__debug("            $tag is a parent of $pred_iterator");
                        $hierarchy_parent{$tag} = $pred_iterator;
                        $hierarchy_children{$pred_iterator}->{$tag} = 1;
                    }
                }

                $mexes_to_examine{$pred_mexID} = 1;
            }


            $continue = 1;
            $mexes_examined{$this_mexID} = 1;
        }
    }

    return $self;
}

sub display {
    my ($self,$prefix) = @_;

    my %tags_found;
    my $hierarchy_children = $self->{children};

    my $print_tag;
    $print_tag = sub {
        my ($prefix,$tag) = @_;

        if (exists $tags_found{$tag}) {
            croak "$tag found twice in feature hierarchy";
        }

        print "${prefix}'${tag}'\n";
        $tags_found{$tag} = 1;

        foreach (keys %{$hierarchy_children->{$tag}}) {
            &$print_tag("$prefix  ",$_) if defined $_;
        }
    };

    print "$prefix<Image>\n";
    &$print_tag("$prefix  ",$_) foreach keys %{$self->{roots}};

    return;
}

sub findIteratorFeaturesForTag {
    my ($self,$iterator,$tag,$feature_list) = @_;

    # Tries to build an SQL statement that finds the iterator
    # features that correspond to a given tag feature.

    #__debug("Building SQL for iterator $iterator and tag $tag");

    my $factory = OME::Session->instance()->Factory();

    # Quickly handle the trivial case.

    if ($iterator eq $tag) {
        return $feature_list;
    }

    # Search up the tree.
    my @path = ($tag);

    while ($path[0] ne $iterator) {
        my $parent = $self->{parents}->{$path[0]};
        if (defined $parent) {
            unshift @path, $parent;
        } else {
            last;
        }
    }

    my $forwards = 1;

    # Did we find one?
    if ($path[0] ne $iterator) {
        # No, so, search down the tree.  Or in other words, search up
        # the tree from the opposite end.

        @path = ($iterator);

        while ($path[0] ne $tag) {
            my $parent = $self->{parents}->{$path[0]};
            if (defined $parent) {
                unshift @path, $parent;
            } else {
                last;
            }
        }

        $forwards = 0;

        # Did we find one?
        if ($path[0] ne $tag) {
            croak "No path in the feature hierarchy between $tag and $iterator";
        }
    }

    my $num_levels = scalar(@path);
    die "We found a path of no length" unless $num_levels > 0;

    if ($forwards) {
        my $tag = "parent_feature";
        $num_levels--;
        $tag .= ".parent_feature" while $num_levels--;
        return $factory->findObject("OME::Feature",
                                    { $tag => ['in',$feature_list] });
    } else {
        my @result_features;
        foreach my $feature (@$feature_list) {
            for (my $i = 0; $i < $num_levels; $i++) {
                last unless defined $feature;
                $feature = $feature->parent_feature();
            }
            push @result_features, $feature
              if defined $feature;
        }
        return \@result_features;
    }
}

sub findIteratorFeatures {
    my ($self,$iterator_tag) = @_;
    my $factory = OME::Session->instance()->Factory();
    my $mex = $self->{mex};
    my $image = $self->{image};

    # keyed by tag
    my %input_features;

    # Find the features of the attributes created by a predecessor
    # node's module execution.

    my @actual_inputs = $factory->
      findObjects("OME::ModuleExecution::ActualInput",
                  {
                   module_execution => $mex,
                   'formal_input.semantic_type.granularity' => 'F',
                  });

    foreach my $actual_input (@actual_inputs) {
        my $formal_input = $actual_input->formal_input();
        my $pred_mex = $actual_input->input_module_execution();

        my $attributes = $factory->
          findAttributes($formal_input->semantic_type(),
                         {
                          module_execution => $pred_mex,
                          'target.image'   => $image,
                         });
        while (my $attribute = $attributes->next()) {
            my $feature = $attribute->target();
            $input_features{$feature->tag()}->{$feature->id()} = $feature;
        }
    }

    my $iterator = $mex->iterator_tag();
    my %iterator_features;

    foreach my $tag (keys %input_features) {
        my @features = values %{$input_features{$tag}};

        if (scalar(@features) > 0) {
            # Build up the SQL statement to find the iterator tags.
            my $features = $self->
              findIteratorFeaturesForTag($iterator,$tag,\@features);

            $iterator_features{$_->id()} = $_ foreach @$features;
        }
    }

    my @features = values %iterator_features;
    #__debug(join(',',@feature_IDs));
    return \@features;
}

1;
