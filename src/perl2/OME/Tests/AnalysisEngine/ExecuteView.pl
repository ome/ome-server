# OME/Tests/AnalysisEngine/ExecuteView.pl

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
use OME::Dataset;
use OME::Tasks::AnalysisEngine;
use Term::ReadKey;

# I really hate those "method clash" warnings, especially since these
# methods are now deprecated.
no strict 'refs';
undef &Class::DBI::min;
undef &Class::DBI::max;
use strict 'refs';

print "\nOME Test Case - Execute view\n";
print "----------------------------\n";

if (scalar(@ARGV) < 2) {
    print "Usage:  ExecuteView <view id> <dataset id> <flags>\n\n";
    exit -1;
}

my $viewID = shift(@ARGV);
my $datasetID = shift(@ARGV);

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();


my $factory = $session->Factory();
$factory->Debug(0);


my $view = $factory->loadObject("OME::AnalysisView",$viewID);
my $dataset = $factory->loadObject("OME::Dataset",$datasetID);

my $engine = OME::Tasks::AnalysisEngine->new();

foreach my $flag_string (@ARGV) {
    my ($flag,$value) = split(/=/,$flag_string,2);
    if ($flag eq "Cached") {
        OME::DBObject->Caching($value);
    } else {
        $engine->Flag($flag,$value);
    }
}

$engine->executeAnalysisView($session,$view,{},$dataset);

my $cache = OME::DBObject->__cache();
my $numClasses = scalar(keys %$cache);
my $numObjects = 0;

foreach my $class (keys %$cache) {
    my $classCache = $cache->{$class};
    my $numClassObjects = scalar(keys %$classCache);
    printf STDERR "%5d %s\n", $numClassObjects, $class;
    $numObjects += $numClassObjects;
}

printf STDERR "\n%5d TOTAL\n", $numObjects;

1;
