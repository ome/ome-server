# OME/DataTable/Column.pm

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


=head1 NAME

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

package OME::DataTable::Column;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Log::Agent;
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

__PACKAGE__->addPseudoColumn('reference_semantic_type',
                             'has-one','OME::SemanticType');

sub reference_semantic_type {
    my $self = shift;
    if (@_) {
        my $type = shift;
        if (defined $type) {
            die "Expects a semantic type object"
              unless UNIVERSAL::isa($type,'OME::SemanticType');
            $self->reference_type($type->name());
        } else {
            $self->reference_type(undef);
        }
    } else {
        my $type_name = $self->reference_type();
        return undef unless defined $type_name;
        my $factory = OME::Session->instance()->Factory();
        my $type = $factory->
          findObject('OME::SemanticType',name => $type_name);
        die "Type $type_name does not exist"
          unless defined $type;
        return $type;
    }
}

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

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

1;
