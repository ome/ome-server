# OME/Web/TrainClassifier.pm

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


package OME::Web::TrainClassifier;

use strict;
use vars qw($VERSION);
use Log::Agent;
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Analysis::Engine;
use OME::Tasks::AnnotationManager;
use OME::Tasks::ChainManager;
use OME::Tasks::CategoryManager;

use base qw(OME::Web);

sub getPageTitle {
	return "OME: Train a Classifier" ;

}

{
	my $menu_text = "Train Classifier";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my	$self = shift ;
	my 	$q = $self->CGI() ;
	my	$session=$self->Session();
    my  $factory = $session->Factory();

	# get parameters
	my $dataset;
	if( $q->param( 'training_dataset_id' ) ) {
		$dataset = $factory->loadObject( 'OME::Dataset', $q->param( 'training_dataset_id' ) )
			or die "Couldn't load dataset with id '".$q->param( 'training_dataset_id' )."'";
	} else {
		$dataset = $session->dataset();
	}
	my $trainer_chain = $factory->findObject( 'OME::AnalysisChain', name => 'Train a Classifier' );

	# load the selected category group. 
	my $cg;
	if( $q->param( 'category_group_id' ) ) {
		$cg = $factory->loadObject( '@CategoryGroup', $q->param( 'category_group_id' ) )
			or die "Couldn't load CategoryGroup id='".$q->param( 'category_group_id' )."'";
	}

	# actually make the dropdown list
	my @cg_list = $factory->findObjects ('@CategoryGroup', { __order => 'Name' });
	my $categoriesGroup_dropdown = (
		@cg_list ?
		$q->popup_menu(
			-name     => 'category_group_id',
			'-values' => ['', map( $_->id, @cg_list) ],
			-default  => ( $cg ? $cg->id : '' ),
			-override => 1,
			-labels   => { 
				'' => "(no selection)",
				( map { $_->id => $_->Name } @cg_list )
			},
			-onChange => "javascript: document.forms[0].submit();"
		) : 
		'(No CategoryGroups found)'
	);
	
	# Count the unclassified images.
	my $num_images_unclassified;
	$num_images_unclassified = OME::Tasks::CategoryManager->
		countUnclassifiedImagesInDataset( $cg, $dataset )
		if( $dataset && $cg );

	# Load & populate the template
	my $tmpl_dir = $self->Session()->Configuration()->template_dir();
	my $tmpl_path = $tmpl_dir."/TrainClassifier.tmpl";
	my $tmpl = HTML::Template->new( filename => $tmpl_path,
	                                case_sensitive => 1 );
	$tmpl->param(
#		trainer_chains          => '',
		training_dataset        => ($dataset ? $self->Renderer()->render( $dataset, 'ref' ) : '' ),
		training_dataset_id     => ($dataset ? $dataset->id : ''),
		category_group_select   => $categoriesGroup_dropdown,
		category_group          => ( $cg ? $self->Renderer()->render( $cg, 'ref' ) : '' ),
		category_group_id       => ( $cg ? $cg->id : '' ),
		num_images_unclassified => $num_images_unclassified,
	);
	my $html = 
		$q->startform().
		$tmpl->output().
		$q->endform();

	return ('HTML',$html);
	
}

1;
