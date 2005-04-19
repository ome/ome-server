# OME/Analysis/Modules/Classification/ML_BayesNet_Trainer.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institue of Technology,
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
# Written by:  Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Analysis::Modules::Classification::ML_BayesNet_Trainer;

=head1 NAME

OME::Analysis::Modules::Classification::ML_BayesNet_Trainer - analysis module for
training a Baysian network

=head1 SYNOPSIS

	use OME::Analysis::Modules::Classification::ML_BayesNet_Trainer;

=head1 DESCRIPTION

This implements a non-standard interface to a matlab function that
trains a baysian network from a signature matrix. 
See OME/src/xml/OME/Analysis/Classifier/Trainer.ome for the module definition.

=cut

use strict;

use OME;
our $VERSION = $OME::VERSION;

use Log::Agent;
use Carp;
use OME::Matlab;
use OME::Tasks::ClassifierTasks;
use OME::Image::Server::File;

use base qw(OME::Analysis::Handler);
use Time::HiRes qw(gettimeofday tv_interval);

sub execute {
    my ($self,$dependence,$target) = @_;
	my $mex = $self->getModuleExecution();
	my $dataset = $target; # target should always be a dataset
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $outBuffer  = " " x 2048;
	
	# open connection to matlab
	my $matlab_engine = OME::Matlab::Engine->open("matlab -nodisplay -nojvm")
		or die "Cannot open a connection to Matlab!";
	my $conf = $session->Configuration() or croak "couldn't retrieve Configuration variables";
	my $matlab_src_dir = $conf->matlab_src_dir or croak "couldn't retrieve matlab src dir from configuration";
	logdbg "debug", "Matlab src dir is $matlab_src_dir\n".
	$matlab_engine->eval("addpath(genpath('$matlab_src_dir'));");

	my $start_time = [gettimeofday()];
	my @images = $dataset->images( );
	@images = sort {$a->id <=> $b->id} @images;
	
	# Compile Signature matrix and place into matlab for input
    my @classification_mexes = map { $_->input_module_execution() } @{ 
    	$self->getActualInputs( 'Classifications' ) };
    my @sigVectors_mexes = map { $_->input_module_execution() } @{ 
    	$self->getActualInputs( 'Signature Vectors' ) };
	my $signature_matrix = OME::Tasks::ClassifierTasks->
		_compileSignatureMatrixWithCategories( \@sigVectors_mexes, \@images, \@classification_mexes );
	$matlab_engine->eval("global signature_matrix");
	$matlab_engine->putVariable( "signature_matrix", $signature_matrix);
	$mex->attribute_db_time(tv_interval($start_time));
	
	# Execute the trainer
	$matlab_engine->setOutputBuffer($outBuffer, length($outBuffer));	
	$matlab_engine->eval( 
		"[sigs_used, sigs_used_ind, sigs_used_col, sigs_excluded, discWalls, bnet, conf_mat] = ".
		"	ML_BayesNet_Trainer(signature_matrix);"
	);
	$outBuffer =~ s/(\0.*)$//;
	if ($outBuffer =~ m/\S/) {
		$mex->error_message("$outBuffer");
		die "***** Error! Output from Matlab:\n$outBuffer\n";		
	}

	# ------ STORE OUTPUTS ------ #

	# Store the discritization walls & classifier
	# For now, dump them to a file, upload that to the image server, 
	# 	and make a BayesNetClassifier output
	my $classifier_dump_path = $session->getTemporaryFilename('ML_BayesNet_Trainer','mat');
	$outBuffer  = " " x 2048;
	$matlab_engine->setOutputBuffer($outBuffer, length($outBuffer));	
	$matlab_engine->eval( "save $classifier_dump_path discWalls bnet;" );
	$outBuffer =~ s/(\0.*)$//;
	if ($outBuffer =~ m/\S/) {
		$mex->error_message("$outBuffer");
		die "***** Error! Output from Matlab:\n$outBuffer\n";		
	}
	my $classifier_dump_file_obj = OME::Image::Server::File->upload($classifier_dump_path);
	$self->newAttributes('Classifier', {
		dataset => $dataset,
		FileID => $classifier_dump_file_obj->getFileID() 
	} );
	$session->finishTemporaryFile( $classifier_dump_path );
	
	# Store the signatures used and their scores
	my $sigs_used_ml = $matlab_engine->getVariable( 'sigs_used' );
	my $sigs_used_list = $sigs_used_ml->convertToList();
	my $sigs_cum_scores_ml = $matlab_engine->getVariable( 'sigs_used_col' );
	my $sigs_cum_scores = $sigs_cum_scores_ml->convertToList();
	my $sigs_ind_scores_ml = $matlab_engine->getVariable( 'sigs_used_ind' );
	my $sigs_ind_scores = $sigs_ind_scores_ml->convertToList();
	# These arrays are ordered by the first sig selected, 
	# the second sig selected, and so on. This is stored in $i
	# and will be permanently stored in SignaturesScores.Index
	for my $i ( 0..( @$sigs_used_list - 1 ) ) {
		my $sig_index = $sigs_used_list->[ $i ];
		my $sig_cum_score = $sigs_cum_scores->[ $i ];
		my $sig_ind_score = $sigs_ind_scores->[ $i ];
		my $vectorLegendList = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX(\@sigVectors_mexes, 'SignatureVectorLegend', {
				VectorPosition   => $sig_index,			
			} )
			or die "Could not find a Vector Legend for one of the signatures used (index=$sig_index)";
		die "Found ".@$vectorLegendList." Vector Legends matching signature used index $sig_index. Expected to find 1."
			unless @$vectorLegendList == 1;
		my $vectorLegend = $vectorLegendList->[0];
		$self->newAttributes('Signatures Used', {
			dataset => $dataset,
			Legend => $vectorLegend
		} );
		$self->newAttributes('Signatures Scores', {
			dataset  => $dataset,
			Legend   => $vectorLegend,
			Rank     => $i,
			CumScore => $sig_cum_score,
			IndScore => $sig_ind_score
		} );
	}
	
	# Store SignaturesExcluded
	my $sigs_excluded_ml = $matlab_engine->getVariable( 'sigs_excluded' );
	my $sigs_excluded_list = $sigs_excluded_ml->convertToList();
	foreach my $sig_index ( @$sigs_excluded_list ) {
		my $vectorLegendList = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX(@sigVectors_mexes, 'SignatureVectorLegend', {
				VectorPosition   => $sig_index,			
			} )
			or die "Could not find a Vector Legend for one of the signatures excluded (index=$sig_index)";
		die "Found ".@$vectorLegendList." Vector Legends matching signature excluded index $sig_index. Expected to find 1."
			unless @$vectorLegendList == 1;
		my $vectorLegend = $vectorLegendList->[0];
		$self->newAttributes('Signatures Not Discretized', {
			dataset => $dataset,
			Legend => $vectorLegend
		} );
	}

	# Make CategoriesUsed
	my @classifications = $self->getInputAttributes( 'Classifications' );
	my %categories_used = map{ $_->Category->id => $_->Category } @classifications;
	foreach my $category ( values %categories_used ) {
		$self->newAttributes('Categories Used', {
			dataset => $dataset,
			Category => $category
		} );		
	}

	# Store Confusion Matrix
	my $confusion_matrix_ml = $matlab_engine->getVariable( 'conf_mat' );
	# getAll() returns a flat list. I know a priori that this matrix is square,
	# and its width is the number of categories. The list goes from top to 
	# bottom, left to right. Rows are StandardCategory, Cols are 
	my $confusion_matrix_values = $confusion_matrix_ml->getAll();
	my $confusion_matrix_width = scalar( keys( %categories_used ) );
	die "Confusion matrix is of unexpected size"
		unless scalar( @$confusion_matrix_values ) eq ( $confusion_matrix_width * $confusion_matrix_width );
	# make a 2d matrix. while making it, sum the rows.
	my @confusion_matrix;
	my @confusion_matrix_row_sums;
	my $col_index = 0;
	my $row_index = 0;
	my $total_num_predictions = 0;
	my $correct_predictions = 0;
	foreach my $value ( @$confusion_matrix_values ) {
		if( $row_index == $confusion_matrix_width ) {
			$row_index = 0;
			$col_index++;
		}
		$confusion_matrix[ $row_index ][ $col_index ] = $value;
		$confusion_matrix_row_sums[ $row_index ] += $value;
		$total_num_predictions += $value;
		$correct_predictions += $value
			if $row_index eq $col_index;
		$row_index++;
	}
	# Store the ConfusionMatrix container
	my $confusion_matrix_attr_list = $self->newAttributes( 'Confusion Matrix', {
		dataset             => $dataset,
		Accuracy            => ( $correct_predictions / $total_num_predictions ),
		TotalNumPredictions => $total_num_predictions,
		TotalUnknown        => ($dataset->count_images() - $total_num_predictions)
	} );
	my $confusion_matrix_attr = $confusion_matrix_attr_list->[0];
	# Store each entry of the matrix
	foreach my $row ( 0..( $confusion_matrix_width - 1 ) ) {
		foreach my $col( 0..( $confusion_matrix_width - 1 ) ) {
			$self->newAttributes( 'ConfusionMatrixEntries', {
				dataset             => $dataset,
				StandardCategory    => ($row + 1),
				AlternativeCategory => ($col + 1),
				ConfusionMatrix     => $confusion_matrix_attr,
				NumPredictions      => $confusion_matrix[ $row ][ $col ],
				NormalizedNumPredictions => ( $confusion_matrix[ $row ][ $col ] / $confusion_matrix_row_sums[ $row ] ),
			} );
		}
	}
	
	# close connection to matlab
	$matlab_engine->close();

	$mex->storeObject();
}


=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=head1 SEE ALSO

L<OME::Matlab>, L<OME::Matlab::Engine>, L<OME::Analysis::Handlers::Matlab>
L<http://www.openmicroscopy.org/XMLschemas/MLI/IR2/MLI.xsd|specification of XML instructions>

=cut


1;
