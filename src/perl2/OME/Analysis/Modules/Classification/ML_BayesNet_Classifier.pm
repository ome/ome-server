# OME/Analysis/Modules/Classification/ML_BayesNet_Classifier.pm

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


package OME::Analysis::Modules::Classification::ML_BayesNet_Classifier;

=head1 NAME

OME::Analysis::Modules::Classification::ML_BayesNet_Classifier - analysis module for
classifying with a Baysian network

=head1 SYNOPSIS

	use OME::Analysis::Modules::Classification::ML_BayesNet_Classifier;

=head1 DESCRIPTION

This implements a non-standard interface to a matlab function that
uses a baysian network and a signature matrix to classify images.
See OME/src/xml/OME/Analysis/Classifier/BayesNetClassifier.ome for the module definition.

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
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $outBuffer  = " " x 2048;
	my $start_time = [gettimeofday()];

	# open connection to matlab
	my $matlab_engine = OME::Matlab::Engine->open("matlab -nodisplay -nojvm")
		or die "Cannot open a connection to Matlab!";
	my $conf = $session->Configuration() or croak "couldn't retrieve Configuration variables";
	my $matlab_src_dir = $conf->matlab_src_dir or croak "couldn't retrieve matlab src dir from configuration";
	logdbg "debug", "Matlab src dir is $matlab_src_dir\n".
	$matlab_engine->eval("addpath(genpath('$matlab_src_dir'));");

	# Target may be a dataset or an image. Ideally, this module will be 
	# executed once per image. Anyway, stuff into an array to make code
	# easier later.
	my @images;
	if( ref( $target ) eq 'OME::Dataset' ) {
		@images = $target->images;
	} else {
		@images = [ $target ];
	}
	
	# Load Classifier & discritezation walls. These were dumped to a matlab
	# file and uploaded to the file repository. The file has two variables:
	# bnet and discWalls.
	my $classifier = $self->getInputAttributes( "Classifier" );
	$classifier = $classifier->[0];
	my $classifier_dump_file = OME::Image::Server::File->new( $classifier->FileID() );
	my $classifier_dump_path = $session->getTemporaryFilename('ML_BayesNet_Classifier','mat');
	open my $file_handle, ">", $classifier_dump_path 
		or die "Could not open $classifier_dump_path";
	print $file_handle $classifier_dump_file->readData( $classifier_dump_file->getLength() );
	close $file_handle;
	$outBuffer  = " " x 2048;
	$matlab_engine->setOutputBuffer($outBuffer, length($outBuffer));	
	$matlab_engine->eval("load '$classifier_dump_path'");
	$outBuffer =~ s/(\0.*)$//;
	if ($outBuffer =~ m/\S/) {
		$mex->error_message("$outBuffer");
		die "***** Error! loading BayesNet classifier (id=".$classifier->id.
		    "). Error msg:\n$outBuffer";
	}
	$session->finishTemporaryFile( $classifier_dump_path );
	
	# Signatures Used: They come out of the trainer in an ordered array
	# The order of the array is important; basically, the indexes of the
	# array specifies a BayesNet node.
	# ATM, this order is not stored in SignaturesUsed, but does make its
	# way into SignaturesScores (another output of the Trainer module)
	my @sigsUsedAttrs = $self->getInputAttributes( "SignaturesUsed" );
	my @orderedSigsUsed;
	foreach my $sigUsed ( @sigsUsedAttrs ) {
		my $score = OME::Tasks::ModuleExecutionManager->
			getAttributesForMEX( $sigUsed->module_execution, 'SignaturesScores',
				{ Legend => $sigUsed->Legend } )
			or die "Couldn't retrieve SignaturesScores output from MEX ".
				   $sigUsed->module_execution->id;
		$score = $score->[0];
		$orderedSigsUsed[ $score->Rank() ] = $sigUsed->Legend->VectorPosition;
	}
	# make matlab variable 'sigs_used' from @orderedSigsUsed
	my $mlOrderedSigsUsed = OME::Matlab::Array->
		newNumericArray( $OME::Matlab::mxDOUBLE_CLASS, $OME::Matlab::mxREAL, 1, scalar(@orderedSigsUsed) )
		or die "Coulnd't make matlab array to store the signatures used";
	$mlOrderedSigsUsed->setAll( \@orderedSigsUsed );
	$mlOrderedSigsUsed->makePersistent();
	$matlab_engine->eval("global sigs_used");
	$matlab_engine->putVariable( "sigs_used", $mlOrderedSigsUsed);
	
	# Load the basis for retrieving signatures
	my @sigVectors_mexes = map { $_->input_module_execution() } @{ 
		$self->getActualInputs( 'SignatureVectors' ) };

	# Build up Categories. Order them to correspond to the order used
	# by the Trainer. The indexes will then provide a mapping from the
	# category numbers used by the BayesNet and the categories objects
	# in OME.
	my @categoriesUsed = $self->getInputAttributes( "CategoriesUsed" );
	my @categories = sort { $a->Name cmp $b->Name } map( $_->Category, @categoriesUsed );

	foreach my $image( @images ) {
		# Compile Signature matrix and place into matlab for input
		my $signature_matrix = OME::Tasks::ClassifierTasks->
			_compileSignatureMatrix( \@sigVectors_mexes, $image );
		$matlab_engine->eval("global contData");
		$matlab_engine->putVariable( "contData", $signature_matrix);
		# Execute the classifier
#print STDERR "trying to get a signature matrix for image ".$image->name."\n";
#print STDERR "from signature vector mexes ".join( ', ', map( $_->id, @sigVectors_mexes ))."\n";
#$matlab_engine->eval( "save classifier_inputs.mat bnet contData sigs_used discWalls" );
		$outBuffer  = " " x 2048;
		$matlab_engine->setOutputBuffer($outBuffer, length($outBuffer));	
		$matlab_engine->eval( 
			"[marginal_probs] = ".
			"	ML_BayesNet_Classifier(bnet, contData(sigs_used), sigs_used, discWalls);"
		);
		$outBuffer =~ s/(\0.*)$//;
		if ($outBuffer =~ m/\S/) {
			$mex->error_message("$outBuffer");
			die "***** Error! Output from Matlab:\n$outBuffer\n";
		}

		# Store the marginal probabilities
		my $marginalProbsML = $matlab_engine->getVariable( 'marginal_probs' )
			or die "couldn't retrieve classifier output";
		my $marginalProbs = $marginalProbsML->convertToList();
		for my $i ( 0..( @$marginalProbs - 1 ) ) {
			my $category = $categories[ $i ];
			my $probability = $marginalProbs->[ $i ];
			$self->newAttributes('Classification', {
				image      => $image,
				Category   => $category,
				Confidence => $probability
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
