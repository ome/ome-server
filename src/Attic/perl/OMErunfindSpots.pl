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

use OMEpl;
use strict;

use vars qw ($OME $programName);
use Benchmark;

$programName="findSpots";

$OME = new OMEpl;

$OME->StartAnalysis();



print_form ();
Execute () if ($OME->cgi->param('Execute'));

print $OME->cgi->end_html;

$OME->Finish();
undef $OME;




sub print_form
{
my $dbh = $OME->DBIhandle();
my $CGI = $OME->cgi();
my $cmd;
my $nTuples;
my $full_url;
my @tableRows;
my @tableColumns;
my $k;
my @radioGrp;





#
# The user supplies the TIME_START, TIME_STOP (begining to end, or number to end or begining to number)
# The WAVELEGTH.  This is a popup containing the wavelegths in the dataset(s),
# The THRESHOLD.  This is either a number or relative to the mean or to the geometric mean.
# Minimum spot volume - a number
# Intensity weight - default 0.
#
	$tableColumns[0]=$CGI->th('Time');
	$tableColumns[1]='<b>From:</b>';
	@radioGrp = $CGI->radio_group(-name=>'startTime',
			-values=>['Begining','timePoint'],-default=>'Begining',-nolabels=>1);
	$tableColumns[2] = $radioGrp[0]."Begining";
	$tableColumns[3] = $radioGrp[1]."Timepoint".$CGI->textfield(-name=>'Start',-size=>4);
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();

	$tableColumns[0]=$CGI->td(' ');
	$tableColumns[1]='<b>To:</b>';
	@radioGrp = $CGI->radio_group(-name=>'stopTime',
			-values=>['End','timePoint'],-default=>'End',-nolabels=>1);
	$tableColumns[2] = $radioGrp[0]."End";
	$tableColumns[3] = $radioGrp[1]."Timepoint".$CGI->textfield(-name=>'Stop',-size=>4);
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();



# Collect the wavelengths available for the selected datasets
	my $wavelengths = $OME->GetSelectedDatasetsWavelengths();
	$tableColumns[0] = $CGI->th ('Wavelength');
	$tableColumns[1] = $CGI->popup_menu(-name=>'wavelengths',
                            	-values=>$wavelengths);
	$tableColumns[2] = $CGI->td (' ');
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();

	$tableColumns[0] = $CGI->th ('Threshold');
	@radioGrp = $CGI->radio_group(-name=>'threshold',
			-values=>['Absolute','Relative','Automatic'],-default=>'Relative',-nolabels=>1);
	$tableColumns[1] = $radioGrp[0]."Absolute :<BR>".$CGI->textfield(-name=>'Absolute',-size=>4);
	$tableColumns[2] = $radioGrp[1]."Relative to:".$CGI->popup_menu(-name=>'means',
				-values=>['Mean','Geometric Mean'],default=>'Geometric Mean').
				"<BR>+/-".$CGI->textfield(-name=>'nSigmas',-size=>4).
				" standard deviations.</blockquote>";
	$tableColumns[3] = $radioGrp[2]."Automatic:<BR>".$CGI->popup_menu(-name=>'autoThresh',
				-values=>['Maximum Entropy','Kittler\'s minimum error','Moment-Preservation','Otsu\'s moment preservation'],
				default=>'Maximum Entropy');
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();


	$tableColumns[0] = $CGI->th ('Min. volume');
	$tableColumns[1] = $CGI->textfield(-name=>'minPix',-size=>4,default=>'4')."pixels.";
	@tableColumns = $CGI->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();



	print $OME->CGIheader (-type=>'text/html');
	print $CGI->start_html(-title=>'Run findSpots');
	print $CGI->h2("Enter parameters for findSpots");
	print $CGI->startform;

	print $CGI->table({-border=>1,-cellspacing=>1,-cellpadding=>1},
		$CGI->Tr(\@tableRows)
		);
		
	print "<CENTER>", $CGI->submit(-name=>'Execute',-value=>'Run findSpots'), "</CENTER>";
	print $CGI->endform;
}



sub Execute 
{
my $CGI = $OME->cgi();
my ($cmd,$tuple);
my $dbh = $OME->DBIhandle();
my $sth;
my @datasetPaths;
my @datasetNames;
my @datasetIDs;
my $datasetID;
my $datasetPath;
my $programPath;
my ($tStart,$tStop,$threshold,$wavelength,$minSpotVol);
my @parameters;
my $outputOptions = " -db -tt -th -c 0 -i 0 -m 0 -g 0 -ms 0 -gs 0 -mc -v -sa -per -ff";
my $k;
my ($programStatus,$shortStatus);
my ($analysisID,$nFeatures);
my ($fNameStdout,$fNameStderr);

# Get the path to the program
	$cmd = "SELECT path,program_name FROM programs WHERE program_name='".$programName."'";
	$programPath = join ("",$dbh->selectrow_array($cmd));
	die "Program $programPath does not exist.\n" unless (-e $programPath);
	die "User '".getpwuid ($<)."' does not have permission to execute $programPath\n" unless (-x $programPath);

# Set the wavelength
	$wavelength = sprintf ("%d",$CGI->param('wavelengths'));

# Get a list of selected dataset paths.
	my $image;
my $t0 = new Benchmark;
	my $images = $OME->GetSelectedDatasetObjects();
my $t1 = new Benchmark;
	foreach $image (@$images) {
print STDERR "Dataset: ",$image->Name,"\n";
		next if exists $image->{Wave} and $image->Wave ne $wavelength;
print STDERR "Process: ",$image->Name,"\n";
		push (@datasetIDs,$image->ID);
		push (@datasetPaths,$image->Path.$image->Name);
		push (@datasetNames,$image->Name);
	}

# make up a parameter string based on user entries.
# The order of required parameters (other than dataset name) is:
# <wavelength> <threshold> <min. spot vol.> [<-time#n-#n>] [<-iwght#n>]

# Set the threshold
	if ($CGI->param('threshold') eq 'Absolute')
	{
		$threshold = sprintf ("%d",$CGI->param('Absolute'));
	}
	elsif ($CGI->param('threshold') eq 'Relative')
	{
	my $nSigmas = sprintf ("%.2f",$CGI->param('nSigmas'));
		if ($CGI->param('means') eq 'Mean')
		{
			$threshold = "mean".$nSigmas."s";
		}
		else
		{
			$threshold = "gmean".$nSigmas."s";
		}
	}
	else
	{
	my %thresholdMap = (
		'Moment-Preservation' => 'MOMENT',
		'Otsu\'s moment preservation' => 'OTSU',
		'Maximum Entropy' => 'ME',
		'Kittler\'s minimum error' => 'KITTLER'
		);
		$threshold = $thresholdMap{$CGI->param('autoThresh')};
	}

# Set the times
	$minSpotVol = sprintf ("%d",$CGI->param('minPix'));
	if ($CGI->param('startTime') eq 'Begining')
	{
		$tStart=0;
	}
	else
	{
		$tStart = sprintf ("%d",$CGI->param('Start'));
	}
	if ($CGI->param('stopTime') eq 'End')
	{
		$tStop=0;
	}
	else
	{
		$tStop = sprintf ("%d",$CGI->param('Stop'));
	}

	push (@parameters,$wavelength);
	push (@parameters,$threshold);
	push (@parameters,$minSpotVol);
	if ($tStart || $tStop)
	{
		push (@parameters,"-time".$tStart."-".$tStop);
	}

# Put the output options at the end of the parameter list.
	push (@parameters,$outputOptions);

# format the parameters to go into the database.
# We need to quote the string parameter
	$threshold = "'$threshold'";

# We need to set tStart and tStop to 'NULL' if they are undef.
	$tStart = 'NULL' unless defined $tStart;
	$tStop = 'NULL' unless defined $tStop;

# Loop through the selected datasets
	$k=0;
	foreach $datasetPath (@datasetPaths)
	{
	# Get temporary file names for stdout and stderr.
		$fNameStdout = $OME->GetTempName ($programName.'-'.$datasetIDs[$k],"stdout")
			or die "Couldn't open a temporary file.\n";
		$fNameStderr = $OME->GetTempName ($programName.'-'.$datasetIDs[$k],"stderr")
			or die "Couldn't open a temporary file.\n";
	# Generate the command for executing the program, and execute it.
		$cmd = $programPath." ".$datasetPath." ".join (" ",@parameters).
			" 2> $fNameStderr 1> $fNameStdout";
		$programStatus = system ($cmd);
		$shortStatus = sprintf "%hd",$programStatus;
		$shortStatus = $shortStatus/256;
	# Dump the error file if there were errors.
		if ($shortStatus < 0)
		{
			print "<H2>Errors durring execution:</H2>";
			print "<PRE>",`cat $fNameStderr`,"</PRE>";
		}

	# Process the program's output if there were no errors.
		else
		{
		# Get a new analysis ID by passing the user parameters to the RegisterAnalysis method.
			$analysisID = $OME->RegisterAnalysis(
				datasetID    => $datasetIDs[$k],
				programName  => $programName,
				TIME_START  => $tStart,
				TIME_STOP => $tStop,
				WAVELENGTH  => $wavelength,
				THRESHOLD => $threshold,
				MIN_SPOT_VOL => $minSpotVol);
		
		# This wrapper reads the output, generates features, and writes them into the DB.
			$nFeatures = Process_Output ($analysisID,$fNameStdout);
my $td = timediff($t1, $t0);
			print "<H4>Analysis ID $analysisID on file '$datasetNames[$k]':  ".$nFeatures." features found.</H4>";
		
		# Tell OME that we're done.  OME will commit the transaction we started in the RegisterAnalysis method,
		# Set the view for the dataset, etc.
			$OME->FinishAnalysis();

		# Purge similar analyses from the DB (similar = same program, same user, same dataset).
			$OME->PurgeDataset($datasetIDs[$k]);

		}
		
		unlink ($fNameStdout);
		unlink ($fNameStderr);

		$k++;
	
	}

}


# Convert a table with column headings to a list of OME Feature object that will be written to the database.
sub Process_Output
{
my $analysisID = shift;
my $fileName = shift;
my $line;
# This is the separator that separates columns in each input line.  \t is the tab character.
# It must be a regular expression, thus the qr//.
my $columnSeparator = qr/\t/;

# The features we construct have the column headings as the datamembers.
# These are column headings expected to have an exact match.
# The column heading is the hash key.
# The values are array references where element 0 is the table name and element 1 is the column name.
# Element 2 is the type specifier.  This should be optional in the future, as the rest of the
# elements can be determined from the datatbase by OME.
my %columnKey = (
	't'           => ['TIMEPOINT','TIMEPOINT'],
	'Thresh.'     => ['THRESHOLD','THRESHOLD'],
	'mean X'      => ['LOCATION', 'X'],
	'mean Y'      => ['LOCATION', 'Y'],
	'mean Z'      => ['LOCATION', 'Z'],
	'volume'      => ['EXTENT',   'VOLUME'],
	'perimiter'   => ['EXTENT',   'PERIMITER'],
	'Surf. Area'  => ['EXTENT',   'SURFACE_AREA'],
	'Form Factor' => ['EXTENT',   'FORM_FACTOR']
	);

# These are column headings that are matched using a regular expression.
# Column headings that don't match a heading specified above are searched against these REs.
# In this case, digits within brackets designate a wavelength.
# The actual wavelength will be pushed onto the end of each of these arrays at run-time.
# 'ONE2MANY' tells the database writer that this is an entry in a table that has a many to one relationship
# to the feature.  The array element immediately following that is the name of the discriminator - i.e. the column
# name that will discriminate between the many entries for this feature.  The element following the discriminator name
# is expected to be the value of the discriminator for that instance.  It will be specified at run-time.
# Note on these REs:  The brackets must be escaped cause we're matching an actual bracket.
# There can be one or more digits between the brackets.  There are parentheses around these because we are going
# to capture this number, and use it as the discriminator value.
# Which we will push on to the end of these arays.
# At run-time.
my %columnKeyRE = (	
	'i\[([0-9]+)\]'      => ['SIGNAL',   'INTEGRAL',       'ONE2MANY', 'WAVELENGTH'],
	'c\[([0-9]+)\]X'     => ['SIGNAL',   'CENTROID_X',     'ONE2MANY', 'WAVELENGTH'],
	'c\[([0-9]+)\]Y'     => ['SIGNAL',   'CENTROID_Y',     'ONE2MANY', 'WAVELENGTH'],
	'c\[([0-9]+)\]Z'     => ['SIGNAL',   'CENTROID_Z',     'ONE2MANY', 'WAVELENGTH'],
	'm\[([0-9]+)\]'      => ['SIGNAL',   'MEAN',           'ONE2MANY', 'WAVELENGTH'],
	'ms\[([0-9]+)\]'     => ['SIGNAL',   'SD_OVER_MEAN',   'ONE2MANY', 'WAVELENGTH'],
	'g\[([0-9]+)\]'      => ['SIGNAL',   'GEOMEAN',        'ONE2MANY', 'WAVELENGTH'],
	'gs\[([0-9]+)\]'     => ['SIGNAL',   'SD_OVER_GEOMEAN','ONE2MANY', 'WAVELENGTH']
	);

my ($column,@columns);
my ($key,$value);
my $keyRE;
my $k;
# These are the feature data members hash (%featureData) and the hash that maps the datamembers
# to the database (%featureDBmap).  The keys of the %featuresData hash will become data members of
# the feature objects.  The %featureDBmap is like a 'static' class member that will be used by the
# database writer to map feature datamembers to tables and columns in the database.
#FIXME: Undecided as to how to specify one-many relationship such as SIGNAL.  Interim solution:
# General case:  Datamember  => ['TABLE','COLUMN',  'TYPE OPTIONS'... ],
# one to many:  Datamember  => ['TABLE','COLUMN',   'ONE2MANY', 'DISCRIMINATOR COLUMN','DISCRIMINATOR VALUE' ],
# Example: i[528]  => ['SIGNAL','INTEGRAL',  'ONE2MANY', 'WAVELENGTH','528' ],
my (%featureData,%featureDBmap);

# For convenience, construct an array called dataMembers which either contains the name of the data member
# or an undefined value.  This array will be used to put the column value into the proper data member (if
# there is a data member defined for that column).  The order of the elements in this array will be the dame as
# the order of the columns in the input file.
my ($dataMember,@dataMembers);

# This will conatin the array of features we construct.  These are object references.
my ($feature,@features);



# Open the input file, read a line, and chop off the terminating newline (if any).
	open (INPUT,"< $fileName") or die "Could not open $programName output file '$fileName' for reading\n";
	$line = <INPUT>;
	chomp $line;
# The first line contains the column headings.
# First, split the headings line into individual headings.
	@columns = split ($columnSeparator,$line);
	$k=-1;
LOOP:
# Process the headings one at a time.
	foreach $column (@columns)
	{
		$k++;
	# Trim leading and trailing whitespace.
		$column =~ s/^\s+//;
		$column =~ s/\s+$//;

	# See if there is an exact match for the heading in the columnKey hash.
		if (! exists $columnKey{$column} )
		{
		# If no match was found, try to match to a regular expression in the columnKeyRE hash.
			while ( ($key,$value) = each %columnKeyRE )
			{
			# make a regular expression out of the key.
				$keyRE = qr/$key/;
				if ($column =~ /${keyRE}/)
				{
				# If we found a match to a regular expression, set a feature data member name equal to the
				# column heading name.
					$featureData{$column} = undef;
				# Push the datamember name on to the dataMembers array.
				# This array is in the same order as the columns.
					push (@dataMembers,$column);
				# Make a copy of the database mapping array, and put a reference to it in the $featureDBmap
				# If we extracted something from the RE, set the discriminator to it.
					if (defined $1) { $featureDBmap{$column} = [@$value,$1]; }
				# Otherwise, just copy the array, and make a reference to it.
					else { $featureDBmap{$column} = [@$value]; }

				# Reset the 'each' iterator for this hash, so we start from the begining next time.
					scalar (keys (%columnKeyRE));
				
				# jump immediately to the next iteration (next heading)
					next LOOP;
				}
			}
		# If we made it here, we didn't have an exact match or a RE match.
		# push undef onto the dataMember array to indicate that this column is to be ignored.
			push (@dataMembers,undef);
		}

	# If we found an exact match, set the feature data member name, push the datamember onto the dataMember array,
	# and copy the DB map array.
		else
		{
			$featureData{$column} = undef;
			push (@dataMembers,$column);
			$featureDBmap{$column} = [@{$columnKey{$column}}];
		}

	}


# Process the file one line at a time.
	while (	defined ($line = <INPUT>) )
	{
	# reset the column counter.
		$k=0;
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
##
#	while ( ($key,$value) = each (%featureDBmap) )
#	{
#		print "feature->$key:\n";
#		print join (',',@$value),"\n";
#	}
	return (scalar @features);
}
