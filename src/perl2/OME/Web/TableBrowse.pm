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

my $BROWSE_PAGE='OME::Web::ImageAnnotationBrowser';

sub getPageTitle {
    return "OME: Browsing Mouse Images";
}

{
	my $menu_text = "Browse Mouse Images";
	sub getMenuText { return $menu_text }
}

sub getPageBody {
    my $self = shift;
    my $q =  $self->CGI();
    my $session = $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;

    my $sub = $q->param('submit');

    $tmpl_data{'Gene'} = $q->param('Gene') if (defined
					       $q->param('Gene'));

    # Gene and embryo Stage for rows and columns if not specified
    $q->param(-name=>'Template',-value=>'GeneProbeTable') unless $q->param('Template');
    $q->param(-name=>'Rows',-value=>'Gene') unless $q->param('Rows');
    $q->param(-name=>'Columns',-value=>'EmbryoStage') unless $q->param('Columns');
    
    my $table = new OME::Web::ImageAnnotationTable();

    my $output =
	$table->getTableDetails($self,'GeneProbeTable','OME::Web::TableBrowse');

    # and the form.
    my $html =
    $q->startform( { -name => 'primary' } );
    $html .= $output;
    $html .= $q->endform();

    return ('HTML',$html);	
}


sub getMenuBuilder {
    return undef;
}

sub getHeaderBuilder {
    return new OME::Web::TableBrowse::HeaderBuilder();
}


1;
