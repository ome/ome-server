#!/usr/bin/perl -w
#
# import_test.pl
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

# This program acts as a test jig for the Importer class. It uses the same
# API for Importer as the production OME.
#

use strict;
use OME::ImportExport::Importer;
use Carp;
use vars qw($VERSION);
$VERSION = '1.0';
my @flist;

# replace these with paths to your own images
if (scalar @ARGV == 0) {
    push @flist, "210502-0min-NFKB-4.r3d";
    push @flist, "EXPERIMENT38_w1FITC_t1.STK";
    push @flist, "n2_plate18_P24_w1.tif";
    print "passing @flist\n";
}
else {
    @flist = @ARGV;
}

# Give importer a callback to which it will return image data & metadata.
# The image data will be in an array, and the metadata will be in a hash.
# Both the hash and the array will be passed to the callback by reference.

my $reader = OME::ImportExport::Importer->new(\@flist, \&retriever);

#print "Importer returned a buffer with ", scalar(@imported_image), " entries\n";


sub retriever {
    my $href = shift;
    my $aref = shift;
    my ($ky, $ky2, $ar, $hr);
    my ($i, $size);

    print "Received hash reference $href, and array reference $aref\n";
    print "    *** Metadata ***\n";
    foreach $ky (keys %$href) {
	print "$ky: $href->{$ky}\n";
	if (ref($href->{$ky}) eq "ARRAY") {
	    $ar = $href->{$ky};
	    $size = scalar(@$ar);
	    for ($i = 0; $i < $size; $i++) {
		print "\n";
		$hr = @$ar[$i];
		foreach $ky2 (keys %$hr) {
		    print "\t$ky2: $hr->{$ky2}\n";
		}
	    }
	    print "\t-------------------------------\n";
	}
    }

    my $d1 = scalar(@{$aref});
    my $d2 = scalar(@{$aref->[0]});
    my $d3 = scalar(@{$aref->[0][0]});
    my $d4 = scalar(@{$aref->[0][0][0]});
    #my $d5 = scalar(@{$aref->[0][0][0][0]});
    print "\n$d1 $d2 $d3 $d4\n'";
    print $aref->[0][0][0][0] . "'\n";
    print length($aref->[0][0][0][0]) . "\n";
    
    print "\n\n\n";
}
