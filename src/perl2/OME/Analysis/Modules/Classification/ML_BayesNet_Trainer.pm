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
	$matlab_engine->eval("addpath(genpath('$matlab_src_dir'));");

	# Compile Signature matrix and place into matlab for input
	my $start_time = [gettimeofday()];
	my @images = $dataset->images( );
	@images = sort {$a->id <=> $b->id} @images;

    my @classification_mexes = map { $_->input_module_execution() } @{ 
    	$self->getActualInputs( 'Classifications' ) };
    my @sigVectors_mexes = map { $_->input_module_execution() } @{ 
    	$self->getActualInputs( 'SignatureVectors' ) };
	my $signature_matrix = OME::Util::Classifier->compile_signature_matrix( \@sigVectors_mexes, \@images, \@classification_mexes );
	$matlab_engine->eval("global signature_matrix");
	$matlab_engine->putVariable( "signature_matrix", $signature_matrix);
	$mex->attribute_db_time(tv_interval($start_time));
	
# Dump the signature matrix to test what we have so far
# my $output_file_name = '~/foo.mat';
# $matlab_engine->eval("global signature_vector");
# $matlab_engine->putVariable('signature_vector',$signature_matrix);
# $matlab_engine->eval( "save $output_file_name signature_vector;" );
# print STDERR "Saved signature vector to file $output_file_name.\n\n\n";

# IMPLEMENT THE REST OF THIS

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
