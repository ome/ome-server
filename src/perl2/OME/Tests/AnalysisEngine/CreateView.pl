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
use OME::AnalysisChain;
use Term::ReadKey;

print "\nOME Test Case - Create view\n";
print "---------------------------\n";

if (scalar(@ARGV) != 0) {
    print "Usage:  CreateView\n\n";
    exit -1;
}

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();


my $factory = $session->Factory();
$factory->Debug(0);

my ($node1, $node2, $node3, $node4, $link);

print "Finding programs...\n";

my $calcXYZInfo = OME::Module->findByName('Stack statistics');
print $calcXYZInfo->name()." (".$calcXYZInfo->id().")\n";

my $calcXYInfo = OME::Module->findByName('Plane statistics');
print $calcXYInfo->name()." (".$calcXYInfo->id().")\n";

my $findSpots = OME::Module->findByName('Find spots');
print $findSpots->name()." (".$findSpots->id().")\n";

my $findCells = OME::Module->findByName('Find cells');
print $findCells->name()." (".$findCells->id().")\n";

my $findGolgi = OME::Module->findByName('Find golgi');
print $findGolgi->name()." (".$findGolgi->id().")\n";

my $findMito = OME::Module->findByName('Find mito');
print $findMito->name()." (".$findMito->id().")\n";

my $findRatio = OME::Module->findByName('Find ratio');
print $findRatio->name()." (".$findRatio->id().")\n";


sub __createChain {
    my ($viewdef,$nodedefs,$linkdefs) = @_;

    my @nodes;

    my $view = $factory->
        newObject("OME::AnalysisChain",
                  {
                   owner => $session->User(),
                   name  => $viewdef->[0],
                  });
    die "Bad view" if !defined $view;
    print "  ".$view->name()." (".$view->id().")\n";

    my $nodeCount = 0;
    foreach my $nodedef (@$nodedefs) {
        my $node = $factory->
            newObject("OME::AnalysisChain::Node",
                      {
                       analysis_chain   => $view,
                       module         => $nodedef->[0],
                       iterator_tag    => $nodedef->[1],
                       new_feature_tag => $nodedef->[2]
                      });
        print "    Node $nodeCount ".$node->module()->name()." (".$node->id().")\n";
        push @nodes, $node;
        $nodeCount++;
    }

    foreach my $linkdef (@$linkdefs) {
        my $node1 = $nodes[$linkdef->[0]];
        my $node2 = $nodes[$linkdef->[2]];

        my $link = $factory->
            newObject("OME::AnalysisChain::Link",
                      {
                       analysis_chain => $view,
                       from_node     => $node1,
                       from_output   => $node1->module()->
                       findOutputByName($linkdef->[1]),
                       to_node       => $node2,
                       to_input      => $node2->module()->
                       findInputByName($linkdef->[3])
                      });
        print "    Link [Node ".$linkdef->[0].".".$linkdef->[1]."]->[Node ".$linkdef->[2].".".$linkdef->[3]."]\n";
    }

    return $view;
}

print "Image import chain...\n";
my $importChain = __createChain
    (['Image import analyses'],
     [[$calcXYZInfo],
      [$calcXYInfo]],
     []);

print "Find spots chain...\n";
my $findSpotsChain = __createChain
    (['Find spots'],
     [[$calcXYZInfo],
      [$findSpots,undef,'SPOT']],
     [[0,'Stack mean',1,'Stack mean'],
      [0,'Stack geomean',1,'Stack geomean'],
      [0,'Stack sigma',1,'Stack sigma'],
      [0,'Stack minimum',1,'Stack minimum'],
      [0,'Stack maximum',1,'Stack maximum']]);


print "Feature test chain...\n";
my $featureTestChain = __createChain
    (["Find lots o' stuff"],
     [[$findCells,undef,'CELL'],
      [$findGolgi,'CELL','GOLGI'],
      [$findMito,'CELL','MITOCHONDRIA'],
      [$findRatio,'CELL',undef]],
     [[0,'Output bounds',1,'Input bounds'],
      [0,'Output bounds',2,'Input bounds'],
      [1,'Output bounds',3,'Golgi bounds'],
      [2,'Output bounds',3,'Mito bounds']]);


$importChain->dbi_commit();

1;
