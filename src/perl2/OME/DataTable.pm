# OME/DataTable.pm

# Copyright (C) 2003 Open Microscopy Environment
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
our $VERSION = 2.000_000;

use Log::Agent;
use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->mk_classdata('_dataTablePackages');
__PACKAGE__->_dataTablePackages({});

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('data_tables');
__PACKAGE__->setSequence('data_table_seq');
__PACKAGE__->addPrimaryKey('data_table_id');
__PACKAGE__->addColumn(granularity => 'granularity',
                       {
                        SQLType => 'char(1)',
                        NotNull => 1,
                        Check   => "(granularity in ('G','D','I','F'))",
                       });
__PACKAGE__->addColumn(table_name => 'table_name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});
__PACKAGE__->hasMany('data_columns',
                     'OME::DataTable::Column','data_table');

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

my %dataTypeConversion = (
                          # XMLType  => SQL_Type
                          integer   => 'integer',
                          double    => 'double precision',
                          float     => 'real',
                          boolean   => 'boolean',
                          string    => 'text',
                          dateTime  => 'timestamp',
                          reference => 'integer'
                         );

sub getSQLType {
    my ($class,$type) = @_;

    die "Invalid SQL type!"
      unless exists $dataTypeConversion{$type};
    return $dataTypeConversion{$type};
}

sub __formPackageName {
    my ($self,$name) = @_;
    $name =~ s/[^\w\d]/_/g;
    $name = uc($name);
    return "OME::DataTable::__$name";
}

sub getDataTablePackage {
    my $self = shift;
    return $self->__formPackageName($self->table_name());
}

sub requireDataTablePackage {
    my ($self,$force) = @_;
    my $pkg = $self->getDataTablePackage();
    return $pkg 
      if (!$force) && (exists $self->_dataTablePackages()->{$pkg});
    logdbg "debug", "Loading data table package $pkg";

    logcroak "Malformed class name $pkg"
      unless $pkg =~ /^\w+(\:\:\w+)*$/;

    my $def = "package $pkg;\n";
    $def .= q{
	use strict;
	our $VERSION = 2.000_000;

	use OME::DBObject;
	use base qw(OME::DBObject);
    };

    eval $def;

    $pkg->mk_classdata('_data_table');
    $pkg->_data_table($self);
    $pkg->newClass();

    my $table = $self->table_name();
    $pkg->setDefaultTable($table);
    $pkg->setSequence('attribute_seq');
    $pkg->addPrimaryKey('attribute_id');
    $pkg->addColumn(module_execution => 'module_execution_id',
                    'OME::ModuleExecution',
                    {
                     SQLType => 'integer',
                     Indexed => 1,
                     ForeignKey => 'module_executions',
                    });

    my $columns = $self->data_columns();
    while (my $column = $columns->next()) {
        my $name = lc($column->column_name());
        my $type = $column->sql_type();
        my $sql_type = $self->getSQLType($type);

        $pkg->addColumn($name,$name,{SQLType => $sql_type});
    }

    my $type = $self->granularity();
    if ($type eq 'D') {
        $pkg->addColumn(['dataset','target'] => 'dataset_id','OME::Dataset',
                        {
                         SQLType => 'integer',
                         NotNull => 1,
                         Indexed => 1,
                         ForeignKey => 'datasets',
                        });
    } elsif ($type eq 'I') {
        $pkg->addColumn(['image','target'] => 'image_id','OME::Image',
                        {
                         SQLType => 'integer',
                         NotNull => 1,
                         Indexed => 1,
                         ForeignKey => 'images',
                        });
    } elsif ($type eq 'F') {
        $pkg->addColumn(['feature','target'] => 'feature_id','OME::Feature',
                        {
                         SQLType => 'integer',
                         NotNull => 1,
                         Indexed => 1,
                         ForeignKey => 'features',
                        });
    }

    $self->_dataTablePackages()->{$pkg} = 1;

    return $pkg;
}


package OME::DataTable::Column;

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);


__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('data_columns');
__PACKAGE__->setSequence('data_column_seq');
__PACKAGE__->addPrimaryKey('data_column_id');
__PACKAGE__->addColumn(data_table_id => 'data_table_id');
__PACKAGE__->addColumn(data_table => 'data_table_id','OME::DataTable',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'data_tables',
                       });
__PACKAGE__->addColumn(column_name => 'column_name',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(description => 'description',{SQLType => 'text'});
__PACKAGE__->addColumn(sql_type => 'sql_type',
                       {
                        SQLType => 'varchar(64)',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(reference_type => 'reference_type',
                       {SQLType => 'varchar(64)'});

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

