#!/usr/bin/perl -w
#
# PixWrapper.pm
# Copyright (C) 2003 Open Microscopy Environment, MIT
# Author:  Brian S. Hughes
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

# This class interfaces with the Pix class
#

package OME::ImportExport::PixWrapper;

use strict;
use File::Temp qw(tempfile);
use OME::Image::Pix;
use vars qw($VERSION);
$VERSION = '1.0';

sub new {
    my $invoker = shift;
    my $xref = shift;
    my $path = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $self = {};
    $self->{xml_ref} = $xref;

    # Create a unique temporary filename for the image repository file.
    # This file will hold the image pixels as they are imported. Only
    # after the complete image is recorded in the database can the permanent
    # filename be created. At that point, the Importer module will rename
    # the image file.

    my ($tmpfh, $tmpfn) = tempfile("importXXXXXX", DIR => $path);
    #close $tmpfh;
    $self->{tempfh} = $tmpfh;
    $self->{tempfn} = $tmpfn;
    $self->{path} = $path;
    $self->{cur_x} = 0;
    $self->{cur_y} = 0;
    $self->{cur_z} = 0;
    $self->{cur_c} = 0;
    $self->{cur_t} = 0;
    $self->{max_x} = $xref->{'Image.SizeX'};
    $self->{max_y} = $xref->{'Image.SizeY'};
    $self->{max_z} = $xref->{'Image.SizeZ'};
    $self->{max_c} = $xref->{'Image.NumWaves'};
    $self->{max_t} = $xref->{'Image.NumTimes'};
    my $bps = $xref->{'Data.BitsPerPixel'};
    $bps /= 8;
    my $pix = new OME::Image::Pix ($tmpfn,
				   $self->{max_x},
				   $self->{max_y},
				   $self->{max_z},
				   $self->{max_c},
				   $self->{max_t},
				   $bps)
  	|| return $self;

    $self->{Pix} = $pix;
    bless $self, $class;

    return $self;
}


sub SetRow {
    my $self = shift;
    my $row = shift;
    my $nOut;

    $nOut = $self->{Pix}->SetRow($row, $self->{cur_y}, $self->{cur_z}, $self->{cur_c}, $self->{cur_t});
    $self->{cur_y} += 1;
    if ($self->{cur_y} > $self->{max_y}) {
	$self->{cur_y} = 0;
	$self->{cur_z} += 1;
	if ($self->{cur_z} > $self->{max_z}) {
	    $self->{cur_z} = 0;
	    $self->{cur_c} += 1;
	    if ($self->{cur_c} > $self->{max_c}) {
		$self->{cur_c} = 0;
		$self->{cur_t} += 1;
	    }
	}
    }

    return $nOut;
}


sub SetRows {
    my $self = shift;
    my $rows = shift;
    my $num_rows = shift;
    my $nOut;

    $nOut = $self->{Pix}->SetRows($rows, $num_rows, $self->{cur_y}, $self->{cur_z}, $self->{cur_c}, $self->{cur_t});
    $self->{cur_y} += $num_rows;
    if ($self->{cur_y} >= $self->{max_y}) {
	$self->{cur_y} = 0;
	$self->{cur_z} += 1;
	if ($self->{cur_z} >= $self->{max_z}) {
	    $self->{cur_z} = 0;
	    $self->{cur_c} += 1;
	    if ($self->{cur_c} >= $self->{max_c}) {
		$self->{cur_c} = 0;
		$self->{cur_t} += 1;
	    }
	}
    }

    return $nOut;
}


sub SetPlane {
    my $self = shift;
    my $pref = shift;    # reference to a pixel plane
    my $theZ = shift;
    my $theC = shift;    # channel number
    my $theT = shift;    # timepoint

    my $nOut = $self->{Pix}->SetPlane($pref, $theZ, $theC, $theT);

}


sub Finish {
    my $self = shift;
    my $fstat = shift;
    close $self->{tempfh};
    unlink $self->{tempfn}
        unless ($fstat =~ /OK/);
}


1;

