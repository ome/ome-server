#!/usr/bin/perl -w
#
# Export_writer.pm
# Copyright (C) 2002 Open Microscopy Environment, MIT
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

# This class contains the base methods for exporting OME images into external
# filetypes.



# ---- Public routines -------
# new()
# export()
# accessImage()
# accessRepositoryFile()
# getDBInfo()


package OME::ImportExport::Export_writer;
our @ISA = ("OME::ImportExport::Exporter");
use strict;
use Carp;
use Config;
use OME::Image;
use OME::ImportExport::TIFFwriter;
use OME::ImportExport::FileUtils;
use vars qw($VERSION);
$VERSION = '1.0';


my %export_writers = ('TIFF' => 'TIFFwriter');


sub new {
    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $self = {};
    $self->{session} = shift;
    $self->{type} = shift;
    $self->{image_list_ref} = shift;
    $self->{repository} = shift;
    $self->{parent} = shift;
    # Find out what byte order this machine has
    my $byteorder = $Config{byteorder};
    my $our_endian = (($byteorder == 1234) || ($byteorder == 12345678)) ? "little" : "big";
    $self->{endian} = $our_endian;

    return bless $self, $class;

}


# Do the export. Will create an instance
# of the proper child class to create the requested file type.
sub export {
    my $self = shift;
    my $status = "";
    my $writer;
    my $exporter;
    my $export_writer;
    my $fh;

    $status = "Don\'t know how to export type $self->{type}";
    if (defined ($writer = $export_writers{$self->{type}})) {
	$status = "";
    }

    return $status
	unless ($status eq "");

    $exporter = "OME::ImportExport::".$writer;
    $export_writer = $exporter->new($self);
    print "Exporting $self->{image_list_ref}\n";
    $status = $export_writer->export($self->{image_list_ref});

    return $status;

}


# Routine that all children should use to access the base Image metadata

sub accessImage {
    my $self = shift;
    my $id   = shift;
    my $href = shift;

    my $session = $self->{session};
    my $image;
    my ($x, $y);
    my $status = "Failed to load image id $id";

    $image = $session->Factory()->loadObject("OME::Image", $id);
    my $dimensions = $image->Dimensions();
    return $status
	unless defined $image && defined $dimensions;

    $status = "";
    $href->{Name}  = $image->name();
    $href->{BitsPerSample}   = $dimensions->bits_per_pixel();
    $href->{SizeX} = $dimensions->size_x();
    $href->{SizeY} = $dimensions->size_y();
    $href->{SizeZ} = $dimensions->size_z();
    $href->{DateTime} = $image->created();
    $href->{NumWaves} = $dimensions->num_waves();
    $href->{NumTimes} = $dimensions->num_times();


    return $status;

}


# Routine that all children should use to access the base Image data

sub accessImagePix {
    my ($self, $id, $pix_ref, $x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2) = @_;
    my $image;
    my $session = $self->{session};
    my $status = "Failed to load image id $id";

    $image = $session->Factory()->loadObject("OME::Image", $id);
    return $status
	unless defined $image;

    $$pix_ref = $image->GetPixels($x1,$x2,$y1,$y2,$z1,$z2,$w1,$w2,$t1,$t2);
    $status = "";

    return $status;
}


1;
