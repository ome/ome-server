# OMEAnalysis.pm
# Analysis wrapper object for OME analyses
# Douglas Creager <dcreager@alum.mit.edu>
# 22 March 2002

package OMEAnalysis;
use strict;
use vars qw($VERSION);
$VERSION = '1.20';

use OMEpl;


# new()
# returns a new instance of this object
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

# DESTROY()
sub DESTROY {
    my $self = shift;
    my $OME  = $self->{OME};

    #OME->Finish();
}

# ExecuteCGI()
# called from a CGI script, performs the analysis completely
# by retrieving parameters from the HTML results
sub ExecuteCGI {
    my $self = shift;
    my $OME  = $self->{OME};

    my $params = $self->GetHTMLParams();

    if ($OME->cgi->param('Execute')) {
	$self->PerformAnalysis($params);
    }

    print $OME->cgi->end_html;
}

# Initialize()
sub Initialize {
}

# OutputHTMLForm()
# displays an appropriate HTML form to retrieve analysis parameters
sub OutputHTMLForm() {
}

# GetParamsHTML()
# returns parameter hash
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

# GetSelectedDatasets([wavelength])
sub GetSelectedDatasets {
    my $self         = shift;
    my @result;
    my $dataset;
    my $datasets     = $self->{OME}->GetSelectedDatasetObjects();
    my $wavelength   = shift;
    
    foreach $dataset (@$datasets) {
	next if defined $wavelength and exists $dataset->{Wave} and $dataset->{Wave} ne $wavelength;
	push(@result,$dataset);
    }

    return \@result;
}

# StartAnalysis(Input parameters)
sub StartAnalysis {
    my $self = shift;
    my $OME  = $self->{OME};

    $OME->StartAnalysis();
}

# Execute(Dataset object)
sub Execute {
}

# FinishAnalysis()
sub FinishAnalysis {
}

# PerformAnalysis(Input parameters)
sub PerformAnalysis {
    my $self   = shift;
    my $params = shift;
    my $OME    = $self->{OME};
    
    $self->StartAnalysis($params);

    my $dataset;
    my $datasets = $self->GetSelectedDatasets();

    foreach $dataset (@$datasets) {
	$self->Execute($dataset);
    }

    $self->FinishAnalysis();
}



# Convert a table with column headings to a list of OME Feature object
# that will be written to the database.

# The features we construct have the column headings as the
# datamembers.  These are column headings expected to have an exact
# match.  The column heading is the hash key.  The values are array
# references where element 0 is the table name and element 1 is the
# column name.  Element 2 is the type specifier.  This should be
# optional in the future, as the rest of the elements can be
# determined from the datatbase by OME.



# These are column headings that are matched using a regular
# expression.  Column headings that don't match a heading specified
# above are searched against these REs.  In this case, digits within
# brackets designate a wavelength.  The actual wavelength will be
# pushed onto the end of each of these arrays at run-time.  'ONE2MANY'
# tells the database writer that this is an entry in a table that has
# a many to one relationship to the feature.  The array element
# immediately following that is the name of the discriminator -
# i.e. the column name that will discriminate between the many entries
# for this feature.  The element following the discriminator name is
# expected to be the value of the discriminator for that instance.  It
# will be specified at run-time.  Note on these REs: The brackets must
# be escaped cause we're matching an actual bracket.  There can be one
# or more digits between the brackets.  There are parentheses around
# these because we are going to capture this number, and use it as the
# discriminator value.  Which we will push on to the end of these
# arays.  At run-time.


    

# ProcessOutput(AnalysisID, Filename, ColumnKey, ColumnKeyRE)

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
