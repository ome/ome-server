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

my $xyzImageInfo = OME::DataType->findByTable('XYZ_IMAGE_INFO');
print "  ".$xyzImageInfo->table_name()." (".$xyzImageInfo->id().")\n";

my $xyImageInfo = OME::DataType->findByTable('XY_IMAGE_INFO');
print "  ".$xyImageInfo->table_name()." (".$xyImageInfo->id().")\n";

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

my $calcXyInfo = $factory->newObject("OME::Program",{
    program_name => 'Plane statistics',
    description  => 'Calculate pixel statistics for each XY plane',
    category     => 'Statistics',
    module_type  => 'OME::Analysis::CLIHandler',
    location     => '/OME/bin/OME_Image_XY_stats'
    });
print "  ".$calcXyInfo->program_name()." (".$calcXyInfo->id().")\n";


$output = $factory->newObject("OME::Program::FormalOutput",{
    program  => $calcXyInfo,
    name     => 'Plane info',
    datatype => $xyImageInfo
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
    program  => $calcXyzInfo,
    name     => 'Stack info',
    datatype => $xyzImageInfo
    });
print "    ".$output->name()." (".$output->id().")\n";



my $findSpots = $factory->newObject("OME::Program",{
    program_name => 'Find spots',
    description  => 'Find spots in the image',
    category     => 'Segmentation',
    module_type  => 'OME::Analysis::FindSpotsHandler',
    location     => '/OME/bin/findSpotsOME'
    });
print "  ".$findSpots->program_name()." (".$findSpots->id().")\n";

$input = $factory->newObject("OME::Program::FormalInput",{
    program  => $findSpots,
    name     => 'Stack info',
    datatype => $xyzImageInfo
    });
print "    ".$input->name()." (".$input->id().")\n";


$output = $factory->newObject("OME::Program::FormalOutput",{
    program  => $findSpots,
    name     => 'Timepoint',
    datatype => $timepoint
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program  => $findSpots,
    name     => 'Threshold',
    datatype => $threshold
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program  => $findSpots,
    name     => 'Location',
    datatype => $location
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program  => $findSpots,
    name     => 'Extent',
    datatype => $extent
    });
print "    ".$output->name()." (".$output->id().")\n";

$output = $factory->newObject("OME::Program::FormalOutput",{
    program  => $findSpots,
    name     => 'Signals',
    datatype => $signal
    });
print "    ".$output->name()." (".$output->id().")\n";


$output->dbi_commit();

1;
