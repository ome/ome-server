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

# ADD ERROR CHECKING
sub getPageBody {
	my $self = shift ;
	my $q = $self->CGI() ;
	my $session= $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;
    my $debug;
    my @categoryGroups;
    my $html;
	
	# Load the correct template and make sure the URL still carries the template
	# name.
	my $tmpl_dir = $self->actionTemplateDir( 'custom' );
	my $which_tmpl = $q->url_param( 'Template' );
	my $referer = $q->referer();
	my $url = $self->pageURL('OME::Web::CG_Search');
	if ($referer =~ m/Template=(.+)$/ && !($which_tmpl)) {
		$which_tmpl = $1;
		$which_tmpl =~ s/%20/ /;
		return ('REDIRECT', $self->redirect($url.'&Template='.$which_tmpl));
	}
	$which_tmpl =~ s/%20/ /;
	my $tmpl;
	
	if ($which_tmpl) {
		my $tmplAttr = $factory->findObject( '@BrowseTemplate', Name => $which_tmpl )
						or die "Could not find BrowseTemplate with name $which_tmpl";
		$tmpl = HTML::Template->new( filename => $tmplAttr->Template(),
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
	
	my @templates = $factory->findObjects('@BrowseTemplate', { ObjectType =>  '@CategoryGroup', __order => 'Name' });
	my $popup;
	my $button;
	my $url = $self->pageURL('OME::Web::CG_Search');
	my $createURL = $self->pageURL('OME::Web::CG_ConstructTemplate');
	my $directions = "<i>There are no templates in the database. <a href=\"$createURL\">Create a template</a><br><br>
						 If you already have templates in your Browse, Actions/Annotator, or Display/One/OME/Image
						 directory,<br>from the command line, run 'ome templates update -u all'</i>";

	if ( scalar(@templates) > 0 ) {
		$directions = "Current template:";
		$popup = $q->popup_menu(
							-name     => 'Templates',
							'-values' =>  [ map( $_->Name, @templates) ],
							-labels   =>  { map{ $_->Name => $_->Name } @templates },
							-default  => $which_tmpl,
							#-onChange => return ('REDIRECT', $self->redirect($url.'&Template='.$q->param( 'Templates' )))
						);
		$button = $q->submit (
						-name => 'LoadTemplate',
						-value => 'Load'
					 );
		return ('REDIRECT', $self->redirect($url.'&Template='.$q->param( 'Templates' ))) if ($q->param( 'LoadTemplate' ));
	}
	
	$html =
		$debug.
		$q->startform().
		$directions.
		$popup.
		$button;
	
	$html .= $tmpl->output() if ($tmpl);
	$html .= $q->endform();

	return ('HTML',$html);
	
}

1;
