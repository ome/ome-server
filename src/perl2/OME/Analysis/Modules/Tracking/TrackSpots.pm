# OME/Analysis/Modules/Tracking/TrackSpots.pm

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


package OME::Analysis::Modules::Tracking::TrackSpots;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use IO::File;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

use fields qw(_timepointSpots _nextTrajectoryNumber _spotEntries
              _spotTrajectories _spotOrders _physicalCoordinates);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class->SUPER::new(@_);
    $self->{_timepointSpots} = {};
    $self->{_nextTrajectoryNumber} = 1;
    $self->{_spotEntries} = {};
    $self->{_physicalCoordinates} = {};
    $self->{_spotTrajectories} = {};
    $self->{_spotOrders} = {};

    bless $self,$class;
    return $self;
}

sub startImage {
    my ($self,$image) = @_;
    $self->SUPER::startImage($image);

    my $dims = $self->getCurrentInputAttributes("Dimensions")->[0];
    if (defined $dims) {
        $self->{_pixelX} = $dims->PixelSizeX() || 1;
        $self->{_pixelY} = $dims->PixelSizeY() || 1;
        $self->{_pixelZ} = $dims->PixelSizeZ() || 1;
    } else {
        $self->{_pixelX} = 1;
        $self->{_pixelY} = 1;
        $self->{_pixelZ} = 1;
    }

    $self->{_spotCount} = 0;
}

sub startFeature {
    my ($self,$spot) = @_;
    $self->SUPER::startFeature($spot);

    # Sort the spots by timepoint
    my $t = $self->getCurrentInputAttributes("Timepoint")->[0]->TheT();
    push @{$self->{_timepointSpots}->{$t}}, $spot;

    # Calculate the physical location of the spot
    my $location = $self->getCurrentInputAttributes("Location")->[0];
    my %phys;
    $phys{X} = $location->TheX() * $self->{_pixelX};
    $phys{Y} = $location->TheY() * $self->{_pixelY};
    $phys{Z} = $location->TheZ() * $self->{_pixelZ};

    $self->{_physicalCoordinates}->{$spot->id()} = \%phys;

    $self->{_spotCount}++;
    print STDERR $self->{_spotCount}," " if ($self->{_spotCount} % 10 == 0);
}

sub finishImage {
    my ($self) = @_;

    my @timepoints = sort {$a <=> $b} keys %{$self->{_timepointSpots}};
    my $dims = $self->getCurrentInputAttributes("Dimensions")->[0];
    my $timeSize = (defined $dims)? $dims->PixelSizeT() || 1: 1;

    my %trajectories;

    # For the spots in all timepoints except for the last one, we search
    # for the nearest spot in the next timepoint, and link the two with
    # a TrajectoryEntry attribute.

    for (my $i = 0; $i < scalar(@timepoints)-1; $i++) {
        my $timepoint = $timepoints[$i];
        print STDERR "\n$timepoint - ";

        # For each spot in a given timepoint
        foreach my $spot (@{$self->{_timepointSpots}->{$timepoint}}) {
            my $trajectory = $self->{_spotTrajectories}->{$spot->id()};
            my $order = $self->{_spotOrders}->{$spot->id()};
            my $phys = $self->{_physicalCoordinates}->{$spot->id()};
            print STDERR $spot->id();

            if (!defined $trajectory) {
                # If this spot was not associated with a spot in the
                # previous timepoint, it should start a new trajectory.
                $trajectory = $self->createNewTrajectory();
                $order = 1;
                my $tAttr = $self->
                  newAttributes("Trajectory",
                                {
                                 target          => $trajectory,
                                 Name            => $trajectory->name(),
                                 TotalDistance   => undef,
                                 AverageVelocity => undef,
                                });
                $trajectories{$trajectory->id()}->{trajectory} = $trajectory;
                $trajectories{$trajectory->id()}->{attribute} = $tAttr->[0];
                $trajectories{$trajectory->id()}->{minX} = $phys->{X};
                $trajectories{$trajectory->id()}->{minY} = $phys->{Y};
                $trajectories{$trajectory->id()}->{minZ} = $phys->{Z};
                $trajectories{$trajectory->id()}->{minT} = $timepoint;
            }

            my ($nextSpot,$deltaX,$deltaY,$deltaZ,$squareDistance) =
              $self->findNearestSpot($spot,$timepoints[$i+1]);
            my $distance = sqrt($squareDistance);
            my $velocity =
              $distance /
              (($timepoints[$i+1]-$timepoints[$i])*$timeSize);

            print STDERR ":",$nextSpot->id()," ";

            my $spotEntry = $self->
              newAttributes("Entries",
                            {
                             target     => $spot,
                             Trajectory => $trajectory->id(),
                             Order      => $order,
                             DeltaX     => $deltaX,
                             DeltaY     => $deltaY,
                             DeltaZ     => $deltaZ,
                             Distance   => $distance,
                             Velocity   => $velocity,
                            });
            $trajectories{$trajectory->id()}->{maxX} = $phys->{X};
            $trajectories{$trajectory->id()}->{maxY} = $phys->{Y};
            $trajectories{$trajectory->id()}->{maxZ} = $phys->{Z};
            $trajectories{$trajectory->id()}->{maxT} = $timepoint;

            $self->{_spotTrajectories}->{$nextSpot->id()} = $trajectory;
            $self->{_spotOrders}->{$nextSpot->id()} = $order + 1;
        }
    }

    # Add entries for the spots in the last timepoint

    my $lastTimepoint = $timepoints[$#timepoints];
    foreach my $spot (@{$self->{_timepointSpots}->{$lastTimepoint}}) {
        my $trajectory = $self->{_spotTrajectories}->{$spot->id()};
        my $order = $self->{_spotOrders}->{$spot->id()};
        my $phys = $self->{_physicalCoordinates}->{$spot->id()};

        if (!defined $trajectory) {
            # If this spot was not associated with a spot in the
            # previous timepoint, it should start a new trajectory.
            $trajectory = $self->createNewTrajectory();
            $order = 1;
            $trajectories{$trajectory->id()}->{trajectory} = $trajectory;
            $trajectories{$trajectory->id()}->{minX} = $phys->{X};
            $trajectories{$trajectory->id()}->{minY} = $phys->{Y};
            $trajectories{$trajectory->id()}->{minZ} = $phys->{Z};
            $trajectories{$trajectory->id()}->{minT} = $lastTimepoint;
        }

        my $spotEntry = $self->
          newAttributes("Entries",
                        {
                         target     => $spot,
                         Trajectory => $trajectory->id(),
                         Order      => $order,
                        });
        $trajectories{$trajectory->id()}->{maxX} = $phys->{X};
        $trajectories{$trajectory->id()}->{maxY} = $phys->{Y};
        $trajectories{$trajectory->id()}->{maxZ} = $phys->{Z};
        $trajectories{$trajectory->id()}->{maxT} = $lastTimepoint;
    }

    # Calculate the attributes of each trajectory
    foreach my $trajectoryID (keys %trajectories) {
        my $tInfo = $trajectories{$trajectoryID};
        my $trajectory = $tInfo->{trajectory};
        my $tAttr = $tInfo->{attribute};

        if (($tInfo->{maxT} - $tInfo->{minT}) != 0) {
            my $dX = $tInfo->{maxX} - $tInfo->{minX};
            my $dY = $tInfo->{maxY} - $tInfo->{minY};
            my $dZ = $tInfo->{maxZ} - $tInfo->{minZ};
            my $dT = $tInfo->{maxT} - $tInfo->{minT};
            my $distance = sqrt($dX*$dX + $dY*$dY + $dZ*$dZ);
            my $velocity = ($dT == 0)? undef: $distance/$dT;
            $tAttr->TotalDistance($distance);
            $tAttr->AverageVelocity($velocity);
            $tAttr->storeObject();
        }
    }

    # Reset the instance fields for the next image
    $self->{_timepointSpots} = {};
    $self->{_nextTrajectoryNumber} = 1;
    $self->{_spotEntries} = {};
    $self->{_physicalCoordinates} = {};
    $self->{_spotTrajectories} = {};
    $self->{_spotOrders} = {};

    $self->SUPER::finishImage();
}

sub createNewTrajectory {
    my ($self) = @_;
    my $trajectory = $self->newFeature("Trajectory ".$self->{_nextTrajectoryNumber});
    $self->{_nextTrajectoryNumber}++;
    return $trajectory;
}

sub findNearestSpot {
    my ($self,$spot,$timepoint) = @_;

    my $phys = $self->{_physicalCoordinates}->{$spot->id()};
    my $nextSpots = $self->{_timepointSpots}->{$timepoint};
    my ($minimumSquaredDistance, $nearestSpot, $deltaX, $deltaY, $deltaZ);

    foreach my $nextSpot (@$nextSpots) {
        next if ($spot->id() eq $nextSpot->id());
        my $nextPhys = $self->{_physicalCoordinates}->{$nextSpot->id()};
        my $x = $nextPhys->{X} - $phys->{X};
        my $y = $nextPhys->{Y} - $phys->{Y};
        my $z = $nextPhys->{Z} - $phys->{Z};
        my $squaredDistance = ($x*$x)+($y*$y)+($z*$z);

        if ((!defined $minimumSquaredDistance) ||
            ($squaredDistance < $minimumSquaredDistance)) {
            $minimumSquaredDistance = $squaredDistance;
            $nearestSpot = $nextSpot;
            $deltaX = $x;
            $deltaY = $y;
            $deltaZ = $z;
        }
    }

    return ($nearestSpot, $deltaX, $deltaY, $deltaZ, $minimumSquaredDistance);
}

1;
