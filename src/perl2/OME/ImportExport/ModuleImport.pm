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

Attribute Type processing, currently performed 2 places in the processDOM function, should be merged and moved to a separate function. 

Should verify that they are using every table and column they declare. 

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
	
	###########################################################################
	#
	# Process Table and Column elements. Make new tables and columns as needed.
	#
	# this hash is keyed by xml id, valued by DBobjects
	my %column_xmlID_object;
	{
		print STDERR ref ($self) . "->processDOM is about to process tables and columns\n"
			if $debug > 1;
		#######################################################################
		#
		# Process Table
		#
		foreach my $tableXML ( $moduleXML->getElementsByTagName( "Table" ) ) {
			print STDERR ref ($self) . "->processDOM looking for table ".$tableXML->getAttribute( 'TableName' )."\n"
				if $debug > 1;
			my @tables = $factory->findObjects( "OME::DataTable", 'table_name' => $tableXML->getAttribute( 'TableName' ) );
			
			my $newTable;
			if( scalar(@tables) == 0 ) { # the table doesn't exist. create it.
				print STDERR ref ($self) . "->processDOM table not found. creating it.\n"
					if $debug > 1;
				my $data = {
					table_name  => $tableXML->getAttribute( 'TableName' ),
					description => $tableXML->getAttribute( 'Description' ),
					granularity => $tableXML->getAttribute( 'Granularity' )
				};
				print STDERR ref ($self) . "->processDOM OME::DataTable DBObject parameters are\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
					if $debug > 1;
				$newTable = $factory->newObject( "OME::DataTable", $data )
					or die ref ($self) . " could not create OME::DataTable. name = " . $tableXML->getAttribute( 'TableName' );
				print STDERR ref ($self) . "->processDOM created OME::DataTable DBObject\n"
					if $debug > 1;

				##############################################################
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
# I believe ACTUAL_OUTPUT_ID will not stick around much longer. After analysisEngine no longer needs it, it should be removed.
				if( $newTable->granularity() eq 'I' ) {
					$statement .= "IMAGE_ID      OID NOT NULL REFERENCES IMAGES DEFERRABLE INITIALLY DEFERRED";
				} elsif ( $newTable->granularity() eq 'D' ) {
					$statement .= "DATATSET_ID   OID NOT NULL REFERENCES DATASETS DEFERRABLE INITIALLY DEFERRED";
				} elsif ( $newTable->granularity() eq 'F' ) {
					$statement .= "FEATURE_ID    OID NOT NULL REFERENCES FEATURES DEFERRABLE INITIALLY DEFERRED";
				}
				$statement .= ")";
				print STDERR ref ($self) . "->processDOM about to create table in DB using statement\n".$statement."\n"
					if $debug > 1;
				my $dbh = $session->DBH();
				my $sth = $dbh->prepare( $statement )
					or die "Table create statement failed when making table ".$newTable->table_name()."\n";
				$sth->execute()
					or die "Unable to create table ".$newTable->table_name()."\n";
				print STDERR ref ($self) . "->processDOM successfully created table\n"
					if $debug > 1;
				#
				#
				##############################################################

				push(@commitOnSuccessfulImport, $newTable);
			} else {
				print STDERR ref ($self) . "->processDOM found table. using existing table.\n"
					if $debug > 1;
				$newTable = $tables[0];
			}

			#
			#
			###################################################################



			##############################################################
			#
			# Process columns in this table
			#
			print STDERR ref ($self) . "->processDOM is processing columns\n"
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
				
			
# change this to a factory search after factory can take multi way searches
# add column_sql to the search after it is represented int the database
				print STDERR ref ($self) . "->processDOM is searching OME::DataTable::Column with\n\tdata_table_id=".$newTable->id()."\n\tcolumn_name=". $columnXML->getAttribute( 'ColumnName' )."\n"
					if $debug > 1;
				require OME::DataTable;
				my @cols = OME::DataTable::Column->search( 
					data_table_id => $newTable->id(),
					column_name   => $columnXML->getAttribute( 'ColumnName' )
				);
				
                                my $desiredSQLType = $columnXML->getAttribute('SQL_DataType');

				my $newColumn;
				if( scalar(@cols) == 0 ) {
					print STDERR ref ($self) . "->processDOM could not find matching column. creating it\n"
						if $debug > 1;
					my $data     = {
						data_table_id  => $newTable,
						column_name    => $columnXML->getAttribute( 'ColumnName' ),
						description    => $columnXML->getAttribute( 'Description' ),
                                                sql_type       => $desiredSQLType,
						#column_sql     => $columnXML->getAttribute( 'Column_SQL' )
# Do we need to store column_sql in the database?
# What if two modules declare a column in the same table with the same name, but the
# columns have different types? We need to check for that and die if it happens.
# Can we check for this if the data type isn't explicetly stored?
					};
					print STDERR ref ($self) . "->processDOM OME::DataTable::Column DBObject parameters are\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
						if $debug > 1;
					$newColumn = $factory->newObject( "OME::DataTable::Column", $data )
						or die "Could not create OME::DataType::Column object\n";
					print STDERR ref ($self) . "->processDOM created OME::DataTable::Column DBObject\n"
						if $debug > 1;
			
					#####################################################################
					#
					# Create the column in the database. 
					# Should this functionality be moved to OME::DataTable::Column 
					# so making a new entry there will cause a new column
					# to be created?
					#
					my $statement =
						"ALTER TABLE ".$newTable->table_name().
						"	ADD ".$newColumn->column_name()." ".$dataTypeConversion{$desiredSQLType};
					my $dbh = $session->DBH();
					my $sth = $dbh->prepare( $statement );
					print STDERR ref ($self) . "->processDOM about to create column in DB using statement\n$statement\n"
						if $debug > 1;
					$sth->execute()
						or die "Unable to create column ".$newColumn->column_name()." in table ".$newTable->table_name();
					print STDERR ref ($self) . "->processDOM created column in db\n"
						if $debug > 1;
					#
					#
					#####################################################################
			
					push(@commitOnSuccessfulImport, $newColumn);
				} else {
					print STDERR ref ($self) . "->processDOM found column. using existing column.\n"
						if $debug > 1;
					$newColumn = $cols[0];
                                        die "Desired SQL type does not match existing database column"
                                          if ($newColumn->sql_type() ne $desiredSQLType);
				}
				$column_xmlID_object{ $columnXML->getAttribute('ColumnID')} =
					$newColumn;
			}
			#
			# END 'Process columns in this table'
			#
			##############################################################
			print STDERR ref ($self) . "->processDOM finished processing columns in that table\n"
				if $debug > 1;
		}
		print STDERR ref ($self) . "->processDOM finished processing tables\n"
			if $debug > 1;
	}
	#
	#
	##########################################################################
	
	
	##########################################################################
	#
	# process formalInputs 
	#
	# this hash is keyed by xml id, valued by DBobjects
	my %formalInputColumn_xmlID_dbObject;
	# this hash is keyed by FormalInputColumn's xml id, valued by FormalInput.Name corrosponding to this FormalInputColumn
	my %formalInputColumn_xmlID_FormalInput;

	print STDERR ref ($self) . "->processDOM about to process formal inputs\n"
		if $debug > 1;
	foreach my $formalInputXML ( $moduleXML->getElementsByTagName( "FormalInput" ) ) {
		print STDERR ref ($self) . "->processDOM is processing formal input, ".$formalInputXML->getAttribute('Name')."\n"
			if $debug > 1;
		# look for existing AttributeType
		print STDERR ref ($self) . "->processDOM is looking for an OME::AttributeType object\n\t[name=]".$formalInputXML->getAttribute( 'AttributeTypeName' )."\n"
			if $debug > 1;
		my $existingAttrType = $factory->findObject( 
			"OME::AttributeType",
			name => $formalInputXML->getAttribute( 'AttributeTypeName' )
		);
		
		my $newAttrType;
		#######################################################################
		#
		# if AttributeType doesn't exist, create it
		#
		if( not defined $existingAttrType ) {
			print STDERR ref ($self) . "->processDOM couldn't find it. creating it.\n"
				if $debug > 1;
			my $data = {
				name        => $formalInputXML->getAttribute('AttributeTypeName'),
				granularity => 'F',
				description => $formalInputXML->getAttribute( 'Description')
			};
			# Granularity is really set below
			print STDERR ref ($self) . "->processDOM is about to make a new OME::AttributeType. (granularity will be reset below) parameters are\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
				if $debug > 1;
			$newAttrType = $factory->newObject("OME::AttributeType",$data)
				or die ref ($self) . " could not create new object of type OME::AttributeType with parameters:\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n";
			print STDERR ref ($self) . "->processDOM made a new OME::AttributeType object\n"
				if $debug > 1;


			###################################################################
			#
			# make OME::AttributeType::Column objects
			#
			my $granularity;
			my $table;
			print STDERR ref ($self) . "->processDOM is about to process attribute columns in this attribute\n"
				if $debug > 1;
			foreach my $attrColumnXML ($formalInputXML->getElementsByTagName( "FormalInputColumn") ) {
				print STDERR ref ($self) . "->processDOM is processing attribute column,\n\tname=".$attrColumnXML->getAttribute('Name')."\n"
					if $debug > 1;
				#check ColumnID
				die ref ($self) . " could not find entry for column '".$attrColumnXML->getAttribute('ColumnID')."'\n"
					unless exists $column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') };
			
				#check granularity
				my $attrColumnGranularity =
					$column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') }->data_table->granularity();
				$granularity = $attrColumnGranularity
					if (not defined $granularity);
				die ref ($self) . " Formal Input (name=".$formalInputXML->getAttribute('Name').") has columns of multiple granularities. Died on column (Name=".$attrColumnXML->getAttribute('name').", ColumnID=".$attrColumnXML->getAttribute('ColumnID').") with granularity '$attrColumnGranularity'"
					unless $granularity eq $attrColumnGranularity;
					
				#check table
				my $attrColumnTable =
					$column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') }->data_table;
				$table = $attrColumnTable
					if (not defined $table);
				die ref ($self) . " Formal Input (name=".$formalInputXML->getAttribute('Name').") has columns in multiple tables. Died on column (Name=".$attrColumnXML->getAttribute('name').", ColumnID=".$attrColumnXML->getAttribute('ColumnID').") in table '".$attrColumnTable->table_name()."'"
					unless $table->id() eq $attrColumnTable->id();
				
				#create object
				my $newAttrColumn = $factory->newObject( "OME::AttributeType::Column", {
					attribute_type => $newAttrType,
					name           => $attrColumnXML->getAttribute('Name'),
					data_column    => $column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') },
					description    => $attrColumnXML->getAttribute('Description')
				})
					or die ref ($self) . " could not create new OME::AttributeType::Column object, name = ". $attrColumnXML->getAttribute('Name');
				
				$formalInputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) } =
					$newAttrColumn;
				print STDERR ref ($self) . "->processDOM added entry to formalInputColumn_xmlID_dbObject.\n\t".$attrColumnXML->getAttribute( 'FormalInputColumnID' )."=>".$formalInputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) }."\n"
					if $debug > 1;

#				$formalInputColumn_xmlID_FormalInput{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) } =
#					$formalInputXML->getAttribute( 'Name' );
#				print STDERR ref ($self) . "->processDOM added entry to formalInputColumn_xmlID_FormalInput.\n\t".$attrColumnXML->getAttribute( 'FormalInputColumnID' )."=>".$formalInputColumn_xmlID_FormalInput{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) }."\n"
#					if $debug > 1;
					
				push(@commitOnSuccessfulImport, $newAttrColumn);
				print STDERR ref ($self) . "->processDOM finished processing attribute column\n"
					if $debug > 1;
			}
			#
			#
			###################################################################

			$newAttrType->granularity( $granularity );
			print STDERR ref ($self) . "->processDOM determined granularity. Setting granularity to '$granularity'. \n"
				if $debug > 1;
			push(@commitOnSuccessfulImport, $newAttrType);
		}
		#
		# END "if AttributeType doesn't exist, create it"
		#
		#######################################################################


		#######################################################################
		#
		# AttributeType exists, verify that the attribute columns are identical
		#	also, populate formalInputColumn_xmlID_dbObject hash
		#
		else { 
			print STDERR ref ($self) . "->processDOM found a matching OME::AttributeType object. inspecting it to see if it matches.\n"
				if $debug > 1;
			my @attrColumns = $existingAttrType->attribute_columns();
			die ref ($self) . " While processing formal input (name=".$formalInputXML->getAttribute('Name')."), found existing AttributeType with same AttributeTypeName (".$formalInputXML->getAttribute('AttributeTypeName').") but differing number of columns. Existing AttributeType has ".scalar(@attrColumns)." columns, new AttributeType of same name has ".scalar(@$formalInputXML->getElementsByTagName( "FormalInputColumn") )."columns."
				unless( scalar(@attrColumns) eq scalar(@ {$formalInputXML->getElementsByTagName( "FormalInputColumn")}) );
			foreach my $attrColumnXML ($formalInputXML->getElementsByTagName( "FormalInputColumn") ) {
				#check ColumnID
				die ref ($self) . " While processing formal input (name=".$formalInputXML->getAttribute('Name')."), could not find entry for columnID '".$attrColumnXML->getAttribute('ColumnID')."'\n"
					unless exists $column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') };

				#find existing AttributeType::Column object corrosponding to attrColumnXML
				map {
					$formalInputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) } = $_
						if $column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') }->id() eq $_->data_column()->id();
				} @attrColumns;
				print STDERR ref ($self) . "->processDOM added entry to formalInputColumn_xmlID_dbObject.\n\t".$attrColumnXML->getAttribute( 'FormalInputColumnID' )."=>".$formalInputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) }."\n"
					if $debug > 1;

#				$formalInputColumn_xmlID_FormalInput{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) } =
#					$formalInputXML->getAttribute( 'Name' );
#				print STDERR ref ($self) . "->processDOM added entry to formalInputColumn_xmlID_FormalInput.\n\t".$attrColumnXML->getAttribute( 'FormalInputColumnID' )."=>".$formalInputColumn_xmlID_FormalInput{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) }."\n"
#					if $debug > 1;

				die ref ($self) . " While processing FormalInput (name=".$formalInputXML->getAttribute('Name')."), found existing AttributeType of same AttributeTypeName (".$formalInputXML->getAttribute('AttributeTypeName')."). Could not find matching column in existing AttributeType for new column (Name=".$attrColumnXML->getAttribute('Name').",ColumnID=".$attrColumnXML->getAttribute('ColumnID').")."
					unless exists $formalInputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalInputColumnID' ) };
			}
			$newAttrType = $existingAttrType;
			print STDERR ref ($self) . "->processDOM determined the Attribute types match. using existing attribute type.\n"
				if $debug > 1;
		}
		#
		# END "AttributeType exists, verify that the attribute columns are identical"
		#
		#######################################################################


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
		my $data = {
			name               => $formalInputXML->getAttribute( 'Name' ),
			description        => $formalInputXML->getAttribute( 'Description' ),
			program_id         => $newProgram,
			attribute_type_id  => $newAttrType,
			lookup_table_id    => $newLookupTable,
			#user_defined => $formalInputXML->getAttribute( 'UserDefined' )
			# this exists in the schema, and only in the schema.
			# we need to add it to other places or remove from schema.
		};
		my $newFormalInput = $factory->newObject( "OME::Program::FormalInput", $data )
			or die ref ($self) . " could not create OME::Program::FormalInput object (name=".$formalInputXML->getAttribute( 'Name' ).")\n";

		map{
			$formalInputColumn_xmlID_FormalInput{ $_->getAttribute("FormalInputColumnID") } = $newFormalInput
		} @{$formalInputXML->getElementsByTagName( "FormalInputColumn")};
		print STDERR ref ($self) . "->processDOM added entries to formalInputColumn_xmlID_FormalInput.\n\t".
			join( "\n\t", 
				map{
					$_->getAttribute("FormalInputColumnID")." => ".$formalInputColumn_xmlID_FormalInput{$_->getAttribute("FormalInputColumnID")}
				} @{$formalInputXML->getElementsByTagName( "FormalInputColumn")}
			)."\n"
			if $debug > 1;

		push(@commitOnSuccessfulImport, $newFormalInput);
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
	# this hash is keyed by xml id, valued by DBobjects
	my %formalOutputColumn_xmlID_dbObject;
	# this hash is keyed by FormalOutputColumn's xml id, valued by Name of the FormalIOutput that contains this FormalOutputColumn
	my %formalOutputColumn_xmlID_FormalOutput;

	print STDERR ref ($self) . "->processDOM about to process formal outputs\n"
		if $debug > 1;
	foreach my $formalOutputXML ( $moduleXML->getElementsByTagName( "FormalOutput" ) ) {

		print STDERR ref ($self) . "->processDOM is processing formal output, ".$formalOutputXML->getAttribute('Name')."\n"
			if $debug > 1;
		# look for existing AttributeType
		print STDERR ref ($self) . "->processDOM is looking for an OME::AttributeType object\n\t[name=]".$formalOutputXML->getAttribute( 'AttributeTypeName' )."\n"
			if $debug > 1;
		my $existingAttrType = $factory->findObject( 
			"OME::AttributeType",
			name => $formalOutputXML->getAttribute( 'AttributeTypeName' )
		);
		
		my $newAttrType;
		#######################################################################
		#
		# if AttributeType doesn't exist, create it
		#
		if( not defined $existingAttrType ) {
			print STDERR ref ($self) . "->processDOM couldn't find it. creating it.\n"
				if $debug > 1;
			my $data = {
				name        => $formalOutputXML->getAttribute('AttributeTypeName'),
				granularity => 'F',
				description => $formalOutputXML->getAttribute( 'Description')
			};
			# Granularity is set below
			print STDERR ref ($self) . "->processDOM is about to make a new OME::AttributeType. (granularity will be reset below) parameters are\n\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
				if $debug > 1;
			$newAttrType = $factory->newObject("OME::AttributeType",$data)
				or die ref ($self) . " could not create new object of type OME::AttributeType with parameters:\n	name => ".
					$formalOutputXML->getAttribute('AttributeTypeName');
			print STDERR ref ($self) . "->processDOM made a new OME::AttributeType object\n"
				if $debug > 1;


			###################################################################
			#
			# make OME::AttributeType::Column objects
			#
			my $granularity;
			my $table;
			print STDERR ref ($self) . "->processDOM is about to process attribute columns in this attribute\n"
				if $debug > 1;
			foreach my $attrColumnXML ($formalOutputXML->getElementsByTagName( "FormalOutputColumn") ) {
				print STDERR ref ($self) . "->processDOM is processing attribute column,\n\tname=".$attrColumnXML->getAttribute('Name')."\n"
					if $debug > 1;
				#check ColumnID
				die ref ($self) . " could not find entry for column '".$attrColumnXML->getAttribute('ColumnID')."'\n"
					unless exists $column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') };
			
				#check granularity
				my $attrColumnGranularity =
					$column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') }->data_table->granularity();
				$granularity = $attrColumnGranularity
					if (not defined $granularity);
				die ref ($self) . " Formal Output (name=".$formalOutputXML->getAttribute('Name').") has columns of multiple granularities. Died on column (Name=".$attrColumnXML->getAttribute('name').", ColumnID=".$attrColumnXML->getAttribute('ColumnID').") with granularity '$attrColumnGranularity'"
					unless $granularity eq $attrColumnGranularity;
					
				#check table
				my $attrColumnTable =
					$column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') }->data_table;
				$table = $attrColumnTable
					if (not defined $table);
				die ref ($self) . " Formal Output (name=".$formalOutputXML->getAttribute('Name').") has columns in multiple tables. Died on column (Name=".$attrColumnXML->getAttribute('name').", ColumnID=".$attrColumnXML->getAttribute('ColumnID').") in table '".$attrColumnTable->table_name()."'"
					unless $table->id() eq $attrColumnTable->id();
				
				#create object
				my $newAttrColumn = $factory->newObject( "OME::AttributeType::Column", {
					attribute_type => $newAttrType,
					name           => $attrColumnXML->getAttribute('Name'),
					data_column    => $column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') },
					description    => $attrColumnXML->getAttribute('Description')
				})
					or die ref ($self) . " could not create new OME::AttributeType::Column object, name = ". $attrColumnXML->getAttribute('Name');
				
				$formalOutputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) } =
					$newAttrColumn;
				print STDERR ref ($self) . "->processDOM added entry to formalOutputColumn_xmlID_dbObject.\n\t".$attrColumnXML->getAttribute( 'FormalOutputColumnID' )."=>".$formalOutputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) }."\n"
					if $debug > 1;

#				$formalOutputColumn_xmlID_FormalOutput{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) } =
#					$formalOutputXML->getAttribute( 'Name' );
#				print STDERR ref ($self) . "->processDOM added entry to formalOutputColumn_xmlID_FormalOutput.\n\t".$attrColumnXML->getAttribute( 'FormalOutputColumnID' )."=>".$formalOutputColumn_xmlID_FormalOutput{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) }."\n"
#					if $debug > 1;

				push(@commitOnSuccessfulImport, $newAttrColumn);
				print STDERR ref ($self) . "->processDOM finished processing attribute column\n"
					if $debug > 1;
			}
			print STDERR ref ($self) . "->processDOM finished processing attribute columns in this attribute\n"
				if $debug > 1;
			#
			#
			###################################################################

			$newAttrType->granularity( $granularity );
			push(@commitOnSuccessfulImport, $newAttrType);
		}
		#
		# END "if AttributeType doesn't exist, create it"
		#
		#######################################################################


		#######################################################################
		#
		# AttributeType exists, verify that the attribute columns are identical
		#	also, populate formalOutputColumn_xmlID_dbObject hash
		#
		else { 
			my @attrColumns = $existingAttrType->attribute_columns();
			my $granularity;
			die ref ($self) . " While processing formal output (name=".$formalOutputXML->getAttribute('Name')."), found existing AttributeType with same AttributeTypeName (".$formalOutputXML->getAttribute('AttributeTypeName').") but differing number of columns. Existing AttributeType has ".scalar(@attrColumns)." columns, new AttributeType of same name has ".scalar(@$formalOutputXML->getElementsByTagName( "FormalOutputColumn") )."columns."
				unless( scalar(@attrColumns) eq scalar(@{$formalOutputXML->getElementsByTagName( "FormalOutputColumn")}) );
			foreach my $attrColumnXML ($formalOutputXML->getElementsByTagName( "FormalOutputColumn") ) {
				#check ColumnID
				die ref ($self) . " While processing formal output (name=".$formalOutputXML->getAttribute('Name')."), could not find entry for columnID '".$attrColumnXML->getAttribute('ColumnID')."'\n"
					unless exists $column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') };

				#check granularity
				my $attrColumnGranularity =
					$column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') }->data_table->granularity();
				$granularity = $attrColumnGranularity
					if (not defined $granularity);
				die ref ($self) . " Formal Output (name=".$formalOutputXML->getAttribute('Name').") has columns of multiple granularities. Died on column (Name=".$attrColumnXML->getAttribute('name').", ColumnID=".$attrColumnXML->getAttribute('ColumnID').") with granularity '$attrColumnGranularity'"
					unless $granularity eq $attrColumnGranularity;

				#find OME::AttributeType::Column matched by OME::DataTable::Column
				map {
					$formalOutputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) } = $_
						if $column_xmlID_object{ $attrColumnXML->getAttribute('ColumnID') }->id() eq $_->data_column()->id();
				} @attrColumns;
				print STDERR ref ($self) . "->processDOM added entry to formalOutputColumn_xmlID_dbObject.\n\t".$attrColumnXML->getAttribute( 'FormalOutputColumnID' )."=>".$formalOutputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) }."\n"
					if $debug > 1;

#				$formalOutputColumn_xmlID_FormalOutput{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) } =
#					$formalOutputXML->getAttribute( 'Name' );
#				print STDERR ref ($self) . "->processDOM added entry to formalOutputColumn_xmlID_FormalOutput.\n\t".$attrColumnXML->getAttribute( 'FormalOutputColumnID' )."=>".$formalOutputColumn_xmlID_FormalOutput{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) }."\n"
#					if $debug > 1;
				
				die ref ($self) . " While processing FormalOutput (name=".$formalOutputXML->getAttribute('Name')."), found existing AttributeType of same AttributeTypeName (".$formalOutputXML->getAttribute('AttributeTypeName')."). Could not find matching column in existing AttributeType for new column (Name=".$attrColumnXML->getAttribute('Name').",ColumnID=".$attrColumnXML->getAttribute('ColumnID').")."
					unless exists $formalOutputColumn_xmlID_dbObject{ $attrColumnXML->getAttribute( 'FormalOutputColumnID' ) };
			}
			die ref ($self) . " While processing formal output (name=".$formalOutputXML->getAttribute('Name')."), found an existing AttributeType with same AttributeTypeName (".$formalOutputXML->getAttribute('AttributeTypeName').") and different granularities."
				unless( $existingAttrType->granularity() eq $granularity );
			$newAttrType = $existingAttrType;
		}
		#
		# END "AttributeType exists, verify that the attribute columns are identical"
		#
		#######################################################################

		###################################################################
		#
		# make OME::FormalOutput object
		#
		my $data = {
			name               => $formalOutputXML->getAttribute( 'Name' ),
			description        => $formalOutputXML->getAttribute( 'Description' ),
			program_id         => $newProgram,
			attribute_type_id  => $newAttrType,
			feature_tag        => $formalOutputXML->getAttribute( 'IBelongTo' )
		};
		my $newFormalOutput = $factory->newObject( "OME::Program::FormalOutput", $data )
			or die "Could not create OME::Program::FormalOutput object\n";

		map{
			$formalOutputColumn_xmlID_FormalOutput{ $_->getAttribute("FormalOutputColumnID") } = $newFormalOutput
		} @{$formalOutputXML->getElementsByTagName( "FormalOutputColumn")};
		print STDERR ref ($self) . "->processDOM added entries to formalOutputColumn_xmlID_FormalOutput.\n\t".
			join( "\n\t", 
				map{
					$_->getAttribute("FormalOutputColumnID")." => ".$formalOutputColumn_xmlID_FormalOutput{$_->getAttribute("FormalOutputColumnID")}
				} @{$formalOutputXML->getElementsByTagName( "FormalOutputColumnID")}
			)."\n"
			if $debug > 1;

		push(@commitOnSuccessfulImport, $newFormalOutput);
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
	my $executionInstructionXML;
	
	# XML schema & DBdesign currently allow at most one execution point per module
	if(scalar(@executionInstructions) == 1) {
		#######################################################################
		#
		# CLI Handler specific execution Instructions
		#
		$executionInstructionXML = $executionInstructions[0];

		#######################################################################
		#
		# replace FormalInputID's with ID's from DB
		#
		#	Right now, using names instead of IDs
		#
		print STDERR ref ($self) . "->processDOM replacing FormalInputColumnID's w/ ID's from DB and is creating other attributes\n"
			if $debug > 1;
		my @inputTypes = ( "Input", "UseValue", "End", "Start" );
		my @inputs;
		map {
			push(@inputs, $executionInstructionXML->getElementsByTagName( $_ ));
		} @inputTypes;

		foreach my $input (@inputs) {
			die ref ($self) . "->processDOM When processing ExecutionInstructions, could not find a matching FormalInputColumnID '".$input->getAttribute( "FormalInputColumnID" )."'. You probably made a typo. Is there a FormalInputColumn with that FormalInputColumnID?\n"
				unless exists $formalInputColumn_xmlID_dbObject { $input->getAttribute( "FormalInputColumnID" )};

			# Create attributes FormalInputID and FormalInputName to store NAME and FORMAL_INPUT_ID of the FORMAL_INPUT that contains the ATTRIBUTE_COLUMN/FormalInputColumn referenced by this element's FormalInputColumnID.
			print STDERR ref ($self) . "->processDOM is creating FormalInputName attribute in element type ".$input->tagName()."\n\tValue is ".
				$formalInputColumn_xmlID_FormalInput { $input->getAttribute( "FormalInputColumnID" )}->name()."\n"
				if $debug > 1;
			$input->setAttribute ( "FormalInputName",
				$formalInputColumn_xmlID_FormalInput{$input->getAttribute( "FormalInputColumnID" )}->name()
			);
			print STDERR ref ($self) . "->processDOM is creating FormalInputID attribute in element type ".$input->tagName()."\n\tValue is ".
				$formalInputColumn_xmlID_FormalInput { $input->getAttribute( "FormalInputColumnID" )}->id()."\n"
				if $debug > 1;
			$input->setAttribute ( "FormalInputID",
				$formalInputColumn_xmlID_FormalInput{$input->getAttribute( "FormalInputColumnID" )}->id()
			);

			print STDERR ref ($self) . "->processDOM is creating FormalInputColumnName in element type ".$input->tagName()."\n".$input->getAttribute( "FormalInputColumnID" )." -> ".
				$formalInputColumn_xmlID_dbObject { $input->getAttribute( "FormalInputColumnID" )}->name()."\n"
				if $debug > 1;
			$input->setAttribute( "FormalInputColumnName",
				$formalInputColumn_xmlID_dbObject {
					$input->getAttribute( "FormalInputColumnID" )}->name());
			print STDERR ref ($self) . "->processDOM is altering FormalInputColumnID in element type ".$input->tagName()."\n".$input->getAttribute( "FormalInputColumnID" )." -> ".
				$formalInputColumn_xmlID_dbObject { $input->getAttribute( "FormalInputColumnID" )}->id()."\n"
				if $debug > 1;
			$input->setAttribute( "FormalInputColumnID",
				$formalInputColumn_xmlID_dbObject {
					$input->getAttribute( "FormalInputColumnID" )}->id());
		}
		print STDERR ref ($self) . "->processDOM finished replacing FormalInputColumnID's\n"
			if $debug > 1;
		#
		#######################################################################
	
		#######################################################################
		#
		# replace FormalOutputID's with ID's from DB
		#
		#	Right now, using names instead of IDs
		#
		print STDERR ref ($self) . "->processDOM replacing FormalOutputColumnID's w/ ID's from DB and is creating other attributes\n"
			if $debug > 1;
		my @outputTypes = ( "OutputTo", "AutoIterate", "IterateRange" );
		my @outputs;
		map {
			push(@outputs, $executionInstructionXML->getElementsByTagName( $_ ));
		} @outputTypes;

		foreach my $output (@outputs) {
			die ref ($self) . "->processDOM When processing ExecutionInstructions, could not find a matching FormalOutputColumnID '".$output->getAttribute( "FormalOutputColumnID" )."'. You probably made a typo. Is there a FormalOutputColumn with that FormalOutputColumnID?\n"
				unless exists $formalOutputColumn_xmlID_dbObject { $output->getAttribute( "FormalOutputColumnID" )};

			# Create attributes FormalOutputID and FormalOutputName to store NAME and FORMAL_OUTPUT_ID of the FORMAL_OUTPUT that contains the ATTRIBUTE_COLUMN/FormalOutputColumn referenced by this element's FormalOutputColumnID.
			print STDERR ref ($self) . "->processDOM is creating FormalOutputName attribute in element type ".$output->tagName()."\n\tValue is ".
				$formalOutputColumn_xmlID_FormalOutput{ $output->getAttribute( "FormalOutputColumnID" )}->name()."\n"
				if $debug > 1;
			$output->setAttribute ( "FormalOutputName",
				$formalOutputColumn_xmlID_FormalOutput{$output->getAttribute( "FormalOutputColumnID" )}->name()
			);
			print STDERR ref ($self) . "->processDOM is creating FormalOutputID attribute in element type ".$output->tagName()."\n\tValue is ".
				$formalOutputColumn_xmlID_FormalOutput{ $output->getAttribute( "FormalOutputColumnID" )}->id()."\n"
				if $debug > 1;
			$output->setAttribute ( "FormalOutputID",
				$formalOutputColumn_xmlID_FormalOutput{$output->getAttribute( "FormalOutputColumnID" )}->id()
			);


			print STDERR ref ($self) . "->processDOM is creating FormalOutputColumnName in element type ".$output->tagName()."\n\tValue is ".
				$formalOutputColumn_xmlID_dbObject { $output->getAttribute( "FormalOutputColumnID" )}->name()."\n"
				if $debug > 1;
			$output->setAttribute( "FormalOutputColumnName",
				$formalOutputColumn_xmlID_dbObject {
					$output->getAttribute( "FormalOutputColumnID" )}->name()
			);
			print STDERR ref ($self) . "->processDOM is altering FormalOutputColumnID in element type ".$output->tagName()."\n".$output->getAttribute( "FormalOutputColumnID" )." -> ".
				$formalOutputColumn_xmlID_dbObject { $output->getAttribute( "FormalOutputColumnID" )}->id()."\n"
				if $debug > 1;
			$output->setAttribute( "FormalOutputColumnID",
				$formalOutputColumn_xmlID_dbObject {
					$output->getAttribute( "FormalOutputColumnID" )}->id()
			);
		}
		print STDERR ref ($self) . "->processDOM finished replacing FormalOutputColumnID's\n"
			if $debug > 1;
		#
		#######################################################################

		#######################################################################
		#
		# normalize XYPlaneID's
		#
		print STDERR ref ($self) . "->processDOM normalizing XYPlaneID's\n"
			if $debug > 1;
		my $currentID = 0;
		my %idMap;
		# first run: normalize XYPlaneID's in XYPlane's
		foreach my $plane($executionInstructionXML->getElementsByTagName( "XYPlane" ) ) {
			$currentID++;
			die ref ($self) . " Two planes found with same ID (".$plane->getAttribute('XYPlaneID').")"
				if ( defined defined $plane->getAttribute('XYPlaneID') ) and ( exists $idMap{ $plane->getAttribute('XYPlaneID') } );
			print STDERR ref ($self) . "->processDOM is altering XYPlaneID in element type XYPlane\n" .
				(defined $plane->getAttribute('XYPlaneID') ? $plane->getAttribute('XYPlaneID') : '[No value]') .
				" -> " . $currentID . "\n"
				if $debug > 1;
			$idMap{ $plane->getAttribute('XYPlaneID') } = $currentID
				if defined $plane->getAttribute('XYPlaneID');
			$plane->setAttribute('XYPlaneID', $currentID);
		}
		# second run: clean up references to XYPlanes
		foreach my $match($executionInstructionXML->getElementsByTagName( "Match" ) ) {
			die ref ($self) . " 'Match' element's reference plane not found. XYPlaneID=".$match->getAttribute('XYPlaneID').". Did you make a typo?"
				unless exists $idMap{ $match->getAttribute('XYPlaneID') };
			print STDERR ref ($self) . "->processDOM is altering XYPlaneID in element type Match\n" .
				$match->getAttribute('XYPlaneID') .	" -> " . $idMap{ $match->getAttribute('XYPlaneID') } . "\n"
				if $debug > 1;
			$match->setAttribute('XYPlaneID',
				$idMap{ $match->getAttribute('XYPlaneID') } );
		}
		print STDERR ref ($self) . "->processDOM finished normalizing XYPlaneID's\n"
			if $debug > 1;
		#
		#######################################################################
		
		#######################################################################
		#
		# check regular expressions for validity
		#
		print STDERR ref ($self) . "->processDOM checking regular expression patterns for validity\n"
			if $debug > 1;
		my @pats =  $executionInstructionXML->getElementsByTagName( "pat" );
		foreach (@pats) {
			my $pat = $_->getFirstChild->getData();
			print STDERR ref ($self) . "->processDOM inspecting pattern:\n$pat\n"
				if $debug > 1;
			eval { "" =~ /$pat/; };
			die "Invalid regular expression pattern: $pat in program ".$newProgram->program_name()
				if $@;
		}
		print STDERR ref ($self) . "->processDOM finished checking regular expression patterns\n"
			if $debug > 1;
		#
		#######################################################################

		print STDERR ref ($self) . "->processDOM's modified ExecutionInstructions are:\n". $executionInstructionXML->toString() ."\n"
			if $debug > 2;
		# save executionInstructions
#		$newProgram->execution_instructions( $executionInstructionXML->toString() );
		print STDERR ref ($self) . "->processDOM finished processing ExecutionInstructions.\n"
			if $debug > 1;
	}
	#
	#
	###########################################################################

	###########################################################################
	# commit this module. It's been successfully imported
	#
	print STDERR ref ($self) . "->processDOM imported module '".$newProgram->program_name."' sucessfully. Committing to DB...\n"
		if $debug > 0;
	print STDERR ref ($self) . "->processDOM saving DBObjects\n"
		if $debug > 2;
	while( my $DBObjectInstance = pop (@commitOnSuccessfulImport) ){
		print STDERR ref ($self) . "->processDOM calling writeObject on $DBObjectInstance\n"
			if $debug > 2;
		$DBObjectInstance->writeObject;
	}                             # commits all DBObjects
	print STDERR ref ($self) . "->processDOM finished saving DBObjects\n"
		if $debug > 2;
	print STDERR ref ($self) . "->processDOM saving changes to tables and columns\n"
		if $debug > 2;
	$session->DBH()->commit();    # new tables & columns written w/ this handle
	print STDERR ref ($self) . "->processDOM finished saving changes to tables and columns\n"
		if $debug > 2;

	# Save ExecutionInstructions
	if( defined $executionInstructionXML ) {
		print STDERR ref ($self) . "->processDOM saving executionInstructions\n"
			if $debug > 2;
		$newProgram->execution_instructions( $executionInstructionXML->toString() );
		$newProgram->writeObject();
		print STDERR ref ($self) . "->processDOM finished saving executionInstructions\n"
			if $debug > 2;
	}

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
