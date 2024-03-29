# OME/Web/CG_Search.pm

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


package OME::Web::CG_Search;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;

use base qw(OME::Web);

sub getPageTitle {
	return "OME: View Images";
}

{
	my $menu_text = "View Images";
	sub getMenuText { return $menu_text }
}

sub getTemplate {

    my $self=shift;
    
    my $which_tmpl =  $self->getTemplateName('OME::Web::CG_Search');

    my $tmpl =
	OME::Web::TemplateManager->getBrowseTemplate($which_tmpl);

    return $tmpl;


}

=head2 getLocation
=cut

sub getLocation {
	my $self = shift;
	my $template = OME::Web::TemplateManager->getLocationTemplate('CG_Search.tmpl');
	return $template->output();
}


# ADD ERROR CHECKING
sub getPageBody {
	my $self = shift ;
	my $tmpl  = shift;
	my $q = $self->CGI() ;
	my $session= $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;
    my @categoryGroups;
    my $html;

	# if we've found a template.
	if ($tmpl ne $OME::Web::TemplateManager::NO_TEMPLATE) {	
		
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
			
		my @image_thumbs;
		my %final_image_ids;
		my $firstCG = 1;
		
		# This code is for filtering displayed thumbs
		# I don't like the way this works: it seems messy and redundant.
		# Perhaps there's a better way to do this, but I can't figure it out.
		
		# Go through filtering for every CG
		my @cg_loop_data;
		my $use_cg_loop = grep{ $_ eq 'cg.loop'} @parameter_names;
		my $cntr = 1;
		foreach my $cg (@categoryGroups) {
			my %temp_image_ids;
			my $label = "FromCG".$cg->id;
			my $categoryID = $q->param( $label );
			# Allow parameter specification as CG_Name=Category_Name
			# If these parameters were found, translate to id and turn on search
			if( $q->param( $cg->Name ) ) {
				my $categoryName = $q->param( $cg->Name );
			    die "More than one category named $categoryID"
			    	if( $factory->countObjects( 
						'@Category', 
						CategoryGroup => $cg,
						Name          => $categoryName
					) > 1 );
				my $category = $factory->findObject( 
					'@Category', 
					CategoryGroup => $cg,
					Name          => $categoryName
				) or die "Couldn't load a Category for CG '".$cg->Name."' given parameter $categoryName.";
				$categoryID = $category->id();
				$q->param( $label, $categoryID );
				$q->param( 'GetThumbs', 1 );
			}
			
			my @categoryList = $cg->CategoryList;
			# First, render the various lists and whatnot
			my %cg_data;
			if( $use_cg_loop ) {
				$cg_data{ 'cg.Name' } = $self->Renderer()->render( $cg, 'ref');
				$cg_data{ "cg.id" } = $cg->id();
				$cg_data{ "cg.cat/render-list_of_options" } = $self->Renderer()->renderArray( 
					\@categoryList, 
					'list_of_options', 
					{ default_value => $categoryID, type => '@Category' }
				);
				push( @cg_loop_data, \%cg_data );
			} else {
				$tmpl_data{ 'cg['.$cntr.'].cat/render-list_of_options' } = $self->Renderer()->renderArray( 
					\@categoryList, 
					'list_of_options', 
					{ default_value => $categoryID, type => '@Category' }
				) if ( grep{ $_ eq 'cg['.$cntr.'].cat/render-list_of_options' } @parameter_names );
				
				$tmpl_data{ 'cg['.$cntr.'].Name' } = $self->Renderer()->render( $cg, 'ref')
					if ( grep{ $_ eq 'cg['.$cntr.'].Name' } @parameter_names );
					
				$tmpl_data{ 'cg['.$cntr.'].id' } = $cg->id
					if ( grep{ $_ eq 'cg['.$cntr.'].id' } @parameter_names );
			}
			
			# Now do filtering
			# If the user selects a Category...
			if ( $q->param( 'GetThumbs' ) ) {
				my @image_hashes = OME::Tasks::CategoryManager->getImagesInCategory($categoryID);
			
				foreach my $hash (@image_hashes) {
					my $id = $hash->id;
					$temp_image_ids{ $id } = 1;
					
					# if this is the first cg being processed, %final_image_ids will be empty,
					# so populate it
					
					$final_image_ids{ $id } = 1 if ($firstCG == 1);
				}
				
				$firstCG = 0 if (scalar(keys(%final_image_ids)) > 0);
				
				# if an ID in %final_image_ids equals an ID in %temp_image_ids, then keep it.
				# otherwise, take that ID out of %final_image_ids
				foreach my $id ( keys %final_image_ids ) {
					if (scalar(keys(%temp_image_ids)) > 0 || (scalar(keys(%temp_image_ids)) == 0 && $categoryID)) {
							delete $final_image_ids{ $id } unless ($temp_image_ids{ $id });
					} 
				}
			}
			$cntr++;
		}
		$tmpl_data{ 'cg.loop' } = \@cg_loop_data if( $use_cg_loop );
		
		foreach my $id ( keys(%final_image_ids) ) {
			push( @image_thumbs, $factory->loadObject( 'OME::Image', $id ) );
		}
		
		$tmpl_data{ 'image_thumbs' } = $self->Renderer()->renderArray( \@image_thumbs, 'ref_cg_display_mass', { type => 'OME::Image' });
	
		$tmpl->param( %tmpl_data );
	}
	
	my $templates =
	    OME::Web::TemplateManager->getCategoryGroupBrowseTemplates();

	my $popup;
	my $button;
	my $createURL = $self->pageURL('OME::Web::CG_ConstructTemplate');
	my $directions = "<i>There are no templates in the database. <a href=\"$createURL\">Create a template</a><br><br>
						 If you already have templates in your Browse, Actions/Annotator, or Display/One/OME/Image
						 directory,<br>from the command line, run 'ome templates update -u all'</i>";

	if ( scalar(@$templates) > 0 ) {
		$directions = "Current template:";
		$popup = $q->popup_menu(
							-name     => 'Templates',
							'-values' =>  [ map( $_->Name, @$templates) ],
							-labels   =>  { map{ $_->Name => $_->Name } @$templates },
							-default  => $q->url_param('Template'),
							#-onChange => return ('REDIRECT', $self->redirect($url.'&Template='.$q->param( 'Templates' )))
						);
		$button = $q->submit (
						-name => 'LoadTemplate',
						-value => 'Load'
					 );
		my $url = $self->pageURL('OME::Web::CG_Search');
		return ('REDIRECT', $self->redirect($url.'&Template='.$q->param( 'Templates' ))) if ($q->param( 'LoadTemplate' ));
	}
	
	$html =
		$q->startform( { -name => 'primary' } ).
		$directions.
		$popup.
		$button;
	
	$html .= $tmpl->output() if ($tmpl &&
		     $tmpl ne $OME::Web::TemplateManager::NO_TEMPLATE);
	$html .= $q->endform();

	return ('HTML',$html);
	
}

1;
