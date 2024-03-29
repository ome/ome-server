# OME/DataTable.pm

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


package OME::DataTable;

=head1 NAME

OME::DataTable - a database table to store attributes

L<OME::DataTable::Column> - a column in a data table

=head1 DESCRIPTION

The C<DataTable> interface describes the database tables used to store
OME semantic types.  Note that there is a one-to-one relationship between
semantic types and data tables. Each semantic type is stored in a single
table and each table can only store a single semantic type.

The actual mapping between semantic types and data tables occurs as a
link between semantic type columns and data table columns.  This link
can be accessed via the C<AttributeType-E<gt>data_columb> method.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
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
                          bigint    => 'bigint',
                          integer   => 'integer',
                          smallint  => 'smallint',
                          double    => 'double precision',
                          float     => 'real',
                          boolean   => 'boolean',
                          string    => 'text',
                          dateTime  => 'timestamp',
                          reference => 'integer'
                         );

sub getSQLType {
    my ($class,$type) = @_;

    confess "$type is an invalid SQL type!"
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

	if( not exists $self->_dataTablePackages()->{$pkg} ) {
		logdbg "debug", "Loading data table package $pkg";
	
		logcroak "Malformed class name $pkg"
		  unless $pkg =~ /^\w+(\:\:\w+)*$/;
	
		my $def = "package $pkg;\n";
		$def .= q{
		use strict;
		use OME;
		our $VERSION = $OME::VERSION;
	
		use OME::DBObject;
		use base qw(OME::DBObject);
		};
	
		eval $def;
	
		$pkg->mk_classdata('_data_table');
		$pkg->_data_table($self);
		$pkg->newClass();
	
		$pkg->setDefaultTable( $self->table_name() );
		$pkg->setSequence('attribute_seq');
		$pkg->addPrimaryKey('attribute_id');
	} else {
		logdbg "debug", "Refreshing data table package $pkg";
	}
	
    $pkg->addColumn(module_execution => 'module_execution_id',
                    'OME::ModuleExecution',
                    {
                     SQLType => 'integer',
                     NotNull => 1,
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
        $pkg->addColumn(['dataset_id','target_id'] => 'dataset_id');
        $pkg->addColumn(['dataset','target'] => 'dataset_id','OME::Dataset',
                        {
                         SQLType => 'integer',
                         NotNull => 1,
                         Indexed => 1,
                         ForeignKey => 'datasets',
                        });
    } elsif ($type eq 'I') {
        $pkg->addColumn(['image_id','target_id'] => 'image_id');
        $pkg->addColumn(['image','target'] => 'image_id','OME::Image',
                        {
                         SQLType => 'integer',
                         NotNull => 1,
                         Indexed => 1,
                         ForeignKey => 'images',
                        });
    } elsif ($type eq 'F') {
        $pkg->addColumn(['feature_id','target_id'] => 'feature_id');
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


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

