#! /usr/bin/perl
use strict;
use OME::SessionManager;
use OME::Factory;
use OME::Tasks::ModuleExecutionManager;

my $session = OME::SessionManager->TTYlogin();
my $factory = $session->Factory();

my $chex = $factory->findObject( 'OME::AnalysisChainExecution',
                                   id => 46 )
    or die "Couldn't load CHEX";

print "Loading Chain Execution's MEXs ...\n";

my @NEXs = $chex->node_executions();
my @MEXs  = map( $_->module_execution, @NEXs );
my $i=0;
foreach my $mex (@MEXs) {
	print "Analyzing MEX ".$i++." of ".scalar(@MEXs);

	my $image = $mex->image();

	my @img_features = $image->all_features();
	my $num_features = scalar(@img_features);

	my @formal_outputs = $factory->findObjects('OME::Module::FormalOutput',
											module => $mex->module()
									);
	# skip MEXs that are not finished
	if ($mex->status ne 'FINISHED') { 
		print " [SKIP]\n";
		next;
	}
	foreach my $fo (@formal_outputs) {
		my @all_attributes = @{OME::Tasks::ModuleExecutionManager->getAttributesForMEX($mex, $fo->semantic_type())};
		if (scalar(@all_attributes) ne $num_features) {	
			foreach my $feature (@img_features) {		
				my @attributes = @{OME::Tasks::ModuleExecutionManager->getAttributesForMEX($mex, $fo->semantic_type(), {feature=>$feature})};
				if (scalar @attributes == 0) {
					print " [ERROR] MEX: '".$mex->id()."' Feature: '".$feature->name()."' FO: '".$fo->name(). "' has ".scalar(@attributes)." attributes\n";
					$mex->status('ERROR');
				} elsif (scalar @attributes == 1) {
					print " [OK] MEX: '".$mex->id(). "' Feature: '".$feature->name()."' FO: '".$fo->name()."'\n";
				} else {
					print " [ERROR] MEX: '".$mex->id()."' Feature: '".$feature->name()."' FO: '".$fo->name(). "' has ".scalar(@attributes)." attributes\n";
					#by starting the for loop with j=1, we skip an attribute
					for (my $j=1; $j < scalar (@attributes); $j++) {
						my $attribute = $attributes[$j] or die "couldn`t load attribute";
						$attribute->deleteObject();
					}
				}
			}
		} else {
	#		print " [OK] MEX: '".$mex->id(). "' FO: '".$fo->name()."'\n";
			;
		}
	}
	$mex->storeObject();
	print "\n";
}

print "Commiting Transaction ...";
$session->commitTransaction();