# OME/AttributeType.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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
our $VERSION = '1.0';

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

__PACKAGE__->mk_classdata('_attributeTypePackages');
__PACKAGE__->_attributeTypePackages({});

__PACKAGE__->table('semantic_types');
__PACKAGE__->sequence('semantic_type_seq');
__PACKAGE__->columns(Primary => qw(semantic_type_id));
__PACKAGE__->columns(Essential => qw(name granularity description));
__PACKAGE__->has_many('semantic_elements',
                      'OME::SemanticType::Column' => qw(semantic_type_id),
                      {sort => 'semantic_element_id'});

#__PACKAGE__->add_trigger(after_create => \&requireAttributeTypePackage);
#__PACKAGE__->add_trigger(select => \&requireAttributeTypePackage);


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

sub getAttributeTypePackage {
    my $self = shift;
    my $table = $self->name();
    $table =~ s/[^\w\d]/_/g;
    return "OME::SemanticType::__$table";
}

sub requireAttributeTypePackage {
    my ($self,$force) = @_;
    my $pkg = $self->getAttributeTypePackage();
    return $pkg 
      if (!$force) && (exists $self->_attributeTypePackages()->{$pkg});
    logdbg "debug", "Loading attribute type package $pkg";

    logcroak "Malformed class name $pkg"
      unless $pkg =~ /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;

    # Create the base definition of the semantic instance class.
    my $def = "package $pkg;\n";
    $def .= q{
	use strict;
	our $VERSION = '1.0';

	use OME::SemanticType;
	use base qw(OME::SemanticType::Superclass);
    };

    eval $def;

    $pkg->_attribute_type($self);

    my $semantic_elements = $self->semantic_elements();
    no strict 'refs';
    while (my $semantic_element = $semantic_elements->next()) {
        my $name = $semantic_element->name();

        # Add an accessor/mutator to the semantic instance class.
        *{$pkg."::".$name} = sub {
            my ($self) = shift;
            return @_? $self->_setField($name,@_): $self->_getField($name);
        };

        # Make this method visible via the Remote Framework
        my $data_column = $semantic_element->data_column();
        my $sql_type = $data_column->sql_type();
        if ($sql_type eq 'reference') {
            addPrototype($pkg,$name,
                         ['OME::SemanticType::Superclass'],
                         ['OME::SemanticType::Superclass'],
                         force => 1);
        } else {
            addPrototype($pkg,$name,['$'],['$'],force => 1);
        }
    }

    # Make accessors for actual output, dataset, image, and feature.
    my $type = $self->granularity();

    no strict 'refs';
    if ($type eq 'D') {
        *{$pkg."::dataset"} = sub { return shift->_getTarget(); };
        addPrototype($pkg,"dataset",[],['OME::Dataset'],force => 1);
    } elsif ($type eq 'I') {
        *{$pkg."::image"}   = sub { return shift->_getTarget(); };
        addPrototype($pkg,"image",[],['OME::Image'],force => 1);
    } elsif ($type eq 'F') {
        *{$pkg."::feature"} = sub { return shift->_getTarget(); };
        addPrototype($pkg,"feature",[],['OME::Feature'],force => 1);
        print STDERR "  $pkg\::feature\n";
    } elsif ($type eq 'G') {
        # No global column
    }
    use strict 'refs';

    $self->_attributeTypePackages()->{$pkg} = 1;

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

sub loadAttribute {
    my ($self,$id) = @_;
    my $pkg = $self->requireAttributeTypePackage();
    return $pkg->load($self->Session(),$id);
}

sub newAttribute {
    my ($self,$target,$id,$rows) = @_;
    my $pkg = $self->requireAttributeTypePackage();
    return $pkg->new($self->Session(),$target,$id,$rows);
}

sub findAttributes {
    my ($self,$target) = @_;

    my $granularity = $self->granularity();
    my $factory = $self->Session()->Factory();

    my @data_tables = $self->dataTables();
    my @criteria;
    my $targetID = ref($target)? $target->id(): $target;

    if ($granularity eq 'D') {
        @criteria = (dataset_id => $targetID);
    } elsif ($granularity eq 'I') {
        @criteria = (image_id => $targetID);
    } elsif ($granularity eq 'F') {
        @criteria = (feature_id => $targetID);
    }

    my %ids;

    foreach my $data_table (@data_tables) {
        my $pkg = $data_table->requireDataTablePackage();
        my @rows = $factory->
          findObjects($pkg,@criteria);
        $ids{$_->id()} = undef foreach @rows;
    }

    my @attributes;
    push @attributes, $self->loadAttribute($_) foreach keys %ids;

    return @attributes;
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
    print STDERR "***** ",$t," ",join(',',@$t),"\n";
    return $t->[0];
}


sub newAttributes {
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

        #$factory = $semantic_type->Session()->Factory()
        #  if !defined $factory;
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

        foreach my $column (@semantic_elements) {
            my $data_column = $column->data_column();
            my $column_name = $data_column->column_name();
            my $data_table = $data_column->data_table();
            my $table_name = $data_table->table_name();
            my $data_granularity = $data_table->granularity();
            my $semantic_element_name = $column->name();

            die "Attribute granularity and data table granularity don't match!"
                if ($granularity ne $data_granularity);

            __debug("    $semantic_element_name -> ${table_name}.$column_name");

            # Mark that $semantic_type resides in $table_name.
            $attribute_tables{$semantic_type->id()}->{$table_name} = 1;

            # Save the data table for later.
            $data_tables{$table_name} = $data_table;

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

            if (exists $data{$table_name}->{$column_name}) {
                my $old_data = $data{$table_name}->{$column_name};
                #__debug("      ?= $old_data");
                croak "Attribute values clash"
                    if ($new_data ne $old_data);
            }

            # Store the datum into the data table hash.
            $data{$table_name}->{$column_name} = $new_data;
        }
    }

    my $t1 = new Benchmark;

    # Now, create a new row in each data table.

    my %data_rows;
    my $id;

    __debug("Creating data rows");

    foreach my $table_name (keys %data_tables) {
        my $data_table = $data_tables{$table_name};
        my $granularity = $granularities{$table_name};

        __debug("  Table $table_name");

        #foreach my $column_name (sort keys %$data) {
        #    __debug("    $column_name = ".$data->{$column_name}."\n");
        #}

        # We've already created the correct data hash.  However, we
        # want all of the data rows to have the same ID.  So, if we've
        # created an ID already, use it, otherwise, allow the Factory
        # to assign a new ID.

        $data{$table_name}->{attribute_id} = $id
          if (defined $id);

        my $data_row = $data_table->newRow($module_execution,
                                           $targets{$table_name},
                                           $data{$table_name});

        $id = $data_row->id()
          if (!defined $id);

        # Store the new data row objects so that we can create the
        # attributes from then.

        $data_rows{$table_name} = $data_row;
    }

    # Now, create attribute objects from the data rows we just
    # created.

    my @attributes;

    my $t2 = new Benchmark;

    __debug("Creating attributes");

    for ($i = 0; $i < $length; $i += 2) {
        $semantic_type = $attribute_info[$i];
        $data_hash = $attribute_info[$i+1];

        my $attribute_tables = $attribute_tables{$semantic_type->id()};
        my $rows = {};
        my $target;
        my $granularity = $semantic_type->granularity();

        # Collect all of the data rows needed for this attribute.

        foreach my $table_name (keys %$attribute_tables) {
            my $data_table = $data_tables{$table_name};
            $rows->{$data_table->id()} = $data_rows{$table_name};
            $target = $targets{$table_name};
        }

        # Create the attribute object.  (Note, this is basically just
        # a logical view into the database, it does not create any new
        # entries in the database itself.)

        my $attribute = $semantic_type->newAttribute($target,
                                                      $id,$rows);

        push @attributes, $attribute;
    }

    my $t3 = new Benchmark;

    my $sort_time = timediff($t1,$t0);
    my $db_time = timediff($t2,$t1);
    my $create_time = timediff($t3,$t2);

    $self->__addTiming($sort_time,$db_time,$create_time);

    return \@attributes;
}


package OME::SemanticType::Column;

=head1 NAME

OME::SemanticType::Column

=head1 DESCRIPTION

This C<AttributeType.Column> interface represents one element of a
semantic type.  The storage type of the element can be accessed via
the element's data column:

	my $data_column = $semantic_element->data_column();
	my $sql_type = $data_column->sql_type();

=cut

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use OME::Factory;
use base qw(OME::DBObject);


__PACKAGE__->AccessorNames({
    semantic_type_id => 'semantic_type',
    data_column_id    => 'data_column'
    });

__PACKAGE__->table('semantic_elements');
__PACKAGE__->sequence('semantic_element_seq');
__PACKAGE__->columns(Primary => qw(semantic_element_id));
__PACKAGE__->columns(Essential => qw(semantic_type_id name data_column_id description));
__PACKAGE__->hasa('OME::SemanticType' => qw(semantic_type_id));
__PACKAGE__->hasa('OME::DataTable::Column' => qw(data_column_id));

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
our $VERSION = '1.0';

use Class::Data::Inheritable;

use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata('_attribute_type');

use fields qw(_data_table_rows _target _analysis _id _session);

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
    $self->{_session} = $session;

    my $module_execution;
    foreach my $row (values %$rows) {
        $module_execution = $row->module_execution();
        last if defined $module_execution;
    }
    $self->{_analysis} = $module_execution;

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

sub id { return shift->{_id}; }
sub ID { return shift->{_id}; }
sub Session { return shift->{_session}; }
sub semantic_type { return shift->_attribute_type(); }
sub module_execution { return shift->{_analysis}; }

=head2 dataset, image, feature

	my $dataset = $attribute->dataset();
	my $image = $attribute->image();
	my $feature = $attribute->feature();

Returns the target of this attribute.  Only the method appropriate to
the granularity of the attribute's semantic type will be defined.

=cut

# The methods described above are created by the
# requireAttributeTypePackage method.  They are aliases for _getTarget,
# defined below.

sub _getTarget {
    my ($self) = @_;
    return $self->{_target};
}

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
        my $value = $self->_getField($column_name);
        $return_hash{$column_name} = $value;
    }

    return \%return_hash;
}

sub _getField {
    my ($self, $field_name) = @_;
    my $factory = $self->Session()->Factory();
    my $rows = $self->{_data_table_rows};
    my $semantic_type = $self->_attribute_type();

    my $semantic_element = $factory->
      findObject("OME::SemanticType::Column",
                 semantic_type_id => $semantic_type->id(),
                 name              => $field_name);
    return undef unless defined $semantic_element;

    my $data_column = $semantic_element->data_column();
    my $column_name = lc($data_column->column_name());
    my $data_table = $data_column->data_table();
    my $data_row = $rows->{$data_table->id()};

    my $value = $data_row->$column_name();
    if ($data_column->sql_type() eq 'reference') {
        my $reference_type = $data_column->reference_type();
        $value = $factory->loadAttribute($reference_type,$value);
    }

    return $value;
}

sub _setField {
    my ($self, $field_name, $value) = @_;
    my $factory = $self->Session()->Factory();
    my $rows = $self->{_data_table_rows};
    my $semantic_type = $self->_attribute_type();

    my $semantic_element = $factory->
      findObject("OME::SemanticType::Column",
                 semantic_type_id => $semantic_type->id(),
                 name              => $field_name);
    return undef unless defined $semantic_element;

    my $data_column = $semantic_element->data_column();
    my $column_name = lc($data_column->column_name());
    my $data_table = $data_column->data_table();
    my $data_row = $rows->{$data_table->id()};

    if (($data_column->sql_type() eq 'reference') &&
        UNIVERSAL::isa($value,"OME::SemanticType::Superclass")) {
        $data_row->$column_name($value->id());
    } else {
        $data_row->$column_name($value);
    }
}

sub commit {
    my ($self) = @_;
    my $rows = $self->{_data_table_rows};
    $_->commit() foreach (values %$rows);
}

=head2 storeObject

	$attribute->storeObject();

This instance methods writes any unsaved changes to the database.

=cut

sub writeObject {
    my ($self) = @_;
    my $rows = $self->{_data_table_rows};
    $_->writeObject() foreach (values %$rows);
}

sub storeObject {
    my ($self) = @_;
    my $rows = $self->{_data_table_rows};
    $_->storeObject() foreach (values %$rows);
}


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

