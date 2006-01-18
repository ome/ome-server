#OME/Web/ImageAnnotationBrowser.pm

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

  
This template file will contain a TMPL_VARS of the form
    "Path.load/types<x>-[....]", where "<x>" is a numeric value,
    starting with one and increasing. Each of these variables will
    include a list of types that will define a path leading from a
    root to sets of images. The number <x> will define the order in
    which these variables are used: 0 will be the outermost hierarchy,
    1 will be next, etc. 

These list of types will alternate between objects and maps. An
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
    assumed to be the Name of the instance of the first ST, in the
    variable named "Path.load/types0..."
    
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


    # get the details. this is where the bulk of the work gets done.
    # use this procedure to allow for bulk of layout to be called from
    # other modules
    my $output = $self->getAnnotationDetails($self,$root,$which_tmpl,
					     \%tmpl_data);


    # and the form.
    my $html =
	$q->startform( { -name => 'primary' } );
    $html .= $output;
    $html .= $q->endform();

    return ('HTML',$html);	
}

=head1 getAnnotationDetails

    Do the bulk of populating the details of the annotations.
    Starting from a root value, iterate down the hierarchy and
    populate the template as appropriate.

=cut

sub getAnnotationDetails {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    # container is the OME::Web object that is calling this code.
    my ($container,$root,$which_tmpl,$tmpl_data) = @_;

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
    # this will be an array of references to arrays.
    # each reference array will be a list of paths.
    my ($paths) = $self->getPaths($tmpl);
    my $pathTypes = $paths->[0];  # get first path. 


    
    # parse out the roots, into an array of 0...n root vars.
    my $roots = $self->parseRoots($root);


    
    # get the header

    my $annotation_detail;
    $annotation_detail = $self->getPageHeader($container,$roots,$paths);


    my $layout =  $self->getDimLayoutCode($container,$paths,$roots,
					  $which_tmpl);
    if ($layout eq "") {
	# or just say that there's nothing found
	$layout = "<br>No Images found\n";
    }
    $annotation_detail .= $layout;
    # populate the template..
    $tmpl_data->{'AnnotationDetail'} = $annotation_detail;

    $tmpl->param(%$tmpl_data);
    
    return $tmpl->output();
}

=head1 getPaths

    Find the template parameters named "Path.load/types<x>-[...]",
    parse out the list of types inside the brackets, and return a
    reference to an array or arrays (one for each variable).
    

=cut
sub getPaths {
    my $self= shift;
    my $tmpl = shift;
    my @pathArray;

    my @parameters = $tmpl->param();

    # find all potentially matching parameters names
    my @found_params  = grep (m/\.load\/types/,@parameters);
    my $paramCount = scalar(@found_params);
    
    # iterate over them in order
    for (my $i = 0; $i < $paramCount;  $i++) {

	# pull param $i out of found_params
	my @list = grep (m/\.load\/types$i/,@parameters);
	my $param = $list[0];

	# find the path value.
	$param =~ m/Path.load\/types$i-\[(.*)\]/;
	#convert to array
	my @path = split (/,/,$1);

	# store array ref
	push @pathArray,\@path;
	
    }
    # return ref to array of refs.
    return \@pathArray;
}

=head1 parseRoots
    With n hierarchies, we can have roots in 0-n of them. this
    procedure will parse out a textual list of roots of the form 
    [root1,root2,root3] and return a reference to an array of the
    individual values.
    
    The entries root2, root2, etc. must be names of objects. for all i,
    root#i must be an object of the first type list in the
    Path.load/types#1.

=cut

sub parseRoots {
    my $self=shift;
    my $root=shift;
    
    $root =~ /\[(.*)\]/;
    my @roots = split(/,/,$1);
    return \@roots;
}

=head1 getPageHeader 
    A header for the whole page.

=cut

sub getPageHeader {
    my $self= shift;
    my $session = $self->Session();
    my $factory = $session->Factory();

    my ($container,$roots,$paths) = @_;
    
    my $html = "Images for  ";
    my $rootText;
    my $count = scalar(@$paths);
    for (my $i = 0; $i < $count; $i++) {
	my $rootName = $roots->[$i];
	next if ($rootName eq "");
	my $rootType = $paths->[$i]->[0];
	my $root = $factory->findObject($rootType,Name=>$rootName);
	my $header = $self->getHeader($container,$root,$rootType);
	if ($i > 0  & $rootText ne "") {
	    $rootText .= ", ";
	}
	$rootType =~ /@(.*)/;
	$rootText .= "$1 $header";
    }
    $html  .= "$rootText<br>";
    return $html;
}

=head1 getHeader 
    Find a header to put above details. This header will link back
    to external links if possible. If not external link is available, 
    provide the object detail url. if that is not availabe, simply do
    the name
=cut

sub getHeader {
    my $self = shift;
    my ($container,$obj,$type) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $html;

    my $q = $container->CGI();

    my $name = $obj->Name();
    $html = $name;
    
    # find map from root type to external  links
    my $mapType =$type."ExternalLinkList";



    # find instance of this for the object. Do it in an eval 
    # because this type might not exist.
    my $map;

    # get the list of links, & find the first element in this list.
    eval{ my $maps = $obj->$mapType(); $map = $maps->next() };


    # if there's an error or no map give the object detail url or just
    # the name (if no details)
    if ($@ || !$map) {
	my $detail = $self->getObjDetailURL($obj);
	if ($detail) {
	    $html = $q->a({href=>$detail},$name);
	}
    }
    elsif ($map) { # but, if the link does exist, create it.
	
	my $link = $map->ExternalLink();
	my $url = $link->URL();
	$html = $q->a({href=>$url},$name);

    }
    return $html;

}

=head getDimLayoutCode

    start the layout for a dimension

=cut

sub getDimLayoutCode {

    my $self=shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my ($container,$paths,$roots,$template,$first,$images) =@_;

    my $factory = $session->Factory();
    if (!$images) {
	my @imageArray;
	$images = \@imageArray;
    }

    # first time through require special handling: for first
    # dimension, we will grab images. for all others, we will 
    # filter from originalset.
    $first = 1 unless (defined $first);

    my $factory = $session->Factory();
    if (!$images) {
	my @imageArray;
	$images = \@imageArray;
    }

    # first time through require special handling: for first
    # dimension, we will grab images. for all others, we will 
    # filter from originalset.
    $first = 1 unless (defined $first);

    my $html;
    # do we have a root here?
    my $root = shift @$roots;
    if ($root ne "") {
	my $pathTypes = $paths->[0];
	my $pathElt = shift @$pathTypes;
	$pathElt =~ /@(.*)/;
	my $rootType=$1;
	my $rootObj = $factory->findObject($pathElt,Name=>$root);
	$html = $self->getLayoutCode($container,$rootObj,$paths,$roots,
				     $rootType,$template,$first,$images);
    }
    else {
	$html = $self->getFullDimLayoutCode(
	    $container,$paths,$roots,$template,$first,$images);
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
    my ($container,$root,$paths,$roots,$parentType,$template,$first,$images) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();
    if (!$images) {
	my @imageArray;
	$images = \@imageArray;
    }

    # first time through require special handling: for first
    # dimension, we will grab images. for all others, we will 
    # filter from originalset.
    $first = 1 unless (defined $first);
    
    my $html="";
    
    # get the first array of dimensions - this is the one we're
    # currently working off of.
    my $pathTypes = $paths->[0];


    # The map is the type that goes between $parentType
    # and $type - the next entry in the list.
    # type will be undef when the map maps directly to image.
    #  thus, for example, map might be @ProbeGene, and type is
    # @Probe.,
    # $parentType is @gene.

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
	    # we're at the end of the list of types for this hierarchy
	    # pop the now-empty first list of types,
	    shift @$paths;
	    # complete it and complete this dimension. 
	    my $resHtml = $self->completeDim($container,\@maps,$roots,
					     $paths,$template,$first,$images);
	    # either add the appropriate html or return null.
	    return $resHtml if ($resHtml eq "");
	    $html .= $resHtml;
	}
	else  { # still more to go.
	    #process the maps to go down a level?
	    my $resHtml =
		$self->processMaps($container,\@maps,$targetField,
				   $roots,$paths,$template,$first,$images);
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

=head1 completeDim

    The completion of a dimension requires either grabbin a new set of
    images (if this is the first dimension) or filtering the existing
    set of images to contain only those that are referenced in the
    maps

=cut

sub completeDim {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my ($container,$maps,$roots,$paths,$template,$first,$images) = @_;

    # first tells off if it's first dim or not. If it is, we don't
    # filter - just take all images. 
    my @newImages;
    if ($first) {

	foreach my $map (@$maps) {
	    my $imageID = $map->image_id;
	    my $image = $factory->loadObject('OME::Image',$imageID);
	    push(@newImages,$image);
	}
	$first  = 0;
    }
    else {
	# if it's not the first dim, take intersection of those that
	# are  in the image list and those that are specified by the map
	foreach my $map (@$maps) {
	    my $imageID = $map->image_id;
	    foreach my $image (@$images) {
		if ($image->ID() == $imageID) {
		    push(@newImages,$image);
		    last;
		}
	    }
	}
    }
	
    $images = \@newImages;
    my $html = "";
    if (defined $paths && scalar(@$paths) > 0) {
	# if we have more dimensions to go, continue on with the
	# full  layout of the next dimension
	$html = $self->getDimLayoutCode($container,$paths,$roots,
					    $template,$first,$images);
    } elsif (scalar(@$images) > 0) {
	# at this point, no more dimensions to go. so, 
	# if we have any images, we render them.
	my $renderer = $container->Renderer();
	$html = 
	    $renderer->renderArray($images,
					   'ref_st_annotation_display_mass',
					   { type =>
						 'OME::Image',
					     Template=>$template});
    }
    return $html;
}


=head1 getFullDimLayoutCode
    For hierarchies 2-n, we don't have a specific "root" to start 
    with. Instead, we pull out every instance of the specified type
    and iterate over it, making it a new entry if there is any
    associated data.


=cut
sub getFullDimLayoutCode {

    my $self= shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my ($container,$paths,$roots,$template,$first,$images) = @_;
    
    my $pathTypes = $paths->[0];
    my $pathElt = shift @$pathTypes;
    
    $pathElt =~ /@(.*)/;
    my $rootType = $1;

    my $html;
    # get all objects of this type,  

    my $objs = $factory->findObjects($pathElt);

    my $itemsHtml;
    while (my $obj = $objs->next()) {
	# copy the paths for each recursive instance
	my $localPaths = $self->copyArray2D($paths);
	my $localRoots = $self->copyArray($roots);

	# recurse to the next level. Note that this recursive call
	#will not be the first instance
	my $innerHtml =$self->getLayoutCode($container,$obj,
					    $localPaths,$roots,
					    $rootType,$template,$first,$images);
	
	# if this gives me anything, put it in an <LI> tag
	if ($innerHtml ne "")  {
	    $itemsHtml .= "<LI> $rootType ";
	    $itemsHtml .= $self->getHeader($container,$obj,$rootType)
		. "<br>\n";
	    $itemsHtml .= $innerHtml;
	}
    }
    # if the over all loop gives me anything, put it in a list.


    if ($itemsHtml ne "") {
	$html .= "<UL>$itemsHtml</UL>";
    }
    return $html;
}


=head1 processMaps

    walk down a list of map objects,populating and recursing.

=cut
sub processMaps  { 

    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($container,$maps,$targetField,$roots,
	$pathTypes,$template,$first,$images) = @_;

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
	my $localPaths = $self->copyArray2D($pathTypes);
	my $localRoots = $self->copyArray($roots);

	# recurse to populate the next level, passing $first value along
	$innerHtml .=	$self->getLayoutCode($container,$target,$localPaths,
			     $localRoots,$targetField,$template,$first,
					     $images); 
	if ($innerHtml ne "") {
	    my $q = $container->CGI();
	    # get the item and build it as a list of item.
	    $html .= "<li>". $targetField . "  ".
		$self->getHeader($container,$target,$targetField) . "<br>\n";
	    $html .= $innerHtml;
	    $html .= "<p>"		    
	}
    }
    return $html;
}

=head1 copyArray2D

    generate a copy of a 2D array as needed for recursion.

=cut

sub copyArray2D {
    my $self=shift;
    my $array = shift;

    my @local;
    for (my $i=0; $i < scalar(@$array); $i++ ) {
	my $inner = $array->[$i];
	my @copy;
	for (my $j = 0; $j  < scalar(@$inner); $j++) {
	    $copy[$j] = $inner->[$j];
	}
	$local[$i] = \@copy;
    }
    return \@local;
}

=head copyArray
    generate a copy of a 1-d array
=cut

sub copyArray {
    my $self=  shift;
    my $array = shift;
    my @local;
    for (my $i = 0; $i< scalar(@$array); $i++) {
	$local[$i] = $array->[$i];
    }
    return \@local;
}
   

1;
