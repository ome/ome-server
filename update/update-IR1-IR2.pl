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
		{ RaiseError => 1, AutoCommit => 0, InactiveDestroy => 1})
                   || die "Could not connect to the database: ".$DBI::errstr;
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

	$dbHandle->do ('select * into temporary table old_table from attributes_iccb_tiff');
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

	$dbHandle->do ('INSERT INTO attributes_iccb_tiff ('.join(',',@oldColumnNames).') SELECT '.
		join(',',@oldColumnNames).' FROM old_table');

# Get the dataset_id, raster_id, name and path for each ICCB_TIFF dataset
	my $tuples = $dbHandle->selectall_hashref('SELECT d.dataset_id, d.name, d.path, t.raster_id '.
		'FROM datasets d, ATTRIBUTES_ICCB_TIFF t where d.dataset_id=t.dataset_id');
	my $rowRef;
	my %rasterIDs;
	my %newColumns;
	my $fullPath;
	my $command;
	my $datasetID;
	my @columns;
	foreach (@$tuples) {
		$rowRef = $_;
		$datasetID = $rowRef->{dataset_id};
	print STDERR "Dataset ID: $datasetID\n";
		if (exists $rasterIDs{$rowRef->{raster_id}}) {
			$rasterIDs{$rowRef->{raster_id}}->[1]++;
		} else {
			$rasterIDs{$rowRef->{raster_id}} = [$datasetID,1];
		}
		$fullPath = $rowRef->{path}.$rowRef->{name};
		
		$command = "$binDir/DumpTIFFheader $fullPath |";
		open (STDOUT_PIPE,$command) or die $!;
		while (<STDOUT_PIPE>) {
			chomp;
			($attribute,$value) = split ('\t',$_);
		# trim leading and trailing whitespace on $attribute
			$attribute =~ s/^\s+//;$attribute =~ s/\s+$//;
		# Trim leading and trailing whitespace, set value to undef if not like a C float.
			$value =~ s/^\s+//;$value =~ s/\s+$//;$value = undef unless ($value =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
			if ($attribute eq 'SizeX') {
				$newColumns{$datasetID}->{size_x} = $value;
			} elsif ($attribute eq 'SizeY') {
				$newColumns{$datasetID}->{size_y} = $value;
			}
		}
		close (STDOUT_PIPE);



		$command = "$binDir/DumpTIFFstats $fullPath |";
		open (STDOUT_PIPE,$command) or die $!;
		@columns = split ('\t', <STDOUT_PIPE>);
		while (<STDOUT_PIPE>) {
			chomp;
			@columns = split ('\t', $_);
		# Trim leading and trailing whitespace, set column value to undef if not like a C float.
			foreach (@columns) {$_ =~ s/^\s+//;$_ =~ s/\s+$//;$_ = undef unless ($_ =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);}
		# Set the XYinfo.
			$newColumns{$datasetID}->{min} = $columns[0];
			$newColumns{$datasetID}->{max} = $columns[1];
			$newColumns{$datasetID}->{mean} = $columns[2];
			$newColumns{$datasetID}->{sigma} = $columns[3];
		}
		close (STDOUT_PIPE);
		$newColumns{$datasetID}->{ID} = $datasetID;
		$newColumns{$datasetID}->{rasterID} = $rowRef->{raster_id};
	}

# Write the stuff to the DB.
my ($keys,$values);
	while ( ($datasetID,$rowRef) = each %newColumns) {
while ( ($keys,$values) = each %$rowRef ) {
	print STDERR "$keys  =>  $values\n";
}
	print STDERR "Dataset ID: $datasetID\n";

		$command = 'UPDATE ATTRIBUTES_ICCB_TIFF SET '.
			'size_x = '.$newColumns{$datasetID}->{size_x}.
			', size_y = '.$newColumns{$datasetID}->{size_y}.
			', num_waves = '.$rasterIDs{$newColumns{$datasetID}->{rasterID}}->[1].
			', raster_id = '.$rasterIDs{$newColumns{$datasetID}->{rasterID}}->[0].
			', min = '.$newColumns{$datasetID}->{min}.
			', max = '.$newColumns{$datasetID}->{max}.
			', mean = '.$newColumns{$datasetID}->{mean}.
			', sigma = '.$newColumns{$datasetID}->{sigma}.
			" WHERE dataset_id=$datasetID";
		print STDERR $command,"\n";
		$dbHandle->do ($command);
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
