# OME/Util/Classifier.pm

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

package OME::Util::Classifier;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use Getopt::Long;

use Log::Agent;
use XML::LibXML;
use XML::LibXSLT;
use OME::SessionManager;
use OME::Session;
use OME::Tasks::ImageTasks;
use OME::Tasks::ChainManager;
use OME::Tasks::OMEImport;
use OME::ImportExport::ChainExport;

use Getopt::Long;
Getopt::Long::Configure("bundling");



sub getCommands {
    return
      {
       'stitch_chain' => 'stitch_chain',
      };
}

sub stitch_chain_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

FIXME: Elaborate description
given a signature chain i.e. the one in FullSignatureChain.ome that has
been imported to the db, this will create a signature stitcher module
for that chain, and create a new chain that includes the custom
signature stitcher.

NOTE: STs SignatureVectorEntry and SignatureVectorLegend need to be
imported for this to work. it's a bug that i'll fix next week. easy way
to do that:
[IICBU-2xG4:OME/src/xml] josiah% ome import OME/Tests/FauxSignatures.ome
[IICBU-2xG4:OME/src/xml] josiah% ome import OME/Tests/SigStitcher.ome

Options:

  -x  path of xml source directory
  
  -o  output directory
  
  -c  the name of the signature chain to stitch
      
  -compress  Compress the output file. 

  -h  Print this help message.
  
USAGE
    CORE::exit(1);
}

# constants
our $OME_NS = 'http://www.openmicroscopy.org/XMLschemas/CA/RC1/CA.xsd';
our $AML_NS = 'http://www.openmicroscopy.org/XMLschemas/AnalysisModule/RC1/AnalysisModule.xsd';
our $XSI_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance';

sub stitch_chain {
	my ($self,$commands) = @_;
	my ($xml_src, $outdir, $compression, $chain_name );
	
	GetOptions('x=s' => \$xml_src, 'o=s' => \$outdir, 'c=s' => \$chain_name, 'compress' => \$compression );
	$compression = ( $compression ? 7 : 0 );
	die "one or more options not specified"
		unless $xml_src and $outdir and $chain_name;
	
	my $session = $self->getSession();
	my $factory = $session->Factory();
	
	# find modules that produce signatures
	# simple implementation of leaf nodes for now
#	my $chain_name = 'Almost Full Signature Chain';
	logdbg "debug", "Finding Signature Modules in chain $chain_name";
	my $chain = $factory->findObject( "OME::AnalysisChain", name => $chain_name )
		or die "cannot find chain named $chain_name";
	my @signature_nodes = OME::Tasks::ChainManager->findLeaves( $chain );
	logdbg "debug", "Found chain nodes. Format of output is 'module_name(node_id)'\n\t".
		join( ', ', map( $_->module->name."(".$_->id.")", @signature_nodes ) );
	
	
# FIXME: add necessary STs to module file!
	##############
	# create signature module (xml)
	logdbg "debug", "Creating signature module";
	my $doc = XML::LibXML::Document->new();
	die "Cannot create XML document"
	  unless defined $doc;
	my $root = $doc->createElementNS($OME_NS,'OME');
	$root->setNamespace($XSI_NAMESPACE, 'xsi',0);
	$root->setAttributeNS($XSI_NAMESPACE,'schemaLocation',"$OME_NS $OME_NS");
	$doc->setDocumentElement($root);
	my $module_library = $doc->createElementNS($AML_NS,'AnalysisModuleLibrary');
	$root->appendChild( $module_library );
	
	# Make the module
	my $module = $doc->createElement('AnalysisModule');
	$module->setAttribute( 'ModuleType', "OME::Analysis::Modules::Classification::SignatureStitcher");
	$module->setAttribute( 'Category', "Classifier");
	my $new_LSID = $self->get_next_LSID( $xml_src );
	$module->setAttribute( 'ID', $new_LSID );
	$new_LSID =~ m/urn:lsid:openmicroscopy.org:Module:(\d+)/;
	my $module_name = "Signature Stitcher ($1)";
	$module->setAttribute( 'ModuleName', $module_name );
	$module->setAttribute( 'ProgramID', "" );
	$module_library->appendChild( $module );
	
	# Make the description
	my $module_description = $doc->createElement('Description');
	$module_description->appendChild( XML::LibXML::Text->new( <<ENDDESCRIPTION ) );
Combines outputs from "signature modules" into a single vector that
describes the image. This stitching is very handy for classifiers.
ENDDESCRIPTION
	$module->appendChild( $module_description );
	
	# Declaration
	my $declaration = $doc->createElement('Declaration');
	$module->appendChild( $declaration );
	
	# Inputs
	my %input_links_by_ST; # values will be array of each link coming in of the same ST
	# round one: gather inputs links
	foreach my $sig_node ( @signature_nodes ) {
		foreach my $output ( $sig_node->module->outputs ) {
			my $ST_name = $output->semantic_type->name;
			push( @{ $input_links_by_ST{ $ST_name } }, {
				from_node   => $sig_node,
				from_output => $output
			} );
		}
	}
	# round two: sort links, translate them to inputs, record mapping from links to inputs
	my %input_links_by_input; # flat hash to store link info. key by input name
	foreach my $ST_name ( keys %input_links_by_ST ) {
		my $name_incrementer = 0;
		foreach my $input_link( @{ $input_links_by_ST{ $ST_name } } ) {
			$name_incrementer++;
			my $input_name;
			if( scalar( @{ $input_links_by_ST{ $ST_name } } ) eq 1 ) {
				$input_name = $ST_name;
			} else {
				$input_name = "$ST_name $name_incrementer";
			}
			my $formal_input = $doc->createElement( 'FormalInput');
			$formal_input->setAttribute( 'Name', $input_name );
			$formal_input->setAttribute( 'SemanticTypeName', $ST_name );
			$formal_input->setAttribute( 'Count', '!' );
			$declaration->appendChild( $formal_input );
			$input_links_by_input{ $input_name } = $input_link;
		}
	}
	
	# Outputs
	my $formal_output = $doc->createElement( 'FormalOutput');
	$formal_output->setAttribute( 'Name', 'SignatureVector' );
	$formal_output->setAttribute( 'SemanticTypeName', 'SignatureVectorEntry' );
	$formal_output->setAttribute( 'Count', '+' );
	$declaration->appendChild( $formal_output );
	$formal_output = $doc->createElement( 'FormalOutput');
	$formal_output->setAttribute( 'Name', 'VectorLegend' );
	$formal_output->setAttribute( 'SemanticTypeName', 'SignatureVectorLegend' );
	$formal_output->setAttribute( 'Count', '+' );
	$declaration->appendChild( $formal_output );
	
	# save to disk
	my $file_name = $module_name;
	$file_name =~ s/ //g;
	$file_name = $outdir. '/' . $file_name . ".ome";
	$doc->toFile( $file_name, 2 );
	logdbg "debug", "Saved signature module to $file_name";
	
	# import module
	logdbg "debug", "Importing module $module_name into DB";
	OME::Tasks::ImageTasks::importFiles (undef, [ $file_name ] );
	my $stitcher_module = $factory->findObject( "OME::Module", name => $module_name )
		or die "Could not load Signature Stitcher module named '$module_name'";
	
	# create new chain that includes signature module (db)
	logdbg "debug", "Creating new chain that includes the stitcher";
	my $new_chain = OME::Tasks::ChainManager->cloneChain( $chain );
	my $stitcher_node  = $factory->newObject( 'OME::AnalysisChain::Node', {
		module         => $stitcher_module,
		analysis_chain => $new_chain
	} );
	# make links
	foreach my $input_name ( keys %input_links_by_input ) {
		my $formal_input = $factory->findObject( "OME::Module::FormalInput",
			module => $stitcher_module,
			name   => $input_name
		) or die "Couldn't load input $input_name for module $module_name";
		my $data = {
			to_node     => $stitcher_node,
			to_input    => $formal_input,
			from_node   => $input_links_by_input{ $input_name }{ 'from_node' },
			from_output => $input_links_by_input{ $input_name }{ 'from_output' },
			analysis_chain => $new_chain
		};
		$factory->newObject( "OME::AnalysisChain::Link", $data )
			or die "Couldn't make link from ".
				$input_links_by_input{ $input_name }{ 'from_node' }->module->name.'.'.
				$input_links_by_input{ $input_name }{ 'from_output' }->name.
				" to $module_name.$input_name";
	}
	$session->commitTransaction();
	
	
	# save new chain to disk
	my $chain_file = $new_chain->name().'.'.$new_chain->id.'.ome';
	$chain_file =~ s/ //g;
	$chain_file = $outdir. '/' . $chain_file;
	logdbg "debug", "Saving new chain to $chain_file";
	my $chainExport = OME::ImportExport::ChainExport->new();
	$chainExport->buildDOM ([$new_chain]);
	$chainExport->exportFile ($chain_file, compression => 0 );
	
}

sub get_next_LSID {
	my ($self, $xml_src ) = @_;
	my $session = $self->getSession();
	my $factory = $session->Factory();

	# FIXME: use something besides backticks for this.
	my @grep_results = `grep -r 'urn:lsid:openmicroscopy.org:Module:72' $xml_src/*`;
	my $high_id=7200;
	foreach( @grep_results ) {
		if( m/urn:lsid:openmicroscopy.org:Module:(72\d\d)/ ) {
			$high_id = $1 if $1 gt $high_id;
		}
	}
	
	# just for yucks, check against LSIDs from the DB
	my @LSIDs = $factory->findObjects( "OME::LSID",
		lsid => [ 'like', 'urn:lsid:openmicroscopy.org:Module:72%' ]
	);
	foreach( map( $_->lsid, @LSIDs) ) {
		if( m/urn:lsid:openmicroscopy.org:Module:(72\d\d)/ ) {
			$high_id = $1 if $1 gt $high_id;
		}		
	}

	return 'urn:lsid:openmicroscopy.org:Module:'.($high_id + 1);
}
