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

	use OME::SemanticType;
	use base qw(OME::SemanticType::Superclass);
    };

    eval $def;

    $pkg->_attribute_type($self);
    $pkg->newClass();
    $pkg->setSequence('attribute_seq');

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
        $data_table->requireDataTablePackage();

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
            my $reference_pkg =
              (defined $reference_type)?
                $reference_type->requireAttributeTypePackage():
                $self->__formPackageName($reference_type_name);

            $pkg->addColumn($name,"${table_name}.${column_name}",
                            $reference_pkg,
                            {
                             SQLType => $sql_type,
                            });

            # Make this method visible via the Remote Framework
            addPrototype($pkg,$name,
                         [$reference_pkg],
                         [$reference_pkg],
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
       'D' => 'dataset_id',
       'I' => 'image_id',
       'F' => 'feature_id'
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

    $criteria{module_execution_id} =
      $module_execution->id()
      if defined $module_execution;
    $criteria{$target_column} = $target_id
      if defined $target_column;

    my @elements = $semantic_type->semantic_elements();
    foreach my $element (@elements) {
        my $data_column_id = $element->data_column_id();

        my @overlaps = $factory->
          findObjects("OME::SemanticType::Element",
                      data_column_id => $data_column_id);
        my $overlap = scalar(@overlaps) > 1;

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
       'D' => 'dataset_id',
       'I' => 'image_id',
       'F' => 'feature_id'
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

        #if (defined $module) {
        #    my $formal_output = $factory->
        #      findObject("OME::Module::FormalOutput",
        #                 module_id => $module->id(),
        #                 semantic_type_id => $semantic_type->id());

            # Only create the entry if the attribute is for an untyped
            # output.
        #    if (!defined $formal_output) {
        #        my $data_hash =
        #          {
        #           module_execution_id => $module_execution->id(),
        #           semantic_type_id    => $semantic_type->id(),
        #          };
        #        $factory->
        #          maybeNewObject("OME::ModuleExecution::SemanticTypeOutput",
        #                         $data_hash);
        #    }
        #}

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


package OME::SemanticType::Element;

=head1 NAME

OME::SemanticType::Element

=head1 DESCRIPTION

This C<SemanticType.Element> interface represents one element of a
semantic type.  The storage type of the element can be accessed via
the element's data column:

	my $data_column = $semantic_element->data_column();
	my $sql_type = $data_column->sql_type();

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use OME::Factory;
use base qw(OME::DBObject);


__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('semantic_elements');
__PACKAGE__->setSequence('semantic_element_seq');
__PACKAGE__->addPrimaryKey('semantic_element_id');
__PACKAGE__->addColumn(semantic_type_id => 'semantic_type_id');
__PACKAGE__->addColumn(semantic_type => 'semantic_type_id',
                       'OME::SemanticType',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'semantic_types',
                       });
__PACKAGE__->addColumn(name => 'name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(data_column_id => 'data_column_id');
__PACKAGE__->addColumn(data_column => 'data_column_id',
                       'OME::DataTable::Column',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'data_columns',
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});


=head1 METHODS

The following methods are available in addition to those defined by
L<OME::DBObject>.

=head2 name

	my $name = $type->name();
	$type->name($name);

Returns or sets the name of this semantic element.

=head2 description

	my $description = $type->description();
	$type->description($description);

Returns or sets the description of this semantic element.

=head2 semantic_type

	my $semantic_type = $type->semantic_type();
	$type->semantic_type($semantic_type);

Returns or sets the attribute type that this semantic element belongs
to.

=head2 data_column

	my $data_column = $type->data_column();
	$type->data_column($data_column);

Returns or sets the data column associated with this semantic element.

=cut

package OME::SemanticType::Superclass;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use Class::Data::Inheritable;

use base qw(OME::DBObject Class::Data::Inheritable);

__PACKAGE__->mk_classdata('_attribute_type');

use fields qw(_data_table_rows _target _module_execution _id );

=head1 NAME

OME::SemanticType::Superclass

=head1 DESCRIPTION

The C<AttributeType::Superclass> class is the superclass every piece of
semantically-typed data in OME.  This includes attributes created by
the user during image import, and any attributes created as output by
the execution of module_execution modules.

Each attribute has a single semantic type, which is represented by an
instance of L<AttributeType>.  Based on the semantic type's
granularity, the attribute will be a property of (or, equivalently,
has a target of) a dataset, image, or feature, or it will be a global
attribute (and have a target of C<undef>.)

Most attributes will be generated computationally as the result of an
analysis module.  The module_execution (and by extension, module) which
generated the attribute can be retrieved with the L<getAnalysis()>
method.

=head1 METHODS

The following methods are available to all attribute subclasses.  In
addition, accessor/mutator methods will automatically be created for
each semantic element in the attribute's semantic type.

=cut

=pod

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($session,$target,$id,$rows) = @_;

    die "Cannot create attribute without data rows"
      if !scalar(%$rows);

    my $self = {};
    $self->{_data_table_rows} = $rows;
    $self->{_target} = $target;
    $self->{_id} = $id;

    my $module_execution;
    foreach my $row (values %$rows) {
        $module_execution = $row->module_execution();
        last if defined $module_execution;
    }
    $self->{_module_execution} = $module_execution;

    bless $self, $class;
    return $self;
}

sub load {
    my ($proto,$session,$id) = @_;
    my $class = ref($proto) || $proto;

    my $rows = {};
    my ($target,$module_execution);
    my $factory = $session->Factory();

    my $semantic_type = $class->_attribute_type();
    my $granularity = $semantic_type->granularity();
    my $semantic_elements = $semantic_type->semantic_elements();
	my $found_data_row = 0;

    while (my $semantic_element = $semantic_elements->next()) {
        my $data_column = $semantic_element->data_column();
        my $data_table = $data_column->data_table();
        my $data_table_pkg = $data_table->requireDataTablePackage();
        my $data_tableID = $data_table->id();
        next if exists $rows->{$data_tableID};

        my $data_row = $factory->loadObject($data_table_pkg,$id);
		next unless defined $data_row;
		$found_data_row = 1;

        $rows->{$data_tableID} = $data_row;

        if (!defined $target) {
            if ($granularity eq 'D') {
                $target = $data_row->dataset();
            } elsif ($granularity eq 'I') {
                $target = $data_row->image();
            } elsif ($granularity eq 'F') {
                $target = $data_row->feature();
            }
        }

        if (!defined $module_execution) {
            $module_execution = $data_row->module_execution();
        }
    }

	return undef unless $found_data_row;
    return $class->new($session,$target,$id,$rows);
}

=cut

=head2 verifyType

	$attribute->verifyType($type_name);

Ensures that this attribute has the given semantic type.  If not, an
exception is thrown.  The semantic type is specified by name, and is
retrieved using the factory that created the attribute.

=cut

sub verifyType {
    my ($self, $type_name) = @_;
    die "Object is not an attribute"
      unless UNIVERSAL::isa($self,__PACKAGE__);
    my $type = $self->_attribute_type();
    my $real_name = $type->name();
    die "Attribute is of the wrong type: Expected $type_name, got $real_name"
      unless $type_name eq $real_name;
    return 1;
}

=head2 id

	my $id = $attribute->id();

Returns the primary key ID of the attribute.

=head2 Session

	my $session = $attribute->Session();

Returns the OME session used to create this attribute.

=head2 semantic_type

	my $semantic_type = $attribute->semantic_type();

Returns the semantic type of this attribute.

=head2 module_execution

	my $module_execution = $attribute->module_execution();

Returns the module_execution that generated this attribute, or undef if it was
created directly by the user.

=cut

sub ID { return shift->id(); }
sub semantic_type { return shift->_attribute_type(); }

=head2 getDataHash

	my $data_hash = $attribute->getDataHash();

Returns a reference to a hash of all of the semantic elements of the
attribute and their values.  This hash will not include entries for
the module_execution, target, semantic type, or primary key ID.

=cut

sub getDataHash {
    my ($self) = @_;

    my %return_hash;

    my $semantic_type = $self->_attribute_type();
    my @columns = $semantic_type->semantic_elements();

    foreach my $column (@columns) {
        my $column_name = $column->name();
        my $value = $self->$column_name();
        $return_hash{$column_name} = $value;
    }

    return \%return_hash;
}

=head2 dataset, image, feature

	my $dataset = $attribute->dataset();
	my $image = $attribute->image();
	my $feature = $attribute->feature();

Returns the target of this attribute.  Only the method appropriate to
the granularity of the attribute's semantic type will be defined.

=head2 storeObject

	$attribute->storeObject();

This instance methods writes any unsaved changes to the database.

=cut


# The Experimenter, Group, and Repository semantic types must have
# their tables created before they are really instantiated as semantic
# types.  (Some of the core tables have foreign keys into this table.)

package OME::SemanticType::BootstrapExperimenter;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('experimenters');
__PACKAGE__->setSequence('attribute_seq');
__PACKAGE__->addPrimaryKey('attribute_id');
__PACKAGE__->addColumn(module_execution => 'module_execution_id',
                       'OME::ModuleExecution',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        #ForeignKey => 'module_executions',
                       });
__PACKAGE__->addColumn(FirstName => 'firstname',{SQLType => 'varchar(30)'});
__PACKAGE__->addColumn(LastName => 'lastname',{SQLType => 'varchar(30)'});
__PACKAGE__->addColumn(Email => 'email',{SQLType => 'varchar(50)'});
__PACKAGE__->addColumn(OMEName => 'ome_name',
                       {
                        SQLType => 'varchar(30)',
                        Unique  => 1,
                       });
__PACKAGE__->addColumn(Password => 'password',{SQLType => 'varchar(64)'});
__PACKAGE__->addColumn(Group => 'group_id',
                       'OME::SemanticType::BootstrapGroup',
                       {
                        SQLType => 'integer',
                       });
__PACKAGE__->addColumn(DataDirectory => 'data_dir',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(Institution => 'institution',{SQLType => 'varchar(256)'});


package OME::SemanticType::BootstrapGroup;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('groups');
__PACKAGE__->setSequence('attribute_seq');
__PACKAGE__->addPrimaryKey('attribute_id');
__PACKAGE__->addColumn(module_execution => 'module_execution_id',
                       'OME::ModuleExecution',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        #ForeignKey => 'module_executions',
                       });
__PACKAGE__->addColumn(Name => 'name',{SQLType => 'varchar(30)'});
__PACKAGE__->addColumn(Leader => 'leader',
                       'OME::SemanticType::BootstrapExperimenter',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'experimenters',
                       });
__PACKAGE__->addColumn(Contact => 'contact',
                       'OME::SemanticType::BootstrapExperimenter',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'experimenters',
                       });


package OME::SemanticType::BootstrapRepository;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('repositories');
__PACKAGE__->setSequence('attribute_seq');
__PACKAGE__->addPrimaryKey('attribute_id');
__PACKAGE__->addColumn(module_execution => 'module_execution_id',
                       'OME::ModuleExecution',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        #ForeignKey => 'module_executions',
                       });
__PACKAGE__->addColumn(Path => 'path',
                       {
                        SQLType => 'varchar(256)',
                        NotNull => 1,
                        Unique  => 1,
                       });


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

