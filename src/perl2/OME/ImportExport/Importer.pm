#!/usr/bin/perl -w
#
# Importer.pm
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

# OME's image import class. It creates an instance of the Import-reader
# class for each image and has that instance's methods and sub-classes
# do the actual import work.
#

# ---- Public routines -------
# new()

# ---- Private routines ------
# get_base_name()

package OME::ImportExport::Importer;
use strict;
use OME::ImportExport::Import_reader;
use Carp;
use vars qw($VERSION);
$VERSION = '1.0';

sub new {
    my @image_buf;
    my %xml_elements;      # build up DB entries in here keyed by their XML element names
    my $image_file;
    my $import_reader;
    my $read_status;


    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $image_file_list_ref = shift;         # reference list of input files
    croak "No image file to import"
	unless $image_file_list_ref;
    my $callback = shift;     # ref. to callback routine to which results returned

    foreach $image_file (@$image_file_list_ref) {
	@image_buf = ();     # clear out any old images
	%xml_elements = ();  # clear out any old metadata
	$xml_elements{'Image.Name'} = get_base_name($image_file);
	$import_reader = new OME::ImportExport::Import_reader($image_file, \@image_buf, \%xml_elements);
	my $fn = $import_reader->Image_reader::image_file;
	$import_reader->check_type;

	if ($import_reader->image_type eq "Unknown") {
	    carp "File $image_file has an unknown type";
	}
	else {
	    $read_status = $import_reader->readFile;
	    if ($read_status ne "") {
		print "Carping: ";
		carp $read_status;
	    }
	    else {
		print "Done with import\n";
		&$callback(\%xml_elements, \@image_buf);
	    }
	}
	$import_reader->DESTROY;
    }
}

sub get_base_name {
    my $fullnm = shift;
    my $fn;
    my @arr;

    @arr = split('/', $fullnm);  # assume Unix style filename
    $fn = $arr[$#arr];
    $fn =~ s/([\w]+).*/$1/;

    return $fn;
}

    
1;
