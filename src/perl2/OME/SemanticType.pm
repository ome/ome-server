# OME/SemanticType.pm

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


package OME::SemanticType;

=head1 NAME

OME::SemanticType - data object representing attribute types

=head1 SYNOPSIS

	use OME::SemanticType;

	# Load object via primary key
	my $atype = $factory->loadObject("OME::SemanticType",1);

	# Ensure that instance package is created
	my $pkg = $atype->requireAttributeTypePackage();

	# Create a new instance of this attribute type via primary key
	my $attribute = $pkg->load(1);

=head1 DESCRIPTION

OME::SemanticType serves two purposes.  First, it functoins just like
any other OME DBObject, representing rows from the semantic_types
table in the OME database.  More importantly, though, it serves as the
means of creating data classes for each attribute type, similar to how
OME::DataTable create data classes for each attribute table.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use Log::Agent;
use OME::DBObject;
use OME::DataTable;
use OME::Remote::Prototypes;
use base qw(OME::DBObject);

use Benchmark qw(timediff timesum);

__PACKAGE__->mk_classdata('_sortTime');
__PACKAGE__->mk_classdata('_dbTime');
__PACKAGE__->mk_classdata('_createTime');

__PACKAGE__->mk_classdata('GuessRows');
__PACKAGE__->GuessRows(0);

__PACKAGE__->mk_classdata('_attributeTypePackages');
__PACKAGE__->_attributeTypePackages({});

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('semantic_types');
__PACKAGE__->setSequence('semantic_type_seq');
__PACKAGE__->addPrimaryKey('semantic_type_id');
__PACKAGE__->addColumn(name => 'name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                        Unique  => 1,
                       });
__PACKAGE__->addColumn(granularity => 'granularity',
                       {
                        SQLType => 'char(1)',
                        NotNull => 1,
                        Check   => "(granularity in ('G','D','I','F'))",
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});
__PACKAGE__->hasMany('semantic_elements',
                     'OME::SemanticType::Element' => 'semantic_type');


=head1 METHODS

The following methods are available in addition to those defined by
L<OME::DBObject>.

=head2 name

	my $name = $type->name();
	$type->name($name);

Returns or sets the name of this semantic type.

=head2 description

	my $description = $type->description();
	$type->description($description);

Returns or sets the description of this semantic type.

=head2 granularity

	my $granularity = $type->granularity();
	$type->granularity($granularity);

Returns or sets the granularity of this semantic type.  Will be either
'G', 'D', 'I', or 'F'.

=head2 semantic_elements

	my @columns = $type->semantic_elements();
	my $column_iterator = $type->semantic_elements();

Returns or iterates, depending on context, a list of all of the
C<Columns> associated with this module_execution.

=cut

sub __formPackageName {
    my ($self,$name) = @_;
    $name =~ s/[^\w\d]/_/g;
    return "OME::SemanticType::__$name";
}

sub getAttributeTypePackage {
    my $self = shift;
    return $self->__formPackageName($self->name());
}

sub requireAttributeTypePackage {
    my ($self,$force) = @_;
    my $pkg = $self->getAttributeTypePackage();
    return $pkg
      if (!$force) && (exists $self->_attributeTypePackages()->{$pkg});
    logdbg "debug", "Loading attribute type package $pkg";

    logcroak "Malformed class name $pkg"
      unless $pkg =~ /^\w+(\:\:\w+)*$/;

    $self->_attributeTypePackages()->{$pkg} = 1;

    my $factory = $self->Session()->Factory();

    # Create the base definition of the semantic instance class.
    my $def = "package $pkg;\n";
    $def .= q{
	use strict;
        use OME;
	our $VERSION = $OME::VERSION;

	use OME::SemanticType::Superclass;
	use base qw(OME::SemanticType::Superclass);
    };

    eval $def;

    $pkg->_attribute_type($self);
    $pkg->newClass();
    $pkg->setSequence('attribute_seq');
    $pkg->addPseudoColumn('semantic_type',
                          'has-one','OME::SemanticType');


    # Any one of the tables that this type is stored in; doesn't
    # matter which.
    my $any_table;

    #print STDERR "********\n";

    my @semantic_elements = $self->semantic_elements();
    foreach my $semantic_element (@semantic_elements) {
        my $name = $semantic_element->name();
        my $data_column = $semantic_element->data_column();
        my $column_name = $data_column->column_name();
        my $type = $data_column->sql_type();
        my $sql_type = OME::DataTable->getSQLType($type);
        my $data_table = $data_column->data_table();
        my $table_name = $data_table->table_name();
        $data_table->requireDataTablePackage($force);

        $any_table = $table_name unless defined $any_table;

        # It doesn't matter if we add the primary key more than once
        # per table, DBObject can deal.
        $pkg->addPrimaryKey("${table_name}.attribute_id");

        #print STDERR $self->name(),".$name $sql_type\n";

        if ($type eq 'reference') {
            # We've got a reference to another semantic type.  In most
            # cases, we just need to load in that type's definition,
            # create the appropriate semantic type class, and create a
            # foreign key column to that class.  However, during
            # bootstrap (or any other time when the referred-to type
            # does not exist yet), the factory call will return undef.
            # Our only real solution in this case is to assume that
            # the bootstrap/XML installer will install the appropriate
            # type definition soon.  In this case, we create the
            # foreign key link without creating the semantic type
            # package.

            my $reference_type_name = $data_column->reference_type();
            my $reference_type = $factory->
              findObject('OME::SemanticType',name => $reference_type_name);
            my $reference_pkg = '@'.$reference_type_name;

            $pkg->addColumn($name,"${table_name}.${column_name}",
                            $reference_pkg,
                            {
                             SQLType => $sql_type,
                            });

            # Make this method visible via the Remote Framework
            my $remote_pkg =
              (defined $reference_type)?
                $reference_type->requireAttributeTypePackage():
                $self->__formPackageName($reference_type_name);
            addPrototype($pkg,$name,
                         [$remote_pkg],
                         [$remote_pkg],
                         force => 1);
        } else {
            # FIXME: Maybe we should allow data columns to specify
            # things like NotNUll, Unique, Indexed, etc.?
            $pkg->addColumn($name,"${table_name}.${column_name}",
                            {
                             SQLType => $sql_type,
                            });

            # Make this method visible via the Remote Framework
            addPrototype($pkg,$name,['$'],['$'],force => 1);
        }
    }

    $pkg->addColumn(module_execution_id => "${any_table}.module_execution_id");
    $pkg->addColumn(module_execution => "${any_table}.module_execution_id",
                    'OME::ModuleExecution',
                    {
                     SQLType => 'integer',
                     Indexed => 1,
                     ForeignKey => 'module_executions',
                    });

    # Make accessors for actual output, dataset, image, and feature.
    my $type = $self->granularity();

    if ($type eq 'D') {
        $pkg->addColumn(['dataset_id','target_id'] => "${any_table}.dataset_id");
        $pkg->addColumn(['dataset','target'] => "${any_table}.dataset_id",
                        'OME::Dataset',
                        {
                         SQLType => 'integer',
                         NotNull => 1,
                         Indexed => 1,
                         ForeignKey => 'datasets',
                        });
        addPrototype($pkg,"dataset",[],['OME::Dataset'],force => 1);
    } elsif ($type eq 'I') {
        $pkg->addColumn(['image_id','target_id'] => "${any_table}.image_id");
        $pkg->addColumn(['image','target'] => "${any_table}.image_id",
                        'OME::Image',
                        {
                         SQLType => 'integer',
                         NotNull => 1,
                         Indexed => 1,
                         ForeignKey => 'images',
                        });
        addPrototype($pkg,"image",[],['OME::Image'],force => 1);
    } elsif ($type eq 'F') {
        $pkg->addColumn(['feature_id','target_id'] => "${any_table}.feature_id");
        $pkg->addColumn(['feature','target'] => "${any_table}.feature_id",
                        'OME::Feature',
                        {
                         SQLType => 'integer',
                         NotNull => 1,
                         Indexed => 1,
                         ForeignKey => 'features',
                        });
        addPrototype($pkg,"feature",[],['OME::Feature'],force => 1);
    } elsif ($type eq 'G') {
        # No global column - create dummy target and target_id methods
        # which always return undef.
        my $accessor = sub { return undef; };
        no strict 'refs';
        *{"$pkg\::target"} = $accessor;
        *{"$pkg\::target_id"} = $accessor;
    }
    use strict 'refs';

    return $pkg;
}

sub dataTables {
    my ($self) = @_;

    my %tables;

    foreach my $attr_column ($self->semantic_elements()) {
        my $data_table = $attr_column->data_column()->data_table();
        $tables{$data_table->id()} = $data_table;
    }

    return values %tables;
}

sub __debug {
    #logdbg "debug", @_;
    #print STDERR @_, "\n";
}

sub __resetTiming {
    my ($self) = @_;

    $self->_sortTime(undef);
    $self->_dbTime(undef);
    $self->_createTime(undef);
}

sub __addOneTime {
    my ($self,$name,$time) = @_;

    my $old_time = $self->$name();
    if (defined $old_time) {
        $self->$name(timesum($old_time,$time));
    } else {
        $self->$name($time);
    }
}

sub __addTiming {
    my ($self,$sort,$db,$create) = @_;

    $self->__addOneTime('_sortTime',$sort);
    $self->__addOneTime('_dbTime',$db);
    $self->__addOneTime('_createTime',$create);
}

sub __getSeconds {
    my ($self,$name) = @_;
    my $t = $self->$name();
    return 0 unless defined $t;
    return $t->[0];
}

# Creates a new attribute of a given semantic type, attempting to place
# it into a preexisting data row if possible.

sub __createNewAttribute {
    my ($self,$session,$module_execution,$semantic_type,$data_hash) = @_;

    # We need to look for data rows that satisfy the following criteria:
    #   - The columns from this ST that overlap with other ST's are
    #     equal to the appropriate values in $data_hash
    #   - The other columns from this ST are null
    #
    # Further, we need at least one of these data rows for each data
    # table that the ST lives in, each with the same attribute_id.
    #
    # If we can find this set of data rows, then it is eligible to be
    # used to store this new attribute.  If not, we must create new
    # data rows to store it.

    my $factory = $session->Factory();

    my %tables;
    my %columns;
    my %elements;
    my %table_criteria;

    my %granularityColumns =
      (
       'G' => undef,
       'D' => 'target',
       'I' => 'target',
       'F' => 'target'
      );

    my %granularityClasses = 
      (
       'D' => 'OME::Dataset',
       'I' => 'OME::Image',
       'F' => 'OME::Feature',
      );

    my $granularity = $semantic_type->granularity();
    my $target_column = $granularityColumns{$granularity};

    my $target_id = defined $target_column?
      $data_hash->{$target_column}: undef;

    if (ref($target_id)) {
        $target_id = $target_id->id();
    }

    my %criteria;

    $criteria{module_execution} =
      $module_execution
      if defined $module_execution;
    $criteria{$target_column} = $target_id
      if defined $target_column;

    my @elements = $semantic_type->semantic_elements();
    foreach my $element (@elements) {
        my $data_column_id = $element->data_column_id();

        my $overlap = $factory->
          objectExists("OME::SemanticType::Element",
                       {
                        data_column_id => $data_column_id,
                        semantic_type  => ['<>',$semantic_type],
                       });

        $criteria{$element->name()} =
          $overlap? $data_hash->{$element->name()}: undef;
    }

    my $matching_attribute = $factory->
      findAttribute($semantic_type,\%criteria);

    my $new_attribute;

    if (defined $matching_attribute) {
        # We found a reusable set of rows.  Arbitrarily choose the
        # first ID in the list.

        $new_attribute = $matching_attribute;
        #print "Found attribute $new_attribute\n";

        foreach my $element_name (keys %$data_hash) {
            $new_attribute->$element_name($data_hash->{$element_name});
        }
        $new_attribute->storeObject();
    } else {
        # We did not find a reusable set of rows.

        # Factory will add the target on its own
        delete $data_hash->{$target_column} if defined $target_column;

        $new_attribute = $factory->newAttribute($semantic_type,
                                                $target_id,
                                                $module_execution,
                                                $data_hash);
        #print "New attribute $new_attribute\n";
    }

    return $new_attribute;
}

# This is the new version of newAttributes, which will try to place
# attributes one by one into existing rows.  It is more useful, but
# slower.

sub newAttributesWithGuessing {
    my ($self,$session,$module_execution,@attribute_info) = @_;

    my ($i, $length);
    $length = scalar(@attribute_info);

    my @attributes;

    for ($i = 0; $i < $length; $i += 2) {
        my $semantic_type = $attribute_info[$i];
        my $data_hash = $attribute_info[$i+1];

        push @attributes, $self->__createNewAttribute($session,
                                                      $module_execution,
                                                      $semantic_type,
                                                      $data_hash);
    }

    return \@attributes;
}

# This is the version of newAttributes which places all of the attributes
# specified in a single call into a single row.

sub newAttributesInOneRow {
    my ($self,$session,$module_execution,@attribute_info) = @_;

    my $t0 = new Benchmark;

    # These hashes are keyed by table name.
    my %data_tables;
    my %data;
    my %targets;
    my %granularities;

    # These hashes are keyed by attribute type ID.
    my %attribute_tables;

    # Merge the attribute data hashes into hashes for each data table.
    # Also, mark which data tables belong to each attribute.

    __debug("Merging attributes");

    #$session->BenchmarkTimer->start("----------Merging attributes");

    my %granularityColumns =
      (
       'G' => undef,
       'D' => 'target',
       'I' => 'target',
       'F' => 'target'
      );

    my ($semantic_type, $data_hash);
    my ($i, $length);
    my $factory = $session->Factory();

    $length = scalar(@attribute_info);

    for ($i = 0; $i < $length; $i += 2) {
        $semantic_type = $attribute_info[$i];
        $data_hash = $attribute_info[$i+1];

        my $semantic_pkg = $semantic_type->requireAttributeTypePackage();
        my $columns = $semantic_pkg->__columns();
        my @semantic_elements = $semantic_type->semantic_elements();
        my $granularity = $semantic_type->granularity();
        my $granularityColumn = $granularityColumns{$granularity};

        __debug("  ".$semantic_type->name()." (".scalar(@semantic_elements)." columns)");

        # Follow each attribute column to its location in the
        # database.  Mark some information about that data table, and
        # ensure that all of the attributes and data tables merge
        # properly.  Specifically, make sure that if two attributes
        # are writing to the same data column, then they write the
        # same value.  Also, ensure that each data table that an
        # attribute writes to is of the same granularity as the
        # attribute itself.

        #foreach my $semantic_element_name (keys %$data_hash) {
        foreach my $column (@semantic_elements) {
            my $semantic_element_name = $column->name();

            my $column_entry = $columns->{$semantic_element_name};

            die "$semantic_element_name is not an element of ".
              $semantic_type->name()
              unless defined $column_entry;

            my $table_name = $column_entry->[0];
            my $column_name = $column_entry->[1];

            __debug("    $semantic_element_name -> ${table_name}.$column_name");

            # Mark that $semantic_type resides in $table_name.
            $attribute_tables{$semantic_type->id()}->{$table_name} = 1;

            # Save the data table for later.
            $data_tables{$table_name} = 1;

            if (exists $granularities{$table_name}) {
                die "Granularities clash!"
                  if ($granularity ne $granularities{$table_name});
            } else {
                $granularities{$table_name} = $granularity;
            }

            # Build the data hash for this data table.

            if (defined $granularityColumn) {
                my $new_target = $data_hash->{$granularityColumn};
                if (exists $targets{$table_name}) {
                    my $old_target = $targets{$table_name};
                    croak "Targets clash"
                      if ($new_target ne $old_target);
                }
                $targets{$table_name} = $new_target;
            }

            # Pull out the datum from the attribute hash.
            my $new_data = $data_hash->{$semantic_element_name};

            #__debug("      = $new_data");

            # If we've already filled in this column in the data table
            # hash, ensure it doesn't clash with this new piece of
            # data.

            if (!defined $new_data) {
                croak "Attribute values clash"
                  if defined $data{$table_name}->{$column_name};
            } else {
                if (exists $data{$table_name}->{$column_name}) {
                    my $old_data = $data{$table_name}->{$column_name};
                    #__debug("      ?= $old_data");
                    croak "Attribute values clash"
                      if ($new_data ne $old_data);
                }
            }

            # Store the datum into the data table hash.
            $data{$table_name}->{$column_name} = $new_data;
        }
    }

    #$session->BenchmarkTimer->stop("----------Merging attributes");

    my $t1 = new Benchmark;

    # Now, create a new row in each data table.

    my %data_rows;
    my $id;

    __debug("Creating data rows");
    #$session->BenchmarkTimer->start("----------Creating data rows");

    foreach my $table_name (keys %data_tables) {
        #my $data_table = $data_tables{$table_name};

        __debug("  Table $table_name");

        #foreach my $column_name (sort keys %$data) {
        #    __debug("    $column_name = ".$data->{$column_name}."\n");
        #}

        # We've already created the correct data hash.  However, we
        # want all of the data rows to have the same ID.  So, if we've
        # created an ID already, use it, otherwise, allow the Factory
        # to assign a new ID.

        $data{$table_name}->{__id} = $id
          if (defined $id);

        $data{$table_name}->{target} = $targets{$table_name}
          if defined $targets{$table_name};

        $data{$table_name}->{module_execution} = $module_execution;

        my $data_pkg = OME::DataTable->__formPackageName($table_name);

        my $data_row = $factory->
          newObject($data_pkg,$data{$table_name});

        $id = $data_row->id()
          if (!defined $id);

        # Store the new data row objects so that we can create the
        # attributes from then.

        $data_rows{$table_name} = $data_row;
    }

    # Now, create attribute objects from the data rows we just
    # created.  Also, add appropriate entries to the
    # SEMANTIC_TYPE_OUTPUTS table if necessary.

    my @attributes;

    #$session->BenchmarkTimer->stop("----------Creating data rows");
    my $t2 = new Benchmark;

    __debug("Creating attributes");
    #$session->BenchmarkTimer->start("----------Creating attributes");

    my $module = $module_execution->module()
      if defined $module_execution;

    for ($i = 0; $i < $length; $i += 2) {
        $semantic_type = $attribute_info[$i];
        $data_hash = $attribute_info[$i+1];

        my $attribute = $factory->loadAttribute($semantic_type,$id);

        # Add the SEMANTIC_TYPE_OUTPUT entry
		#     if there is a mex defined and
		#        there is neither a module defined for this mex nor 
		#                         a formal output of this type
#		$factory->maybeNewObject("OME::ModuleExecution::SemanticTypeOutput", {
#			module_execution_id => $module_execution,
#			semantic_type_id    => $semantic_type,
#		}) if (defined $module_execution and
#              ( not $module_execution->module() or
#                not $factory->findObject("OME::Module::FormalOutput",
#		                module_id        => $module_execution->module,
#		                semantic_type_id => $semantic_type 
#		            )
#		      ) );

        push @attributes, $attribute;
    }

    my $t3 = new Benchmark;
    #$session->BenchmarkTimer->stop("----------Creating attributes");

    my $sort_time = timediff($t1,$t0);
    my $db_time = timediff($t2,$t1);
    my $create_time = timediff($t3,$t2);

    $self->__addTiming($sort_time,$db_time,$create_time);

    return \@attributes;
}

# Currently newAttributes defaults to the no-guessing version.

sub newAttributes {
    my $self = shift;
    if ($self->GuessRows()) {
        return $self->newAttributesWithGuessing(@_);
    } else {
        return $self->newAttributesInOneRow(@_);
    }
}


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

