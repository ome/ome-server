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

# The ICCB filenames are on the command line following the script's name - including wild-cards
#use Pg;
use OMEpl;
use File::Basename;
use Cwd 'abs_path';
use strict;

use vars qw ($OME);

END
{
	$OME = undef;
}

$OME = new OMEpl;

#
my $i=0;
my $fileName;
my ($name,$path,$suffix);
my $wave;
my $sample;
my $well;
my $plate;
my $base;
my $frag;
my $fragRe;
my $absPath;
my $ICCB_Dataset;
printf "%-35s\t%-25s\tPlate\tWell\tSample\twave\n","Filename","Base name";

LOOP:
foreach $fileName (@ARGV)
{
	# reset our variables
	$wave = $sample = $well = $plate = undef;
	$frag = "";

	# Get the name, path and suffix from the filename.
	($name,$path,$suffix) = fileparse($fileName,".TIF",".tif");
	
	# Get the absolute path for the file.
	$absPath = abs_path ($path)."/";
#	print "absolute path: $absPath\n";
	

	# The suffix (when converted to uppercase) must be equal to "TIF"
	if (uc ($suffix) ne ".TIF")
	{
		print "'$fileName' is not a TIFF file\n";
		next LOOP;
	}

	# Build frag from the end to the begining.
	# eventually it will contain all the stuff after the base name.
	# Get the well,sample,and wave
	# if we find matches, set the variable, and prepend the format to frag
	if ($name =~ /_w([0-9]+)/){ $wave = $1; $frag = "_w".$wave.$frag; }
	if ($name =~ /_s([0-9]+)/){ $sample = $1; $frag = "_s".$sample.$frag; }
	if ($name =~ /_([A-P][0-2][0-9])/){ $well = $1; $frag = "_".$well.$frag;}
	
	if (! defined $well)
	{
		print "'$fileName' is not an ICCB TIFF file - The well was not defined.\n";
		next LOOP;
	}

	# Make frag a regular expression and use it to find the plate number.
	# Prepend the plate number to frag so we can find the basename.
	# N.B.: If the base name ends in a digit, then we cannot determine the plate number!
	$fragRe = qr/$frag/;
	if ($name =~ /([0-9]+)${fragRe}/){ $plate = $1; $frag = $plate.$frag }

	# The base name is everything before $frag.
	$fragRe = qr/$frag/;
	if ($name =~ /(.*)${fragRe}/){ $base = $1;}
	
	# Get a new ICCB Dataset
	$ICCB_Dataset = $OME->NewDataset (
		Name => $name.$suffix,
		Path => $absPath,
		Type => "ICCB_TIFF",
		);
	
	$ICCB_Dataset->Well($well);
	$ICCB_Dataset->BaseName($base);
	$ICCB_Dataset->Wave($wave);
	$ICCB_Dataset->Sample($sample);
	$ICCB_Dataset->ChemPlate($plate);
	$ICCB_Dataset->WriteDB();

	$wave = '-' unless defined $wave;
	$sample = '-' unless defined $sample;
	$plate = '-' unless defined $plate;

	printf "%-35s\t%-25s\t%5s\t%4s\t%6s\t%4s\n",$name.$suffix,
#		$ICCB_Dataset->BaseName(),
#		$ICCB_Dataset->ChemPlate(),
#		$ICCB_Dataset->Well(),
#		$ICCB_Dataset->Sample(),
#		$ICCB_Dataset->Wave();
		$base,
		$plate,
		$well,
		$sample,
		$wave;
}
