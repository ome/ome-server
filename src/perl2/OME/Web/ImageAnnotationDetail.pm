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
use Data::Dumper;
use base qw(OME::Web);

sub getPageTitle {
    return "OME: Image Annotation Details";
}

{
    my $menu_text = "Image Annotation Details";
    sub getMenuText { return $menu_text }
}

sub getTemplate {

    my $self=shift;
    my $id = $self->CGI()->url_param('ID');
    my $which_tmpl =  
	$self->getTemplateName('OME::Web::ImageAnnotationDetail',
	"&ID=$id");

    my $tmpl =
	OME::Web::TemplateManager->getDisplayTemplate($which_tmpl);

    return $tmpl;


}



=head1 getPageBody

Get the body for a page that displays an image associated with given
    annotations. The annotations to be displayed will be given by the
    content of a Template file - as specified in the Template
    parameter of the requesting URL.

  
This template file will contain a TMPL_VARS of the name
    "Path.load/types-[....]". Inside the brackets, these variable name
    will include a list of types that will be used to define a path
    leading images to a set of annotations. These  vars will be given
  ids: types1, types2 etc. that will indicate the order in which they
    are placed into the resulting output page.

The list of types will alternate between objects and maps. An
    event-numbered list of types will always be included - starting with
    a root, followed by a map type, a subsequent type, etc., and
    ending with a map that leads to a final ST.
    
Thus, for example, a list of the form 
    [ImageProbe,Probe,ProbeGene,Gene] will start with
    an Image, use ImageProbe to find all associated probes, and then
    ProbeGene to find all genes for the probe.

Successive annotation types will be displayed in nested lists.

CategoryGroup/Category annotations for the image will be displayed
    below the ST annotations. All CategoryGroup/Category
    annotations for the image will be displayed.

Where possible, the final elements will be displayed with appropriate
   links to external URLs.
       
=cut


sub getPageBody {
    my $self = shift ;
    my $tmpl= shift;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;

    my $ID = $q->url_param('ID');


    # instantiate variables in the template    
    $tmpl_data{'Template'} = $q->param('Template');

    my @parameters=$tmpl->param();

    # load the image.

    my $image = $factory->loadObject( 'OME::Image', $ID);
    # populate  the basic image display  in the template.
    $self->getImageDisplay(\@parameters,\%tmpl_data,$image);

    # get a parsed array of the ST types in the path variable.s
    my $pathTypes= $self->getPaths(\@parameters);

    # get the display detail.
    if (scalar(@$pathTypes) > 0) {
	$tmpl_data{'AnnotationDetails'} = $self->getDetail($pathTypes,$image);
    }

    $self->getClassificationDetails($image,\%tmpl_data);

    $self->getPublicationDetails($image,\%tmpl_data);

    # populate the template..
    $tmpl->param(%tmpl_data);
    # and the form.
    my $html =
	$q->startform( { -name => 'primary' } );
    $html .= $tmpl->output() if ($tmpl);
    $html .= $q->endform();

    return ('HTML',$html);	
}

=head1 getImageDisplay
    
    $self->getImageDisplay($parameter_names,$tmpl_data,$image);

    The template will have a variable name of the form
    "image/render-<mode", where <mode> describes an image rendering
    mode, such as "large_no_comments".  This procedure will render the
    image according to that node ad use it to populate the template
    data appropriately.

=cut

sub getImageDisplay {
    my $self  = shift;
    my ($parameter_names,$tmpl_data,$image) = @_;

    my $session= $self->Session();
    my $factory = $session->Factory();
 

    my @image_requests = grep( m'^image/render-(\w+)$', @$parameter_names )
	or die "no image requested";
    my $image_request = $image_requests[0];
    $image_request =~ m'^image/render-(\w+)$';
    my $mode = $1;
    $tmpl_data->{$image_request } = $self->Renderer()->render( $image, $mode);
}


=head1 getPaths

    $self->getPaths(@parameters);

    Find the template parameters named "Path.load/typesX-[...]", where 
    X= 0, 1, 2... 
    Parse out the list of types inside the brackets, and return an
    reference to an array. The array contains references to the split
    arrays of all of the type names. Thus, $paths->[0]is an array
    containing the names in the first path specification, etc. 
    

=cut

sub getPaths {
    my $self= shift;
    my $parameters = shift;
    my @paths;

    my @found_params = grep (m/Path\.load=/,@$parameters);
    foreach my $param (@found_params) {
    	$paths[$1] = [split (/,/,$2)] if $param =~ m/Path\.load=\[(\d+)\](.*)$/;
    }
#     print STDERR "paths...\n";
#     print STDERR Dumper(\@paths);
#     print STDERR "\n";

    return \@paths;
}


=head2 getDetail

    $self->getDetail($pathTypes,$root)

    Generate the detailed output from the semantic type paths. Iterate
    over all paths and concatenate the resulting HTML from each.

=cut

sub getDetail {
    my $self= shift;
    my ($pathTypes,$root) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my $html;

    foreach my $path (@$pathTypes) {
	$html  .= $self->getPathDetail('OME::Image',$root,@$path);
    }
    return $html;
}

=head1 getPathDetail

    $self->getPathDetail($pathTypes,$parentType,$root);

    Recursively iterate through one path of types, populating the list s
    until we get down to the bare items at the end

=cut

sub getPathDetail {
    my $self= shift;
    my $q= $self->CGI();

    # each pathTypes array is passed in not as a reference,
    # but as the actual array.
    # this way, it gets copied on call, and recursive calls can 
    # modify their array without fear of doing harm.

    my ($parentType,$root,@pathTypes) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my $html;

    # The map is the type that goes between $parentType
    # and $type - the next entry in the list.
    # type will be undef when the map maps directly to image.
    # shifting walks down the list destructively,
    # so we have to copy the list when we recurse.
	my ($STName1,$SEName) = split (/\./, shift @pathTypes);
	my $STName2;
	($STName2,$SEName) = split (/\./, shift (@pathTypes)) unless $SEName;
#  print STDERR "\n\ngetPathDetail STName1,SEName: '$STName1','$SEName'\n";
#  print STDERR "getPathDetail STName2,SEName: '$STName2','$SEName'\n";

    my @objs;
    my $accessor;
    if ($parentType eq 'OME::Image') {
		$accessor = 'image';
    } else {
		$accessor = $parentType;
    }

    # find the objects that correspond to the root object.
	my ($target, $targetField, $targetType);
#  print STDERR "getPathDetail Parent: $parentType, $STName1 -> $accessor; objects:\n";
	if ($STName2) {
		$targetType = $STName2;
		$targetField = $STName2;
		@objs = $factory->findObjects('@'.$STName1,$accessor=>$root);
	} else {
		# The object is not a map, so its the target
		$targetType = $STName1;
		$targetField = $STName1;
		@objs = ($root->$STName1());
	}
#  print STDERR Dumper(\@objs);
#  print STDERR "\n";

	# start a new list
	$html .= "<ul>";
    if (scalar(@objs) > 0) {
	# if i have any objs

	    foreach my $obj (@objs) {
	    	if ($STName2) {
	    		# the object is a map, so we get the target by calling the targetField
	    		$target = $obj->$targetField;
	    	} else {
	    		$target = $obj;
	    	}
	    	
#      print STDERR "targetType: $targetType, SEName: $SEName object: $obj\n";
			# get the external URL
			if ($target) {
				my $url = $self->getObjURL($target,$targetType,$SEName);
				$html .= "<li> $targetField: $url</li>";
				# recurse to populate the next level. Pass the array
				# as a whole so it will get copied.
				$html .= $self->getPathDetail($targetType,$target,@pathTypes) if scalar (@pathTypes);
			} else {
				$html .= "<li> $targetField: ** undefined **</li>";
			}
	    }
	} else  {
		# if I found no objects.
		$html .=  "<li>No ${targetField}s found</li>";
    }
	# end the list.
	$html .= "</ul>";
    return $html;
}




=head1 getClassificationDetails

    $self->getClassificationDetails($image,$tmpl_data);
    get classifications details for each category group, and populate
    template.


=cut

sub getClassificationDetails  {
    my $self  = shift;
    my ($image,$tmpl_data) = @_;

    my $classifications = 
	OME::Tasks::CategoryManager->getImageClassification($image);
    if ($classifications) {
	my @annotations;
	my $annotation;
	if (ref($classifications) eq 'ARRAY') {
	    foreach my $class (@$classifications) {
		$annotation = $self->getClassificationDetail($class);
		push (@annotations,$annotation);
	    }
	}
	else { 
	    $annotation =
		$self->getClassificationDetail($classifications);
	    push (@annotations,$annotation);
	}

	$tmpl_data->{categoryAnnotations} = \@annotations;
    }
}

=head1 getClassificationDetail

    $self->getClassificationDetail($classification);

    get the detail for a specific classification

=cut

sub getClassificationDetail {

    my $self=shift;
    my $q=$self->CGI();
    my ($classification) = @_;
    my %detail;

    my $group = $classification->Category()->CategoryGroup();

    my $groupURL = $q->a({ href=> $self->getObjDetailURL($group) },
			 $group->Name());
    my $cat = $classification->Category();
    my $catURL = $q->a({ href=> $self->getObjDetailURL($cat)},
			 $cat->Name);

    $detail{catGroup} = $groupURL;
    $detail{catValue} = $catURL;
    return \%detail;
}


=head1 getPublicationDetails

    $self->getPublicationDetails($image,$tmpl_data);
    get details for all associated publications


=cut

sub getPublicationDetails  {
    my $self  = shift;
    my ($image,$tmpl_data) = @_;

    # get the image publications.
    my @publicationLinks = $image->ImagePublicationList(); 
    if (scalar(@publicationLinks) > 0) {
	my @publications = map { $_->Publication} @publicationLinks;
	my $pubList = "<Ul>";
	$tmpl_data->{'publications/render-item_list'} =  
	    $self->Renderer()->renderArray(\@publications,'item_list',
					   {type => '@Publication'});
    }
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
    my ($target,$type,$field) = @_;

    my $session = $self->Session();
    my $factory = $session->Factory();
    my $q  = $self->CGI();

    my $name = $target->$field();
    my $html = $name;
    my $extLink = $self->getExternalLinkText($q,$type,$target);
    if ($extLink) {
	$html .= " " . $extLink;
    }
    return $html;
}
    
1;
