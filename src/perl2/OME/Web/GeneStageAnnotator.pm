# OME/Web/GeneStageAnnotator.pm

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
# Written by:    Harry Hochheiser <hsh@nih.gov>, based on code in
#                CG_Annotator.pm by Arpun Nagaraja <arpun@mit.edu>
#
# NOTE: This code is very similar to code found in
# ImageDetailAnnotator. There's a substantial amount of code
# overlap. Eventually, a clean subclassing scenario should be developed.
#-------------------------------------------------------------------------------


package OME::Web::GeneStageAnnotator;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;
use OME::Tasks::ImageManager;

use base qw(OME::Web);

sub getPageTitle {
    return "OME: Annotate Images";
}

{
    my $menu_text = "Annotate Images";
    sub getMenuText { return $menu_text }
}

=head1 getPageBody

Load up the correct annotation template, save any annotations, allow
    for selection of images, show images that have been annotated and 
    have not yet been annotated.

    The assumption here is that we're running off of a template
    that has a variable named
    DetailSTs.load/-[ST1:MapST1,ST2:MapST2...]

    where the STn:MapSTn pairs indicate the STs that will be used to
    annotate images. For each pair, the first elemen will be an ST
    indicating some data with which we will want each images to be
    associated. 

    The MapST in each pair will be a simple mapping between the
    specified ST and images.

    Note that this does not account for ST instances that map directly
    to images - image granularity STs. This functionality is not
    currently supported. 
    
=cut

sub getPageBody {
    my $self = shift ;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my %tmpl_data;

    # Load the correct template and make sure the URL still carries the template
    # name.

    my $tmpl_dir=$self->actionTemplateDir('custom');
    my $which_tmpl = $q->url_param('Template'); 

    my $referer = $q->referer();
    my $url = $self->pageURL('OME::Web::GeneStageAnnotator');
    if ($referer && $referer =~ m/Template=(.+)$/ && !($which_tmpl)) {
	$which_tmpl = $1;
	$which_tmpl =~ s/%20/ /;
	return ('REDIRECT', $self->redirect($url.'&Template='.$which_tmpl));
    }
    $which_tmpl =~ s/%20/ /;
    my $tmpl;

    my $tmpl_Attr  =  $factory->findObject( '@AnnotationTemplate', 
					    Name => $which_tmpl )
	or die "Could not find AnnotationTemplate with name $which_tmpl";
    $tmpl = HTML::Template->new( filename => $tmpl_Attr->Template(),
				 path => $tmpl_dir,
				 case_sensitive => 1 );

    $tmpl_data{'template'}=$which_tmpl;
    
    # Load the requested category groups
    my @parameter_names = $tmpl->param();

    # find the STs and the mapping STs to be used
    my $cgST =
    $factory->findObject('OME::SemanticType',{name=>'CategoryGroup'});

    my ($sts,$maps) = $self->findSTs(\@parameter_names);

    # get the category groups
    my($category_groups) = $self->findCategoryGroups($cgST,\@parameter_names);

    # display images
    my ($currentImage,$imageToAnnotate) =
	$self->populateImageDetails(\%tmpl_data, $tmpl);

        # annnotate if they hit 'save and next'
    if ($q->param('SaveAndNext') eq 'SaveAndNext')  {
		$self->annotateWithSTs($imageToAnnotate,$sts,$maps);
		$self->annotateWithCGs($imageToAnnotate,$category_groups);
		# Save image comments as a text annotation
		if( $q->param( 'comments' ) ) {
			my $currentAnnotation = OME::Tasks::ImageManager->
				getCurrentAnnotation( $imageToAnnotate );
			if( (not defined $currentAnnotation ) ||
				( $currentAnnotation->Content ne $q->param( 'comments' ) ) 
			  ) {
				OME::Tasks::ImageManager->writeAnnotation(
					$imageToAnnotate, { Content => $q->param( 'comments' ) }
				);
				$session->commitTransaction();
			}
		}
    }
    elsif ($q->param('AddToCG') eq 'AddToCG') {
	$self->addCategories($category_groups);
    }
    elsif ($q->param('CreateProbe') eq 'CreateProbe') {
	# create a new probe if needed.
	$self->createProbe(\%tmpl_data);
    }


    # display annotation types - first STs
    if (grep {$_ eq 'st.loop'} @parameter_names) {
	$self->populateAnnotationSTs($currentImage,\%tmpl_data,$sts,$maps,
	    \@parameter_names);
    }
    # and then category groups
    if (grep {$_ eq 'cg.loop'} @parameter_names) {
	$self->populateAnnotationGroups($currentImage,\%tmpl_data,$category_groups);
    }

    # add fields for creating a new probe.
    $self->populateProbeFields(\%tmpl_data,\@parameter_names);

    # populate the template
    $tmpl->param( %tmpl_data );


    my $html =
	$q->startform( { -name => 'primary' } );
    $html .= $tmpl->output() if ($tmpl);
    $html .= $q->endform();

    return ('HTML',$html);	
}

=head1 findSTs
    
    As mentioned above, the annotation STs are fond in a template
    variable of the form:
    DetailSTs.load/-[ST1:MapST1,ST2:MapST2...]

    This procedure parses this variable, returning 2 values:
    a list of the actual ST objects, and a hash mapping
    ST names to mapping ST objects.

=cut

sub findSTs {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $parameter_names = shift;

    my @stlist;

    my @found_params = grep( m/DetailSTs\.load/, @$parameter_names );
    my $request = $found_params[0];
    my @ids;
    if( $request =~ m/\/-\[(.*)\]/ ) {
	@stlist = split(/,/, $1);
    } else { 
	die "couldn't parse $request";
    }
    
    my  @sts;
    my %maps;


    foreach my $stEntry (@stlist) {
	# each entry has form type:mapType
	my ($st,$mapST) = split(/:/,$stEntry);
	
	my $semantic_type = $self->loadST($st);
	my $map_type = $self->loadST($mapST);

	push(@sts,$semantic_type);
	
	$maps{$semantic_type->name()} = $map_type;
    }
    return (\@sts,\%maps);
}


=head1 loadST

loads a given ST 


=cut
sub loadST  {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $st = shift;

    my $semantic_type =  $st;
    if (!ref($semantic_type)) {
	my $name = $semantic_type;
	$semantic_type= $factory->findObject('OME::SemanticType',
					     {name => $name});
	die "couldn't load SemanticType : $name" unless 
	    defined $semantic_type;
    } elsif (UNIVERSAL::isa($semantic_type,'OME::SemanticType')) {
	# Excellent, this is just what we need
    } else {
	die "findSTs needs a semantic type: $st is no good";
    }
    return $semantic_type;
}

=head1 findCategoryGroups

    Find and load category groups as given in template
    Category groups are listed in a template variable of the form..
    "CategoryGroup.load/id=[..]", where one or more category
    groups are specified in between the brackets. Category groups can
    be specified by name or by ID.

=cut

sub findCategoryGroups {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $cgST = shift;
    my $parameter_names = shift;

    my (@cat_params) = grep(/CategoryGroup\.load/,@$parameter_names);
    return [] unless( scalar( @cat_params ) > 0);
    my $request = $cat_params[0];

    my @cats;
    if ($request =~ m/\/id=\[(.*)\]/) {
	@cats = split(/,/,$1);
    } else {
	die "couldn't parse $request";
    }

    my @cgs;
    foreach my $cat (@cats) {
	my $cg;
	if ($cat =~ /\d+/)  {
	    $cg =$factory->loadObject('@CategoryGroup', $cat);
	}
	else {
	    my $iter = $factory->findAttributes($cgST,{Name=> $cat});
	    $cg = $iter->next();
	}
	if ($cg) {
	    push(@cgs,$cg);
	}
    }
    return \@cgs;
}


=head1 annotateWithSTs

    Saves ST annotations associated with the current image.

=cut
sub annotateWithSTs {
    my $self = shift;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($currentImage,$sts,$maps) = @_;

    # for each incoming st
    foreach my $st (@$sts) {
	#find the field name specified in the template
	my $stAnnotationFieldName = "st".$st->id;
	
	# Get incoming category ids from CGI parameters
	# get value of it.
	my $attributeID = $q->param( $stAnnotationFieldName );
	# Load attribute object?
	if( $attributeID && $attributeID ne '' ) {
	    my $attribute = $factory->loadAttribute( $st, $attributeID )
		or die "Couldn't load Attribute (id=$attributeID)";

	    ####create a new association between the image id 
	    ### and the attribute_id.
	    # find the apppropriate ST
	    my $assnSt = $maps->{$st->name()};
	    #create the annotation
	    my ($mex,$attrs) =
		OME::Tasks::AnnotationManager->annotateImage(
		    $currentImage,$assnSt,
		    { $st->name() => $attribute});
	}
    }
    #################
    # commit the DB transaction
    $session->commitTransaction();
}

=head2 annotateWithCGs
    
    annotate with images with CategoryGroups.
=cut

sub annotateWithCGs {
    
    my $self = shift;
    my $q = $self->CGI();
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($currentImage,$categoryGroups) = @_;


    my @categoryNames = map("FromCG".$_->id,@$categoryGroups);
    
    foreach my $categoryName (@categoryNames) {
	# get incoming from CGI
	my $categoryID = $q->param($categoryName);
	if ($categoryID && $categoryID ne '') {
	    my    $category=$factory->loadObject('@Category',$categoryID);
	    OME::Tasks::CategoryManager->classifyImage($currentImage,$category);
	}
    }
    #################
    # commit the DB transaction
    $session->commitTransaction();

}



=head2 populateImageDetails

    display image to annotate, images left to annotate, and those
    already annotated
=cut

sub populateImageDetails {
    my $self = shift ;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($tmpl_data, $tmpl) = @_;
    my @images;
    my @completed_images;

    # Get the list of ID's that are left to annotate
    if (defined $q->param('images_to_annotate') &&
	$q->param('images_to_annotate') ne 'none') {
	if ($q->param('images_to_annotate') ne "") {
	    my $concatenated_image_ids = $q->param( 'images_to_annotate' );
	    
	    # sort by name
	    my @unsorted_image_ids = split( /,/, $concatenated_image_ids );
	    my @unsorted_images = map  $factory->loadObject('OME::Image', $_) ,	@unsorted_image_ids;
	    @images = sort ( {$a->name cmp $b->name} @unsorted_images);
	}  
    }

    
    # completed images
    if (defined $q->param('images_completed') &&
	$q->param('images_completed') ne "") {
	my $completedList = $q->param('images_completed');
	my @completed_ids  =split( /,/, $completedList);
	my @unsorted_completed = map  
	    $factory->loadObject('OME::Image', $_) ,
	    @completed_ids;
	@completed_images = sort ( {$a->name cmp $b->name} @unsorted_completed);
    }

    my @image_thumbs;
    my $currentImageID;
    
    # if no image is displayed, the ID you need is in the array
    my ( $currentImage, $imageToAnnotate);
    if (defined $q->param('currentImageID') &&
	$q->param( 'currentImageID' ) eq '') { 
	$currentImage = shift(@images);
	$currentImageID = $currentImage->ID if (defined $currentImage);
    }
    else { 
	$currentImageID = $q->param( 'currentImageID' ); 
	$currentImage = $factory->loadObject( 'OME::Image', $currentImageID);
    }
    
    # If they want to annotate this image, get the next ID and load that image
    if ($q->param( 'SaveAndNext' )) {
	# if an image had been specified
	if ($q->param('currentImageID') ne '') {
	    # push it onto completed
	    push (@completed_images,$currentImage);
	}
	# save the image to be annotated. The calling function will perform the actual annotation.
    $imageToAnnotate = $currentImage;
	$currentImage = shift(@images);
	$currentImageID = $currentImage->ID if (defined $currentImage);
    }
    
    # Render the image. Allow the template to specify the rendering mode using the syntax:
    # <TMPL_VAR NAME=current_image/render-RENDER_MODE>
	my $field_requests = $self->Renderer()->parse_tmpl_fields( [ $tmpl->param() ] );
	my $field = 'current_image';
	if( $field_requests->{ $field } ) {
		foreach my $request ( @{ $field_requests->{ $field } } ) {
			my $request_string = $request->{ 'request_string' };
			my $render_mode = ( $request->{ render } or 'ref' );
			$tmpl_data->{ $request_string } = $self->Renderer()->render( $currentImage, $render_mode );
		}
	} else {
		# legacy support.
		$tmpl_data->{ 'image_large' } = $self->Renderer()->render( $currentImage, 'large');
	}
    
    # set the ID of the current image on display
    $tmpl_data->{ 'current_image_id' } = $currentImageID;
    
    
     $tmpl_data->{ 'image_thumbs' } = 
	 $self->Renderer()->renderArray(\@images, 'bare_ref_mass', { type => 'OME::Image' });

    # populate hidden field indicating what to do next.
    if (scalar(@images) > 0) {
	my @image_ids = map $_->ID , @images;
	$tmpl_data->{ 'images_to_annotate' } = join( ',', @image_ids);
	# list of ID's to annotate
    }
    else {
	$tmpl_data->{'images_to_annotate'} = 'none';
    }

    # display images that have been annotated.
    $tmpl_data->{'annotated_image_thumbs'}  = 
	$self->Renderer()->renderArray(\@completed_images, 'bare_ref_mass', 
				       { type => 'OME::Image' });
    my @completed_ids = map $_->ID,@completed_images;
    $tmpl_data->{'images_completed'} = join(',',@completed_ids);
    return( $currentImage, $imageToAnnotate);
}

=head2 populateAnnotationSTs

Popuate the menus with the various annotation types. For each ST that
    we are using, add an  entry to the St.loop. Each entry in the
    ST.loop variable will have a select name of stxx, where xx is the
    ID of the ST (given by template var st.id), a label given by
    template var st.Name, and a pull down option list given by the 
    st.val/render-list_of_options field.

    There are three possibilities for the default value. In order of
    preference :

    1) if a new values has been created, use it.
    2) If the image already has the a defined value for the annotation
    ST,  use it. 
    3) If a value from the annotation of the previous image is
    available, use it.
    annotation.

    If multiple annotations of a given type exist, the first one found
    will be used as the default.


=cut
sub populateAnnotationSTs {
    my $self = shift ;
    my ($currentImage,$tmpl_data,$sts,$maps,$parameter_names) = @_;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    

    # get a hash of all of the "new values specified in the form.
    # for each input of the form "NewXXX", return a hash with key
    # being the type of thing being created (XXX) and the value being
    # the new value.
    # ie, if "NewProbe" has value ABCED , this $hash{Probe} = "ABCED"
    my $newVals = $self->getNewValues($tmpl_data,$parameter_names);


    my @st_loop_data;
    foreach my $st (@$sts) {
	my $label = "st".$st->id();
	my $stVal = $q->param( $label );
	my %st_data;


	my @stValList = $factory->findObjects($st);

	my $stName =$st->name();
        # get the map between image and the st.: ie, ImageProbe
	my $map = $maps->{$stName}->name();

	# the accessor for the list of instances of the ST - ImageProbeList.
	my $accessor = $map."List" ;

	if ($currentImage) {
	    # if we have a value for that map,
	    my  $currentVals = $currentImage->$accessor();
	    # find first entry
	    my $mapVal = $currentVals->next();
	    if ($mapVal) {
		# and get the instance f the st
		my $currentVal = $mapVal->$stName();
		# to make it the default value in this form. 
		$stVal = $currentVal->id();
	    }
	}
	# if there is a new value for this st, it becomes the 
	# default.
	if ($newVals->{$stName}) {
	    my $newVal = $newVals->{$stName};
	    $stVal = $newVal;
	}

	
	# If the template is using a loop, the variable names will be different
	$st_data{ 'st.Name' } = $self->Renderer()->render( $st, 'ref');
	$st_data{ "st.id" } = $st->id();
	$st_data{ "st.val/render-list_of_options" } = 
	    $self->Renderer()->renderArray( 
		\@stValList,'list_of_options', { default_value => $stVal, type => $st }
	    );
	push( @st_loop_data, \%st_data );
    }
    
    $tmpl_data->{ 'st.loop' } = \@st_loop_data;
}

=head1 getNewValues

   find the values in the CGI that start with "New". For each of
   these, take the remainder of the CGI name and put it in a hash with
   the  value for that param in the CGI.

=cut

sub getNewValues {
    my $self= shift;
    my ($tmpl_data,$parameter_names) = @_;
    my $q = $self->CGI();
    my %newVals;

    my @params = $q->param();

    my @newParams = grep ( m/New.*/,@$parameter_names);
    foreach my $param (@newParams) {
	$param =~ /New(.*)/;
	$newVals{$1} = $tmpl_data->{$param};
    }
    return \%newVals;

}
=head1 populateAnnotationGroups

   Populate the fields for annotation by catgory group.
    Find the category groups that were requested and populate the
    pull-downs and related fields.

=cut
sub populateAnnotationGroups {

    my $self = shift;
    my ($currentImage,$tmpl_data,$category_groups) = @_;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();

    my @cg_loop_data;


    foreach my $cg (@$category_groups) {
	my $label = "FromCG".$cg->id;
	# get category id if one is specified in form
	my $categoryID = $q->param($label);
	my %cg_data;	
	my @categoryList = $cg->CategoryList();
	my $classification = OME::Tasks::CategoryManager->
	    getImageClassification($currentImage,$cg);
	$categoryID = $classification->Category->ID if ($classification);

	$cg_data{ 'cg.Name' } = $self->Renderer()->render( $cg, 'ref');
	$cg_data{ "cg.id" } = $cg->id();
	$cg_data{ "cg.cat/render-list_of_options" } = $self->Renderer()->renderArray( 
	    \@categoryList, 
	    'list_of_options', 
	    { default_value => $categoryID, type => '@Category' }
	    );
	push (@cg_loop_data,\%cg_data);
    }
    $tmpl_data->{'cg.loop'} = \@cg_loop_data;
}

=head1 addCategories

    When requested, add categories

=cut

sub addCategories {

    my $self =shift;
    my $categoryGroups = shift;
    my $q = $self->CGI() ;
    my $session= $self->Session();

    my @addCategoryNames =map
	("CategoryAddTo".$_->id,@$categoryGroups);

    foreach my $categoryGroupName (@addCategoryNames) {
	my $categoryToAdd = $q->param($categoryGroupName);
	$categoryGroupName =~ m/CategoryAddTo(\d+)/;
	my $categoryGroupID=$1;  # get the id of the category group
	my %data_hash =	( 'Name' => $categoryToAdd, 
			  'Description' => undef,
			  'CategoryGroup' => $categoryGroupID
	    );
	if ($categoryToAdd && $categoryToAdd ne '') {
	    OME::Tasks::AnnotationManager->annotateGlobal('Category',\%data_hash);
	}
    }
    $session->commitTransaction();
}


=head1 populateProbeFields 

    Populate the pull-downs for associating a probe type and a gene
    name with a new probe.

=cut

sub populateProbeFields {
    my $self=shift;
    my ($tmpl_data,$parameter_names)= @_;
    
    if (grep {$_ eq 'Gene'} @$parameter_names) {
	$tmpl_data->{'Gene'} = $self->populateProbePulldown('Gene');
    }
    if (grep {$_ eq 'ProbeType'} @$parameter_names) {
	$tmpl_data->{'ProbeType'} =
	    $self->populateProbePulldown('ProbeType');
    }
}
=head1 populateProbePulldown 

    populate choices for new probe
=cut

sub populateProbePulldown {

    my $self = shift;
    my $type = shift;
    my $session = $self->Session();
    my $factory = $session->Factory();

    my $stName = "@".$type;
    my @objs = $factory->findObjects($stName,{ __order =>
						   ['Name']});
    my $st = $factory->findObject('OME::SemanticType', {name=>$type});
    my $data = $self->Renderer->renderArray(\@objs,
					    'list_of_options',
					    {type => $st});
    return $data;
}

=head1 createProbe 

create a probe when warranted
=cut

sub createProbe {
    my $self = shift;
    my $tmpl_data = shift;
    my $q = $self->CGI();
    my $session= $self->Session();
    my $factory = $session->Factory();

    my $pName = $q->param('ProbeName');
    my $gene = $q->param('Gene');
    my $pType = $q->param('ProbeType');
  
    if ($pName eq "") {
	$tmpl_data->{'Results'} = "Probe name was not specified";
	return;
    }

    my $found = $factory->findObject('@Probe',{Name=>$pName});
    if ($found) {
	$tmpl_data->{'Results'} = "Probe $pName already exists.";
    }
    else {
	# get a mex
	my $module = $factory->findObject( 'OME::Module', 
			   name => 'Global import' );
	my $mex = OME::Tasks::ModuleExecutionManager->createMEX($module,'G' );

	# create the attributes
	my $probe = $factory->newAttribute('Probe',undef,$mex,
					   {Name=>$pName,Type=>$pType});
	my $pg = $factory->newAttribute('ProbeGene',undef,$mex,
					{Probe=>$probe,Gene=>$gene});
	# finish the transaction.
	$mex->status('FINISHED');
	$mex->storeObject();
	$session->commitTransaction();

	# put results in to template.
	$tmpl_data->{'Results'} = "Probe $pName Created!";
	$tmpl_data->{'NewProbe'} = $probe->ID;
    }
}
1;
