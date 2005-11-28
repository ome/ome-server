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


=head1 getPageBody

Get the body for a page that displays images associated with given
    annotations. The annotations to be displayed will be given by the
    content of a Template file - as specified in the Template
    parameter of the requesting URL.

  
This template file will contain a TMPL_VAR of the name
    "Path.load/types-[....]". Inside the brackets, this variable name
    will include a list of types that will be used to define a path
    leading from some root to sets of images.

The list of types will alternate between objects and maps. An
    event-numbered list of types will always be included - starting with
    a root, followed by a map type, a subsequent type, etc., and
    ending with a map that leads to OME::Image. Since OME::Image is
    always the last element, it's presence in the list is implied.
    
Thus, for example, a list of the form 
    [@Gene,@ProbeGene,@Probe,@ImageProbe] will start with
    an instance of the Gene ST, use ProbeGene to find a set of
    probes, and ImageProbe to find a set of images for each probe.

It is assumed that this module is also called with a query parameter
    Root indicating the value (name) of the first ST in the list. Thus,
    Root=Mga will find all of the genes, probes and eventually images
    associated with the name "Mga". The value given for root is 
    assumed to be the Name of the instance of the first ST.

   
    
=cut


sub getPageBody {
    my $self = shift ;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;

    # Load the correct template and make sure the URL still carries
    # the template  name.
    # get template from url parameter, or referer

    my $which_tmpl = $q->url_param('Template');
    my $referer = $q->referer();
    my $url = $self->pageURL('OME::Web::ImageAnnotationBrowser');
    if ($referer && $referer =~ m/Template=(.+)$/ && !($which_tmpl)) {
	$which_tmpl = $1;
	$which_tmpl =~ s/%20/ /;
	return ('REDIRECT', $self->redirect($url.'&Template='.$which_tmpl));
    }
    $which_tmpl =~ s/%20/ /;

    # load the appropriate information for the named template.
    my $tmplData = 
	$factory->findObject( '@BrowseTemplate', Name => $which_tmpl );
	
    # instantiate the template
    my $tmpl = 
	HTML::Template->new(filename => $tmplData->Template(),
			    case_sensitive=>1);
    
   # get the root object
    my $root = $q->param('Root');

    # instantiate variables in the template
    $tmpl_data{'Root'} = $root;
    $tmpl_data{'Template'} = $q->param('Template');

	
    # get a parsed array of the types in the path variable.
    my $pathTypes= $self->getPaths($tmpl);
    
    

    # find the instances associated with root. 
    # NOTE: We might want to change this if we revise to handle 
    # _all_ instances of the first class
    my $pathElt = shift @$pathTypes;
    my $rootObj = $factory->findObject($pathElt, Name=>$root);


    # strip off preceding '@'

    $pathElt =~ /@(.*)/;
    my $rootType = $1;
    $tmpl_data{'RootType'} = $rootType;

    if (defined $rootObj)  {

	# get the associated layout code
	$tmpl_data{'RootHtml'} = $self->getHeader($rootObj,$rootType);
	$tmpl_data{'AnnotationDetail'} = 
	    $self->getLayoutCode($rootObj,$pathTypes,$rootType);
    }
	

    # populate the template..
    $tmpl->param(%tmpl_data);
    # and the form.
    my $html =
	$q->startform( { -name => 'primary' } );
    $html .= $tmpl->output() if ($tmpl);
    $html .= $q->endform();

    return ('HTML',$html);	
}

=head1 getPaths

    Find the template parameter named "Path.load/types-[...]",
    parse out the list of types inside the brackets, and return an
    array reference.
    

=cut
sub getPaths {
    my $self= shift;
    my $tmpl = shift;

    my @parameters = $tmpl->param();
    my @found_params = grep (m/\.load/,@parameters);
    my $path = $found_params[0];

    $path =~ m/Path.load\/types-\[(.*)\]/;
    my @paths = split(/,/,$1);
    return \@paths;
}

=head1 getHeader 
    Find a header to put above details. This header will link back
    to external links if possible.
=cut

sub getHeader {
    my $self = shift;
    my ($rootObj,$rootType) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $q = $self->CGI();
    my $html;

    # at this point, $root object is what we start with, rootType is
    # its type
    
    # find map from root type to ext link
    my $mapType ="@".$rootType."ExternalLink";

    my $name = $rootObj->Name();

    # find instance of this for the object
    my $map = $factory->findObject($mapType,$rootType=>$rootObj);

    # if it exists, get link and make href
    if (defined $map) {
	my $link = $map->ExternalLink();
	my $url = $link->URL();
	$html = $q->a({href=>$url},$name);

    }else {    # if not, just put out name.
	$html = "$name";
    }
    return $html;

}

=head1 getLayoutCode
    
    Get the layout code. Recursively walk down the list of types,
    find all instances of the next type, and recurse down those, 
    building resulting html into a list of nested <ul>..</ul> 
    lists.
    
=cut
sub getLayoutCode {
    my $self = shift;
    my ($root,$pathTypes,$parentType) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();
    
    my $html;

    # The map is the type that goes between $parentType
    # and $type - the next entry in the list.
    # type will be undef when the map maps directly to image.
    # shifting walks down the list destructively,
    # so we have to copy the list when we recurse.

    my $map = shift @$pathTypes;
    my $type = shift @$pathTypes || undef;

    # strip off the "@" to get the field name.
    $type =~ /@(.*)/;
    # so, if map is ProbeGeneMap and type is "@Probe", target field
    # will be probe
    my $targetField = $1;

    # find the maps that correspond to the root object.
    my @maps = $factory->
	findObjects($map, { $parentType  =>
				$root});
    
    if (scalar(@maps) > 0) {
	# if i have any maps

	if (scalar(@$pathTypes) ==0 ) {
	    # we're at the end of the list of types.

	    my @images;
	    # find the image associated with the maps.
	    foreach my $map (@maps) {
		my $imageID = $map->image_id;
		my $image = $factory->loadObject('OME::Image',$imageID);
		push(@images,$image);
	    }
	    # render them in an html array
	    $html .=   return 
		$self->Renderer()->renderArray(\@images,
					       'ref_st_annotation_display_mass',
					     { type => 'OME::Image'});
	    
	}
	else  { # still more to go.
	    #start a new list
	    $html .= "<ul>";
	    foreach my $map (@maps) {
		# get target of map
		# print a label for it
		# recurse with it as root and it's type as parent

		# target field is now the next type in the hierarchy.
		my $target = $map->$targetField;
		# get the item and build it as a list of item.
		$html .= "<li> ". $targetField . "  ".
		    $target->Name() .    "<br>\n";

		# fresh copy of the list of types for the next recursion
		my @localTypes;
		for (my $i=0; $i < scalar(@$pathTypes); $i++) {
		    $localTypes[$i]=$pathTypes->[$i];
		}
		# recurse to populate the next level.
		$html .= $self->getLayoutCode($target,\@localTypes,
					      $targetField);
		$html .= "<p>"
	    }
	    # end the list.

	    $html .= "</ul>";
	}
    }
    else  {
	# if I found no maps.
	return "<p>No images found.<p> "if (scalar(@$pathTypes) == 0);

	return "No ${targetField}s found.<p>";
    }
    return $html;
}




1;
