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
__PACKAGE__->columns(Essential => qw(parent_feature_id image_id tag));
__PACKAGE__->hasa('OME::Image' => qw(image_id));
__PACKAGE__->hasa('OME::Feature' => qw(parent_feature_id));



1;
