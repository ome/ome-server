# OME/Web/MultiObjCreate/ExperimentProtocol

#-------------------------------------------------------------------------------
#
# Copyright (C) 2005 Open Microscopy Environment
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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::MultiObjCreate::ExperimentProtocol;

=head1 NAME

OME::Web::MultiObjCreate - Create Multi instances of Semantic Types 

=head1 DESCRIPTION

Specific instance of a MultiObjCreate. See OME::Web::MultiObjCreate
for details and documentation.
=cut


use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Tasks::MultipleSTAnnotationManager;
use OME::Web::MultiObjCreate;
use base qw(OME::Web::MultiObjCreate);

sub getPageTitle {
    return "OME: Define Experiment Protocol";
}

sub getSTsToCreate{ 
    my $self = shift;

    return ("ExperimentProtocol","Husbandry","SamplePreparation",
	    "DevelopmentalStage","Fluorofor","Strain");
}


sub getReturnType {
    my $self = shift;
    return "ExperimentProtocol";
}


sub populateTemplate {

    my $self = shift;
    my $tmpl_params = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    $self->SUPER::populateTemplate($tmpl_params);


    $tmpl_params->{DevelopmentalStageValue} = 
	$self->populateDropDown(
	    '@DevelopmentalStageValue','DevelopmentalStageValue');
}

1;
