# OME/Analysis/Modules/PPM/Typecast.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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


package OME::Analysis::Modules::PPM::Typecast;

use strict;
use OME 2.002_000;
our $VERSION = 1.000;

=head1 NAME

OME::Analysis::Modules::PPM::Typecast

=cut

use base qw(OME::Analysis::Handler);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);

    bless $self, $class;
    return $self;
}

sub execute {
    my ($self,$dependence,$target) = @_;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my $mex    = $self->getModuleExecution();
    my $module = $mex->module();

    # Mark this module execution as being virtual.  This only works
    # because of the fact that our outputs are attributes which have
    # already been created.  If we were creating new attribtues, we
    # could not have this be a virtual MEX.

    $mex->virtual_mex(1);
    $mex->storeObject();

    # Find all of the formal inputs for this module.  Each one should
    # have a semantic type which is a PPM subclass.

    my @formal_inputs = $module->inputs();

  INPUT:
    foreach my $formal_input (@formal_inputs) {
        # Since the input represents a PPM subclass ST, it should have
        # an element named Parent.  First, check that there is a Parent
        # element for this ST, and that it's a reference element.  If
        # not, skip this input.

        my $st = $formal_input->semantic_type();
        my $element = $factory->
          findObject('OME::SemanticType::Element',
                     {
                      semantic_type => $st,
                      name          => 'Parent',
                     });

        if (!defined $element) {
            # No element named Parent
            warn "Formal input $formal_input to module ".$module->name().
              " is not a PPM semantic type (no Parent element)";
            next INPUT;
        }

        if ($element->data_column()->sql_type() ne 'reference') {
            # Element is not a reference
            warn "Formal input $formal_input to module ".$module->name().
              " is not a PPM semantic type (Parent element isn't a reference)";
            next INPUT;
        }

        # We have a valid Parent link for this input.  So, find all of
        # the input values, follow their Parent links, and create
        # virtual MEX outputs for these parents.

        my @values = $self->getInputAttributes($formal_input);
        my @parents = map { $_->Parent() } @values;

        foreach my $value (@values) {
            my $parent = $value->Parent();
            my $vmm = $factory->
              newObject('OME::ModuleExecution::VirtualMEXMap',
                        {
                         module_execution => $mex,
                         attribute        => $parent,
                        });
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
