# OME/Web/RunClassifier.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::RunClassifier;

use strict;
use vars qw($VERSION);
use Log::Agent;
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Analysis::Engine;
use OME::Tasks::ModuleExecutionManager;
use OME::Tasks::ClassifierTasks;
use OME::Fork;
use OME::Tasks::NotificationManager;

use base qw(OME::Web);

sub getPageTitle {
	return "OME: Run a Classifier" ;

}

{
	my $menu_text = "Run Classifier";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my	$self = shift ;
	my 	$q = $self->CGI() ;
	my	$session=$self->Session();
    my  $factory = $session->Factory();

	# get parameters
	my $dataset;
	if( $q->param( 'exp_dataset_id' ) ) {
		$dataset = $factory->loadObject( 'OME::Dataset', $q->param( 'exp_dataset_id' ) )
			or die "Couldn't load dataset with id '".$q->param( 'exp_dataset_id' )."'";
	} else {
		$dataset = $session->dataset();
	}
	
	# load the selected classifier
	my $classifier;
	if( $q->param( 'classifier_id' ) ) {
		$classifier = $factory->loadObject( '@BayesNetClassifier', $q->param( 'classifier_id' ) )
			or die "Couldn't load BayesNetClassifier id='".$q->param( 'classifier_id' )."'";
	}

	# Run the classifier?
	if( $q->param( 'action' ) eq 'runClassifier' ) {
		my $classifier_chain = OME::Tasks::ClassifierTasks->
			getClassifierChain( $classifier );
		my %formal_inputs;
		foreach my $input_name( "Classifier", "CategoriesUsed", "Signatures Needed" ) {
			$formal_inputs{ $input_name } = $factory->
				findObject( 'OME::Module::FormalInput',
					'module.name' => 'BayesNet Classifier',
					name          => $input_name
				) or die "Couldn't find '$input_name' formal input to module 'BayesNet Classifier'";
		}

my $chain_id = $classifier_chain->id;
my $dataset_id = $dataset->id;
my $input_string = join( '-', map( $_->id.':'.$classifier->module_execution->id, values %formal_inputs ) );
#my $fi_id = $classificationInput->id;
#my $mex_id_list = join( ',', map( $_->id, @$classification_mexes ) );
return( 'HTML', <<END_INSTRS );
<p>Due to technical difficulties involveing apache and matlab, you will
have to execute this on the command line. Make sure you've followed
these setup instructions <a href="http://cvs.openmicroscopy.org.uk/horde/chora/browse.php?f=OME%2Fsrc%2Fxml%2FREADME.Classifier">OME/src/xml/README.Classifier</a> then
type this at the command line:<br>
<pre>
	ome execute -c -a $chain_id -d $dataset_id --inputs $input_string
</pre></p><p>
END_INSTRS
#--inputs $fi_id:$mex_id_list
		# This is not possible until apache is set up to run matlab
		# It starts the chain going, but doesn't redirect the page until the
		# chain is finished.
		# my $task = OME::Tasks::NotificationManager->
		#   new('Executing '.$trainer_chain->name, 1);
		# $task->setPID($$);
		# OME::Fork->doLater( sub {
		# 	OME::Analysis::Engine->
		# 		executeChain( $trainer_chain, $dataset, $user_inputs, $task );
		# });
		# return( 'REDIRECT', 'serve.pl?Page=OME::Web::TaskProgress');
	}

	# We aren't running the classifier, so finish making the page.
	# actually make the dropdown list
	my @classifier_list = $factory->findObjects ('@BayesNetClassifier', __order => 'id');
	my $classifier_dropdown = (
		@classifier_list ?
		$self->Renderer()->renderArray( \@classifier_list, 'dropdown_select', { 
			'field_name'       => 'classifier_id',
			'submit_on_change' => 1,
			'default_value'    => ( $classifier ? $classifier->id : '' )
		} ) :
		'(No Classifiers found)'
	);
	
	# Load & populate the template
	my $tmpl_dir = $self->actionTemplateDir();
	my $tmpl = HTML::Template->new( 
		filename => "RunClassifier.tmpl",
		path     => $tmpl_dir, 
		case_sensitive => 1 );
	$tmpl->param(
		exp_dataset         => ($dataset ? $self->Renderer()->render( $dataset, 'ref' ) : '' ),
		exp_dataset_id      => ($dataset ? $dataset->id : ''),
		classifier_select   => $classifier_dropdown,
		classifier          => ( $classifier ? $self->Renderer()->render( $classifier, 'ref' ) : '' ),
	);
	my $html = 
		$q->startform().
		$q->hidden({-name => 'action'}).
		$tmpl->output().
		$q->endform();

	return ('HTML',$html);
	
}

1;
