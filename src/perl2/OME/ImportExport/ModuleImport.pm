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
	my $debug = $params{debug};
	
	print STDERR $proto . "->new called with parameters:\n\t" . join( "\n\t", map { $_."=>".$params{$_} } keys %params ) ."\n" 
		if $debug > 1;
	
	my @requiredParams = ('session');
	
	foreach (@requiredParams) {
		die ref ($class) . "->new called without required parameter '$_'"
			unless exists $params{$_}
	}

	my $self = {
		session => $params{session},
		debug   => $params{debug}
	};
	
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
	my $parser     = XML::LibXML->new();
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
	print STDERR ref ($self) . "->processDOM called to process " . scalar(@{$root->getElementsByTagName( "AnalysisModule" )} ) . " modules\n"
		if $debug > 0;


###############################################################################
#
# Make new tables, columns, and Attribute types
#
# semanticTypes is keyed by name, valued by DBObject AttributeType
my %semanticTypes;
# semanticColumns is a double keyed hash
#	keyed by {Attribute_Type.Name}->{Attribute_Column.Name}
#	valued by DBObject AttributeColumn
my %semanticColumns;

my $SemanticDefinitionsXML = $root->getElementsByTagName( "SemanticTypeDefinitions" )->[0];

	print STDERR ref ($self) . "->processDOM: about to process SemanticTypeDefinitions\n";

	###########################################################################
	#
	# Process Table and Column elements. Make new tables and columns as needed.
	#
	# dataColumns is a double keyed hash
	#	keyed by {Data_Type.Name}->{Data_Column.Name}
	#	valued by DBobject DataColumn
	my %dataColumns;

	print STDERR ref ($self) . "->processDOM: about to process tables and columns\n"
		if $debug > 1;
	foreach my $tableXML ( $SemanticDefinitionsXML->getElementsByTagName( "Table" ) ) {
		#######################################################################
		#
		# Process a Table
		#
		print STDERR ref ($self) . "->processDOM: looking for table ".$tableXML->getAttribute( 'TableName' )."\n"
			if $debug > 1;
		my @tables = $factory->findObjects( "OME::DataTable", 'table_name' => $tableXML->getAttribute( 'TableName' ) );
		
		my $newTable;
		if( scalar(@tables) == 0 ) { # the table doesn't exist. create it.
			print STDERR ref ($self) . "->processDOM: table not found. creating it.\n"
				if $debug > 1;
			my $data = {
				table_name  => $tableXML->getAttribute( 'TableName' ),
				description => $tableXML->getAttribute( 'Description' ),
				granularity => $tableXML->getAttribute( 'Granularity' )
			};
			print STDERR ref ($self) . "->processDOM: OME::DataTable DBObject parameters are\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
				if $debug > 1;
			$newTable = $factory->newObject( "OME::DataTable", $data )
				or die ref ($self) . " could not create OME::DataTable. name = " . $tableXML->getAttribute( 'TableName' );
			print STDERR ref ($self) . "->processDOM: successfully created OME::DataTable DBObject\n"
				if $debug > 1;

			###################################################################
			#
			# Make the table in the database. 
			# Should this functionality be moved to OME::Datatype 
			# so making a new entry there will cause a new table
			# to be created?
			#
			my $statement = "
				CREATE TABLE ".$newTable->table_name()." (
					ATTRIBUTE_ID	 OID DEFAULT NEXTVAL('ATTRIBUTE_SEQ') PRIMARY KEY,
					ANALYSIS_ID      OID REFERENCES ANALYSES DEFERRABLE INITIALLY DEFERRED,";
			if( $newTable->granularity() eq 'I' ) {
				$statement .= "IMAGE_ID      OID NOT NULL REFERENCES IMAGES DEFERRABLE INITIALLY DEFERRED";
			} elsif ( $newTable->granularity() eq 'D' ) {
				$statement .= "DATATSET_ID   OID NOT NULL REFERENCES DATASETS DEFERRABLE INITIALLY DEFERRED";
			} elsif ( $newTable->granularity() eq 'F' ) {
				$statement .= "FEATURE_ID    OID NOT NULL REFERENCES FEATURES DEFERRABLE INITIALLY DEFERRED";
			}
			$statement .= ")";
			print STDERR ref ($self) . "->processDOM: about to create table in DB using statement\n".$statement."\n"
				if $debug > 1;
			my $dbh = $session->DBH();
			my $sth = $dbh->prepare( $statement )
				or die "Could not prepare Table create statement when making table ".$newTable->table_name()."\nStatement was\n$statement";
			$sth->execute()
				or die "Unable to create table ".$newTable->table_name()."\n";
			print STDERR ref ($self) . "->processDOM: successfully created table\n"
				if $debug > 1;
			#
			#
			###################################################################

			push(@commitOnSuccessfulImport, $newTable);
		} else {
			print STDERR ref ($self) . "->processDOM: found table. using existing table.\n"
				if $debug > 1;
			$newTable = $tables[0];
		}
		#
		# END 'Process a Table'
		#
		########################################################################


		########################################################################
		#
		# Process columns in this table
		#
		print STDERR ref ($self) . "->processDOM: processing columns\n"
			if $debug > 1;
		foreach my $columnXML($tableXML->getElementsByTagName( "Column" ) ){
			my %dataTypeConversion = (
			#	XMLType  => SQL_Type
				integer  => 'integer',
				double   => 'double precision',
				float    => 'real',
				boolean  => 'boolean',
				string   => 'text',
				dateTime => 'timestamp'
				);
			$columnXML->setAttribute( 
				'SQL_DataType', 
				$dataTypeConversion{ $columnXML->getAttribute( 'SQL_DataType' ) }
			);

			
			print STDERR ref ($self) . "->processDOM: searching OME::DataTable::Column with\n\tdata_table_id=".$newTable->id()."\n\tcolumn_name=". $columnXML->getAttribute( 'ColumnName' )."\n"
				if $debug > 1;
#				my @cols = $factory->findObjects( "OME::DataTable::Column", {
#					data_table_id => $newTable->id(),
#					column_name   => $columnXML->getAttribute( 'ColumnName' )
#				});
# change this to a factory search after factory can take multi way searches
			require OME::DataTable;
			my @cols = OME::DataTable::Column->search( 
				data_table_id => $newTable->id(),
				column_name   => $columnXML->getAttribute( 'ColumnName' )
			);
			
			my $newColumn;
			if( scalar(@cols) == 0 ) {
				print STDERR ref ($self) . "->processDOM: could not find matching column. creating it\n"
					if $debug > 1;
				my $data     = {
					data_table_id  => $newTable,
					column_name    => $columnXML->getAttribute( 'ColumnName' ),
					description    => $columnXML->getAttribute( 'Description' ),
					sql_type       => $columnXML->getAttribute( 'SQL_DataType' )
				};
				print STDERR ref ($self) . "->processDOM: OME::DataTable::Column DBObject parameters are\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
					if $debug > 1;
				$newColumn = $factory->newObject( "OME::DataTable::Column", $data )
					or die "Could not create OME::DataType::Column object\n";
				print STDERR ref ($self) . "->processDOM: created OME::DataTable::Column DBObject\n"
					if $debug > 1;
		
				################################################################
				#
				# Create the column in the database. 
				# Should this functionality be moved to OME::DataTable::Column 
				# so making a new entry there will cause a new column
				# to be created?
				#
				my $statement =
					"ALTER TABLE ".$newTable->table_name().
					"	ADD ".$newColumn->column_name()." ".$columnXML->getAttribute( 'SQL_DataType' );
				my $dbh = $session->DBH();
				my $sth = $dbh->prepare( $statement )
					or die "Could not prepare statment when adding column ".$newColumn->column_name()." to table ".$newTable->table_name()."\nStatement:\n$statement";
				print STDERR ref ($self) . "->processDOM: about to create column in DB using statement\n$statement\n"
					if $debug > 1;
				$sth->execute()
					or die "Unable to create column ".$newColumn->column_name()." in table ".$newTable->table_name();
				print STDERR ref ($self) . "->processDOM: created column in db\n"
					if $debug > 1;
				#
				#
				################################################################
		
				push(@commitOnSuccessfulImport, $newColumn);
			} else {
				die "Found matching column with different sql data type."
					unless $cols[0]->sql_type() eq $columnXML->getAttribute( 'SQL_DataType' );
				print STDERR ref ($self) . "->processDOM: found column. using existing column.\n"
					if $debug > 1;
				$newColumn = $cols[0];
			}
			$dataColumns{$newTable->table_name()}->{ $newColumn->column_name()} =
				$newColumn;
		}
		#
		# END 'Process columns in this table'
		#
		########################################################################
		print STDERR ref ($self) . "->processDOM: finished processing columns in that table\n"
			if $debug > 1;
	}
	print STDERR ref ($self) . "->processDOM: finished processing tables\n"
		if $debug > 1;
	#
	# END 'Process Table and Column elements. Make new tables and columns as needed.'
	#
	###########################################################################

	###########################################################################
	#
	# Make AttributeTypes
	#
	print STDERR ref ($self) . "->processDOM: making new AttributeTypes from SemanticTypes\n"
		if $debug > 1;
	foreach my $semanticTypeXML ( $SemanticDefinitionsXML->getElementsByTagName( "SemanticType" ) ) {
		# look for existing AttributeType
		print STDERR ref ($self) . "->processDOM is looking for an OME::AttributeType object\n\t[name=]".$semanticTypeXML->getAttribute( 'Name' )."\n"
			if $debug > 1;
		my $existingAttrType = $factory->findObject( 
			"OME::AttributeType",
			name => $semanticTypeXML->getAttribute( 'Name' )
		);
		
		my $newAttrType;
		###########################################################################
		#
		# if AttributeType doesn't exist, create it
		#
		if( not defined $existingAttrType ) {
			print STDERR ref ($self) . "->processDOM: couldn't find it. creating it.\n"
				if $debug > 1;
			my $data = {
				name        => $semanticTypeXML->getAttribute('Name'),
				granularity => 'F',
				description => $semanticTypeXML->getAttribute( 'Description')
			};
			# Granularity is set properly below. DB set up won't let us use NULL for it and we don't have enough info to know what it is yet.
			print STDERR ref ($self) . "->processDOM: about to make a new OME::AttributeType. (granularity will be reset below) parameters are\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
				if $debug > 1;
			$newAttrType = $factory->newObject("OME::AttributeType",$data)
				or die ref ($self) . " could not create new object of type OME::AttributeType with parameters:\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n";
			print STDERR ref ($self) . "->processDOM: made a new OME::AttributeType object\n"
				if $debug > 1;
	
	
			#######################################################################
			#
			# make OME::AttributeType::Column objects
			#
			my $granularity;
			my $tableName;
			print STDERR ref ($self) . "->processDOM: about to make AttributeColumns from SemanticElements in this SemanticType\n"
				if $debug > 1;
			foreach my $SemanticElementXML ($semanticTypeXML->getElementsByTagName( "SemanticElement") ) {
				print STDERR ref ($self) . "->processDOM: processing attribute column,\n\tname=".$SemanticElementXML->getAttribute('Name')."\n"
					if $debug > 1;
				#check ColumnID
				die ref ($self) . " could not find entry for column '".$SemanticElementXML->getAttribute('ColumnName')."'\n"
					unless exists $dataColumns{$SemanticElementXML->getAttribute('TableName')}->{ $SemanticElementXML->getAttribute('ColumnName') };
			
				#check granularity
				my $attrColumnGranularity =
					$dataColumns{$SemanticElementXML->getAttribute('TableName')}->{ $SemanticElementXML->getAttribute('ColumnName') }->data_table()->granularity();
				$granularity = $attrColumnGranularity
					if (not defined $granularity);
				die ref ($self) . " SemanticType (name=".$semanticTypeXML->getAttribute('Name').") has elements with different granularities. Died on element (Name=".$SemanticElementXML->getAttribute('Name').", ColumnName=".$SemanticElementXML->getAttribute('ColumnName').") with granularity '$attrColumnGranularity'"
					unless $granularity eq $attrColumnGranularity;
					
				#check table
				$tableName = $SemanticElementXML->getAttribute('TableName')
					if (not defined $tableName);
				die ref ($self) . " SemanticType (name=".$semanticTypeXML->getAttribute('Name').") has elements in multiple tables. Died on column (Name=".$SemanticElementXML->getAttribute('Name').", ColumnName=".$SemanticElementXML->getAttribute('ColumnName').") in table '".$SemanticElementXML->getAttribute('TableName')."'"
					unless $tableName eq $SemanticElementXML->getAttribute('TableName');
				
				#create object
				my $newAttrColumn = $factory->newObject( "OME::AttributeType::Column", {
					attribute_type => $newAttrType,
					name           => $SemanticElementXML->getAttribute('Name'),
					data_column    => $dataColumns{$SemanticElementXML->getAttribute('TableName')}->{ $SemanticElementXML->getAttribute('ColumnName') },
					description    => $SemanticElementXML->getAttribute('Description')
				})
					or die ref ($self) . " could not create new OME::AttributeType::Column object, name = ". $SemanticElementXML->getAttribute('Name');
				
				$semanticColumns{$newAttrType->name()}->{ $newAttrColumn->name() } =
					$newAttrColumn;
				print STDERR ref ($self) . "->processDOM added entry to semanticColumns.\n\t".$newAttrType->name().".".$newAttrColumn->name()."=>".$semanticColumns{$newAttrType->name()}->{ $newAttrColumn->name() }."\n"
					if $debug > 1;
	
				push(@commitOnSuccessfulImport, $newAttrColumn);
				print STDERR ref ($self) . "->processDOM finished processing attribute column ".$newAttrColumn->name()."\n"
					if $debug > 1;
			}
			print STDERR ref ($self) . "->processDOM: finished making AttributeColumns from SemanticElements\n"
				if $debug > 1;
			#
			#
			#######################################################################
	
			$newAttrType->granularity( $granularity );
			print STDERR ref ($self) . "->processDOM: determined granularity. Setting granularity to '$granularity'. \n"
				if $debug > 1;
			push(@commitOnSuccessfulImport, $newAttrType);
                        # DC -> 3/24/2003
                        # The attribute types aren't getting committed
                        # unless there's a module declared.
                        $newAttrType->commit();
		}
		#
		# END "if AttributeType doesn't exist, create it"
		#
		###########################################################################
	
	
		###########################################################################
		#
		# AttributeType exists, verify that the attribute columns are identical
		#	also, populate formalInputColumn_xmlID_dbObject hash
		#
		else { 
			print STDERR ref ($self) . "->processDOM: found a OME::AttributeType object with matching name. inspecting it to see if it completely matches.\n"
				if $debug > 1;
			my @attrColumns = $existingAttrType->attribute_columns();
			die ref ($self) . " While processing Semantic Type (name=".$semanticTypeXML->getAttribute('Name')."), found existing AttributeType with same name and a different number of columns. Existing AttributeType has ".scalar(@attrColumns)." columns, new AttributeType of same name has ".scalar(@$semanticTypeXML->getElementsByTagName( "SemanticElement") )." columns."
				unless( scalar(@attrColumns) eq scalar(@ {$semanticTypeXML->getElementsByTagName( "SemanticElement")}) );
			foreach my $SemanticElementXML ($semanticTypeXML->getElementsByTagName( "SemanticElement") ) {
				#check ColumnID
				die ref ($self) . " While processing Semantic Type (name=".$semanticTypeXML->getAttribute('Name')."), could not find matching data column for ColumnName '".$SemanticElementXML->getAttribute('ColumnName')."'\n"
					unless exists $dataColumns{$SemanticElementXML->getAttribute('TableName')}->{ $SemanticElementXML->getAttribute('ColumnName') };
	
				#find existing AttributeType::Column object corrosponding to SemanticElementXML
				map {
					$semanticColumns{$existingAttrType->name()}->{ $SemanticElementXML->getAttribute( 'Name' ) } = $_
						if $dataColumns{$SemanticElementXML->getAttribute('TableName')}->{ $SemanticElementXML->getAttribute('ColumnName') }->id() eq $_->data_column()->id();
				} @attrColumns;
				print STDERR ref ($self) . "->processDOM: added entry to semanticColumns.\n\t".$newAttrType->name().".".$SemanticElementXML->getAttribute( 'Name' )."=>".$semanticColumns{$newAttrType->name()}->{ $SemanticElementXML->getAttribute( 'Name' ) }."\n"
					if $debug > 1;
	
				die ref ($self) . " While processing Semantic Type (name=".$existingAttrType->getAttribute('Name')."), found existing AttributeType with the same name. Could not find matching column in existing AttributeType for new AttributeColumn (Name=".$SemanticElementXML->getAttribute('Name').",ColumnName=".$SemanticElementXML->getAttribute('ColumnName').")."
					unless exists $semanticColumns{$existingAttrType->name()}->{ $SemanticElementXML->getAttribute( 'Name' ) };
			}
			$newAttrType = $existingAttrType;
			print STDERR ref ($self) . "->processDOM: determined the Attribute types match. using existing attribute type.\n"
				if $debug > 1;
		}
		#
		# END "AttributeType exists, verify that the attribute columns are identical"
		#
		###########################################################################

		$semanticTypes{ $newAttrType->name() } = $newAttrType;
		print STDERR ref ($self) . "->processDOM: finished processing semanticType ".$newAttrType->name()."\n"
			if $debug > 1;

	}
	#
	# END "Make AttributeTypes"
	#
	###########################################################################

	print STDERR ref ($self) . "->processDOM: finished processing SemanticTypeDefinitions\n"
			if $debug > 1;

#
# END 'Make new tables, columns, and Semantic types'
#
###############################################################################



foreach my $moduleXML ($root->getElementsByTagName( "AnalysisModule" )) {

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
	foreach my $formalInputXML ( $moduleXML->getElementsByTagName( "FormalInput" ) ) {
		print STDERR ref ($self) . "->processDOM is processing formal input, ".$formalInputXML->getAttribute('Name')."\n"
			if $debug > 1;


		#######################################################################
		#
		# make OME::LookupTable & OME::LookupTable::Entry objects
		#
		#
		my $newLookupTable;
		my @lookupTables = $formalInputXML->getElementsByTagName( "LookupTable" );
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
			my @entries = $lookupTableXML->getElementsByTagName( "LookupTableEntry" );
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
			unless exists $semanticTypes{ $formalInputXML->getAttribute( 'SemanticTypeName' ) };
		my $data = {
			name               => $formalInputXML->getAttribute( 'Name' ),
			description        => $formalInputXML->getAttribute( 'Description' ),
			program_id         => $newProgram,
			attribute_type_id  => $semanticTypes{ $formalInputXML->getAttribute( 'SemanticTypeName' ) },
			lookup_table_id    => $newLookupTable,
			#user_defined => $formalInputXML->getAttribute( 'UserDefined' )
			# this exists in the schema, and only in the schema.
			# we need to add it to the DB or remove from schema.
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
	foreach my $formalOutputXML ( $moduleXML->getElementsByTagName( "FormalOutput" ) ) {

		print STDERR ref ($self) . "->processDOM is processing formal output, ".$formalOutputXML->getAttribute('Name')."\n"
			if $debug > 1;

		###################################################################
		#
		# make OME::FormalOutput object
		#
		die "When processing Formal Output (name=".$formalOutputXML->getAttribute( 'Name' )."), could not find Semantic type referenced by ".$formalOutputXML->getAttribute( 'SemanticTypeName' )."\n"
			unless exists $semanticTypes{ $formalOutputXML->getAttribute( 'SemanticTypeName' ) };
		my $data = {
			name               => $formalOutputXML->getAttribute( 'Name' ),
			description        => $formalOutputXML->getAttribute( 'Description' ),
			program_id         => $newProgram,
			attribute_type_id  => $semanticTypes{ $formalOutputXML->getAttribute( 'SemanticTypeName' ) },
			feature_tag        => $formalOutputXML->getAttribute( 'IBelongTo' )
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
		$moduleXML->getElementsByTagName( "ExecutionInstructions" );
	
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
			push(@inputs, $executionInstructionXML->getElementsByTagName( $_ ));
		} @inputTypes;

		foreach my $input (@inputs) {
			my $formalInput    = $formalInputs{ $input->getAttribute( "FormalInputName" ) }
				or die "Could not find formal input referenced by element ".$input->tagName()." with FormalInputName ". $input->getAttribute( "FormalInputName");
			my $semanticType   = $formalInput->attribute_type();
			my $semanticElement = $semanticColumns{ $semanticType->name() }->{ $input->getAttribute( "SemanticElementName" ) }
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
			push(@outputs, $executionInstructionXML->getElementsByTagName( $_ ));
		} @outputTypes;

		foreach my $output (@outputs) {
			my $formalOutput    = $formalOutputs{ $output->getAttribute( "FormalOutputName" ) }
				or die "Could not find formal output referenced by element ".$output->tagName()." with FormalOutputName ". $output->getAttribute( "FormalOutputName");
			my $semanticType   = $formalOutput->attribute_type();
			my $semanticElement = $semanticColumns{ $semanticType->name() }->{ $output->getAttribute( "SemanticElementName" ) }
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
		foreach my $plane($executionInstructionXML->getElementsByTagName( "XYPlane" ) ) {
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
		foreach my $match ( $executionInstructionXML->getElementsByTagName( "Match" ) ) {
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
		my @pats =  $executionInstructionXML->getElementsByTagName( "pat" );
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
