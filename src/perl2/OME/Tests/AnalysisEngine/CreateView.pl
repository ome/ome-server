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

my ($node1, $node2, $node3, $node4, $link);

print "Finding programs...\n";

my $calcXyzInfo = OME::Program->findByName('Stack statistics');
print $calcXyzInfo->program_name()." (".$calcXyzInfo->id().")\n";

my $calcXyInfo = OME::Program->findByName('Plane statistics');
print $calcXyInfo->program_name()." (".$calcXyInfo->id().")\n";

my $findSpots = OME::Program->findByName('Find spots');
print $findSpots->program_name()." (".$findSpots->id().")\n";

my $findCells = OME::Program->findByName('Find cells');
print $findCells->program_name()." (".$findCells->id().")\n";

my $findGolgi = OME::Program->findByName('Find golgi');
print $findGolgi->program_name()." (".$findGolgi->id().")\n";

my $findMito = OME::Program->findByName('Find mito');
print $findMito->program_name()." (".$findMito->id().")\n";

my $findRatio = OME::Program->findByName('Find ratio');
print $findRatio->program_name()." (".$findRatio->id().")\n";

print "Image import chain...\n";

my $view = $factory->
  newObject("OME::AnalysisView",
            {
             owner => $session->User(),
             name  => "Image import analyses"
            });
die "Bad view" if !defined $view;
print "  ".$view->name()." (".$view->id().")\n";


$node1 = $factory->
  newObject("OME::AnalysisView::Node",
            {
             analysis_view => $view,
             program       => $calcXyzInfo,
             iterator_tag  => undef
            });
print "    Node 1 ".$node1->program()->program_name()." (".$node1->id().")\n";

$node1 = $factory->
  newObject("OME::AnalysisView::Node",
            {
             analysis_view => $view,
             program       => $calcXyInfo,
             iterator_tag  => undef
            });
print "    Node 2 ".$node1->program()->program_name()." (".$node1->id().")\n";


print "Find spots chain...\n";

my $view = $factory->
  newObject("OME::AnalysisView",
            {
             owner => $session->User(),
             name  => "Find spots"
            });
die "Bad view" if !defined $view;
print "  ".$view->name()." (".$view->id().")\n";


$node1 = $factory->
  newObject("OME::AnalysisView::Node",
            {
             analysis_view => $view,
             program       => $calcXyzInfo,
             iterator_tag  => undef
            });
print "    Node 1 ".$node1->program()->program_name()." (".$node1->id().")\n";

$node2 = $factory->
  newObject("OME::AnalysisView::Node",
            {
             analysis_view => $view,
             program       => $findSpots,
             iterator_tag  => undef
            });
print "    Node 2 ".$node2->program()->program_name()." (".$node2->id().")\n";

$link = $factory->
  newObject("OME::AnalysisView::Link",
            {
             analysis_view => $view,
             from_node     => $node1,
             from_output   => $node1->program()->findOutputByName('Stack info'),
             to_node       => $node2,
             to_input      => $node2->program()->findInputByName('Stack info')
            });
print "    Link [Node 1.Stack info]->[Node 2.Stack info]\n";


print "Feature test chain...\n";

my $view = $factory->
  newObject("OME::AnalysisView",
            {
             owner => $session->User(),
             name  => "Find lots o' stuff"
            });
die "Bad view" if !defined $view;
print "  ".$view->name()." (".$view->id().")\n";


$node1 = $factory->
  newObject("OME::AnalysisView::Node",
            {
             analysis_view => $view,
             program       => $findCells,
             iterator_tag  => undef
            });
print "    Node 1 ".$node1->program()->program_name()." (".$node1->id().")\n";

$node2 = $factory->
  newObject("OME::AnalysisView::Node",
            {
             analysis_view => $view,
             program       => $findGolgi,
             iterator_tag  => 'CELL'
            });
print "    Node 2 ".$node2->program()->program_name()." (".$node2->id().")\n";

$node3 = $factory->
  newObject("OME::AnalysisView::Node",
            {
             analysis_view => $view,
             program       => $findMito,
             iterator_tag  => 'CELL'
            });
print "    Node 3 ".$node3->program()->program_name()." (".$node3->id().")\n";

$node4 = $factory->
  newObject("OME::AnalysisView::Node",
            {
             analysis_view => $view,
             program       => $findRatio,
             iterator_tag  => 'CELL'
            });
print "    Node 4 ".$node4->program()->program_name()." (".$node4->id().")\n";

$link = $factory->
  newObject("OME::AnalysisView::Link",
            {
             analysis_view => $view,
             from_node     => $node1,
             from_output   => $node1->program()->findOutputByName('Output bounds'),
             to_node       => $node2,
             to_input      => $node2->program()->findInputByName('Input bounds')
            });
print "    Link [Node 1.Output bounds]->[Node 2.Input bounds]\n";

$link = $factory->
  newObject("OME::AnalysisView::Link",
            {
             analysis_view => $view,
             from_node     => $node1,
             from_output   => $node1->program()->findOutputByName('Output bounds'),
             to_node       => $node3,
             to_input      => $node3->program()->findInputByName('Input bounds')
            });
print "    Link [Node 1.Output bounds]->[Node 3.Input bounds]\n";

$link = $factory->
  newObject("OME::AnalysisView::Link",
            {
             analysis_view => $view,
             from_node     => $node2,
             from_output   => $node2->program()->findOutputByName('Output bounds'),
             to_node       => $node4,
             to_input      => $node4->program()->findInputByName('Golgi bounds')
            });
print "    Link [Node 2.Output bounds]->[Node 4.Golgi bounds]\n";

$link = $factory->
  newObject("OME::AnalysisView::Link",
            {
             analysis_view => $view,
             from_node     => $node3,
             from_output   => $node3->program()->findOutputByName('Output bounds'),
             to_node       => $node4,
             to_input      => $node4->program()->findInputByName('Mito bounds')
            });
print "    Link [Node 3.Output bounds]->[Node 4.Mito bounds]\n";




$link->dbi_commit();

1;
