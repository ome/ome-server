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

    # get the root object
    my $root = $q->param('Root');


    my $output = $self->getAnnotationDetails($root,$which_tmpl,
					     \%tmpl_data,$self);


    # and the form.
    my $html =
	$q->startform( { -name => 'primary' } );
    $html .= $output;
    $html .= $q->endform();

    return ('HTML',$html);	
}

sub getAnnotationDetails {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($root,$which_tmpl,$tmpl_data,$obj) = @_;

    # load the appropriate information for the named template.
    my $tmplData = 
	$factory->findObject( '@BrowseTemplate', Name => $which_tmpl );

    
	
    # instantiate the template
    my $tmpl = 
	HTML::Template->new(filename => $tmplData->Template(),
			    case_sensitive=>1);
    


    # instantiate variables in the template
    $tmpl_data->{'Root'} = $root;
    $tmpl_data->{'Template'} = $which_tmpl;

	
    # get a parsed array of the types in the path variable.
    my ($pathTypes,$pathTypes2)= $self->getPaths($tmpl);
    
    # here is where we can add a swap depending on state of the pull-down
    

    # find the instances associated with root. 
    # NOTE: We might want to change this if we revise to handle 
    # _all_ instances of the first class
    my $pathElt = shift @$pathTypes;
    my $rootObj = $factory->findObject($pathElt, Name=>$root);


    # strip off preceding '@'

    $pathElt =~ /@(.*)/;
    my $rootType = $1;


    my $annotation_detail;
    if (defined $rootObj)  {

	# get the associated layout code
	$annotation_detail = "Images for $rootType " .
	    $self->getHeader($rootObj,$rootType,$obj) . "<br>\n";
	$annotation_detail .= 
	    $self->getLayoutCode($rootObj,$pathTypes,$rootType,$pathTypes2,
				 $obj,$which_tmpl);
    }
    else {
	$annotation_detail = "$rootType $root not found \n";
    }
    $tmpl_data->{'AnnotationDetail'} = $annotation_detail;
	
    # populate the template..
    $tmpl->param(%$tmpl_data);
    
    return $tmpl->output();
}

=head1 getPaths

    Find the template parameter named "Path.load/types-[...]",
    parse out the list of types inside the brackets, and return an
    array reference.
    

=cut
sub getPaths {
    my $self= shift;
    my $tmpl = shift;

    my $res2 = undef;

    my @parameters = $tmpl->param();
    my @found_params = grep (m/\.load\/types1-/,@parameters);
    my $path = $found_params[0];

    $path =~ m/Path.load\/types1-\[(.*)\]/;
    my @paths = split(/,/,$1);

    @found_params = grep (m/\.load\/types2-/,@parameters);
    $path = $found_params[0];

    if (defined  $path) {
	$path =~ m/Path.load\/types2-\[(.*)\]/;
	my @paths2 = split(/,/,$1);
	$res2= \@paths2;
    }


    return (\@paths,$res2);
}

=head1 getHeader 
    Find a header to put above details. This header will link back
    to external links if possible.
=cut

sub getHeader {
    my $self = shift;
    my ($obj,$type,$webObj) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $html;

    my $q = $webObj->CGI();
    # at this point, $root object is what we start with, rootType is
    # its type
    
    # find map from root type to ext link
    my $mapType ="@".$type."ExternalLink";

    my $name = $obj->Name();
    $html = $name;

    # find instance of this for the object. Do it in an eval 
    # because this type might not exist.
    my $map;

    eval {$map= $factory->findObject($mapType,$type=>$obj) };

    return $html if $@;


    # if it exists, get link and make href
    if (defined $map) {
	my $link = $map->ExternalLink();
	my $url = $link->URL();
	$html = $q->a({href=>$url},$name);

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
    my ($root,$pathTypes,$parentType,$paths2,$obj,$template) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();
    
    my $html="";
    

    # The map is the type that goes between $parentType
    # and $type - the next entry in the list.
    # type will be undef when the map maps directly to image.


    my $map = shift @$pathTypes;
    my $type = shift @$pathTypes || undef;

    # strip off the "@" to get the field name.
    $type =~ /@(.*)/ if (defined $type);
    # so, if map is ProbeGeneMap and type is "@Probe", target field
    # will be probe
    my $targetField = $1;

    # find the maps that correspond to the root object.
    my @maps = $factory->
	findObjects($map, { $parentType  =>
				$root,
	                    __order =>['id']});
    
    if (scalar(@maps) > 0) {
	# if i have any maps

	if (scalar(@$pathTypes) ==0 ) {
	    # we're at the end of the list of types.

	    my $resHtml = $self->completeFirstDim(\@maps,$paths2,$obj,$template);

	    return $resHtml if ($resHtml eq "");
	    $html .= $resHtml;
	}
	else  { # still more to go.
	    #start a new list
	    my $resHtml =
		$self->processMaps(\@maps,$targetField,$pathTypes,
				   $paths2,$obj,$template);
	    # end the list.
	    if ($resHtml ne "") {
		$html = "<ul>$resHtml</ul>";
	    }
	}
    }
    else  {
	return "";
    }
    return $html;
}

sub completeFirstDim {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my ($maps,$paths,$obj,$template) = @_;

    my $html = "";
    my @images;
    foreach my $map (@$maps) {
	my $imageID = $map->image_id;
	my $image = $factory->loadObject('OME::Image',$imageID);
	push(@images,$image);
    }

    if (defined $paths && scalar(@$paths) > 0) {
	$html=   $self->secondDimRender(\@images,$paths,$obj,$template);
    } elsif (scalar(@images) > 0) {
	$html = 
	    my $renderer = $obj->Renderer();
	    $renderer->renderArray(\@images,
					   'ref_st_annotation_display_mass',
					   { type =>
						 'OME::Image',
					     Template=>$template});
    }
    return $html;
}

sub processMaps {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($maps,$targetField,$pathTypes,$paths2,$obj,$template) = @_;

    my $html = "";
    foreach my $map (@$maps) {
	my $innerHtml = "";
	# get target of map
	# print a label for it
	# recurse with it as root and it's type as parent
	
	
	# target field is now the next type in the hierarchy.
	my $target = $map->$targetField;
	
	# fresh copy of the list of types for the next
	# recursion;
	# shifting walks down the list destructively,
	# so we have to copy the list when we recurse.
	my @localTypes;
	for (my $i=0; $i < scalar(@$pathTypes); $i++) {
	    $localTypes[$i]=$pathTypes->[$i];
	}
	
	my $res2 = undef;
	if (defined $paths2) {
	    my @local2;
	    for (my $i=0; $i < scalar(@$paths2); $i++) {
		$local2[$i]=$paths2->[$i];
	    }
	    $res2 = \@local2;
	}
		# recurse to populate the next level.
	$innerHtml .= $self->getLayoutCode($target,\@localTypes,
					   $targetField,$res2,$obj,
					   $template);
	if ($innerHtml ne "") {
	    my $q = $obj->CGI();
	    # get the item and build it as a list of item.
	    $html .= "<li>". $targetField . "  ".
		$self->getHeader($target,$targetField,$obj) . "<br>\n";
	    $html .= $innerHtml;
	    $html .= "<p>"		    
	}
    }
    return $html;
}
    

sub secondDimRender {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($images,$paths,$obj,$template) = @_;


    my $type = shift @$paths;
    my $html="";
    
    #find all of the items of type $type
    my  @items = $factory->findObjects($type, { __order => ['id']});
    $type=~ /@(.*)/;
    my $parentType = $1;

    my $itemHtml="";
    foreach my $item (@items) {
	my @mypaths;
	for (my $i =0; $i < scalar(@$paths); $i++) {
	    $mypaths[$i]=$paths->[$i];
	}
	my $res  =
	    $self->secondDimRecurse($images,$parentType,$item,\@mypaths,$obj,
				    $template);
	if ($res ne "") {
	    $itemHtml .= "<LI> $parentType ". 
		$self->getHeader($item,$parentType,$obj);
	    $itemHtml .= $res;
	}
    }
    if ($itemHtml  ne "") {
	$html = "<UL>$itemHtml</UL>";
    }
    return $html;
}

sub secondDimRecurse {
    my $self= shift;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my ($images,$parentType,$parent,$paths,$obj,$template) = @_;

    my $html= "";
    #  now,  map type is something like ABMap, and type is $b
    # ie., each map is a probe gene, and mapType is probeGene.    
    my $mapType = shift @$paths;
    my $type = shift @$paths || undef;

    #find the maps.

    $type =~ /@(.*)/ if (defined $type);
    my $targetField = $1;
    my @maps  = $factory->findObjects($mapType,{$parentType =>
						    $parent,
				                __order =>['id'] });
    my $innerHtml = "";

    if (scalar(@maps) > 0)  {
	if (scalar(@$paths) == 0)  {
	    #actually render the images 
	    my $resHtml = $self->renderImages(\@maps,$images,$obj,$template);
	    if ($resHtml ne "") {
		$innerHtml .= $resHtml;
	    }
	}
	else {
	    #types is now @Probe, targetfiled is "Probe"
	    #recurse
	    foreach my $map (@maps) {
		my $target = $map->$targetField;
		# copy
		my @localPath;
		for (my $i =0; $i < scalar(@$paths); $i++) {
		    $localPath[$i] = $paths->[$i];
		    #$targetfield is new parent type, $target is new parent
		    my $resHtml .=
			$self->secondDimRecurse($images,$targetField,
						$target,\@localPath,$obj,$template);
		    if ($resHtml ne "") {
			$innerHtml .= "<li> " . $targetField . " " .
			    $self->getHeader($target,$targetField,$obj) . 
			    "<br>\n";
			$innerHtml .= $resHtml;
		    }
		}
	    }
	}
    }
    else {
	return "";
    }
    if ($innerHtml ne "") {
	$html =  "<UL>$innerHtml</UL>";
    }
    return $html;

}


sub renderImages {
    my $self = shift;
    my ($maps,$images,$obj,$template) = @_;

    # at this point, we have two refs to arrays.
    # map is an array of things that map to images.
    # (with $image_id fields)
    # and $images is a bunch of images.
    # we want to retain intersection and render.
    my @imagesToRender;
    IMAGE: foreach my $image (@$images) {
	foreach my $map (@$maps) {
		$image->ID . "\n";
	    if ($map->image_id == $image->ID) {
		push @imagesToRender, ($image);
		next IMAGE;
	    }
	}
    }
    if (scalar(@imagesToRender) > 0) {
	my $renderer = $obj->Renderer();
	return $renderer->renderArray(\@imagesToRender,
					      'ref_st_annotation_display_mass',
					      { type =>
						    'OME::Image',
						Template=>$template});
    }
    else {
	return "";
    }
}

1;