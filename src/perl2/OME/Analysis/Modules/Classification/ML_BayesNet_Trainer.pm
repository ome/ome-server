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
use OME::Matlab::Engine;
use OME::Util::Classifier;

use base qw(OME::Analysis::Handler);
use Time::HiRes qw(gettimeofday tv_interval);

sub execute {
    my ($self,$dependence,$target) = @_;
	my $mex = $self->getModuleExecution();
	my $dataset = $target; # target should always be a dataset
	
	# open connection to matlab
	my $matlab_engine = OME::Matlab::Engine->open("matlab -nodisplay -nojvm")
		or die "Cannot open a connection to Matlab!";
	my $session = OME::Session->instance();
	my $conf = $session->Configuration() or croak "couldn't retrieve Configuration variables";
	my $matlab_src_dir = $conf->matlab_src_dir or croak "couldn't retrieve matlab src dir from configuration";
	logdbg "debug", "Matlab src dir is $matlab_src_dir\n".
	$engine->eval("addpath(genpath('$matlab_src_dir'));");

	# Compile Signature matrix and place into matlab for input
	my $start_time = [gettimeofday()];
	my @images = $dataset->images( );
	@images = sort {$a->id <=> $b->id} @images;
	my $actual_inputs_list = $self->getActualInputs( 'SignatureVectors' );
    my @input_mexes = map { $_->input_module_execution() } @$actual_inputs;
	my $signature_matrix = OME::Util::Classifier->compile_signature_matrix( \@input_mexes, \@images );
	$matlab_engine->eval("global signature_matrix");
	$matlab_engine->putVariable( "signature_matrix", $signature_matrix);
	$mex->attribute_db_time(tv_interval($start_time));
	
# TEST ME
	# Execute the function
	my $command = "[serialized_bayes_net_classifier, signatures_used] = trainer_fuction( signature_matrix );";
	logdbg "debug", "***** Command to Matlab: $command\n";
	my $outBuffer      = " " x 2048;
	my $blankOutBuffer = " " x 2048;
	$matlab_engine->setOutputBuffer($outBuffer, length($outBuffer));
	$start_time = [gettimeofday()];
	$matlab_engine->eval($command);
	$outBuffer =~ s/(\0.*)$//;
	$mex->total_time(tv_interval($start_time));
	if ($outBuffer ne $blankOutBuffer) {
		$mex->error_message("$outBuffer");
		logdbg "debug", "***** Output from Matlab:\n $outBuffer\n";
	} else {
		logdbg "debug", "***** Output from Matlab:\n";
	}

	# retrieve output & save to DB
	$start_time = [gettimeofday()];
	my $classifier = $matlab_engine->getVariable( "serialized_bayes_net_classifier" )
		or die "Couldn't retrieve output 'serialized_bayes_net_classifier'";
	$classifier->makePersistent();
# FIXME: extract data from $classifier & save to DB
	my $sigs_used = $matlab_engine->getVariable( "signatures_used" )
		or die "Couldn't retrieve output 'signatures_used'";
	$sigs_used->makePersistent();
# FIXME: extract data from $sigs_used & save to DB
	$mex->attribute_create_time(tv_interval($start_time));

	# close connection to matlab
	$matlab_engine->close();

}


=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=head1 SEE ALSO

L<OME::Matlab>, L<OME::Matlab::Engine>, L<OME::Analysis::Handlers::Matlab>
L<http://www.openmicroscopy.org/XMLschemas/MLI/IR2/MLI.xsd|specification of XML instructions>

=cut


1;
