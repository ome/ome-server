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


package OME::DataTable;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->mk_classdata('_dataTablePackages');
__PACKAGE__->_dataTablePackages({});

__PACKAGE__->table('data_tables');
__PACKAGE__->sequence('data_table_seq');
__PACKAGE__->columns(Primary => qw(data_table_id));
__PACKAGE__->columns(Essential => qw(granularity table_name description));
__PACKAGE__->has_many('data_columns',
                      'OME::DataTable::Column' => qw(data_table_id),
                      {sort => 'data_column_id'});

# These triggers should ensure that the appropriate DBObject subclass
# definition is evaluated when a data type is loaded from the
# database.
__PACKAGE__->add_trigger(after_create => \&requireDataTablePackage);
__PACKAGE__->add_trigger(select => \&requireDataTablePackage);


__PACKAGE__->set_sql('get_attributes',<<'SQL;','Main');
  SELECT attr.attribute_id
    FROM %s attr
   WHERE %s = ?
ORDER BY attr.attribute_id
SQL;

sub findByTable {
    my ($class, $table_name) = @_;
    my @datatypes = $class->search('table_name',$table_name);
    die "Multiple matching datatypes" if (scalar(@datatypes) > 1);
    return $datatypes[0];
}

sub findColumnByName {
    my ($self, $column_name) = @_;
    my $type_id = $self->id();
    return OME::DataTable::Column->findByTypeAndColumn($type_id,
						      $column_name);
}

sub findAttributesByTarget {
    my ($self, $targetID) = @_;
    my $granularity = $self->attribute_type();
    my $attr_table = $self->table_name();

    my %columns = ('D' => 'dataset_id','I' => 'image_id','F' => 'feature_id');
    my $sth = $self->sql_get_attributes($attr_table,$columns{$granularity});
    $sth->execute($targetID);

    return $sth;
}

sub getDataTablePackage {
    my $self = shift;
    my $table = $self->table_name();
    $table =~ s/[^\w\d]/_/g;
    return "OME::DataTable::__$table";
}

sub requireDataTablePackage {
    my $self = shift;
    my $pkg = $self->getDataTablePackage();
    return $pkg if exists $self->_dataTablePackages()->{$pkg};
    #print STDERR "**** Loading data table package $pkg\n";

    my $def = "package $pkg;\n";
    $def .= q{
	use strict;
	our $VERSION = '1.0';

	use OME::DBObject;
	use base qw(OME::DBObject);
    };

    eval $def;

    $pkg->mk_classdata('_data_table');
    $pkg->_data_table($self);

    my $table = $self->table_name();
    $pkg->table($table);
    $pkg->sequence('attribute_seq');
    $pkg->columns(Primary => qw(attribute_id));

    my $columns = $self->data_columns();
    my @column_defs = ('analysis_id');
    while (my $column = $columns->next()) {
	push @column_defs, lc($column->column_name());
    }

    #$pkg->hasa('OME::Analysis::ActualOutput' => qw(actual_output_id));
    $pkg->hasa('OME::Analysis' => qw(analysis_id));

    my $type = $self->granularity();
    my $accessors = {};
    if ($type eq 'D') {
	$pkg->hasa('OME::Dataset' => qw(dataset_id));
    } elsif ($type eq 'I') {
	$pkg->hasa('OME::Image' => qw(image_id));
    } elsif ($type eq 'F') {
	$pkg->hasa('OME::Feature' => qw(feature_id));
    }

    $pkg->columns(Essential => @column_defs);

    # Make accessors for actual output, dataset, image, and feature.
    no strict 'refs';
    *{$pkg."::analysis"} = \&{$pkg."::analysis_id"};
    if ($type eq 'D') {
        *{$pkg."::dataset"} = \&{$pkg."::dataset_id"};
    } elsif ($type eq 'I') {
        *{$pkg."::image"}   = \&{$pkg."::image_id"};
    } elsif ($type eq 'F') {
        *{$pkg."::feature"} = \&{$pkg."::feature_id"};
    }
    use strict 'refs';

    $self->_dataTablePackages()->{$pkg} = 1;

    return $pkg;
}



package OME::DataTable::Column;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->AccessorNames({
    data_table_id => 'data_table'
    });

__PACKAGE__->table('data_columns');
__PACKAGE__->sequence('data_column_seq');
__PACKAGE__->columns(Primary => qw(data_column_id));
__PACKAGE__->columns(Essential => qw(data_table_id column_name description sql_type));
__PACKAGE__->hasa('OME::DataTable' => qw(data_table_id));

__PACKAGE__->make_filter('__type_column' => 'data_table_id = ? and column_name = ?');

sub findByTypeAndColumn {
    my ($class, $type_id, $column_name) = @_;
    my @columns = $class->__type_column(data_table_id => $type_id,
					column_name => $column_name);
    die "Multiple matching columns" if (scalar(@columns) > 1);
    return $columns[0]; 
}



1;

