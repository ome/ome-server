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
use Data::Dumper;
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


    my $output = $self->getAnnotationDetails($self,$root,$which_tmpl,
					     \%tmpl_data);


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
    # was my ($pathTypes,$pathTypes2)= $self->getPaths($tmpl);
    my ($paths) = $self->getPaths($tmpl);
    my $pathTypes = $paths->[0];  # get first entry.
    # here is where we can add a swap depending on state of the pull-down
    

    # find the instances associated with root. 
    # NOTE: We might want to change this if we revise to handle 
    # _all_ instances of the first class
    my $pathElt = shift @$pathTypes;
    print STDERR "path elt is $pathElt\n";
    my $rootObj = $factory->findObject($pathElt, Name=>$root);


    # strip off preceding '@'

    $pathElt =~ /@(.*)/;
    my $rootType = $1;


    my $annotation_detail;
    my @images;
    if (defined $rootObj)  {

	# get the associated layout code
	$annotation_detail = "Images for $rootType " .
	    $self->getHeader($container,$rootObj,$rootType) . "<br>\n";
	$annotation_detail .= 
	    $self->getLayoutCode($container,$rootObj,$paths,$rootType,$which_tmpl,1,\@images);
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
    my @pathArray;

    my @parameters = $tmpl->param();
 
    my @found_params  = grep (m/\.load\/types/,@parameters);
    my $paramCount = scalar(@found_params);
    print STDERR "***param count is $paramCount\n";
    for (my $i = 1; $i <= $paramCount;  $i++) {
	my @list = grep (m/\.load\/types$i/,@parameters);
	# pull param $i out of found_params
	my $param = $list[0];
	print STDERR "found param $param\n";

	# find the path value.
	$param =~ m/Path.load\/types$i-\[(.*)\]/;
	my @path = split (/,/,$1);

	push @pathArray,\@path;
	
    }
    return \@pathArray;
}

=head1 getHeader 
    Find a header to put above details. This header will link back
    to external links if possible.
=cut

sub getHeader {
    my $self = shift;
    my ($container,$obj,$type) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $html;

    my $q = $container->CGI();
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
    my ($container,$root,$paths,$parentType,$template,$first,$images) = @_;
    my $session= $self->Session();
    my $factory = $session->Factory();
    
    my $html="";
    print STDERR "** starting get layout code. root is $root, parent   type is $parentType\n";
    

    # The map is the type that goes between $parentType
    # and $type - the next entry in the list.
    # type will be undef when the map maps directly to image.
    my $pathTypes = $paths->[0];


    my $map = shift @$pathTypes;
    my $type = shift @$pathTypes || undef;

    # strip off the "@" to get the field name.
    $type =~ /@(.*)/ if (defined $type);
    # so, if map is ProbeGeneMap and type is "@Probe", target field
    # will be probe
    my $targetField = $1;

    print STDERR "*** in get layout code. map is $map, type is $type\n";
    print STDERR Data::Dumper->Dump([$map,$type]);
    
    # find the maps that correspond to the root object.
    my @maps = $factory->
	findObjects($map, { $parentType  =>
				$root,
	                    __order =>['id']});
    
    if (scalar(@maps) > 0) {
	# if i have any maps

	if (scalar(@$pathTypes) ==0 ) {
	    # we're at the end of the list of types.

	    my $resHtml = $self->completeDim($container,\@maps,$paths,$template,$first,$images);
	    return $resHtml if ($resHtml eq "");
	    $html .= $resHtml;
	}
	else  { # still more to go.
	    #start a new list
	    my $resHtml =
		$self->processMaps($container,\@maps,$targetField,$paths,$template,$first,$images);
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


sub getFullDimLayoutCode {

    print STDERR "*STARTING  full dim layout code..\n";
    my $self= shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my ($container,$paths,$template,$images) = @_;
    
    my $pathTypes = $paths->[0];
    my $pathElt = shift @$pathTypes;
    print STDERR "*  in full dim layout. path element is $pathElt\n";
    
    $pathElt =~ /@(.*)/;
    my $rootType = $1;

    my $html;
    # get all objects of this type,  
    my $objs = $factory->findObjects($pathElt);
    my $itemsHtml;
    while (my $obj = $objs->next()) {
	my @localPaths;
	for (my $i=0; $i < scalar(@$paths); $i++ ) {
	    my $inner = $paths->[$i];
	    my @copy;
	    for (my $j = 0; $j  < scalar(@$inner); $j++) {
		$copy[$j] = $inner->[$j];
	    }
	    $localPaths[$i] = \@copy;
	}

	my $innerHtml =$self->getLayoutCode($container,$obj,
					    \@localPaths,$rootType,$template,0,$images);
	if ($innerHtml ne "")  {
	    $itemsHtml  = "<LI> $rootType";
	    $itemsHtml .=
					    $self->getHeader($container,$obj,$rootType)
					    . "<br>\n";
	    $itemsHtml .= $innerHtml;
	}
    }
    if ($itemsHtml ne "") {
	$html = "<UL>$itemsHtml</UL>";
    }
    return $html;
}

sub completeDim {
    print STDERR "* starting complete dim \n";
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my ($container,$maps,$paths,$template,$first,$images) = @_;

    # first tells off if it's first dim or not. If it is, we don't
    # filter - just take all images. if it is, stuff that we find must
    # be in the list we're looking at.
    my @newImages;
    if ($first) {

	foreach my $map (@$maps) {
	    my $imageID = $map->image_id;
	    my $image = $factory->loadObject('OME::Image',$imageID);
	    push(@newImages,$image);
	}
    }
    else {
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
    print STDERR "*~*!*!* in complete dimr. # of paths is " . scalar(@$paths) . "\n";
    if (defined $paths && scalar(@$paths) > 1) {
	print STDERRR "** at end of first dim...\n";
	# copy dim 2 and onward.
	shift @$paths;

	# was $html=
	# $self->secondDimRender($container,$images,$paths,$template);
	$html = $self->getFullDimLayoutCode($container,$paths,$template,$images);
    } elsif (scalar(@$images) > 0) {
	print STDERR "****RENDERING  " . scalar(@$images) . "\n";
	print STDERR Data::Dumper->Dump([$images]);
	print STDERR Data::Dumper->Dump([$template]);
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

sub processMaps  { 

    print STDERR "* STARTING PRocess maps \n";
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($container,$maps,$targetField,$pathTypes,$template,$first,$images) = @_;

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
	my @localPaths;
	for (my $i=0; $i < scalar(@$pathTypes); $i++ ) {
	    my $inner = $pathTypes->[$i];
	    my @copy;
	    for (my $j = 0; $j  < scalar(@$inner); $j++) {
		$copy[$j] = $inner->[$j];
	    }
	    $localPaths[$i] = \@copy;
	}
	# recurse to populate the next level.
	$innerHtml .= $self->getLayoutCode($container,$target,\@localPaths,
					   $targetField,$template,$first,$images);
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
    

sub secondDimRender {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($container,$images,$pathTypes,$template) = @_;

    my $paths = $pathTypes->[0];
    my $type = shift @$paths;
    my $html="";
    
    #find all of the items of type $type
    print STDERRR "***SECOND DIM RENDER . type is $type\n";
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
	    $self->secondDimRecurse($container,$images,$parentType,$item,\@mypaths,$template);
	if ($res ne "") {
	    $itemHtml .= "<LI> $parentType ". 
		$self->getHeader($container,$item,$parentType);
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
    my ($container,$images,$parentType,$parent,$paths,$template) = @_;

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
	    my $resHtml = $self->renderImages($container,\@maps,$images,$template);
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
			$self->secondDimRecurse($container,$images,$targetField,
						$target,\@localPath,$template);
		    if ($resHtml ne "") {
			$innerHtml .= "<li> " . $targetField . " " .
			    $self->getHeader($container,$target,$targetField) . 
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
    my ($container,$maps,$images,$template) = @_;

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
	my $renderer = $container->Renderer();
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
