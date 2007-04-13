#! /usr/bin/perl
use strict;
use OME::SessionManager;
use OME::Factory;
use OME::Tasks::ModuleExecutionManager;
use OME::Tasks::ImageManager;

my $session = OME::SessionManager->TTYlogin();
my $factory = $session->Factory();

my $chex = $factory->findObject( 'OME::AnalysisChainExecution',
                                   id => 65 )
    or die "Couldn't load CHEX";

# find the NODE that produces ROIs
my $ROI_node = $factory->findObject ("OME::AnalysisChain::Node",
									analysis_chain => $chex->analysis_chain(),
									'module.name' => 'Image 2D Tiled ROIs')
or die "Couldn't find ROI producing node in chain";

my $ROI_FO = $factory->findObject ("OME::Module::FormalOutput",
									module => $ROI_node->module(),
									name => "Image ROIs")
or die "Couldn't find ROI Formal Output";


print "Loading Chain Execution's MEXs ...\n";

my @NEXs = $chex->node_executions();
my @MEXs  = map( $_->module_execution, @NEXs );
my $i=0;
foreach my $mex (@MEXs) {
	print "Analyzing MEX ".$i++." of ".scalar(@MEXs);

	# skip MEXs that are not finished
	if ($mex->status ne 'FINISHED') { 
		print " [SKIP]\n";
		next;
	}
	
	my $image = $mex->image();
	
	#
	# figure out which MEX's features are relevent to this chain
	#
	my $originalFile = OME::Tasks::ImageManager->getImageOriginalFiles($image);
	die "Image ".$_->name." doesn't have exactly one Original File"
		if( ref( $originalFile ) eq 'ARRAY' );
	
	# get ROI Node execution
	my $ROI_nex = $factory->findObject ("OME::AnalysisChainExecution::NodeExecution",
										analysis_chain_execution => $chex,
										analysis_chain_node => $ROI_node,
										'module_execution.image' => $image,
									   ) or die "couldn't load ROI NEX";
	
	my @img_features;
	my @all_img_features = $image->all_features();
	foreach my $feature (@all_img_features) {
		# select the features made by this CHEX
		my @attributes = @{OME::Tasks::ModuleExecutionManager->getAttributesForMEX($ROI_nex->module_execution(),
																				   $ROI_FO->semantic_type(),
																				   {feature =>$feature})};
		my $attribute = $attributes[0];
		next unless (defined $attribute); # i.e. this ROI wasn't made by this signature chain
		
		push @img_features, $feature;
	}
	
	my @formal_outputs = $factory->findObjects('OME::Module::FormalOutput',
									module => $mex->module()
								);

	my $num_features = scalar(@img_features);
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