# OME/Program.pm

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


package OME::Program;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->table('programs');
__PACKAGE__->sequence('program_seq');
__PACKAGE__->columns(Primary => qw(program_id));
__PACKAGE__->columns(Essential => qw(program_name description category));
__PACKAGE__->columns(Definition => qw(module_type location));
__PACKAGE__->has_many('inputs','OME::Program::FormalInput' => qw(program_id));
__PACKAGE__->has_many('outputs','OME::Program::FormalOutput' => qw(program_id));
__PACKAGE__->has_many('analyses','OME::Analysis' => qw(program_id));


sub findByName {
    my ($class,$name) = @_;
    my @programs = $class->search(program_name => $name);
    die "Multiple matching programs" if (scalar(@programs) > 1);
    return $programs[0];
}

sub findInputByName {
    my ($self, $name) = @_;
    my $program_id = $self->id();
    return OME::Program::FormalInput->findByProgramAndName($program_id,
							   $name);
}

sub findOutputByName {
    my ($self, $name) = @_;
    my $program_id = $self->id();
    return OME::Program::FormalOutput->findByProgramAndName($program_id,
							    $name);
}




package OME::Program::FormalInput;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use OME::DataType;
use base qw(OME::DBObject);

require OME::Analysis;

__PACKAGE__->AccessorNames({
    program_id      => 'program',
    lookup_table_id => 'lookup_table',
    datatype_id     => 'datatype'
    });

__PACKAGE__->table('formal_inputs');
__PACKAGE__->sequence('formal_input_seq');
__PACKAGE__->columns(Primary => qw(formal_input_id));
__PACKAGE__->columns(Essential => qw(program_id name datatype_id));
__PACKAGE__->columns(Other => qw(lookup_table_id));
__PACKAGE__->hasa('OME::Program' => qw(program_id));
__PACKAGE__->hasa('OME::LookupTable' => qw(lookup_table_id));
__PACKAGE__->hasa('OME::DataType' => qw(datatype_id));

__PACKAGE__->has_many('actual_inputs','OME::Analysis::ActualInput' =>
		      qw(formal_input_id));
                     
__PACKAGE__->make_filter('__program_name' => 'program_id = ? and name = ?');

sub findByProgramAndName {
    my ($class, $program_id, $name) = @_;
    my @inputs = $class->__program_name(program_id => $program_id,
					name       => $name);
    die "Multiple matching inputs" if (scalar(@inputs) > 1);
    return $inputs[0]; 
}


package OME::Program::FormalOutput;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

require OME::Analysis;

__PACKAGE__->AccessorNames({
    program_id  => 'program',
    datatype_id => 'datatype'
    });

__PACKAGE__->table('formal_outputs');
__PACKAGE__->sequence('formal_output_seq');
__PACKAGE__->columns(Primary => qw(formal_output_id));
__PACKAGE__->columns(Essential => qw(program_id name datatype_id));
__PACKAGE__->hasa('OME::Program' => qw(program_id));
__PACKAGE__->hasa('OME::DataType' => qw(datatype_id));

__PACKAGE__->has_many('actual_outputs','OME::Analysis::ActualOutput' =>
		      qw(formal_output_id));
                     
__PACKAGE__->make_filter('__program_name' => 'program_id = ? and name = ?');

sub findByProgramAndName {
    my ($class, $program_id, $name) = @_;
    my @outputs = $class->__program_name(program_id => $program_id,
					 name       => $name);
    die "Multiple matching outputs" if (scalar(@outputs) > 1);
    return $outputs[0]; 
}


1;

