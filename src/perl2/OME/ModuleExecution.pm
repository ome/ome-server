# OME/Analysis.pm

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


package OME::Analysis;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    program_id => 'program',
    dataset_id => 'dataset'
    });

__PACKAGE__->table('analyses');
__PACKAGE__->sequence('analysis_seq');
__PACKAGE__->columns(Primary => qw(analysis_id));
__PACKAGE__->columns(Essential => qw(program_id dependence
				     dataset_id));
__PACKAGE__->columns(Timing => qw(timestamp status));
__PACKAGE__->hasa('OME::Program' => qw(program_id));
__PACKAGE__->hasa('OME::Dataset' => qw(dataset_id));
__PACKAGE__->has_many('inputs','OME::Analysis::ActualInput' => qw(analysis_id));
__PACKAGE__->has_many('outputs','OME::Analysis::ActualOutput' => qw(analysis_id));



package OME::Analysis::ActualInput;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
require OME::Program;
use base qw(OME::DBObject);

use fields qw(_attribute);

__PACKAGE__->AccessorNames({
    analysis_id      => 'analysis',
    formal_input_id  => 'formal_input',
    actual_output_id => 'actual_output'
    });

__PACKAGE__->table('actual_inputs');
__PACKAGE__->sequence('actual_input_seq');
__PACKAGE__->columns(Primary => qw(actual_input_id));
__PACKAGE__->columns(Essential => qw(actual_output_id analysis_id formal_input_id));
__PACKAGE__->hasa('OME::Analysis' => qw(analysis_id));
__PACKAGE__->hasa('OME::Program::FormalInput' => qw(formal_input_id));
__PACKAGE__->hasa('OME::Analysis::ActualOutput' => qw(actual_output_id));



sub attribute {
    my $self = shift;
    my $formalInput = $self->formal_input();
    my $columnType = $formalInput->column_type();
    my $dataType = $columnType->datatype();
    my $attributePackage = $dataType->getAttributePackage();

    if (@_) {
       	# We are setting the attribute; make sure it is of the
	# appropriate data type, and that it has an ID.

	my $result = $self->{_attribute};
	my $attribute = shift;
	die "This attribute is not of the correct type."
	    unless ($attribute->isa($attributePackage));
	die "This attribute does not have an ID."
	    unless (defined $attribute->ID());
	$self->attribute_id($attribute->ID());
	$self->{_attribute} = $attribute;
	return $result;
    } else {
	my $attribute = $self->{_attribute};
	if (!defined $attribute) {
	  $attribute = $self->Session()->Factory()->loadObject($attributePackage,
						    $self->attribute_id());
	  $self->{_attribute} = $attribute;
	}
	return $attribute;
    }
}


package OME::Analysis::ActualOutput;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
require OME::Program;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    analysis_id      => 'analysis',
    formal_output_id => 'formal_output'
    });

__PACKAGE__->table('actual_outputs');
__PACKAGE__->sequence('actual_output_seq');
__PACKAGE__->columns(Primary => qw(actual_output_id));
__PACKAGE__->columns(Essential => qw(analysis_id formal_output_id));
__PACKAGE__->hasa('OME::Analysis' => qw(analysis_id));
__PACKAGE__->hasa('OME::Program::FormalOutput' => qw(formal_output_id));



1;
