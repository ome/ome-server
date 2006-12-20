# OME/SemanticType/Label.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::SemanticType::Label;

=head1 NAME

OME::SemanticType::Label

=head1 DESCRIPTION

This is a label for a semantic type that allows for
internationalization. It is distinct from a semantic type's name in that
an ST may have only one name, the name is used for class generation, and
the name is restricted to alphanumeric characters (no spaces or
puncuations). In contrast, an ST may have many distinct labels for
different languages, the labels are used by user agents for display
purposes, and may contain spaces or puncuation in addition to
alphanumeric characters.

This package has four fields: semantic_type, label, description, and languaage.
language also has an alias of lang. The values of the lang field are
defined by [IETF RFC 3066], Tags for the Identification of Languages,
which can be found at. http://www.ietf.org/rfc/rfc3066.txt (These values
are what xml:lang uses.) For a simplified version, see 
http://www.w3.org/International/articles/language-tags/Overview.en.php

=head2 Implementation notes

For english labels, the description field will duplicate content in ST's
description field. This is not ideal, and ST's description field will be
dropped from the database in time, and will become a "pseudo-column"
that retrieves the description from this package.

There is supposed to be a unique contraint on ST + lang, but this is not 
currently implemented at the database level.

The lang field is currently implemented as a text field. The postgresql 
documentation claims that char fields offer no performance advantages over
text fields. 
http://www.postgresql.org/docs/8.0/interactive/datatype-character.html

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use OME::Factory;
use base qw(OME::DBObject);


__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('semantic_type_labels');
__PACKAGE__->setSequence('semantic_type_label_seq');
__PACKAGE__->addPrimaryKey('semantic_type_label_id');
__PACKAGE__->addColumn(semantic_type_id => 'semantic_type_id');
__PACKAGE__->addColumn(semantic_type => 'semantic_type_id',
                       'OME::SemanticType',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'semantic_types',
                       });
__PACKAGE__->addColumn(label => 'label',
                       {
                        SQLType => 'text',
                        NotNull => 1,
                       });
__PACKAGE__->addColumn(description => 'description',
                       { SQLType => 'text' });
__PACKAGE__->addColumn(['language', 'lang'] => 'language',
                       {
                        SQLType => 'text',
                        NotNull => 1,
                       });


=head1 METHODS

The following methods are available in addition to those defined by
L<OME::DBObject>.

=head2 label

	my $label_text = $label->label();
	$label->label($label_text);

Returns or sets the name of this semantic type label.

=head2 description

	my $description = $label->description();
	$label->description($description);

Returns or sets the description of this semantic type label.

=head2 semantic_type

	my $semantic_type = $label->semantic_type();
	$label->semantic_type($semantic_type);

Returns or sets the semantic type that this semantic type label belongs
to.

=head2 language

	my $language = $label->language();
	$label->language($language);

Returns or sets the language of this semantic type label. Also has an alias of 
'lang'.

=cut

1;

__END__

=head1 AUTHOR

Josiah Johnston <siah@nih.gov>,
Open Microscopy Environment, NIH

=cut

