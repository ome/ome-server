# OME/Analysis/Modules/PPM/Typecast2DerivedPixels.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2006 Open Microscopy Environment
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
# Written by: Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------

package OME::Analysis::Modules::PPM::Typecast2DerivedPixels;

use strict;
use OME 2.002_000;
our $VERSION = 1.000;

=head1 NAME

OME::Analysis::Modules::PPM::Typecast2DerivedPixels

=head1 SYNOPSIS

Typecaster module to DerivedPixels

=head1 OVERVIEW

This module allows a attribute (which has Pixels as Parent) to be used as a 
DerivedPixels.

=cut

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use Time::HiRes qw(gettimeofday tv_interval);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);

    bless $self, $class;
    return $self;
}

sub startFeature {
    my ($self,$feature) = @_;
    $self->SUPER::startFeature($feature);

    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    my $mex     = $self->getModuleExecution();
    my $module  = $mex->module();

	my $start_time = [gettimeofday()];
	my $derivedPixelsST = $factory->findObject('OME::SemanticType', {name => 'DerivedPixels'});

    # Find all of the formal inputs for this module.  Each one should
    # have a semantic type which is a PPM subclass.
    my @formal_inputs  = $module->inputs();
    
	$mex->read_time(tv_interval($start_time));
	$mex->execution_time(0);
	$mex->write_time(0);
  INPUT:
    foreach my $formal_input (@formal_inputs) {
		$start_time = [gettimeofday()];
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
            warn "Formal input ".$formal_input->name()." to module ".$module->name().
              " is not a PPM semantic type (no Parent element)";
            next INPUT;
        }

        if ($element->data_column()->sql_type() ne 'reference') {
            # Element is not a reference
            warn "Formal input ".$formal_input->name()." to module ".$module->name().
              " is not a PPM semantic type (Parent element isn't a reference)";
            next INPUT;
        }
       
	    # We have a valid Parent link for this input.  So, find all of
        # the input values, follow their Parent links, and create
        # virtual MEX outputs for these parents.
		
        my @values = $self->getCurrentInputAttributes($formal_input);
		$mex->read_time($mex->read_time() + tv_interval($start_time));
		
		$start_time = [gettimeofday()];
        foreach my $value (@values) {
            my $parent = $value->Parent();
            
            if ($parent->semantic_type()->name() ne "Pixels") {
            	die "Formal input '".$formal_input->name()."' of module '".
			    $module->name()."' PPM inherits from semantic type '".
			    $parent->semantic_type()->name(). "' which doesn't inherit from
			    Pixels";
			}
			
			my $formal_output = $factory->findObject('OME::Module::FormalOutput',
				{
					module => $module,
					semantic_type => $derivedPixelsST,
				});
			
			die "couldn't find a formal output with ST DerivedPixels" unless
				defined( $formal_output);
				
			$self->newAttributes($formal_output->name(),
				{
					Parent => $parent,
					StartX => 0,
					EndX   => $parent->SizeX()-1,
					StartY => 0,
					EndY   => $parent->SizeY()-1,
					StartZ => 0,
					EndZ   => $parent->SizeZ()-1,
					StartC => 0,
					EndC   => $parent->SizeC()-1,
					StartT => 0,
					EndT   => $parent->SizeT()-1,
				});
        }
		$mex->write_time($mex->write_time() + tv_interval($start_time));
    }
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>,
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
