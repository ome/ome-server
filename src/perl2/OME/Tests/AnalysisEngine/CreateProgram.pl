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
print "    ".$input->name()." (".$output->id().")\n";

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


$output->dbi_commit();

1;
