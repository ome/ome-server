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
use OME::DataType;
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


print "Finding datatypes...\n";

my $simpleStatistics = OME::DataType->findByTable('SIMPLE_STATISTICS');
print "  ".$simpleStatistics->table_name()." (".$simpleStatistics->id().")\n";

my $simpleCounts = OME::DataType->findByTable('SIMPLE_COUNTS');
print "  ".$simpleCounts->table_name()." (".$simpleCounts->id().")\n";

my $xyzImageInfo = OME::DataType->findByTable('XYZ_IMAGE_INFO');
print "  ".$xyzImageInfo->table_name()." (".$xyzImageInfo->id().")\n";

my $xyImageInfo = OME::DataType->findByTable('XY_IMAGE_INFO');
print "  ".$xyImageInfo->table_name()." (".$xyImageInfo->id().")\n";

my $features = OME::DataType->findByTable('FEATURES');
print "  ".$features->table_name()." (".$features->id().")\n";

my $timepoint = OME::DataType->findByTable('TIMEPOINT');
print "  ".$timepoint->table_name()." (".$timepoint->id().")\n";

my $threshold = OME::DataType->findByTable('THRESHOLD');
print "  ".$threshold->table_name()." (".$threshold->id().")\n";

my $location = OME::DataType->findByTable('LOCATION');
print "  ".$location->table_name()." (".$location->id().")\n";

my $extent = OME::DataType->findByTable('EXTENT');
print "  ".$extent->table_name()." (".$extent->id().")\n";

my $signal = OME::DataType->findByTable('SIGNAL');
print "  ".$signal->table_name()." (".$signal->id().")\n";

print "Creating programs...\n";

my ($input,$output);

my $testStatistics = $factory->newObject("OME::Program",{
    program_name => 'Test statistics',
    description  => 'Calculate some test statistics',
    category     => 'Tests',
    module_type  => 'OME::Analysis::PerlHandler',
    location     => 'OME::Analysis::TestStatistics'
    });
print "  ".$testStatistics->program_name()." (".$testStatistics->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $testStatistics,
    name        => 'Average',
    column_type => $simpleStatistics->findColumnByName('AVG_INTENSITY')
    });
print "    ".$output->name()." (".$output->id().")\n";
$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $testStatistics,
    name        => 'Minimum',
    column_type => $simpleStatistics->findColumnByName('MIN_INTENSITY')
    });
print "    ".$output->name()." (".$output->id().")\n";
$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $testStatistics,
    name        => 'Maximum',
    column_type => $simpleStatistics->findColumnByName('MAX_INTENSITY')
    });
print "    ".$output->name()." (".$output->id().")\n";

my $testCounts = $factory->newObject("OME::Program",{
    program_name => 'Test counts',
    description  => 'Count pixels based on test statistics',
    category     => 'Tests',
    module_type  => 'OME::Analysis::PerlHandler',
    location     => 'OME::Analysis::TestCounts'
    });
print "  ".$testCounts->program_name()." (".$testCounts->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program     => $testCounts,
    name        => 'Average',
    column_type => $simpleStatistics->findColumnByName('AVG_INTENSITY')
    });
print "    ".$input->name()." (".$input->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $testCounts,
    name        => 'Bright count',
    column_type => $simpleCounts->findColumnByName('NUM_BRIGHT')
    });
print "    ".$output->name()." (".$output->id().")\n";
$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $testCounts,
    name        => 'Average count',
    column_type => $simpleCounts->findColumnByName('NUM_AVERAGE')
    });
print "    ".$output->name()." (".$output->id().")\n";
$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $testCounts,
    name        => 'Dim count',
    column_type => $simpleCounts->findColumnByName('NUM_DIM')
    });
print "    ".$output->name()." (".$output->id().")\n";


my $calcXyInfo = $factory->newObject("OME::Program",{
    program_name => 'Plane statistics',
    description  => 'Calculate pixel statistics for each XY plane',
    category     => 'Statistics',
    module_type  => 'OME::Analysis::CLIHandler',
    location     => '/OME/bin/OME_Image_XY_stats'
    });
print "  ".$calcXyInfo->program_name()." (".$calcXyInfo->id().")\n";


$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyInfo,
    name        => 'Wave',
    column_type => $xyImageInfo->findColumnByName('WAVENUMBER')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyInfo,
    name        => 'Time',
    column_type => $xyImageInfo->findColumnByName('TIMEPOINT')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyInfo,
    name        => 'Z',
    column_type => $xyImageInfo->findColumnByName('ZSECTION')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyInfo,
    name        => 'Min',
    column_type => $xyImageInfo->findColumnByName('MIN')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyInfo,
    name        => 'Max',
    column_type => $xyImageInfo->findColumnByName('MAX')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyInfo,
    name        => 'Mean',
    column_type => $xyImageInfo->findColumnByName('MEAN')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyInfo,
    name        => 'GeoMean',
    column_type => $xyImageInfo->findColumnByName('GEOMEAN')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyInfo,
    name        => 'Sigma',
    column_type => $xyImageInfo->findColumnByName('SIGMA')
    });
print "    ".$output->name()." (".$output->id().")\n";


my $calcXyzInfo = $factory->newObject("OME::Program",{
    program_name => 'Stack statistics',
    description  => 'Calculate pixel statistics for each XYZ stack',
    category     => 'Statistics',
    module_type  => 'OME::Analysis::CLIHandler',
    location     => '/OME/bin/OME_Image_XYZ_stats'
    });
print "  ".$calcXyzInfo->program_name()." (".$calcXyzInfo->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Wave',
    column_type => $xyzImageInfo->findColumnByName('WAVENUMBER')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Time',
    column_type => $xyzImageInfo->findColumnByName('TIMEPOINT')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Min',
    column_type => $xyzImageInfo->findColumnByName('MIN')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Max',
    column_type => $xyzImageInfo->findColumnByName('MAX')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Mean',
    column_type => $xyzImageInfo->findColumnByName('MEAN')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'GeoMean',
    column_type => $xyzImageInfo->findColumnByName('GEOMEAN')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Sigma',
    column_type => $xyzImageInfo->findColumnByName('SIGMA')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Centroid_x',
    column_type => $xyzImageInfo->findColumnByName('CENTROID_X')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Centroid_y',
    column_type => $xyzImageInfo->findColumnByName('CENTROID_Y')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $calcXyzInfo,
    name        => 'Centroid_z',
    column_type => $xyzImageInfo->findColumnByName('CENTROID_Z')
    });
print "    ".$output->name()." (".$output->id().")\n";


my $findSpots = $factory->newObject("OME::Program",{
    program_name => 'Find spots',
    description  => 'Find spots in the image',
    category     => 'Segmentation',
    module_type  => 'OME::Analysis::CLIHandler',
    location     => '/OME/bin/findSpotsOME'
    });
print "  ".$findSpots->program_name()." (".$findSpots->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program     => $findSpots,
    name        => 'Wavelength',
    column_type => $xyzImageInfo->findColumnByName('WAVENUMBER')
    });
print "    ".$input->name()." (".$input->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program     => $findSpots,
    name        => 'Timepoint',
    column_type => $xyzImageInfo->findColumnByName('TIMEPOINT')
    });
print "    ".$input->name()." (".$input->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program     => $findSpots,
    name        => 'Min',
    column_type => $xyzImageInfo->findColumnByName('MIN')
    });
print "    ".$input->name()." (".$input->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program     => $findSpots,
    name        => 'Max',
    column_type => $xyzImageInfo->findColumnByName('MAX')
    });
print "    ".$input->name()." (".$input->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program     => $findSpots,
    name        => 'Mean',
    column_type => $xyzImageInfo->findColumnByName('MEAN')
    });
print "    ".$input->name()." (".$input->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program     => $findSpots,
    name        => 'Geometric mean',
    column_type => $xyzImageInfo->findColumnByName('GEOMEAN')
    });
print "    ".$input->name()." (".$input->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program     => $findSpots,
    name        => 'Sigma',
    column_type => $xyzImageInfo->findColumnByName('SIGMA')
    });
print "    ".$input->name()." (".$input->id().")\n";


$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Timepoint',
    column_type => $timepoint->findColumnByName('TIMEPOINT')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Threshold',
    column_type => $threshold->findColumnByName('THRESHOLD')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'X',
    column_type => $location->findColumnByName('X')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Y',
    column_type => $location->findColumnByName('Y')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Z',
    column_type => $location->findColumnByName('Z')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Volume',
    column_type => $extent->findColumnByName('VOLUME')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Perimeter',
    column_type => $extent->findColumnByName('PERIMITER')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Surface area',
    column_type => $extent->findColumnByName('SURFACE_AREA')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Form factor',
    column_type => $extent->findColumnByName('FORM_FACTOR')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Wavelength',
    column_type => $signal->findColumnByName('WAVELENGTH')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Integral',
    column_type => $signal->findColumnByName('INTEGRAL')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Centroid X',
    column_type => $signal->findColumnByName('CENTROID_X')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Centroid Y',
    column_type => $signal->findColumnByName('CENTROID_Y')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Centroid Z',
    column_type => $signal->findColumnByName('CENTROID_Z')
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Mean',
    column_type => $signal->findColumnByName('MEAN')
    });
print "    ".$output->name()." (".$output->id().")\n";

#$output = $factory->newObject("OME::Program::FormalOutput",{
#    program     => $findSpots,
#    name        => 'StdDev over Mean',
#    column_type => $signal->findColumnByName('SD_OVER_MEAN')
#    });
#print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Geometric Mean',
    column_type => $signal->findColumnByName('GEOMEAN')
    });
print "    ".$output->name()." (".$output->id().")\n";

#$output = $factory->newObject("OME::Program::FormalOutput",{
#    program     => $findSpots,
#    name        => 'StdDev over Geomean',
#    column_type => $signal->findColumnByName('SD_OVER_GEOMEAN')
#    });
#print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program     => $findSpots,
    name        => 'Spots',
    column_type => $features->findColumnByName('NAME')
    });
print "    ".$output->name()." (".$output->id().")\n";


$output->dbi_commit();

1;
