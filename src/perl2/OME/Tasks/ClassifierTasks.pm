# OME/Tasks/ClassifierTasks.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Tasks::ClassifierTasks;
use strict;
use OME;
use OME::Session;
use OME::Tasks::ModuleExecutionManager;
use OME::Tasks::ChainManager;

our $VERSION = $OME::VERSION;

=head1 NAME

OME::Tasks::ClassifierTasks

=head1 SYNOPSIS

	use OME::Tasks::ClassifierTasks;

=head1 DESCRIPTION

Most of the packages under OME::Tasks provide methods for a specific object 
type. e.g. ImageManager, PixelsManager, CategoryManager, etc.
This package is distinct in that is provides methods for a specific process:
classification. I used the suffix "Tasks" in the package name to distiguish
it from the rest of the packages in this directory. Hopefully this explanation 
will make life easier for whoever organizes the overall OME API.

This package is intended to provide a high level API that disguises the tricks
I'm doing to the data model and analysis system to get the classifier working.
This will allow me or anyone else to modify the analysis system or its data
model without disturbing classification clients.

This package will rely on certain modules and chains being in the system.
Roughly, those are outlined in OME/src/xml/README.Classifier
Before release, it would be handy to have methods for checking if those
chains and modules are installed, and install them if needed.
This package will also make assumptions on the structure of chains and
definitions of modules.

=head1 METHODS

=head2 getClassifierChain()

	my $classifierChain = OME::Tasks::ClassifierTasks->
		getClassifierChain( $classifier );
	my $classifierChain = OME::Tasks::ClassifierTasks->
		getClassifierChain( $trainerMEX );

Given a classifier object or module execution that produced a classifier,
this returns an optimized chain for running the classifier. It will first 
look for an existing chain. If the search fail, it will make a new one.
Note, if a new chain is constructed, you will have to commit the transaction
in order for the chain to be written to the DB.

=cut

sub getClassifierChain {
	my ($proto, $classifierOrMEX ) = @_;
	
	# Search for an existing one
	my $chain = $proto->findClassifierChain( $classifierOrMEX );
	return $chain if $chain;
	# Can't find one? Make a new one
	$chain = $proto->makeClassifierChain( $classifierOrMEX );
	return $chain;
}

=head2 findClassifierChain()

	my $classifierChain = OME::Tasks::ClassifierTasks->
		findClassifierChain($classifier);
	my $classifierChain = OME::Tasks::ClassifierTasks->
		findClassifierChain($trainerMEX);

Given a classifier object or module execution that produced one, looks for
an optimized chain for running the classifier. It will either return a chain
or undef.

=cut

sub findClassifierChain {
	my ($proto, $classifierOrMEX ) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my ( $classifier, $trainerMEX ) = $proto->
		__parseClassiferOrMEXInput( $classifierOrMEX );

	# Step 1: construct search parameters for retrieving existing chain
	# Step 2: search and return if found
	return undef;
}

=head2 makeClassifierChain()

	my $classifierChain = OME::Tasks::ClassifierTasks->
		makeClassifierChain($classifier);
	my $classifierChain = OME::Tasks::ClassifierTasks->
		makeClassifierChain($trainerMEX);

Given a classifier object or module execution that produced one, constructs
an optimized chain for running the classifier.

=cut

sub makeClassifierChain {
	my ($proto, $classifierOrMEX ) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my ( $classifier, $trainerMEX ) = $proto->
		__parseClassiferOrMEXInput( $classifierOrMEX );

	# Step 1: find trainer chain
	my $trainerChain = $factory->findObject( 'OME::AnalysisChain',
		'executions.node_executions.module_execution' => $trainerMEX,
		name => ['like', 'Trainer chain%' ])
		or die "Couldn't find a chain used to produce the trainer MEX ".$trainerMEX->id;

	# Step 2: clone and rename the chain
	my $classifierChain = OME::Tasks::ChainManager->
		cloneChain( $trainerChain );
	$classifierChain->name( 'Classifier chain '.$classifierChain->id );

	# Step 3: identify important nodes in new chain
	my $sigStitcherNode = $factory->findObject( 'OME::AnalysisChain::Node',
		analysis_chain => $classifierChain,
		'module.name'  => ['like', 'Signature Stitcher%' ]
	) or die "Couldn't find a Chain node to match chain ".$classifierChain->id.", module.name like 'Signature Stitcher%'";
	my $trainerNode = $factory->findObject( 'OME::AnalysisChain::Node',
		analysis_chain => $classifierChain,
		'module.name'  => ['like', 'BayesNet Trainer' ]
	) or die "Couldn't find a Chain node to match chain ".$classifierChain->id.", module.name 'BayesNet Trainer'";

	# Step 4: identify signatures to be saved
	my $sigsNeededList = OME::Tasks::ModuleExecutionManager->
		getAttributesForMEX( $trainerMEX, 'SignaturesUsed' )
		or die "Couldn't retrieve SignaturesUsed output from MEX ".
			   $trainerMEX->id;
# FIXME: (Explanation of Hack)
# When I commit the transaction at this point, I am able to delete Nodes
# and Links from the chain just fine. When I don't, I get the error:
# DBD::Pg::db commit failed: ERROR:  <unnamed> referential integrity violation - key referenced from analysis_chain_links not found in analysis_chain_nodes at OME/Factory.pm line 611, <STDIN> line 2.
# My best guess (which I haven't tested at all) is that the statements
# within the transactional block are committed out of order, so some deletes
# end up happening prior to the write. I don't know.
# For pragmatic reasons, I'll accept this work-around, but I do think it
# would be worthwhile to revisit this issue.
$session->commitTransaction();

	# Step 5: cut links into sigStitcher that aren't needed
	my @unneededSigLinks = $sigStitcherNode->input_links( 
		'to_input.name' => ['not in', [map( $_->Legend->FormalInput, @$sigsNeededList )] ]
	);
	$_->deleteObject() foreach @unneededSigLinks;

	# Step 6: remove nodes that do not have connected outputs. 
	#         do not remove the trainer module while doing this
	#         repeat until no nodes are removed
	my $num_nodes_removed = 0;
	do {
		my @nodes = $classifierChain->nodes();
		# I don't know how to encode the count_output_links criteria into
		# a factory search, so I'm using a grep for now. Less than optimal,
		# but it works, and won't be a bottleneck anytime soon.
		my @leaf_nodes_to_delete = grep( 
			(
				( $_->count_output_links() eq 0 ) && 
				( $_->module->id ne $trainerMEX->module->id ) 
			), @nodes 
		);
		$num_nodes_removed = scalar( @leaf_nodes_to_delete );
		foreach my $node_to_delete ( sort( @leaf_nodes_to_delete ) ) {
			# delete all input links, then delete the node
			my @links_to_delete = $node_to_delete->input_links;
			$_->deleteObject() foreach @links_to_delete;
			$node_to_delete->deleteObject();
		}
	} while $num_nodes_removed;

	# Step 7: replace the trainer with the classifier
	my $classifierModule = $factory->findObject( 'OME::Module',
		name => 'BayesNet Classifier'
	) or die "Couldn't find a module named 'BayesNet Classifier'";
	my $classifierNode = OME::Tasks::ChainManager->addNode(
		$classifierChain, $classifierModule );
	my $signatureLink = OME::Tasks::ChainManager->addLink(
		$classifierChain, $sigStitcherNode, 'SignatureVector', 
		                  $classifierNode,  'SignatureVectors' 
	);
	my @trainerLinks = $trainerNode->input_links();
	$_->deleteObject() foreach @trainerLinks;
	$trainerNode->deleteObject();

	# Step 8: save and return the chain.
	$classifierChain->storeObject();
	$session->commitTransaction();
	return $classifierChain;
}

=head2 _compileSignatureMatrix()

	my $signatureArray = OME::Tasks::ClassifierTasks->
		_compileSignatureMatrix($stitcher_mex, $images);

Returns a signature matrix suitable for classification (an
OME::Matlab::PersistentArray object) This signature matrix will not have
a category column.

Inputs:
	both $stitcher_mex and $images can be either arrays of objects or
	single objects.

=cut

sub _compileSignatureMatrix {
	my ($proto, $stitcher_mex, $images) = @_;
	my $factory = OME::Session->instance()->Factory();
	# deal with single object calling style
	$images = [ $images ] if ref( $images ) eq 'OME::Image';
	
	# instantiate the matlab signature array. 
	#	number of columns is the size of the signature vector
	#	number of rows is the number of images.
	my $vector_legends = OME::Tasks::ModuleExecutionManager->
		getAttributesForMEX( $stitcher_mex, "SignatureVectorLegend" )
		or die "Could not load signature vector legend for mex (id=".$stitcher_mex->id.")";
	my $signature_array = OME::Matlab::Array->newDoubleMatrix(scalar( @$vector_legends ), scalar( @$images ));
	$signature_array->makePersistent();
	
	# populate the signature matrix.
	my $image_number = 0;
	my $category_col_index = scalar( @$vector_legends );
	foreach my $image ( @$images ) {
		my $signature_entry_list = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX( $stitcher_mex, "SignatureVectorEntry",
				{ image => $image }
			)
			or die "Could not load image signature vector for image (id=".$image->id."), mex (id=".( ref( $stitcher_mex ) ne 'ARRAY' ? $stitcher_mex->id : join( ', ', map( $_->id, @$stitcher_mex ) ) ).")";
		# set the image's signature vector
		foreach my $sig_entry ( @$signature_entry_list ) {
			# VectorPosition is numbered 1 to n. Array positions should be 0 to (n-1).
			my $col_index = $sig_entry->Legend->VectorPosition() - 1;
			$signature_array->set( $col_index, $image_number, $sig_entry->Value() );
		}
		$image_number += 1;
	}	
	return $signature_array;
}

=head2 _compileSignatureMatrixWithCategories()

	my ($signature_array, $categoryMapping) = OME::Tasks::ClassifierTasks->
		_compileSignatureMatrixWithCategories($stitcher_mex, $images, $classification_mex);

Returns a signature matrix suitable for training (an
OME::Matlab::PersistentArray object). The last column of the signature
matrix will be the category IDs.
$categoryMapping is a reference to a hash of the form 
	{ ML_ID => DB_ID }
It maps the category ids presented to matlab to the database ids.

=cut

sub _compileSignatureMatrixWithCategories {
	my ($proto, $stitcher_mex, $images, $classification_mex) = @_;
	my $factory = OME::Session->instance()->Factory();
	
	# classifications is a hash that maps image ids to classification attributes
	# category_numbers is a hash that maps category ids to ids suited for the 
	# BayesNet. 
	my ( $classifications, $category_numbers ) = $proto->
		_getClassificationsAndCategoryNumbering( $images, $classification_mex);

	# instantiate the matlab signature array. 
	#	number of columns is the size of the signature vector plus one for the image classification.
	#	number of rows is the number of images.
	my $vector_legends = OME::Tasks::ModuleExecutionManager->
		getAttributesForMEX( $stitcher_mex, "SignatureVectorLegend" )
		or die "Could not load signature vector legend for mex (id=".$stitcher_mex->id.")";
	my $signature_array = OME::Matlab::Array->newDoubleMatrix(scalar( @$vector_legends ) + 1, scalar( @$images ));
	$signature_array->makePersistent();
	
	# populate the signature matrix.
	my $image_number = 0;
	my $category_col_index = scalar( @$vector_legends );
	foreach my $image ( @$images ) {
		my $signature_entry_list = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX( $stitcher_mex, "SignatureVectorEntry",
				{ image => $image }
			)
			or die "Could not load image signature vector for image (id=".$image->id."), mex (id=".( ref( $stitcher_mex ) ne 'ARRAY' ? $stitcher_mex->id : join( ', ', map( $_->id, @$stitcher_mex ) ) ).")";
		# set the image category
		my $category_num = $category_numbers->{ $classifications->{ $image->id }->Category->id };
		$signature_array->set( $category_col_index, $image_number, $category_num );
		# set the image's signature vector
		foreach my $sig_entry ( @$signature_entry_list ) {
			# VectorPosition is numbered 1 to n. Array positions should be 0 to (n-1).
			my $col_index = $sig_entry->Legend->VectorPosition() - 1;
			$signature_array->set( $col_index, $image_number, $sig_entry->Value() );
		}
		$image_number += 1;
	}
	# Reverse the category mapping from { DB_id => ML_id } to { ML_id => DB_id }
	my $categoryReverseMapping;
	$categoryReverseMapping->{ $category_numbers->{ $_ } } = $_
		foreach( keys %$category_numbers );
	return ( $signature_array, $categoryReverseMapping );
}


=head2 _getClassificationsAndCategoryNumbering()

	my ( $classifications, $category_numbers ) = $proto->
		_getClassificationsAndCategoryNumbering( $images, $classification_mex);


Checks inputs, Compiles classifications and constructs a Category
mapping. The BayesNet toolbox requires Categories to be numbered 1-n,
where n is the number of categories.

Inputs:
	images is a list of OME::Images
	classification_mex can be a mex or list of mexes. These mexes should have
produced mutually exclusive classifications under one category group for those images.

Outputs:
	classifications is a hash that maps image ids to classification attributes
	category_numbers is a hash that maps category ids to ids suited for the BayesNet. 

=cut

sub _getClassificationsAndCategoryNumbering {
	my ($proto, $images, $classification_mex) = @_;
	my $factory = OME::Session->instance()->Factory();
	my ( $classifications, $category_numbers );
	my $category_group;
	foreach my $image ( @$images ) {
		# If we were given a mex or list of mexes, then use it to find classifications
		my @classification_list = @{ OME::Tasks::ModuleExecutionManager->
				getAttributesForMEX( $classification_mex, "Classification",
					{image => $image } 
				) }
			or die "Could not find a classification for image id=".$image->id.
			       " using mexes: ". ( ref( $classification_mex ) eq 'ARRAY' ?
			           join( ', ', map( $_->id, @$classification_mex ) ) :
			           $classification_mex->id
			       );
		die "More than one classification found for image id=".$image->id.
		    ", mex id(s) ".(
		    	# $classification_mex may be a list of MEXs or a single MEX.
		    	# either print out the list of IDs or the single ID
		    	ref( $classification_mex ) eq 'ARRAY' ?
		    	'( '.join( ", ", map( $_->id, @$classification_mex ) ).' )' :
		    	$classification_mex->id
		    )
			unless scalar( @classification_list ) eq 1;
		$category_group = $classification_list[0]->Category->CategoryGroup
			unless $category_group;
		die "Classification for image id=".$image->id." does not belong to the same category group as other images in this dataset."
			unless $category_group->id eq $classification_list[0]->Category->CategoryGroup->id;
		$classifications->{ $image->id } = $classification_list[0];
	}
	# map categories to category numbers
	my @categories = $factory->findAttributes( "Category", CategoryGroup => $category_group );
	my $cn = 0;
	foreach( sort { $a->Name cmp $b->Name } @categories ) { 
		$cn++;
		$category_numbers->{ $_->id } = $cn;
	}
	return ($classifications, $category_numbers );
}

sub __parseClassiferOrMEXInput {
	my ($proto, $classifierOrMEX ) = @_;

	my ( $classifier, $trainerMEX );
	if( ref( $classifierOrMEX ) eq 'OME::ModuleExecution' ) {
		$trainerMEX = $classifierOrMEX;
		my $classifier_list = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX( $trainerMEX, 'BayesNetClassifier' )
			or die "Couldn't retrieve BayesNetClassifier output from MEX ".
			       $trainerMEX->id;
		$classifier = $classifier_list->[0];
	} elsif( $classifierOrMEX->verifyType( 'BayesNetClassifier' ) ) {
		$classifier = $classifierOrMEX;
		$trainerMEX = $classifier->module_execution;
	}
	return ( $classifier, $trainerMEX );
}

=head1 AUTHOR

Josiah Johnston <siah@nih.gov>

=cut

1;

