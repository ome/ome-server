package OME::Tasks::ProgramImport;

use XML::LibXML;
use strict;

=head1 NAME

OME::Tasks::ProgramImport - Process an Analysis Module XML specification.

=head1 SYNOPSIS

	use OME::Tasks::ProgramImport;
	OME::Tasks::ProgramImport->importXMLFile( $filePath );

=head1 DESCRIPTION

This module automates the module import process. Given an XML specification
of a module, this will import it into the OME system.
Specifically, it will:
install the module onto the local system
register the module with the database
add any custom tables & columns (to the DB) that the module requires


=head1 AUTHOR

Josiah Johnston (siah@nih.gov)

=head1 SEE ALSO

AnalysisModule.xsd

=cut


#####################################################
#
#   !!!!!!!!!!------ HACK ALERT -----!!!!!!!!	
#
# Problem is creating tables & columns. Checking for
# existence of tables & columns with the db handle I'm writing with
# causes some sort of sticky condition (probably
# an Error condition) that prevents me from creating tables or inserting columns.
# The only way I've found out of that is call a rollback. But that screws up the
# transaction I'm working on.
# Making another database handle to query for table existence is the only solution
# I can think of. The way I've done this is most definately a hack.
#
# This is ok because the test won't be necessary in the future.
# Eventually, every table a module can use as an input or output
# will be registered with DataTypes if it exists. That might be
# the case at this point for all I know. But it hasn't been discussed,
# so I'm taking precautions.

require DBI;
require OME::DBConnection;
my $dbhQ = DBI->connect( OME::DBConnection->DataSource(),
                OME::DBConnection->DBUser(),
               OME::DBConnection->DBPassword() );

#
#####################################################



######################################################
#
# parameter(s) are:
#	$session - an OME::Session object
#	$filePath
#
sub importXMLFile {
	my $self     = shift;
	my $session  = shift;
	my $filePath = shift;

	my $parser = XML::LibXML->new();
	#Validate file against Schema
	{
	# insert code here
	};

	#Parse
	my $tree = $parser->parse_file( $filePath );

	#process tree
	processDOM( $session, $tree->getDocumentElement() );

	#return ...what?
	# maybe list of all new OME::Programs objects
}
#
#
######################################################
my $commitNow =undef;


######################################################
#
# Process DOM tree
# parameter(s):
#	$session - an OME::Session object
#	$root element (DOM model)
#
sub processDOM {
	my $session = shift;
	my $root    = shift;
	my $factory = $session->Factory();

my @modules = $root->getElementsByTagName( "AnalysisModule" );
foreach my $module (@modules) {

	##################################################
	#
	# make OME::Programs object
	#
# use find_or_create instead ? ? ? ?
	my @programs = $factory->findObjects( "OME::Program", 
		'program_name', $module->getAttribute( 'ModuleName' ) );
	die "\nCannot add module ". $module->getAttribute( 'ModuleName' ) . ". A module of the same name already exists.\n"
		unless scalar (@programs) eq 0;
	my $data = {
		program_name     => $module->getAttribute( 'ModuleName' ),
		description      => $module->getAttribute( 'Description' ),
		category         => $module->getAttribute( 'Category' ),
		module_type      => $module->getAttribute( 'ModuleType' ),
		# this location biz is a temporary hack
		location         => $module->getAttribute( 'ProgramID' ),
		default_iterator => $module->getAttribute( 'FeatureIterator' ),
		new_feature_tag  => $module->getAttribute( 'NewFeatureName' ),
		#visual_design => $module->getAttribute( 'VisualDesign' )
		# visual design is not implemented in the api. I think it is depricated.
	};
	my $program = $factory->newObject("OME::Program",$data)
		or die "Could not create OME::Program object\n";
	$program->writeObject() if $commitNow;
	#
	#
	##################################################
	
	##################################################
	#
	# process TableDefinitions. Maybe make new tables.
	#
	my %table_xmlID_object;
	{
		foreach my $table ( $module->getElementsByTagName( "TableDefinition" ) ) {
# move all this functionality to OME::DataType?
			my @tables = $factory->findObjects( "OME::DataType", 'table_name' => $table->getAttribute( 'TableName' ) );
			
			my $newTable;
			if( scalar(@tables) == 0 ) {
				my $data = {
					table_name     => $table->getAttribute( 'TableName' ),
					description    => $table->getAttribute( 'Description' ),
					attribute_type => $table->getAttribute( 'AttributeType' )
				};
				$newTable = $factory->newObject( "OME::DataType", $data )
					or die "Could not create OME::DataType\n";
				$newTable->writeObject() if $commitNow;
# In the future, the following test will not be necessary because every table a module
# can access will have a corrosponding entry in the Datatypes table. We have
# just checked for an entry and found none. For now, this rule may not be universally true.
# Thus the test.
				my $dbh = $session->DBH();
				my $sth = $dbhQ->prepare( "SELECT * from ".$table->getAttribute( 'TableName' )." limit 1;" );
				$sth->{RaiseError} = 0;
				my $tableExists = $sth->execute();
				if( not defined $tableExists ) { 
					# rollback to escape error caused by selecting a non-existent table
					$dbhQ->rollback();
					my $sth = $dbh->prepare( "
						CREATE TABLE ".$table->getAttribute( 'TableName' )." (
							ATTRIBUTE_ID	OID DEFAULT NEXTVAL('ATTRIBUTE_SEQ') PRIMARY KEY
						)")
						or die "Table create statement failed when making table ".$table->getAttribute( 'TableName' )."\n";
# are there any other mandatory columns? row based schema wants actual_output_id. 
					$sth->execute()
						or die "Unable to create table ".$table->getAttribute( 'TableName' )."\n";
				}
			} else {
				$newTable = $tables[0];
			}

			$table_xmlID_object{ $table->getAttribute( 'TableID' ) } =
				$newTable;
		}
	}
	#
	#
	##################################################
	
	##################################################
	#
	# process formalInputs 
	#
	my %formalInput_xmlID_dbID;
	{
		foreach my $formalInput ( $module->getElementsByTagName( "FormalInput" ) ) {
			
			##########################################
			#
			# make OME::DataTypeColumn object from DBLocation element
			#
			my $dbLocation = $formalInput->getElementsByTagName( "DBLocation" )->[0];
			my $DataTypeColumn = makeDataTypeColumn($session, $dbLocation, { %table_xmlID_object});
			#
			##########################################
			
			##########################################
			#
			# make OME::LookupTable & OME::LookupTable::Entry objects
			#
			my $lookupTable;
			my @lookupTables = $formalInput->getElementsByTagName( "LookupTable" );
			# lookupTables may or may not exist. Either way is fine.
			if( scalar( @lookupTables ) == 1 ) {

				#####################################
				#
				# make OME::LookupTable object
				#
				my $lookupTableXML = $lookupTables[0];
				my $data = {
					name        => $lookupTableXML->getAttribute( 'Name' ),
					description => $lookupTableXML->getAttribute( 'Description' )
				};
				$lookupTable = $factory->newObject( "OME::LookupTable", $data )
					or die "Could not make OME::LookupTable object\n";
				$lookupTable->writeObject() if $commitNow;
				#
				#####################################

				#####################################
				#
				# make OME::LookupTable::Entry objects
				#
				my @entries = $lookupTable->getElementsByTagName( "LookupTableEntry" );
				foreach my $entry (@entries) {
					my $data = {
						value           => $entry->getAttribute( 'Value' ),
						label           => $entry->getAttribute( 'Label' ),
						lookup_table_id => $lookupTable->ID()
					};
					my $lookupEntry = $factory->newObject( "OME::LookupTable::Entry", $data )
						or die "Could not make OME::LookupTable::Entry object\n";
					$lookupEntry->writeObject() if $commitNow;
				}
				#
				######################################
			}
			#
			#
			##########################################

			##########################################
			#
			# make OME::FormalInput object
			#
			my $data = {
				name               => $formalInput->getAttribute( 'Name' ),
				description        => $formalInput->getAttribute( 'Description' ),
				program_id         => $program,
				datatype_id => $DataTypeColumn->datatype->id(),
				lookup_table_id    => $lookupTable,
				#user_defined => $formalInput->getAttribute( 'UserDefined' )
				# this exists in the schema, and only in the schema.
				# we need to add it to other places or remove from schema.
			};
			my $newFormalInput = $factory->newObject( "OME::Program::FormalInput", $data )
				or die "Could not make OME::Program::FormalInput object\n";
			$newFormalInput->writeObject() if $commitNow;
			#
			#
			##########################################
			
			# add dbID to reference list.
			$formalInput_xmlID_dbID{ $formalInput->getAttribute( "FormalInputID" ) }
				= $newFormalInput->ID();
		}
	}
	#
	#
	##################################################
	

	##################################################
	#
	# process formalOutputs
	#
	my %formalOutput_xmlID_dbID;
	{
		foreach my $formalOutput ( $module->getElementsByTagName( "FormalOutput" ) ) {

			##########################################
			#
			# make OME::DataTypeColumn object from DBLocation element
			#
			my $dbLocation = $formalOutput->getElementsByTagName( "DBLocation" )->[0];
			my $DataTypeColumn = makeDataTypeColumn($session, $dbLocation, { %table_xmlID_object});
			#
			##########################################

			##########################################
			#
			# make OME::FormalOutput object
			#
			my $data = {
				name               => $formalOutput->getAttribute( 'Name' ),
				description        => $formalOutput->getAttribute( 'Description' ),
				program_id         => $program,
				datatype_id        => $DataTypeColumn->datatype->id(),
				feature_tag        => $formalOutput->getAttribute( 'IBelongTo' )
			};
			my $newFormalOutput = $factory->newObject( "OME::Program::FormalOutput", $data )
				or die "Could not make OME::Program::FormalOutput object\n";
			$newFormalOutput->writeObject() if $commitNow;
			#
			##########################################

			# add dbID to reference list.
			$formalOutput_xmlID_dbID{ $formalOutput->getAttribute( "FormalOutputID"	) } = 
				$newFormalOutput->ID();
		}
	}
	#
	#
	##################################################
	
	
	##################################################
	#
	# process executionInstructions 
	#
	my @executionInstructions = 
		$module->getElementsByTagName( "ExecutionInstructions" );
	
	# XML schema & DBdesign currently allow at most one execution point per module
	if(scalar(@executionInstructions) == 1) {
		my $executionInstruction = $executionInstructions[0];

		##############################################
		#
		# replace FormalInputID's with ID's from DB
		#
		my @inputs = (
			$executionInstruction->getElementsByTagName( "Input" ),
			$executionInstruction->getElementsByTagName( "theZ" ),
			$executionInstruction->getElementsByTagName( "theT" ),
			$executionInstruction->getElementsByTagName( "theW" ) );
		foreach my $inputType (@inputs) {
			foreach my $input (@$inputType) {
				$input->setAttribute( "FormalInputID",
									  $formalInput_xmlID_dbID {
										  $input->getAttribute( "FormalInputID" )});
			}
		}
		#
		##############################################
	
		##############################################
		#
		# replace FormalOutputID's with ID's from DB
		#
		my @outputs = $executionInstruction->getElementsByTagName( "Output" );
		foreach my $output (@outputs) {
			$output->setAttribute( "FormalOutputID",
								  $formalOutput_xmlID_dbID {
									  $output->getAttribute( "FormalOutputID" )});
		}
		#
		##############################################
		
		# save executionInstructions to DB
		$program->execution_instructions( $executionInstruction->toString() );
		$program->writeObject() if $commitNow;
	}
	#
	#
	##################################################

	# commit this module. It's been successfully imported
	$program->writeObject();   # *hopefully* reliably commits all DBObjects
	$session->DBH()->commit(); # new tables & columns written w/ this handle

} # END foreach my $module( @modules )

} # END sub processDOM
#
#
######################################################

sub makeDataTypeColumn {
	my ($session, $dbLocation, $table_xmlID_object) = @_;
	my $factory = $session->Factory();
	my %dataTypeConversion = (
#       XMLType  => SQL_Type
		integer  => 'integer',
		double   => 'double precision',
		float    => 'real',
		boolean  => 'boolean',
		string   => 'text',
		dateTime => 'timestamp'
		);
	
	die "TableID entry not found for dbLocation.column_name= ".$dbLocation->getAttribute( 'ColumnName' ).", TableID= ".$dbLocation->getAttribute( 'TableID' )."\n"
		unless exists $table_xmlID_object->{ $dbLocation->getAttribute( 'TableID' ) };

	# change this to a factory search after factory can take multi way searches
	require OME::DataType;
	my @cols = OME::DataType::Column->search( 
		datatype_id => $table_xmlID_object->{ $dbLocation->getAttribute( 'TableID' ) }->id(),
		column_name => $dbLocation->getAttribute( 'ColumnName' )
	);
	
	my $DataTypeColumn;
	if( scalar(@cols) == 0 ) {
		my $data     = {
			datatype_id    => $table_xmlID_object->{ $dbLocation->getAttribute( 'TableID' ) }->id(),
			column_name    => $dbLocation->getAttribute( 'ColumnName' ),
			description    => $dbLocation->getAttribute( 'Description' ),
			reference_type => $dbLocation->getAttribute( 'ReferenceType' ),
			#column_sql     => $dbLocation->getAttribute( 'Column_SQL' )
			# column sql only exists in the schema. it needs to be added to other places or removed from the schema.
		};
		$DataTypeColumn = $factory->newObject( "OME::DataType::Column", $data )
			or die "Could not make OME::DataType::Column object\n";
# In the future, the following test will not be necessary because every column a module
# can access will have a corrosponding entry in the Datatype_column table. We have
# just looked for an entry and found none. For now, this rule may not be universally true.
# Thus the test.
		my $dbh = $session->DBH();
		my $sth = $dbhQ->prepare( "SELECT ".$DataTypeColumn->column_name()." from ".$table_xmlID_object->{ $dbLocation->getAttribute( 'TableID' ) }->table_name()." limit 1;" );
		$sth->{RaiseError} = 0;
		my $err = $sth->execute();
		if( not defined $err ) { 
			# rollback to escape error caused by selecting a non-existent column
			$dbhQ->rollback();
			my $sth = $dbh->prepare( 
				"ALTER TABLE ".$table_xmlID_object->{ $dbLocation->getAttribute( 'TableID' ) }->table_name().
				"	ADD ".$DataTypeColumn->column_name()." ".$dataTypeConversion{$dbLocation->getAttribute( 'SQL_DataType' )}
			);
			$sth->execute()
				or die "Unable to create column ".$DataTypeColumn->column_name()." in table ".$table_xmlID_object->{ $dbLocation->getAttribute( 'TableID' ) }->table_name();
		}
		$DataTypeColumn->writeObject() if $commitNow;
	} else {
		$DataTypeColumn = $cols[0];
	}
	return $DataTypeColumn;
}

1;