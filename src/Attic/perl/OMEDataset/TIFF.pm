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

# This is support for generic single-plane TIFF datasets.
# This is an implemented class - not a virtual class.
# There is some compatibility with 5-D datasets - all OME_XYZWT methods are supported.
# This should probably not serve as a base for implementing 5-D datasets constructed from TIFF files - a dubious pursuit anyway.
# There is a similar class that supports multi-wavelength TIFFs (ICCB_TIFF).
package OMEDataset::TIFF;
use OMEDataset;
@ISA = qw(OMEDataset);

use strict;
use vars qw($AUTOLOAD);

my $myAttributesTable = 'ATTRIBUTES_TIFF';
my $myType = 'TIFF';

my %Fields = (
		ID         => [$myAttributesTable,'DATASET_ID',  'REFERENCE', 'DATASETS'  ],
		SizeX      => [$myAttributesTable,'SIZE_X',      'INTEGER'                ],
		SizeY      => [$myAttributesTable,'SIZE_Y',      'INTEGER'                ],
		Min        => [$myAttributesTable,'MIN',         'INTEGER'                ],
		Max        => [$myAttributesTable,'MAX',         'INTEGER'                ],
		Mean       => [$myAttributesTable,'MEAN',        'FLOAT'                  ],
		Sigma      => [$myAttributesTable,'SIGMA',       'FLOAT'                  ],
		);

# Constructor new
# Required parameters:  Name or ID or Import => '/absolute/path/to/file' and OME.
# This is a sub-class of the Dataset class.  The constructor over-rides Dataset's constructor, but calls
# it with a couple exta parameters.
# The extra parameters are the AttributesTable and the Type.  These will become datamembers of the
# resulting class.
# The superclass constructor sets the fields in the superclass only.  It also sets the field
# values (by reading the DB) if an ID was passed as a parameter.
# The Type parameter is required for the Dataset constructor, but is ignored in the sub-class constructor.
# There are no 'generic' datasets at this time, so all new datasets should be created via their sub-classes.
#
# We should be able to call the constructor with a filename and have it "import" the dataset into OME.
# The way to do this is call SomeOMEDatasetClass->new (Import => "/absolute/path/to/file").
# Normally, a client would call the ImportDataset method directly from OME.
# OME calls each Dataset class it knows about in turn, and stops when it gets a non-NULL dataset.
# The method needs to determine (quickly!) if the specified file is of the correct type.  If not, it should immediately
# return undef.  If it can import this file, then do so, returning an object reference as usual.
# Actually, the difference with Import is that it goes and writes the all the attributes to the database - unlike the other ways
# of calling new, which only return a reference, and nothing gets written until WriteDB is called.
# Ambiguous dataset types (for example a derived class and its parent) will be imported as the first successfull import command, so
# the order of import attempts is important.  This is determined by how the OME->ImportDataset method is called.
sub new {
	my $proto = shift;
	my %params = @_;
	my $attributes;
	my ($attribute,$value);
	my $importing = 0;

#
# Before we try to instantiate the class, see if we're importing - if so determine if the file is right.
# If the file looks good, then import it, if not return undef immediately.

	if (exists $params{Import}) {   # Determine if the file is the right type.
	# If the file is good, sets the value of the Name parameter to the value of the Import parameter,
	# and deletes the Import parameter so it doesn't wind up as a field in the object.
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

	my $class = ref($proto) || $proto;
	$params{AttributesTable} = $myAttributesTable;
	$params{Type} = $myType;

# Call the parent (superclass) constructor.
# This will set the Name, Path, ID, etc.
	my $self  = $class->SUPER::new(%params);


# This statement allows OME to write the object to the database.  SHould probably be done through
# an OME method rather than this way.
# This has to be done in all derived classes after calling the superclass constructor.
	push (@{$self->{_OME_FIELDS_}},\%Fields);

# Certain datamembers of this object may have already been set by the superclass (i.e. via the parameters),
# so don't over-write them when creating the datamembers.
	while ( ($attribute,$value) = each (%Fields) )
	{
		$self->{$attribute} = undef unless exists ($self->{$attribute});
	}

	bless ($self, $class);

	initialize($self);

# Check DBcurrent to make sure we're importing a brand-new dataset.
# OMEDataset sets DBcurrent if it found a dataset in the database with the same name, path and host.
	if ($importing and not $self->DBcurrent) {
		return undef unless (Import ($self));
		$self->WriteDB();
	}

	return $self;
}



sub initialize {
	my $self = shift;
	my $OME = $self->{OME};
	my $dbh = $OME->DBIhandle();
	my $cmd;
	my $sth;
	my $row;

	$sth = $dbh->prepare ("SELECT * FROM ".$self->{AttributesTable}." WHERE DATASET_ID=".$self->{ID});
	$sth->execute();
	$row = $sth->fetchrow_arrayref;

# Read the data out of the database, putting the right values in the right fields.
	if (defined $row and $row)
	{
	my $i;
	my $fname;
	my $pname;
	my %DBFieldMap;
	my $OMEfields = \%Fields;
	my ($attribute,$value);

	# Reverse the Field->DB map in order to have a way to look up parameter names based on database column names.
		while ( ($attribute,$value) = each (%$OMEfields) )
		{
			$DBFieldMap{@$value[1]} = $attribute;
		}

		for ($i=0; $i < $sth->{NUM_OF_FIELDS};$i++)
		{
			$fname = $sth->{NAME_uc}->[$i];
			$pname = $DBFieldMap{$fname};
			$self->{$pname} = $row->[$i];
		}
	}

# for compatibility with 5-D datasets:
	$self->{SizeZ} = 1;
	$self->{NumWaves} = 1;
	$self->{NumTimes} = 1;
	
	$sth->finish();
	undef $sth;
	undef $dbh;
	
}


# Check if the file is the right type.  If not, return undef.
# If the file type is good, then set the Name key in the params hash to the value of the Import key, and delete the Import key.
# return 1.
# In this case all we're checking is the TIFF magic number.  This type checker can be used for all TIFFS.
#
sub CheckFileType {
my $params = shift;
my $filename = $params->{Import};
#my $TIFFMagicAddress = 0;
my $TIFFMagicBigEndian = 0x4d4d;
my $TIFFMagicLittleEndian = 0x4949;
my $TIFFMagic;


	open (DATASET,$params->{Import}) or die "Can't open file '".$params->{Import}."': $!\n";
	binmode (DATASET);
	
#	seek (DATASET, $TIFFMagicAddress, 0);
	read (DATASET,$TIFFMagic,2);
	close (DATASET);

	$TIFFMagic = unpack ('S',$TIFFMagic);
	return (undef) unless ($TIFFMagic eq $TIFFMagicBigEndian or $TIFFMagic eq $TIFFMagicLittleEndian);


return 1;
}



# Subroutine Import
# The assumption here is that this is a NEW dataset.
# The initialize method has been called, but all our fields are undef still because there was nobody home in the DB.
# We fill out our own fields, and ignore (for now) the XYZinfo, XYinfo and Wavelengths arrays.
# In this general case, we don't have a standard method for extracting much of this information from a TIFF file anyway.
# The only thing we can go is calculate the statistics.  Since we have one dataset per plane, we store the statistics
# right in out attributes table in the DB.  We provide methods for getting the XYinfo, XYZinfo, and Wavelength arrays
# from our internal fields in a format compatible with other 5D datasets.
# We never make use of the XY_Dataset_Info, XYZ_dataset_info and dataset_wavelengths tables.
#
# We don't write anything to the DB here - that is done in the WriteDB method - which is not over-ridden because
# we aren't writing to extra tables.
# We do set the _OME_DB_STATUS_ field to 'DIRTY'.
# Note that the parent's constructor (and from there, the parent's Initialize and Import) has been called, so
# the parent should have filled in its fields.  We only need to worry about our own fields.
# Sub-classes implementing multi-dimensional TIFFs should definitely implement their own Import.
# The details will depend on how many dimensions, etc.  Obviously the stitching together of the multi-D TIFFs will
# be highly dependent on their source.
# Probably in most cases it would be best to start with something like this rather than trying to sub-class OME_XYZWT.
# My only thoughts on this is that existing tables should be used for XYZinfo and Wavelengths - using the RasterID (see ICCB_TIFF)
# rather than the dataset ID in the DATASET_ID column.  The RasterID should probably be assigned to one of the dataset IDs in the
# multi-TIFF raster.
sub Import {
my $self = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my $DumpTIFFheader = $OME->binPath.'DumpTIFFheader';
my $DumpTIFFstats = $OME->binPath.'DumpTIFFstats';
my ($XYZinfo,$XYinfo,$Wavelengths);
my ($zSection,$waveNum,$timePoint);
# This is provided by the parent class (ultimately by OMEDataset.pm)
my $datasetPath = $self->{Path}.$self->{Name};
print STDERR "TIFF.pm:  Importing $datasetPath\n";
my $command;

my ($attribute,$value);
my @columns;

	my $tempFileNameErr = $OME->GetTempName ('TIFFimport','err') or die "Couldn't get a name for a temporary file $!\n";

# This will get the dimentions, etc of the dataset.
# The output of this program is one attribute per line (attribute name \t attribute value).
# Conveniently, the attribute names match the Object's field names so me don't need a map.
	$command = "$DumpTIFFheader $datasetPath 2> $tempFileNameErr |";
	open (STDOUT_PIPE,$command) or die "Could not execute '$command'.\n";
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

	die "Could not determine the width of the image.\n" unless exists $self->{SizeX} and $self->{SizeX};
	die "Could not determine the height of the image.\n" unless exists $self->{SizeY} and $self->{SizeY};

# This will calculate statistics about TIFF files, and output two lines -
# one line with the following column headings, and the next line containing the values.
# min \t max \t mean \t sigma \t sum_XI \t sum YI \t sum I \t sum I^2 \n
# The sum XI, sum YI, sum I and sum I^2 can be used for calculating statistics for a stack of TIFFs.
# This Import function ignores these values, because this class is for a single-plane dataset.
# The file will actually be read at this point, and an error reported if its corrupt.
	$command = "$DumpTIFFstats $datasetPath 2>> $tempFileNameErr |";
	open (STDOUT_PIPE,$command) or die "Could not execute '$command'.\n";
	@columns = split ('\t', <STDOUT_PIPE>);
	while (<STDOUT_PIPE>) {
		chomp;
		@columns = split ('\t', $_);
	# Trim leading and trailing whitespace, set column value to undef if not like a C float.
		foreach (@columns) {$_ =~ s/^\s+//;$_ =~ s/\s+$//;$_ = undef unless ($_ =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);}
	# Set the XYinfo.
		$self->{Min}   = int ($columns[0]) if defined $columns[0];
		$self->{Max}   = int ($columns[1]) if defined $columns[1];
		$self->{Mean}  = $columns[2];
		$self->{Sigma} = $columns[3];
	
	}
	close (STDOUT_PIPE);
	
	$self->{_OME_DB_STATUS_} = 'DIRTY';
	return $self;
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
					$self->{Min}   =  $XYinfo->[$waveNum][$timePoint][$zSection]->{Min};
					$self->{Max}   =  $XYinfo->[$waveNum][$timePoint][$zSection]->{Max};
					$self->{Mean}  =  $XYinfo->[$waveNum][$timePoint][$zSection]->{Mean};
					$self->{Sigma} =  $XYinfo->[$waveNum][$timePoint][$zSection]->{Sigma};

					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Min}   = $self->{Min};
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Max}   = $self->{Max};
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Mean}  = $self->{Mean};
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Sigma} = $self->{Sigma};
				}		
			}
		}

# Tell WriteDB to do the write.
	$self->{_OME_DB_STATUS_} = 'DIRTY';
	}

	elsif (not exists $self->{XYinfo}) {
		my ($waveNum,$timePoint,$zSection);
		my ($numWaves,$numTimes,$numZ) = ($self->{NumWaves},$self->{NumTimes},$self->{SizeZ});
		for ($waveNum = 0; $waveNum < $numWaves; $waveNum++) {
			for ($timePoint = 0; $timePoint < $numTimes; $timePoint++) {
				for ($zSection = 0; $zSection < $numZ; $zSection++) {
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Min}   = $self->{Min};
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Max}   = $self->{Max};
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Mean}  = $self->{Mean};
					$self->{XYinfo}->[$waveNum][$timePoint][$zSection]->{Sigma} = $self->{Sigma};
				}		
			}
		}
	}
	
	return $self->{XYinfo};
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
					Min       => $XYZinfo->[$waveNum][$timePoint]->{Min},
					Max       => $XYZinfo->[$waveNum][$timePoint]->{Max},
					Mean      => $XYZinfo->[$waveNum][$timePoint]->{Mean},
					Sigma     => $XYZinfo->[$waveNum][$timePoint]->{Sigma},
				};			
				$self->{Min}   =  $XYZinfo->[$waveNum][$timePoint]->{Min};
				$self->{Max}   =  $XYZinfo->[$waveNum][$timePoint]->{Max};
				$self->{Mean}  =  $XYZinfo->[$waveNum][$timePoint]->{Mean};
				$self->{Sigma} =  $XYZinfo->[$waveNum][$timePoint]->{Sigma};

			}
		}
	}

# We can't read this from the DB because Z sections are not defined for this class.
	elsif (not exists $self->{XYZinfo}) {
		my ($waveNum,$timePoint);
		my ($numWaves,$numTimes) = ($self->{NumWaves},$self->{NumTimes});
		for ($waveNum = 0; $waveNum < $numWaves; $waveNum++) {
			for ($timePoint = 0; $timePoint < $numTimes; $timePoint++) {
				$self->{XYZinfo}->[$waveNum][$timePoint] = {
					Min       => $self->{Min},
					Max       => $self->{Max},
					Mean      => $self->{Mean},
					Sigma     => $self->{Sigma},
				};			
			}
		}
	}
	
	return $self->{XYZinfo};
}


# Wavelengths are not defined for this dataset - return undef
sub Wavelengths {
	return undef;
}


# These are simply traps because we don't write this stuff to the DB.
sub WriteDB_XYinfo {
}

sub WriteDB_XYZinfo {
}

sub WriteDB_Wavelengths {
}




1;
