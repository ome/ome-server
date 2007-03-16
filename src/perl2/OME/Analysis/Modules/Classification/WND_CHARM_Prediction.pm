# OME/Analysis/Modules/Classification/WND_CHARM_Prediction.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#
# Written by:	Tom Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------

=head1 NAME

OME::Analysis::Modules::Classification::WND_CHARM_Prediction - Merge
image features into a feature vector. Analyze the feature_vector
using a trained classifier in order to create an image classification.

=cut

package OME::Analysis::Modules::Classification::WND_CHARM_Prediction;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Log::Agent;
use OME::Matlab;
use OME::Image::Server;
use OME::Tasks::ImageManager;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);

sub startAnalysis {
	my ($self,$module_execution) = @_;
	my $factory = OME::Session->instance()->Factory();
	my $environment = OME::Install::Environment->initialize();

	my $mex = $self->getModuleExecution();
	my $module = $mex->module();
	
	# open MATLAB connection
	logdbg "debug", "Open MATLAB connection";
	my $engine = OME::Matlab::Engine->openEngine()
		or die "Cannot open a connection to Matlab! as user ".$environment->matlab_conf()->{USER};
	
	##############################################################################
	# read the the ImageClassifier from OMEIS and write to temporary file on disk
	# then load temporary file into MATLAB space.
	##############################################################################
	logdbg "debug", "Load Trained Classifier Object";
	my $trainedClassifierFI = $factory->findObject('OME::Module::FormalInput',{
													module => $module,
													'semantic_type.name' => "WND_CHARM_TrainedClassifier",
												   }) or die "couldn`t load TrainedClassifer FI";
												   
	my @input_attr_list = $self->getInputAttributes( $trainedClassifierFI )
		or die "Couldn't get inputs for WND_CHARM_TrainedClassifier FormalInput";
	
	my $trainedClassifierOriginalFile = $input_attr_list[0]->ClassifierObject();
	my $data = OME::Image::Server->readFile($trainedClassifierOriginalFile->Repository(),
											$trainedClassifierOriginalFile->FileID());

	my $filename = OME::Session->instance()->getTemporaryFilename("WND_TrainedClassifier","mat");
	open (MAT_FILE, ">$filename") || die ("Couldn't open MATLAB temporary file ($filename) for writing");
	print MAT_FILE $data;
	close (MAT_FILE);
	$engine->eval("load $filename");
	OME::Session->instance()->finishTemporaryFile($filename);
	
	##############################################################################
	# create LUT mapping InternalClassifierCategoryName to Category
	##############################################################################
	logdbg "debug", "create LUT mapping InternalClassifierCategoryName to Category";
	my $categoriesUsedFI = $factory->findObject('OME::Module::FormalInput',{
												module => $module,
												'semantic_type.name' => "CategoriesUsed",
											   }) or die "couldn`t load CategoriesUsed FI";
											   
	@input_attr_list = $self->getInputAttributes( $categoriesUsedFI )
		or die "Couldn't get inputs for CategoriesUsed FormalInput";
	my %categoriesUsedLUT;
	foreach (@input_attr_list) {
		$categoriesUsedLUT{$_->InternalClassifierCategoryName()} = $_->Category();
	}

	##############################################################################
	# Analyze Formal Inputs 
	##############################################################################
	logdbg "debug", "analyzing formal inputs to speed up image feature vector computations";

	# skip TrainedClassifier and Categories Used FI
	my @formal_inputs = $factory->findObjects('OME::Module::FormalInput',{
												module => $module,
												'semantic_type.name' => [ '!=', "WND_CHARM_TrainedClassifier"],
												'semantic_type.name' => [ '!=', "CategoriesUsed"],
											});
	@formal_inputs = sort { $a->name cmp $b->name } @formal_inputs;
	
	my %FI_id_to_se_names;
	my $feature_vector_length = 0;
	foreach my $formal_input (@formal_inputs) {
		my @SEs = $formal_input->semantic_type->semantic_elements();
		@SEs = sort { $a->name cmp $b->name } @SEs;
	
		my @se_names;
		foreach my $se ( @SEs ) {
			# is SE of an appropriate type i.e a double
			next if $se->data_column()->sql_type() eq 'string';
			next if $se->data_column()->sql_type() eq 'reference';
			push (@se_names, $se->name());
			$feature_vector_length++;
		}

		$FI_id_to_se_names{$formal_input->id} = \@se_names;
	}

	$self->{engine} = $engine;
	$self->{categoriesUsedLUT} = \%categoriesUsedLUT;
	$self->{formal_inputs} = \@formal_inputs;
	$self->{FI_id_to_se_names} = \%FI_id_to_se_names;
	$self->{feature_vector_length} = $feature_vector_length;
}

sub startImage {
	my ($self,$image) = @_;
	$self->SUPER::startImage($image);

	my $factory = OME::Session->instance()->Factory();
	my $engine = $self->{engine};
	my $mex = $self->getModuleExecution();
	my $module = $mex->module();

	##############################################################################################################
	# Build the Image Feature Vector, in the process seperate out the TrainedClassifier and CategoriesUsed inputs
	##############################################################################################################

	# prepare for the Signature Vector Entry outputs;
	logdbg "debug", "Writing Image Feature Vector for Image: ".$image->name();
	my $feature_vector = OME::Matlab::Array->newDoubleMatrix($self->{feature_vector_length}, 1);
	$feature_vector->makePersistent();

	my @formal_inputs;
	@formal_inputs = @{$self->{formal_inputs}};	
	my %FI_id_to_se_names = %{$self->{FI_id_to_se_names}};

	my $sig_row=0;
	foreach my $formal_input ( @formal_inputs ) {
		# Collect the actual inputs for this image
		my @input_attr_list = $self->getCurrentInputAttributes($formal_input)
		  or logdbg "debug", "Couldn't get inputs for formal input '".$formal_input->name."', (id=".$formal_input->id.")!";		  
		my $attribute = $input_attr_list[0];

		my @se_names;
		@se_names = @{$FI_id_to_se_names{$formal_input->id}};
		foreach my $se_name ( @se_names ) {
			$feature_vector->set($sig_row++, 0, $attribute->$se_name);	
		}
	}
	
	# instantiate the MATLAB image feature vector
	$engine->eval("global feature_vector");
	$engine->putVariable('feature_vector',$feature_vector);
	
	############################################################################
	# Run WND_CHARM Predict
	############################################################################
	logdbg "debug", "Run WND_Predict";
	$engine->eval(" [marginal_probabilities, class_predictions, class_similarities] = ".
				  "WND_Predict( feature_vector, norm_train_matrix, features_used, feature_scores, feature_min, feature_max) ;");
	
	############################################################################
	# Convert class_prediction into an OME classification using the CategoriesUsed ST
	############################################################################
	logdbg "debug", "Use output from WND_Predict to make a new image classification";
	my $class_prediction = $engine->getVariable('class_predictions')->getScalar()
		or die "couldn't load class_predictions variable";

	$factory->newAttribute("Classification", $image, $mex,
		{
			'Category' => $self->{categoriesUsedLUT}->{$class_prediction},
			'Confidence' => '1',
			'Valid' => '1',
		});
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>

=cut
