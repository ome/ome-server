# OME/Web/MouseSearch.pm

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


package OME::Web::MouseSearch;

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
    my $url = "http://lgsun.grc.nia.nih.gov/geneindex5/";
    my $debug;
	
	my @categoryGroups = $factory->findObjects ('@CategoryGroup', __order => 'id');
		
	my @image_thumbs;
	my %final_image_ids;
	my $firstCG = 1;
	my $cgCounter = 1;
	
	# This code is for filtering displayed thumbs and should be standard for all CG display templates
	# I don't like the way this works: it seems messy and redundant.
	# Perhaps there's a better way to do this, but I can't figure it out.
	
	# Go through filtering for every CG
	foreach my $cg (@categoryGroups) {
		my %temp_image_ids;
		my $label = "FromCG".$cg->id;
		my $categoryID = $q->param( $label );
		
		my @categoryList = $cg->CategoryList;
		$tmpl_data{ 'rendered_cat_'.$cgCounter } = $self->Renderer()->renderArray( 
			\@categoryList, 
			'list_of_options', 
			{ default_value => $categoryID, type => '@Category' }
		);
		$tmpl_data{ 'cg_name_'.$cgCounter } = $self->Renderer()->render( $cg, 'ref');
		$tmpl_data{ 'cg_id_'.$cgCounter } = $cg->id;
		
		my $size = 8;
		if ($cgCounter == 1) { $size = 30; }
		$tmpl_data{ 'size_'.$cgCounter } = $size;
		
		# If you're on GeneSymbols - not appropriate for general search, but will do for now
		if ($categoryID && $cgCounter == 1) {
			my $categoryObj = $factory->findObject( '@Category', { id => $categoryID } ) if $categoryID;
			my $categoryName = $categoryObj->Name if $categoryObj;
			$tmpl_data{ 'GENE' } = $categoryName;
			$url .= "bin/giU.cgi?search_term=$categoryName";
		}
		
		$cgCounter++;
		
		# If the user selects a Category...
		if ( $q->param( 'GetThumbs' ) ) {
			my @image_hashes = OME::Tasks::CategoryManager->getImagesInCategory($categoryID);
			
			foreach my $hash (@image_hashes) {
				my $id = $hash->id;
				$temp_image_ids{ $id } = 1;
				
				# if this is the first cg being processed, %final_image_ids will be empty,
				# so populate it
				if ($firstCG == 1) { $final_image_ids{ $id } = 1; }
			}
			
			# It's not the first cg anymore if %final_image_ids has entries
			$firstCG = 0 if (scalar(keys(%final_image_ids)) > 0);
			
			# if an ID in %final_image_ids equals an ID in %temp_image_ids, then keep it.
			# otherwise, take that ID out of %final_image_ids
			foreach my $id ( keys %final_image_ids ) {
				if (scalar(keys(%temp_image_ids)) > 0) {
						delete $final_image_ids{ $id } unless ($temp_image_ids{ $id });
				} 
			}
		}
	}
	my $num = scalar(keys(%final_image_ids));
	# $debug .= "There are $num images that meet the criteria.<br>";
	foreach my $id ( keys(%final_image_ids) ) {
		push( @image_thumbs, $factory->loadObject( 'OME::Image', $id ) );
	}
	
	$tmpl_data{ 'image_thumbs' } = $self->Renderer()->renderArray( \@image_thumbs, 'bare_ref_mass', { type => 'OME::Image' });
	$tmpl_data{ 'MGI_URL' } = $url;
	
	# Load & populate the template
	my $tmpl_dir = $self->actionTemplateDir();
	my $tmpl = HTML::Template->new( filename => "MouseSearch.tmpl",
									path => $tmpl_dir,
	                                case_sensitive => 1 );
	$tmpl->param( %tmpl_data );

	my $html =
		$debug.
		$q->startform().
		$tmpl->output().
		$q->endform();

	return ('HTML',$html);
	
}

1;
