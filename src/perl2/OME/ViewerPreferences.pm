# OME/ViewerPreferences.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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


package OME::ViewerPreferences;

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('viewer_preferences');
__PACKAGE__->setSequence('attribute_seq');
__PACKAGE__->addPrimaryKey('attribute_id');
__PACKAGE__->addColumn(experimenter_id => 'experimenter_id',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        ForeignKey => 'experimenters',
                       });
__PACKAGE__->addColumn(toolbox_scale => 'toolbox_scale',{SQLType => 'real'});

1;

