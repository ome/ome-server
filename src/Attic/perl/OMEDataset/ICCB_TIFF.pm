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

package OMEDataset::ICCB_TIFF;
use OMEDataset;
@ISA = qw(OMEDataset);

use strict;
use vars qw($AUTOLOAD);

my $myAttributesTable = 'ATTRIBUTES_ICCB_TIFF';
my $myType = 'ICCB_TIFF';

my %Fields = (
		ID         => ['ATTRIBUTES_ICCB_TIFF','DATASET_ID',  'REFERENCE', 'DATASETS'            ],
		SizeX      => ['ATTRIBUTES_ICCB_TIFF','SIZE_X',      'INTEGER'                          ],
		SizeY      => ['ATTRIBUTES_ICCB_TIFF','SIZE_Y',      'INTEGER'                          ],
		BaseName   => ['ATTRIBUTES_ICCB_TIFF','BASE_NAME',   'STRING'                           ],
		ChemPlate  => ['ATTRIBUTES_ICCB_TIFF','CHEM_PLATE',  'STRING',    'REFERENCE','EXTERNAL'],
		CompoundID => ['ATTRIBUTES_ICCB_TIFF','COMPOUND_ID', 'REFERENCE', 'EXTERNAL'            ],
		Wave       => ['ATTRIBUTES_ICCB_TIFF','WAVE',        'INTEGER',   'DATASETS'            ],
		Well       => ['ATTRIBUTES_ICCB_TIFF','WELL',        'STRING',    'DATASETS'            ],
		Sample     => ['ATTRIBUTES_ICCB_TIFF','SAMPLE',      'INTEGER',   'DATASETS'            ],
		RasterID   => ['ATTRIBUTES_ICCB_TIFF','RASTER_ID',   'REFERENCE'                        ],
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
	}

	my $class = ref($proto) || $proto;
	$params{AttributesTable} = $myAttributesTable;
	$params{Type} = $myType;

# N.B.:  It is pointless to try to over-ride methods called from the Dataset constructor in a sub-class.  This is
#        because at that point the class is a Dataset class, not a sub-class.  Over-ridden methods will only take effect
#        after the bless statement below.  At least that's how I figure it.  Actually, the superclass calls its own
#        initialize method, not the one we have defined below.  OK, I don't know who's going to be called.  The
#        super-class calls the initialize method as a local subroutine.  We do the same here.  I guess technically
#        this would be a 'private' class (not object) method.
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
		$self->WriteDB();
		$self->FixWavelengths();
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
	
	$sth->finish();
	undef $sth;
	undef $dbh;
	
}


# Check if the file is the right type.  If not, return undef.
# If the file type is good, then set the Name key in the params hash to the value of the Import key, and delete the Import key.
# return 1.
# In this case all we're checking is the TIFF magic number.  This type checker can be used for all TIFFS.
#
# We should also check for the presence of certain elements in the filename since this object is an ICCB_TIFF, and these elements get
# parsed into the appropriate fields in the ICCB_TIFF attributes table.
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


#
# Below is what differentiates an ICCB_TIFF from a regular TIFF file.
#
use File::Basename;
my ($name,$path,$suffix);
my ($wave,$sample,$well);
my ($frag,$fragRe);
my ($base,$plate);

	# Get the name, path and suffix from the filename.
	($name,$path,$suffix) = fileparse($filename,".TIF",".tif");	

	# The suffix (when converted to uppercase) must be equal to "TIF"
	return undef unless (uc ($suffix) eq ".TIF");

	# Build frag from the end to the begining.
	# eventually it will contain all the stuff after the base name.
	# Get the well,sample,and wave
	# if we find matches, set the variable, and prepend the format to frag
	if ($name =~ /_w([0-9]+)/){ $wave = $1; $frag = "_w".$wave.$frag; }
	if ($name =~ /_s([0-9]+)/){ $sample = $1; $frag = "_s".$sample.$frag; }
	if ($name =~ /_([A-P][0-2][0-9])/){ $well = $1; $frag = "_".$well.$frag;}

	# The last check is that we have to have the well defined.  If not, its not an ICCB_TIFF.
	return undef unless defined $well;

	# If we made it this far, then we're going to make a dataset object.

	# Make frag a regular expression and use it to find the plate number.
	# Prepend the plate number to frag so we can find the basename.
	# N.B.: If the base name ends in a digit, then we cannot determine the plate number!

	$fragRe = qr/$frag/;
	if ($name =~ /([0-9]+)${fragRe}/){ $plate = $1; $frag = $plate.$frag }

	# The base name is everything before $frag.
	$fragRe = qr/$frag/;
	if ($name =~ /(.*)${fragRe}/){ $base = $1;}

	$params->{Name} = delete ($params->{Import});

	# Set fields specific to our dataset - we're setting keys and values in the parameters hash, so that when the new
	# method returns, everything will be copasetic.
	$params->{Well}      = $well;
	$params->{BaseName}  = $base;
	$params->{Wave}      = $wave;
	$params->{Sample}    = $sample;
	$params->{ChemPlate} = $plate;


return 1;
}

# GetWavelengthDatasets
# This method will return an array of dataset objects which have the same
# Well, BaseName, Sample and ChemPlate as the calling object, but different
# wavelengths.  The array members are ordered by wave number.
# N.B.:  There will be a COPY of the calling object in the array (not a reference to the calling object)
sub GetWavelengthDatasets {
my $self = shift;
my $rasterID = $self->{RasterID};
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my $datasetIDs = $dbh->selectcol_arrayref ("SELECT dataset_id FROM attributes_iccb_tiff WHERE raster_id = $rasterID ORDER BY wave");

	return $OME->GetDatasetObjects ($datasetIDs);

}

# FixWavelengths
# makes sure all wavelengths of the dataset have the same raster_id.
# This preserves the mapping of one file per dataset, but allows for multiple files/datasets
# to be part of the same raster.
# Wavelengths are part of the same raster.
# Timepoints are part of the same raster.
# Z-sections are in the same raster.
# multiple samples of the same "coverslip" are not.
sub FixWavelengths() {
my $self = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my $rasterID = $self->{RasterID};
my @datasetIDs;

	my $cmd = "SELECT dataset_id,raster_id FROM attributes_iccb_tiff WHERE ".
		"dataset_id = datasets.dataset_id and datasets.path = '".$self->{Path}."' AND ".
		"base_name = ? AND chem_plate = ? AND well = ? AND sample = ?";
	my @values = ($self->{BaseName},$self->{ChemPlate},$self->{Well},$self->{Sample});
	my $rows = $dbh->selectall_arrayref($cmd,undef,@values);
	
	foreach (@$rows) {
		my ($col1,$col2) = @$_;
		push (@datasetIDs,$col1);
		if (defined $rasterID and $rasterID and defined $col2 and $col2) {
			die "Raster_ID $col2, in dataset ID $col1 doesn't match raster_id $rasterID in other datasets having the same base_name, chem_plate, well, and sample!!!\n"
				unless $col2 = $rasterID;
		}
		if (defined $col2 and $col2) {
			$rasterID = $col2;
		}
	}

	if (not defined $rasterID or not $rasterID) {
		$rasterID = $OME->GetOID ('RASTER_ID');
		$self->{RasterID} = $rasterID;
	}

	foreach (@datasetIDs) {
		$dbh->do ("UPDATE attributes_iccb_tiff SET raster_id=$rasterID WHERE dataset_id=$_");
	}
	

}


sub GetBinaryImagePath() {
my $self = shift;
my $OME = $self->{OME};
my $dbh = $OME->DBIhandle();
my $rasterID = $self->{RasterID};

	my $cmd = "SELECT path,name FROM binary_image ".
		"WHERE analysis_id = (SELECT MAX(analysis_id) FROM binary_image ".
			"WHERE binary_image.dataset_id_in = attributes_iccb_tiff.dataset_id AND attributes_iccb_tiff.raster_id=$rasterID)";
	my ($path,$name) = $dbh->selectrow_array($cmd);
	return $path.$name;
	
}



1;
