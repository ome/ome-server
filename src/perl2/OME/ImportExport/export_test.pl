#!/usr/bin/perl -w
#
# export_test.pl
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

# This program acts as a test jig for the Exporter class. It uses the same
# API for Exporter as the production OME.
#

use strict;
use OME::ImportExport::Exporter;
use OME::ImportExport::TIFFwriter;
use Carp;
use vars qw($VERSION);
$VERSION = '1.0';

my @image_list;
my $export_type = "TIFF";

# replace these with your own OME DB image ids
if (scalar @ARGV == 0) {
    push @image_list, "5";
    print "passing @image_list\n";
}
else {
    @image_list = @ARGV;
}

my $writer = OME::ImportExport::Exporter->new(\@image_list, $export_type);

