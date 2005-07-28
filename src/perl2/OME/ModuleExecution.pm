# OME/ModuleExecution.pm

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


package OME::ModuleExecution;

=head1 NAME

OME::ModuleExecution - execution of an analysis module

=head1 DESCRIPTION

The C<module_execution> class represents an execution of an OME analysis
module against a dataset of images.  Each actual execution of a module
is represented by exactly one C<module_execution>.  If the results of a module
execution are reused during the future execution of an analysis chain,
no new C<module_execution> is created (although a new
C<AnalysisExecution::NodeExecution> is created).

C<Analyses> have a notion of <i>dependence</i> which help the analysis
engine determine when analysis results are eligible for reuse.  Each
C<module_execution> has a dependence of Global, Dataset, or Image.

An dependence of Image signifies that the results produced by an
analysis module for a given image are independent of which other
images are in the dataset being analyzed.  This allows the results of
this C<module_execution> to be reused, even if the dataset being executed in
the future is different.

A dependence of Dataset, on the other hand, signifies that the results
are not independent on a per-image basis.  Attributes created by a
dataset-dependent C<module_execution> could only be reused if the future
analysis is being performed against the exact same dataset.

A dependence of Global is rarely seen, and is only possible if the
module generates global outputs.  In this case, the distinction
between image- and dataset-dependence has no meaning.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('module_executions');
__PACKAGE__->setSequence('module_execution_seq');
__PACKAGE__->addPrimaryKey('module_execution_id');
__PACKAGE__->addColumn(module_id => 'module_id');
__PACKAGE__->addColumn(module => 'module_id','OME::Module',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        ForeignKey => 'modules',
                       });
__PACKAGE__->addColumn(virtual_mex => 'virtual_mex',
                       {
                        SQLType => 'boolean',
                        NotNull => 1,
                        Default => 'f',
                       });
__PACKAGE__->addColumn(dependence => 'dependence',
                       {
                        SQLType => 'char(1)',
                        NotNull => 1,
                        Check   => "(dependence in ('G','D','I'))",
                       });
__PACKAGE__->addColumn(dataset_id => 'dataset_id');
__PACKAGE__->addColumn(dataset => 'dataset_id','OME::Dataset',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        ForeignKey => 'datasets',
                       });
__PACKAGE__->addColumn(image_id => 'image_id');
__PACKAGE__->addColumn(image => 'image_id','OME::Image',
                       {
                        SQLType => 'integer',
                        Indexed => 1,
                        ForeignKey => 'images',
                       });
__PACKAGE__->addColumn(iterator_tag => 'iterator_tag',
                       {SQLType => 'varchar(128)'});
__PACKAGE__->addColumn(new_feature_tag => 'new_feature_tag',
                       {SQLType => 'varchar(128)'});
__PACKAGE__->addColumn(input_tag => 'input_tag',
                       {SQLType => 'text'});
__PACKAGE__->addColumn(experimenter_id => 'experimenter_id',
                       {SQLType => 'integer', Indexed => 1, NotNull => 1,
                        ForeignKey => 'experimenters'});
__PACKAGE__->addColumn(experimenter => 'experimenter_id','@Experimenter');
__PACKAGE__->addColumn(group_id => 'group_id',
                       {SQLType => 'integer', Indexed => 1,
                        ForeignKey => 'groups'});
__PACKAGE__->addColumn(group => 'group_id','@Group');
__PACKAGE__->addColumn(timestamp => 'timestamp',
                       {
                        SQLType => 'timestamp',
                        Default => 'now()',
                       });
__PACKAGE__->addColumn(total_time => 'total_time',
                       {SQLType => 'float'});
__PACKAGE__->addColumn(attribute_sort_time => 'attribute_sort_time',
                       {SQLType => 'float'});
__PACKAGE__->addColumn(attribute_db_time => 'attribute_db_time',
                       {SQLType => 'float'});
__PACKAGE__->addColumn(attribute_create_time => 'attribute_create_time',
                       {SQLType => 'float'});
__PACKAGE__->addColumn(status => 'status',{SQLType => 'varchar(16)'});
__PACKAGE__->addColumn(error_message => 'error_message',
                       {SQLType => 'text'});
__PACKAGE__->hasMany('inputs','OME::ModuleExecution::ActualInput' =>
                     'module_execution');
__PACKAGE__->hasMany('consumed_outputs','OME::ModuleExecution::ActualInput' =>
                     'input_module_execution');
__PACKAGE__->hasMany('untypedOutputs','OME::ModuleExecution::SemanticTypeOutput' =>
                     'module_execution');
__PACKAGE__->hasMany('parentalOutputs','OME::ModuleExecution::ParentalOutput' =>
                     'module_execution');
__PACKAGE__->hasMany('node_executions','OME::AnalysisChainExecution::NodeExecution' =>
                     'module_execution');
__PACKAGE__->addACL ({
        	user    => 'experimenter_id',
        	group   => 'group_id',
        	});


__PACKAGE__->addPseudoColumn('predecessors','has-many',
			     'OME::ModuleExecution');

__PACKAGE__->addPseudoColumn('successors','has-many',
			     'OME::ModuleExecution');

__PACKAGE__->addPseudoColumn('chain_executions','has-many',
			     'OME::AnalysisChainExecution');



=head1 METHODS (C<module_execution>)

The following methods are available to C<module_execution> in addition to
those defined by L<OME::DBObject>.

=head2 module

	my $module = $module_execution->module();
	$module_execution->module($module);

Returns or sets the analysis module that was executed.

=head2 dataset

	my $dataset = $module_execution->dataset();
	$module_execution->dataset($dataset);

Returns or sets the dataset that was analyzed.  This column should
only be defined if the dependence of the module is 'D'.

=head2 image

	my $image = $module_execution->image();
	$module_execution->image($image);

Returns or sets the image that was analyzed.  This column should only
be defined if the dependence of the module is 'I'.

=head2 dependence

	my $dependence = $module_execution->dependence();
	$module_execution->dependence($dependence);

Returns or sets the dependence of this module_execution.  This will be either
'G', 'D', or 'I'.

=head2 timestamp

	my $timestamp = $module_execution->timestamp();
	$module_execution->timestamp($timestamp);

Returns or sets when the module_execution was completed.

=head2 status

	my $status = $module_execution->status();
	$module_execution->status($status);

Returns or sets the module_execution's status.  Current possible values are:

=over

=item C<RUNNING>

The module is still executing.

=item C<FINISHED>

The module has finished, and all results are in the database.

=item Anything else

There was an error executing the module.  The return value is the
error string generated.

=back

=head2 inputs

	my @inputs = $module_execution->inputs();
	my $input_iterator = $module_execution->inputs();

Returns or iterates, depending on context, a list of all of the
L<OME::ModuleExecution::ActualInputs> associated with this
    module_execution.

=head2 predecessors
    
       my @predecessors = $module_execution->predecessors();

Returns the set  of all of the module executions that are immediate
predecessors to this module execution in the data history.  

=head2 successors
    
       my @successors = $module_execution->successors();

Returns the set  of all of the module executions that are immediate
successors to this module execution in the data history.  

=head2 chain_executions
    
       my @chexes = $module_execution->chain_executions();


The list of chain executions that this module execution is associated
with. Note that this call will not produce any results for  mexes
corresponding to universal executions.

=head2 actual_outputs

    my @actual_outputs  = $module_execution->actual_outputs()

The list of "forward links" for this module execution  - instances of
OME::ModuleExecution::ActualInput with $module_execution as the
input_module_execution. 

=cut


sub predecessors {
    my $self = shift;

    my $factory = $self->Session()->Factory();
    return $factory->findObjects('OME::ModuleExecution',
				 { 'consumed_outputs.module_execution' => $self ,
				    '__distinct' => 'id'});
}

sub successors { 
    my $self = shift;

    my $factory = $self->Session()->Factory();

    return $factory->findObjects('OME::ModuleExecution',
				{ 'inputs.input_module_execution' => $self,
				 '__distinct' => 'id'});
}

sub chain_executions {
    my $self = shift;

    my $factory = $self->Session()->Factory();
    
    return $factory->findObjects('OME::AnalysisChainExecution', 
				 {'node_executions.module_execution' => $self,
				 '__distinct' => 'id'});
}


1;


__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

