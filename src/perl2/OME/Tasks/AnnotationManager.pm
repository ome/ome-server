# OME/Tasks/AnnotationManager.pm

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


package OME::Tasks::AnnotationManager;

=head1 NAME

OME::Tasks::AnnotationManager - Workflow methods for handling
user-defined annotations

=head1 SYNOPSIS

	my $attribute = OME::Tasks::AnnotationManager->
	    annotate([$semantic_type,$target,$data],...);

=head1 DESCRIPTION

Computational results only provide half the story when it comes to an
image in OME.  Equally important are the user-defined annotations.
These annotations are semantically typed, just like comptational
results, allowing data visualization tools to work on both, and to
allow those annotations to be used as inputs into analysis algorithms.

The AnnotationManager class provides method to ease the creation of
user-defined annotations.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;

use OME::Tasks::ModuleExecutionManager;

sub annotateGlobal  { shift->__annotate('G',@_); }
sub annotateDataset { shift->__annotate('D',@_); }
sub annotateImage   { shift->__annotate('I',@_); }
sub annotateFeature { shift->__annotate('F',@_); }

sub __annotate {
    my $class = shift;
    my $granularity = shift;
    my $target = shift if $granularity ne 'G';

    my $factory = OME::Session->instance()->Factory();

    my $annotation_module = OME::Session->instance()->
      Configuration()->annotation_module();
    die "Cannot annotate without an annotation module!"
      unless defined $annotation_module;

    my @params;

    # First, sort the parameters in the @params array

    while (@_) {
        my $semantic_type = shift;
        die "annotateGlobal needs a semantic type"
          unless defined $semantic_type;

        if (!ref($semantic_type)) {
            # Assume this is an ST name, not an ST object
            my $name = $semantic_type;
            $semantic_type = $factory->
              findObject('OME::SemanticType',{name => $name});

            die "Cannot find a semantic type named $name"
              unless defined $semantic_type;
        } elsif (UNIVERSAL::isa($semantic_type,'OME::SemanticType')) {
            # Excellent, this is just what we need
        } else {
            die "annotateGlobal needs a semantic type";
        }

        my $st_granularity = $semantic_type->granularity();
        die "Semantic type does not match granularity $granularity"
          unless $granularity eq $st_granularity;

        my $data = shift;
        die "annotateGlobal needs a data hash"
          unless defined $data && ref($data) eq 'HASH';

        push @params, [$semantic_type, $target, $data];
    }

    # Great, now let's create some attributes

    my @attributes;
    my $new_mex;

    my ($dependence,$mex_target);
    if ($granularity eq 'F') {
        $dependence = 'I';
        $mex_target = $target->image();
    } else {
        $dependence = $granularity;
        $mex_target = $target;
    }

  PARAM:
    foreach my $param (@params) {
        my ($semantic_type, $target, $data) = @$param;

        # First, look for an existing annotation attribute with these
        # values.  If we find one, save it, and record the MEX that
        # created it.

        # We need to add some criteria to the data hash.  We create a
        # so that we don't clobber the data hash with the criteria hash.
        my %criteria = %$data;

        $criteria{'module_execution.module'} = $annotation_module;

        my $existing = $factory->
          findAttribute($semantic_type,\%criteria);

        if (defined $existing) {
            push @attributes, $existing;
            next PARAM;
        }

        # We couldn't find an existing attribute, so we need to create
        # a new one.  If we haven't created a new MEX for these new
        # attributes, do so.

        if (!defined $new_mex) {
            $new_mex = OME::Tasks::ModuleExecutionManager->
              createMEX($annotation_module,$dependence,$mex_target);
            die "Cannot create annotation MEX!"
              unless defined $new_mex;
        }

        my $new_attr = $factory->
          newAttribute($semantic_type,$target,$new_mex,$data);

        push @attributes, $new_attr;
    }

    if (defined $new_mex) {
        $new_mex->status('FINISHED');
        $new_mex->storeObject();
    }

    # Okay, now we should have attribute objects in the @attributes
    # array corresponding to each of the inputs.  If necessary, create
    # a virtual MEX for them via the ModuleExecutionManager.

    return OME::Tasks::ModuleExecutionManager->
      createVirtualMEX(\@attributes);
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
