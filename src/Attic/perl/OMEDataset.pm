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
package OMEDataset;
use OMEpl;

use vars qw($AUTOLOAD);  # it's a package global

use File::Basename;
use Cwd 'abs_path';
use Sys::Hostname;

use strict;

my %Fields = (
		ID              => ['DATASETS','DATASET_ID',       'REFERENCE', 'PRIMARY KEY'  ],
		Name            => ['DATASETS','NAME',             'STRING'                    ],
		Path            => ['DATASETS','PATH',             'STRING'                    ],
		Host            => ['DATASETS','HOST',             'STRING'                    ],
		URL             => ['DATASETS','URL',              'STRING'                    ],
		InstrumentID    => ['DATASETS','INSTRUMENT_ID',    'REFERENCE', 'INSTRUMENTS'  ],
		ExperimenterID  => ['DATASETS','EXPERIMENTER_ID',  'REFERENCE', 'EXPERIMENTERS'],
		Created         => ['DATASETS','CREATED',          'TIMESTAMP'                 ],
		Inserted        => ['DATASETS','INSERTED',         'TIMESTAMP'                 ],
		Type            => ['DATASETS','DATASET_TYPE',     'STRING'                    ],
		AttributesTable => ['DATASETS','ATTRIBUTES_TABLE', 'STRING',    'TABLE NAME'   ],
		);

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my %params = @_;
	my ($attribute,$value);
	my $OME = $params{OME};
	die "Attempt to create a Dataset object without specifying its OME object\n" unless defined $OME;

	my $self = {
		_OME_FIELDS_ => [],
		_OME_DB_STATUS_ => 'DIRTY',
		OME         => $OME
		};

# This statement allows OME to write the object to the database.  SHould probably be done through
# an OME method rather than this way.
	push (@{$self->{_OME_FIELDS_}},\%Fields);

# Put all the fields declared above into the object as datamembers
	while ( ($attribute,$value) = each (%Fields) )
	{
		$self->{$attribute} = undef;
	}

# Add any parameters that were passed in.
# Note that parameters in addition to the standard fields are allowed, but:
# N.B.:  These will never be written to the database - they are meant to hold temporary values ONLY!!
	while ( ($attribute,$value) = each (%params) )
	{
		$self->{$attribute} = $value;
#	print STDERR "OMEDataset:  setting $attribute to $value\n";
	}

	bless ($self, $class);
	initialize($self);
	return $self;
}


sub initialize {
	my $self = shift;
	my $OME = $self->{OME};
	my $dbh = $OME->DBIhandle();
	my $cmd;
	my $sth;
	my $row;
	my $i;

	my $fname;
	my $pname;
	my %DBFieldMap;
	my $OMEfields = \%Fields;
	my ($attribute,$value);
	my ($host,$name,$path);

# Reverse the Field->DB map in order to have a way to look up parameter names based on database column names.
	while ( ($attribute,$value) = each (%$OMEfields) )
	{
		$DBFieldMap{@$value[1]} = $attribute;
	}

# Set the host, name and path.
# The Name parameter may contain a base name, a relative path or a full (absolute) path.
# If the Name parameter is not an absolute path, then the absolute path is constructed by using the
# Path prameter.  If the Path parameter doesn't exist, or is a relative path, then the Path parameter
# is used to get an absolute path (using abs_path).
#
# Make sure the name we got is a base-name.  If it isn't then reset the path we got (if any), and determine
# the absolute path.
	if (defined $self->{Name})
	{
	# get the path components out of the name.
		($name,$path,undef) = fileparse ($self->{Name});
	
	# If we got any path bits, then make them absolute.
		if (defined $self->{Path}) { $path = abs_path ($self->{Path})."/"; }

	# If we didn't get path bits in Path, get the absolute path from the Name.
		else { $path = abs_path ($path)."/"; }

	# Set the Dataset's fields to what we figured out.
		$self->{Name} = $name;
		$self->{Path} = $path;

	# Make sure we've got the host.
		if (!defined $self->{Host}) { $host = hostname; $self->{Host} = $host; }
	}
# If we got an ID, read the Dataset from the DB.
	if (defined $self->{ID} && $self->{ID} > 0)
	{
		$sth = $dbh->prepare ("SELECT * FROM datasets WHERE DATASET_ID=".$self->{ID});
		$sth->execute();
		$row = $sth->fetchrow_arrayref;
	}

# If we got a host, name and path that matches an existing dataset, read that.
	elsif (defined $name)
	{
		$sth = $dbh->prepare ("SELECT * FROM datasets WHERE NAME='$name' AND PATH='$path' AND HOST='$host'");
		$sth->execute();
		$row = $sth->fetchrow_arrayref;
	}
	else { die "Must provide either a Name or an ID parameter when calling OMEDataset->new\n"; }

# Read the data out of the database, putting the right values in the right fields.
	if (defined $row and $row)
	{
		for ($i=0; $i < $sth->{NUM_OF_FIELDS};$i++)
		{
			$fname = $sth->{NAME_uc}->[$i];
			if (exists $DBFieldMap{$fname}) {
				$pname = $DBFieldMap{$fname};
			} else {
				$pname = undef;
			}
			if (defined $pname) { $self->{$pname} = $row->[$i]; }
		}
	# Set the 'CURRENT' flag because we found the dataset in the database.
		$self->{_OME_DB_STATUS_} = 'CURRENT';
	}

# If we're not reading the database, get a new ID.
# The Name, Path and Host were set above (or we died).
	else
	{
	# First make sure we have enough parameters to make a valid Dataset.
		die "The Type must be specified when creating a new Dataset\n" unless defined $self->{Type};
		die "The Attributes_Table must be specified when creating a new Dataset.\n" unless defined $self->{AttributesTable};
		die "The Name must be specified when creating a new Dataset.\n" unless defined $self->{Name};

		$self->{ID} = $OME->GetOID('DATASET_SEQ');
		$self->{Inserted} = 'CURRENT_TIMESTAMP';
	}

	$sth->finish();
	undef $sth;
	undef $dbh;


}

sub WriteDB()
{
my $self = shift;
my $OME = $self->{OME};

# Write our own fields
	if (! $self->DBcurrent ) { $OME->WriteOMEobject ($self); }
	$self->{_OME_DB_STATUS_} = 'CURRENT';
}


sub DBcurrent ()
{
my $self = shift;

	return ($self->{_OME_DB_STATUS_} eq 'CURRENT');
}




sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self)
		or die "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion

	return if $name eq 'DESTROY';
	
	unless (exists $self->{$name} ) {
    	die "Can't access `$name' field in class $type";
	}

	if (@_)
	{
	my $value = shift;
	# Can't set the ID.
		if ($name ne 'ID')
		{
			if ( (!defined $self->{$name}) or (defined $self->{$name} && $self->{$name} ne $value) )
			{
				$self->{$name} = $value;
				$self->{_OME_DB_STATUS_} = 'DIRTY';
			}
		}
		return $value;
	}
	else
	{
    	return $self->{$name};
	}
}



1;
