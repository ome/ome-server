# OME/ModuleExecution/SemanticTypeOutput.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------

package OME::ModuleExecution::SemanticTypeOutput;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('semantic_type_outputs');
__PACKAGE__->setSequence('semantic_type_output_seq');
__PACKAGE__->addPrimaryKey('semantic_type_output_id');
__PACKAGE__->addColumn(module_execution_id => 'module_execution_id');
__PACKAGE__->addColumn(module_execution => 'module_execution_id',
                       'OME::ModuleExecution',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        ForeignKey => 'module_executions',
                       });
__PACKAGE__->addColumn(semantic_type_id => 'semantic_type_id');
__PACKAGE__->addColumn(semantic_type => 'semantic_type_id',
                       'OME::SemanticType',
                       {
                        SQLType => 'integer',
                        NotNull => 1,
                        ForeignKey => 'semantic_types',
                       });

sub attributes {
	my $self    = shift;
	my $factory = $self->Session()->Factory();
	return $factory->findObjects( 
		$self->semantic_type,
		module_execution_id => $self->module_execution_id
	);
}

1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut
