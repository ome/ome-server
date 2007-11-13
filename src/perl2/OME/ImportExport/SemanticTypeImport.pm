# OME/ImportExport/SemanticTypeImport.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
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
# Written by:	 Josiah Johnston <siah@nih.gov>,
#                Tomasz Macura <tmacura@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::ImportExport::SemanticTypeImport;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use Log::Agent;
use XML::LibXML;

use OME::Database::Delegate;
use OME::Session;

our $default_lang = 'en';

sub new {
	my ($proto, %params) = @_;
	my $class = ref($proto) || $proto;

	my @fieldsILike = qw( _parser);

	my $self;

	@$self{@fieldsILike} = @params{@fieldsILike};

	if (!defined $self->{_parser}) {
		my $parser = XML::LibXML->new();
		logdie "Cannot create XML parser"
		  unless defined $parser;

		$parser->validation(exists $params{ValidateXML}?
							$params{ValidateXML}: 0);
		$self->{_parser} = $parser;
	}

	return bless $self, $class;
}


sub importFile {
	my ($self, $filename, %flags) = @_;
	my $doc = $self->{_parser}->parse_file($filename)
	  or logdie "Cannot parse file $filename";
	return $self->processDOM($doc->getDocumentElement(),%flags);
}

sub importXML {
	my ($self, $xml, %flags) = @_;
	my $doc = $self->{_parser}->parse_string($xml)
	  or logdie "Cannot parse XML string";
	return $self->processDOM($doc->getDocumentElement(),%flags);
}

sub SemanticTypes { return shift->{semanticTypes}; }
sub SemanticColumns { return shift->{semanticColumns}; }

sub printElement {
	my $element = shift;
	print "\n".$element->nodeName.":\n";
	foreach ($element->getChildNodes()) {
		print "	 ".$_->nodeName."\n";
	}
}

=head1 METHODS

=head2 processDOM( $root, %flags )

Note: You must call commit on the DBH attached to this object's session after calling processDOM.
Changes to tables and columns are made on that handle, but shouldn't be committed here.

=cut

sub processDOM {
	my ($self, $root, %flags) = @_;
	my $session = OME::Session->instance();
	my $factory = $session->Factory();
	my $delegate = OME::Database::Delegate->getDefaultDelegate();

	my $ignoreAlterTableErrors = $flags{IgnoreAlterTableErrors};

	my @commitOnSuccessfulImport;
	my @newSemanticTypes;

	my %dataTypeConversion = (
							  # XMLType	 => SQL_Type
							  bigint   => 'bigint',
							  integer  => 'integer',
							  smallint => 'smallint',
							  double   => 'double precision',
							  float	   => 'real',
							  boolean  => 'boolean',
							  string   => 'text',
							  dateTime => 'timestamp',
							  reference => 'oid'
							 );
	my %reverseDataTypeConversion;
	foreach my $key ( keys %dataTypeConversion ) {
		$reverseDataTypeConversion{ $dataTypeConversion{ $key } } = $key;
		$reverseDataTypeConversion{'double'}    = 'double';
		$reverseDataTypeConversion{'float'}     = 'float';
		$reverseDataTypeConversion{'string'}    = 'string';
		$reverseDataTypeConversion{'dateTime'}  = 'dateTime';
		$reverseDataTypeConversion{'reference'} = 'reference';
	}
	
	###############################################################################
	#
	# Make new tables, columns, and Attribute types
	#
	# semanticTypes is keyed by name, valued by DBObject AttributeType
	my $semanticTypes;

	# semanticColumns is a double keyed hash
	#	keyed by {semantic_type.Name}->{semantic_element.Name}
	#	valued by DBObject AttributeColumn
	my $semanticColumns;

	my $SemanticDefinitionsXML = $root;
	#  getElementsByLocalName("SemanticTypeDefinitions" )->[0];
	#printElement($SemanticDefinitionsXML);
	my ($tName,$cName);
	my ($tables,$table);

	logdbg "debug", ref ($self) . 
	  "->processDOM: processing SemanticTypeDefinitions";

	###########################################################################
	#
	# First pass through the STDs.
	#	Check for conflicting STDs.
	#	Make new tables and columns as needed.
	#
	# dataColumns is a hash used to store the DataColumn where a Semantic Element lives.
	# It gets populated when we are making tables/columns after the first pass through the STs
	# and gets used when we make the STs in the DB on the second pass.
	# The hash is:
	#	keyed by {$tName.'.'.$cName} (i.e. DBLocation of the Semantic Element)
	#	valued by DBobject DataColumn
	my %dataColumns;

	my @STDs = $root->getElementsByLocalName( 'SemanticType' );


	foreach my $ST_XML (@STDs) {
	###########################################################################
	#
    # Check if the semantic type exists, and if so that it doesn't conflict.
	#
		my $stName = $ST_XML->getAttribute('Name');
        $self->validateSTName($stName);
		$semanticTypes->{ $stName } = undef;
		my $stDescription = $self->_getDescription( $ST_XML, $default_lang );
		my $stParent = $ST_XML->getAttribute('Parent');

        # If inheritance came into play, pull semantic elements from the parent
        # and inject them into the XML
		if( $stParent ) {
			my $parentST = $factory->findObject( 'OME::SemanticType', name => $stParent )
				or die "Couldn't load parent ST $stParent";
			my @inheritedSEs = $parentST->semantic_elements();
			foreach my $inheritedSE ( @inheritedSEs ) {
				# Add a SE to the XML DOM. 
				# 2do: Die if there is already an SE of the same name
				my $SE_XML = $root->ownerDocument()->createElement('Element');
				$SE_XML->setAttribute( 'Name', $inheritedSE->name );
				
				if ($inheritedSE->data_column->reference_type) {
					$SE_XML->setAttribute( 'DataType', 'integer');
				} else {
					$SE_XML->setAttribute( 'DataType', $reverseDataTypeConversion{ $inheritedSE->data_column->sql_type() } );
				}
				
				if ($inheritedSE->data_column->sql_type() eq 'reference') {
					my $referenceTo = $inheritedSE->data_column->reference_type();
					$SE_XML->setAttribute( 'RefersTo', $referenceTo);
				}
				# Attach the Element element to the ST
				$ST_XML->appendChild($SE_XML);
			}
		}
		# Debugging line
		# print STDERR "\n\n".$ST_XML->toString()."\n\n";
		
		my @SEs_XML = $ST_XML->getElementsByLocalName ('Element');

		my $existingSemanticType = $factory->
          findObject("OME::SemanticType",
                     name => $stName);

        my $newSemanticType;
		###########################################################################
		#
        # if SemanticType exists, make sure the new one doesn't conflict.
        # All semantic elements must be identical to avoid conflict:
		#		Name, DBLocation, DataType, RefersTo
		# If it does conflict, its a fatal error.
		#
        if (defined $existingSemanticType ) {
			logdbg "debug", ref ($self) . 
			  "->processDOM: found a OME::SemanticType object with matching ".
			  "name ($stName). inspecting it to see if it completely matches.";

            my @seColumns = $existingSemanticType->semantic_elements();

			logdie ref ($self) . ": While processing Semantic Type $stName, ".
              " existing $stName has ".scalar(@seColumns).
			  " columns, new declaration has ".scalar(@SEs_XML)." columns."
              unless (scalar(@seColumns) eq scalar(@SEs_XML));

			foreach my $SemanticElementXML (@SEs_XML) {
				my $seName = $SemanticElementXML->getAttribute('Name');
                $self->validateSEName($seName);
                my $seDBloc = $SemanticElementXML->getAttribute('DBLocation');
                $seDBloc = $self->deriveDBLocation($stName,$seName) unless defined $seDBloc; # DBLocation is optional

				my $seDataType = $SemanticElementXML->getAttribute('DataType');
				my $seReferenceTo = $SemanticElementXML->getAttribute('RefersTo');
                my $seCol;
                foreach (@seColumns) {
					if ($_->name() eq $seName) {
                        $seCol = $_;
						last;
					};
				}
                logdie ref ($self) . ": While processing existing Semantic Type $stName, ".
                    "existing declaration has no Semantic Element $seName."
                    unless defined $seCol and $seCol->name() eq $seName;
                
                my $actual_seDBloc = $seCol->data_column()->data_table()->table_name().'.'.$seCol->data_column()->column_name();
                logdie ref ($self) . ": While processing Semantic Type $stName, ".
                    "existing semantic element $seName is stored in $actual_seDBloc instead of $seDBloc."
                    unless defined $actual_seDBloc and $actual_seDBloc eq $seDBloc;

                my $actual_seDataType = $seCol->data_column()->sql_type();
                logdie ref ($self) . ": While processing Semantic Type $stName, ".
                    "existing semantic element $seName has data type $actual_seDataType instead of $seDataType."
                    unless defined $actual_seDataType and $actual_seDataType eq $seDataType;

                my $actual_seReferenceTo = $seCol->data_column()->reference_type();
                logdie ref ($self) . ": While processing Semantic Type $stName, ".
                    "existing semantic element $seName refers to $actual_seReferenceTo instead of $seReferenceTo."
                    if defined $actual_seReferenceTo and not ($actual_seReferenceTo eq $seReferenceTo);
			}
			logdbg "debug", ref ($self) . 
			  "->processDOM: Complete match between revious and current definition of $stName.";
			next; # don't need to anything more for this ST as since it's already defined
	# END:	Check for conflict with existing Semantic Type.
	###########################################################################
		}			 
   
	###########################################################################
	# Build the table hash:
	# $granularity = $tables{$tableName}->{granularity};
	# @tDescriptions = $tables{$tableName}->{description};	  # array of ST descriptions
	# $datatype = $tables{$tableName}->{columns}->{$cName}->{datatype};
	# $referenceTo_DBObject = $tables{$tableName}->{columns}->{$cName}->{reference}->{DBObject};
	# $referenceTo_STname = $tables{$tableName}->{columns}->{$cName}->{reference}->{STname};
	# @cDescriptions = $tables{$tableName}->{columns}->{$cName}->{description}; # array of SE descriptions
		my $tDescription = $self->_getDescription( $ST_XML, $default_lang );

		my $st_tName; # each ST can only be defined in a single table
		foreach my $SE_XML (@SEs_XML) {
			my $seName = $SE_XML->getAttribute('Name');
			$self->validateSEName($seName);
			my $DBLocation = $SE_XML->getAttribute('DBLocation');
            $DBLocation = $self->deriveDBLocation($stName,$seName) unless defined $DBLocation;
			my $dataType = $SE_XML->getAttribute('DataType');
			($tName,$cName) = split (/\./,$DBLocation);
			
			# verify the one table per ST (i.e. ST SEs are not spread across multiple tables)
            if (defined $st_tName) {
            	logdie ref($self) .": While processing Semantic Type $stName, ".
            		"Semantic Type cannot be defined across multiple tables. ".
            		"This ST is trying to define semantic elements in tables ".
            		"$st_tName and $tName\n" unless ($st_tName eq $tName);
            } else {
            	$st_tName = $tName;
            }
            
			if (not exists $tables->{$tName}){
				$tables->{$tName}->{columns} = {};
                $tables->{$tName}->{stName} = $stName;
				$tables->{$tName}->{description} = [];
				$tables->{$tName}->{name} = $tName;
				$tables->{$tName}->{order} = scalar (keys %{$tables}) + 1;
				$tables->{$tName}->{granularity} = $ST_XML->getAttribute('AppliesTo');
				push (@{$tables->{$tName}->{description}},$tDescription)
				  if defined $tDescription and length ($tDescription) > 0;
			} elsif ($tables->{$tName}->{stName} ne $stName) {
				logdie ref($self) .": While processing Semantic Type $stName, ".
					"Multiple Semantic Types cannot be defined in the same table. ".
            		"STs ".$tables->{$tName}->{stName}." and ". $stName . " both are ".
            		"defined to store SEs in ".$tName."\n";
            }
			
			# Put the required column in the table hash.
			# If the column doesn't exist yet and is a reference,
			# try to get the DBObject it points to from the DB.
			if (not exists ($tables->{$tName}->{columns}->{$cName})) {
				$tables->{$tName}->{columns}->{$cName}->{datatype} = $dataType;
				if ($dataType eq 'reference') {
					my $referenceTo = $SE_XML->getAttribute('RefersTo')
                    	or logdie ref($self) ."Semantic Element '".$SE_XML->getAttribute( 'Name' )."' in Semantic Type '$stName' is a reference, but lacks a RefersTo.\n".$SE_XML->toString();
					$tables->{$tName}->{columns}->{$cName}->{reference}->{STname} = $referenceTo;
					$tables->{$tName}->{columns}->{$cName}->{reference}->{DBObject} = $factory->findObject("OME::SemanticType",name => $referenceTo);
				}
				$tables->{$tName}->{columns}->{$cName}->{order} = scalar (keys %{$tables->{$tName}->{columns}}) + 1;
				$tables->{$tName}->{columns}->{$cName}->{description} = [];
				$tables->{$tName}->{columns}->{$cName}->{name} = $cName;
			} elsif ($tables->{$tName}->{columns}->{$cName}->{datatype} ne $dataType) {
				logdie ref ($self) .
				  "->processDOM: internally conflicting column datatypes for $DBLocation\n!Declared as ".
				  $dataType.', Previously declared as '.$tables->{$tName}->{columns}->{$cName}->{datatype};
			}
			my $cDescription = $self->_getDescription( $ST_XML, $default_lang );
			push (@{$tables->{$tName}->{columns}->{$cName}->{description}},$cDescription)
				if defined $cDescription and length ($cDescription) > 0;
		}
	}

	# END:	First pass on semantic types: Checking conflicts and gathering required tables.
	###########################################################################
	
	
	#######################################################################
	#
	# Create the necessary tables
	#

	foreach $table	( sort { $a->{order} <=> $b->{order} } values %$tables ) {
		$tName = $table->{name};
		logdbg "debug", ref ($self) . "->processDOM: processing table ".$tName;
		my @DT_tables = $factory->findObjects( "OME::DataTable", 'table_name' => $tName );

		my $newTable;
		if ( scalar(@DT_tables) == 0 ) { # the table doesn't exist. create it.
			logdbg "debug", ref ($self) . 
			  "->processDOM: table $tName not found. creating it.";
			my $data = {
						table_name	=> $tName,
						description => $table->{description}->[0],
						granularity => $table->{granularity},
					   };

			$newTable = $factory->newObject( "OME::DataTable", $data )
			  or logdie ref($self)." could not create OME::DataTable. name=$tName";

			push(@commitOnSuccessfulImport, $newTable);

		} else {
            logdie ref ($self) .
              "->processDOM: table $tName already exists. One Semantic Type per table.";
		}
		#
		# END 'Process a Table'
		#
		########################################################################

		########################################################################
		#
		# Process columns in this table
		#
		logdbg "debug", ref ($self) . "->processDOM: processing columns";

		my $column;
		foreach $column ( sort { $a->{order} <=> $b->{order} } values %{$tables->{$tName}->{columns}} ) {
			my $cName = $column->{name};

			my $dataType = $column->{datatype};
			my $sqlDataType = $dataTypeConversion{$dataType};
			
			logdie ref ($self) .
			  "->processDOM: Could not find a matching SQL type for datatype '$dataType'."
			  unless defined $sqlDataType and length ($sqlDataType) > 0;

			logdbg "debug", ref ($self) .
			  "->processDOM: processing column: $tName . $cName";

			my $cols = $factory->
			  findObject("OME::DataTable::Column",
						  data_table => $newTable->id(),
						  column_name	=> $cName
						 );

			my $newColumn;

			if (!defined $cols) {
				# If the column is a reference, the reference must be resolved at this point - either because its in the DB already or in the current document.
				if (exists $column->{reference}) {
					logdie ref ($self).":  Unresolved reference.  The Semantic Type ".$column->{reference}->{STname}.
						" was used in a reference, but it does not exist in the database or in the current document."
						unless exists $column->{reference}->{DBObject} or exists $semanticTypes->{$column->{reference}->{STname}};
				}

				logdbg "debug", ref ($self) . 
				  "->processDOM: could not find matching column. creating it";

				my $data	 = {
								'data_table'  => $newTable->id(),
								'column_name'	 => $cName,
								'description'	 => $column->{description}->[0],
#								 'sql_type'		  => 'foo',
								'sql_type'		 => $dataType,
#								 'sql_type'		  => $sqlDataType,	# NOT!
# FIXME - IGG:
# Believe it or not, setting sql_type to $dataType fails in $factory->newObject for some (but not all) 'integer's with:
#	Failure while doing 'MakeNewObj' with 'New OME::DataTable::Column'
#	DBD::Pg::st execute failed: ERROR:	Attribute 'integer' not found at /Library/Perl/Ima/DBI.pm line 733.
#	at /Library/Perl/OME/Tasks/SemanticTypeImport.pm line 428
# The only hope is to set it to a literal string.  Yes, the offending 'integer's are 'eq' and '==' to 'integer' string literals,
# and $sqlDataType gets set properly, so there are no hidden gremlins in there.
# If you know why and have a better fix, please have at it.
# The best idea I can come up with is maybe some inconsistent implementation of unicode.
#
# The usage of sql_type indicates that this is in fact the XML datatype, not a SQL type (which is good IMHO),
# specifically with regard to 'reference'.	sql_type should really be renamed to datatype, though.
								'reference_type' => $column->{reference}->{STname}
							   };

				$newColumn = $factory->newObject( 'OME::DataTable::Column', $data )
                    or logdie ref($self)."Could not create OME::DataType::Column object";
#
# This is the continuation of the sql_type fiasco.	$newColumn->sql_type($dataType) won't let you commit the object with the offending 'integer'.
# Only the string literal will do.
				#if ($dataType eq 'integer') {
				#	 $newColumn->sql_type('integer');
				#} else {
				#	 $newColumn->sql_type($dataType);
				#}

				push(@commitOnSuccessfulImport, $newColumn);

			} else {
                logdie ref($self)."Column $tName.$cName already exists.".
                				  "There here can only be one Semantic Element defined per column.";
			}
			
			$dataColumns{$tName.'.'.$cName} = $newColumn;


		}

		#
		# END 'Process columns in this table'
		#
		########################################################################

		# Force this data table to regenerate its Perl package.	 (So
		# that the new columns become visible)
		my $pkg = $newTable->requireDataTablePackage(1);

		# Add the table to the database
		# This gets the Factory's DBH - not a new one.
		$delegate->addClassToDatabase($factory->obtainDBH(),$pkg);
# We're not supposed to release the Factory's DBH.	Only ones we get from Factory->newDBH
#		 $factory->releaseDBH($dbh);

	}

	#
	# END make necessary tables
	#
	###########################################################################

	###########################################################################
	#
	# Make SemanticTypes
	#
	logdbg "debug", ref ($self) .
	  "->processDOM: creating SemanticTypes";

	foreach my $ST_XML (@STDs) {
		my $stName = $ST_XML->getAttribute('Name');
        $self->validateSTName($stName);
		my $stGranularity = $ST_XML->getAttribute('AppliesTo');
        my $stDescription = $self->_getDescription( $ST_XML, $default_lang );
		my $stParent      = $ST_XML->getAttribute('Parent');

		# look for existing ST
		# If the ST exists, we already know it doesn't conflict from the first pass.
		logdbg "debug", ref($self)."->processDOM processing $stName";
        my $existingSemanticType = $factory->
		  findObject("OME::SemanticType",
					 name => $stName);

        my $newSemanticType;
		###########################################################################
		#
        # if SemanticType doesn't exist, create it
		#
        if ( not defined $existingSemanticType ) {
			logdbg "debug", ref ($self) . "->processDOM: Creating new semantic type.";

			my $data;
			if ($stParent) {
				my $parentST = $factory->findObject( 'OME::SemanticType', name => $stParent )
					or die "Couldn't load parent ST $stParent";
				$data = {
							name		=> $stName,
							granularity => $stGranularity,
							description => $stDescription,
							parent      => $parentST,
					   };
			} else {
				$data = {
							name		=> $stName,
							granularity => $stGranularity,
							description => $stDescription,
					   };
			}

            $newSemanticType = $factory->newObject("OME::SemanticType",$data)
			  or logdie ref ($self) . 
			  " could not create new object of type OME::SemanticType with".
			  "parameters:\n\t".
				join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n";


			#######################################################################
			#
			# make OME::SemanticType::Element objects
			#
			foreach my $SemanticElementXML ($ST_XML->getElementsByLocalName( "Element") ) {
				my $seName = $SemanticElementXML->getAttribute('Name');
				$self->validateSEName($seName);
				my $seDBloc = $SemanticElementXML->getAttribute('DBLocation');
                $seDBloc = $self->deriveDBLocation($stName,$seName) unless defined $seDBloc; # DBLocation is optional
				my $seDescription = $self->_getDescription( $SemanticElementXML, $default_lang );

				#check ColumnID
				logdie ref ($self) . 
				  " could not find entry for column '$seName'\n"
				  unless exists $dataColumns{$seDBloc};

				my $dataColumn = $dataColumns{$seDBloc};

				#Create object

				my $newSEColumn = $factory->
				  newObject( "OME::SemanticType::Element",
							 {
                              semantic_type  => $newSemanticType,
							  name			 => $seName,
							  data_column	 => $dataColumn,
							  description	 => $seDescription,
							 })
				  or logdie ref ($self) . 
					" could not create new OME::SemanticType::Element object, ".
					"name = $seName";

				$semanticColumns->{$stName}->{ $seName } =
				  $newSEColumn;

                push(@commitOnSuccessfulImport, $newSEColumn);

			}

			#######################################################################
			# Gather information for ST & SE labels
			#######################################################################
			my %label_dat = $self->_extractLabelData( $ST_XML, $newSemanticType->name(), $newSemanticType->description() );
			# Create or update the ST labels
			foreach my $lang( keys %label_dat ) {
				my $label = $factory->findObject( 'OME::SemanticType::Label', 
					semantic_type => $newSemanticType, 
					lang		  => $lang
				);
				if( $label ) {
					$label->label( $label_dat{ $lang }{ LabelText } );
					$label->description( $label_dat{ $lang }{ Description } );
				} else {
					$label = $factory->newObject( 'OME::SemanticType::Label', {
						semantic_type => $newSemanticType, 
						lang		  => $lang,
						label		  => $label_dat{ $lang }{ LabelText }, 
						description	  => $label_dat{ $lang }{ Description },
					} );
				}
				push(@commitOnSuccessfulImport, $label);
			}
			foreach my $SemanticElementXML ($ST_XML->getElementsByLocalName( "Element") ) {
				my $seName = $SemanticElementXML->getAttribute('Name');
				my $SE = (
					(
						exists( $semanticColumns->{$newSemanticType->name} ) &&
						exists( $semanticColumns->{$newSemanticType->name}->{ $seName } )
					) ? 
					$semanticColumns->{$newSemanticType->name}->{ $seName } :
					$factory->findObject( 'OME::SemanticType::Element', {
						semantic_type    => $newSemanticType,
						name			 => $seName
					} )
				) or die "could not load SE from the data hash or database. ST=".$newSemanticType->name."; SE=".$seName;
				my %label_dat = $self->_extractLabelData( $SemanticElementXML, $SE->name(), $SE->description() );
				# Create or update the SE labels
				foreach my $lang( keys %label_dat ) {
					my $label = $factory->findObject( 'OME::SemanticType::Element::Label', 
						semantic_element => $SE, 
						lang		     => $lang,
					);
					if( $label ) {
						$label->label( $label_dat{ $lang }{ LabelText } );
						$label->description( $label_dat{ $lang }{ Description } );
					} else {
						$label = $factory->newObject( 'OME::SemanticType::Element::Label', {
							semantic_element => $SE, 
							lang		     => $lang,
							label		     => $label_dat{ $lang }{ LabelText }, 
							description	     => $label_dat{ $lang }{ Description },
						} );
					}
					push(@commitOnSuccessfulImport, $label);
				}
			}

            push(@commitOnSuccessfulImport, $newSemanticType);
            push(@newSemanticTypes, $newSemanticType);
		}
		#
		# END "if ST doesn't exist, create it"
		#
		###########################################################################
		else {
            $newSemanticType = $existingSemanticType;
			logdbg "debug", ref ($self) ."->processDOM: semantic type already exists.";
		}
        $semanticTypes->{ $newSemanticType->name() } = $newSemanticType;
	}
	#
	# END "Make Semantic Types"
	#
	###########################################################################

	#
	# END 'Make new tables, columns, and Semantic types'
	#
	###############################################################################

	$_->storeObject() foreach @commitOnSuccessfulImport;
	@commitOnSuccessfulImport = ();

	my $dbh = $factory->obtainDBH();
	$delegate->addForeignKeyConstraints ($dbh,$_->getAttributeTypePackage())
       foreach @newSemanticTypes;

	$self->{semanticTypes} = $semanticTypes;
	$self->{semanticColumns} = $semanticColumns;

	my @returnTypes = values %$semanticTypes;
	return \@returnTypes;
}

# Utility function to reuse code between ST labels and SE labels. Also isolates
# changes to xml spec, which is currently under discussion.
sub _extractLabelData {
	my ( $self, $xml_node, $default_en_name, $default_en_descrip ) = @_;
	my %label_data;

	my @Labels_XML = $xml_node->childNodes;
	@Labels_XML = grep( 
		(
			( $_->nodeType() eq XML_ELEMENT_NODE() ) &&
			( $_->tagName() =~ m/Label$/o ) 
		),
		@Labels_XML
	);
	
	foreach my $label_xml ( @Labels_XML ) {
		my $lang = (
			$label_xml->getAttribute( "xml:lang" ) || # newer, correct versions of LibXML need the namespace
			$label_xml->getAttribute( "lang" )     || # older, buggy versions of LibXML need the namespace absent
			$default_lang                             # default language
		);
		$label_data{ $lang }{ LabelText } = $label_xml->firstChild()->nodeValue()
			if( $label_xml->hasChildNodes() );
		$label_data{ $lang }{ Description } = $self->_getDescription( $xml_node, $lang );
	}
	if( !exists( $label_data{ $default_lang } ) ) {
		$label_data{ $default_lang }{ LabelText }   = $default_en_name;
		$label_data{ $default_lang }{ Description } = $default_en_descrip;
	}
	
	return %label_data;
}

# Utility function to get a description from an ST or SE's DOM
# The lang input is optional and defaults to $default_lang
sub _getDescription {
	my ( $self, $xml_node, $lang ) = @_;
	my @description_list = $xml_node->childNodes;
	@description_list = grep( 
		(
			( $_->nodeType() eq XML_ELEMENT_NODE() ) &&
			( $_->tagName() =~ m/Description$/o ) 
		),
		@description_list
	);
	my $description;
	# If there is exactly one description, and a specific language was not requested,
	# return the single description
	if( ( scalar( @description_list ) == 1 ) && ! $lang ) {
		$description = $description_list[0];
	# If any descriptions are present, determine their language, search through
	# them for one to return. 
	# The desired language defaults to english, and the description's language
	# defaults to english.
	# If a specific language was requested, and a description in that language
	# is not available, no description will be returned.
	} elsif( scalar( @description_list ) >= 1 ) {
		# default to english
		$lang = $default_lang unless $lang;
		@description_list = grep( 
			( (				
				$_->getAttribute( "xml:lang" ) || # newer, correct versions of LibXML need the namespace
				$_->getAttribute( "lang" )	   || # older, buggy versions of LibXML need the namespace absent
				$default_lang					  # default language
			) eq $lang ), 
			@description_list
		);
		$description = $description_list[0] 
			if( scalar( @description_list ) > 0 );
	}
	my $descriptionText = (
		( $description && $description->hasChildNodes() ) ?
		[$description->childNodes()]->[0]->data() :
		''
	);
	return $descriptionText;
}

sub validateSTName ()
{
	my ($self, $stName) = @_;
	
	logdie ref($self) .": While processing Semantic Type $stName, ".
	"Semantic Types cannot have spaces in their names." if ($stName =~ m/\s/);
	
	logdie ref($self) .": While processing Semantic Type $stName, ".
	"Semantic Types must be comprised of only alpha-numerical and ".
	"underscore characters." if ($stName =~ m/\W+/);
}

sub validateSEName ()
{
	my ($self, $seName) = @_;
	
	logdie ref($self) .": While processing Semantic Element $seName, ".
	"Semantic Elements cannot have spaces in their names." if ($seName =~ m/\s/);
	
	logdie ref($self) .": While processing Semantic Element $seName, ".
	"Semantic Elements must be comprised of only alpha-numerical and ".
	"underscore characters." if ($seName =~ m/\W+/);
}

my %sql_reserved_words = (
	'ABSOLUTE' => 1,
	'ACTION' => 1,
	'ADD' => 1,
	'AFTER' => 1,
	'ALL' => 1,
	'ALLOCATE' => 1,
	'ALTER' => 1,
	'AND' => 1,
	'ANY' => 1,
	'ARE' => 1,
	'ARRAY' => 1,
	'AS' => 1,
	'ASC' => 1,
	'ASENSITIVE' => 1,
	'ASSERTION' => 1,
	'ASYMMETRIC' => 1,
	'AT' => 1,
	'ATOMIC' => 1,
	'AUTHORIZATION' => 1,
	'AVG' => 1,
	'BEFORE' => 1,
	'BEGIN' => 1,
	'BETWEEN' => 1,
	'BIGINT' => 1,
	'BINARY' => 1,
	'BIT' => 1,
	'BIT_LENGTH' => 1,
	'BLOB' => 1,
	'BOOLEAN' => 1,
	'BOTH' => 1,
	'BREADTH' => 1,
	'BY' => 1,
	'CALL' => 1,
	'CALLED' => 1,
	'CASCADE' => 1,
	'CASCADED' => 1,
	'CASE' => 1,
	'CAST' => 1,
	'CATALOG' => 1,
	'CHAR' => 1,
	'CHAR_LENGTH' => 1,
	'CHARACTER' => 1,
	'CHARACTER_LENGTH' => 1,
	'CHECK' => 1,
	'CLOB' => 1,
	'CLOSE' => 1,
	'COALESCE' => 1,
	'COLLATE' => 1,
	'COLLATION' => 1,
	'COLUMN' => 1,
	'COMMIT' => 1,
	'CONDITION' => 1,
	'CONNECT' => 1,
	'CONNECTION' => 1,
	'CONSTRAINT' => 1,
	'CONSTRAINTS' => 1,
	'CONSTRUCTOR' => 1,
	'CONTAINS' => 1,
	'CONTINUE' => 1,
	'CONVERT' => 1,
	'CORRESPONDING' => 1,
	'COUNT' => 1,
	'CREATE' => 1,
	'CROSS' => 1,
	'CUBE' => 1,
	'CURRENT' => 1,
	'CURRENT_DATE' => 1,
	'CURRENT_DEFAULT_TRANSFORM_GROUP' => 1,
	'CURRENT_PATH' => 1,
	'CURRENT_ROLE' => 1,
	'CURRENT_TIME' => 1,
	'CURRENT_TIMESTAMP' => 1,
	'CURRENT_TRANSFORM_GROUP_FOR_TYPE' => 1,
	'CURRENT_USER' => 1,
	'CURSOR' => 1,
	'CYCLE' => 1,
	'DATA' => 1,
	'DATE' => 1,
	'DAY' => 1,
	'DEALLOCATE' => 1,
	'DEC' => 1,
	'DECIMAL' => 1,
	'DECLARE' => 1,
	'DEFAULT' => 1,
	'DEFERRABLE' => 1,
	'DEFERRED' => 1,
	'DELETE' => 1,
	'DEPTH' => 1,
	'DEREF' => 1,
	'DESC' => 1,
	'DESCRIBE' => 1,
	'DESCRIPTOR' => 1,
	'DETERMINISTIC' => 1,
	'DIAGNOSTICS' => 1,
	'DISCONNECT' => 1,
	'DISTINCT' => 1,
	'DO' => 1,
	'DOMAIN' => 1,
	'DOUBLE' => 1,
	'DROP' => 1,
	'DYNAMIC' => 1,
	'EACH' => 1,
	'ELEMENT' => 1,
	'ELSE' => 1,
	'ELSEIF' => 1,
	'END' => 1,
	'EQUALS' => 1,
	'ESCAPE' => 1,
	'EXCEPT' => 1,
	'EXCEPTION' => 1,
	'EXEC' => 1,
	'EXECUTE' => 1,
	'EXISTS' => 1,
	'EXIT' => 1,
	'EXTERNAL' => 1,
	'EXTRACT' => 1,
	'FALSE' => 1,
	'FETCH' => 1,
	'FILTER' => 1,
	'FIRST' => 1,
	'FLOAT' => 1,
	'FOR' => 1,
	'FOREIGN' => 1,
	'FOUND' => 1,
	'FREE' => 1,
	'FROM' => 1,
	'FULL' => 1,
	'FUNCTION' => 1,
	'GENERAL' => 1,
	'GET' => 1,
	'GLOBAL' => 1,
	'GO' => 1,
	'GOTO' => 1,
	'GRANT' => 1,
	'GROUP' => 1,
	'GROUPING' => 1,
	'HANDLER' => 1,
	'HAVING' => 1,
	'HOLD' => 1,
	'HOUR' => 1,
	'IDENTITY' => 1,
	'IF' => 1,
	'IMMEDIATE' => 1,
	'IN' => 1,
	'INDICATOR' => 1,
	'INITIALLY' => 1,
	'INNER' => 1,
	'INOUT' => 1,
	'INPUT' => 1,
	'INSENSITIVE' => 1,
	'INSERT' => 1,
	'INT' => 1,
	'INTEGER' => 1,
	'INTERSECT' => 1,
	'INTERVAL' => 1,
	'INTO' => 1,
	'IS' => 1,
	'ISOLATION' => 1,
	'ITERATE' => 1,
	'JOIN' => 1,
	'KEY' => 1,
	'LANGUAGE' => 1,
	'LARGE' => 1,
	'LAST' => 1,
	'LATERAL' => 1,
	'LEADING' => 1,
	'LEAVE' => 1,
	'LEFT' => 1,
	'LEVEL' => 1,
	'LIKE' => 1,
	'LIMIT' => 1,
	'LOCAL' => 1,
	'LOCALTIME' => 1,
	'LOCALTIMESTAMP' => 1,
	'LOCATOR' => 1,
	'LOOP' => 1,
	'LOWER' => 1,
	'MAP' => 1,
	'MATCH' => 1,
	'MAX' => 1,
	'MEMBER' => 1,
	'MERGE' => 1,
	'METHOD' => 1,
	'MIN' => 1,
	'MINUTE' => 1,
	'MODIFIES' => 1,
	'MODULE' => 1,
	'MONTH' => 1,
	'MULTISET' => 1,
	'NAMES' => 1,
	'NATIONAL' => 1,
	'NATURAL' => 1,
	'NCHAR' => 1,
	'NCLOB' => 1,
	'NEW' => 1,
	'NEXT' => 1,
	'NO' => 1,
	'NONE' => 1,
	'NOT' => 1,
	'NULL' => 1,
	'NULLIF' => 1,
	'NUMERIC' => 1,
	'OBJECT' => 1,
	'OCTET_LENGTH' => 1,
	'OF' => 1,
	'OFFSET' => 1,
	'OLD' => 1,
	'ON' => 1,
	'ONLY' => 1,
	'OPEN' => 1,
	'OPTION' => 1,
	'OR' => 1,
	'ORDER' => 1,
	'ORDINALITY' => 1,
	'OUT' => 1,
	'OUTER' => 1,
	'OUTPUT' => 1,
	'OVER' => 1,
	'OVERLAPS' => 1,
	'PAD' => 1,
	'PARAMETER' => 1,
	'PARTIAL' => 1,
	'PARTITION' => 1,
	'PATH' => 1,
	'POSITION' => 1,
	'PRECISION' => 1,
	'PREPARE' => 1,
	'PRESERVE' => 1,
	'PRIMARY' => 1,
	'PRIOR' => 1,
	'PRIVILEGES' => 1,
	'PROCEDURE' => 1,
	'PUBLIC' => 1,
	'RANGE' => 1,
	'READ' => 1,
	'READS' => 1,
	'REAL' => 1,
	'RECURSIVE' => 1,
	'REF' => 1,
	'REFERENCES' => 1,
	'REFERENCING' => 1,
	'RELATIVE' => 1,
	'RELEASE' => 1,
	'REPEAT' => 1,
	'RESIGNAL' => 1,
	'RESTRICT' => 1,
	'RESULT' => 1,
	'RETURN' => 1,
	'RETURNS' => 1,
	'REVOKE' => 1,
	'RIGHT' => 1,
	'ROLE' => 1,
	'ROLLBACK' => 1,
	'ROLLUP' => 1,
	'ROUTINE' => 1,
	'ROW' => 1,
	'ROWS' => 1,
	'SAVEPOINT' => 1,
	'SCHEMA' => 1,
	'SCOPE' => 1,
	'SCROLL' => 1,
	'SEARCH' => 1,
	'SECOND' => 1,
	'SECTION' => 1,
	'SELECT' => 1,
	'SENSITIVE' => 1,
	'SESSION' => 1,
	'SESSION_USER' => 1,
	'SET' => 1,
	'SETS' => 1,
	'SIGNAL' => 1,
	'SIMILAR' => 1,
	'SIZE' => 1,
	'SMALLINT' => 1,
	'SOME' => 1,
	'SPACE' => 1,
	'SPECIFIC' => 1,
	'SPECIFICTYPE' => 1,
	'SQL' => 1,
	'SQLCODE' => 1,
	'SQLERROR' => 1,
	'SQLEXCEPTION' => 1,
	'SQLSTATE' => 1,
	'SQLWARNING' => 1,
	'START' => 1,
	'STATE' => 1,
	'STATIC' => 1,
	'SUBMULTISET' => 1,
	'SUBSTRING' => 1,
	'SUM' => 1,
	'SYMMETRIC' => 1,
	'SYSTEM' => 1,
	'SYSTEM_USER' => 1,
	'TABLE' => 1,
	'TABLESAMPLE' => 1,
	'TEMPORARY' => 1,
	'THEN' => 1,
	'TIME' => 1,
	'TIMESTAMP' => 1,
	'TIMEZONE_HOUR' => 1,
	'TIMEZONE_MINUTE' => 1,
	'TO' => 1,
	'TRAILING' => 1,
	'TRANSACTION' => 1,
	'TRANSLATE' => 1,
	'TRANSLATION' => 1,
	'TREAT' => 1,
	'TRIGGER' => 1,
	'TRIM' => 1,
	'TRUE' => 1,
	'UNDER' => 1,
	'UNDO' => 1,
	'UNION' => 1,
	'UNIQUE' => 1,
	'UNKNOWN' => 1,
	'UNNEST' => 1,
	'UNTIL' => 1,
	'UPDATE' => 1,
	'UPPER' => 1,
	'USAGE' => 1,
	'USER' => 1,
	'USING' => 1,
	'VALUE' => 1,
	'VALUES' => 1,
	'VARCHAR' => 1,
	'VARYING' => 1,
	'VIEW' => 1,
	'WHEN' => 1,
	'WHENEVER' => 1,
	'WHERE' => 1,
	'WHILE' => 1,
	'WINDOW' => 1,
	'WITH' => 1,
	'WITHIN' => 1,
	'WITHOUT' => 1,
	'WORK' => 1,
	'WRITE' => 1,
	'YEAR' => 1,
	'ZONE' => 1);

sub deriveDBLocation ()
{
	my ($self, $stName, $seName) = @_;
	
	# checks for SQL reserved words
	$stName = $stName."_st" if (exists $sql_reserved_words{uc($stName)});
	$seName = $seName."_se" if (exists $sql_reserved_words{uc($seName)});

	# check for starting with a digit
	$stName = "st_$stName" if ($stName =~ '^\d');
	$seName = "se_$seName" if ($seName =~ '^\d');

	return $stName.".".$seName;
}

1;
