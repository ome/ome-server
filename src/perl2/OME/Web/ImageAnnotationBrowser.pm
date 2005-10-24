# OME/Web/ImageAnnotationBrowser.pm

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
#
#-------------------------------------------------------------------------------


package OME::Web::ImageAnnotationBrowser;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;

use base qw(OME::Web);

sub getPageTitle {
    return "OME: Image Annotation Browser";
}

{
    my $menu_text = "Image Annotation Browser";
    sub getMenuText { return $menu_text }
}

sub getPageBody {
    my $self = shift ;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;

    # Load the correct template and make sure the URL still carries the template
    # name.
    
    my $geneName = $q->param('GeneName');


    return $self->getGeneChooser() unless (defined $geneName);

    my $which_tmpl = $q->url_param('Template');
    my $referer = $q->referer();
    my $url = $self->pageURL('OME::Web::ImageAnnotationBrowser');
    if ($referer =~ m/Template=(.+)$/ && !($which_tmpl)) {
	$which_tmpl = $1;
	$which_tmpl =~ s/%20/ /;
	return ('REDIRECT', $self->redirect($url.'&Template='.$which_tmpl));
    }
    $which_tmpl =~ s/%20/ /;
    my $tmplData = $factory->findObject( '@BrowseTemplate', Name => $which_tmpl );
	
    my $tmpl = HTML::Template->new(filename => $tmplData->Template(),
				case_sensitive=>1);
    $tmpl_data{'GeneName'} = $geneName;
    $tmpl_data{'Template'} = $q->param('Template');
    $tmpl->param(%tmpl_data);

    my $gene = $factory->findObject('@Gene',  Name => $geneName);
    print STDERR "Gene id is " .$gene->ID() . "\n";
    my @pgmaps = $factory->findObjects('@ProbeGeneMap', {Gene =>$gene});
    print STDERR "Probes found : " . scalar(@pgmaps) . "\n";

    
    my @loop_data;

    while (@pgmaps) {
	my %row_data;	
	my $pgmap = shift @pgmaps;
	my $probe = $pgmap->Probe;
	$row_data{'Probe'} = $probe->Name;
	my $images = $self->getImageDisplay($probe);
	$row_data{'ProbeImages'} = $images;
	push(@loop_data,\%row_data);
    }
    $tmpl_data{'ProbeGenes'} = \@loop_data;

    $tmpl->param(%tmpl_data);
    my $html =
	$q->startform( { -name => 'primary' } );
    $html .= $tmpl->output() if ($tmpl);
    $html .= $q->endform();

    return ('HTML',$html);	
}

sub getImageDisplay {
    my $self = shift;
    my $probe = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my (@probeImageMaps) = 
	$factory->findObjects('@ImageProbe', {Probe=>$probe});
    my @images;

    while (@probeImageMaps) {
	my $map = shift @probeImageMaps;
	my %row_data;
	my $imageID = $map->image_id;
	my $image = $factory->loadObject("OME::Image",$imageID);
	push(@images,$image);
    }
    return $self->Renderer->renderArray(\@images,'bare_ref_mass',
					{ type => 'OME::Image'});
}

sub getGeneChooser {
    my $self=shift;
    my $q = $self->CGI();
    my $session= $self->Session();
    my $factory = $session->Factory();

    my @genes = $factory->findObjects('@Gene');
    my $url = $self->pageURL('OME::Web::ImageAnnotationBrowser');
    my $directions = "Choose a gene ";
    my $template = $q->param('Template');
    my $popup =  $q->popup_menu(
	-name => 'GeneChoice',
	-values => [ map($_->Name,@genes)]);

    if (defined $q->param('ChooseGene')) {
	my $full = $url.'&Template='.$template.'&GeneName='.
	    $q->param('GeneChoice');
	return('REDIRECT',$full) 
    }

    my $button = $q->submit(-name=>'ChooseGene',-value=>'Submit');
    my $html = $q->startform({ -name=>'primary'}) .
        $q->hidden(-name=>'Template',-default=>$template)  .
	$directions. $popup . $button. $q->endform();
    return ('HTML',$html);
}



1;
