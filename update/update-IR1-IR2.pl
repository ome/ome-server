#/usr/bin/perl
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
use DBI;
my $binDir = '/OME/dev';
my $dataSource =   "dbi:Pg:dbname=ome";
my $dbHandle = DBI->connect($dataSource, undef, undef,
		{ RaiseError => 1, AutoCommit => 1, InactiveDestroy => 1, PrintError => 1})
                   || die "Could not connect to the database: ".$DBI::errstr;
#	$dbHandle->trace(3);
my @oldColumnNames = (
	'dataset_id',
	'size_x',
	'size_y',
	'base_name',
	'chem_plate',
	'compound_id',
	'wave',
	'well',
	'sample',
	'raster_id'
);

#	$dbHandle->do ('select * into temporary table old_table from attributes_iccb_tiff');
	$dbHandle->do ('drop table attributes_iccb_tiff');
	$dbHandle->do (q /
CREATE TABLE ATTRIBUTES_ICCB_TIFF (
DATASET_ID      OID       REFERENCES DATASETS DEFERRABLE INITIALLY DEFERRED,
SIZE_X          INTEGER,
SIZE_Y          INTEGER,
NUM_WAVES       INTEGER,
MIN             INTEGER,
MAX             INTEGER,
MEAN            FLOAT,
SIGMA           FLOAT,
BASE_NAME       VARCHAR(64),
CHEM_PLATE      VARCHAR(64),
COMPOUND_ID     OID,
WAVE            INTEGER,
WELL            CHAR(3),
SAMPLE          INTEGER,
RASTER_ID       OID
)/);

	$dbHandle->do (q /CREATE INDEX ICCB_TIFF_RASTER_idx ON ATTRIBUTES_ICCB_TIFF (RASTER_ID)/);
	$dbHandle->do (q /CREATE INDEX ICCB_TIFF_ID_idx ON ATTRIBUTES_ICCB_TIFF (DATASET_ID)/);

#	$dbHandle->do ('INSERT INTO attributes_iccb_tiff ('.join(',',@oldColumnNames).') SELECT '.
#		join(',',@oldColumnNames).' FROM old_table');

# Get the dataset_id, raster_id, name and path for each ICCB_TIFF dataset
	my $tuples = $dbHandle->selectall_hashref('SELECT d.dataset_id, d.name, d.path '.
		"FROM datasets d where d.dataset_type='ICCB_TIFF'");
	my $rowRef;
	my %rasterIDs;
	my %newColumns;
	my $fullPath;
	my $command;
	my $datasetID;
	my @columns;
use File::Basename;
my ($name,$path,$suffix);
my ($wave,$sample,$well);
my ($frag,$fragRe);
my ($base,$plate);
my $raster_key;
my %newColumnsHash;
	foreach (@$tuples) {
		$rowRef = $_;
		$datasetID = $rowRef->{dataset_id};
	print STDERR "Analyzing Dataset ID: $datasetID\n";
		$fullPath = $rowRef->{path}.$rowRef->{name};



		# Get the name, path and suffix from the filename.
		($name,$path,$suffix) = fileparse($fullPath,".TIF",".tif");	

		# The suffix (when converted to uppercase) must be equal to "TIF"
		next unless (uc ($suffix) eq ".TIF");

		# Build frag from the end to the begining.
		# eventually it will contain all the stuff after the base name.
		# Get the well,sample,and wave
		# if we find matches, set the variable, and prepend the format to frag
		if ($name =~ /_w([0-9]+)/){ $wave = $1; $frag = "_w".$wave.$frag; }
		if ($name =~ /_s([0-9]+)/){ $sample = $1; $frag = "_s".$sample.$frag; }
		if ($name =~ /_([A-P][0-2][0-9])/){ $well = $1; $frag = "_".$well.$frag;}

		# The last check is that we have to have the well defined.  If not, its not an ICCB_TIFF.
		next unless defined $well;

		# If we made it this far, then we're going to make a dataset object.

		# Make frag a regular expression and use it to find the plate number.
		# Prepend the plate number to frag so we can find the basename.
		# N.B.: If the base name ends in a digit, then we cannot determine the plate number!

		$fragRe = qr/$frag/;
		if ($name =~ /([0-9]+)${fragRe}/){ $plate = $1; $frag = $plate.$frag }

		# The base name is everything before $frag.
		$fragRe = qr/$frag/;
		if ($name =~ /(.*)${fragRe}/){ $base = $1;}

		# Set fields specific to our dataset - we're setting keys and values in the parameters hash, so that when the new
		# method returns, everything will be copasetic.
		
		$newColumnsHash{well}       = $well;
		$newColumnsHash{base_name}  = $base;
		$newColumnsHash{wave}       = $wave;
		$newColumnsHash{sample}     = $sample;
		$newColumnsHash{chem_plate} = $plate;
		$raster_key = $path.$base.$plate.$well.$sample;
		$newColumnsHash{rasterID} = $raster_key;
#print STDERR "Full Path: $fullPath, Raster Key: $raster_key\n";


		if (exists $rasterIDs{$raster_key}) {
			$rasterIDs{$raster_key}->[1]++;
		} else {
			$rasterIDs{$raster_key} = [$datasetID,1];
		}


		
		$command = "$binDir/DumpTIFFheader $fullPath 2>/dev/null |";
		open (STDOUT_PIPE,$command) or die $!;
		while (<STDOUT_PIPE>) {
			chomp;
			($attribute,$value) = split ('\t',$_);
		# trim leading and trailing whitespace on $attribute
			$attribute =~ s/^\s+//;$attribute =~ s/\s+$//;
		# Trim leading and trailing whitespace, set value to undef if not like a C float.
			$value =~ s/^\s+//;$value =~ s/\s+$//;$value = undef unless ($value =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
			if ($attribute eq 'SizeX') {
				$newColumnsHash{size_x} = $value;
			} elsif ($attribute eq 'SizeY') {
				$newColumnsHash{size_y} = $value;
			}
		}
		close (STDOUT_PIPE);
		next unless exists $newColumnsHash{size_x} and $newColumnsHash{size_x} and
			exists $newColumnsHash{size_y} and $newColumnsHash{size_y};


		$command = "$binDir/DumpTIFFstats $fullPath 2>/dev/null |";
		open (STDOUT_PIPE,$command) or die $!;
		@columns = split ('\t', <STDOUT_PIPE>);
		while (<STDOUT_PIPE>) {
			chomp;
			@columns = split ('\t', $_);
		# Trim leading and trailing whitespace, set column value to undef if not like a C float.
			foreach (@columns) {$_ =~ s/^\s+//;$_ =~ s/\s+$//;$_ = undef unless ($_ =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);}
		# Set the XYinfo.
			$newColumnsHash{min} = $columns[0];
			$newColumnsHash{max} = $columns[1];
			$newColumnsHash{mean} = $columns[2];
			$newColumnsHash{sigma} = $columns[3];
		}
		close (STDOUT_PIPE);
		$newColumnsHash{ID} = $datasetID;
		$newColumns{$datasetID} = {%newColumnsHash};
	}

# Write the stuff to the DB.
	my @keys = ('dataset_id','size_x','size_y','num_waves','raster_id','min','max','mean','sigma',
		'well','base_name','wave','sample','chem_plate');

	$command = 'INSERT INTO ATTRIBUTES_ICCB_TIFF ('.join (',',@keys).
		') VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)';
print STDERR $command."\n";
print STDERR join ("\t",@keys)."\n";
	my $sth = $dbHandle->prepare ($command);
	my @values;
	my $hashRef;
	while ( ($datasetID,$rowRef) = each %newColumns) {
		$hashRef = $newColumns{$datasetID};
		@values = ($datasetID,$hashRef->{size_x},$hashRef->{size_y},
			$rasterIDs{$hashRef->{rasterID}}->[1],
			$rasterIDs{$hashRef->{rasterID}}->[0],
			$hashRef->{min},
			$hashRef->{max},
			$hashRef->{mean},
			$hashRef->{sigma},
			$hashRef->{well},
			$hashRef->{base_name},
			$hashRef->{wave},
			$hashRef->{sample},
			$hashRef->{chem_plate}
			);
print STDERR join ("\t",@values)."\n";
		$sth->execute (@values);
	}
	
	

# Deal with the Dataset_Wavelengths - ND_FILTER went from INTEGER to FLOAT

	$dbHandle->do ('select * into temporary table old_table2 from DATASET_WAVELENGTHS');
	$dbHandle->do ('drop table DATASET_WAVELENGTHS');
	$dbHandle->do (q /
CREATE TABLE DATASET_WAVELENGTHS (
DATASET_ID      OID      REFERENCES DATASETS DEFERRABLE INITIALLY DEFERRED,
WAVENUMBER      INTEGER,
EX_WAVELENGTH   INTEGER,
EM_WAVELENGTH   INTEGER,
ND_FILTER       FLOAT
)/);
	$dbHandle->do (q /CREATE INDEX DATASET_WAVELENGTHS_ID_idx ON DATASET_WAVELENGTHS (DATASET_ID)/);
	$dbHandle->do ('INSERT INTO DATASET_WAVELENGTHS SELECT * FROM old_table2');
	

# Create the generic TIFF table
	$dbHandle->do (q /
CREATE TABLE ATTRIBUTES_TIFF (
DATASET_ID      OID       REFERENCES DATASETS DEFERRABLE INITIALLY DEFERRED,
SIZE_X          INTEGER,
SIZE_Y          INTEGER,
MIN             INTEGER,
MAX             INTEGER,
MEAN            FLOAT,
SIGMA           FLOAT
)/);
	$dbHandle->do (q /CREATE INDEX TIFF_ID_idx ON ATTRIBUTES_TIFF (DATASET_ID)/);




# Final commit
	$dbHandle->commit;
