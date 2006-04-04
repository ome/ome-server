# OME/Web/CG_Annotator.pm

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
# Written by:    Arpun Nagaraja <arpun@mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Web::CG_Annotator;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;
use OME::Tasks::ImageManager;

use base qw(OME::Web);

sub getPageTitle {
	return "OME: Annotate Images";
}

{
	my $menu_text = "Annotate Images";
	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift ;
	my $q = $self->CGI() ;
	my $session= $self->Session();
	my $factory = $session->Factory();
	my %tmpl_data;
	my @categoryGroups;
	my $html;

	# Load the correct template and make sure the URL still carries the template
	# name.
	my $tmpl_dir = $self->rootTemplateDir( 'custom' );
	my $which_tmpl = $q->url_param( 'Template' );
	my $referer = $q->referer();
	my $url = $self->pageURL('OME::Web::CG_Annotator');
	if ($referer && $referer =~ m/Template=(.+)$/ && !($which_tmpl)) {
		$which_tmpl = $1;
		$which_tmpl =~ s/%20/ /;
		return ('REDIRECT', $self->redirect($url.'&Template='.$which_tmpl));
	}
	my $tmpl;
	
	if ($which_tmpl) {
	        $which_tmpl =~ s/%20/ /;
		my $tmplAttr = $factory->findObject( '@AnnotationTemplate', Name => $which_tmpl )
						or die "Could not find AnnotationTemplate with name $which_tmpl";
		$tmpl = HTML::Template->new( filename => $tmplAttr->Template(),
										path => $tmpl_dir,
										case_sensitive => 1 );
		
		# Load the requested category groups
		my @parameter_names = $tmpl->param();
		my @found_params = grep( m/\.load/, @parameter_names );
		my $request = $found_params[0];
		my $concatenated_request;
		my @ids;
		if( $request =~ m/\/id-\[((\d+,)*\d*)\]/ ) {
				@ids = split(/,/, $1);
		} else { 
				die "couldn't parse $request";
		}
		
		foreach my $id (@ids) {
			my $cg = $factory->loadObject( '@CategoryGroup', $id )
				or die "couldn't load CategoryGroup id: $id";
			push (@categoryGroups, $cg);
		}
		
		# DNFW, this naming convention is tied to Annotator template
		my @category_names = map( "FromCG".$_->id, @categoryGroups );
		my @add_category_name = map( "CategoryAddTo".$_->id, @categoryGroups );
		
		# Classify an image if they click Save & Next
		if ($q->param( 'SaveAndNext' )) {
			my $currentImage = $factory->loadObject( 'OME::Image', $q->param( 'currentImageID' ));
			# for each incoming category
			foreach my $categoryAnnotationFieldName ( @category_names ) {
				# Get incoming category ids from CGI parameters
				my $categoryID = $q->param( $categoryAnnotationFieldName );
				# Load category object?
				if( $categoryID && $categoryID ne '' ) {
					my $category = $factory->loadObject( '@Category', $categoryID )
						or die "Couldn't load Category (id=$categoryID)";
					# Create new 'Classification' attributes on image
					OME::Tasks::CategoryManager->classifyImage($currentImage, $category);
				}
			}
			# Save image comments as a text annotation
			if( $q->param( 'comments' ) ) {
				my $currentAnnotation = OME::Tasks::ImageManager->
					getCurrentAnnotation( $currentImage );
				if( (not defined $currentAnnotation ) ||
				    ( $currentAnnotation->Content ne $q->param( 'comments' ) ) 
				  ) {
					OME::Tasks::ImageManager->writeAnnotation(
						$currentImage, { Content => $q->param( 'comments' ) }
					);
				}
			}
		}
			
		# If the user clicks "Add" then add the category in the text box to the appropriate CG
		if ( $q->param( 'AddToCG' ) ) {
			# for each category group
			foreach my $categoryGroupName ( @add_category_name ) {
				my %data_hash;
				my $categoryToAdd = $q->param( $categoryGroupName );
				$categoryGroupName =~ m/CategoryAddTo(\d+)/;
				my $categoryGroupID = $1; # Get the ID of the CategoryGroup to which to add this Category
				
				%data_hash = ( 'Name' => $categoryToAdd, 
							 'Description' => undef,
							 'CategoryGroup' => $categoryGroupID
				);
				
				if ($categoryToAdd && $categoryToAdd ne '') {
					OME::Tasks::AnnotationManager->annotateGlobal('Category', \%data_hash);
				}
			}
		}
		# commit the DB transaction
		$session->commitTransaction();
		
		# Get the list of ID's that are left to annotate
		my $concatenated_image_ids = $q->param( 'images_to_annotate' );
		
		# sort by name
		my @unsorted_image_ids;
                @unsorted_image_ids = split( /,/, $concatenated_image_ids )
                              if ($concatenated_image_ids);
		my @image_ids = sort( { ($factory->loadObject( 'OME::Image', $a))->name cmp ($factory->loadObject( 'OME::Image', $b))->name } @unsorted_image_ids );
		my @image_thumbs;
		my $currentImageID;
		
		# if no image is displayed, the ID you need is in the array
		if (!$q->param('currentImageID') ||
		    $q->param( 'currentImageID' ) eq '')  {
		    $currentImageID = shift(@image_ids); 
		}
		else { $currentImageID = $q->param( 'currentImageID' ); }
	
		my $image = $factory->loadObject( 'OME::Image', $currentImageID);
		
		# If they want to annotate this image, get the next ID and load that image
		if ($q->param( 'SaveAndNext' )) {
			$currentImageID = shift(@image_ids);
			$image = $factory->loadObject( 'OME::Image', $currentImageID);
		}
		my $field_requests = $self->Renderer()->parse_tmpl_fields( [ $tmpl->param() ] );
		my $field = 'current_image';
		if( $field_requests->{ $field } ) {
			foreach my $request ( @{ $field_requests->{ $field } } ) {
				my $request_string = $request->{ 'request_string' };
				my $render_mode = ( $request->{ render } or 'ref' );
				$tmpl_data{ $request_string } = $self->Renderer()->render( $image, $render_mode );
			}
		} else {
			#/render-large
			$tmpl_data{ 'image_large' } = $self->Renderer()->render( $image, 'large');
		}
		
		# set the ID of the current image on display
		$tmpl_data{ 'current_image_id' } = $currentImageID;
		
		# Update the list of images left to annotate
		foreach my $image_id ( @image_ids ) {
			push( @image_thumbs, $factory->loadObject( 'OME::Image', $image_id ) );
		}
		
		$tmpl_data{ 'image_thumbs' } = $self->Renderer()->renderArray( \@image_thumbs, 'ref_mass', { type => 'OME::Image' });
		$tmpl_data{ 'image_id_list' } = join( ',', @image_ids); # list of ID's to annotate
		
		# Render each Category Group and associated Category List
		my @cg_loop_data;
		my $use_cg_loop = grep{ $_ eq 'cg.loop'} @parameter_names;
		my $cntr = 1;
		foreach my $cg (@categoryGroups) {
			my $label = "FromCG".$cg->id;
			my $categoryID = $q->param( $label );
			my %cg_data;
			my @categoryList = $cg->CategoryList;
			my $currentImage = $factory->loadObject( 'OME::Image', $currentImageID);
			my $classification = OME::Tasks::CategoryManager->getImageClassification($currentImage, $cg);
			my $categoryName = $classification->Category->Name if ($classification);
			
			# If the template is using a loop, the variable names will be different
			if( $use_cg_loop ) {
				$cg_data{ 'cg.Name' } = $self->Renderer()->render( $cg, 'ref');
				$cg_data{ "cg.id" } = $cg->id();
				$cg_data{ "cg.cat/render-list_of_options" } = $self->Renderer()->renderArray( 
					\@categoryList, 
					'list_of_options', 
					{ default_value => $categoryID, type => '@Category' }
				);
				
				# If there's actually an image there.
				if ($currentImage) {
				$cg_data{ 'cg.classification' } = "Classified as <b>$categoryName</b>"
					if $categoryName;
				$cg_data{ 'cg.classification' } = "<i>Unclassified</i>"
					unless $categoryName;
				}
				push( @cg_loop_data, \%cg_data );
			} else {
				# The greps are used to see if the user actually wants
				# the variables in question. It is not used in the loop
				# because the variables are not in the list of parameters.
				# FIXME!
				$tmpl_data{ 'cg['.$cntr.'].Name' } = $self->Renderer()->render( $cg, 'ref')
					if ( grep{ $_ eq 'cg['.$cntr.'].Name' } @parameter_names );
					
				$tmpl_data{ "cg[".$cntr."].id" } = $cg->id()
					if ( grep{ $_ eq 'cg['.$cntr.'].id' } @parameter_names );
					
				$tmpl_data{ 'cg['.$cntr.'].cat/render-list_of_options' } = $self->Renderer()->renderArray( 
					\@categoryList, 
					'list_of_options', 
					{ default_value => $categoryID, type => '@Category' }
				) if ( grep{ $_ eq 'cg['.$cntr.'].cat/render-list_of_options' } @parameter_names );
				
				if (( grep{ $_ eq 'cg['.$cntr.'].classification' } @parameter_names ) && $currentImage) {
					$tmpl_data{ 'cg['.$cntr.'].classification' } = "Classified as <b>$categoryName</b>"
						if $categoryName;
					$tmpl_data{ 'cg['.$cntr.'].classification' } = "<i>Unclassified</i>"
						unless $categoryName;
				}
			}
			$cntr++;
		}
		
		$tmpl_data{ 'cg.loop' } = \@cg_loop_data
			if( $use_cg_loop );
		
		# populate the template
		$tmpl->param( %tmpl_data );
	}
	
	# render the dropdown list of available templates
	
	my @templates = $factory->findObjects('@AnnotationTemplate', { ObjectType =>  '@CategoryGroup', __order => 'Name' });
	my $popup="";
	my $button="";
	my $createURL = $self->pageURL('OME::Web::CG_ConstructTemplate');
	my $current = $q->url_param( 'Template' );
	my $directions = "<i>There are no templates in the database. <a href=\"$createURL\">Create a template</a><br><br>
						 If you already have templates in your Browse, Actions/Annotator, or Display/One/OME/Image
						 directory,<br>from the command line, run 'ome templates update -u all'</i>";
						 
	if ( scalar(@templates) > 0 ) {
		$directions = "Current Template: ";
		$popup = $q->popup_menu(
							-name     => 'Templates',
							-values =>  [ map( $_->Name, @templates) ],
							-labels   =>  { map{ $_->Name => $_->Name } @templates },
							-default  => $current
						);
		$button = $q->submit (
						-name => 'LoadTemplate',
						-value => 'Load'
					 );
					 
		return ('REDIRECT', $self->redirect($url.'&Template='.$q->param( 'Templates' ))) if ($q->param( 'LoadTemplate' ));
	}

	$html =
		$q->startform( { -name => 'primary' } ).
		$directions.
		$popup.
		$button;
	
	$html .= $tmpl->output() if ($tmpl);
	$html .= $q->endform();
	
	return ('HTML',$html);	
}

1;
