# OME/Web/TableBrowse.pm
#
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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#-------------------------------------------------------------------------------

package OME::Web::TableBrowse;

use strict;
use Carp 'cluck';
use vars qw($VERSION);

use base qw(OME::Web);
use OME::Web::ImageAnnotationBrowser;
use OME::Web::TableBrowse::HeaderBuilder;
use OME::Web::ImageAnnotationTable;
use OME::Web::TemplateManager;

sub getPageTitle {
    return "OME: Browsing Images in Table View";
}

{
	my $menu_text = "Browse Image Table";
	sub getMenuText { return $menu_text }
}

sub getPageBody {
    my $self = shift;
    my $q =  $self->CGI();
    my $session = $self->Session();
    my $factory = $session->Factory();

    # Find a template if not specified
    if ( not $q->param('Template') and $q->url_param('Template') ) {
    	$q->param(-name=>'Template',-value=> $q->url_param('Template'));
    	print STDERR "Got url param but not param\n";
    }
    if (not $q->param('Template')) {
    	my $template = $factory->findObject ('@BrowseTemplate',{
    		ImplementedBy => ref ($self)
    	});
		die "Could not find appropriate BrowseTemplate for OME::Web::TableBrowse" unless $template;
    	$q->param(-name=>'Template',-value=> $template->Name());
    }
    
    my $table = new OME::Web::ImageAnnotationTable();

    my $tmpl = OME::Web::TemplateManager->getBrowseTemplate($q->param('Template'));
	die "The template '".$q->param('Template')."' could not be loaded" unless $tmpl;

    my $output =
	$table->getTableDetails($self,$tmpl,'OME::Web::TableBrowse');

    # and the form.
    my $html =
    $q->startform( { -name => 'primary' } );
    $html .= $output;
    $html .= $q->endform();

    return ('HTML',$html);	
}

# These are turned off
sub getMenuBuilder {
    return undef;
}


1;
