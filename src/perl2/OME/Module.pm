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
__PACKAGE__->has_many('inputs',OME::Program::FormalInput => qw(program_id));
__PACKAGE__->has_many('outputs',OME::Program::FormalOutput => qw(program_id));
__PACKAGE__->has_many('analyses',OME::Analysis => qw(program_id));


# performAnalysis(parameters,dataset)
# -----------------------------------
# Creates a new Analysis (an instance of this Program being run), and
# performs the analysis against a dataset.  The parameters are defined
# as follows:
#    { $FormalInput => { attribute => $Attribute } }
# or { $FormalInput => { analysis  => $Analysis,
#                        output    => $FormalOutput } }
# These two possibilities model the fact that inputs can come from a
# previous module's calculations, or from user input.

sub performAnalysis {
    my ($self, $params, $dataset) = @_;
    my $factory = $self->Factory();

    my $analysisData = {
        program      => $self,
        experimenter => $self->Session()->User(),
        dataset      => $dataset
        };
    my $analysis = $factory->newObject("OME::Analysis",$analysisData);

    # We've set up everything we can, now delegate to
    # the Analysis object to perform the actual processing.

    $analysis->performAnalysis($params);
    
}


package OME::Program::FormalInput;

use strict;
use $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorName({
    program_id      => 'program',
    lookup_table_id => 'lookup_table'
    });

__PACKAGE__->table('formal_inputs');
__PACKAGE__->sequence('formal_input_seq');
__PACKAGE__->columns(Primary => qw(formal_input_id));
__PACKAGE__->columns(Essential => qw(program_id name column_type));
__PACKAGE__->hasa(OME::Program => qw(program_id));
__PACKAGE__->hasa(OME::LookupTable => qw(lookup_table_id));
                     


package OME::Program::FormalOutput;

use strict;
use $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorName({
    program_id      => 'program'
    });

__PACKAGE__->table('formal_outputs');
__PACKAGE__->sequence('formal_output_seq');
__PACKAGE__->columns(Primary => qw(formal_output_id));
__PACKAGE__->columns(Essential => qw(program_id name column_type));
__PACKAGE__->hasa(OME::Program => qw(program_id));
                     


1;

