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
    my $debug;
    my @categoryGroups;
    my $html;

	# Load the correct template
	my $tmpl_dir = $self->actionTemplateDir();
	my $which_tmpl = $q->param( 'Template' );
	my $tmpl;
	
	if ($which_tmpl) {
		my $tmplAttr = $factory->loadObject( '@AnnotationTemplate', $which_tmpl )
			or die "Could not load AnnotationTemplate with id $which_tmpl";
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
		
		# DNFW, this naming convention is tied to CG_Annotator.tmpl
		my @category_names = map( "FromCG".$_->id, @categoryGroups );
		my @add_category_name = map( "CategoryAddTo".$_->id, @categoryGroups );
		
		# Classify an image if they click Save & Next
		if ($q->param( 'SaveAndNext' )) {
			# for each incoming category
			foreach my $categoryAnnotationFieldName ( @category_names ) {
				# Get incoming category ids from CGI parameters
				my $categoryID = $q->param( $categoryAnnotationFieldName );
				# Load category object?
				if( $categoryID && $categoryID ne '' ) {
					my $category = $factory->loadObject( '@Category', $categoryID )
						or die "Couldn't load Category (id=$categoryID)";
					# Create new 'Classification' attributes on image
					my $currentImage = $factory->loadObject( 'OME::Image', ($q->param( 'currentImageID' )));
					OME::Tasks::CategoryManager->classifyImage($currentImage, $category);
				}
			}
		}
			
		# If the user clicks "Add" then add the category in the text box to the appropriate CG
		if ( $q->param( 'AddToCG' ) ) {
			# Add a category
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
		
		# Render each Category Group and associated Category List
		my @cg_loop_data;
		my $use_cg_loop = grep{ $_ eq 'cg.loop'} @parameter_names;
		my $cntr = 1;
		foreach my $cg (@categoryGroups) {
			my $label = "FromCG".$cg->id;
			my $categoryID = $q->param( $label );
			
			# what we'd like to have sometime
			#$self->Renderer()->populateTemplate( 'template_name', { "cg_".$cntr => $cg } );
			
			my %cg_data;
			my @categoryList = $cg->CategoryList;
			if( $use_cg_loop ) {
				$cg_data{ 'cg.Name' } = $self->Renderer()->render( $cg, 'ref');
				$cg_data{ "cg.id" } = $cg->id();
				$cg_data{ "cg.rendered_cats" } = $self->Renderer()->renderArray( 
					\@categoryList, 
					'list_of_options', 
					{ default_value => $categoryID, type => '@Category' }
				);
				push( @cg_loop_data, \%cg_data );
			} else {
				$tmpl_data{ 'cg['.$cntr.'].Name' } = $self->Renderer()->render( $cg, 'ref');
				$tmpl_data{ "cg[".$cntr."].id" } = $cg->id();
				$tmpl_data{ "cg[".$cntr."].rendered_cats" } = $self->Renderer()->renderArray( 
					\@categoryList, 
					'list_of_options', 
					{ default_value => $categoryID, type => '@Category' }
				);
			}
			$cntr++;
		}
		$tmpl_data{ 'cg.loop' } = \@cg_loop_data
			if( $use_cg_loop );
		
		# Get the list of ID's that are left to annotate
		my $concatenated_image_ids = $q->param( 'images_to_annotate' );
		
		# sort by name
		my @unsorted_image_ids = split( /,/, $concatenated_image_ids );
		my @image_ids = sort( { ($factory->findObject( 'OME::Image', id => $a))->name cmp ($factory->findObject( 'OME::Image', id => $b))->name } @unsorted_image_ids );
		my @image_thumbs;
		my $currentImageID;
		
		# if no image is displayed, the ID you need is in the array
		if ($q->param( 'currentImageID' ) eq '') { $currentImageID = shift(@image_ids); }
		else { $currentImageID = $q->param( 'currentImageID' ); }
	
		my $image = $factory->loadObject( 'OME::Image', $currentImageID);
		
		# If they want to annotate this image, get the next ID and load that image
		if ($q->param( 'SaveAndNext' )) {
			$currentImageID = shift(@image_ids);
			$image = $factory->loadObject( 'OME::Image', $currentImageID);
		}
		$tmpl_data{ 'image_large' } = $self->Renderer()->render( $image, 'large');
		
		# set the ID of the current image on display
		$tmpl_data{ 'current_image_id' } = $currentImageID;
		
		# Update the list of images left to annotate
		foreach my $image_id ( @image_ids ) {
			push( @image_thumbs, $factory->loadObject( 'OME::Image', $image_id ) );
		}
		
		$tmpl_data{ 'image_thumbs' } = $self->Renderer()->renderArray( \@image_thumbs, 'bare_ref_mass', { type => 'OME::Image' });
		$tmpl_data{ 'image_id_list' } = join( ',', @image_ids); # list of ID's to annotate
		
		# populate the template
		$tmpl->param( %tmpl_data );

		$html =
			$debug.
			$q->startform().
			$tmpl->output().
			$q->hidden( -name => 'Template' ).
			$q->endform();

	}
	else {
		# render the dropdown list of available templates, and if they select
		# one, refresh the page with that param in the URL
		my @templates = $factory->findObjects('@AnnotationTemplate', { ObjectType =>  '@CategoryGroup', __order => 'Name' });
		my $popup;
		my $button;
		my $url = $self->pageURL('OME::Web::CG_ConstructTemplate');
		my $directions = "<i>There are no templates in the database. <a href=\"$url\">Create a template</a><br><br>
							 If you already have a template in your Actions/Annotator, Actions/Browse, or Actions/Display
							 directory,<br>from the command line, run 'ome templates update -u Actions'</i>";
							 
		if ( scalar(@templates) > 0 ) {
			$directions = "Select a template:<br>";
			$popup = $q->popup_menu(
								-name     => 'Template',
								'-values' =>  [ map( $_->id, @templates) ],
								-labels   =>  { map{ $_->id => $_->Name } @templates }
							);
			$button = $q->submit (
							-name => 'LoadTemplate',
							-value => 'Go'
						 );
		}
		
		$html =
		$debug.
		$q->startform().
		$directions.
		$popup.
		$button.
		$q->endform();
	}
	
	return ('HTML',$html);	
}

1;
