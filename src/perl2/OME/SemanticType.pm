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

use strict;
our $VERSION = '1.0';

use OME::DBObject;
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


sub getAttributeTypePackage {
    my $self = shift;
    my $table = $self->name();
    $table =~ s/[^\w\d]/_/g;
    return "OME::AttributeType::__$table";
}

sub requireAttributeTypePackage {
    my $self = shift;
    my $pkg = $self->getAttributeTypePackage();
    return $pkg if exists $self->_attributeTypePackages()->{$pkg};
    #print STDERR "**** Loading data table package $pkg\n";

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
            return $self->getField($name);
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
    }
    use strict 'refs';

    $self->_attributeTypePackages()->{$pkg} = 1;

    return $pkg;
}


package OME::AttributeType::Column;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
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

use fields qw(_data_table_rows _target);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($target,$rows) = @_;
    
    my $self = {};
    $self->{_data_table_rows} = $rows;
    $self->{_target} = $target;

    bless $self, $class;
    return $self;
}

sub load {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my ($id) = @_;
    my $rows = {};
    my $target;

    my $attribute_type = $class->_attribute_type();
    my $granularity = $attribute_type->granularity();
    my $attribute_columns = $attribute_type->attribute_columns();
    while (my $attribute_column = $attribute_columns->next()) {
        my $data_column = $attribute_column->data_column();
        my $data_table = $data_column->data_table();
        my $data_tableID = $data_table->id();
        next if exists $rows->{$data_tableID};

        my $data_row = $data_table->retrieve($id);
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

    return $class->new($target,$rows);
}

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
    my $column_name = $data_column->column_name();
    my $data_table = $data_column->data_table();
    my $data_row = $rows->{$data_table->id()};

    return $data_row->$column_name();
}
