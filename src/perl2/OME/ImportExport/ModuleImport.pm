# OME/ImportExport/ModuleImport.pm

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


package OME::ImportExport::ModuleImport;

use XML::LibXML;
use OME::Tasks::LSIDManager;
use OME::Session;
use Log::Agent;
use strict;

=head1 NAME

OME::ImportExport::ModuleImport - Import an Analysis Module XML specification.

=head1 SYNOPSIS

	use OME::ImportExport::ModuleImport;
	use OME::SessionManager;
	
	my $manager       = OME::SessionManager->new();
	my $session       = $manager->TTYlogin();
	my $programImport = OME::ImportExport::ModuleImport->new( 
		_parser => $parser
	);

	my $newPrograms   = $programImport->importXMLFile( $filePath );

=head1 DESCRIPTION

This module automates the module import process. Given an XML specification
of a module, this will import it into the OME system.
Specifically, it will:
install the module onto the local system
register the module with the database
add any custom tables & columns (to the DB) that the module requires

=cut

# FIXME: Should verify that every table and column declared are used. 


sub new {
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my %params = @_;
	
	my @requiredParams = ('session' );
	
	my $self = {
		_parser => $params{_parser},
	};
	
	if (!defined $self->{_parser}) {
		my $parser = XML::LibXML->new();
		die "Cannot create XML parser"
		  unless defined $parser;
		
		$parser->validation(exists $params{ValidateXML}?
							$params{ValidateXML}: 0);
		$self->{_parser} = $parser;
	}

	bless($self,$class);
	return $self;
}


=pod
=head2 importXMLFile

Input Parameters:
	filePath - path to xml file to import

Description:
	Import a module from its description in an xml file

=cut

###############################################################################
#
# parameter(s) are:
#	$filePath
#
sub importXMLFile {
	my $self       = shift;
	my $filePath   = shift;

	my $session    = OME::Session->instance();

#	logdbg "debug", ref ($self) . "->importXMLFile called with parameters:\n\t[filePath=] $filePath"
	my $parser = $self->{_parser};

	#Parse
	my $tree = $parser->parse_file( $filePath )
		or die ref($self) . " Could not parse file ($filePath)";

	#process tree
	my $newPrograms = $self->processDOM( $tree->getDocumentElement() );

	#return a list of imported programs (OME::Modules objects)
	return $newPrograms;
}
#
#
###############################################################################

# Given a full category path and optional description, ensures that all
# portions of the path exist in the database as categories, and returns
# the Category object for the leaf category.

sub __getCategory {
    my ($self,$path,$description) = @_;
    my $session = OME::Session->instance();
    my $factory = $session->Factory();

    my @names = split(/\./,$path);
    my $leaf_name = pop(@names);

    # Create/load categories for all but the leaf element
    my $last_parent;
    foreach my $name (@names) {
        my $criteria = { name => $name };
        $criteria->{parent_category_id} = $last_parent->id()
          if defined $last_parent;

        $last_parent = $factory->
          maybeNewObject('OME::Module::Category',$criteria);
    }

    # And then do the same for the leaf element
    my %criteria = ( name => $leaf_name );
    $criteria{parent_category_id} = $last_parent->id()
      if defined $last_parent;

    # We can't use maybeNewObject b/c the search criteria is not the
    # same as the hash to create the new object.

    my $category = $factory->findObject('OME::Module::Category',%criteria);
    if (!defined $category) {
        $criteria{description} = $description;
        $category = $factory->newObject('OME::Module::Category',\%criteria);
    }

    return $category;
}


###############################################################################
#
# Process DOM tree
# parameters:
#	$root element (DOM model)
# returns:
#	list of imported programs
#
sub processDOM {
	my $self    = shift;
	my $root    = shift;

	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $lsidManager = OME::Tasks::LSIDManager->new();

	my @commitOnSuccessfulImport;
	my @newPrograms;
	logdbg "debug", ref ($self) . "->processDOM called to process " . scalar(@{$root->getElementsByLocalName( "AnalysisModule" )} ) . " modules";


	foreach my $categoryXML ($root->getElementsByLocalName('Category')) {
		my $categoryPath = $categoryXML->getAttribute('Path');
		my $categoryDescriptions = $categoryXML->getElementsByLocalName('Description');
		my $categoryDescription = [$categoryDescriptions->[0]->childNodes()]->[0]->data()
			if $categoryDescriptions and [$categoryDescriptions->[0]->childNodes()]->[0];

		my $category = $self->__getCategory($categoryPath,$categoryDescription);
	}


foreach my $moduleXML ($root->getElementsByLocalName( "AnalysisModule" )) {

	###########################################################################
	#
	# make OME::Modules object
	#
	logdbg "debug", ref ($self) . "->processDOM creating OME::Module ".$moduleXML->getAttribute( 'ModuleName' );
	my $program = $lsidManager->getObject( $moduleXML->getAttribute( 'ID' ) );
	if (defined $program) {
		logdbg "debug", ref($self)."->processDOM: ". $moduleXML->getAttribute( 'ModuleName' ) ." already exists in the DB. Skipping...";
		next;
	}
        my $categoryPath = $moduleXML->getAttribute('Category');
        my $categoryID;
        if (defined $categoryPath) {
            my $category = $self->__getCategory($categoryPath);
            $categoryID = $category->id();
        }

	my $descriptions = $moduleXML->getElementsByLocalName('Description');
	my $description = [$descriptions->[0]->childNodes()]->[0]->data()
		if $descriptions and $descriptions->[0]->childNodes()->size() > 0;
	my $module_type = $moduleXML->getAttribute( 'ModuleType' );
	my $data = {
		name     => $moduleXML->getAttribute( 'ModuleName' ),
		description      => $description,
		category         => $categoryID,
		module_type      => $module_type,
		# location using ProgramID attribute is a temporary hack
		location         => $moduleXML->getAttribute( 'ProgramID' ),
		default_iterator => $moduleXML->getAttribute( 'FeatureIterator' ),
		new_feature_tag  => $moduleXML->getAttribute( 'NewFeatureName' ),
	};
	my $newProgram = $factory->newObject("OME::Module",$data)
		or die "Could not create OME::Module object\n";
	push(@commitOnSuccessfulImport, $newProgram);
	$lsidManager->setLSID( $newProgram, $moduleXML->getAttribute( 'ID' ) )
		or die "Couldn't set LSID for module ".$moduleXML->getAttribute( 'ID' );
	#
	#
	###########################################################################
	
	
	##########################################################################
	#
	# process formalInputs 
	#
	# this hash is keyed by FormalInput.Name, valued by DBObject FormalInput
	my %formalInputs;

	logdbg "debug", ref ($self) . "->processDOM processing formal inputs";
	foreach my $formalInputXML ( $moduleXML->getElementsByLocalName( "FormalInput" ) ) {
		logdbg "debug", "\tformal input: ".$formalInputXML->getAttribute('Name');

		#######################################################################
		#
		# make OME::LookupTable & OME::LookupTable::Entry objects
		#
		#
		my $newLookupTable;
		my @lookupTables = $formalInputXML->getElementsByLocalName( "LookupTable" );
		# lookupTables may or may not exist. Either way is fine.
		if( scalar( @lookupTables ) == 1 ) {

			###################################################################
			#
			# make OME::LookupTable object
			#
			my $lookupTableXML = $lookupTables[0];
			my $descriptions = $lookupTableXML->getElementsByLocalName('Description');
			my $description = [$descriptions->[0]->childNodes()]->[0]->data()
				if $descriptions;

			my $data = {
				name        => $lookupTableXML->getAttribute( 'Name' ),
				description => $description
			};
			$newLookupTable = $factory->newObject( "OME::LookupTable", $data )
				or die "Could not create OME::LookupTable object\n";
			push(@commitOnSuccessfulImport, $newLookupTable);
			#
			###################################################################

			###################################################################
			#
			# make OME::LookupTable::Entry objects
			#
			my @entries = $lookupTableXML->getElementsByLocalName( "LookupTableEntry" );
			foreach my $entry (@entries) {
				my $data = {
					value           => $entry->getAttribute( 'Value' ),
					label           => $entry->getAttribute( 'Label' ),
					lookup_table_id => $newLookupTable->ID()
				};
				my $lookupEntry = $factory->newObject( "OME::LookupTable::Entry", $data )
					or die "Could not create OME::LookupTable::Entry object\n";
				push(@commitOnSuccessfulImport, $lookupEntry);
			}
			#
			###################################################################
		}
		#
		#
		#######################################################################

		#######################################################################
		#
		# make OME::FormalInput object
		#
		my $semanticType = $factory->findObject( "OME::SemanticType", name => $formalInputXML->getAttribute( 'SemanticTypeName' ) )
			or die "When processing Formal Input (name=".$formalInputXML->getAttribute( 'Name' )."), could not find Semantic type referenced by ".$formalInputXML->getAttribute( 'SemanticTypeName' )."\n";

		my ($optional, $list, $count);
		$count = $formalInputXML->getAttribute( 'Count' );
		if( $count ) {
			$optional = ( $count eq '*' || $count eq '?' ? 't' : 'f' );
			$list     = ( $count eq '*' || $count eq '+' ? 't' : 'f' );
		} 
		# FIXME: this is the wrong place to set default values. the default values for these columns are specified
		# in OME::Module::FormalInput, but something is broken. if I don't specify them here, then those columns
		# come up blank.
		else {
			$optional = 'f';
			$list = 't';
		}

		my $descriptions = $formalInputXML->getElementsByLocalName('Description');
		my $description = [$descriptions->[0]->childNodes()]->[0]->data()
			if $descriptions;

		my $data = {
			name               => $formalInputXML->getAttribute( 'Name' ),
			description        => $description,
			module_id         => $newProgram,
			semantic_type_id  => $semanticType->id(),
			lookup_table_id    => $newLookupTable,
			optional           => $optional,
			list               => $list,
			user_defined       => $formalInputXML->getAttribute( 'UserDefined' )
		};
		my $newFormalInput = $factory->newObject( "OME::Module::FormalInput", $data )
			or die ref ($self) . " could not create OME::Module::FormalInput object (name=".$formalInputXML->getAttribute( 'Name' ).")\n";

		push(@commitOnSuccessfulImport, $newFormalInput);
		$formalInputs{ $newFormalInput->name() } = $newFormalInput;
		#
		#
		#######################################################################

	}
	#
	#
	###########################################################################
	

	###########################################################################
	#
	# process formalOutputs
	#
	# this hash is keyed by FormalOutput.Name, valued by DBObject FormalOutput
	my %formalOutputs;

	logdbg "debug", ref ($self) . "->processDOM processing formal outputs";
	foreach my $formalOutputXML ( $moduleXML->getElementsByLocalName( "FormalOutput" ) ) {
		logdbg "debug", "\tformal output: ".$formalOutputXML->getAttribute('Name');

		###################################################################
		#
		# make OME::FormalOutput object
		#
        my $semanticTypeName = $formalOutputXML->getAttribute('SemanticTypeName');
        my $semanticType = $factory->findObject( "OME::SemanticType", name => $semanticTypeName );
        # Null semantic types are now allowed for formal outputs
        if (defined $semanticTypeName) {
            die "When processing Formal Output (name=".$formalOutputXML->getAttribute( 'Name' )."), could not find Semantic type referenced by ".$semanticTypeName."\n"
				unless defined $semanticType;
        }
		my ($optional, $list, $count);
		$count = $formalOutputXML->getAttribute( 'Count' );
		if( $count ) {
			$optional = ( $count eq '*' || $count eq '?' ? 't' : 'f' );
			$list     = ( $count eq '*' || $count eq '+' ? 't' : 'f' );
		} else {
                    $optional = 'f';
                    $list = 't';
                }

		my $descriptions = $formalOutputXML->getElementsByLocalName('Description');
		my $description = [$descriptions->[0]->childNodes()]->[0]->data()
			if $descriptions;
		my $data = {
			name               => $formalOutputXML->getAttribute( 'Name' ),
			description        => $description,
			module_id         => $newProgram,
			semantic_type_id  => $semanticType,
			feature_tag        => $formalOutputXML->getAttribute( 'IBelongTo' ),
			optional           => $optional,
			list               => $list
		};
		my $newFormalOutput = $factory->newObject( "OME::Module::FormalOutput", $data )
			or die "Could not create OME::Module::FormalOutput object\n";

		push(@commitOnSuccessfulImport, $newFormalOutput);
		$formalOutputs{ $newFormalOutput->name() } = $newFormalOutput;
		#
		###################################################################

	}
	#
	#
	###########################################################################
	
	
	###########################################################################
	#
	# process executionInstructions (CLI handler specific)
	#
	logdbg "debug", ref ($self) . "->processDOM processing ExecutionInstructions";
	my @executionInstructions = 
		$moduleXML->getElementsByLocalName( "ExecutionInstructions" );
	
	# XML schema & DBdesign currently allow at most one execution point per module
	if(scalar(@executionInstructions) == 1) {
		#######################################################################
		#
		# CLI Handler specific execution Instructions
		#
		my $executionInstructionXML = $executionInstructions[0];

		if ($module_type eq 'OME::Analysis::CLIHandler') {

			#######################################################################
			#
			# verify FormalInputNames. also add ID attributes.
			#
			my @inputTypes = ( "Input", "UseValue", "End", "Start" );
			my @inputs;
			map {
				push(@inputs, $executionInstructionXML->getElementsByLocalName( $_ ));
			} @inputTypes;
	
			foreach my $input (@inputs) {
				my ($formalInputName, $path) = split( /\./, $input->getAttribute( "Location" ), 2 );

				my $formalInput    = $formalInputs{ $formalInputName }
				  or die "Could not find formal input referenced by element ".$input->tagName()." with FormalInputName ". $input->getAttribute( "FormalInputName");
				my $semanticType   = $formalInput->semantic_type();

				my $sen = $path;
				$sen =~ s/^(.*?)\..*$/$1/; # check the SE belonging to this ST, not referenced attributes
				# i guess ideally, you would trace through the references and do a full sweep.
				my $semanticElement = $factory->findObject( "OME::SemanticType::Element", semantic_type_id => $semanticType->id(), name => $sen )
				  or die "Could not find semantic element '$sen' referenced by ".$input->toString().".\n";
	
				# Create attributes FormalInputID and SemanticElementID
				# also create FormalInputName and SemanticElementName to work with CLIHandler code
				# maybe should change CLIHandler code sometime?
				$input->setAttribute ( "FormalInputName", $formalInputName );
				$input->setAttribute ( "SemanticElementName", $path );
				$input->setAttribute ( "FormalInputID", $formalInput->id() );
				$input->setAttribute ( "SemanticElementID", $semanticElement->id() );
	
			}
			#
			#######################################################################
		
			#######################################################################
			#
			# verify outputs. also add ID attributes.
			#
			my @outputTypes = ( "OutputTo", "AutoIterate", "IterateRange" );
			my @outputs;
			map {
				push(@outputs, $executionInstructionXML->getElementsByLocalName( $_ ));
			} @outputTypes;
	
			foreach my $output (@outputs) {
				my ($formalOutputName, $sen) = split( /\./, $output->getAttribute( "Location" ) );
	
				my $formalOutput    = $formalOutputs{ $formalOutputName }
				  or die "Could not find formal output referenced by element ".$output->tagName()." with FormalOutputName ". $output->getAttribute( "FormalOutputName");
				my $semanticType   = $formalOutput->semantic_type();
				my $semanticElement = $factory->findObject( "OME::SemanticType::Element", semantic_type_id => $semanticType->id(), name => $sen )
				  or die "Could not find semantic column referenced by element ".$output->tagName()." with SemanticElementName ".$output->getAttribute( "SemanticElementName" );
	
				# Create attributes FormalOutputID and SemanticElementID to store NAME and FORMAL_OUTPUT_ID
				$output->setAttribute ( "FormalOutputName", $formalOutputName );
				$output->setAttribute ( "SemanticElementName", $sen );
				$output->setAttribute ( "FormalOutputID", $formalOutput->id() );
				$output->setAttribute ( "SemanticElementID", $semanticElement->id() );
	
			}
			#
			#######################################################################
	
			#######################################################################
			#
			# normalize XYPlaneID's
			#
			my $currentID = 0;
			my %idMap;
			# first run: normalize XYPlaneID's in XYPlane's
			foreach my $plane ($executionInstructionXML->getElementsByLocalName( "XYPlane" ) ) {
				$currentID++;
				die "Two planes found with same ID (".$plane->getAttribute('XYPlaneID').")"
				  if ( defined defined $plane->getAttribute('XYPlaneID') ) and ( exists $idMap{ $plane->getAttribute('XYPlaneID') } );
				$idMap{ $plane->getAttribute('XYPlaneID') } = $currentID
				  if defined $plane->getAttribute('XYPlaneID');
				$plane->setAttribute('XYPlaneID', $currentID);
			}
			# second run: clean up references to XYPlanes
			foreach my $match ( $executionInstructionXML->getElementsByLocalName( "Match" ) ) {
				die "'Match' element's reference plane not found. XYPlaneID=".$match->getAttribute('XYPlaneID').". Did you make a typo?"
					unless exists $idMap{ $match->getAttribute('XYPlaneID') };
				$match->setAttribute('XYPlaneID',
					 $idMap{ $match->getAttribute('XYPlaneID') } );
			}
			#
			#######################################################################
			
			#######################################################################
			#
			# check regular expressions for validity
			#
			my @pats =  $executionInstructionXML->getElementsByLocalName( "pat" );
			foreach (@pats) {
				my $pat = $_->getFirstChild->getData();
				eval { "" =~ /$pat/; };
				die "Invalid regular expression pattern: $pat in module ".$newProgram->name()
				  if $@;
			}
			#
			#######################################################################

            }

            $newProgram->execution_instructions( $executionInstructionXML->toString() );
	}
	#
	#
	###########################################################################



	###########################################################################
	# commit this module. It's been successfully imported
	#
	logdbg "debug", ref ($self) . "->processDOM: imported module '".$newProgram->name."' sucessfully. Committing to DB...";
	while( my $DBObjectInstance = pop (@commitOnSuccessfulImport) ){
		$DBObjectInstance->storeObject();
	}                             # commits all DBObjects
    $session->commitTransaction();
	#
	###########################################################################
	
	push(@newPrograms, $newProgram)

} # END foreach my $moduleXML( @modules )
	
	return \@newPrograms;
	
} # END sub processDOM
#
#
###############################################################################


=pod

=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=head1 SEE ALSO

OME/src/xml/AnalysisModule.xsd - XML specification documents should conform to.
OME/src/xml/CLIExecutionInstructions.xsd - XML specification documents should conform to.

=cut


1;
