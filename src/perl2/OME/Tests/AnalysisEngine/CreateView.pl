# OME/Tests/AnalysisEngine/CreateView.pl

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
use OME::AnalysisView;
use Term::ReadKey;

print "\nOME Test Case - Create view\n";
print "---------------------------\n";

if (scalar(@ARGV) != 0) {
    print "Usage:  CreateView\n\n";
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

my ($node1, $node2, $link);

print "Finding programs...\n";

my $testStatistics = OME::Program->findByName('Test statistics');
print $testStatistics->program_name()." (".$testStatistics->id().")\n";

my $testCounts = OME::Program->findByName('Test counts');
print $testCounts->program_name()." (".$testCounts->id().")\n";

print "Chain with 1 node...\n";

my $view = $factory->newObject("OME::AnalysisView",{
    owner => $session->User(),
    name  => "Test chain"
    });
die "Bad view" if !defined $view;
print "  ".$view->name()." (".$view->id().")\n";


$node1 = $factory->newObject("OME::AnalysisView::Node",{
    analysis_view => $view,
    program       => $testStatistics
    });
print "    Node 1 ".$node1->program()->program_name()." (".$node1->id().")\n";


print "Chain with 2 nodes...\n";

my $view = $factory->newObject("OME::AnalysisView",{
    owner => $session->User(),
    name  => "Test chain 2"
    });
die "Bad view" if !defined $view;
print "  ".$view->name()." (".$view->id().")\n";

$node1 = $factory->newObject("OME::AnalysisView::Node",{
    analysis_view => $view,
    program       => $testStatistics
    });
print "    Node 1 ".$node1->program()->program_name()." (".$node1->id().")\n";

$node2 = $factory->newObject("OME::AnalysisView::Node",{
    analysis_view => $view,
    program       => $testCounts
    });
print "    Node 2 ".$node2->program()->program_name()." (".$node2->id().")\n";

$link = $factory->newObject("OME::AnalysisView::Link",{
    analysis_view => $view,
    from_node     => $node1,
    from_output   => $node1->program()->findOutputByName('Average'),
    to_node       => $node2,
    to_input      => $node2->program()->findInputByName('Average')
    });
print "    Link [Node 1.Average]->[Node 2.Average]\n";


$link->dbi_commit();

1;
