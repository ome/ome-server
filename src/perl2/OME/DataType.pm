# OME/DataType.pm

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


package OME::DataType;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->mk_classdata('_attributePackages');
__PACKAGE__->_attributePackages({});

__PACKAGE__->table('datatypes');
__PACKAGE__->sequence('datatype_seq');
__PACKAGE__->columns(Primary => qw(datatype_id));
__PACKAGE__->columns(Essential => qw(table_name description attribute_type));
__PACKAGE__->has_many('db_columns',OME::DataType::Column => qw(datatype_id));

# These triggers ensure that the appropriate OME::Attribute subclass
# definition is evaluated when a data type is loaded from the
# database.
__PACKAGE__->add_trigger(after_create => \&requireAttributePackage);
__PACKAGE__->add_trigger(select => \&requireAttributePackage);


sub getAttributePackage {
    my $self = shift;
    my $table = $self->table_name();
    return "OME::Attribute::$table";
}

sub requireAttributePackage {
    my $self = shift;
    my $pkg = $self->getAttributePackage();
    return if exists $self->_attributePackages()->{$pkg};

    my $def = "package $pkg;\n";
    $def .= q{
	use strict;
	our $VERSION = '1.0';
	
	use OME::Attribute;
	use base qw(OME::Attribute);
    };

    eval $def;

    my $table = $self->table_name();
    $pkg->table($table);
    $pkg->sequence('attribute_seq');
    $pkg->columns(Primary => qw(attribute_id));

    my $columns = $self->db_columns();
    my @column_defs;
    while (my $column = $columns->next()) {
	push @column_defs, lc($column->column_name());
    }

    $pkg->columns(Essential => @column_defs);
    
    my $type = $self->attribute_type();
    my $accessors = {};
    if ($type eq 'D') {
	$pkg->hasa(OME::Dataset => qw(dataset_id));
	$accessors->{dataset_id} = 'dataset';
    } elsif ($type eq 'I') {
	$pkg->hasa(OME::Image => qw(image_id));
	$accessors->{image_id} = 'image';
    } elsif ($type eq 'F') {
	#$pkg->hasa(OME::Feature => qw(feature_id));
    }

    $pkg->AccessorNames($accessors);

    $self->_attributePackages()->{$pkg} = $self;
}



package OME::DataType::Column;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->AccessorNames({
    datatype_id => 'datatype'
    });

__PACKAGE__->table('datatype_columns');
__PACKAGE__->sequence('datatype_column_seq');
__PACKAGE__->columns(Primary => qw(datatype_column_id));
__PACKAGE__->columns(Essential => qw(column_name reference_type));
__PACKAGE__->hasa(OME::DataType => qw(datatype_id));
    

1;

