#!/usr/bin/perl -w
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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------

use strict;
use OME;
use OME::SessionManager;
use OME::Session;
use Carp;

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();

my $datasetName = $ARGV[0];

if (defined $datasetName) {
    print "Looking for dataset $datasetName\n";
}
else {
    print "No dataset name specified. \n";
    exit 0;
}

my $dataset = $factory->findObject(
                'OME::Dataset', 
		{    name => $datasetName
		}) or confess "Couldn't load dataset $datasetName";

my $id = $dataset->ID();
print "Dataset $datasetName: $id\n";

my $owner = $dataset->owner();
my $first = $owner->FirstName();
my $last = $owner->LastName();
print "Owner: $first $last\n";

# projects

my @projects  = $dataset->projects();
my $count = scalar(@projects);
my $name;


print "** PROJECTS **\n";
print "Dataset has $count projects\n";


foreach (@projects) {
	$id = $_->ID();
	$name = $_->name();
	print "$id, $name\n";
}


# images
my @images = $dataset->images();

#better way to do count? ***

$count = scalar(@images);
print "** IMAGES **\n";

print "Dataset has $count images\n";

my $image;

#better way to do loop?
foreach (@images) {
	$id = $_->ID();
	$name = $_->name();
	print "Image ID: $id, name  $name\n";
}


1;
