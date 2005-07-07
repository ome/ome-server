# OME/Web/MouseDisplay.pm

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


package OME::Web::MouseDisplay;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;

use base qw(OME::Web);

sub getPageTitle {
	return "OME: Display an Image";
}

{
	my $menu_text = "Display an Image";
	sub getMenuText { return $menu_text }
}

# ADD ERROR CHECKING
sub getPageBody {
	my $self = shift ;
	my $q = $self->CGI() ;
	my $session= $self->Session();
    my $factory = $session->Factory();
    my $dataset = $session->dataset();
    my %tmpl_data;
    my $debug;
	
	my $id = $q->param( 'ID' );
	my $image = $factory->loadObject( 'OME::Image', $id) if ($id);
	
	# Find category groups
	my @cg_list = $factory->findObjects ('@CategoryGroup', __order => 'id');
	
	# Render each Category Group and associated Category List
	my $cgCounter = 1;
	
	foreach my $cg (@cg_list) {
		if ($image) {
			my $classifi = OME::Tasks::CategoryManager->getImageClassification($image, $cg);
			my @categoryList;
			
			if (ref($classifi) eq 'ARRAY') {
				foreach my $classification (@$classifi) {
					my $categoryID = %$classification->{ __fields }->{classification}->{category};
					my $category = $factory->loadObject( '@Category', $categoryID );
					push ( @categoryList, $category );
				}
			}
			else {
				my $categoryID = %$classifi->{ __fields }->{classification}->{category};
				my $category = $factory->loadObject( '@Category', $categoryID );
				push ( @categoryList, $category );
			}
			
			$tmpl_data{ 'cg_name_'.$cgCounter } = $self->Renderer()->render( $cg, 'ref');
			$tmpl_data{ 'rendered_cat_'.$cgCounter } = $self->Renderer()->renderArray( 
				\@categoryList, 'ref_mass', { type => '@Category' }
			);
		}
		$cgCounter++;
	}
	
	
	$tmpl_data{ 'image_large' } = $self->Renderer()->render( $image, 'large');
		
	# Load & populate the template
	my $tmpl_dir = $self->actionTemplateDir();
	my $tmpl = HTML::Template->new( filename => "MouseDisplay.tmpl",
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
