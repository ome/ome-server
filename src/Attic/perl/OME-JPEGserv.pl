#!/usr/bin/perl -w
# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
#

use OMEpl;
use strict;


my $OME = new OMEpl;
my $cgi = $OME->cgi;
my $path = $cgi->url_param('Path');
my $directory = $cgi->url_param('Dir');
my $file = $cgi->url_param('Name');
my $ID = $cgi->url_param('ID');
my $red = $cgi->url_param('Red');
my $green = $cgi->url_param('Green');
my $blue = $cgi->url_param('Blue');

	if (defined $directory and $directory and defined $file and $file) {
		$path = "$directory/$file" unless defined $path and $path;
	}
	die "No Dtaaset specified"
		unless (defined $path and $path) or (defined $ID and $ID);
	print $cgi->header (-type=>'image/jpeg');
	

	if (defined $path and $path) {
		print `convert -normalize '$path' JPEG:-`;
	} else {
		my $select = "SELECT datasets.path, datasets.name, attributes_iccb_tiff.wave ".
			"WHERE attributes_iccb_tiff.dataset_id = datasets.dataset_id AND datasets.dataset_id IN ".
			" (SELECT dataset_id FROM attributes_iccb_tiff WHERE raster_id = ".
			" (SELECT raster_id FROM attributes_iccb_tiff WHERE dataset_id=$ID))".
			" ORDER BY attributes_iccb_tiff.wave";
		my $rows =  $OME->DBIhandle->selectall_arrayref ($select);
		my $cmd;

		if (scalar @$rows eq 3) {
			$red = 0 unless defined $red;
			$green = 1 unless defined $green;
			$blue = 2 unless defined $blue;
		} elsif (scalar @$rows eq 2) {
			$red = 0 unless defined $red;
			$green = 1 unless defined $green;
			$blue = 1 unless defined $blue;
		}
		/* This assumes that RGB will always be associated with      */
		/* channels 3,2,1, resp. Needs to read the color/channel     */
		/* assignment from the metadata, once it gets recorded there */
		if (scalar @$rows eq 3) {
		    $cmd = q/combine -compose ReplaceBlue "|convert -normalize '/.
			$rows->[$blue]->[0].$rows->[$blue]->[1].
			q/' TIFF:-" -compose ReplaceGreen "|convert -normalize '/.
			$rows->[$green]->[0].$rows->[$green]->[1].
			q/' TIFF:-" -compose ReplaceRed "|convert -normalize '/.
			$rows->[$red]->[0].$rows->[$red]->[1].
			q/' TIFF:-" JPEG:-/;
		} elsif (scalar @$rows eq 2) {
		    $cmd = q/combine -compose ReplaceBlue "|convert -normalize '/.
			$rows->[$blue]->[0].$rows->[$blue]->[1].
			q/' TIFF:-" -compose ReplaceRed "|convert -normalize '/.
			$rows->[$red]->[0].$rows->[$red]->[1].
			q/' TIFF:-" JPEG:-/;
		}

#		$cmd = q/combine -compose CopyBlue "|convert -normalize '/.
#			$rows->[$blue]->[0].$rows->[$blue]->[1].
#			q/' TIFF:-" -compose CopyGreen "|convert -normalize '/.
#			$rows->[$green]->[0].$rows->[$green]->[1].
#			q/' TIFF:-" -compose CopyRed "|convert -normalize '/.
#			$rows->[$red]->[0].$rows->[$red]->[1].
#			q/' TIFF:-" JPEG:-/;
		print `$cmd`;
	}
	
	$OME->Finish;
	


