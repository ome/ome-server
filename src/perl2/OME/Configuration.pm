# OME/Configuration.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Configuration;

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->table('configuration');
__PACKAGE__->columns(Primary => qw(configuration_id));
__PACKAGE__->columns(All => qw(mac_address db_instance lsid_authority
                               ome_root tmp_dir xml_dir bin_dir
                               import_formats
                               display_settings import_module import_chain));
__PACKAGE__->hasa('OME::Module' => qw(import_module));
__PACKAGE__->hasa('OME::AnalysisChain' => qw(import_chain));


1;
