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
#
# Essentialy a hacked version of ICCB_TIF.pm for the support to Applied Precision, Inc.
#
# 1/29/01 -- fmyers@api.com 
#            Created.
#
# 4/02/01 -- Removed all references to Pg, and made everything go via DBI
#            igg
# 8/09/01 -- Added more documentation and an actual implementation (igg@mit.edu).
package OMEDataset::OME_XYZWT::SoftWorx;
use OMEDataset::OME_XYZWT;

@ISA = qw(OMEDataset::OME_XYZWT);

use strict;
use vars qw($AUTOLOAD);

my $myAttributesTable   = 'ATTRIBUTES_DATASET_XYZWT';
my $myType              = 'OME_XYZWT::SoftWorx';

#
# The attributes for this dataset class are specific for SoftWorx.
# The object is written such that the attributes specific to API SoftWorx are clearly marked to make this migration easier in the future.
#
# The format of this description is:
#  FieldName => ['DB_Table','DB_Column'] for single-value fields, and:
#  FieldName => [$dimension1_bounds][$dimension2_bounds]... = { FieldName => ['DB_Table','DB_Column'] }
# for fields containing array references (which may be multidimensional) which in-turn contain hash references.
# Attributes inherited from OMEDataset:
#	ID              => ['DATASETS','DATASET_ID'],
#	Name            => ['DATASETS','NAME],
#	Path            => ['DATASETS','PATH'],
#	Host            => ['DATASETS','HOST'],
#	URL             => ['DATASETS','URL'],
#	InstrumentID    => ['DATASETS','INSTRUMENT_ID'],
#	ExperimenterID  => ['DATASETS','EXPERIMENTER_ID'],
#	Created         => ['DATASETS','CREATED'],
#	Inserted        => ['DATASETS','INSERTED'],
#	Type            => ['DATASETS','DATASET_TYPE'],
#	AttributesTable => ['DATASETS','ATTRIBUTES_TABLE'],
# Top-level OME_XYZWT attributes:
#	SizeX         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_X'],
#	SizeY         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_Y'],
#	SizeZ         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_Z'],
#	NumWaves      => ['ATTRIBUTES_DATASET_XYZWT','NUM_WAVES'],
#	NumTimes      => ['ATTRIBUTES_DATASET_XYZWT','NUM_TIMES'],
#	PixelSizeX    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_X'], # These three are in microns.
#	PixelSizeY    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_Y'],
#	PixelSizeZ    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_Z'],
#	WaveIncrement => ['ATTRIBUTES_DATASET_XYZWT','WAVE_INCREMENT'], # These are not used by SoftWorx, but would be in nm and seconds.
#	TimeIncrement => ['ATTRIBUTES_DATASET_XYZWT','TIME_INCREMENT'],
# XYZinfo: an array of hash references that contain info about every XYZ "stack" (one XYZ stack per wavelength per timepoint)
#	XYZinfo       => [$NumWaves][$NumTimes] = {
#				DeltaTime => ['XYZ_Dataset_Info','deltatiime'], # refers to first XY plane in this stack.
#				Min       => ['XYZ_Dataset_Info','min'],
#				Max       => ['XYZ_Dataset_Info','max'],
#				Mean      => ['XYZ_Dataset_Info','mean'],
#				GeoMean   => ['XYZ_Dataset_Info','geomean'],
#				Sigma     => ['XYZ_Dataset_Info','sigma'],
#				CentroidX => ['XYZ_Dataset_Info','centroid_x'], # the "center of mass" signal distribution
#				CentroidY => ['XYZ_Dataset_Info','centroid_y'],
#				CentroidZ => ['XYZ_Dataset_Info','centroid_z']
#			};
# XYinfo: an array of hash references for XY plane info (one XY plane per Z section per wavelength, per timepoint).
#	XYinfo       => [$NumWaves][$NumTimes][$SizeZ] = {
#				DeltaTime    => ['XY_Dataset_Info','deltatime'],  # seconds since first XY plane in this dataset
#				ExposureTime => ['XY_Dataset_Info','exptime'],
#				StageX       => ['XY_Dataset_Info','stage_x'],  # These are in the instrument's reference frame
#				StageY       => ['XY_Dataset_Info','stage_y'],  # not sure of the units yet.
#				StageZ       => ['XY_Dataset_Info','stage_z'],
#				Min          => ['XY_Dataset_Info','min'],
#				Max          => ['XY_Dataset_Info','max'],
#				Mean         => ['XY_Dataset_Info','mean'],
#				GeoMean      => ['XY_Dataset_Info','geomean'],
#				Sigma        => ['XY_Dataset_Info','sigma'],
#			# API SoftWorx-specific:
#				Photosensor  => ['XY_SoftWorx_Info','photosensor_reading'],
#				IntenScaling => ['XY_SoftWorx_Info','inten_scaling']
#			};
# Wavelengths: an array of hash references that contains info about the wavelengths in the dataset (excitation, emission, neutral density).
# The order of the Wavelengths array corresponds to the order of the wavelengths (wave numbers)
# as stored in the dataset file (not necessarily in any wavelength order).
#	Wavelengths => [$NumWaves] = {
#				ExWavelength => ['Dataset_Wavelengths','ex_wavelength'],
#				EmWavelength => ['Dataset_Wavelengths','em_wavelength'],
#				NDFilter     => ['Dataset_Wavelengths','nd_filter']
#			};
# The three arrays above are instantiated (from the DB) when their respective accessor methods are first called - the exception
# is an object instantiation from a file rather than the DB, in which case these arrays are instantiated in the constructor.
# As with most OME accessor methods they are single-name get/set methods:
# $object->Field() returns the value, $object->Field($value) sets the value and returns the Field's value.
# If the value is a reference, the contents of the reference are deeply copied, so the returned value will be different in these cases
# from the passed-in value.
# Example calls to the $OME factory object:
# Importing datasets - this will return undef if the file is unreadable or is not one of the specified or known types:
# my $dataset = $OME->ImportDataset (Name => '/absolute/path/to/file');
# my $dataset = $OME->ImportDataset (Name => '/absolute/path/to/file', Types => ['A_DATASET_TYPE','ANOTHER_DATASET_TYPE']);
# Reading datasets from the DB:
# my $dataset = $OME->NewDataset (Name => '/absolute/path/to/file', Type => 'SoftWorx');
# my $dataset = $OME->NewDataset (ID => '123');
# Making a new dataset (not from a file or the DB):
# my $dataset = $OME->NewDataset (Name => '/absolute/path/to/file', Type => 'ICCB_TIFF');
# Successfully importing a dataset from a file will cause it to be written to the DB.
# If generating a new dataset from scratch, or modifying a dataset that exists in the DB,
# you must explicitly call $dataset->WriteDB() for it to be written to the DB.
#
# The Fields hash is empty because we inherit all our top-level attributes from OME_XYZWT
#
my %Fields = (
);

# Constructor new
# Required parameters:  Name or ID or Import => '/absolute/path/to/file' and OME.
# This object gets most of its fields from OME_XYZWT.  Only a couple extra fields are added to XYinfo from the extended header.
# This object also implements (over-rides) the Import method from OME_XYZWT


sub new
{
    my $proto           = shift;
    my %params          = @_;
    my $attributes;
    my ($attribute, $value);
	my $importing = 0;

#
# Before we try to instantiate the class, see if we're importing - if so determine if the file is right.
# If the file looks good, then import it, if not return undef immediately.

	if (exists $params{Import}) {   # Determine if the file is the right type.
	# This does a file-check and returns 1 or undef.  It does not actually import anything from the file even if its the right type.
		if (not CheckFileType(\%params)) { 
			return undef;
		}
		$importing = 1;

	# If its the right type, then the Name field is set to the value of the Import field, and the Import field is deleted.
	# This is done because that's one of the ways that the parent class can fill in all of its own fields - using the full file system path
	# passed in as the Name parameter.  The parent class will also determine if this dataset exists, and read things from the database.
	# If the dataset doesn't exist in the database, then the parent class will assign a new dataset ID.
	# The parent class will also change the Name field to contain only the name, and the Path field to contain only the path.
		$params{Name} = delete ($params{Import});
	}

	my $class           = ref($proto) || $proto;

	$params{AttributesTable} = $myAttributesTable;
	$params{Type} = $myType;
	
# The super-class takes care of initializing super-class fields by
# reading from the DB, importing, whatever.
	my $self = $class->SUPER::new(%params);

# Make ourselves an object
	bless($self, $class);

# We don't have any of our own fields, and the superclass already called its own Initialize,
# so we skip the initialize step.
#	$self->Initialize();

# Check DBcurrent to make sure we're importing a brand-new dataset.
# OMEDataset sets DBcurrent if it found a dataset in the database with the same name, path and host.
# Only call Import if this is a new dataset.
	if ($importing and not $self->DBcurrent) {
		$self->Import;
		$self->WriteDB();
	}

    return $self;
}






# Check if the file is the right type.  If not, return undef.
# If the file type is good, then return 1.
# The check is done by looking at the SoftWorx magic number, which is two bytes at offset 96.
# This number also tells us if the file is reverse-endian from the system we're running on.
# We don't do anything with endian-ness at this point, but we have to check both versions of this number.
sub CheckFileType {
my $params = shift;
my $filename = $params->{Import};
my $DVMagicAddress = 96;
my $DVMagicBigEndian = 0xc0a0;
my $DVMagicLittleEndian = 0xa0c0;
my $DVMagic;


	open (DATASET,$params->{Import}) or die "Can't open file '".$params->{Import}."': $!\n";
	binmode (DATASET);

	seek (DATASET, $DVMagicAddress, 0);
	read (DATASET,$DVMagic,2);
	close (DATASET);

	$DVMagic = unpack ('S',$DVMagic);
	return (undef) unless ($DVMagic eq $DVMagicBigEndian or $DVMagic eq $DVMagicLittleEndian);

#
# If we made it here, then we got a good magic number.
#


return 1;
}



# Subroutine Import
# The assumption here is that this is a NEW dataset.
# The initialize method has been called, but all our fields are undef still because there was nobody home in the DB.
# We fill out our own fields, and the XYZinfo, XYinfo and Wavelengths arrays.
# We don't write anything to the DB here - that is done in the WriteDB method.
# We do set the _OME_DB_STATUS_ field to 'DIRTY'.
# Note that the parent's constructor (and from there, the parent's Initialize and Import) has been called, so
# the parent should have filled in its fields.  We only need to worry about our own and possibly over-write some of
# the parent's fields, but not in this case.
sub Import {
my $self = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my $DumpSoftWorxHeader = $OME->binPath.'DumpSoftWorxHeader';
my $DumpSoftWorxExtHeader = $OME->binPath.'DumpSoftWorxExtHeader';
my $DumpSoftWorxStats = $OME->binPath.'DumpSoftWorxStats';
my ($XYZinfo,$XYinfo,$Wavelengths);
my ($zSection,$waveNum,$timePoint);
my $datasetPath = $self->{Path}.$self->{Name};
print STDERR "SoftWorx.pm:  Importing $datasetPath\n";
my $command;

my ($attribute,$value);
my @columns;

	my $tempFileNameErr = $OME->GetTempName ('SoftWorxImport','err') or die "Couldn't get a name for a temporary file $!\n";

# This will get the dimentions, etc of the dataset.
# The output of this program is one attribute per line (attribute name \t attribute value).
# Conveniently, the attribute names match the Object's field names so me don't need a map.
	$command = "$DumpSoftWorxHeader $datasetPath 2> $tempFileNameErr |";
	open (STDOUT_PIPE,$command);
	while (<STDOUT_PIPE>) {
		chomp;
		($attribute,$value) = split ('\t',$_);
	# trim leading and trailing whitespace on $attribute
		$attribute =~ s/^\s+//;$attribute =~ s/\s+$//;
	# Trim leading and trailing whitespace, set value to undef if not like a C float.
		$value =~ s/^\s+//;$value =~ s/\s+$//;$value = undef unless ($value =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
		$self->{$attribute} = $value;
	}
	close (STDOUT_PIPE);

foreach (  keys (%$self) ) {
print STDERR "SoftWorx:Import, self: $_ => ".$self->{$_}."\n";
}

# This will dump the info in the extended header.
# The output is one line per XY plane.
	print STDERR "SoftWorx:Import - Checking if $DumpSoftWorxExtHeader is executable\n";
	if (-x $DumpSoftWorxExtHeader) {
		$command = "$DumpSoftWorxExtHeader $datasetPath 2>> $tempFileNameErr |";
	print STDERR "SoftWorx:Import - $DumpSoftWorxExtHeader is executable\nExecuting $command\n";
		open (STDOUT_PIPE,$command);
		@columns = split ('\t', <STDOUT_PIPE>);
	print STDERR ">$_\n@columns\n";
		while (<STDOUT_PIPE>) {
			chomp;
			@columns = split ('\t', $_);
		# Trim leading and trailing whitespace, set column value to undef if not like a C float.
			foreach (@columns) {$_ =~ s/^\s+//;$_ =~ s/\s+$//;$_ = undef unless ($_ =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);}
			($zSection,$waveNum,$timePoint) = ($columns[0],$columns[1],$columns[2]);
			$XYinfo->[$waveNum][$timePoint][$zSection]->{Photosensor}  = $columns[3];
			$XYinfo->[$waveNum][$timePoint][$zSection]->{DeltaTime}    = $columns[4];
			$XYinfo->[$waveNum][$timePoint][$zSection]->{StageX}       = $columns[5];
			$XYinfo->[$waveNum][$timePoint][$zSection]->{StageY}       = $columns[6];
			$XYinfo->[$waveNum][$timePoint][$zSection]->{StageZ}       = $columns[7];
			$XYinfo->[$waveNum][$timePoint][$zSection]->{Min}          = int ($columns[8]) if defined $columns[8];
			$XYinfo->[$waveNum][$timePoint][$zSection]->{Max}          = int ($columns[9]) if defined $columns[9];
			$XYinfo->[$waveNum][$timePoint][$zSection]->{Mean}         = $columns[10];
			$XYinfo->[$waveNum][$timePoint][$zSection]->{ExposureTime} = $columns[11];
			$Wavelengths->[$waveNum]->{NDFilter}                       = $columns[12];
			$Wavelengths->[$waveNum]->{ExWavelength}                   = int ($columns[13]) if defined $columns[13] and $columns[13] > 0;
			$Wavelengths->[$waveNum]->{EmWavelength}                   = int ($columns[14]) if defined $columns[14] and $columns[14] > 0;
			$XYinfo->[$waveNum][$timePoint][$zSection]->{IntenScaling} = $columns[15];
			if ($zSection == 0) {
				$XYZinfo->[$waveNum][$timePoint]->{DeltaTime} = $XYinfo->[$waveNum][$timePoint][$zSection]->{DeltaTime};
			}
		}
		close (STDOUT_PIPE);

	}

# This will calculate statistics about XYZ stacks, and output one line per stack.
# The file will actually be read at this point, and an error reported if its corrupt.
	$command = "$DumpSoftWorxStats $datasetPath 2>> $tempFileNameErr |";
	open (STDOUT_PIPE,$command);
	@columns = split ('\t', <STDOUT_PIPE>);
	while (<STDOUT_PIPE>) {
		chomp;
		@columns = split ('\t', $_);
	# Trim leading and trailing whitespace, set column value to undef if not like a C float.
		foreach (@columns) {$_ =~ s/^\s+//;$_ =~ s/\s+$//;$_ = undef unless ($_ =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);}
		($waveNum,$timePoint) = ($columns[ 0],$columns[ 2]);
		if (not defined $Wavelengths->[$waveNum]->{EmWavelength} and defined $columns[ 1] and $columns[ 1]) {
			$Wavelengths->[$waveNum]->{EmWavelength} = $columns[ 1];
		}
		$XYZinfo->[$waveNum][$timePoint]->{Min}       = int ($columns[ 3]) if defined $columns[3];
		$XYZinfo->[$waveNum][$timePoint]->{Max}       = int ($columns[ 4]) if defined $columns[4];
		$XYZinfo->[$waveNum][$timePoint]->{Mean}      = $columns[ 5];
		$XYZinfo->[$waveNum][$timePoint]->{GeoMean}   = $columns[ 6];
		$XYZinfo->[$waveNum][$timePoint]->{Sigma}     = $columns[ 7];
		$XYZinfo->[$waveNum][$timePoint]->{CentroidX} = $columns[ 8];
		$XYZinfo->[$waveNum][$timePoint]->{CentroidY} = $columns[ 9];
		$XYZinfo->[$waveNum][$timePoint]->{CentroidZ} = $columns[10];
	}
	close (STDOUT_PIPE);

	$self->XYinfo($XYinfo);
	$self->XYZinfo($XYZinfo);
	$self->Wavelengths($Wavelengths);

	$self->{_OME_DB_STATUS_} = 'DIRTY';
}


sub XYinfo {
my $self = shift;
# Call the super-class XYinfo, and work on the reference it returns.
my $XYinfo = $self->SUPER::XYinfo(shift);
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();

my $tuples;
my %row;
#
# Call the superclass:
	

	if (defined $XYinfo) {
		die "Parameter passed to $self->XYinfo is not a reference to a 3-D array.\n"
			unless ref($XYinfo) eq 'ARRAY' and ref ($XYinfo->[0]) eq 'ARRAY' and ref ($XYinfo->[0][0]) eq 'ARRAY';
		die "The bounds of the 3-D array reference passed to $self->XYinfo do not match [NumWaves][NumTimes][SizeZ].\n"
			unless scalar (@$XYinfo) eq $self->{NumWaves} and
				scalar (@{$XYinfo->[0]}) eq $self->{NumTimes} and
				scalar (@{$XYinfo->[0][0]}) eq $self->{SizeZ};

		my ($waveNum,$timePoint,$zSection);
		my ($numWaves,$numTimes,$numZ) = ($self->{NumWaves},$self->{NumTimes},$self->{SizeZ});
		for ($waveNum = 0; $waveNum < $numWaves; $waveNum++) {
			for ($timePoint = 0; $timePoint < $numTimes; $timePoint++) {
				for ($zSection = 0; $zSection < $numZ; $zSection++) {
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Photosensor} = 
						$XYinfo->[$waveNum][$timePoint][$zSection]->{Photosensor};
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{IntenScaling} = 
						$XYinfo->[$waveNum][$timePoint][$zSection]->{IntenScaling};
				}		
			}
		}

# Tell WriteDB to do the write.
	$self->{_OME_DB_STATUS_} = 'DIRTY';
	}

	elsif (not exists $self->{XYinfo}) {
	#
	# Here is the API SoftWorx-specific stuff:
		$tuples = $dbh->selectall_hashref ('SELECT * FROM XY_SoftWorx_Info WHERE dataset_id='.$self->{ID});
		foreach (@$tuples) {
			%row = %$_;
			$self->{XYinfo}->[$row{wavenumber}][$row{timepoint}][$row{zsection}]->{Photosensor}  = $row{photosensor_reading};
			$self->{XYinfo}->[$row{wavenumber}][$row{timepoint}][$row{zsection}]->{IntenScaling} = $row{inten_scaling}
		}
	}
	
	return $self->{XYinfo};
}




sub WriteDB_XYinfo {
my $self = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my $sth;
my ($wave,$time,$zSection);
my $XYinfo = $self->XYinfo;
my ($numWaves,$numTimes,$numZ) = (scalar (@$XYinfo), scalar (@{$XYinfo->[0]}),scalar (@{$XYinfo->[0][0]}));
my $ID = $self->ID;

	$self->SUPER::WriteDB_XYinfo();

#
# Insert the SoftWorx-specific stuff.
	$dbh->do ('DELETE FROM XY_SoftWorx_Info WHERE dataset_id = '.$ID);

	$sth = $dbh->prepare('INSERT INTO XY_SoftWorx_Info '.
		'(dataset_id,wavenumber,timepoint,zsection,photosensor_reading,inten_scaling) '.
		'VALUES (?,?,?,?,?,?)'
	);

	for ($wave=0;$wave<$numWaves;$wave++) {
		for ($time=0;$time<$numTimes;$time++) {
			for ($zSection=0;$zSection<$numZ;$zSection++) {
				$sth->execute($ID,$wave,$time,$zSection,
					$XYinfo->[$wave][$time][$zSection]->{Photosensor},
					$XYinfo->[$wave][$time][$zSection]->{IntenScaling}
				);
			}
		}
	}
}



1;
