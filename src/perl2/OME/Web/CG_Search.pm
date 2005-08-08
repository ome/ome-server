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
    # my $url = "http://lgsun.grc.nia.nih.gov/geneindex5/";
    my $debug;
    my @categoryGroups;
    my $html;
	
	# Load the correct template
	my $tmpl_dir = $self->actionTemplateDir();
	my $which_tmpl = $q->param( 'Template' );
	my $tmpl;
	
	if ($which_tmpl) {
		my $tmplAttr = $factory->loadObject( '@BrowseTemplate', $which_tmpl )
						or die "Could not load BrowseTemplate with id $which_tmpl";
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
		
		# This code is for filtering displayed thumbs and should be standard for all CG display templates
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
			my %cg_data;
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
				$tmpl_data{ 'cg['.$cntr.'].rendered_cats' } = $self->Renderer()->renderArray( 
					\@categoryList, 
					'list_of_options', 
					{ default_value => $categoryID, type => '@Category' }
				);
				$tmpl_data{ 'cg['.$cntr.'].Name' } = $self->Renderer()->render( $cg, 'ref');
				$tmpl_data{ 'cg['.$cntr.'].id' } = $cg->id;
			}		
	# 		if ($categoryID && $cgCounter == 1) {
	# 			my $categoryObj = $factory->findObject( '@Category', { id => $categoryID } ) if $categoryID;
	# 			my $categoryName = $categoryObj->Name if $categoryObj;
	# 			$tmpl_data{ 'GENE' } = $categoryName;
	# 			# $url .= "bin/giU.cgi?search_term=$categoryName";
	# 		}
					
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
		#my $num = scalar(keys(%final_image_ids));
		#$debug .= "There are $num images that meet the criteria.<br>";
		foreach my $id ( keys(%final_image_ids) ) {
			push( @image_thumbs, $factory->loadObject( 'OME::Image', $id ) );
		}
		
		$tmpl_data{ 'image_thumbs' } = $self->Renderer()->renderArray( \@image_thumbs, 'ref_cg_display_mass', { type => 'OME::Image' });
	
		$tmpl->param( %tmpl_data );
	}
	
	my @templates = $factory->findObjects('@BrowseTemplate', { ObjectType =>  '@CategoryGroup', __order => 'Name' });
	my $popup;
	my $button;
	my $url = $self->pageURL('OME::Web::CG_ConstructTemplate');
	my $directions = "<i>There are no templates in the database. <a href=\"$url\">Create a template</a><br><br>
						 If you already have a template in your Actions/Annotator, Actions/Browse, or Actions/Display
						 directory,<br>from the command line, run 'ome templates update -u Actions'</i>";

	if ( scalar(@templates) > 0 ) {
		$directions = "Current template:";
		$popup = $q->popup_menu(
							-name     => 'Template',
							'-values' =>  [ map( $_->id, @templates) ],
							-labels   =>  { map{ $_->id => $_->Name } @templates }
						);
		$button = $q->submit (
						-name => 'LoadTemplate',
						-value => 'Load'
					 );
	}
	
	$html =
		$debug.
		$q->startform().
		$directions.
		$popup.
		$button;
	
	$html .= $tmpl->output() if ($tmpl);
	$html .= $q->hidden( -name => 'Template' ).
			 $q->endform();

	return ('HTML',$html);
	
}

1;
