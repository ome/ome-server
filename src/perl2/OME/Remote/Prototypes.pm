# OME/Remote/Prototypes.pm

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


package OME::Remote::Prototypes;
use OME;
our $VERSION = $OME::VERSION;

use strict;

use constant NULL_REFERENCE => ">>OBJ:NULL";

require Exporter;
use base qw(Exporter);
our @EXPORT = qw(addPrototype findPrototype
                 verifyInputPrototype verifyOutputPrototype
                 NULL_REFERENCE);
our @EXPORT_OK = qw(addPrototype findPrototype
                    verifyInputPrototype verifyOutputPrototype
                    NULL_REFERENCE);

use Carp;

=head1 NAME

OME::Remote::Prototypes - specifies which API methods are visible via
the Remote Framework

=head1 SYNOPSIS

	package OME::MyPackage;
	use OME::Remote::Prototypes;
	addPrototype("OME::MyPackage","foo",[],['$']);
	sub foo {
	    my ($self) = @_;
	    return 5;
	}

=head1 DESCRIPTION

Contains methods for describing and checking the prototypes of the
method calls visible via the Remote Framework.  When writing a new
package, object methods can be published by calling the addPrototype
procedure.  The module writer must specify the prototype of the
function, since most RPC protocols to do not support the same
flexibility in subroutine calls that Perl has.

=head1 PROTOTYPES

Each published method must have a prototype declared for both its
input parameters and its results.  Because information about the type
of values cannot easily be passed across the RPC channel, all of the
typing information must be fully specified by the prototypes.
Specifically, the Remote Framework must know which parameters on the
input channel are object references, so that the Dispatcher can
demarshall them into the Perl objects they represent.

A single prototype (for either the input or output) is fairly
straightforward: it is an anonymous array of strings.  Each string in
the array specifies the type of one parameter.  The possible values
for each each string are as follows:

=over

=item '$'

Any scalar value

=item '$$'

Any binary scalar value

=item '@'

An array (treated in Perl as an array reference).  Can be abritrarily
complex, but should not contain any object references.

=item '%'

A hash, struct, or the equivalent (treated in Perl as a hash
reference).  Can be arbitrarily complex, but should not contain any
object references.

=item A class name

In the RPC channel, this value must be an object reference, which can
only be obtained from the output of a previous method.  The Dispatcher
will ensure that the object is an instance of a subclass of the
specified class, and throw an error otherwise.  (If you want to accept
any object at all, you can always use the "UNIVERSAL" class, which all
Perl classes are descendants of.)

=item '*'

Signifies a list; all remaining parameters are checked against the
previous entry in the prototype.  This entry, if it exists, should be
last in the prototype, since anything after it will be ignored.
Further, it cannot be the first element of a prototype.  If it is, the
Remote Framework will throw an error when the prototype is registered.

=back

For input prototypes, it is important to know that the published
method will be called in Perl using object-oriented syntax.  As such,
there will always be an implied first parameter (usually called
$self), which should I<not> be specified in the prototype.

Note that these prototypes are not nearly as complicated as what a
Perl method can actually accept as input or generate as output.  There
are some methods which cannot be published without providing a wrapper
method with a simpler interface.  This wrapper method can then be
published.  There are no cases of complex methods like this in the OME
API.

=head2 Examples

Below are some hypothetical subroutines and their corresponding
input and output prototypes.

	sub add {
	    # Takes two numbers and adds them together.
	    my ($self,$addend1,$addend2) = @_;
	    return $addend1+$addend2;
	}
	Input:  ['$','$']
	Output: ['$']

	sub addList {
	    my $self = shift;
	    # Takes in a list of numbers and adds them together.
	    my $sum = 0;
	    $sum += $_ foreach @_;
	    return $sum;
	}
	Input:  ['$','*']
	Output: ['$']

	sub OME::Project::addDatasetToProject {
	    # This method doesn't really exist; don't try to call it.
	    my ($self,$dataset) = @_;
	    $self->Session()->Factory()->
	      maybeNewObject("OME::Project::DatasetMap",
	                     {
	                      project_id => $self->id(),
	                      dataset_id => $dataset->id()
	                     });
	    return;
	}
	Input:  ['OME::Dataset']
	Output: []

	sub OME::Factory::findObjects {
	    my ($self,$className,@criteria) = @_;
	    # You can find the code for this in OME::Factory.
	    return @listOfObjects;
	}
	Input:  ['$','$','*']  (technically, ['$','*'] would also work)
	Output: ['OME::DBObject','*']

=head2 Context

Perl method calls also support the notion of context, which allows a
single subroutine to generate different results depending on how its
called.  (See L<perldata/"Context">.)  No currently RPC
implementations support the notion of context, so the prototype of a
method must specify which context to use explicitly, or the Dispatcher
must guess.  It does this based on the length of the output prototype;
if the prototype is empty ([]), the method is called in void context.
If it has one element, it is called in scalar context.  Otherwise, it
is called in list context.

Note that almost all RPC protocols require a method to return exactly
one return value.  To support Perl methods that return lists, the
Dispatcher will automatically wrap the results of a list-context
function into an array, and return that array as its single return
value.

=head2 Method overloading and renaming

Many Perl methods are overloaded, either by parameter list or by
context.  Currently, the Remote Framework will only support one set of
prototypes (including a single context specification, if any) for any
published method.  To support overloading, the Remote Framework allows
methods to be published under names which are different than the Perl
subroutine implementing them.

=head1 METHODS

The following methods are available for handling prototypes:

=head2 addPrototype

	addPrototype($className,$methodName,
	             $inputPrototype,$outputPrototype,
	             [ context => $context, ]
	             [ publishedName => $publishedName ],
	             [ force => 1 ]);

Publishes the $className::$methodName method via the Remote Framework.
The prototypes of the input parameters and results are specified by
the $inputPrototype and $outputPrototype parameters, and must be of
the format described above.  The context, publishedName, and force
parameters are optional.  The context option forces the Dispatcher to
call the method in a particular context ('void', 'scalar', or 'list').
The publishedName option makes the Dispatcher publish the method under
a different name.  If the force option is set to 1, addPrototype will
silently replace any existing prototype.

=head2 findPrototype

	my $prototype = findPrototype($className,$methodName);

Returns a prototype corresponding to the given $className and
$methodName.  Note that $methodName in this case refers to the
published method name if it differs from the Perl method name.  The
prototype returned is a hash with the following format:

	{
	    input   => the input prototype,
	    output  => the output prototype,
	    method  => the Perl method name,
	    context => the context
	}

The values should not be modified.  The hash can be passed into other
routines in this package which require a prototype.

This method will follow the inheritance tree to find a prototype for
the method specified.  If the specified class does not publish the
given method, each of its ancestors will be checked in order.  If
after checking the entire ancestry tree no prototype is found,
findPrototype will return undef.

=head2 verifyInputPrototype

	verifyInputPrototype($prototype,$params,$subroutine,[@subParams]);

Verifies that a list of input parameters matches $prototype, which
should be a value returned from the findPrototype function.  Uses
$subroutine to translate object references into Perl objects.  If a
parameter is supposed to be an object, $subroutine will be called as
follows:

	my ($object, $replacement) = $subroutine->($parameter,@subParams);

This routine should return the object that $parameter represents, and
the value that should be placed in the parameter list in place of the
original parameter.  (The second result can be undefined, signifying
that the parameter list should not be modified.)  The $object result
must be a descendant of the class specified in the input prototype for
the parameter list to match.

=head2 verifyOutputPrototype

	verifyOutputPrototype($prototype,$params,$subroutine,[@subParams]);

Similar to verifyInputPrototype, but checks a result list against the
output prototype.
Uses
$subroutine to translate Perl objects into object references.  If a
parameter is supposed to be an object, $subroutine will be called as
follows:

	my ($object, $replacement) = $subroutine->($result,@subParams);

In this case, the routine should return $result as the $object output,
since it's already a Perl object.  The $replacement output should be
the object reference to place in the result list.  The $object output
will be checked to make sure it is a descendant of the class specified
in the output prototype.

=cut


our %prototypes;

# If this is set to 1, then addPrototype will be very verbose.
our $debug = 0;

# If this is set to 1, then addPrototype will verify that each Perl
# method exists, and that any types mentioned in the prototypes exist.
our $test = 0;

# Just to shut up some of the tests that aren't actually wrong
require OME::SemanticType;
require OME::Factory;

addPrototype("OME::DBObject","id",['$'],['$']);
addPrototype("OME::DBObject","writeObject",[],[]);
addPrototype("OME::DBObject","storeObject",[],[]);
addPrototype("OME::DBObject","Session",[],['OME::Session']);
addPrototype("OME::DBObject","populate",[],['%']);
addPrototype("OME::DBObject","populate_list",['@'],['@']);

addPrototype("OME::SemanticType::Superclass","semantic_type",
             [],["OME::SemanticType"]);
addPrototype("OME::SemanticType::Superclass","module_execution",
             [],["OME::ModuleExecution"]);
addPrototype("OME::SemanticType::Superclass","target",
             [],["OME::DBObject"]);

addPrototype("OME::Session","commitTransaction",[],[]);
addPrototype("OME::Session","rollbackTransaction",[],[]);
addPrototype("OME::Session","User",[],['OME::SemanticType::Superclass']);
addPrototype("OME::Session","Factory",[],['OME::Factory']);
addPrototype("OME::Session","project",['OME::Project'],[]);
addPrototype("OME::Session","dataset",['OME::Dataset'],[]);

addPrototype("OME::Factory","newObject",['$','%'],['OME::DBObject']);
addPrototype("OME::Factory","maybeNewObject",['$','%'],['OME::DBObject']);
addPrototype("OME::Factory","loadObject",['$','$'],['OME::DBObject']);

# These prototypes follow the original Factory method specs -- the
# criteria must be passed directly in the parameter list.

addPrototype("OME::Factory","objectExists",['$','*'],['$']);
addPrototype("OME::Factory","findObject",['$','*'],['OME::DBObject']);
addPrototype("OME::Factory","findObjects",['$','*'],['OME::DBObject','*']);
addPrototype("OME::Factory","findObjects",['$','*'],['OME::Factory::Iterator'],
             publishedName => "iterateObjects");
addPrototype("OME::Factory","findObjectLike",['$','*'],['OME::DBObject']);
addPrototype("OME::Factory","findObjectsLike",['$','*'],['OME::DBObject','*']);
addPrototype("OME::Factory","findObjectsLike",['$','*'],['OME::Factory::Iterator'],
             publishedName => "iterateObjectsLike");

# These prototypes expect the criteria to be encoded as a
# hash/structure; they are passed to OME::Factory as a hash ref.  They
# are published under different names so as not to conflict with the
# previous methods.

addPrototype("OME::Factory","objectExists",['$','%'],['$'],
             publishedName => 'objectExistsByCriteriaHash');
addPrototype("OME::Factory","findObject",['$','%'],['OME::DBObject'],
             publishedName => 'findObjectByCriteriaHash');
addPrototype("OME::Factory","findObjects",['$','%'],['OME::DBObject','*'],
             publishedName => 'findObjectsByCriteriaHash');
addPrototype("OME::Factory","findObjects",['$','%'],['OME::Factory::Iterator'],
             publishedName => "iterateObjectsByCriteriaHash");
addPrototype("OME::Factory","findObjectLike",['$','%'],['OME::DBObject'],
             publishedName => 'findObjectLikeByCriteriaHash');
addPrototype("OME::Factory","findObjectsLike",['$','%'],['OME::DBObject','*'],
             publishedName => 'findObjectsLikeByCriteriaHash');
addPrototype("OME::Factory","findObjectsLike",['$','%'],['OME::Factory::Iterator'],
             publishedName => "iterateObjectsLikeByCriteriaHash");

# This is the original findAttributes method, which only allows you to
# search by target.

addPrototype("OME::Factory","findAttributes",
             ['$','OME::DBObject'],['OME::SemanticType::Superclass','*']);

# This is the new findAttributes method, which accepts arbitrary
# criteria.

addPrototype("OME::Factory","findAttributes",
             ['$','%'],['OME::SemanticType::Superclass','*'],
             publishedName => 'findAttributesByCriteriaHash');
addPrototype("OME::Factory","findAttributes",
             ['$','%'],['OME::Factory::Iterator'],
             publishedName => 'iterateAttributesByCriteriaHash');

addPrototype("OME::Factory","newAttribute",
             ['$','OME::DBObject','OME::ModuleExecution','%'],
             ['OME::SemanticType::Superclass']);
addPrototype("OME::Factory","loadAttribute",
             ['$','$'],['OME::SemanticType::Superclass']);

addPrototype("OME::Factory::Iterator","first",[],['OME::DBObject']);
addPrototype("OME::Factory::Iterator","next",[],['OME::DBObject']);

addPrototype("OME::Project","name",['$'],['$']);
addPrototype("OME::Project","description",['$'],['$']);
addPrototype("OME::Project","owner",
             ['OME::SemanticType::Superclass'],['OME::SemanticType::Superclass']);
#addPrototype("OME::Project","group",
#             ['OME::SemanticType::Superclass'],['OME::SemanticType::Superclass']);
addPrototype("OME::Project","dataset_links",[],['OME::Project::DatasetMap','*']);
addPrototype("OME::Project","dataset_links",[],['OME::Factory::Iterator'],
             publishedName => "iterate_dataset_links");
addPrototype("OME::Project","addDataset", ['OME::Dataset'], ['OME::Dataset']);

addPrototype("OME::Project::DatasetMap","project",
             ['OME::Project'],['OME::Project']);
addPrototype("OME::Project::DatasetMap","dataset",
             ['OME::Dataset'],['OME::Dataset']);

addPrototype("OME::Dataset","name",['$'],['$']);
addPrototype("OME::Dataset","description",['$'],['$']);
addPrototype("OME::Dataset","locked",['$'],['$']);
addPrototype("OME::Dataset","owner",
             ['OME::SemanticType::Superclass'],['OME::SemanticType::Superclass']);
#addPrototype("OME::Dataset","group",
#             ['OME::SemanticType::Superclass'],['OME::SemanticType::Superclass']);
addPrototype("OME::Dataset","project_links",[],['OME::Project::DatasetMap','*']);
addPrototype("OME::Dataset","project_links",[],['OME::Factory::Iterator'],
             publishedName => "iterate_project_links");
addPrototype("OME::Dataset","image_links",[],['OME::Image::DatasetMap','*']);
addPrototype("OME::Dataset","image_links",[],['OME::Factory::Iterator'],
             publishedName => "iterate_image_links");
addPrototype("OME::Dataset","addImage", ['OME::Image'], ['OME::Image']);
addPrototype("OME::Dataset","importImages",['$'],['$']);

addPrototype("OME::Image","name",['$'],['$']);
addPrototype("OME::Image","description",['$'],['$']);
addPrototype("OME::Image","image_guid",['$'],['$']);
addPrototype("OME::Image","created",['$'],['$']);
addPrototype("OME::Image","inserted",['$'],['$']);
addPrototype("OME::Image","experimenter",
             ['OME::SemanticType::Superclass'],['OME::SemanticType::Superclass']);
addPrototype("OME::Image","group",
             ['OME::SemanticType::Superclass'],['OME::SemanticType::Superclass']);
addPrototype("OME::Image","dataset_links",[],['OME::Image::DatasetMap','*']);
addPrototype("OME::Image","dataset_links",[],['OME::Factory::Iterator'],
             publishedName => "iterate_dataset_links");
addPrototype("OME::Image","all_features",[],['OME::Feature','*']);
addPrototype("OME::Image","all_features",[],['OME::Factory::Iterator'],
             publishedName => "iterate_all_features");
addPrototype("OME::Image","DefaultPixels",[],['OME::SemanticType::Superclass'],
             publishedName => 'getDefaultPixels' );
addPrototype("OME::Image","GetPix",
             ['OME::SemanticType::Superclass'],
             ['OME::Image::Pix']);

addPrototype("OME::Image::Pix","GetPixels",[],['$$']);
addPrototype("OME::Image::Pix","GetPlane",['$','$','$'],['$$']);
addPrototype("OME::Image::Pix","GetStack",['$','$'],['$$']);
addPrototype("OME::Image::Pix","GetROI",
             ['$','$','$','$','$','$','$','$','$','$'],['$$']);

addPrototype("OME::Image::DatasetMap","image",
             ['OME::Image'],['OME::Image']);
addPrototype("OME::Image::DatasetMap","dataset",
             ['OME::Dataset'],['OME::Dataset']);

addPrototype("OME::Feature","name",['$'],['$']);
addPrototype("OME::Feature","tag",['$'],['$']);
addPrototype("OME::Feature","image",['OME::Image'],['OME::Image']);
addPrototype("OME::Feature","parent_feature",['OME::Feature'],['OME::Feature']);
addPrototype("OME::Feature","children",[],['OME::Feature','*']);
addPrototype("OME::Feature","children",[],['OME::Factory::Iterator'],
             publishedName => "iterate_children");

addPrototype("OME::LookupTable","name",['$'],['$']);
addPrototype("OME::LookupTable","description",['$'],['$']);
addPrototype("OME::LookupTable","entries",[],['OME::LookupTable::Entry','*']);
addPrototype("OME::LookupTable","entries",[],['OME::Factory::Iterator'],
             publishedName => "iterate_entries");

addPrototype("OME::LookupTable::Entry","value",['$'],['$']);
addPrototype("OME::LookupTable::Entry","label",['$'],['$']);
addPrototype("OME::LookupTable::Entry","lookup_table",
             ['OME::LookupTable'],['OME::LookupTable']);

addPrototype("OME::DataTable","granularity",['$'],['$']);
addPrototype("OME::DataTable","table_name",['$'],['$']);
addPrototype("OME::DataTable","description",['$'],['$']);
addPrototype("OME::DataTable","data_columns",[],['OME::DataTable::Column','*']);
addPrototype("OME::DataTable","data_columns",[],['OME::Factory::Iterator'],
             publishedName => "iterate_data_columns");

addPrototype("OME::DataTable::Column","column_name",['$'],['$']);
addPrototype("OME::DataTable::Column","description",['$'],['$']);
addPrototype("OME::DataTable::Column","sql_type",['$'],['$']);
addPrototype("OME::DataTable::Column","reference_type",['$'],['$']);
addPrototype("OME::DataTable::Column","data_table",
             ['OME::DataTable'],['OME::DataTable']);

addPrototype("OME::SemanticType","granularity",['$'],['$']);
addPrototype("OME::SemanticType","name",['$'],['$']);
addPrototype("OME::SemanticType","description",['$'],['$']);
addPrototype("OME::SemanticType","semantic_elements",
             [],['OME::SemanticType::Element','*']);
addPrototype("OME::SemanticType","semantic_elements",
             [],['OME::Factory::Iterator'],
             publishedName => "iterate_semantic_elements");

addPrototype("OME::SemanticType::Element","name",['$'],['$']);
addPrototype("OME::SemanticType::Element","description",['$'],['$']);
addPrototype("OME::SemanticType::Element","semantic_type",
             ['OME::SemanticType'],['OME::SemanticType']);
addPrototype("OME::SemanticType::Element","data_column",
             ['OME::DataTable::Column'],['OME::DataTable::Column']);

addPrototype("OME::Module::Category","name",['$'],['$']);
addPrototype("OME::Module::Category","description",['$'],['$']);
addPrototype("OME::Module::Category","parent_category",
             ["OME::Module::Category"],["OME::Module::Category"]);
addPrototype("OME::Module::Category","children",
             [],['OME::Module::Category','*']);
addPrototype("OME::Module::Category","children",
             [],['OME::Factory::Iterator'],
             publishedName => "iterate_children");
addPrototype("OME::Module::Category","modules",
             [],['OME::Module','*']);
addPrototype("OME::Module::Category","modules",
             [],['OME::Factory::Iterator'],
             publishedName => "iterate_modules");

addPrototype("OME::Module","name",['$'],['$']);
addPrototype("OME::Module","description",['$'],['$']);
addPrototype("OME::Module","category",
             ['OME::Module::Category'],['OME::Module::Category']);
addPrototype("OME::Module","module_type",['$'],['$']);
addPrototype("OME::Module","location",['$'],['$']);
addPrototype("OME::Module","default_iterator",['$'],['$']);
addPrototype("OME::Module","new_feature_tag",['$'],['$']);
addPrototype("OME::Module","execution_instructions",['$'],['$']);
addPrototype("OME::Module","inputs",[],['OME::Module::FormalInput','*']);
addPrototype("OME::Module","inputs",[],['OME::Factory::Iterator'],
             publishedName => "iterate_inputs");
addPrototype("OME::Module","outputs",[],['OME::Module::FormalOutput','*']);
addPrototype("OME::Module","outputs",[],['OME::Factory::Iterator'],
             publishedName => "iterate_outputs");
addPrototype("OME::Module","module_executions",[],['OME::ModuleExecution','*']);
addPrototype("OME::Module","module_executions",[],['OME::Factory::Iterator'],
             publishedName => "iterate_module_executions");

addPrototype("OME::Module::FormalInput","name",['$'],['$']);
addPrototype("OME::Module::FormalInput","description",['$'],['$']);
addPrototype("OME::Module::FormalInput","optional",['$'],['$']);
addPrototype("OME::Module::FormalInput","list",['$'],['$']);
addPrototype("OME::Module::FormalInput","user_defined",['$'],['$']);
addPrototype("OME::Module::FormalInput","semantic_type",
             ['OME::SemanticType'],['OME::SemanticType']);
addPrototype("OME::Module::FormalInput","lookup_table",
             ['OME::LookupTable'],['OME::LookupTable']);
addPrototype("OME::Module::FormalInput","module",
             ['OME::Module'],['OME::Module']);

addPrototype("OME::Module::FormalOutput","name",['$'],['$']);
addPrototype("OME::Module::FormalOutput","description",['$'],['$']);
addPrototype("OME::Module::FormalOutput","feature_tag",['$'],['$']);
addPrototype("OME::Module::FormalOutput","optional",['$'],['$']);
addPrototype("OME::Module::FormalOutput","list",['$'],['$']);
addPrototype("OME::Module::FormalOutput","semantic_type",
             ['OME::SemanticType'],['OME::SemanticType']);
addPrototype("OME::Module::FormalOutput","module",
             ['OME::Module'],['OME::Module']);

addPrototype("OME::ModuleExecution","module",['OME::Module'],['OME::Module']);
addPrototype("OME::ModuleExecution","dataset",['OME::Dataset'],['OME::Dataset']);
addPrototype("OME::ModuleExecution","dependence",['$'],['$']);
addPrototype("OME::ModuleExecution","timestamp",['$'],['$']);
addPrototype("OME::ModuleExecution","status",['$'],['$']);
addPrototype("OME::ModuleExecution","inputs",[],['OME::ModuleExecution::ActualInput','*']);
addPrototype("OME::ModuleExecution","inputs",[],['OME::Factory::Iterator'],
             publishedName => "iterate_inputs");

addPrototype("OME::ModuleExecution::ActualInput","module_execution",
             ['OME::ModuleExecution'],['OME::ModuleExecution']);
addPrototype("OME::ModuleExecution::ActualInput","input_module_execution",
             ['OME::ModuleExecution'],['OME::ModuleExecution']);
addPrototype("OME::ModuleExecution::ActualInput","formal_input",
             ['OME::Module::FormalInput'],['OME::Module::FormalInput']);

addPrototype("OME::AnalysisChain","owner",
             ['OME::SemanticType::Superclass'],['OME::SemanticType::Superclass']);
addPrototype("OME::AnalysisChain","name",['$'],['$']);
addPrototype("OME::AnalysisChain","description",['$'],['$']);
addPrototype("OME::AnalysisChain","locked",['$'],['$']);
addPrototype("OME::AnalysisChain","nodes",[],['OME::AnalysisChain::Node','*']);
addPrototype("OME::AnalysisChain","nodes",[],['OME::Factory::Iterator'],
             publishedName => "iterate_nodes");
addPrototype("OME::AnalysisChain","links",[],['OME::AnalysisChain::Link','*']);
addPrototype("OME::AnalysisChain","links",[],['OME::Factory::Iterator'],
             publishedName => "iterate_links");
addPrototype("OME::AnalysisChain","paths",[],['OME::AnalysisPath','*']);
addPrototype("OME::AnalysisChain","paths",[],['OME::Factory::Iterator'],
             publishedName => "iterate_paths");

addPrototype("OME::AnalysisChain::Node","analysis_chain",
             ['OME::AnalysisChain'],['OME::AnalysisChain']);
addPrototype("OME::AnalysisChain::Node","module",
             ['OME::Module'],['OME::Module']);
addPrototype("OME::AnalysisChain::Node","iterator_tag",['$'],['$']);
addPrototype("OME::AnalysisChain::Node","new_feature_tag",['$'],['$']);
addPrototype("OME::AnalysisChain::Node","input_links",
             [],['OME::AnalysisChain::Link','*']);
addPrototype("OME::AnalysisChain::Node","input_links",
             [],['OME::Factory::Iterator'],
             publishedName => "iterate_input_links");
addPrototype("OME::AnalysisChain::Node","output_links",
             [],['OME::AnalysisChain::Link','*']);
addPrototype("OME::AnalysisChain::Node","output_links",
             [],['OME::Factory::Iterator'],
             publishedName => "iterate_output_links");

addPrototype("OME::AnalysisChain::Link","analysis_chain",
             ['OME::AnalysisChain'],['OME::AnalysisChain']);
addPrototype("OME::AnalysisChain::Link","from_node",
             ['OME::AnalysisChain::Node'],['OME::AnalysisChain::Node']);
addPrototype("OME::AnalysisChain::Link","from_output",
             ['OME::Module::FormalOutput'],['OME::Module::FormalOutput']);
addPrototype("OME::AnalysisChain::Link","to_node",
             ['OME::AnalysisChain::Node'],['OME::AnalysisChain::Node']);
addPrototype("OME::AnalysisChain::Link","to_input",
             ['OME::Module::FormalInput'],['OME::Module::FormalInput']);

addPrototype("OME::AnalysisPath","path_length",['$'],['$']);
addPrototype("OME::AnalysisPath","analysis_chain",
             ['OME::AnalysisChain'],['OME::AnalysisChain']);
addPrototype("OME::AnalysisPath","path_nodes",
             [],['OME::AnalysisPath::Map','*']);
addPrototype("OME::AnalysisPath","path_nodes",
             [],['OME::Factory::Iterator'],
             publishedName => "iterate_path_nodes");

addPrototype("OME::AnalysisPath::Map","path_order",['$'],['$']);
addPrototype("OME::AnalysisPath::Map","path",
             ['OME::AnalysisPath'],['OME::AnalysisPath']);
addPrototype("OME::AnalysisPath::Map","analysis_chain_node",
             ['OME::AnalysisChain::Node'],['OME::AnalysisChain::Node']);

addPrototype("OME::AnalysisChainExecution","timestamp",['$'],['$']);
addPrototype("OME::AnalysisChainExecution","analysis_chain",
             ['OME::AnalysisChain'],['OME::AnalysisChain']);
addPrototype("OME::AnalysisChainExecution","dataset",
             ['OME::Dataset'],['OME::Dataset']);
addPrototype("OME::AnalysisChainExecution","experimenter",
             ['OME::SemanticType::Superclass'],['OME::SemanticType::Superclass']);
addPrototype("OME::AnalysisChainExecution","node_executions",
             [],['OME::AnalysisChainExecution::NodeExecution','*']);
addPrototype("OME::AnalysisChainExecution","node_executions",
             [],['OME::Factory::Iterator'],
             publishedName => "iterate_node_executions");

addPrototype("OME::AnalysisChainExecution::NodeExecution","analysis_chain_execution",
             ['OME::AnalysisChainExecution'],['OME::AnalysisChainExecution']);
addPrototype("OME::AnalysisChainExecution::NodeExecution","analysis_chain_node",
             ['OME::AnalysisChain::Node'],['OME::AnalysisChain::Node']);
addPrototype("OME::AnalysisChainExecution::NodeExecution","module_execution",
             ['OME::ModuleExecution'],['OME::ModuleExecution']);

addPrototype("OME::Tasks::ProjectManager","new",
             [],['OME::Tasks::ProjectManager']);
addPrototype("OME::Tasks::ProjectManager","addToProject",
             ['OME::Dataset','OME::Project'],[],
             publishedName => "addDatasetToProject");
addPrototype("OME::Tasks::ProjectManager","addToProject",
             ['OME::Dataset'],[],
             publishedName => "addDatasetToCurrentProject");

addPrototype("OME::Tasks::DatasetManager","new",
             [],['OME::Tasks::DatasetManager']);
addPrototype("OME::Tasks::DatasetManager","addToDataset",
             ['OME::Image','OME::Dataset'],[],
             publishedName => "addImageToDataset");
addPrototype("OME::Tasks::DatasetManager","addToDataset",
             ['OME::Image'],[],
             publishedName => "addImageToCurrentDataset");

addPrototype("OME::Tasks::ChainManager","new",
             ['OME::Session'],['OME::Tasks::ChainManager']);
addPrototype("OME::Tasks::ChainManager","createChain",
             ['$','$','OME::SemanticType::Superclass'],
             ['OME::AnalysisChain']);
addPrototype("OME::Tasks::ChainManager","cloneChain",
             ['OME::AnalysisChain','OME::SemanticType::Superclass'],
             ['OME::AnalysisChain']);
addPrototype("OME::Tasks::ChainManager","findModule",['$'],['OME::Module']);
addPrototype("OME::Tasks::ChainManager","addNode",
             ['OME::AnalysisChain','OME::Module','$','$'],
             ['OME::AnalysisChain::Node']);
addPrototype("OME::Tasks::ChainManager","removeNode",
             ['OME::AnalysisChain','OME::AnalysisChain::Node'],[]);
addPrototype("OME::Tasks::ChainManager","getNode",
             ['OME::AnalysisChain','$'],
             ['OME::AnalysisChain::Node']);
addPrototype("OME::Tasks::ChainManager","getFormalInput",
             ['OME::AnalysisChain','OME::AnalysisChain::Node','$'],
             ['OME::Module::FormalInput']);
addPrototype("OME::Tasks::ChainManager","addLink",
             ['OME::AnalysisChain',
              'OME::AnalysisChain::Node','OME::Module::FormalOutput',
              'OME::AnalysisChain::Node','OME::Module::FormalInput'],
             ['OME::AnalysisChain::Link']);
addPrototype("OME::Tasks::ChainManager","addLink",
             ['OME::AnalysisChain',
              'OME::AnalysisChain::Node','$',
              'OME::AnalysisChain::Node','$'],
             ['OME::AnalysisChain::Link'],
             publishedName => 'addLinkByName');
addPrototype("OME::Tasks::ChainManager","removeLink",
             ['OME::AnalysisChain',
              'OME::AnalysisChain::Node','OME::Module::FormalOutput',
              'OME::AnalysisChain::Node','OME::Module::FormalInput'],
             [],
             publishedName => 'removeLinkByParameter');
addPrototype("OME::Tasks::ChainManager","removeLink",
             ['OME::AnalysisChain',
              'OME::AnalysisChain::Node','$',
              'OME::AnalysisChain::Node','$'],
             [],
             publishedName => 'removeLinkByName');
addPrototype("OME::Tasks::ChainManager","removeLink",
             ['OME::AnalysisChain','OME::AnalysisChain::Link'],[]);
addPrototype("OME::Tasks::ChainManager","getUserInputs",
             ['OME::AnalysisChain'],['@']);

sub addPrototype {
    my ($class,$method,$inputPrototype,$outputPrototype,%options) = @_;

    # Get the published name (default to the method name), and verify
    # there's not already a prototype for this method.

    if ($debug) {
        print STDERR "  $class","->$method\n";
        print STDERR "    Input:  [";
        print STDERR join(",",@$inputPrototype),"]\n";
        print STDERR "    Output: [";
        print STDERR join(",",@$outputPrototype),"]\n";
    }

    if ($test) {
        die "Malformed class name $class"
          unless $class =~ /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;
        eval "require $class";

        carp "Method ${class}->${method} does not exist"
          unless UNIVERSAL::can($class,$method);
    }

    my $publishedName =
      exists $options{publishedName}?
        $options{publishedName}:
        $method;

    die "Prototype already exists for $class\::$publishedName!"
      if exists $prototypes{$class}->{$publishedName} &&
         (!$options{force});

    # Verify that the prototypes are well-formed.

    die "Prototypes must be array references"
      unless (ref($inputPrototype) eq "ARRAY") &&
             (ref($outputPrototype) eq "ARRAY");

    foreach (@$inputPrototype,@$outputPrototype) {
        next if $_ eq '$';
        next if $_ eq '$$';
        next if $_ eq '@';
        next if $_ eq '%';
        next if $_ eq '*';
        if (/^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/) {
            if ($test) {
                eval "require $_";
                eval {
                    no strict 'refs';
                    my $fullname = "$_\::VERSION";
                    carp "Class $_ does not exist"
                      unless defined $$fullname;
                };
            }
            next;
        }
        die "Illegal prototype entry: $_";
    }

    if (scalar(@$inputPrototype) > 0) {
        die "First entry of prototype cannot be '*'"
          if ($inputPrototype->[0] eq '*');
    }
    if (scalar(@$outputPrototype) > 0) {
        die "First entry of prototype cannot be '*'"
          if ($outputPrototype->[0] eq '*');
    }

    # Get the context, and verify it.

    my $context;
    if (exists $options{context}) {
        $context = lc($options{context});
        die "Illegal context"
          if ($context ne "void") &&
             ($context ne "scalar") &&
             ($context ne "list");
    } elsif (scalar(@$outputPrototype) == 0) {
        $context = "void";
    } elsif (scalar(@$outputPrototype) == 1) {
        $context = "scalar";
    } else {
        $context = "list";
    }

    # Create the prototype and store it

    my $prototype = {
                     input   => $inputPrototype,
                     output  => $outputPrototype,
                     method  => "$method",
                     context => $context
                    };
    bless $prototype, "OME::Remote::Prototypes::PrototypeObject";

    $prototypes{$class}->{$publishedName} = $prototype;
}

sub findPrototype {
    my ($class, $method) = @_;

    my @classesToCheck = ($class);
    my $prototypeFound;

    #print STDERR "*** $class\n ";
    while (my $nextClass = shift(@classesToCheck)) {
        if (exists $prototypes{$nextClass}->{$method}) {
            $prototypeFound = $prototypes{$nextClass}->{$method};
            last;
        }
        my $isaRef = "${nextClass}::ISA";
        no strict 'refs';
        #print STDERR join(' ',@$isaRef)," ";
        push @classesToCheck, @$isaRef;
        use strict 'refs';
    }

    #print STDERR "\n";

    return $prototypeFound;
}

# Verifies one value in a parameter list against the type specified in
# the prototype.
#   PRIVATE METHOD
#   Inputs:
#     $which      - the prototype to use ('input' or 'output')
#     $param      - the parameter value (should be an lvalue)
#     $type       - the type to check it against
#     $subroutine - a subroutine (code reference) used to perform
#                   object reference replacement (see the POD above)
#     @subInputs  - other values to pass into the subroutine
#   Returns:
#     1 - parameter matches type
#     0 - parameter does not match type
#     If $type is an object type, $param will be modified according
#     to what is returned by $subroutine.

sub __verifyOneValue {
    my ($which,$param,$type,$subroutine,@subInputs) = @_;
    my $ref = ref($param);

    if ($type eq '$') {
        # Function expects a single scalar
        return (!$ref);
    }

    if ($type eq '$$') {
        if ($which eq 'output') {
            return 0 if $ref;
            print STDERR "  Got some binary... ",length($param),"\n";
            $_[1] = SOAP::Data->type(base64 => $param);
            return 1;
        } else {
            return !$ref;
        }
    }

    if ($type eq '@') {
        # Function expects an array reference
        return 0 if $ref ne "ARRAY";

        #print "  Checking array\n";

        # Check the values of the array -- if any is an object, array,
        # or hash, use this method recursively to turn it into an object
        # reference.
        foreach my $value (@$param) {
            #print "    Value $value\n";
            if (ref($value) eq 'ARRAY') {
                my $good = __verifyOneValue($which,$value,'@',
                                            $subroutine,@subInputs);
                return 0 unless $good;
            } elsif (ref($value) eq 'HASH') {
                my $good = __verifyOneValue($which,$value,'%',
                                            $subroutine,@subInputs);
                return 0 unless $good;
            } elsif (ref($value) || $value =~ /^(>|&gt;)(>|&gt;)OBJ:/) {
                my $good = __verifyOneValue($which,$value,'UNIVERSAL',
                                            $subroutine,@subInputs);
                return 0 unless $good;
            }
        }

        return 1;
    }

    if ($type eq '%') {
        # Function expects a hash reference
        return 0 if $ref ne "HASH";

        #print "   Checking hash\n";

        # Check the values of the hash -- if any is an object, array, or
        # hash, use this method recursively to turn it into an object
        # reference.
        foreach my $key (keys %$param) {
            my $value = $param->{$key};
            #print "   $key = $value =>";
            if (ref($value) eq 'ARRAY') {
                my $good = __verifyOneValue($which,$param->{$key},'@',
                                            $subroutine,@subInputs);
                return 0 unless $good;
            } elsif (ref($value) eq 'HASH') {
                my $good = __verifyOneValue($which,$param->{$key},'%',
                                            $subroutine,@subInputs);
                return 0 unless $good;
            } elsif (ref($value) || $value =~ /^(>|&gt;)(>|&gt;)OBJ:/) {
                my $good = __verifyOneValue($which,$param->{$key},'UNIVERSAL',
                                            $subroutine,@subInputs);
                return 0 unless $good;
            }
            #print " ",$param->{$key},"\n";
        }

        return 1;
    }

    # Call the helper subroutine.
    return 0 unless defined $subroutine;
    my ($good,$object,$replacement) = $subroutine->($param,@subInputs);

    # If the subroutine flags an error (by returing 0), then
    # the parameter doesn't match.
    return 0 unless $good;

    # Check the inheritance of the object.
    $good = (!defined $object) || UNIVERSAL::isa($object,$type);
    #print STDERR "  vone $good\n";

    # Replace the object in the parameter list, if necessary.
    $_[1] = $replacement if defined $replacement && $good;

    return $good;
}

# Verifies a list of parameters against a prototype.
#   PRIVATE METHOD
#   Inputs:
#     $which      - the prototype to use ('input' or 'output')
#     $prototype  - prototype object returned from findPrototype
#     $params     - list of parameters (array reference)
#     $subroutine - a subroutine (code reference) used to perform
#                   object reference replacement (see the POD above)
#     @subInputs  - other values to pass into the subroutine
#   Returns:
#     1 - parameter list matches prototype
#     0 - doesn't
#     Any parameters matching an object type will be replaced
#     according to what is returned by $subroutine.

sub __verifyPrototype {
    my ($which,$prototype,$params,$subroutine,@subParams) = @_;

    die "$prototype not a prototype!"
      unless UNIVERSAL::isa($prototype,"OME::Remote::Prototypes::PrototypeObject");

    my @types = (@{$prototype->{$which}});
    my $lastType;
    my $currentType = shift(@types);
    foreach my $param (@$params) {
        return 0 unless defined $currentType;

        my $typeToCheck =
          $currentType eq "*"? $lastType: $currentType;

        return 0 unless defined $typeToCheck;
        return 0 unless __verifyOneValue($which,$param,$typeToCheck,
                                         $subroutine,@subParams);

        if ($currentType ne "*") {
            $lastType = $currentType;
            $currentType = shift(@types);
        }
    }

    return 1;
}

sub verifyInputPrototype {
    return __verifyPrototype("input",@_);
}

sub verifyOutputPrototype {
    return __verifyPrototype("output",@_);
}


1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
