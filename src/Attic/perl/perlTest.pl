#!/usr/bin/perl -w

use Pg;
use OMEpl;
use strict;
use POSIX qw(strftime);
my ($key,$value);

print "\n";





my $Variable = "foo";
my $variable2;
my $now_string = strftime "%a %b %e %H:%M:%S %Y", localtime;
my $month = strftime "%b", localtime;
my $day = strftime "%e", localtime;
my $year = strftime "%Y", localtime;
my $OME = new OMEpl;

my $cmd;
my $result;
my $conn=$OME->conn;


$OME->SetSelectedDatasets(3);
$OME->StartAnalysis();


my ($col1,$col2,$col3,$col4,$col5);

$cmd = "SELECT * from analyses";
$result = $conn->exec($cmd);
die "error executing '$cmd':\n".$conn->errorMessage unless PGRES_TUPLES_OK eq $result->resultStatus;
($col1,$col2,$col3,$col4,$col5) = $result->fetchrow;
if ($col1) {print "col1 : $col1 \n";}
print "col2 : $col2 \n";
print "col3 : $col3 \n";
print "col4 : $col4 \n";
print "col5 : $col5 \n";

my %testHash = (
	param1 => 'foo',
	param2 => 'Bar',
	param3 => 1,
	param4 => 2,
	param5 => 3
	);
	

&print_hash (%testHash);
&print_delete_hash (%testHash);


$testHash {'param2'} = 'Bar2';

&print_hash (%testHash);

$testHash {'param3'} = 'blech';
&print_hash (%testHash);

&print_hash (param1=>'foo',param4=>'test3');
&print_first (%testHash);
&print_first (12345);

$key = "table__value";
my ($table,$column);
($table,$column) = split (/__/,$key);
$table = uc ($table);
$column = uc ($column);
print "Key: $key, Table: $table, Column: $column\n";

$OME->{'fooBar'} = "New data member";
print "Added OME data member : ".$OME->{'fooBar'}."\n";

my $features = $OME->GetFeatures (DatasetID=>undef, AnalysisID=> 3, FeatureID=>undef, fooAttribue=>"test",
		'location__x'=>undef,
		'location__y'=>undef,
		'location__z'=>undef,
		'cluster_f__cluster_id'=>undef,
		'timepoint__timepoint'=>undef);


my $feature;
foreach $feature (@$features)
{
	print "Feature ID          : ".$feature->ID."\n";
	print "AnalysisID          : ".$feature->AnalysisID."\n";
	print "DatasetID           : ".$feature->DatasetID."\n";
	print "fooAttribue         : ".$feature->fooAttribue."\n";
	print "location.x          : ".$feature->location__x."\n";
	print "location.y          : ".$feature->location__y."\n";
	print "location.z          : ".$feature->location__z."\n";
	print "timepoint.timepoint : ".$feature->timepoint__timepoint."\n";
}

print return_increment()."\n";
print return_increment()."\n";
print return_increment()."\n";
print return_increment()."\n";
print return_increment()."\n";
print return_increment()."\n";

print_array_ref($features);
my $attribute_str = "   cluster_f__cluster_id 	location__x                     location__y";
print $OME->MakeFeatureQuery (3,split (' ',$attribute_str))."\n";



{
my $value;
sub return_increment {

	$value = 0 unless defined $value;
	
	$value++;
	return $value;
}
}

sub print_array_ref {
	my $featuresRef = shift;

	my $features;
	my $feature;
	
	return unless ref($featuresRef);
	print "featuresRef is a reference to ".ref($featuresRef)."\n";
	$features = $featuresRef if ref($featuresRef) eq "ARRAY";
	print "features is a reference to ".ref($features)."\n";
	foreach $feature (@$features) {print $feature->ID."\n";}
	
}



sub print_hash {
	my %params = @_;
print join (",",keys %params),"\n",join(",",values %params),"\n";
}
sub print_delete_hash {
	my %params = @_;
	delete $params{'param1'};
print join (",",keys %params),"\n",join(",",values %params),"\n";
}

sub print_first {
	my $first = $_[0];
	print "First : $first \n";
}
