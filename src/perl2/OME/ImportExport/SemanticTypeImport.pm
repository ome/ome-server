# OME/ImportExport/SemanticTypeImport.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:  Josiah Johnston <siah@nih.gov>
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


package OME::ImportExport::SemanticTypeImport;

use strict;
our $VERSION = '1.0';

use Carp;
use Log::Agent;
use XML::LibXML;


sub new {
    my ($proto, %params) = @_;
    my $class = ref($proto) || $proto;

    my @fieldsILike = qw(session _parser debug);

    my $self;

    @$self{@fieldsILike} = @params{@fieldsILike};

    logdie "I need a session"
      unless exists $self->{session} &&
             UNIVERSAL::isa($self->{session},'OME::Session');

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
        print "  ".$_->nodeName."\n";
    }
}

=head2 processDOM( $root, %flags )

Note: You must call commit on the DBH attached to this object's session after calling processDOM.
Changes to tables and columns are made on that handle, but shouldn't be committed here.

=cut
sub processDOM {
    my ($self, $root, %flags) = @_;
    my $debug   = $self->{debug};
    my $session = $self->{session};
    my $factory = $session->Factory();

    my $ignoreAlterTableErrors = $flags{IgnoreAlterTableErrors};

    my @commitOnSuccessfulImport;

    my %dataTypeConversion = (
                              # XMLType  => SQL_Type
                              integer  => 'integer',
                              double   => 'double precision',
                              float    => 'real',
                              boolean  => 'boolean',
                              string   => 'text',
                              dateTime => 'timestamp',
                              reference => 'oid'
                             );

    ###############################################################################
    #
    # Make new tables, columns, and Attribute types
    #
    # semanticTypes is keyed by name, valued by DBObject AttributeType
    my $semanticTypes;

    # semanticColumns is a double keyed hash
    #   keyed by {semantic_type.Name}->{semantic_element.Name}
    #   valued by DBObject AttributeColumn
    my $semanticColumns;

    my $SemanticDefinitionsXML = $root;
    #  getElementsByLocalName("SemanticTypeDefinitions" )->[0];
    #printElement($SemanticDefinitionsXML);
    my ($tName,$cName);
    my ($tables,$table);

    logdbg "debug", ref ($self) . 
      "->processDOM: about to process SemanticTypeDefinitions\n";

    ###########################################################################
    #
    # First pass through the STDs.
    #   Check for conflicting STDs.
    #   Make new tables and columns as needed.
    #
    # dataColumns is a hash used to store the DataColumn where a Semantic Element lives.
    # It gets populated when we are making tables/columns after the first pass through the STs
    # and gets used when we make the STs in the DB on the second pass.
    # The hash is:
    #   keyed by {$tName.'.'.$cName} (i.e. DBLocation of the Semantic Element)
    #   valued by DBobject DataColumn
    my %dataColumns;

    logdbg "debug", ref ($self) .
      "->processDOM: about to process tables and columns\n";

    my @STDs = $root->getElementsByLocalName( 'SemanticType' );

    foreach my $ST_XML (@STDs) {
    ###########################################################################
    #
    # Check if the attribute type exists, and if so that it doesn't conflict.
    #
        my $stName = $ST_XML->getAttribute('Name');
        $semanticTypes->{ $stName } = undef;
		my $stDescriptions = $ST_XML->getElementsByLocalName('Description');
		my $stDescription = [$stDescriptions->[0]->childNodes()]->[0]->data()
			if $stDescriptions;
        my @SEs_XML = $ST_XML->getElementsByLocalName ('Element');

        # look for existing AttributeType
        logdbg "debug", ref($self).
          "->processDOM is looking for an OME::SemanticType ".
          "object called:\n\t$stName";
        my $existingAttrType = $factory->
          findObject("OME::SemanticType",
                     name => $stName);

        my $newAttrType;
        ###########################################################################
        #
        # if AttributeType exists, make sure the new one doesn't conflict.
        # All attribute elements must be identical to avoid conflict:
        # 		Name, DBLocation, DataType, RefersTo
        # If it does conflict, its a fatal error.
        #
        if (defined $existingAttrType ) {
            logdbg "debug", ref ($self) . 
              "->processDOM: found a OME::SemanticType object with matching ".
              "name ($stName). inspecting it to see if it completely matches.";

            my @attrColumns = $existingAttrType->semantic_elements();

            logdie ref ($self) . ": While processing Semantic Type $stName, ".
              " existing $stName has ".scalar(@attrColumns).
              " columns, new declaration has ".scalar(@SEs_XML)." columns."
              unless (scalar(@attrColumns) eq scalar(@SEs_XML));

            foreach my $SemanticElementXML (@SEs_XML) {
                my $seName = $SemanticElementXML->getAttribute('Name');
                my $seDBloc = $SemanticElementXML->getAttribute('DBLocation');
                my $seDataType = $SemanticElementXML->getAttribute('DataType');
                my $seReferenceTo = $SemanticElementXML->getAttribute('RefersTo');
                my $attrCol;
                foreach (@attrColumns) {
                    if ($_->name() eq $seName) {
                        $attrCol = $_;
                        last;
                    };
                }
                logdie ref ($self) . ": While processing existing Semantic Type $stName, ".
                    "existing declaration has no Semantic Element $seName."
                    unless defined $attrCol and $attrCol->name() eq $seName;
                
                my $attrDBloc = $attrCol->data_column()->data_table()->table_name().'.'.$attrCol->data_column()->column_name();
                logdie ref ($self) . ": While processing Semantic Type $stName, ".
                    "existing semantic element $seName is stored in $attrDBloc instead of $seDBloc."
                    unless defined $attrDBloc and $attrDBloc eq $seDBloc;

                my $attrDataType = $attrCol->data_column()->sql_type();
                logdie ref ($self) . ": While processing Semantic Type $stName, ".
                    "existing semantic element $seName has data type $attrDataType instead of $seDataType."
                    unless defined $attrDataType and $attrDataType eq $seDataType;

                my $attrReferenceTo = $attrCol->data_column()->reference_type();
                logdie ref ($self) . ": While processing Semantic Type $stName, ".
                    "existing semantic element $seName refers to $attrReferenceTo instead of $seReferenceTo."
                    if defined $attrReferenceTo and not ($attrReferenceTo eq $seReferenceTo);
            }
            logdbg "debug", ref ($self) . 
              "->processDOM: Complete match between revious and current definition of $stName.";
    # END:  Check for conflict with existing Semantic Type.
    ###########################################################################
        }            
   
    ###########################################################################
    # Build the table hash:
    # $granularity = $tables{$tableName}->{granularity};
    # @tDescriptions = $tables{$tableName}->{description};    # array of ST descriptions
    # $datatype = $tables{$tableName}->{columns}->{$cName}->{datatype};
    # $referenceTo_DBObject = $tables{$tableName}->{columns}->{$cName}->{reference}->{DBObject};
    # $referenceTo_STname = $tables{$tableName}->{columns}->{$cName}->{reference}->{STname};
    # @cDescriptions = $tables{$tableName}->{columns}->{$cName}->{description}; # array of SE descriptions
        foreach my $SE_XML (@SEs_XML) {
            my $DBLocation = $SE_XML->getAttribute('DBLocation');
            my $dataType = $SE_XML->getAttribute('DataType');
            ($tName,$cName) = split (/\./,$DBLocation);
            if (not exists $tables->{$tName}){
                $tables->{$tName}->{columns} = {};
                $tables->{$tName}->{description} = [];
                $tables->{$tName}->{name} = $tName;
                $tables->{$tName}->{order} = scalar (keys %{$tables}) + 1;
            }
            
            # Put the required column in the table hash.
            # If the column doesn't exist yet and is a reference,
            # try to get the DBObject it points to from the DB.
            if (not exists ($tables->{$tName}->{columns}->{$cName})) {
                $tables->{$tName}->{columns}->{$cName}->{datatype} = $dataType;
                if ($dataType eq 'reference') {
                    my $referenceTo = $SE_XML->getAttribute('RefersTo');
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
			my $cDescriptions = $SE_XML->getElementsByLocalName('Description');
			my $cDescription = [$cDescriptions->[0]->childNodes()]->[0]->data()
				if $cDescriptions;
            push (@{$tables->{$tName}->{columns}->{$cName}->{description}},$cDescription)
                if defined $cDescription and length ($cDescription) > 0;
        }
        $tables->{$tName}->{granularity} = $ST_XML->getAttribute('AppliesTo');
		my $tDescriptions = $ST_XML->getElementsByLocalName('Description');
		my $tDescription = [$tDescriptions->[0]->childNodes()]->[0]->data()
			if $tDescriptions;
        push (@{$tables->{$tName}->{description}},$tDescription)
           if defined $tDescription and length ($tDescription) > 0;
    }

    # END:  First pass on semantic types: Checking conflicts and gathering required tables.
    ###########################################################################
    
    
    #######################################################################
    #
    # Create the necessary tables
    #
    foreach $table  ( sort { $a->{order} <=> $b->{order} } values %$tables ) {
        $tName = $table->{name};
        logdbg "debug", ref ($self) . 
          "->processDOM: looking for table ".$tName."\n";
        my @DT_tables = $factory->findObjects( "OME::DataTable", 'table_name' => $tName );

        my $newTable;
        if ( scalar(@DT_tables) == 0 ) { # the table doesn't exist. create it.
            logdbg "debug", ref ($self) . 
              "->processDOM: table not found. creating it.\n";
            my $data = {
                        table_name  => $tName,
                        description => $table->{description}->[0],
                        granularity => $table->{granularity},
                       };
            logdbg "debug", ref ($self) . 
              "->processDOM: OME::DataTable DBObject parameters are\n\t".
              join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n";

            $newTable = $factory->newObject( "OME::DataTable", $data )
              or logdie ref($self)." could not create OME::DataTable. name=$tName";

            logdbg "debug", ref ($self) . 
              "->processDOM: successfully created OME::DataTable DBObject\n";

            ###################################################################
            #
            # Make the table in the database. 
            # Should this functionality be moved to OME::Datatype 
            # so making a new entry there will cause a new table
            # to be created?
            #
            my $statement = "
                CREATE TABLE $tName (
                ATTRIBUTE_ID  OID DEFAULT NEXTVAL('ATTRIBUTE_SEQ') PRIMARY KEY,
                module_execution_id   OID REFERENCES MODULE_EXECUTIONS
                              DEFERRABLE INITIALLY DEFERRED";

            if ( $newTable->granularity() eq 'I' ) {
                $statement .= ",
                IMAGE_ID      OID NOT NULL REFERENCES IMAGES
                              DEFERRABLE INITIALLY DEFERRED";
            } elsif ( $newTable->granularity() eq 'D' ) {
                $statement .= ",
                DATASET_ID    OID NOT NULL REFERENCES DATASETS
                              DEFERRABLE INITIALLY DEFERRED";
            } elsif ( $newTable->granularity() eq 'F' ) {
                $statement .= ",
                FEATURE_ID    OID NOT NULL REFERENCES FEATURES
                              DEFERRABLE INITIALLY DEFERRED";
            }
            $statement .= ")";

            logdbg "debug", ref ($self) . 
              "->processDOM: about to create table in DB using statement\n".
              $statement."\n";

            my $dbh = $session->DBH();
            my $sth;
            eval { $sth = $dbh->prepare( $statement ) };

            if ($@) {
                if ($ignoreAlterTableErrors) {
                    $dbh->commit();
                    logdbg "debug", "\n  *** Ignoring error $@\n\n";
                } else {
                    logdie "Could not prepare Table create statement when making table ".
                      $newTable->table_name()."\nStatement was\n$statement";
                }
            }

            eval { $sth->execute() };

            if ($@) {
                if ($ignoreAlterTableErrors) {
                    $dbh->commit();
                    logdbg "debug", "\n  *** Ignoring error $@\n\n";
                } else {
                    logdie "Unable to create table ".$newTable->table_name().". Error message was:\n$@\n";
                }
            }

            if (length ($newTable->description()) > 0 ) {
                $statement = "COMMENT ON TABLE $tName IS ?";
                $sth = $dbh->prepare($statement)
                  or logdie "Could not prepare comment for table $tName";
                $sth->execute($newTable->description())
                  or logdie "Could not add comment to table $tName";
    
                logdbg "debug", ref ($self) .
                  "->processDOM: successfully created table\n";
            }
            #
            #
            ###################################################################

            push(@commitOnSuccessfulImport, $newTable);
        } else {
            logdbg "debug", ref ($self) .
              "->processDOM: found table. using existing table.\n";
            $newTable = $DT_tables[0];
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
              "->processDOM: searching OME::DataTable::Column with\n\t".
              "data_table_id=".$newTable->id()."\n\tcolumn_name=$cName";

            my $cols = $factory->
              findObject("OME::DataTable::Column",
                          data_table_id => $newTable->id(),
                          column_name   => $cName
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

                my $data     = {
                                'data_table_id'  => $newTable->id(),
                                'column_name'    => $cName,
                                'description'    => $column->{description}->[0],
                                'sql_type'       => 'foo',
#                                'sql_type'       => $dataType,
#                                'sql_type'       => $sqlDataType,  # NOT!
# FIXME - IGG:
# Believe it or not, setting sql_type to $dataType fails in $factory->newObject for some (but not all) 'integer's with:
#   Failure while doing 'MakeNewObj' with 'New OME::DataTable::Column'
#   DBD::Pg::st execute failed: ERROR:  Attribute 'integer' not found at /Library/Perl/Ima/DBI.pm line 733.
#   at /Library/Perl/OME/Tasks/SemanticTypeImport.pm line 428
# The only hope is to set it to a literal string.  Yes, the offending 'integer's are 'eq' and '==' to 'integer' string literals,
# and $sqlDataType gets set properly, so there are no hidden gremlins in there.
# If you know why and have a better fix, please have at it.
# The best idea I can come up with is maybe some inconsistent implementation of unicode.
#
# The usage of sql_type indicates that this is in fact the XML datatype, not a SQL type (which is good IMHO),
# specifically with regard to 'reference'.  sql_type should really be renamed to datatype, though.
                                'reference_type' => $column->{reference}->{STname}
                               };

                logdbg "debug", ref ($self) .
                  "->processDOM: OME::DataTable::Column DBObject parameters are\n".
                  "\t".join( "\n\t", map { $_."=>'".$data->{$_}."'" } keys %$data );

                $newColumn = $factory->newObject( 'OME::DataTable::Column', $data )
                    or logdie "Could not create OME::DataType::Column object";
#
# This is the continuation of the sql_type fiasco.  $newColumn->sql_type($dataType) won't let you commit the object with the offending 'integer'.
# Only the string literal will do.
                if ($dataType eq 'integer') {
                    $newColumn->sql_type('integer');
                } else {
                    $newColumn->sql_type($dataType);
                }
                logdbg "debug", ref ($self) . 
                  "->processDOM: created OME::DataTable::Column DBObject\n";

                ################################################################
                #
                # Create the column in the database. 
                # Should this functionality be moved to OME::DataTable::Column 
                # so making a new entry there will cause a new column
                # to be created?
                #
                my $statement =
                  "ALTER TABLE ".$newTable->table_name().
                    " ADD COLUMN ".$newColumn->column_name()." ".$sqlDataType;
                my $dbh = $session->DBH();
                my $sth;
                eval { $sth = $dbh->prepare( $statement ) };

                if ($@) {
                    if ($ignoreAlterTableErrors) {
                        $dbh->commit();
                        logdbg "debug", "\n  *** Ignoring error $@\n\n";
                    } else {
                        logdie "Could not prepare statment when adding column ".
                          $newColumn->column_name()." to table ".
                          $newTable->table_name()."\nStatement:\n$statement";
                    }
                }

                logdbg "debug", ref ($self) .
                  "->processDOM: about to create column in DB using statement".
                  "\n$statement\n";

                eval { $sth->execute() };
                if ($@) {
                    if ($ignoreAlterTableErrors) {
                        $dbh->commit();
                        logdbg "debug", "\n  *** Ignoring error $@\n\n";
                    } else {
                        logdie "Unable to create column ".$newColumn->column_name().
                          " in table ".$newTable->table_name();
                    }
                }
                
                if (length ($newColumn->description()) > 0 ) {
					$statement = 'COMMENT ON COLUMN '.$newTable->table_name().'.'.$newColumn->column_name().' IS ?';
					$sth = $dbh->prepare($statement)
					  or logdie "Could not prepare comment for table $tName";
					$sth->execute($newColumn->description())
					  or logdie "Could not add comment to table $tName";
		
					logdbg "debug", ref ($self) .
					  "->processDOM: successfully created table\n";
           	 	}


                logdbg "debug", ref ($self) . "->processDOM: created column in db\n";
                #
                #
                ################################################################

                push(@commitOnSuccessfulImport, $newColumn);
            } else {
                logdie "Found matching column with different sql data type."
                  unless $cols->sql_type() eq $column->{datatype};

                logdbg "debug", ref ($self) . 
                  "->processDOM: found column. using existing column.\n";
                $newColumn = $cols;
            }
            
            $dataColumns{$tName.'.'.$cName} = $newColumn;


        }

        #
        # END 'Process columns in this table'
        #
        ########################################################################
        logdbg "debug", ref ($self) . 
          "->processDOM: finished processing columns in that table\n";


        # Force this data table to regenerate its Perl package.  (So
        # that the new columns become visible)
        $newTable->requireDataTablePackage(1);
    }

    logdbg "debug", ref ($self) . 
      "->processDOM: finished processing tables\n";
    #
    # END make necessary tables
    #
    ###########################################################################

    ###########################################################################
    #
    # Make AttributeTypes
    #
    logdbg "debug", ref ($self) .
      "->processDOM: making new AttributeTypes from SemanticTypes\n";

    foreach my $ST_XML (@STDs) {
        my $stName = $ST_XML->getAttribute('Name');
        my $stGranularity = $ST_XML->getAttribute('AppliesTo');
		my $stDescriptions = $ST_XML->getElementsByLocalName('Description');
		my $stDescription = [$stDescriptions->[0]->childNodes()]->[0]->data()
			if $stDescriptions;

        # look for existing AttributeType
        # If the AttributeType exists, we already know it doesn't conflict from the first pass.
        logdbg "debug", ref($self).
          "->processDOM is looking for an OME::SemanticType ".
          "object\n\t[name=$stName]\n";
        my $existingAttrType = $factory->
          findObject("OME::SemanticType",
                     name => $stName);

        my $newAttrType;
        ###########################################################################
        #
        # if AttributeType doesn't exist, create it
        #
        if ( not defined $existingAttrType ) {
            logdbg "debug", ref ($self) .
              "->processDOM: couldn't find it. creating it.\n";

            my $data = {
                        name        => $stName,
                        granularity => $stGranularity,
                        description => $stDescription,
                       };

            logdbg "debug", ref ($self) . 
              "->processDOM: about to make a new OME::SemanticType for $stName.\n\t".
              join( "\n\t", map { $_."=>".$data->{$_} } keys %$data );

            $newAttrType = $factory->newObject("OME::SemanticType",$data)
              or logdie ref ($self) . 
              " could not create new object of type OME::SemanticType with".
              "parameters:\n\t".
                join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n";

            logdbg "debug", ref ($self) . 
              "->processDOM: made a new OME::SemanticType object\n";


            #######################################################################
            #
            # make OME::SemanticType::Element objects
            #
            logdbg "debug", ref ($self) .
              "->processDOM: about to make AttributeColumns from SemanticElements for $stName";

            foreach my $SemanticElementXML ($ST_XML->getElementsByLocalName( "Element") ) {
                my $seName = $SemanticElementXML->getAttribute('Name');
                my $seDBloc = $SemanticElementXML->getAttribute('DBLocation');
				my $seDescriptions = $SemanticElementXML->getElementsByLocalName('Description');
				my $seDescription = [$seDescriptions->[0]->childNodes()]->[0]->data()
					if $seDescriptions;

                logdbg "debug", ref ($self) .
                  "->processDOM: processing attribute column,\n\tname=$seName\n";

                #check ColumnID
                logdie ref ($self) . 
                  " could not find entry for column '$seName'\n"
                  unless exists $dataColumns{$seDBloc};

                my $dataColumn = $dataColumns{$seDBloc};

                #Create object

                my $newAttrColumn = $factory->
                  newObject( "OME::SemanticType::Element",
                             {
                              semantic_type => $newAttrType,
                              name           => $seName,
                              data_column    => $dataColumn,
                              description    => $seDescription,
                             })
                  or logdie ref ($self) . 
                    " could not create new OME::SemanticType::Element object, ".
                    "name = $seName";

                $semanticColumns->{$stName}->{ $seName } =
                  $newAttrColumn;
                logdbg "debug", ref ($self) . 
                  "->processDOM added entry to semanticColumns.\n\t".
                    "$stName.$seName => $newAttrColumn\n";

                push(@commitOnSuccessfulImport, $newAttrColumn);

                logdbg "debug", ref ($self) . 
                  "->processDOM finished processing attribute column $seName\n";
            }
            logdbg "debug", ref ($self) . 
              "->processDOM: finished making AttributeColumns ".
              "from SemanticElements\n";
            #
            #
            #######################################################################

            push(@commitOnSuccessfulImport, $newAttrType);
        }
        #
        # END "if AttributeType doesn't exist, create it"
        #
        ###########################################################################
        else {
            $newAttrType = $existingAttrType;
            logdbg "debug", ref ($self) . 
              "->processDOM: using existing attribute type.\n";
        }

        $semanticTypes->{ $newAttrType->name() } = $newAttrType;
        logdbg "debug", ref ($self) . 
          "->processDOM: finished processing semanticType ".
            $newAttrType->name()."\n";


        # Force this attribute type to regenerate its Perl
        # package.  (So that the new columns become visible)
        $newAttrType->requireAttributeTypePackage(1);
    }
    #
    # END "Make AttributeTypes"
    #
    ###########################################################################

    logdbg "debug", ref ($self) . "->processDOM: finished processing SemanticTypeDefinitions\n";

    #
    # END 'Make new tables, columns, and Semantic types'
    #
    ###############################################################################

    $_->storeObject() foreach @commitOnSuccessfulImport;
    @commitOnSuccessfulImport = ();

    $self->{semanticTypes} = $semanticTypes;
    $self->{semanticColumns} = $semanticColumns;

    my @returnTypes = values %$semanticTypes;
    return \@returnTypes;
}


1;
