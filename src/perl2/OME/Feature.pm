# OME::Feature
# Initial revision: 06/01/2002 (Doug Creager dcreager@alum.mit.edu)
# Created from OMEpl (v1.20) package split.
#
# OMEpl credits
# -----------------------------------------------------------------------------
# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# -----------------------------------------------------------------------------
# 
#

package OME::Feature;

=head1 NAME

OME::Feature - subsets of an image

=head1 DESCRIPTION

The C<Feature> class represents OME features, which are subdivisions
of an image.  The features of an image form a tree, with the image
itself at the root.  (Features right below the image in the tree will
have C<undef> for their parent feature link.)  Features also have a
tag, which allow similar kinds of features (cells, nuclei, etc.) to be
grouped for module_execution.

=cut

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use OME::Image;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    image_id          => 'image',
    parent_feature_id => 'parent_feature'
    });

__PACKAGE__->table('features');
__PACKAGE__->sequence('feature_seq');
__PACKAGE__->columns(Primary => qw(feature_id));
__PACKAGE__->columns(Essential => qw(parent_feature_id image_id tag name));
__PACKAGE__->hasa('OME::Image' => qw(image_id));
__PACKAGE__->hasa('OME::Feature' => qw(parent_feature_id));
__PACKAGE__->has_many('children','OME::Feature' => qw(parent_feature_id),
                     {sort => 'feature_id'});

__PACKAGE__->make_filter('__image_roots' => 'image_id = ? and parent_feature_id is null order by tag, feature_id');

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

