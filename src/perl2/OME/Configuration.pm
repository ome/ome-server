# OME/Configuration.pm

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


package OME::Configuration;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('configuration');
__PACKAGE__->addPrimaryKey('configuration_id');
__PACKAGE__->addColumn(mac_address => 'mac_address',{SQLType => 'varchar(20)'});
__PACKAGE__->addColumn(db_instance => 'db_instance',{SQLType => 'char(6)'});
__PACKAGE__->addColumn(lsid_authority => 'lsid_authority',
                       {SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(tmp_dir => 'tmp_dir',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(xml_dir => 'xml_dir',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(bin_dir => 'bin_dir',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(ome_root => 'ome_root',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(import_formats => 'import_formats',
                       {SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(import_module_id => 'import_module');
__PACKAGE__->addColumn(import_module => 'import_module',
                       'OME::Module',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'modules',
                       });
__PACKAGE__->addColumn(import_chain_id => 'import_chain');
__PACKAGE__->addColumn(import_chain => 'import_chain',
                       'OME::AnalysisChain',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'analysis_chains',
                       });


1;
