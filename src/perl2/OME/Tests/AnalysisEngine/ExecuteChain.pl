# OME/Tests/AnalysisEngine/ExecuteChain.pl

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
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
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


use OME::Session;
use OME::SessionManager;
use OME::AnalysisChain;
use OME::Dataset;
use OME::Analysis::AnalysisEngine;
use OME::Tasks::ChainManager;
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
    print "Usage:  ExecuteView <view id> <dataset id> <flags>\n";
    print "known flags are: ReuseResults, DebugDefault, DebugTiming. Flag usage is [flag]=[0 or 1] (i.e. ReuseResults=0)\n\n";
# flags are listed in AnalysisEngine, so I say known flags cuz the flags there might change independently of this usage note.

    exit -1;
}

my $chainID = shift(@ARGV);
my $datasetID = shift(@ARGV);

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();


my $factory = $session->Factory();


my $chain = $factory->loadObject("OME::AnalysisChain",$chainID);
my $dataset = $factory->loadObject("OME::Dataset",$datasetID);

my $engine = OME::Analysis::AnalysisEngine->new();

foreach my $flag_string (@ARGV) {
    my ($flag,$value) = split(/=/,$flag_string,2);
    if ($flag eq "Cached") {
        OME::DBObject->Caching($value);
    } else {
        $engine->Flag($flag,$value);
    }
}

OME::DBObject->Caching(1) if $ENV{'OME_CACHE'};

# Retrieve user inputs

my $cmanager = OME::Tasks::ChainManager->new($session);

my $user_input_list = $cmanager->getUserInputs($chain);

print "User inputs:\n";

my %user_inputs;

foreach my $user_input (@$user_input_list) {
    my ($node,$module,$formal_input,$semantic_type) = @$user_input;
    print "\n",$module->name(),".",$formal_input->name(),":\n";

    my $new;
    while ($new ne 'N' && $new ne 'E') {
        print "  New or existing? [N]/E  ";
        $new = <STDIN>;
        chomp($new);
        $new = uc($new) || 'N';
    }

    my @columns = $semantic_type->semantic_elements();
    my @attributes;

    if ($new eq 'N') {
        my $count = 0;

      LIST_LOOP:
        while (1) {
            $count++;
            print "  Attribute #$count\n";
            my $data_hash = {};

            foreach my $column (@columns) {
                my $column_name = $column->name();

                print "    ",$column_name,": ";
                my $value = <STDIN>;
                chomp($value);
                last LIST_LOOP if ($value eq '\d');
                $value = undef if ($value eq '');
                $value = '' if ($value eq '\0');
                $data_hash->{$column_name} = $value;
            }

            my $attribute = $factory->
              newAttribute($semantic_type,undef,undef,$data_hash);
            push @attributes,$attribute;
        }
    } else {
        print "  Type in a list of attribute ID's, separated by spaces.\n";
        print "  [Enter] by itself will terminate the list.\n";

      LIST_LOOP:
        while (1) {
            print "  ? ";
            my $value = <STDIN>;
            chomp($value);
            my @ids = split(' ',$value);
            last LIST_LOOP if scalar(@ids) == 0;

          ID_LOOP:
            foreach my $id (@ids) {
                if ($id !~ /^\d+$/) {
                    print "    $id is not a number.  Skipping.\n";
                    next ID_LOOP;
                }

                my $attribute = $factory->loadAttribute($semantic_type,$id);
                if (!defined $attribute) {
                    print "    Could not find attribute #$id.  Skipping.\n";
                    next ID_LOOP;
                }

                print "    Adding attribute #$id.\n";
                push @attributes, $attribute;
            }
        }
    }

    $user_inputs{$node->id()}->{$formal_input->id()} = \@attributes;
}

$engine->executeAnalysisView($session,$chain,\%user_inputs,$dataset);

#$session->BenchmarkTimer->report();

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
