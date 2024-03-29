# OME/Feature.pm

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
# Written by:  
#   Douglas Creager <dcreager@alum.mit.edu>
#   Ilya G. Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


# Initial revision: 06/01/2002 (Doug Creager dcreager@alum.mit.edu)
# Created from OMEpl (v1.20) package split.
#
# OMEpl credits
# -----------------------------------------------------------------------------
# Author:  Ilya G. Goldberg (igg@mit.edu)
# This file is part of OME.
# -----------------------------------------------------------------------------
#
#

package OME::Feature;

=head1 NAME

OME::Feature - subsets of an image

=head1 DESCRIPTION

The C<Feature> class represents OME features, which are analytic
subdivisions of an image.  Often, features will correspond to actual
pixel regions within an image, specified by a coordinate bounds or
image mask.  However, this does not have to be the case; features can
be entirely logical divisions in an image.  In a practical sense, they
are just used to group attributes which, together, refer to the same
portion of an image, but not to the image a whole.

The features of an image form a tree, with the image
itself at the root.  (Features right below the image in the tree will
have C<undef> for their parent feature link.)  Features also have a
tag, which allows similar kinds of features (cells, nuclei, etc.) to
be grouped for analysis.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use OME::Image;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('features');
__PACKAGE__->setSequence('feature_seq');
__PACKAGE__->addPrimaryKey('feature_id');
__PACKAGE__->addColumn(image_id => 'image_id');
__PACKAGE__->addColumn(image => 'image_id','OME::Image',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        Indexed => 1,
                        ForeignKey => 'images',
                       });
__PACKAGE__->addColumn(parent_feature_id => 'parent_feature_id');
__PACKAGE__->addColumn(parent_feature => 'parent_feature_id',
                       'OME::Feature',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        ForeignKey => 'features',
                       });
__PACKAGE__->addColumn(tag => 'tag',
                       {
                        SQLType => 'varchar(128)',
                        NotNull => 1,
                        Indexed => 1,
                       });
__PACKAGE__->addColumn(name => 'name',{SQLType => 'varchar(128)'});
__PACKAGE__->hasMany('children','OME::Feature' => 'parent_feature');


=head1 METHODS (C<Feature>)

The following methods are available to C<Feature> in addition to those
defined by L<OME::DBObject>.

=head2 name

	my $name = $feature->name();
	$feature->name($name);

Returns or sets the name of this feature.

=head2 tag

	my $tag = $feature->tag();
	$feature->tag($tag);

Returns or sets the tag of this feature.

=head2 image

	my $image = $feature->image();
	$feature->image($image);

Returns or sets the image that this feature belongs to.

=head2 parent_feature

	my $parent_feature = $feature->parent_feature();
	$feature->parent_feature($parent_feature);

Returns or sets the parent feature of this feature.

=head2 children

	my @children = $feature->children();
	my $children_iterator = $feature->children();

Returns or iterates, depending on context, the child features of this
feature.

=cut

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

