# OMEAnalysis.pm:  Ancestor object for OME analyses
# Author:  Douglas Creager <dcreager@alum.mit.edu>
# Copyright 2002 Douglas Creager.
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

package OMEAnalysis;
use strict;
use vars qw($VERSION);
$VERSION = '1.20';

use OMEpl;


# new()
# ----
# Returns a new instance of this object.

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;    # allow to be invoked as a class or instance method

    my $self = {
	OME         => new OMEpl,
	programName => undef
    };

    bless($self,$class);
    return $self;
}


# ExecuteCGI()
# ------------
# Automates the steps performed when executing this analysis from a
# CGI script.

sub ExecuteCGI {
    my $self = shift;
    my $OME  = $self->{OME};

    my $params = $self->GetHTMLParams();

    if ($OME->cgi->param('Execute')) {
	$self->PerformAnalysis($params);
    }

    print $OME->cgi->end_html;
}


# OutputHTMLForm()
# ----------------
# Outputs an appropriate HTML form to retrieve analysis parameters
# from the user.

sub OutputHTMLForm() {
}


# GetParamsHTML()
# ---------------
# Returns a parameter hash suitable for StartAnalysis with values
# filled in the from the CGI input.  Only the parameters specified in
# the htmlVars instance variable are copied into the parameter hash.

sub GetHTMLParams {
    my $self = shift;
    my $CGI  = $self->{OME}->cgi();
    
    my %params;
    my $var;

    if (defined $self->{htmlVars}) {
	foreach $var (@{$self->{htmlVars}}) {
	    $params{$var} = $CGI->param($var);
	}
    }
    
    return \%params;
}

# GetSelectedDatasets()
# ---------------------
# Retrieves the selected datasets from the OME system.  Override this
# to filter the list if the user can specify extra constraints.

sub GetSelectedDatasets {
    my $self = shift;
    return $self->{OME}->GetSelectedDatasetObjects();
}

# StartAnalysis(Parameter hash)
# -----------------------------
# Performs any setup necessary for the analysis.  This method is
# called once, before any datasets are analyzed.

sub StartAnalysis {
    my $self = shift;
    my $OME  = $self->{OME};

    $OME->StartAnalysis();
}


# Execute(Dataset object)
# -----------------------
# Performs the analysis on a single dataset.  This method will be
# called once for each dataset selected by the user.

sub Execute {
}


# FinishAnalysis()
# ----------------
# Performs any cleanup after analyzing all of the datasets.

sub FinishAnalysis {
}


# PerformAnalysis(Input parameters, [Dataset objects])
# ----------------------------------------------------
# Performs the entire analysis process, including setup and cleanup.
# The analysis is performed on whichever datasets are returned by
# GetSelectedDatasets.  (By default, the datasets selected by the
# user.)

sub PerformAnalysis {
    my $self       = shift;
    my $params     = shift;
    my $datasets   = shift;
    my $OME        = $self->{OME};
    
    $self->StartAnalysis($params);

    my $dataset;
    if (!defined $datasets) {
	$datasets = $self->GetSelectedDatasets();
    }

    foreach $dataset (@$datasets) {
	$self->Execute($dataset);
    }

    $self->FinishAnalysis();
}


# ProcessOutput(AnalysisID, Filename, [columnKey, columnKeyRE])
# -----------------------------------------------------------
# Processes the tab-delimited output of an external analysis program.
# The first line of output should be column headings.  One feature
# will be added to the dataset for each subsequent line of output.
# Allowed columns are specified by the columnKey and columnKeyRE
# hashes.  If columnKey and columnKeyRE aren't passed in as
# parameters, they are taken from instance variables of the same name.
#
# The columnKey hash defines columns whose headings are expected to
# have an exact match.  The column heading is the hash key.  The
# values are table column definitions which will be used by the
# OMEpl::WriteFeatures method.
#
# The columnKeyRE hash defines columns whose headings should match the
# given regular expression.  Column headings that don't match a
# heading specified above are searched against these REs.  The first
# parenthesis group in the RE will be pushed onto the end of each of
# these arrays at runtime to create an appropriate table column
# definition.  This allows the regular expression to determine the
# discriminator value of a one-to-many feature relationship.

sub ProcessOutput
{
    my $self        = shift;
    my $analysisID  = shift;
    my $fileName    = shift;
    my $columnKey   = shift;
    my $columnKeyRE = shift;
    my $OME         = $self->{OME};
    my $line;

    if (!defined $columnKey) {
	$columnKey = $self->{columnKey};
    }

    if (!defined $columnKeyRE) {
	$columnKeyRE = $self->{columnKeyRE};
    }

    # This is the separator that separates columns in each input line.
    # \t is the tab character.  It must be a regular expression, thus
    # the qr//.
    my $columnSeparator = qr/\t/;

    my ($column,@columns);
    my ($key,$value);
    my $keyRE;
    my $k;
    
    # These are the feature data members hash (%featureData) and the
    # hash that maps the datamembers to the database (%featureDBmap).
    # The keys of the %featuresData hash will become data members of
    # the feature objects.  The %featureDBmap is like a 'static' class
    # member that will be used by the database writer to map feature
    # datamembers to tables and columns in the database.  #FIXME:
    # Undecided as to how to specify one-many relationship such as
    # SIGNAL.  Interim solution:
    # General case: Datamember => ['TABLE','COLUMN',
    #                                'TYPE OPTIONS'... ],
    # one to many:  Datamember => ['TABLE','COLUMN',
    #                                'ONE2MANY', 'DISCRIMINATOR COLUMN',
    #                                'DISCRIMINATOR VALUE' ],
    # Example:      i[528]     => ['SIGNAL','INTEGRAL',
    #                                'ONE2MANY', 'WAVELENGTH','528' ],
    my (%featureData,%featureDBmap);

    # For convenience, construct an array called dataMembers which
    # either contains the name of the data member or an undefined
    # value.  This array will be used to put the column value into the
    # proper data member (if there is a data member defined for that
    # column).  The order of the elements in this array will be the
    # dame as the order of the columns in the input file.
    my ($dataMember,@dataMembers);

    # This will conatin the array of features we construct.  These are
    # object references.
    my ($feature,@features);

    # Open the input file, read a line, and chop off the terminating
    # newline (if any).
    open (INPUT,"< $fileName") or
	die "Could not open $self->{programName} output file '$fileName' for reading\n";
    $line = <INPUT>;
    chomp $line;

    # The first line contains the column headings.
    # First, split the headings line into individual headings.
    @columns = split ($columnSeparator,$line);
    $k = -1;
    
  LOOP:
    # Process the headings one at a time.
    foreach $column (@columns)
    {
	$k++;
	# Trim leading and trailing whitespace.
	$column =~ s/^\s+//;
	$column =~ s/\s+$//;

	# See if there is an exact match for the heading in the
	# columnKey hash.
	if (! exists $columnKey->{$column} )
	{
	    # If no match was found, try to match to a regular
	    # expression in the columnKeyRE hash.
	    while ( ($key,$value) = each %$columnKeyRE )
	    {
		# make a regular expression out of the key.
		$keyRE = qr/$key/;
		if ($column =~ $keyRE)
		{
		    # If we found a match to a regular expression, set
		    # a feature data member name equal to the column
		    # heading name.
		    $featureData{$column} = undef;
		    
		    # Push the datamember name on to the dataMembers
		    # array.  This array is in the same order as the
		    # columns.
		    push (@dataMembers,$column);
		    
		    if (defined $1) {
			# Make a copy of the database mapping array,
			# and put a reference to it in the
			# $featureDBmap If we extracted something from
			# the RE, set the discriminator to it.
			$featureDBmap{$column} = [@$value,$1];
		    } else {

			# Otherwise, just copy the array, and make a
			# reference to it.
			$featureDBmap{$column} = [@$value];
		    }

		    # Reset the 'each' iterator for this hash, so we
		    # start from the begining next time.
		    scalar (keys (%{$self->{columnKeyRE}}));
		    
		    # jump immediately to the next iteration (next heading)
		    next LOOP;
		}
	    }
	    
	    # If we made it here, we didn't have an exact match or a RE
	    # match.  push undef onto the dataMember array to indicate
	    # that this column is to be ignored.
	    push (@dataMembers,undef);
	} else {

	    # If we found an exact match, set the feature data member
	    # name, push the datamember onto the dataMember array, and
	    # copy the DB map array.
	    $featureData{$column} = undef;
	    push (@dataMembers,$column);
	    $featureDBmap{$column} = [@{$columnKey->{$column}}];
	}
    }


    # Process the file one line at a time.
    while (defined ($line = <INPUT>) )
    {
	# reset the column counter.
	$k = 0;
	
	# Get rid of the trailing newline.
	chomp $line;
 
	# make a new feature object with the proper data members.
	$feature = new OMEfeature ( %featureData );
	
	# split the line into columns separated by the $columnSeparator RE.
	@columns = split ($columnSeparator,$line);
	
	# process the columns one at a time.
	foreach $column (@columns)
	{
	    # Set the datamember's value only if it is defined for this column.
	    if (defined $dataMembers[$k])
	    {
		# Trim leading and trailing whitespace.
		$column =~ s/^\s+//;
		$column =~ s/\s+$//;
		
		# Numeric columns ONLY.  Set undef if not like a C float.
		$column = undef unless ($column =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/);
		
		# use the feature object's data member method to set the value
		$dataMember = $dataMembers[$k];
		$feature->$dataMember($column);
	    }
	    $k++;
	}
	
	# Put the completed feature into the features array.
	push (@features,$feature);
    }

    # ask OME to write the features to the DB.
    $OME->WriteFeatures ($analysisID,\@features,\%featureDBmap);
    $OME->Commit;

    #	foreach $feature (@features)
    #	{
    #		while ( ($key,$value) = each (%featureData) )
    #		{
    #			print "$key (".$feature->$key().")   ";
    #		}
    #		print "\n";
    #	}
    #    #
    #	while ( ($key,$value) = each (%featureDBmap) )
    #	{
    #		print "feature->$key:\n";
    #		print join (',',@$value),"\n";
    #	}
    return (scalar @features);
}

    
    1;
