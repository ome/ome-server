# OME/Tasks/OMEImport.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Tasks::OMEImport;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use Log::Agent;
use XML::LibXML;
use XML::LibXSLT;

use OME::Analysis::Engine;
use OME::Tasks::ImportManager;
use OME::ImportExport::SemanticTypeImport;
use OME::ImportExport::ModuleImport;
use OME::ImportExport::ChainImport;
use OME::ImportExport::HierarchyImport;
use OME::ImportExport::DataHistoryImport;
use OME::ImportExport::ResolveFiles;
use OME::Image::Server::File;
use OME::Tasks::PixelsManager;

sub new {
    my ($proto, %params) = @_;
    my $class = ref($proto) || $proto;

    my @fieldsILike = qw(session _parser debug);

    my $self;

    @$self{@fieldsILike} = @params{@fieldsILike};

    die $class."->new needs a session"
      unless exists $self->{session} &&
             UNIVERSAL::isa($self->{session},'OME::Session');

    if (!defined $self->{_parser}) {
        my $parser = XML::LibXML->new();
        die "Cannot create XML parser"
          unless defined $parser;

        $parser->validation(exists $params{ValidateXML}?
                            $params{ValidateXML}: 0);
        $self->{_parser} = $parser;
    }

    return bless $self, $class;
}


sub importFile {
    my ($self, $filename, %flags) = @_;
    my $session = $self->{session};
    my $parser  = $self->{_parser};
	my $factory       = $session->Factory();

	my $repository;
	eval {
		$repository = $factory->findAttribute( "Repository", IsLocal => 'f' );
	};
	$repository = $factory->findObject( "OME::SemanticType::BootstrapRepository", IsLocal => 'f' )
		unless $repository;
	die "Could not find a remote image server to load"
		unless $repository;

    OME::Tasks::PixelsManager->activateRepository($repository);

	my $file = OME::Image::Server::File->upload($filename);	

	# FIXME: image server should autodetect duplicate file and take action --or--
	#  this code should delete this just uploaded file if it has duplicate SHA1
	my $sha1 = $file->getSHA1();
    my $originalFile;
    eval {
        $originalFile = $session->Factory->
          findAttribute("originalFile",SHA1 => $sha1);
    };
	return if defined $originalFile;

    my $resolver = OME::ImportExport::ResolveFiles->new( session => $session, parser => $parser )
    	or die "Could not instantiate OME::ImportExport::ResolveFiles\n";
    my $doc = $resolver->importFile( $file->getFileID(), $repository );
 	
 	# Apply Stylesheet
 	my $xslt = XML::LibXSLT->new();
 	my $style_doc_path = $session->Configuration()->xml_dir() . "/OME2OME-CA.xslt";
 	my $style_doc = $parser->parse_file( $style_doc_path );
	my $stylesheet = $xslt->parse_stylesheet($style_doc);
	my $CA_doc = $stylesheet->transform($doc);

    OME::Tasks::ImportManager->startImport();

	$self->processDOM($CA_doc->getDocumentElement(),%flags);
    
	# Store the file hash.
    my $mex = OME::Tasks::ImportManager->getOriginalFilesMEX();
    if (defined $mex) {
        $originalFile = $session->Factory->
          newAttribute("OriginalFile",undef,$mex,
                       {SHA1 => $file->getSHA1(), 
                        Path => $file->getFilename(), 
                        FileID => $file->getFileID(), 
                        Format => 'OME XML',
                        Repository => $repository });
        $mex->status('FINISHED');
        $mex->storeObject();
    }

    # Commit the transaction to the DB.
    $self->{session}->commitTransaction();

    OME::Tasks::ImportManager->finishImport();

	return;
}

# importXML commented out by josiah 6/10/03
# preprocessing of the xml document must have a file as input (so far)
# preprocessing must be performed, so this function will not work for now
#sub importXML {
#    my ($self, $xml, %flags) = @_;
#    my $doc = $self->{_parser}->parse_string($xml)
#      or die "Cannot parse XML string";
#    return $self->processDOM($doc->getDocumentElement(),%flags);
#}


sub processDOM {
    my ($self, $root, %flags) = @_;

    # Parse the semantic types

    my $typeImporter = OME::ImportExport::SemanticTypeImport->
      new(session => $self->{session},
          _parser => $self->{_parser},
          debug => $self->{debug});

    my $stdElement = $root->
      getElementsByLocalName("SemanticTypeDefinitions" )->[0];

    my $semanticTypeList = $typeImporter->processDOM($stdElement,%flags)
        if defined $stdElement;

    my $semanticTypes = $typeImporter->SemanticTypes();
    my $semanticColumns = $typeImporter->SemanticColumns();

    # Parse the modules

    my $moduleImporter = OME::ImportExport::ModuleImport->
      new(session         => $self->{session},
          _parser         => $self->{_parser},
         debug => $self->{debug});

    my $amlElement = $root->
      getElementsByLocalName("AnalysisModuleLibrary" )->[0];

    my $moduleList = $moduleImporter->processDOM($amlElement,%flags)
      if defined $amlElement;

    # Parse the chains

    my $chainImporter = OME::ImportExport::ChainImport->
      new(session => $self->{session},
          _parser => $self->{_parser});

    my $chainList = $chainImporter->processDOM($root,%flags);


    # Parse the hierarchy and custom attributes

    my $hierarchyImporter = OME::ImportExport::HierarchyImport->
      new(session         => $self->{session},
          _parser         => $self->{_parser},
          semanticTypes   => $semanticTypes,
          semanticColumns => $semanticColumns);

    my ($importedObjects, $importDataset ) = $hierarchyImporter->processDOM($root);

    # Parse the data History
    my $historyImporter = OME::ImportExport::DataHistoryImport->
      new(session         => $self->{session},
          _parser         => $self->{_parser},
          objects         => $importedObjects);

    $historyImporter->processDOM($root);

    # Detect and mark imported objects that already exist in the DB
	$self->detectAndMarkDuplicateObjects($hierarchyImporter);
    # Store unmarked objects.
	$hierarchyImporter->storeObjects( );
	
	# Run the engine on the imported dataset.
	if( $importDataset ) {
		my $chain = $self->{session}->Factory->
			findObject("OME::AnalysisChain",name => 'Image import analyses');
		
		if (!defined $chain) {
			logcarp "The image import analysis chain is not defined.  Skipping predefined analyses..."
				if !defined $chain;
		} else {
			logdbg "debug", ref ($self)."->processDOM: Running module_execution tasks";
			OME::Analysis::Engine->
                executeChain($chain,$importDataset,{});
		}
	}

	# commit changes made to database structure by $typeImporter if we made it
	# this far
    $self->{session}->commitTransaction();

}

sub detectAndMarkDuplicateObjects {
	my ($self, $hierarchyImporter) = @_;
	
	my $factory	= $self->{session}->Factory();
	
	logdbg "debug", ref ($self)."->detectDuplicateObjects: Looking for objects in the DB identical to imported objects with malformed LSIDs";

	foreach my $entry ( values %{ $hierarchyImporter->{_malformedLSIDs} } ) {
		my ( $object, $refs2Obj ) = ($entry->{object}, $entry->{refsToObject} );
		if( UNIVERSAL::isa($object,"OME::SemanticType::Superclass") ){
			logdbg "debug", ref ($self)."->detectDuplicateObjects: examining $object";
			my $criteria = $object->getDataHash();
			$criteria->{ target_id } = $object->target_id
				unless $object->semantic_type->granularity eq 'G';
			# objects without a module execution in the imported file are assigned one by the hierarchyImporter
			#   the module_execution_id is not considered relevent in the test for equality if it was not
			#   given in the file.
			$criteria->{ module_execution_id } = $object->module_execution_id
				unless $hierarchyImporter->createdMEXduringImport( $object->module_execution_id );
#			logdbg "debug", ref ($self)."->detectDuplicateObjects: searching with criteria\n\t".join( "\n\t", map ( $_." => ".$criteria->{$_}, keys %$criteria ) );
			my @matches = $factory->findAttributes( $object->semantic_type, $criteria);
			@matches = grep( $_->id ne $object->id, @matches);
			#####################
			# duplicate object found
			if( scalar @matches > 0 ) {  
				my $new_referent = $matches[0];
				logdbg "debug", ref ($self)."->detectDuplicateObjects: found matching object ($new_referent, ".$new_referent->id.")";
				# We found an existing attr that matches. Change references to the duplicate obj to the existing db object.
				foreach (@{ $refs2Obj }) {
					my ($obj, $field) = ( $_->{Object}, $_->{Field} );
					$obj->$field( $new_referent );
					$obj->storeObject()
				}
# FIXME: need to delete duplicate objects or mark them for hierarchy import to delete
# FIXME: need to map duplicate objects' recent import MEX to pre-existing objects via virtual MEX once Imports are recorded as virtual MEXs
			}
		}
	}
}

1;
