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

=head1 NAME

OME::DataTable - a database table to store attributes

OME::DataTable::Column - a column in a data table

=head1 DESCRIPTION

The C<DataTable> interface describes the database tables used to store
OME semantic types.  Note that there can be a many-to-many
relationship between semantic types and data tables.  Semantic types
which are logically related can be stored in the same database table,
to help reduce the overhead of columns added to each table by the
analysis engine.  Further, semantic types which can be broken into
sparse distinct subparts can be stored in separate tables to help
reduce the sparsity of each data row.

The actual mapping between semantic types and data tables occurs as a
link between semantic type columns and data table columns.  This link
can be accessed via the C<AttributeType-E<gt>data_columb> method.

=cut

use strict;
our $VERSION = '1.0';

use Log::Agent;
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
#__PACKAGE__->add_trigger(after_create => \&requireDataTablePackage);
#__PACKAGE__->add_trigger(select => \&requireDataTablePackage);

=head1 METHODS (C<DataTable>)

The following methods are available to C<DataTable> in addition to
those defined by L<OME::DBObject>.

=head2 granularity

	my $granularity = $table->granularity();
	$table->granularity($granularity);

Returns or sets the granularity of the data table.  This granuarity
must match the granularity of any semantic types which store elements
in it.

=head2 table_name

	my $table_name = $table->table_name();
	$table->table_name($table_name);

Returns or sets the name of the underlying database table.

=head2 description

	my $description = $table->description();
	$table->description($description);

Returns or sets the description of this data table.

=head2 data_columns

	my @data_columns = $table->data_columns();
	my $data_column_iterator = $table->data_columns();

Returns or iterates, depending on context, the list of columns in this
data table.

=cut

__PACKAGE__->set_sql('get_attributes',<<'SQL;','Main');
  SELECT attr.attribute_id
    FROM %s attr
   WHERE %s = ?
ORDER BY attr.attribute_id
SQL;

sub findAttributesByTarget {
    my ($self, $targetID) = @_;
    my $granularity = $self->semantic_type();
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
    my ($self,$force) = @_;
    my $pkg = $self->getDataTablePackage();
    return $pkg 
      if (!$force) && (exists $self->_dataTablePackages()->{$pkg});
    logdbg "debug", "Loading data table package $pkg";

    logcroak "Malformed class name $pkg"
      unless $pkg =~ /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;

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
    $pkg->columns(Primary => qw(attribute_id module_execution_id));

    my $columns = $self->data_columns();
    my @column_defs = ('module_execution_id');
    while (my $column = $columns->next()) {
        push @column_defs, lc($column->column_name());
        #print STDERR "   $table.".lc($column->column_name())."\n";
    }

    my $type = $self->granularity();
    if ($type eq 'D') {
        push @column_defs, 'dataset_id';
    } elsif ($type eq 'I') {
        push @column_defs, 'image_id';
    } elsif ($type eq 'F') {
        push @column_defs, 'feature_id';
    }

    $pkg->columns(Essential => @column_defs);

    $pkg->has_a(module_execution_id => 'OME::ModuleExecution');

    no strict 'refs';
    *{$pkg."::module_execution"} = \&{$pkg."::module_execution_id"};
    use strict 'refs';

    # Make accessors for actual output, dataset, image, and feature.

    my $accessors = {};
    if ($type eq 'D') {
        $pkg->has_a(dataset_id => 'OME::Dataset');

        no strict 'refs';
        *{$pkg."::dataset"} = \&{$pkg."::dataset_id"};
        use strict 'refs';
    } elsif ($type eq 'I') {
        $pkg->has_a(image_id => 'OME::Image');

        no strict 'refs';
        *{$pkg."::image"}   = \&{$pkg."::image_id"};
        use strict 'refs';
    } elsif ($type eq 'F') {
        $pkg->has_a(feature_id => 'OME::Feature');

        no strict 'refs';
        *{$pkg."::feature"} = \&{$pkg."::feature_id"};
        use strict 'refs';
    } elsif ($type eq 'G') {
        # No target column
    }


    $self->_dataTablePackages()->{$pkg} = 1;

    return $pkg;
}


sub loadRow {
    my ($self,$id) = @_;
    my $pkg = $self->requireDataTablePackage();
    return $self->Session()->Factory()->loadObject($pkg,$id);
}

sub newRow {
    my ($self,$module_execution,$target,$data) = @_;
    my $pkg = $self->requireDataTablePackage();
    my $granularity = $self->granularity();
    $data->{module_execution_id} = $module_execution;
    if ($granularity eq 'D') {
        $data->{dataset_id} = ref ($target) ? $target->id() : $target;
    } elsif ($granularity eq 'I') {
        $data->{image_id} = ref ($target) ? $target->id() : $target;
    } elsif ($granularity eq 'F') {
        $data->{feature_id} = ref ($target) ? $target->id() : $target;
    }
    return $self->Session()->Factory()->newObject($pkg,$data);
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
__PACKAGE__->columns(Essential => qw(data_table_id column_name description
                                     sql_type reference_type));
__PACKAGE__->hasa('OME::DataTable' => qw(data_table_id));

__PACKAGE__->make_filter('__type_column' => 'data_table_id = ? and column_name = ?');

=head1 METHODS (C<DataTable::Column>)

The following methods are available to C<DataTable::Column> in addition to
those defined by L<OME::DBObject>.

=head2 data_table

	my $tn = $column->tn();
	$column->tn($tn);

Returns or sets the data table that this column belongs to.

=head2 column_name

	my $column_name = $column->column_name();
	$column->column_name($column_name);

Returns or sets the name of the underlying database column.

=head2 description

	my $description = $column->description();
	$column->description($description);

Returns or sets the description of the data column.

=head2 sql_type

	my $sql_type = $column->sql_type();
	$column->sql_type($sql_type);

Returns or sets the storage type of this data column.

=head2 reference_type

	my $reference_type = $column->reference_type();
	$column->reference_type($reference_type);

Returns or sets the semantic type that this data column refers to,
assuming that the storage type is "reference".

=cut

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

