# OME/Tests/AnalysisEngine/CreateProgram.pl

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


use OME::Session;
use OME::SessionManager;
use OME::Program;
use OME::DataTable;
use OME::AttributeType;
use Term::ReadKey;

print "\nOME Test Case - Create program\n";
print "---------------------------\n";

if (scalar(@ARGV) != 0) {
    print "Usage:  CreateProgram\n\n";
    exit -1;
}

print "Please login to OME:\n";

print "Username? ";
ReadMode(1);
my $username = ReadLine(0);
chomp($username);

print "Password? ";
ReadMode(2);
my $password = ReadLine(0);
chomp($password);
print "\n";
ReadMode(1);

my $manager = OME::SessionManager->new();
my $session = $manager->createSession($username,$password);

if (!defined $session) {
    print "That username/password does not seem to be valid.\nBye.\n\n";
    exit -1;
}

print "Great, you're in.\n\n";

my $factory = $session->Factory();
$factory->Debug(0);


print "Finding data tables...\n";

my $xyzImageInfo = $factory->findObject("OME::DataTable",table_name => 'XYZ_IMAGE_INFO');
print "  ".$xyzImageInfo->table_name()." (".$xyzImageInfo->id().")\n";

my $xyImageInfo = $factory->findObject("OME::DataTable",table_name => 'XY_IMAGE_INFO');
print "  ".$xyImageInfo->table_name()." (".$xyImageInfo->id().")\n";

my $timepoint = $factory->findObject("OME::DataTable",table_name => 'TIMEPOINT');
print "  ".$timepoint->table_name()." (".$timepoint->id().")\n";

my $threshold = $factory->findObject("OME::DataTable",table_name => 'THRESHOLD');
print "  ".$threshold->table_name()." (".$threshold->id().")\n";

my $location = $factory->findObject("OME::DataTable",table_name => 'LOCATION');
print "  ".$location->table_name()." (".$location->id().")\n";

my $extent = $factory->findObject("OME::DataTable",table_name => 'EXTENT');
print "  ".$extent->table_name()." (".$extent->id().")\n";

my $signal = $factory->findObject("OME::DataTable",table_name => 'SIGNAL');
print "  ".$signal->table_name()." (".$signal->id().")\n";

my $bounds = $factory->findObject("OME::DataTable",table_name => 'BOUNDS');
print "  ".$bounds->table_name()." (".$bounds->id().")\n";

my $ratio = $factory->findObject("OME::DataTable",table_name => 'RATIO');
print "  ".$ratio->table_name()." (".$ratio->id().")\n";


print "Create attribute types...\n";

my ($atype,$acolumn);


my $atype = $factory->newObject("OME::AttributeType",{
    name        => 'Stack mean',
    granularity => 'I',
    description => ''
    });
print "  ".$atype->name()." (".$atype->id().")\n";
my $xyzMean = $atype;

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'WAVENUMBER',
    data_column    => $xyzImageInfo->findColumnByName('WAVENUMBER'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'TIMEPOINT',
    data_column    => $xyzImageInfo->findColumnByName('TIMEPOINT'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'MEAN',
    data_column    => $xyzImageInfo->findColumnByName('MEAN'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";


my $atype = $factory->newObject("OME::AttributeType",{
    name        => 'Stack geomean',
    granularity => 'I',
    description => ''
    });
print "  ".$atype->name()." (".$atype->id().")\n";
my $xyzGeomean = $atype;

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'WAVENUMBER',
    data_column    => $xyzImageInfo->findColumnByName('WAVENUMBER'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'TIMEPOINT',
    data_column    => $xyzImageInfo->findColumnByName('TIMEPOINT'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'GEOMEAN',
    data_column    => $xyzImageInfo->findColumnByName('GEOMEAN'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";


my $atype = $factory->newObject("OME::AttributeType",{
    name        => 'Stack sigma',
    granularity => 'I',
    description => ''
    });
print "  ".$atype->name()." (".$atype->id().")\n";
my $xyzSigma = $atype;

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'WAVENUMBER',
    data_column    => $xyzImageInfo->findColumnByName('WAVENUMBER'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'TIMEPOINT',
    data_column    => $xyzImageInfo->findColumnByName('TIMEPOINT'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'SIGMA',
    data_column    => $xyzImageInfo->findColumnByName('SIGMA'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";


my $atype = $factory->newObject("OME::AttributeType",{
    name        => 'Stack minimum',
    granularity => 'I',
    description => ''
    });
print "  ".$atype->name()." (".$atype->id().")\n";
my $xyzMinimum = $atype;

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'WAVENUMBER',
    data_column    => $xyzImageInfo->findColumnByName('WAVENUMBER'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'TIMEPOINT',
    data_column    => $xyzImageInfo->findColumnByName('TIMEPOINT'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'MAX',
    data_column    => $xyzImageInfo->findColumnByName('MAX'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";


my $atype = $factory->newObject("OME::AttributeType",{
    name        => 'Stack centroid',
    granularity => 'I',
    description => ''
    });
print "  ".$atype->name()." (".$atype->id().")\n";
my $xyzCentroid = $atype;

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'WAVENUMBER',
    data_column    => $xyzImageInfo->findColumnByName('WAVENUMBER'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'TIMEPOINT',
    data_column    => $xyzImageInfo->findColumnByName('TIMEPOINT'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'X',
    data_column    => $xyzImageInfo->findColumnByName('CENTROID_X'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'Y',
    data_column    => $xyzImageInfo->findColumnByName('CENTROID_Y'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";

$acolumn = $factory->newObject("OME::AttributeType::Column",{
    attribute_type => $atype,
    name           => 'Z',
    data_column    => $xyzImageInfo->findColumnByName('CENTROID_Z'),
    description    => ''
    });
print "    ".$acolumn->name()." : ".$acolumn->data_column()->column_name()." (".$acolumn->id()." )\n";


$acolumn->dbi_commit();

exit;


print "Creating programs...\n";

my ($input,$output);

my $calcXyInfo = $factory->
  newObject("OME::Program",
            {
             program_name     => 'Plane statistics',
             description      => 'Calculate pixel statistics for each XY plane',
             category         => 'Statistics',
             module_type      => 'OME::Analysis::CLIHandler',
             location         => '/OME/bin/OME_Image_XY_stats',
             default_iterator => undef,
             new_feature_tag  => undef
            });
print "  ".$calcXyInfo->program_name()." (".$calcXyInfo->id().")\n";


$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $calcXyInfo,
             name     => 'Plane info',
             datatype => $xyImageInfo
            });
print "    ".$output->name()." (".$output->id().")\n";



my $calcXyzInfo = $factory->
  newObject("OME::Program",
            {
             program_name     => 'Stack statistics',
             description      => 'Calculate pixel statistics for each XYZ stack',
             category         => 'Statistics',
             module_type      => 'OME::Analysis::CLIHandler',
             location         => '/OME/bin/OME_Image_XYZ_stats',
             default_iterator => undef,
             new_feature_tag  => undef
            });
print "  ".$calcXyzInfo->program_name()." (".$calcXyzInfo->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $calcXyzInfo,
             name     => 'Stack info',
             datatype => $xyzImageInfo
            });
print "    ".$output->name()." (".$output->id().")\n";



my $findSpots = $factory->
  newObject("OME::Program",
            {
             program_name     => 'Find spots',
             description      => 'Find spots in the image',
             category         => 'Segmentation',
             module_type      => 'OME::Analysis::FindSpotsHandler',
             location         => '/OME/bin/findSpotsOME',
             default_iterator => undef,
             new_feature_tag  => 'SPOT'
            });
print "  ".$findSpots->program_name()." (".$findSpots->id().")\n";

$input = $factory->
  newObject("OME::Program::FormalInput",
            {
             program  => $findSpots,
             name     => 'Stack info',
             datatype => $xyzImageInfo
            });
print "    ".$input->name()." (".$input->id().")\n";


$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findSpots,
             name     => 'Timepoint',
             datatype => $timepoint,
             feature_tag => '[Feature]'
            });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findSpots,
             name     => 'Threshold',
             datatype => $threshold,
             feature_tag => '[Feature]'
            });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findSpots,
             name     => 'Location',
             datatype => $location,
             feature_tag => '[Feature]'
            });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findSpots,
             name     => 'Extent',
             datatype => $extent,
             feature_tag => '[Feature]'
            });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findSpots,
             name     => 'Signals',
             datatype => $signal,
             feature_tag => '[Feature]'
            });
print "    ".$output->name()." (".$output->id().")\n";


my $findCells = $factory->
  newObject("OME::Program",
            {
             program_name     => 'Find cells',
             description      => 'Find cells',
             category         => 'Testing',
             module_type      => 'OME::Analysis::FindBounds',
             location         => '',
             default_iterator => undef,
             new_feature_tag  => 'CELL'
            });
print "  ".$findCells->program_name()." (".$findCells->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findCells,
             name     => 'Output bounds',
             datatype => $bounds,
             feature_tag => '[Feature]'
            });
print "    ".$output->name()." (".$output->id().")\n";


my $findGolgi = $factory->
  newObject("OME::Program",
            {
             program_name     => 'Find golgi',
             description      => 'Find golgi',
             category         => 'Testing',
             module_type      => 'OME::Analysis::FindBounds',
             location         => '',
             default_iterator => 'CELL',
             new_feature_tag  => 'GOLGI'
            });
print "  ".$findGolgi->program_name()." (".$findGolgi->id().")\n";

$input = $factory->
  newObject("OME::Program::FormalInput",
            {
             program  => $findGolgi,
             name     => 'Input bounds',
             datatype => $bounds
            });
print "    ".$input->name()." (".$input->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findGolgi,
             name     => 'Output bounds',
             datatype => $bounds,
             feature_tag => '[Feature]'
            });
print "    ".$output->name()." (".$output->id().")\n";


my $findMito = $factory->
  newObject("OME::Program",
            {
             program_name     => 'Find mito',
             description      => 'Find mito',
             category         => 'Testing',
             module_type      => 'OME::Analysis::FindBounds',
             location         => '',
             default_iterator => 'CELL',
             new_feature_tag  => 'MITOCHONDRIA'
            });
print "  ".$findMito->program_name()." (".$findMito->id().")\n";

$input = $factory->
  newObject("OME::Program::FormalInput",
            {
             program  => $findMito,
             name     => 'Input bounds',
             datatype => $bounds
            });
print "    ".$input->name()." (".$input->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findMito,
             name     => 'Output bounds',
             datatype => $bounds,
             feature_tag => '[Feature]'
            });
print "    ".$output->name()." (".$output->id().")\n";


my $findRatio = $factory->
  newObject("OME::Program",
            {
             program_name     => 'Find ratio',
             description      => 'Find ratio',
             category         => 'Testing',
             module_type      => 'OME::Analysis::FindRatio',
             location         => '',
             default_iterator => 'CELL',
             new_feature_tag  => undef
            });
print "  ".$findRatio->program_name()." (".$findRatio->id().")\n";

$input = $factory->
  newObject("OME::Program::FormalInput",
            {
             program  => $findRatio,
             name     => 'Golgi bounds',
             datatype => $bounds
            });
print "    ".$input->name()." (".$input->id().")\n";

$input = $factory->
  newObject("OME::Program::FormalInput",
            {
             program  => $findRatio,
             name     => 'Mito bounds',
             datatype => $bounds
            });
print "    ".$input->name()." (".$input->id().")\n";

$output = $factory->
  newObject("OME::Program::FormalOutput",
            {
             program  => $findRatio,
             name     => 'Golgi-mito ratio',
             datatype => $ratio,
             feature_tag => '[Iterator]'
            });
print "    ".$output->name()." (".$output->id().")\n";



$output->dbi_commit();

1;
