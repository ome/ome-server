# OME/Install/IntallationTask.pm

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
# Written by:  
#
#-------------------------------------------------------------------------------


package OME::Install::InstallationTask;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;


# Interface common to all installation tasks.

# Every installation task will have to implement this method to carry out its
# job.
sub execute {
    return undef;
}

# Every installation task will have to implement this to undo the work that has
# been done at time this method is invoked.
sub rollback {
    return undef;
}


1;

