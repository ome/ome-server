# OME/DataTable.pm

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


package OME::AttributeType;

=head1 NAME

OME::AttributeType - data object representing attribute types

=head1 SYNOPSIS

	use OME::AttributeType;

	# Load object via primary key
	my $atype = $factory->loadObject("OME::AttributeType",1);

	# Ensure that instance package is created
	my $pkg = $atype->requireAttributeTypePackage();

	# Create a new instance of this attribute type via primary key
	my $attribute = $pkg->load(1);

=head1 DESCRIPTION

OME::AttributeType serves two purposes.  First, it functoins just like
any other OME DBObject, representing rows from the ATTRIBUTE_TYPES
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
use base qw(OME::DBObject);

__PACKAGE__->mk_classdata('_attributeTypePackages');
__PACKAGE__->_attributeTypePackages({});

__PACKAGE__->table('attribute_types');
__PACKAGE__->sequence('attribute_type_seq');
__PACKAGE__->columns(Primary => qw(attribute_type_id));
__PACKAGE__->columns(Essential => qw(name granularity description));
__PACKAGE__->has_many('attribute_columns',
                      'OME::AttributeType::Column' => qw(attribute_type_id),
                      {sort => 'attribute_column_id'});

__PACKAGE__->add_trigger(after_create => \&requireAttributeTypePackage);
__PACKAGE__->add_trigger(select => \&requireAttributeTypePackage);


=head1

=cut

sub getAttributeTypePackage {
    my $self = shift;
    my $table = $self->name();
    $table =~ s/[^\w\d]/_/g;
    return "OME::AttributeType::__$table";
}

sub requireAttributeTypePackage {
    my ($self,$force) = @_;
    my $pkg = $self->getAttributeTypePackage();
    return $pkg 
      if (!$force) && (exists $self->_attributeTypePackages()->{$pkg});
    logdbg "debug", "Loading data table package $pkg";

    logcroak "Malformed class name $pkg"
      unless $pkg =~ /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;

    my $def = "package $pkg;\n";
    $def .= q{
	use strict;
	our $VERSION = '1.0';

	use OME::AttributeType;
	use base qw(OME::AttributeType::Superclass);
    };

    eval $def;

    $pkg->_attribute_type($self);

    my $attribute_columns = $self->attribute_columns();
    no strict 'refs';
    while (my $attribute_column = $attribute_columns->next()) {
        my $name = $attribute_column->name();
        *{$pkg."::".$name} = sub {
            my ($self) = shift;
            return @_? $self->_setField($name,@_): $self->_getField($name);
        };
    }

    # Make accessors for actual output, dataset, image, and feature.
    my $type = $self->granularity();

    no strict 'refs';
    if ($type eq 'D') {
        *{$pkg."::dataset"} = \&{$pkg."::_getTarget"};
    } elsif ($type eq 'I') {
        *{$pkg."::image"}   = \&{$pkg."::_getTarget"};
    } elsif ($type eq 'F') {
        *{$pkg."::feature"} = \&{$pkg."::_getTarget"};
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

    foreach my $attr_column ($self->attribute_columns()) {
        my $data_table = $attr_column->data_column()->data_table();
        $tables{$data_table->id()} = $data_table;
    }

    return values %tables;
}

sub loadAttribute {
    my ($self,$id) = @_;
    my $pkg = $self->requireAttributeTypePackage();
    return $pkg->load($id);
}

sub newAttribute {
    my ($self,$target,$id,$rows) = @_;
    my $pkg = $self->requireAttributeTypePackage();
    return $pkg->new($target,$id,$rows);
}

sub findAttributes {
    my ($self,$target) = @_;

    my $granularity = $self->granularity();
    my $factory = $self->Session()->Factory();

    my @data_tables = $self->dataTables();
    my @criteria;

    if ($granularity eq 'D') {
        @criteria = (dataset_id => $target);
    } elsif ($granularity eq 'I') {
        @criteria = (image_id => $target);
    } elsif ($granularity eq 'F') {
        @criteria = (feature_id => $target);
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


sub newAttributes {
    my ($self,$analysis,@attribute_info) = @_;

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

    my ($attribute_type, $data_hash, $factory);
    my ($i, $length);

    $length = scalar(@attribute_info);

    for ($i = 0; $i < $length; $i += 2) {
        $attribute_type = $attribute_info[$i];
        $data_hash = $attribute_info[$i+1];

        $factory = $attribute_type->Session()->Factory()
          if !defined $factory;
        my @attribute_columns = $attribute_type->attribute_columns();
        my $granularity = $attribute_type->granularity();
        my $granularityColumn = $granularityColumns{$granularity};

        __debug("  ".$attribute_type->name()." (".scalar(@attribute_columns)." columns)");

        # Follow each attribute column to its location in the
        # database.  Mark some information about that data table, and
        # ensure that all of the attributes and data tables merge
        # properly.  Specifically, make sure that if two attributes
        # are writing to the same data column, then they write the
        # same value.  Also, ensure that each data table that an
        # attribute writes to is of the same granularity as the
        # attribute itself.

        foreach my $column (@attribute_columns) {
            my $data_column = $column->data_column();
            my $column_name = $data_column->column_name();
            my $data_table = $data_column->data_table();
            my $table_name = $data_table->table_name();
            my $data_granularity = $data_table->granularity();
            my $attribute_column_name = $column->name();

            die "Attribute granularity and data table granularity don't match!"
                if ($granularity ne $data_granularity);

            __debug("    $attribute_column_name -> ${table_name}.$column_name");

            # Mark that $attribute_type resides in $table_name.
            $attribute_tables{$attribute_type->id()}->{$table_name} = 1;

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
            my $new_data = $data_hash->{$attribute_column_name};

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

        my $data_row = $data_table->newRow($analysis,
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

    __debug("Creating attributes");

    for ($i = 0; $i < $length; $i += 2) {
        $attribute_type = $attribute_info[$i];
        $data_hash = $attribute_info[$i+1];

        my $attribute_tables = $attribute_tables{$attribute_type->id()};
        my $rows = {};
        my $target;
        my $granularity = $attribute_type->granularity();

        # Collect all of the data rows needed for this attribute.

        foreach my $table_name (keys %$attribute_tables) {
            my $data_table = $data_tables{$table_name};
            $rows->{$data_table->id()} = $data_rows{$table_name};
            $target = $targets{$table_name};
        }

        # Create the attribute object.  (Note, this is basically just
        # a logical view into the database, it does not create any new
        # entries in the database itself.)

        my $attribute = $attribute_type->newAttribute($target,$id,$rows);

        push @attributes, $attribute;
    }

    return \@attributes;
}


package OME::AttributeType::Column;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use OME::Factory;
use base qw(OME::DBObject);


__PACKAGE__->AccessorNames({
    attribute_type_id => 'attribute_type',
    data_column_id    => 'data_column'
    });

__PACKAGE__->table('attribute_columns');
__PACKAGE__->sequence('attribute_column_seq');
__PACKAGE__->columns(Primary => qw(attribute_column_id));
__PACKAGE__->columns(Essential => qw(attribute_type_id name data_column_id description));
__PACKAGE__->hasa('OME::AttributeType' => qw(attribute_type_id));
__PACKAGE__->hasa('OME::DataTable::Column' => qw(data_column_id));


package OME::AttributeType::Superclass;

use strict;
our $VERSION = '1.0';

use Class::Data::Inheritable;

use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata('_attribute_type');

use fields qw(_data_table_rows _target _id);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($target,$id,$rows) = @_;

    die "Cannot create attribute without data rows"
      if !scalar(%$rows);

    my $self = {};
    $self->{_data_table_rows} = $rows;
    $self->{_target} = $target;
    $self->{_id} = $id;

    bless $self, $class;
    return $self;
}

sub load {
    my ($proto,$id) = @_;
    my $class = ref($proto) || $proto;

    my $rows = {};
    my $target;

    my $attribute_type = $class->_attribute_type();
    my $granularity = $attribute_type->granularity();
    my $attribute_columns = $attribute_type->attribute_columns();
    while (my $attribute_column = $attribute_columns->next()) {
        my $data_column = $attribute_column->data_column();
        my $data_table = $data_column->data_table();
        my $data_table_pkg = $data_table->requireDataTablePackage();
        my $data_tableID = $data_table->id();
        next if exists $rows->{$data_tableID};

        my $data_row = $data_table_pkg->retrieve($id);
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
    }

    return $class->new($target,$id,$rows);
}

sub id { return shift->{_id}; }
sub ID { return shift->{_id}; }

sub _getTarget {
    my ($self) = @_;
    return $self->{_target};
}

sub _getField {
    my ($self, $field_name) = @_;
    my $rows = $self->{_data_table_rows};
    my $attribute_type = $self->_attribute_type();

    my $attribute_columns = OME::AttributeType::Column->
        search(attribute_type_id => $attribute_type->id(),
               name              => $field_name);
    my $attribute_column = $attribute_columns->next() or return undef;

    my $data_column = $attribute_column->data_column();
    my $column_name = lc($data_column->column_name());
    my $data_table = $data_column->data_table();
    my $data_row = $rows->{$data_table->id()};

    my $value = $data_row->$column_name();
    if ($data_column->sql_type() eq 'reference') {
        my $reference_type = $data_column->reference_type();
        $value = OME::Factory->loadAttribute($reference_type,$value);
    }

    return $value;
}

sub _setField {
    my ($self, $field_name, $value) = @_;
    my $rows = $self->{_data_table_rows};
    my $attribute_type = $self->_attribute_type();

    my $attribute_columns = OME::AttributeType::Column->
        search(attribute_type_id => $attribute_type->id(),
               name              => $field_name);
    my $attribute_column = $attribute_columns->next() or return undef;

    my $data_column = $attribute_column->data_column();
    my $column_name = lc($data_column->column_name());
    my $data_table = $data_column->data_table();
    my $data_row = $rows->{$data_table->id()};

    if (($data_column->sql_type() eq 'reference') &&
        UNIVERSAL::isa($value,"OME::AttributeType::Superclass")) {
        $data_row->$column_name($value->id());
    } else {
        $data_row->$column_name($value);
    }
}

sub writeObject {
    my ($self) = @_;
    my $rows = $self->{_data_table_rows};
    $_->writeObject() foreach (values %$rows);
}


1;
