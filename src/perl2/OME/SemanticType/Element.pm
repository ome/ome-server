# OME/SemanticType/Element.pm

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

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

