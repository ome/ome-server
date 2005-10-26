# OME/Web/ImageAnnotationDetail.pm

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


package OME::Web::ImageAnnotationDetail;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;

use base qw(OME::Web);

sub getPageTitle {
    return "OME: Image Annotation Details";
}

{
    my $menu_text = "Image Annotation Details";
    sub getMenuText { return $menu_text }
}


=head1 getPageBody

Get the body for a page that displays an image associated with given
    annotations. The annotations to be displayed will be given by the
    content of a Template file - as specified in the Template
    parameter of the requesting URL.

  
This template file will contain a TMPL_VAR of the name
    "Path.load/types-[....]". Inside the brackets, this variable name
    will include a list of types that will be used to define a path
    leading images to a set of annotations.

The list of types will alternate between objects and maps. An
    event-numbered list of types will always be included - starting with
    a root, followed by a map type, a subsequent type, etc., and
    ending with a map that leads to a final ST.
    
Thus, for example, a list of the form 
    [@ImageProbe,@Probe,@ProbeGene,@Gene] will start with
    an Image, use ImageProbe to find all associated probes, and then
    ProbeGene to find all genes for the probe.

Successive annotation types will be displayed in nested lists.

Where possible, the final elements will be displayed with appropriate
   links to external URLs.
       
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
    my $url = $self->pageURL('OME::Web::ImageAnnotationDetail');
    my $ID = $q->url_param("ID");
    if ($referer && $referer =~ m/Template=(.+)$/ && !($which_tmpl)) {
	$which_tmpl = $1;
	$which_tmpl =~ s/%20/ /;
	my $redirect =$self->redirect($url.'&Template='.$which_tmpl."&ID=".$ID);
	return ('REDIRECT', $redirect);
    }
    $which_tmpl =~ s/%20/ /;

    # load the appropriate information for the named template.
    my $tmplData = 
	$factory->findObject( '@DisplayTemplate', Name => $which_tmpl );
	
    # instantiate the template
    my $tmpl = 
	HTML::Template->new(filename => $tmplData->Template(),
			    case_sensitive=>1);

    # instantiate variables in the template    
    $tmpl_data{'Template'} = $q->param('Template');

    # load the imaeg.
    my $ID = $q->param('ID');
    my $image = $factory->loadObject( 'OME::Image', $ID);
    # populate  the basic image display  in the template.
    $self->getImageDisplay($tmpl,\%tmpl_data,$image);



	
    # get a parsed array of the types in the path variable.
    my $pathTypes= $self->getPaths($tmpl);

    # get the display detail.
    $tmpl_data{'AnnotationDetails'} = 
	$self->getDetail($pathTypes,'OME::Image',$image);
    
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


=head1 getImageDisplay

    get the basic display for the image 
=cut
sub getImageDisplay {
    my $self  = shift;
    my ($tmpl,$tmpl_data,$image) = @_;

    my $session= $self->Session();
    my $factory = $session->Factory();
    my @parameter_names = $tmpl->param();
 

    my @image_requests = grep( m'^image/render-(\w+)$', @parameter_names )
	or die "no image requested";
    my $image_request = $image_requests[0];
    $image_request =~ m'^image/render-(\w+)$';
    my $mode = $1;
    $tmpl_data->{$image_request } = $self->Renderer()->render( $image, $mode);
}

=head1 getDetail

    Recursively iterate through the path of types, populating the list s
    until we get down to the bare items at the end
=cut
sub getDetail {
    my $self= shift;
    my ($pathTypes,$parentType,$root) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my $html;

    # The map is the type that goes between $parentType
    # and $type - the next entry in the list.
    # type will be undef when the map maps directly to image.
    # shifting walks down the list destructively,
    # so we have to copy the list when we recurse.

    my $map = shift @$pathTypes;
    my $type = shift @$pathTypes;

    # strip off the "@" to get the field name.
    $type =~ /@(.*)/;
    # so, if map is ProbeGeneMap and type is "@Probe", target field
    # will be probe
    my $targetField = $1;

    my @maps;
    # find the maps that correspond to the root object.
    if ($parentType eq 'OME::Image') {
	@maps = $factory->findObjects($map,image=>$root);
    }
    else {
	@maps = $factory->
	    findObjects($map, { $parentType  =>
				    $root});
    }
    
    if (scalar(@maps) > 0) {
	# if i have any maps

	if (scalar(@$pathTypes) ==0 ) {
	    # we're at the end of the list of types.
	    $html .= "<ul>";


	    # find the image associated with the maps.
	    foreach my $map (@maps) {
		# now, i've got the gene;
		my $target = $map->$targetField;
		# get the external URL
		my $url = $self->getObjURL($target,$type);
		$html .= "<li> $targetField $url</br>";
	    }
	    $html .= "</ul>";
	}
	else  { # still more to go.
	    #start a new list
	    $html .= "<ul>";
	    foreach my $map (@maps) {
		# image probes now

		# target field is now the next type in the
		# hierarchy. - probe.
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
		$html .= $self->getDetail(\@localTypes,
					      $targetField,$target);
	    }
	    # end the list.

	    $html .= "</ul>";
	}
    }
    else  {
	# if I found no maps.
	return "No ${targetField}s found";
    }
    return $html;
}

=head1 getObjURL

    Find an HREF the external URL for the object. Assume that if we have
    type Foo, then ST "FooExternalLink" will contain the appropriate
    mapping to an external link. Also assume that any external link
    will be sufficient.

    The URL will be returned in an HREF for the URL, with the name 
    of the object being used as the text of the link. If no URL is
    available, the name of the object is returned.

=cut
sub getObjURL {
    my $self = shift;
    my ($target,$type) = @_;

    my $session = $self->Session();
    my $factory = $session->Factory();
    my $q  = $self->CGI();

    my $name = $target->Name();
    my $html = $name;
    # type = "@Gene", $target is the gene.
    my $linkMap = $type."ExternalLink";
    $type =~ /@(.*)/;
    my $field =$1;
    my $linkMapEntry = $factory->findObject($linkMap,$field=>$target);

    if (defined $linkMapEntry) {
	my  $link = $linkMapEntry->ExternalLink();
	my $url = $link->URL();
	$html =$q->a({href=>$url},$name);
    }
    return $html;
}
    
1;
