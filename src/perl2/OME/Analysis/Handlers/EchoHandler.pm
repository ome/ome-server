# OME/Analysis/Handlers/EchoHandler.pm

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

package OME::Analysis::Handlers::EchoHandler;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

sub executeGlobal {
    my ($self) = @_;
    $self->SUPER::executeGlobal();
    print STDERR "    executeGlobal\n";

    my $mex = $self->ModuleExecution();
    my $module = $mex->module();
    print STDERR "      MEX ",$mex->id()," (",$module->name(),")\n";

    print STDERR "      Global inputs:\n";
    my $inputs = $self->getFormalInputsByGranularity('G');
    if (scalar(@$inputs) == 0) {
        print STDERR "        none\n";
    } else {
        foreach my $input (@$inputs) {
            my $vals = $self->getGlobalInputs($input->name());
            print "        ",$input->name()," - ",scalar(@$vals),"\n";
            if (scalar(@$vals) < 10) {
                print "          ",join(',',map { $_->id() } @$vals),"\n";
            }
        }
    }
}

sub startDataset {
    my ($self) = @_;
    $self->SUPER::startDataset();
    print STDERR "    startDataset\n";

    print STDERR "      Dataset inputs:\n";
    my $inputs = $self->getFormalInputsByGranularity('D');
    if (scalar(@$inputs) == 0) {
        print STDERR "        none\n";
    } else {
        foreach my $input (@$inputs) {
            my $vals = $self->getDatasetInputs($input->name());
            print "        ",$input->name()," - ",scalar(@$vals),"\n";
            if (scalar(@$vals) < 10) {
                print "          ",join(',',map { $_->id() } @$vals),"\n";
            }
        }
    }
}

sub startImage {
    my ($self) = @_;
    $self->SUPER::startImage();
    print STDERR "    startImage\n";

    print STDERR "      Image inputs:\n";
    my $inputs = $self->getFormalInputsByGranularity('I');
    if (scalar(@$inputs) == 0) {
        print STDERR "        none\n";
    } else {
        foreach my $input (@$inputs) {
            my $vals = $self->getImageInputs($input->name());
            print "        ",$input->name()," - ",scalar(@$vals),"\n";
            if (scalar(@$vals) < 10) {
                print "          ",join(',',map { $_->id() } @$vals),"\n";
            }
        }
    }
}

sub startFeature {
    my ($self) = @_;
    $self->SUPER::startFeature();
    print STDERR "    startFeature\n";

    print STDERR "      Feature inputs:\n";
    my $inputs = $self->getFormalInputsByGranularity('F');
    if (scalar(@$inputs) == 0) {
        print STDERR "        none\n";
    } else {
        foreach my $input (@$inputs) {
            my $vals = $self->getFeatureInputs($input->name());
            print "        ",$input->name()," - ",scalar(@$vals),"\n";
            if (scalar(@$vals) < 10) {
                print "          ",join(',',map { $_->id() } @$vals),"\n";
            }
        }
    }
}

sub finishFeature {
    my ($self) = @_;
    $self->SUPER::finishFeature();
    print STDERR "    finishFeature\n";
}

sub finishImage {
    my ($self) = @_;
    $self->SUPER::finishImage();
    print STDERR "    finishImage\n";
}

sub finishDataset {
    my ($self) = @_;
    $self->SUPER::finishDataset();
    print STDERR "    finishDataset\n";
}

1;
