# OME/DBConnection.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::DBConnection;
use OME;
our $VERSION = $OME::VERSION;

use strict;

use base qw(Class::Accessor Class::Data::Inheritable);

__PACKAGE__->mk_classdata('DataSource');
__PACKAGE__->mk_classdata('DBUser');
__PACKAGE__->mk_classdata('DBPassword');

__PACKAGE__->DataSource("dbi:Pg:dbname=ome");
__PACKAGE__->DBUser(undef);
__PACKAGE__->DBPassword(undef);

1;
