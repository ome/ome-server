package OME::Tasks::ProgramImport;

use XML::LibXML;
use strict;

=head1 NAME

OME::Tasks::ProgramImport - Import an Analysis Module XML specification.

=head1 SYNOPSIS

	use OME::Tasks::ProgramImport;
	use OME::SessionManager;
	
	my $session       = OME::SessionManager->TTYlogin();
	my $programImport = OME::Tasks::ProgramImport->new( 
		session => $session,
		debug   => 0
	);
	# debug => 0 means report only fatal errors
	# debug => 1 means give a description of what is happening
	# debug => 2 means give an extremely detailed description of what is happening

	my $newPrograms   = $programImport->importXMLFile( $filePath );

=head1 DESCRIPTION

This module automates the module import process. Given an XML specification
of a module, this will import it into the OME system.
Specifically, it will:
install the module onto the local system
register the module with the database
add any custom tables & columns (to the DB) that the module requires

=head1 IMPROVEMENTS/2do

Should verify that every table and column declared are used. 

=cut

sub new {
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my %params = @_;
	my $debug = $params{debug} || 0;
	
	print STDERR $proto . "->new called with parameters:\n\t" . join( "\n\t", map { $_."=>".$params{$_} } keys %params ) ."\n" 
		if $debug > 1;
	
	my @requiredParams = ('session','semanticTypes','semanticColumns');
	
	foreach (@requiredParams) {
		die ref ($class) . "->new called without required parameter '$_'"
			unless exists $params{$_}
	}

	my $self = {
		session => $params{session},
		debug   => $params{debug} || 0,
                semanticTypes => $params{semanticTypes},
                semanticColumns => $params{semanticColumns},
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
	print STDERR ref ($self) . "->new returning successfully\n" 
		if $debug > 1;
	return $self;
}


=pod
=head2 importXMLFile

Input Parameters:
	filePath - path to xml file to import

Description:
	Import a module from its descriptiong in an xml file

=cut

###############################################################################
#
# parameter(s) are:
#	$session - an OME::Session object
#	$filePath
#
sub importXMLFile {
	my $self       = shift;
	my $filePath   = shift;

	my $debug      = $self->{debug};
	my $session    = $self->{session};

	print STDERR ref ($self) . "->importXMLFile called with parameters:\n\t[filePath=] $filePath\n"
		if $debug > 0;
	#my $parser     = XML::LibXML->new();
        my $parser = $self->{_parser};
#	print STDERR ref ($self) . "->importXMLFile about to validate file\n"
#		if $debug > 1;
	#Validate file against Schema
	{
	# insert code here
	};
#	print STDERR ref ($self) . "->importXMLFile has validated file\n"
#		if $debug > 1;

	#Parse
	print STDERR ref ($self) . "->importXMLFile about to parse file\n"
		if $debug > 1;
	my $tree = $parser->parse_file( $filePath )
		or die ref($self) . " Could not parse file ($filePath)";
	print STDERR ref ($self) . "->importXMLFile parsed file\n"
		if $debug > 1;

	#process tree
	print STDERR ref ($self) . "->importXMLFile about to process DOM (parsed file)\n"
		if $debug > 1;
	my $newPrograms = $self->processDOM( $tree->getDocumentElement() );
	print STDERR ref ($self) . "->importXMLFile processed DOM\n"
		if $debug > 1;

	#return a list of imported programs (OME::Programs objects)
	print STDERR ref ($self) . "->importXMLFile returning\n" 
		if $debug > 0;
	return $newPrograms;
}
#
#
###############################################################################


###############################################################################
#
# Process DOM tree
# parameters:
#	$session - an OME::Session object
#	$root element (DOM model)
# returns:
#	list of imported programs
#
sub processDOM {
	my $self    = shift;
	my $root    = shift;

	my $debug   = $self->{debug};
	my $session = $self->{session};
	my $factory = $session->Factory();

	my @commitOnSuccessfulImport;
	my @newPrograms;
	print STDERR ref ($self) . "->processDOM called to process " . scalar(@{$root->getElementsByLocalName( "AnalysisModule" )} ) . " modules\n"
		if $debug > 0;


        my $semanticTypes = $self->{semanticTypes};
        my $semanticColumns = $self->{semanticColumns};


foreach my $moduleXML ($root->getElementsByLocalName( "AnalysisModule" )) {

	###########################################################################
	#
	# make OME::Programs object
	#
# À use find_or_create instead ?
	print STDERR ref ($self) . "->processDOM about to create an OME::Program object\n"
		if $debug > 1;
	my @programs = $factory->findObjects( "OME::Program", 
		'program_name', $moduleXML->getAttribute( 'ModuleName' ) );
	die "\nCannot add module ". $moduleXML->getAttribute( 'ModuleName' ) . ". A module of the same name already exists.\n"
		unless scalar (@programs) eq 0;
	my $data = {
		program_name     => $moduleXML->getAttribute( 'ModuleName' ),
		description      => $moduleXML->getAttribute( 'Description' ),
		category         => $moduleXML->getAttribute( 'Category' ),
		module_type      => $moduleXML->getAttribute( 'ModuleType' ),
		# location using ProgramID attribute is a temporary hack
		location         => $moduleXML->getAttribute( 'ProgramID' ),
		default_iterator => $moduleXML->getAttribute( 'FeatureIterator' ),
		new_feature_tag  => $moduleXML->getAttribute( 'NewFeatureName' ),
		#visual_design => $moduleXML->getAttribute( 'VisualDesign' )
		# visual design is not implemented in the api. I think it is depricated.
	};
	print STDERR "Program parameters are\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
		if $debug > 1;
	my $newProgram = $factory->newObject("OME::Program",$data)
		or die "Could not create OME::Program object\n";
	push(@commitOnSuccessfulImport, $newProgram);
	print STDERR ref ($self) . "->processDOM created an OME::Program object\n"
		if $debug > 1;
	#
	#
	###########################################################################
	
	
	##########################################################################
	#
	# process formalInputs 
	#
	# this hash is keyed by FormalInput.Name, valued by DBObject FormalInput
	my %formalInputs;

	print STDERR ref ($self) . "->processDOM about to process formal inputs\n"
		if $debug > 1;
	foreach my $formalInputXML ( $moduleXML->getElementsByLocalName( "FormalInput" ) ) {
		print STDERR ref ($self) . "->processDOM is processing formal input, ".$formalInputXML->getAttribute('Name')."\n"
			if $debug > 1;


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
			my $data = {
				name        => $lookupTableXML->getAttribute( 'Name' ),
				description => $lookupTableXML->getAttribute( 'Description' )
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
		die "When processing Formal Input (name=".$formalInputXML->getAttribute( 'Name' )."), could not find Semantic type referenced by ".$formalInputXML->getAttribute( 'SemanticTypeName' )."\n"
			unless exists $semanticTypes->{ $formalInputXML->getAttribute( 'SemanticTypeName' ) };

		my ($optional, $list, $count);
		$count = $formalInputXML->getAttribute( 'Count' );
		if( $count ) {
			$optional = ( $count eq '*' || $count eq '?' ? 't' : 'f' );
			$list     = ( $count eq '*' || $count eq '+' ? 't' : 'f' );
		} else {
                    $optional = 'f';
                    $list = 't';
                }
		my $data = {
			name               => $formalInputXML->getAttribute( 'Name' ),
			description        => $formalInputXML->getAttribute( 'Description' ),
			program_id         => $newProgram,
			attribute_type_id  => $semanticTypes->{ $formalInputXML->getAttribute( 'SemanticTypeName' ) },
			lookup_table_id    => $newLookupTable,
			optional           => $optional,
			list               => $list,
			user_defined       => $formalInputXML->getAttribute( 'UserDefined' )
		};
		my $newFormalInput = $factory->newObject( "OME::Program::FormalInput", $data )
			or die ref ($self) . " could not create OME::Program::FormalInput object (name=".$formalInputXML->getAttribute( 'Name' ).")\n";

		push(@commitOnSuccessfulImport, $newFormalInput);
		$formalInputs{ $newFormalInput->name() } = $newFormalInput;
		#
		#
		#######################################################################

		print STDERR ref ($self) . "->processDOM finished processing formal input, ".$newFormalInput->name()."\n"
			if $debug > 1;
	}
	print STDERR ref ($self) . "->processDOM finished processing formal inputs\n"
		if $debug > 1;
	#
	#
	###########################################################################
	

	###########################################################################
	#
	# process formalOutputs
	#
	# this hash is keyed by FormalOutput.Name, valued by DBObject FormalOutput
	my %formalOutputs;

	print STDERR ref ($self) . "->processDOM about to process formal outputs\n"
		if $debug > 1;
	foreach my $formalOutputXML ( $moduleXML->getElementsByLocalName( "FormalOutput" ) ) {

		print STDERR ref ($self) . "->processDOM is processing formal output, ".$formalOutputXML->getAttribute('Name')."\n"
			if $debug > 1;

		###################################################################
		#
		# make OME::FormalOutput object
		#
        my $semanticTypeName = $formalOutputXML->getAttribute('SemanticTypeName');
        my $semanticType = undef;
        # Null semantic types are now allowed for formal outputs
        if (defined $semanticTypeName) {
            die "When processing Formal Output (name=".$formalOutputXML->getAttribute( 'Name' )."), could not find Semantic type referenced by ".$semanticTypeName."\n"
              unless exists $semanticTypes->{ $semanticTypeName };
            $semanticType = $semanticTypes->{ $semanticTypeName };
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
		my $data = {
			name               => $formalOutputXML->getAttribute( 'Name' ),
			description        => $formalOutputXML->getAttribute( 'Description' ),
			program_id         => $newProgram,
			attribute_type_id  => $semanticType,
			feature_tag        => $formalOutputXML->getAttribute( 'IBelongTo' ),
			optional           => $optional,
			list               => $list
		};
		my $newFormalOutput = $factory->newObject( "OME::Program::FormalOutput", $data )
			or die "Could not create OME::Program::FormalOutput object\n";

		push(@commitOnSuccessfulImport, $newFormalOutput);
		$formalOutputs{ $newFormalOutput->name() } = $newFormalOutput;
		#
		###################################################################

		print STDERR ref ($self) . "->processDOM finished processing formal output, ".$newFormalOutput->name()."\n"
			if $debug > 1;
	}
	print STDERR ref ($self) . "->processDOM finished processing formal outputs\n"
		if $debug > 1;
	#
	#
	###########################################################################
	
	
	###########################################################################
	#
	# process executionInstructions (CLI handler specific)
	#
	print STDERR ref ($self) . "->processDOM about to process ExecutionInstructions\n"
		if $debug > 1;
	my @executionInstructions = 
		$moduleXML->getElementsByLocalName( "ExecutionInstructions" );
	
	# XML schema & DBdesign currently allow at most one execution point per module
	if(scalar(@executionInstructions) == 1) {
		#######################################################################
		#
		# CLI Handler specific execution Instructions
		#
		my $executionInstructionXML = $executionInstructions[0];

		#######################################################################
		#
		# verify FormalInputNames. also add ID attributes.
		#
		print STDERR ref ($self) . "->processDOM: verifying input references. (FormalInputNames and SemanticElementNames). Also creating ID attributes\n"
			if $debug > 1;
		my @inputTypes = ( "Input", "UseValue", "End", "Start" );
		my @inputs;
		map {
			push(@inputs, $executionInstructionXML->getElementsByLocalName( $_ ));
		} @inputTypes;

		foreach my $input (@inputs) {
			my $formalInput    = $formalInputs{ $input->getAttribute( "FormalInputName" ) }
				or die "Could not find formal input referenced by element ".$input->tagName()." with FormalInputName ". $input->getAttribute( "FormalInputName");
			my $semanticType   = $formalInput->attribute_type();
			my $semanticElement = $semanticColumns->{ $semanticType->name() }->{ $input->getAttribute( "SemanticElementName" ) }
				or die "Could not find semantic column referenced by element ".$input->tagName()." with SemanticElementName ".$input->getAttribute( "SemanticElementName" );
		
			# Create attributes FormalInputID and SemanticElementID to store FORMAL_INPUT_ID and ATTRIBUTE_COLUMN_ID.
			print STDERR ref ($self) . "->processDOM: creating FormalInputID attribute in element type ".$input->tagName()."\n\tValue is ".
				$formalInput->id() . "\n"
				if $debug > 1;
			$input->setAttribute ( "FormalInputID", $formalInput->id() );
			print STDERR ref ($self) . "->processDOM: creating SemanticElementID attribute in element type ".$input->tagName()."\n\tValue is ".
				$semanticElement->id()."\n"
				if $debug > 1;
			$input->setAttribute ( "SemanticElementID", $semanticElement->id() );

		}
		print STDERR ref ($self) . "->processDOM: finished verifying inputs and adding ID attributes.\n"
			if $debug > 1;
		#
		#######################################################################
	
		#######################################################################
		#
		# verify outputs. also add ID attributes.
		#
		print STDERR ref ($self) . "->processDOM: verifying output references (FormalOutputName and SemanticElementName). Also creating ID attributes.\n"
			if $debug > 1;
		my @outputTypes = ( "OutputTo", "AutoIterate", "IterateRange" );
		my @outputs;
		map {
			push(@outputs, $executionInstructionXML->getElementsByLocalName( $_ ));
		} @outputTypes;

		foreach my $output (@outputs) {
			my $formalOutput    = $formalOutputs{ $output->getAttribute( "FormalOutputName" ) }
				or die "Could not find formal output referenced by element ".$output->tagName()." with FormalOutputName ". $output->getAttribute( "FormalOutputName");
			my $semanticType   = $formalOutput->attribute_type();
			my $semanticElement = $semanticColumns->{ $semanticType->name() }->{ $output->getAttribute( "SemanticElementName" ) }
				or die "Could not find semantic column referenced by element ".$output->tagName()." with SemanticElementName ".$output->getAttribute( "SemanticElementName" );

			# Create attributes FormalOutputID and SemanticElementID to store NAME and FORMAL_OUTPUT_ID
			print STDERR ref ($self) . "->processDOM: creating FormalOutputID attribute in element type ".$output->tagName()."\n\tValue is ".
				$formalOutput->id() . "\n"
				if $debug > 1;
			$output->setAttribute ( "FormalOutputID", $formalOutput->id() );
			print STDERR ref ($self) . "->processDOM: creating SemanticElementID attribute in element type ".$output->tagName()."\n\tValue is ".
				$semanticElement->id()."\n"
				if $debug > 1;
			$output->setAttribute ( "SemanticElementID", $semanticElement->id() );

		}
		print STDERR ref ($self) . "->processDOM: finished verifying outputs and adding ID attributes.\n"
			if $debug > 1;
		#
		#######################################################################

		#######################################################################
		#
		# normalize XYPlaneID's
		#
		print STDERR ref ($self) . "->processDOM: normalizing XYPlaneID's\n"
			if $debug > 1;
		my $currentID = 0;
		my %idMap;
		# first run: normalize XYPlaneID's in XYPlane's
		foreach my $plane($executionInstructionXML->getElementsByLocalName( "XYPlane" ) ) {
			$currentID++;
			die "Two planes found with same ID (".$plane->getAttribute('XYPlaneID').")"
				if ( defined defined $plane->getAttribute('XYPlaneID') ) and ( exists $idMap{ $plane->getAttribute('XYPlaneID') } );
			print STDERR ref ($self) . "->processDOM: altering attribute XYPlaneID in element type XYPlane\n" .
				(defined $plane->getAttribute('XYPlaneID') ? $plane->getAttribute('XYPlaneID') : '[No value]') .
				" -> " . $currentID . "\n"
				if $debug > 1;
			$idMap{ $plane->getAttribute('XYPlaneID') } = $currentID
				if defined $plane->getAttribute('XYPlaneID');
			$plane->setAttribute('XYPlaneID', $currentID);
		}
		# second run: clean up references to XYPlanes
		foreach my $match ( $executionInstructionXML->getElementsByLocalName( "Match" ) ) {
			die "'Match' element's reference plane not found. XYPlaneID=".$match->getAttribute('XYPlaneID').". Did you make a typo?"
				unless exists $idMap{ $match->getAttribute('XYPlaneID') };
			print STDERR ref ($self) . "->processDOM: altering XYPlaneID in element type Match\n" .
				$match->getAttribute('XYPlaneID') .	" -> " . $idMap{ $match->getAttribute('XYPlaneID') } . "\n"
				if $debug > 1;
			$match->setAttribute('XYPlaneID',
				$idMap{ $match->getAttribute('XYPlaneID') } );
		}
		print STDERR ref ($self) . "->processDOM: finished normalizing XYPlaneID's\n"
			if $debug > 1;
		#
		#######################################################################
		
		#######################################################################
		#
		# check regular expressions for validity
		#
		print STDERR ref ($self) . "->processDOM: checking regular expression patterns for validity\n"
			if $debug > 1;
		my @pats =  $executionInstructionXML->getElementsByLocalName( "pat" );
		foreach (@pats) {
			my $pat = $_->getFirstChild->getData();
			print STDERR ref ($self) . "->processDOM: inspecting pattern:\n$pat\n"
				if $debug > 1;
			eval { "" =~ /$pat/; };
			die "Invalid regular expression pattern: $pat in program ".$newProgram->program_name()
				if $@;
		}
		print STDERR ref ($self) . "->processDOM: finished checking regular expression patterns\n"
			if $debug > 1;
		#
		#######################################################################

		print STDERR ref ($self) . "->processDOM: finished processing ExecutionInstructions. Writing them to DBObject Program\n"
			if $debug > 1;
		$newProgram->execution_instructions( $executionInstructionXML->toString() );
	}
	#
	#
	###########################################################################

	###########################################################################
	# commit this module. It's been successfully imported
	#
	print STDERR ref ($self) . "->processDOM: imported module '".$newProgram->program_name."' sucessfully. Committing to DB...\n"
		if $debug > 0;
	print STDERR ref ($self) . "->processDOM: committing DBObjects\n"
		if $debug > 2;
	while( my $DBObjectInstance = pop (@commitOnSuccessfulImport) ){
		print STDERR ref ($self) . "->processDOM: about to commit DBObject: $DBObjectInstance\n"
			if $debug > 2;
		$DBObjectInstance->writeObject;
		print STDERR ref ($self) . "->processDOM: successfully commited DBObject: $DBObjectInstance\n"
			if $debug > 2;
	}                             # commits all DBObjects
	print STDERR ref ($self) . "->processDOM: finished committing DBObjects\n"
		if $debug > 2;

	print STDERR ref ($self) . "->processDOM: committing changes to tables and columns\n"
		if $debug > 2;
	$session->DBH()->commit();    # new tables & columns written w/ this handle
	print STDERR ref ($self) . "->processDOM: finished committing changes to tables and columns\n"
		if $debug > 2;

	print STDERR ref ($self) . "->processDOM commit successful\n"
		if $debug > 0;
	#
	###########################################################################
	
	push(@newPrograms, $newProgram)

} # END foreach my $moduleXML( @modules )
	
	print STDERR ref ($self) . "->processDOM returning \n"
		if $debug > 0;
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
