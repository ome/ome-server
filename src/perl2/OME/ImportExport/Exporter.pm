#!/usr/bin/perl -w
#
# OME/ImportExport/Exporter.pm
#
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
# Written by:    Brian S. Hughes
#
#-------------------------------------------------------------------------------


#

# OME's image export class. It creates an instance of the Export_writer
# class for each image and has that instance's methods and sub-classes
# do the actual import work.
#

# ---- Public routines -------
# new()

package OME::ImportExport::Exporter;
use strict;
use OME::ImportExport::Export_writer;
use Carp;
use File::Basename;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

sub new {
    my $export_writer;
    my $image_list_ref;
    my $export_type;
    my $session;
    my $repository;
    my $ky;

    my $self = {};

    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance

    $session = shift;

    $export_type = shift;
    die "No export type given" unless $export_type;

    $image_list_ref = shift;         # reference list of export images
    die "No image file to export" unless $image_list_ref;

    $repository = shift;
    die "No repository found" unless $repository;

   
    $export_writer = new OME::ImportExport::Export_writer($session, $export_type, $image_list_ref, $repository, $self)
    	or die "Couldn\'t make Export_writer instance";
	my $status = $export_writer->export;
	die $status if ($status ne "");


}


1;
