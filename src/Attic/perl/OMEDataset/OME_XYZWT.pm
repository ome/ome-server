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
package OMEDataset::OME_XYZWT;
use OMEDataset;

@ISA = qw(OMEDataset);

use strict;
use vars qw($AUTOLOAD);

my $myAttributesTable   = 'ATTRIBUTES_DATASET_XYZWT';
my $myType              = 'OME_XYZWT';

#
# The attributes for this dataset class are general to 5-D datasets composed of XYZ-Wave-Time type data.
# The OMEDataset parent class does not specify any dimensionality, and is meant to be a virtual class.
# The other implemented dataset is ICCB_TIFF - used by the ICCB for cell-based visual screening.
# In the ICCB_TIFF case, the one:one dataset:file mapping is maintained, even for cases where multiple wavelengths are stored in separate
# TIFF files.  The different wavelengths are 'linked' through a 'raster_id' attribute.  The accessor methods for ICCB_TIFF attributes return
# the same identical data for each dataset in a set of datasets linked through their 'raster_id's.
# The inherited OMEDataset attributes are different for each dataset, but the ICCB_TIFF attributes are the same.
# The idea is to make this 'collection of TIFFs' behave as similarly as possible to a
# true 5-D dataset - such that missing dimensions have a size of 1 (rather than being undefined or 0).
# Although this might seem like a hack, its in fact a work-around to deal with the following:
# Collections of TIFFs must be supported, and the files must left in their original state (rather than doing conversions), 
# need to have a consistent interface between the two very different ways of storing otherwise similar data.
# Its the best I was able to come up with, but better (or just different) suggestions are welcome.
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
# Top-level XYZWT attributes:
#	SizeX         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_X'],
#	SizeY         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_Y'],
#	SizeZ         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_Z'],
#	NumWaves      => ['ATTRIBUTES_DATASET_XYZWT','NUM_WAVES'],
#	NumTimes      => ['ATTRIBUTES_DATASET_XYZWT','NUM_TIMES'],
#	PixelSizeX    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_X'], # These three are in microns.
#	PixelSizeY    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_Y'],
#	PixelSizeZ    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_Z'],
#	WaveIncrement => ['ATTRIBUTES_DATASET_XYZWT','WAVE_INCREMENT'], # These would be in nm and seconds.
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
#				Sigma        => ['XY_Dataset_Info','sigma']
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
# As of this writing only the first two elements of the array referenced by the hash keys are actually used.
# The rest can (and should) be determined from the schema at runtime.
# FIXME:  This array reference should probably replaced with a string in table.column format.
#
# The attributes in XYZinfo and XYinfo could be implemnted in a similar (or at least consistent) way,
# but I haven't done that yet because it didn't seem compelling enough.
#
my %Fields = (
	ID            => ['ATTRIBUTES_DATASET_XYZWT','DATASET_ID',    'OID', 'DATASETS'],
	SizeX         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_X',        'INTEGER'              ],
	SizeY         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_Y',        'INTEGER'              ],
	SizeZ         => ['ATTRIBUTES_DATASET_XYZWT','SIZE_Z',        'INTEGER'              ],
	NumWaves      => ['ATTRIBUTES_DATASET_XYZWT','NUM_WAVES',     'INTEGER'              ],
	NumTimes      => ['ATTRIBUTES_DATASET_XYZWT','NUM_TIMES',     'INTEGER'              ],
	PixelSizeX    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_X',  'FLOAT'                ],
	PixelSizeY    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_Y',  'FLOAT'                ],
	PixelSizeZ    => ['ATTRIBUTES_DATASET_XYZWT','PIXEL_SIZE_Z',  'FLOAT'                ],
	WaveIncrement => ['ATTRIBUTES_DATASET_XYZWT','WAVE_INCREMENT','FLOAT'                ],
	TimeIncrement => ['ATTRIBUTES_DATASET_XYZWT','TIME_INCREMENT','FLOAT'                ]
);

# Constructor new
# Required parameters:  Name or ID or Import => '/absolute/path/to/file' and OME.
# This is a sub-class of the Dataset class.  The constructor over-rides Dataset's constructor, but calls
# it with a couple exta parameters.
# The extra parameters are AttributesTable=>$myAttributesTable and Type=>$myType.  It is in-fact an error to
# call the OMEDataset constructor (which must eventually be called) without specifying these parameters
# because OMEDataset is (for now) a virtual class.
# These parameters and any others passed into this constructor will become datamembers of the resulting class.
# The superclass constructor sets the fields in the superclass only.  It also sets the field
# values (by reading the DB) if an ID was passed as a parameter.
# The Type parameter is required for the Dataset constructor, but is ignored in the sub-class constructor.
# There are no 'generic' datasets at this time, so all new datasets should be created via their sub-classes.
#
# We should be able to call the constructor with a filename and have it "import" the dataset into OME.
# The way to do this is call SomeOMEDatasetClass->new (Import => "/absolute/path/to/file").
# Normally, a client would call the ImportDataset method directly from OME ($myOME->ImportDataset() ).
# OME calls each Dataset class it knows about in turn, and stops when it gets a non-NULL dataset.
# The new method needs to determine (quickly!) if the specified file is of the correct type.  If not, it should immediately
# return undef.  If it can import this file, then do so, returning an object reference as usual.
# Actually, the difference with Import is that it goes and writes the all the attributes to the database - unlike the other ways
# of calling new, which only return a reference, and nothing gets written until WriteDB is called.
# Ambiguous dataset types (for example a derived class and its parent) will be imported as the first successfull import command, so
# the order of import attempts is important.  This is determined by how the OME->ImportDataset method is called (the Types parameter).
# Other notes:
#   Currently, the OMEDataset object and its relational counterpart in the database are supposed to be "synchronized".
#   It is possible to create an OMEDataset object without a database couterpart, but this is ill-advised.
#   You can call new with a Name and/or Path attributes, and a new dataset will be created, and a dataset ID assigned.
#   The assigned ID will be unique across all datasets in the database that OME is connected to.
#   The dataset will only be written to the database if the WriteDB method is called, but the assigned ID can never be used again regardless of that.
#   The WriteDB method will write to the database only those attributes specified in the "%Fields" hash above.
#   This method is smart enough to write the fields for the sub-class as well as all of its super-classes up to OMEDataset itself.
#   If there are other attributes that belong in the database other than those in the "%Fields" hash, their writing will
#   have to be implemented separately.  This is unfortunately the case with XYZinfo and XYinfo because these attributes are
#   arrays, and we don't store arrays in table rows unless the array is for all intents and purposes "atomic".
#   Dealing with arrays (and other things like that) in a general way may be implemented in the future (FIXME?).
#   As a work-around we over-ride WriteDB in this class to also call WriteDB_XYZinfo, WriteDB_XYinfo and WrideDB_Wavelengths.
#   It should probably be policy that all of these should exist in the database - even datasets composed entirely of one XY plane.
#   One possible work-around is to make the XYZinfo acessor methods for an XY dataset return the XYinfo structure without reading the XYZinfo table.
#

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

# These have to be provided by the sub-class!!!
#    $params{AttributesTable} = $myAttributesTable;
#	$params{Type} = $myType;
	
# The super-class takes care of initializing super-class fields by
# reading from the DB, importing, whatever.
    my $self = $class->SUPER::new(%params);

# The sub-class can over-ride the fields hash, and pass it in as a parameter.
    my $fieldsRef = \%Fields;
    $fieldsRef = delete $params{Fields} if exists $params{Fields};

# Add the fields->DB map to the object.
    push(@{$self->{_OME_FIELDS_}}, $fieldsRef);
	$self->{_MY_FIELDS_} = $fieldsRef;

# Here we set our sub-class fields to undef unless the super-class already assigned them.
    while(($attribute, $value) = each(%Fields))
    {
        $self->{$attribute} = undef unless exists ($self->{$attribute});
    }

# Make ourselves an object
    bless($self, $class);

# Initialize our own fields - either from DB or by importing a file.
# N.B.:  We are already a class, but these aren't being called as object methods, but as package subroutines.
# These routines will over-ride the super-class Initialize and Import methods, but the super-class will call its own
# Initialize and Import as package sub-routines from the super-class package's new method, not the methods we define here.
# What this means is that a class's Import and Initialize routines are essentially acessory functions to the new method.
# In OO parlance, they would be private methods which cannot be over-ridden.
# Calling $self->Initialize, would call the Initialize method in this package (obviously), but you shouldn't really do that
# outside of the new method.  That would be the case if we declared these private in a stricter OO language.
    Initialize($self);

# Check DBcurrent to make sure we're importing a brand-new dataset.
# OMEDataset sets DBcurrent if it found a dataset in the database with the same name, path and host.
# Only call Import if this is a new dataset.
	if ($importing and not $self->DBcurrent) {
		Import ($self);
		$self->WriteDB();
	}

    return $self;
}

sub Initialize {
	my $self = shift;
	my $OME = $self->{OME};
	my $dbh = $OME->DBIhandle();
	my $cmd;
	my $sth;
	my $row;
	my $tuples;
	my $OMEfields = $self->{_MY_FIELDS_};
	my %DBFieldMap;
	my ($attribute,$value);
	my $fname;
	my $pname;
	
	$self->{_OME_DB_STATUS_} = 'DIRTY';

# Reverse the Field->DB map in order to have a way to look up parameter names based on database column names.
	while ( ($attribute,$value) = each (%$OMEfields) )
	{
		$DBFieldMap{$value->[1]} = $attribute;
	}
	
	$pname = $DBFieldMap{DATASET_ID};


	$sth = $dbh->prepare ("SELECT * FROM ".$self->{AttributesTable}." WHERE DATASET_ID=".$self->{$pname});
	$sth->execute();
	$row = $sth->fetchrow_arrayref;

# Read the data out of the database, putting the right values in the right fields.
	if (defined $row and $row)
	{
	my $i;

		for ($i=0; $i < $sth->{NUM_OF_FIELDS};$i++)
		{
			$fname = $sth->{NAME_uc}->[$i];
			$pname = $DBFieldMap{$fname};
			$self->{$pname} = $row->[$i];
		}
		$self->{_OME_DB_STATUS_} = 'CURRENT';
	}


	$sth->finish();
	undef $sth;
	undef $dbh;


}

sub GetClassFieldsHash {
	return (%Fields);
}



# Check if the file is the right type.  If not, return undef.
# If the file type is good, then return 1.
# Since this base 5D class is virtual, we always return undef.
# a sub-class would actually implement this method.
# This method could become non-virtual if we had our own OME_XYZWT file type.
sub CheckFileType {
my $params = shift;
my $filename = $params->{Import};
my $DVMagicAddress = 96;
my $DVMagicBigEndian = 0xc0a0;
my $DVMagicLittleEndian = 0xa0c0;
my $DVMagic;


	
return undef;
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
#
# Implementation left to sub-classes
}

sub XYZinfo {
my $self = shift;
my $XYZinfo = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();

my $tuples;
my %row;
# This is a combined Get/Set method.  If no parameter is passed, then its a Get method.
# If a parameter is passed, then it is a Set method.
# if used as a Get method, we import data from the XYZ_Dataset_Info table to build up the XYZinfo array.
# We read the database the first time this method is called, and stash the results in the XYZinfo field
# (which doesn't exist until this method is called).
# subsequent calls return the 2-D array reference stored in the XYZinfo field.
# The 2-D array is accessed as XYZinfo->[WaveNumber][Timepoint]->{DeltaTime}, etc.
# It is a FATAL error if the array bounds returned from the database do not match $Dataset->NumWaves and $Dataset->NumTimes.
# It is a FATAL error if a parameter is passed, but it is not a 2-D array reference,
#   or if the bounds of the array do not match $Dataset->NumWaves and $Dataset->NumTimes.
# In the Set method sense, the arrays in the array reference are copied to a new array reference,
#   which is the value of the XYZinfo key in the object hash.  A reference to the copied arrays is returned.
# The Set method does not write to the database, that is only done in the WriteDB method, which should call WriteDB_XYZinfo.
	if (defined $XYZinfo) {
		die "Parameter passed to $self->XYZinfo is not a reference to a 2-D array.\n"
			unless ref($XYZinfo) eq 'ARRAY' and ref ($XYZinfo->[0]) eq 'ARRAY';
		die 'The bounds of the 2-D array reference passed to '.ref($self).'->XYZinfo do not match ['.
				ref($self).'->NumWaves]['.ref($self)."->NumTimes].\nExpected [".$self->{NumWaves}.']['.$self->{NumTimes}.
				'], Got ['.scalar (@$XYZinfo).']['.scalar (@{$XYZinfo->[0]})."].\n"
			unless scalar (@$XYZinfo) eq $self->{NumWaves} and scalar (@{$XYZinfo->[0]}) eq $self->{NumTimes};

		my ($waveNum,$timePoint);
		my ($numWaves,$numTimes) = ($self->{NumWaves},$self->{NumTimes});
		for ($waveNum = 0; $waveNum < $numWaves; $waveNum++) {
			for ($timePoint = 0; $timePoint < $numTimes; $timePoint++) {
				$self->{XYZinfo}->[$waveNum][$timePoint] = {
					DeltaTime => $XYZinfo->[$waveNum][$timePoint]->{DeltaTime},
					Min       => $XYZinfo->[$waveNum][$timePoint]->{Min},
					Max       => $XYZinfo->[$waveNum][$timePoint]->{Max},
					Mean      => $XYZinfo->[$waveNum][$timePoint]->{Mean},
					GeoMean   => $XYZinfo->[$waveNum][$timePoint]->{GeoMean},
					Sigma     => $XYZinfo->[$waveNum][$timePoint]->{Sigma},
					CentroidX => $XYZinfo->[$waveNum][$timePoint]->{CentroidX},
					CentroidY => $XYZinfo->[$waveNum][$timePoint]->{CentroidY},
					CentroidZ => $XYZinfo->[$waveNum][$timePoint]->{CentroidZ},
				};			
			}
		}

# Tell WriteDB to do the write.
	$self->{_OME_DB_STATUS_} = 'DIRTY';
	}

	elsif (not exists $self->{XYZinfo}) {
		$tuples = $dbh->selectall_hashref ('SELECT * FROM XYZ_Dataset_Info WHERE dataset_id='.$self->{ID});
		foreach (@$tuples) {
			%row = %$_;
			$self->{XYZinfo}->[$row{wavenumber}][$row{timepoint}] = {
				DeltaTime => $row{deltatiime},
				Min       => $row{min},
				Max       => $row{max},
				Mean      => $row{mean},
				GeoMean   => $row{geomean},
				Sigma     => $row{sigma},
				CentroidX => $row{centroid_x},
				CentroidY => $row{centroid_y},
				CentroidZ => $row{centroid_z}
			};
		}
	}
	
	return $self->{XYZinfo};
}


sub XYinfo {
my $self = shift;
my $XYinfo = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();

my $tuples;
my %row;
# This is a combined Get/Set method.  If no parameter is passed, then its a Get method.
# If a parameter is passed, then it is a Set method.
# if used as a Get method, we import data from the XY_Dataset_Info table to build up the XYinfo array.
# We read the database the first time this method is called, and stash the results in the XYinfo field
# (which doesn't exist until this method is called).
# subsequent calls return the 3-D array reference stored in the XYinfo field.
# The 3-D array is accessed as XYinfo->[WaveNumber][Timepoint][Zsection]->{DeltaTime}, etc.
# It is a FATAL error if the array bounds returned from the database do not match $Dataset->NumWaves, $Dataset->NumTimes and $Dataset->SizeZ.
# It is a FATAL error if a parameter is passed, but it is not a 3-D array reference,
#   or if the bounds of the array do not match $Dataset->NumWaves, $Dataset->NumTimes, and $Dataset->SizeZ.
# In the Set method sense, the arrays in the array reference are copied to a new array reference,
#   which is the value of the XYinfo key in the object hash.  A reference to the copied arrays is returned.
# The Set method does not write to the database, that is only done in the WriteDB method, which should call WriteDB_XYinfo.
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
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection] = {
						DeltaTime    => $XYinfo->[$waveNum][$timePoint][$zSection]->{DeltaTime},
						ExposureTime => $XYinfo->[$waveNum][$timePoint][$zSection]->{ExposureTime},
						StageX       => $XYinfo->[$waveNum][$timePoint][$zSection]->{StageX},
						StageY       => $XYinfo->[$waveNum][$timePoint][$zSection]->{StageY},
						StageZ       => $XYinfo->[$waveNum][$timePoint][$zSection]->{StageZ},
						Min          => $XYinfo->[$waveNum][$timePoint][$zSection]->{Min},
						Max          => $XYinfo->[$waveNum][$timePoint][$zSection]->{Max},
						Mean         => $XYinfo->[$waveNum][$timePoint][$zSection]->{Mean},
						GeoMean      => $XYinfo->[$waveNum][$timePoint][$zSection]->{GeoMean},
						Sigma        => $XYinfo->[$waveNum][$timePoint][$zSection]->{Sigma},
					};
				}		
			}
		}

# Tell WriteDB to do the write.
	$self->{_OME_DB_STATUS_} = 'DIRTY';
	}

	elsif (not exists $self->{XYinfo}) {
		$tuples = $dbh->selectall_hashref ('SELECT * FROM XY_Dataset_Info WHERE dataset_id='.$self->{ID});
		foreach (@$tuples) {
			%row = %$_;
			$self->{XYinfo}->[$row{wavenumber}][$row{timepoint}][$row{zsection}] = {
				DeltaTime    => $row{deltatiime},
				ExposureTime => $row{exptime},
				StageX       => $row{stage_x},
				StageY       => $row{stage_y},
				StageZ       => $row{stage_z},
				Min          => $row{min},
				Max          => $row{max},
				Mean         => $row{mean},
				GeoMean      => $row{geomean},
				Sigma        => $row{sigma}
			};
		}
	}
	
	return $self->{XYinfo};
}



sub Wavelengths {
my $self = shift;
my $Wavelengths = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();

my $tuples;
my %row;
# This is a combined Get/Set method.  If no parameter is passed, then its a Get method.
# If a parameter is passed, then it is a Set method.
# if used as a Get method, we import data from the Dataset_Wavelengths table to build up the Wavelengths array.
# We read the database the first time this method is called, and stash the results in the Wavelengths field
# (which doesn't exist until this method is called).
# subsequent calls return the array reference stored in the Wavelengths field.
# The array is accessed as Wavelengths->[WaveNumber]->{ExWavelength}, etc.
# It is a FATAL error if the array bounds returned from the database do not match $Dataset->NumWaves.
# It is a FATAL error if a parameter is passed, but it is not an array reference,
#   or if the bounds of the array do not match $Dataset->NumWaves.
# In the Set method sense, the array in the array reference is copied to a new array reference,
#   which is the value of the Wavelengths key in the object hash.  A reference to the copied array is returned.
# The Set method does not write to the database, that is only done in the WriteDB method, which should call WriteDB_Wavelengths.
# The attributes of this array are:
# ExWavelength:  The excitation wavelength in nm.
# EmWavelength:  The emission wavelength in nm.
# NDFilter:      The neutral density filter, as a percentage from 0.0 to 1.0
# N.B.:  This array is sorted by wave number, so that Wavelengths[0] is the first wave in the dataset, etc.
	if (defined $Wavelengths) {
		die "Parameter passed to $self->Wavelengths is not a reference to an array.\n"
			unless ref($Wavelengths) eq 'ARRAY';
		die "The bounds of the array reference passed to $self->Wavelengths do not match [$self->NumWaves].\n"
			unless scalar (@$Wavelengths) eq $self->{NumWaves};

		my ($waveNum,$numWaves) = (0,$self->{NumWaves});
		for ($waveNum = 0; $waveNum < $numWaves; $waveNum++) {
			$self->{Wavelengths}->[$waveNum] = {
				ExWavelength => $Wavelengths->[$waveNum]->{ExWavelength},
				EmWavelength => $Wavelengths->[$waveNum]->{EmWavelength},
				NDFilter     => $Wavelengths->[$waveNum]->{NDFilter}
			};			
		}

# Tell WriteDB to do the write.
	$self->{_OME_DB_STATUS_} = 'DIRTY';
	}

	elsif (not exists $self->{Wavelengths}) {
		$tuples = $dbh->selectall_hashref ('SELECT * FROM Dataset_Wavelengths WHERE dataset_id='.$self->{ID}.'ORDER BY wavenumber ASC');
		foreach (@$tuples) {
			%row = %$_;
			$self->{Wavelengths}->[$row{wavenumber}] = {
				ExWavelength => $row{ex_wavelength},
				EmWavelength => $row{em_wavelength},
				NDFilter     => $row{nd_filter}
			};
		}
	}

	return $self->{Wavelengths};
}



#
# This is an over-ride of the superclass WriteDB method.
# The superclass wethod relies on all attributes written to the DB to be expressed in the %Fields hash above
# and the equivalent for all parent classes.  Here we have to write the arrays that aren't represented in the %Fields hash above.
# If this method is inherited and over-ridden by a sub-class, make sure you don't inadvertantly leave this out!
sub WriteDB {
my $self = shift;

	
# Call the superclass WriteDB
	$self->SUPER::WriteDB ();

# Write our specific attributes not included in the Fields hash
	$self->WriteDB_XYZinfo;
	$self->WriteDB_XYinfo;
	$self->WriteDB_Wavelengths;

}


sub WriteDB_XYZinfo {
my $self = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my ($wave,$time);
my $XYZinfo = $self->XYZinfo;
return unless defined $XYZinfo;
my ($numWaves,$numTimes) = (scalar (@$XYZinfo), scalar (@{$XYZinfo->[0]}));
my $ID = $self->ID;

# Clean out any old info for this dataset.
	$dbh->do ('DELETE FROM xyz_dataset_info WHERE dataset_id = '.$ID);

my $sth = $dbh->prepare('INSERT INTO xyz_dataset_info '.
		'(dataset_id,wavenumber,timepoint,deltatime,min,max,mean,geomean,sigma,centroid_x,centroid_y,centroid_z) '.
		'VALUES (?,?,?,?,?,?,?,?,?,?,?,?)'
	);

	for ($wave=0;$wave<$numWaves;$wave++) {
		for ($time=0;$time<$numTimes;$time++) {
			$sth->execute($ID,$wave,$time,
				$XYZinfo->[$wave][$time]->{DeltaTime},
				$XYZinfo->[$wave][$time]->{Min},
				$XYZinfo->[$wave][$time]->{Max},
				$XYZinfo->[$wave][$time]->{Mean},
				$XYZinfo->[$wave][$time]->{GeoMean},
				$XYZinfo->[$wave][$time]->{Sigma},
				$XYZinfo->[$wave][$time]->{CentroidX},
				$XYZinfo->[$wave][$time]->{CentroidY},
				$XYZinfo->[$wave][$time]->{CentroidZ}
			);
		}
	}
}


sub WriteDB_XYinfo {
my $self = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my ($wave,$time,$zSection);
my $XYinfo = $self->XYinfo;
return unless defined $XYinfo;
my ($numWaves,$numTimes,$numZ) = (scalar (@$XYinfo), scalar (@{$XYinfo->[0]}),scalar (@{$XYinfo->[0][0]}));
my $ID = $self->ID;

# Clean out any old info for this dataset.
	$dbh->do ('DELETE FROM xy_dataset_info WHERE dataset_id = '.$ID);

my $sth = $dbh->prepare('INSERT INTO xy_dataset_info '.
		'(dataset_id,wavenumber,timepoint,zsection,deltatime,exptime,stage_x,stage_y,stage_z,min,max,mean,geomean,sigma) '.
		'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)'
	);

	for ($wave=0;$wave<$numWaves;$wave++) {
		for ($time=0;$time<$numTimes;$time++) {
			for ($zSection=0;$zSection<$numZ;$zSection++) {
				$sth->execute($ID,$wave,$time,$zSection,
					$XYinfo->[$wave][$time][$zSection]->{DeltaTime},
					$XYinfo->[$wave][$time][$zSection]->{ExposureTime},
					$XYinfo->[$wave][$time][$zSection]->{StageX},
					$XYinfo->[$wave][$time][$zSection]->{StageY},
					$XYinfo->[$wave][$time][$zSection]->{StageZ},
					$XYinfo->[$wave][$time][$zSection]->{Min},
					$XYinfo->[$wave][$time][$zSection]->{Max},
					$XYinfo->[$wave][$time][$zSection]->{Mean},
					$XYinfo->[$wave][$time][$zSection]->{GeoMean},
					$XYinfo->[$wave][$time][$zSection]->{Sigma}
				);
			}
		}
	}
}


sub WriteDB_Wavelengths {
my $self = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my ($wave);
my $Wavelengths = $self->Wavelengths;
return unless defined $Wavelengths;
my ($numWaves) = (scalar (@$Wavelengths));
my $ID = $self->ID;

# Clean out any old info for this dataset.
	$dbh->do ('DELETE FROM dataset_wavelengths WHERE dataset_id = '.$ID);

my $sth = $dbh->prepare('INSERT INTO dataset_wavelengths '.
		'(dataset_id,wavenumber,ex_wavelength,em_wavelength,nd_filter) '.
		'VALUES (?,?,?,?,?)'
	);

	for ($wave=0;$wave<$numWaves;$wave++) {
		$sth->execute($ID,$wave,
			$Wavelengths->[$wave]->{ExWavelength},
			$Wavelengths->[$wave]->{EmWavelength},
			$Wavelengths->[$wave]->{NDFilter}
		);
	}
}



1;
