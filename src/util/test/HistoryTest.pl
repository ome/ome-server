#!/usr/bin/perl -w
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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------

use strict;
use OME;
use OME::SessionManager;
use OME::Session;
use OME::Tasks::HistoryManager;
use OME::ModuleExecution;
use OME::Module;
use OME::AnalysisChainExecution;
use OME::Remote::Facades::GenericFacade;
use Data::Dumper;
use Carp;



my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();
my $module;
my $name;
my @inputs;
my $input;

# get a mex.

my $mexID = $ARGV[0];
my $chexID = $ARGV[1];

if (defined $mexID) {
    print "Looking for module execution  $mexID\n";
}
else {
    print "No module execution specified. \n";
    exit 0;
}

my $mex = $factory->loadObject('OME::ModuleExecution',$mexID);

$module = $mex->module();
$name = $module->name();

print "module execution " . $mex->ID() . ", module " . $module->ID()
    . ", $name\n";

my @succs = $mex->successors();
print "# of successors is " . scalar(@succs) . "\n";



foreach my $modex (@succs) {
    $module = $modex->module();
    print $modex->ID(). ", module " . $module->name() ."\n";

}

my @preds = $mex->predecessors();

print "# of predecessors is : " . scalar(@preds) . "\n";

foreach (@preds) {
    $module = $_->module();
    print $_->ID(). ", module " . $module->name() ."\n";

}


my @chexes = $mex->chain_executions();
print "# of chain executions is " . scalar(@chexes) . "\n";
my $chain;

foreach (@chexes) {
    $chain =  $_->analysis_chain();
    print $_->ID() . " chain " . $chain->ID() . " name: "
	. $chain->name() ."\n";
}



my @outputs = $mex->actual_outputs();
print "# of outputs is " . scalar(@outputs) . "\n";

foreach my $output (@outputs) {
    my $mex = $output->module_execution();
    print "actual output... " . $output->ID() . ", mex " . $mex->ID()
	. "\n";
}

print "Gettting data history!\n";

my @mexes = OME::Tasks::HistoryManager->getMexDataHistory($mexID);

print "# of predecessors of mex " .$mex->ID() . "  " . scalar(@mexes) . "\n";
dumpHistory(@mexes);

exit 0 unless (defined $chexID);

print "Chain execution History!\n";
@mexes = OME::Tasks::HistoryManager->getChainDataHistory($chexID);

dumpHistory(@mexes);

exit 0;

sub dumpHistory{ 
    my(@mexes) = @_;


    foreach $mex (@mexes) {
	$module = $mex->module();
	$name = $module->name();
	print "\n\n" .$mex->ID() . ",  module " . $module->ID() . ", $name\n";
	print "INPUTS: \n";
	@inputs = $mex->inputs();
	foreach $input (@inputs) {
	    dumpInput($input);
	}
    }
}

sub dumpInput {
    my $input  = shift;
    my $mex = $input->module_execution();
    my $inputMex = $input->input_module_execution();
    print $input->ID() . ", module execution id ..".$mex->ID() . "\n";
    print "Input mex is ". $inputMex->ID() . ", module .. ". 
	$inputMex->module()->name() . "\n";
    my $fin  = $input->formal_input();
    print "Formal input " . $fin->ID() . ", " . $fin->name() . " \n";
    my $st = $fin->semantic_type();
    print "Type: " . $st->ID() . ", " . $st->name() . "\n";
    my $fout = $input->formal_output();
    if (defined $fout) {
	print "Formal output " . $fout->ID() . ", " . $fout->name() . "\n";
	$st = $fout->semantic_type();
	print "Type: " . $st->ID() . ", " . $st->name() . "\n"
	    if (defined $st);
    }
}


