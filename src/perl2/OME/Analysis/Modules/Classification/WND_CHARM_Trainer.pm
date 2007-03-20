# OME/Analysis/Modules/Classification/WND_CHARM_Trainer.pm

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

OME::Analysis::Modules::Classification::WND_CHARM_Trainer - Merge
image features into a feature matrix for use with the WND_CHARM_Classifier 

=cut

package OME::Analysis::Modules::Classification::WND_CHARM_Trainer;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Log::Agent;
use OME::Matlab;
use OME::Image::Server;
use OME::Image::Server::File;
use OME::Tasks::ImageManager;

use base qw(OME::Analysis::Handler);

sub execute {
	my ($self,$dependence,$target) = @_;
	my $factory = OME::Session->instance()->Factory();
	my $environment = OME::Install::Environment->initialize();

	my $start_timestamp = time;
	my $start_timestr = localtime $start_timestamp;

	my $mex = $self->getModuleExecution();
	my $module = $mex->module();
	
	
	# open MATLAB connection
	my $engine = OME::Matlab::Engine->openEngine()
		or die "Cannot open a connection to Matlab! as user ".$environment->matlab_conf()->{USER};
	#
	# Build the Feature Vector Legend
	#
	logdbg "debug", "Creating ImageFeaturesLegend (Perl)";
	my @formal_inputs = $factory->findObjects('OME::Module::FormalInput', { module => $module });
	@formal_inputs = sort { $a->name cmp $b->name } @formal_inputs;
	
	# Image Features Legend (MATLAB)
	my @signature_labels;

	# Image Features Legend (OME)
	my @FeatureDescription;
	my @FeatureIndex;
	my @Used;
	my @Target;
	my %ImageFeaturesLegend = (
			FeatureDescription => \@FeatureDescription,
			FeatureIndex => \@FeatureIndex,
			Used => \@Used,
			Target => \@Target);

	my $num_of_features = 0;
	my $num_of_ROIs = 0;

	foreach my $formal_input ( @formal_inputs ) {
		# this should only be called once
		if (not $num_of_ROIs) {
			my @input_attr_list = $self->getInputAttributes( $formal_input )
			  or logdbg "debug", "Couldn't get inputs for formal input '".$formal_input->name."', (id=".$formal_input->id.")!";
			$num_of_ROIs = scalar (@input_attr_list);
		}
		
		my @SEs = $formal_input->semantic_type->semantic_elements();
		@SEs = sort { $a->name cmp $b->name } @SEs;
		
		foreach my $se ( @SEs ) {
			# is SE of an appropriate type i.e a double
			next if $se->data_column()->sql_type() eq 'string';
			next if $se->data_column()->sql_type() eq 'reference';

			$num_of_features++;
			
			# Define a new vector position.
			push (@FeatureDescription, $formal_input->name().".".$se->name());
			push (@FeatureIndex, $num_of_features);
			push (@Used, "1");
			push (@Target, $target->id());
			
			push (@signature_labels, $formal_input->name().".".$se->name());
		}
	}
	
	logdbg "debug", "Writing ImageFeaturesLegend";
	my $ImageFeaturesLegendST = $factory->findObject("OME::SemanticType", name => 'ImageFeaturesLegend')
		or die "Couldn't find ST ImageFeaturesLegend";
	$factory->newObjectsNitrox ($ImageFeaturesLegendST, $mex, \%ImageFeaturesLegend)
		or die "Couldn't make ImageFeaturesLegend";

	# Writing Image Features Legend (MATLAB)
	my $signature_labels_array = OME::Matlab::Array->newStringArray(\@signature_labels);
	$signature_labels_array->makePersistent();
	
	# make an array of image_paths/feature names
	# img_path [feature name]
	# img_path [feature name]
	# ...
	logdbg "debug", "Making an array of image_paths/feature names";
	
	my $formal_input = $formal_inputs[0];
	my @input_attr_list = $self->getInputAttributes( $formal_input )
		  or logdbg "debug", "Couldn't get inputs for formal input '".$formal_input->name."', (id=".$formal_input->id.")!";
		  
	my @features = map($_->target(), @input_attr_list);
	my @image_feature_paths; # this is a 'path' to the image feature
	
	foreach my $feature (@features) {
		my $originalFile = OME::Tasks::ImageManager->getImageOriginalFiles($feature->image());
		die "Image ".$feature->image()->name." doesn't have exactly one Original File"
			if( ref( $originalFile ) eq 'ARRAY' );

		push @image_feature_paths, $originalFile->Path()." [".$feature->name()."]";
	}
	
	# sort images by image_path not image name to match MATLAB sort order
	# so /CHO/tumor.tiff will be before /Pollen/obj_198_1.tiff
	my @image_feature_path_indices = sort{$image_feature_paths[$a] cmp $image_feature_paths[$b]}0..$#image_feature_paths;
	@image_feature_paths = @image_feature_paths[@image_feature_path_indices];
	@features = @features[@image_feature_path_indices];

	# write image_feature_paths to MATLAB
	my $image_paths_array = OME::Matlab::Array->newStringArray(\@image_feature_paths);
	$image_paths_array->makePersistent();
	
	# create a LUT mapping Features to Matrix Columns
	logdbg "debug", "Creating LUT that maps Features to Matrix Column";
	my %features_to_matrix_column;
	my $i=0;
	foreach (@features) {
		$features_to_matrix_column{$_->id()} = $i++;
	}
	
	############################################################################
	# Build Categories Used
	############################################################################
	
	# figure out the mappings from images to OME categories
	# and OME categories to 
	my %image_to_OME_category;
	my %OME_category_to_category_number;
	my @category_names;
	foreach (@input_attr_list) {
		my $img = $_->target()->image();
		my @classification_list = $factory->findAttributes( 'Classification', image => $img );
		
		if( scalar( @classification_list ) == 0 ) {
			die "Could not find a classification for image ".$img->name()." (".$img->id.")";
		}
		die "More than one classification found for image id=".$img->id
			unless scalar( @classification_list ) eq 1;
		my $category_group = $classification_list[0]->Category->CategoryGroup();
		die "Classification for image id=".$img->id." does not belong to the same category group as other images in this dataset."
			unless $category_group->id eq $classification_list[0]->Category->CategoryGroup->id;
		
		# record the classifcation
		my $cat_id = $classification_list[0]->Category->id();
		$image_to_OME_category{ $img->id } = $cat_id;
		$OME_category_to_category_number{$cat_id} = undef;
		
		push (@category_names, $classification_list[0]->Category->Name());
	}
	
	# write categories_used_to_MATLAB
	my $category_names_array = OME::Matlab::Array->newStringArray(\@category_names);
	$category_names_array->makePersistent();
	
	# write categories_used to OME
	$i=1;
	foreach my $cat_id (keys %OME_category_to_category_number) {
		$OME_category_to_category_number{$cat_id} = $i++;

		$factory->newAttribute("CategoriesUsed", $target, $mex,
			{
				'Category' => $cat_id,
				'CategoryIndex' => $OME_category_to_category_number{$cat_id},
			});
	}
	
	############################################################################
	# Do the MATLAB Signature Array
	############################################################################
	
	# instantiate the matlab signature array. 
	#	number of rows is the size of the signature vector plus one for the image classification.
	#	number of columns is the number of image ROIs
	my $signature_array = OME::Matlab::Array->newDoubleMatrix($num_of_features + 1, $num_of_ROIs);
	$signature_array->makePersistent();
	
	# prepare for the Signature Vector Entry outputs;
	logdbg "debug", "	Writing Image Features into a Matrix";
	my $sig_row=0;
	foreach my $formal_input ( @formal_inputs ) {
		logdbg "debug", "Writing ".$formal_input->name()." Image Features";
		
		# Collect the actual inputs for all the images
		my @input_attr_list = $self->getInputAttributes( $formal_input )
		  or logdbg "debug", "Couldn't get inputs for formal input '".$formal_input->name."', (id=".$formal_input->id.")!";
		
		# Every semantic element gets an entry in the vector
		my @SEs = $formal_input->semantic_type->semantic_elements();
		@SEs = sort { $a->name cmp $b->name } @SEs;

		foreach my $se ( @SEs ) {
			# is SE of an appropriate type i.e a double
			next if $se->data_column()->sql_type() eq 'string';
			next if $se->data_column()->sql_type() eq 'reference';
			my $se_name = $se->name();
			
			foreach my $attribute (@input_attr_list) {
				$signature_array->set($sig_row, $features_to_matrix_column{$attribute->target->id()}, $attribute->$se_name);
			}
			$sig_row++;
		}
	}

	logdbg "debug", "	Writing the Image Classifications Row";
	foreach my $feature (@features) {

		my $ome_category = $image_to_OME_category{$feature->image()->id()};
		$signature_array->set($num_of_features,
							  $features_to_matrix_column{$feature->id()},
							  $OME_category_to_category_number{$ome_category});
	}

	############################################################################
	# Writing the MATLAB file
	############################################################################
	logdbg "debug", "	Writing the MATLAB Classifier State File";
	$engine->eval("global category_names_char_array");
	$engine->putVariable('category_names_char_array',$category_names_array);
	# Convert the rectangualar string array that has null terminated strings into a cell array.
	# Cell arrays are easier to deal with for strings.
	$engine->eval( "category_names=''; ".
				   "for i=1:size( category_names_char_array, 1 ),".
	               "category_names{i} = sprintf( '%s', category_names_char_array(i,:) ); ".
	               "end;" );
	               
	$engine->eval("global signature_labels_char_array");
	$engine->putVariable('signature_labels_char_array',$signature_labels_array);
	$engine->eval( "for i=1:size( signature_labels_char_array, 1 ),".
	               "signature_labels{i} = sprintf( '%s', signature_labels_char_array(i,:) ); ".
	               "end;" );

	$engine->eval("global image_paths_char_array");
	$engine->putVariable('image_paths_char_array',$image_paths_array);
	$engine->eval( "for i=1:size( image_paths_char_array, 1 ),".
	               "image_paths{i} = sprintf( '%s', image_paths_char_array(i,:) ); ".
	               "end;" );

	$engine->eval("global signature_matrix");
	$engine->putVariable('signature_matrix',$signature_array);

	$engine->eval( "dataset_name = '".$mex->dataset->name()."';" );
	
	# take the signature matrix and do the "training step"	
	logdbg "debug", "	Doing WND_Train";
	$engine->eval("[features_used, feature_scores, norm_train_matrix, feature_min, feature_max] = WND_Train(signature_matrix);");

	# Storing the MATLAB file on OMEIS

	my $filename = OME::Session->instance()->getTemporaryFilename("WND_TrainedClassifier","mat");
	$engine->eval( "save $filename dataset_name category_names signature_labels signature_matrix image_paths ".
				   "features_used feature_scores norm_train_matrix feature_min feature_max;" );
	logdbg "debug", "Saved signature matrix to file $filename.";
	$engine->close();
	$engine = undef;

	logdbg "debug", "Putting the MATLAB File to OME/OMEIS";
	
	my $file = OME::Image::Server::File->upload($filename)
			or die "Couldn't upload $filename to server";
			
	OME::Session->instance()->finishTemporaryFile($filename);
	my $originalFile = $factory->
	  newAttribute("OriginalFile",undef,$mex,
				   {SHA1 => $file->getSHA1(), 
					Path => $filename, 
					FileID => $file->getFileID(), 
					Format => 'MATLAB MAT',
					Repository => OME::Session->instance()->findRepository()
				   });
					   
	$factory->newAttribute("WND_CHARM_TrainedClassifier", $target, $mex,
		{
			'Parent' => $originalFile,
		});
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>

=cut
