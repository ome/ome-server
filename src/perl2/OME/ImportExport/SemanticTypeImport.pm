# OME/Tasks/SemanticTypeImport.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
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


package OME::Tasks::SemanticTypeImport;

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

    die "I need a session"
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
    my $doc = $self->{_parser}->parse_file($filename)
      or die "Cannot parse file $filename";
    return $self->processDOM($doc->getDocumentElement(),%flags);
}

sub importXML {
    my ($self, $xml, %flags) = @_;
    my $doc = $self->{_parser}->parse_string($xml)
      or die "Cannot parse XML string";
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

sub processDOM {
    my ($self, $root, %flags) = @_;
    my $debug   = $self->{debug};
    my $session = $self->{session};
    my $factory = $session->Factory();

    my $ignoreAlterTableErrors = $flags{IgnoreAlterTableErrors};

    my @commitOnSuccessfulImport;

    ###############################################################################
    #
    # Make new tables, columns, and Attribute types
    #
    # semanticTypes is keyed by name, valued by DBObject AttributeType
    my $semanticTypes;

    # semanticColumns is a double keyed hash
    #   keyed by {Attribute_Type.Name}->{Attribute_Column.Name}
    #   valued by DBObject AttributeColumn
    my $semanticColumns;

    my $SemanticDefinitionsXML = $root;
    #  getElementsByLocalName("SemanticTypeDefinitions" )->[0];
    #printElement($SemanticDefinitionsXML);

    my $dataDefinitionsXML = $SemanticDefinitionsXML->
      getElementsByLocalName('DataDefinitions')->[0];
    #printElement($dataDefinitionsXML);

    print STDERR ref ($self) . 
      "->processDOM: about to process SemanticTypeDefinitions\n"
      if $debug > 0;

    ###########################################################################
    #
    # Process Record and Column elements. Make new tables and columns as needed.
    #
    # dataColumns is a hash
    #   keyed by {FieldID}
    #   valued by DBobject DataColumn
    my %dataColumns;

    print STDERR ref ($self) .
      "->processDOM: about to process tables and columns\n"
      if $debug > 1;

    my @tables = $dataDefinitionsXML->getElementsByLocalName( "Record" );

    foreach my $tableXML (@tables) {
        my $tName = $tableXML->getAttribute('Name');
        my $tDescription = $tableXML->getAttribute('Description');
        my $tGranularity = $tableXML->getAttribute('AppliesTo');

        #######################################################################
        #
        # Process a Record
        #
        print STDERR ref ($self) . 
          "->processDOM: looking for table ".$tName."\n"
          if $debug > 1;
        my @tables = $factory->findObjects( "OME::DataTable", 'table_name' => $tName );

        my $newTable;
        if ( scalar(@tables) == 0 ) { # the table doesn't exist. create it.
            print STDERR ref ($self) . 
              "->processDOM: table not found. creating it.\n"
              if $debug > 1;
            my $data = {
                        table_name  => $tName,
                        description => $tDescription,
                        granularity => $tGranularity,
                       };
            print STDERR ref ($self) . 
              "->processDOM: OME::DataTable DBObject parameters are\n\t".
              join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
              if $debug > 1;

            $newTable = $factory->newObject( "OME::DataTable", $data )
              or die ref($self)." could not create OME::DataTable. name=$tName";

            print STDERR ref ($self) . 
              "->processDOM: successfully created OME::DataTable DBObject\n"
              if $debug > 1;

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
                ANALYSIS_ID   OID REFERENCES ANALYSES
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

            print STDERR ref ($self) . 
              "->processDOM: about to create table in DB using statement\n".
              $statement."\n"
              if $debug > 1;

            my $dbh = $session->DBH();
            my $sth;
            eval { $sth = $dbh->prepare( $statement ) };

            if ($@) {
                if ($ignoreAlterTableErrors) {
                    $dbh->commit();
                    print STDERR "\n  *** Ignoring error $@\n\n"
                      if $debug > 1;
                } else {
                    die "Could not prepare Table create statement when making table ".
                      $newTable->table_name()."\nStatement was\n$statement";
                }
            }

            eval { $sth->execute() };

            if ($@) {
                if ($ignoreAlterTableErrors) {
                    $dbh->commit();
                    print STDERR "\n  *** Ignoring error $@\n\n"
                      if $debug > 1;
                } else {
                    die "Unable to create table ".$newTable->table_name()."\n";
                }
            }

            $statement = "COMMENT ON TABLE $tName IS ?";
            $sth = $dbh->prepare($statement)
              or die "Could not prepare comment for table $tName";
            $sth->execute($tDescription)
              or die "Could not add comment to table $tName";

            print STDERR ref ($self) .
              "->processDOM: successfully created table\n"
              if $debug > 1;
            #
            #
            ###################################################################

            push(@commitOnSuccessfulImport, $newTable);
        } else {
            print STDERR ref ($self) .
              "->processDOM: found table. using existing table.\n"
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

        my @columns = $tableXML->getElementsByLocalName( "Field" );
        foreach my $columnXML (@columns) {
            my $cName = $columnXML->getAttribute('Name');
            my $cFieldID = $columnXML->getAttribute('FieldID');
            my $cDescription = $columnXML->getAttribute('Description');
            my $cDataType = $columnXML->getAttribute('DataType');
            my $cReferenceType = $columnXML->getAttribute('ReferenceType');

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

            my $sqlDataType = $dataTypeConversion{$cDataType};

            print STDERR ref ($self) .
              "->processDOM: searching OME::DataTable::Column with\n\t".
              "data_table_id=".$newTable->id()."\n\tcolumn_name=$cName\n"
              if $debug > 1;

            my $cols = $factory->
              findObject("OME::DataTable::Column",
                         {
                          data_table_id => $newTable->id(),
                          column_name   => $cName
                         });

            my $newColumn;

            if (!defined $cols) {
                print STDERR ref ($self) . 
                  "->processDOM: could not find matching column. creating it\n"
                    if $debug > 1;

                my $data     = {
                                data_table_id  => $newTable,
                                column_name    => $cName,
                                description    => $cDescription,
                                sql_type       => $cDataType,
                                reference_type => $cReferenceType,
                               };

                print STDERR ref ($self) .
                  "->processDOM: OME::DataTable::Column DBObject parameters are\n".
                  "\t".join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
                  if $debug > 1;

                $newColumn = $factory->
                  newObject( "OME::DataTable::Column", $data )
                    or die "Could not create OME::DataType::Column object\n";

                print STDERR ref ($self) . 
                  "->processDOM: created OME::DataTable::Column DBObject\n"
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
                    "   ADD ".$newColumn->column_name()." ".$sqlDataType;
                my $dbh = $session->DBH();
                my $sth;
                eval { $sth = $dbh->prepare( $statement ) };

                if ($@) {
                    if ($ignoreAlterTableErrors) {
                        $dbh->commit();
                        print STDERR "\n  *** Ignoring error $@\n\n"
                          if $debug > 1;
                    } else {
                        die "Could not prepare statment when adding column ".
                          $newColumn->column_name()." to table ".
                          $newTable->table_name()."\nStatement:\n$statement";
                    }
                }

                print STDERR ref ($self) .
                  "->processDOM: about to create column in DB using statement".
                  "\n$statement\n"
                  if $debug > 1;

                eval { $sth->execute() };
                if ($@) {
                    if ($ignoreAlterTableErrors) {
                        $dbh->commit();
                        print STDERR "\n  *** Ignoring error $@\n\n"
                          if $debug > 1;
                    } else {
                        die "Unable to create column ".$newColumn->column_name().
                          " in table ".$newTable->table_name();
                    }
                }

                print STDERR ref ($self) . "->processDOM: created column in db\n"
                  if $debug > 1;
                #
                #
                ################################################################

                push(@commitOnSuccessfulImport, $newColumn);
            } else {
                die "Found matching column with different sql data type."
                  unless $cols->sql_type() eq $cDataType;

                print STDERR ref ($self) . 
                  "->processDOM: found column. using existing column.\n"
                  if $debug > 1;
                $newColumn = $cols;
            }

            $dataColumns{$cFieldID} = $newColumn;
        }

        #
        # END 'Process columns in this table'
        #
        ########################################################################
        print STDERR ref ($self) . 
          "->processDOM: finished processing columns in that table\n"
          if $debug > 1;


        # Force this data table to regenerate its Perl package.  (So
        # that the new columns become visible)
        $newTable->requireDataTablePackage(1);
    }

    print STDERR ref ($self) . 
      "->processDOM: finished processing tables\n"
      if $debug > 1;
    #
    # END 'Process Table and Column elements. Make new tables and columns as needed.'
    #
    ###########################################################################

    ###########################################################################
    #
    # Make AttributeTypes
    #
    print STDERR ref ($self) .
      "->processDOM: making new AttributeTypes from SemanticTypes\n"
      if $debug > 1;

    my @types =  $SemanticDefinitionsXML->getElementsByLocalName( "SemanticType" );

    foreach my $semanticTypeXML (@types) {
        my $stName = $semanticTypeXML->getAttribute('SemanticTypeName');
        my $stDescription = $semanticTypeXML->getAttribute('Description');

        # look for existing AttributeType
        print STDERR ref($self).
          "->processDOM is looking for an OME::AttributeType ".
          "object\n\t[name=$stName]\n"
          if $debug > 1;
        my $existingAttrType = $factory->
          findObject("OME::AttributeType",
                     name => $stName);

        my $newAttrType;
        ###########################################################################
        #
        # if AttributeType doesn't exist, create it
        #
        if ( not defined $existingAttrType ) {
            print STDERR ref ($self) .
              "->processDOM: couldn't find it. creating it.\n"
              if $debug > 1;

            my $data = {
                        name        => $stName,
                        granularity => 'F',
                        description => $stDescription,
                       };

            # Granularity is set properly below. DB set up won't let
            # us use NULL for it and we don't have enough info to know
            # what it is yet.

            print STDERR ref ($self) . 
              "->processDOM: about to make a new OME::AttributeType. ".
              "(granularity will be reset below) parameters are\n\t".
              join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n"
              if $debug > 1;

            $newAttrType = $factory->newObject("OME::AttributeType",$data)
              or die ref ($self) . 
              " could not create new object of type OME::AttributeType with".
              "parameters:\n\t".
                join( "\n\t", map { $_."=>".$data->{$_} } keys %$data )."\n";

            print STDERR ref ($self) . 
              "->processDOM: made a new OME::AttributeType object\n"
              if $debug > 1;


            #######################################################################
            #
            # make OME::AttributeType::Column objects
            #
            my $granularity;
            my $tableName;

            print STDERR ref ($self) .
              "->processDOM: about to make AttributeColumns from SemanticElements".
              "in this SemanticType\n"
              if $debug > 1;

            foreach my $SemanticElementXML ($semanticTypeXML->getElementsByLocalName( "SemanticElement") ) {
                my $seName = $SemanticElementXML->getAttribute('Name');
                my $seFieldID = $SemanticElementXML->getAttribute('FieldID');
                my $seDescription = $SemanticElementXML->
                  getAttribute('Description');

                print STDERR ref ($self) .
                  "->processDOM: processing attribute column,\n\tname=$seName\n"
                  if $debug > 1;

                #check ColumnID
                die ref ($self) . 
                  " could not find entry for column '$seName'\n"
                  unless exists $dataColumns{$seFieldID};

                my $dataColumn = $dataColumns{$seFieldID};

                #check granularity
                my $attrColumnGranularity =
                  $dataColumn->data_table()->granularity();

                $granularity = $attrColumnGranularity
                  if (not defined $granularity);

                die ref ($self) . " SemanticType (name=$stName)".
                  " has elements with different granularities. Died on element ".
                  "($stName.$seName) ".
                  " with granularity '$attrColumnGranularity'"
                  unless $granularity eq $attrColumnGranularity;

                #check table
#                 $tableName = $SemanticElementXML->getAttribute('TableName')
#                   if (not defined $tableName);
#                 die ref ($self) . " SemanticType (name=".$semanticTypeXML->getAttribute('SemanticTypeName').") has elements in multiple tables. Died on column (SemanticTypeName=".$SemanticElementXML->getAttribute('SemanticTypeName').", SemanticTypeName=".$SemanticElementXML->getAttribute('SemanticTypeName').") in table '".$SemanticElementXML->getAttribute('TableName')."'"
#                   unless $tableName eq $SemanticElementXML->getAttribute('TableName');

                #Create object

                my $newAttrColumn = $factory->
                  newObject( "OME::AttributeType::Column",
                             {
                              attribute_type => $newAttrType,
                              name           => $seName,
                              data_column    => $dataColumn,
                              description    => $seDescription,
                             })
                  or die ref ($self) . 
                    " could not create new OME::AttributeType::Column object, ".
                    "name = $seName";

                $semanticColumns->{$stName}->{ $seName } =
                  $newAttrColumn;
                print STDERR ref ($self) . 
                  "->processDOM added entry to semanticColumns.\n\t".
                    "$stName.$seName => $newAttrColumn\n"
                  if $debug > 1;

                push(@commitOnSuccessfulImport, $newAttrColumn);

                print STDERR ref ($self) . 
                  "->processDOM finished processing attribute column $seName\n"
                  if $debug > 1;
            }
            print STDERR ref ($self) . 
              "->processDOM: finished making AttributeColumns ".
              "from SemanticElements\n"
              if $debug > 1;
            #
            #
            #######################################################################

            $newAttrType->granularity( $granularity );
            print STDERR ref ($self) . 
              "->processDOM: determined granularity. Setting ".
              "granularity to '$granularity'. \n"
              if $debug > 1;
            push(@commitOnSuccessfulImport, $newAttrType);
        }
        #
        # END "if AttributeType doesn't exist, create it"
        #
        ###########################################################################
        
        
        ###########################################################################
        #
        # AttributeType exists, verify that the attribute columns are identical
        #       also, populate formalInputColumn_xmlID_dbObject hash
        #
        else { 
            print STDERR ref ($self) . 
              "->processDOM: found a OME::AttributeType object with matching ".
              "name. inspecting it to see if it completely matches.\n"
              if $debug > 1;

            my @attrColumns = $existingAttrType->attribute_columns();
            my @xmlColumns = $semanticTypeXML->
              getElementsByLocalName('SemanticElement');

            die ref ($self) . " While processing Semantic Type (name=$stName), ".
              "found existing AttributeType with same name and a different number".
              " of columns. Existing AttributeType has ".scalar(@attrColumns).
              " columns, new AttributeType of same name has ".
                scalar(@xmlColumns)." columns."
              unless (scalar(@attrColumns) eq scalar(@xmlColumns));

            foreach my $SemanticElementXML (@xmlColumns) {
                my $seName = $SemanticElementXML->getAttribute('Name');
                my $seFieldID = $SemanticElementXML->getAttribute('FieldID');
                my $seDescription = $SemanticElementXML->
                  getAttribute('Description');

                #check ColumnID

                die ref ($self) .
                  " While processing Semantic Type (name=$stName), could not ".
                  "find matching data column for SemanticTypeName '$seName'\n"
                  unless exists $dataColumns{$seFieldID};

                my $dataColumn = $dataColumns{$seFieldID};

                #find existing AttributeType::Column object
                #corrosponding to SemanticElementXML

                map {
                    $semanticColumns->{$existingAttrType->name()}->{$seName} = $_
                      if $dataColumn->id() eq $_->data_column()->id();
                } @attrColumns;

                print STDERR ref ($self) . 
                  "->processDOM: added entry to semanticColumns.\n\t".
                    $newAttrType->name().".$seName=>".
                    $semanticColumns->{$newAttrType->name()}->{ $seName }."\n"
                  if $debug > 1;

                die ref ($self) . 
                  " While processing Semantic Type (name=".
                  $existingAttrType->name()."), found existing AttributeType with ".
                  "the same name. Could not find matching column in existing ".
                  "AttributeType for new AttributeColumn (Name=$seName)"
                  unless exists $semanticColumns->{$existingAttrType->name()}->
                    { $seName };
            }

            $newAttrType = $existingAttrType;
            print STDERR ref ($self) . 
              "->processDOM: determined the Attribute types match. ".
              "using existing attribute type.\n"
              if $debug > 1;
        }
        #
        # END "AttributeType exists, verify that the attribute columns are identical"
        #
        ###########################################################################

        $semanticTypes->{ $newAttrType->name() } = $newAttrType;
        print STDERR ref ($self) . 
          "->processDOM: finished processing semanticType ".
            $newAttrType->name()."\n"
          if $debug > 1;


        # Force this attribute type to regenerate its Perl
        # package.  (So that the new columns become visible)
        $newAttrType->requireAttributeTypePackage(1);
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

    $_->writeObject() foreach @commitOnSuccessfulImport;
    @commitOnSuccessfulImport = ();

    $session->DBH()->commit();

    $self->{semanticTypes} = $semanticTypes;
    $self->{semanticColumns} = $semanticColumns;

    my @returnTypes = values %$semanticTypes;
    return \@returnTypes;
}


1;
