# OME/module.pm

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


package OME::Module;

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->table('modules');
__PACKAGE__->sequence('module_seq');
__PACKAGE__->columns(Primary => qw(module_id));
__PACKAGE__->columns(Essential => qw(name description category));
__PACKAGE__->columns(Definition => qw(module_type location
                                      default_iterator new_feature_tag
                                      execution_instructions ));
__PACKAGE__->hasa('OME::Module::Category' => qw(category));
__PACKAGE__->has_many('inputs','OME::Module::FormalInput' => qw(module_id));
__PACKAGE__->has_many('outputs','OME::Module::FormalOutput' => qw(module_id));
__PACKAGE__->has_many('analyses','OME::ModuleExecution' => qw(module_id));


package OME::Module::FormalInput;

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

require OME::ModuleExecution;

__PACKAGE__->AccessorNames({
    module_id        => 'module',
    lookup_table_id   => 'lookup_table',
    semantic_type_id => 'semantic_type'
    });

__PACKAGE__->table('formal_inputs');
__PACKAGE__->sequence('formal_input_seq');
__PACKAGE__->columns(Primary => qw(formal_input_id));
__PACKAGE__->columns(Essential => qw(module_id name semantic_type_id
                                     optional list user_defined));
__PACKAGE__->columns(Other => qw(lookup_table_id description));
__PACKAGE__->hasa('OME::Module' => qw(module_id));
__PACKAGE__->hasa('OME::LookupTable' => qw(lookup_table_id));
__PACKAGE__->hasa('OME::SemanticType' => qw(semantic_type_id));

__PACKAGE__->has_many('actual_inputs','OME::ModuleExecution::ActualInput' =>
		      qw(formal_input_id));
                     
__PACKAGE__->make_filter('__module_name' => 'module_id = ? and name = ?');

package OME::Module::FormalOutput;

use strict;
our $VERSION = 2.000_000;

use OME::DBObject;
use base qw(OME::DBObject);

require OME::ModuleExecution;

__PACKAGE__->AccessorNames({
    module_id        => 'module',
    semantic_type_id => 'semantic_type'
    });

__PACKAGE__->table('formal_outputs');
__PACKAGE__->sequence('formal_output_seq');
__PACKAGE__->columns(Primary => qw(formal_output_id));
__PACKAGE__->columns(Essential => qw(module_id name semantic_type_id
                                     feature_tag optional list));
__PACKAGE__->columns(Other => qw(description));
__PACKAGE__->hasa('OME::Module' => qw(module_id));
__PACKAGE__->hasa('OME::SemanticType' => qw(semantic_type_id));

__PACKAGE__->make_filter('__module_name' => 'module_id = ? and name = ?');

1;

