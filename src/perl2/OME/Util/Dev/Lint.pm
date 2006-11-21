# OME/Util/Dev/Lint.pm

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

package OME::Util::Dev::Lint;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use Getopt::Long;

use XML::LibXML;
use XML::LibXSLT;
use OME::SessionManager;
use OME::Session;
use OME::Tasks::ChainManager;
use OME::Tasks::OMEImport;
use OME::ImportExport::ChainExport;

use Getopt::Long;
Getopt::Long::Configure("bundling");



sub getCommands {
    return
      {
       'untangle_chains' => 'untangle_chains',
       'uc'              => 'untangle_chains',
      };
}

sub uc_help { return shift->untangle_chains_help( @_ ); }
sub untangle_chains_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This utility will parse an OME file containing chains, check for
multiple nodes feeding a single input, correct those if found, and save
the untangled chains back to file.

Options:
      
  -f  Specify filename for the input file.
  
  -o  Specify a filename for the OME XML file.  Otherwise all output goes
      to STDOUT
      
  -v  Verbose. Print out a topologically sorted view of the chain nodes.
  
  -c  Compress the output file. 
  
USAGE
}


sub untangle_chains {
	my ($self,$commands) = @_;
	my ($infile, $outfile, $verbose, $compression );
	
	GetOptions('f=s' => \$infile, 'o=s' => \$outfile, 'v' => \$verbose, 'c' => \$compression );
	$compression = ( $compression ? 7 : 0 );
	
	my $session = $self->getSession();
	my $factory = $session->Factory();

	# Load objects from the file into DB, but do not make a mess
	#	do not leave an OriginalFiles, 
	#	do not commit any transactions, 
	#	and do not upload anything to omeis.
	# OME::Tasks::OMEImport->importFile() uploads to omeis & makes an OriginalFiles,
	# so I've copied & pasted some code from it to here:
	my $parser = XML::LibXML->new();
	my $doc = $parser->parse_file( $infile );
	# Apply Stylesheet
	my $xslt = XML::LibXSLT->new();
	my $style_doc_path = $session->Configuration()->xml_dir() . "/OME2OME-CA.xslt";
	my $style_doc = $parser->parse_file( $style_doc_path );
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	my $CA_doc = $stylesheet->transform($doc);
	my $omeImport = OME::Tasks::OMEImport->new();
	my $importedObjects = $omeImport->processDOM( $CA_doc->getDocumentElement(), DO_NOT_COMMIT => 1 );
	
	# Pull out chains to save.
	my @chains_from_file = grep( $_->getFormalName() eq 'OME::AnalysisChain', @$importedObjects );
	my @chains_to_save;
	foreach my $chain( @chains_from_file ) {
		if( $verbose ) {
			print "chain ".$chain->name." (id=".$chain->id.")\n";
			my @chain_elevations = OME::Tasks::ChainManager->topologicalSort($chain);
			OME::Tasks::ChainManager->printChainElevations(@chain_elevations);
		}
	
		my $untangled_chain = $self->__untangle( $chain );
		if( $untangled_chain ) {
			push( @chains_to_save, $untangled_chain );
			if( $verbose ) {
				print "Untangled chain ".$untangled_chain->name." (id=".$untangled_chain->id.")\n";
				my @chain_elevations = $self->__topological_sort( $untangled_chain );
				$self->__print_topo_of_chain(  @chain_elevations );
			}
		} else {
			push( @chains_to_save, $chain );
			print "Chain ".$chain->name." (id=".$chain->id.") is not tangled\n"
				if( $verbose );
		}
	}
	
	# Write the untangled chains to the output file;
	my $chainExport = OME::ImportExport::ChainExport->new();
	$chainExport->buildDOM (\@chains_to_save);
	# ATM, $outfile is guaranteed to be defined. That's cuz I'm lazy about parsing inputs
	if ($outfile) {
		$chainExport->exportFile ($outfile, compression => $compression );
	} else {
		print $chainExport->exportXML();
	}

	# Make sure No mess is left behind
	$session->rollbackTransaction();
}





sub __untangle {
	my ($self, $chain) = @_;

	my $session = OME::Session->instance();
	my $factory = $session->Factory();

	my $untangled_chain = OME::Tasks::ChainManager->cloneChain($chain);
	my @chain_elvations = OME::Tasks::ChainManager->topologicalSort($untangled_chain);
	my $chain_was_tangled = 0;
	
	foreach my $elevation ( @chain_elvations ) {
		foreach my $node ( @$elevation ) {
			my %input_is_satisfied;
			foreach my $incoming_link ( $node->input_links ) {
				# if the input pointed at by this link has not been previously
				# encountered, then mark it as satisfied and go on				
				if( not exists $input_is_satisfied{ $incoming_link->to_input_id } ) {
					$input_is_satisfied{ $incoming_link->to_input_id } = undef;
				}
				
				# otherwise, clone the node & most of the links, AND redirect the rogue link
				else {
					$chain_was_tangled++;
					my $new_node = $factory->newObject(
						"OME::AnalysisChain::Node", {
						module          => $node->module,
						iterator_tag    => $node->iterator_tag,
						new_feature_tag => $node->new_feature_tag,
						analysis_chain  => $node->analysis_chain
					} );
					# copy incoming links (except those coming into the current input )
					foreach my $link ( $node->input_links ) {
						# duplicate incoming links that aren't being examined ATM
						if( $link->to_input_id ne $incoming_link->to_input_id ) {
							$factory->newObject( 'OME::AnalysisChain::Link', {
								to_node        => $new_node,
								to_input       => $link->to_input,
								from_node      => $link->from_node,
								from_output    => $link->from_output,
								analysis_chain => $link->analysis_chain,
							} );					
						} 
						# redirect the rouge link
						elsif( $link->id eq $incoming_link->id ) {
							$link->to_node( $new_node );
							$link->storeObject();
						}
					}
					# copy outgoing links
					foreach my $link ( $node->output_links ) {
						$factory->newObject( 'OME::AnalysisChain::Link', {
							from_node      => $new_node,
							from_output    => $link->from_output,
							to_node        => $link->to_node,
							to_input       => $link->to_input,
							analysis_chain => $link->analysis_chain,
						} );					
					}
					# Finally, put the new node on the elevation stack
					# so it can be checked as well.
					push( @$elevation, $new_node );
				}
			}
		}
	}
	
	# el fin
	return $untangled_chain
		if( $chain_was_tangled );
}

1;
