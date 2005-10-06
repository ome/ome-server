# OME/Web/ImageDetailAnnotator.pm

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
# Written by:    Arpun Nagaraja <arpun@mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Web::ImageDetailAnnotator;

use strict;
use Carp;
use Carp 'cluck';
use vars qw($VERSION);
use OME::SessionManager;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;

use base qw(OME::Web);

sub getPageTitle {
    return "OME: Annotate Images";
}

{
    my $menu_text = "Annotate Images";
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
    my $tmpl_dir = $self->actionTemplateDir();
    my $tmpl =
	HTML::Template->new(filename=>"ImageDetailAnnotator.tmpl",
			    path=>$tmpl_dir,case_sensitive=>1);
    
    
    # Load the requested category groups
    my @parameter_names = $tmpl->param();
    my ($sts,$maps) = $self->findSTs(\@parameter_names);

    $self->selectDataset();
    # annnotate
    $self->annotateImages($sts,$maps);

    # display images
    my $currentImageID = $self->populateImageDetails(\%tmpl_data);

    # populate dataset choices
    $self->populateDatasets(\%tmpl_data);

    # display annotation types
    $self->populateAnnotationTypes($currentImageID,
				   \%tmpl_data,\@parameter_names,$sts);
    # populate the template
    $tmpl->param( %tmpl_data );


    my $html =
	$q->startform( { -name => 'primary' } );
    $html .= $tmpl->output() if ($tmpl);
    $html .= $q->endform();

    return ('HTML',$html);	
}

sub findSTs {
    my $self = shift;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my $parameter_names = shift;

    my @stlist;

    my @found_params = grep( m/\.load/, @$parameter_names );
    my $request = $found_params[0];
    my $concatenated_request;
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
	print STDERR "associating map type " . $map_type->name() . " with " .
	    $semantic_type->name() . "\n";
	
	$maps{$semantic_type->name()} = $map_type;
    }
    return (\@sts,\%maps);
}

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
	print STDERR "found ST " . $semantic_type->name() . "\n";
    } elsif (UNIVERSAL::isa($semantic_type,'OME::SemanticType')) {
	# Excellent, this is just what we need
    } else {
	die "findSTs needs a semantic type: $st is no good";
    }
    return $semantic_type;
}

sub selectDataset() {
    my $self = shift;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    
    if ($q->param('ChangeDataset')) {
	my $dataset  = $q->param('dataset');
	$session->dataset($dataset);
    }

}
sub annotateImages {
    my $self = shift;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($sts,$maps) = @_;

    # Classify an image if they click Save & Next
    if ($q->param( 'SaveAndNext' )) {
	# for each incoming category - FromCG.id (in template)
	foreach my $st (@$sts) {
	    print STDERR "ST is  $st\n";
	    my $stAnnotationFieldName = "st".$st->id;

	    # Get incoming category ids from CGI parameters
	    # get value of it.
	    my $attributeID = $q->param( $stAnnotationFieldName );
	    # Load attribute object?
	    if( $attributeID && $attributeID ne '' ) {

		my $attribute = $factory->loadAttribute( $st, $attributeID )
		    or die "Couldn't load Attribute (id=$attributeID)";
		# Create new 'Classification' attributes on image
		my $currentImage = $factory->loadObject( 'OME::Image',
				 $q->param( 'currentImageID' ));

		####create a new association between the image id 
		### and the attribute_id.
		
		print STDERR "looking for association with  "
		    .  $st->name() . "\n";

		my $assnSt = $maps->{$st->name()};
		print STDERR "loading association ST: " .
		    $assnSt->name() . "\n";

		print STDERR "annotating type with " . $assnSt->name()
		              . "\n";
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
}

sub populateImageDetails {
    my $self = shift ;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    my ($tmpl_data) = @_;
    my @images;
    my @completed_images;

    # Get the list of ID's that are left to annotate
    if ($q->param('images_to_annotate') ne 'none') {
	if ($q->param('images_to_annotate') ne "") {
	    my $concatenated_image_ids = $q->param( 'images_to_annotate' );
	    
	    # sort by name
	    my @unsorted_image_ids = split( /,/, $concatenated_image_ids );
	    my @unsorted_images = map  $factory->loadObject('OME::Image', $_) ,	@unsorted_image_ids;
	    @images = sort ( {$a->name cmp $b->name} @unsorted_images);
	} else { 
	    my $d = $session->dataset;
	    @images = $d->images;
	}
    }

    
    # completed images
    if ($q->param('images_completed') ne "") {
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
    my $image;
    if ($q->param( 'currentImageID' ) eq '') { 
	$image = shift(@images);
	$currentImageID = $image->ID if (defined $image);
    }
    else { 
	$currentImageID = $q->param( 'currentImageID' ); 
	$image = $factory->loadObject( 'OME::Image', $currentImageID);
    }
    
    # If they want to annotate this image, get the next ID and load that image
    if ($q->param( 'SaveAndNext' )) {
	# if an image had been specified
	if ($q->param('currentImageID') ne '') {
	    # push it onto completed
	    push (@completed_images,$image);
	}
	$image = shift(@images);
	$currentImageID = $image->ID if (defined $image);
    }
    $tmpl_data->{ 'image_large' } = $self->Renderer()->render( $image, 'large');
    
    # set the ID of the current image on display
    $tmpl_data->{ 'current_image_id' } = $currentImageID;
    
     $tmpl_data->{ 'image_thumbs' } = 
	 $self->Renderer()->renderArray(\@images, 'bare_ref_mass', { type => 'OME::Image' });

    if (scalar(@images) > 0) {
	my @image_ids = map $_->ID , @images;
	$tmpl_data->{ 'images_to_annotate' } = join( ',', @image_ids);
	# list of ID's to annotate
    }
    else {
	$tmpl_data->{'images_to_annotate'} = 'none';
    }


    $tmpl_data->{'annotated_image_thumbs'}  = 
	$self->Renderer()->renderArray(\@completed_images, 'bare_ref_mass', 
				       { type => 'OME::Image' });
    my @completed_ids = map $_->ID,@completed_images;
    $tmpl_data->{'images_completed'} = join(',',@completed_ids);
    return $currentImageID;
}

sub populateDatasets() {
    my $self= shift;
    my $session = $self->Session();
    my $dataset = $session->dataset;
    my $factory = $session->Factory();
    my $tmpl_data = shift;

    print STDERR "current dataset is " . $dataset->name . "\n";
    my @dataset_list = $factory->findObjects("OME::Dataset",
	{ owner => $session->User() });
    #pull out those things that are importset..
    my @dataset_choices = grep {$_->name() ne 'ImportSet'} @dataset_list;
    $tmpl_data->{'datasets'} = 
	$self->Renderer()->renderArray(
	    \@dataset_choices ,'list_of_options',{default_value =>   $dataset->ID});
}

sub populateAnnotationTypes {
    my $self = shift ;
    my ($currentImageID,$tmpl_data,$parameter_names,$sts) = @_;
    my $q = $self->CGI() ;
    my $session= $self->Session();
    my $factory = $session->Factory();
    

    # Render each ST and values
    my @st_loop_data;
    my $use_st_loop = grep{ $_ eq 'st.loop'} @$parameter_names;
    my $cntr = 1;
    foreach my $st (@$sts) {
	my $label = "st".$st->id();
	my $stVal = $q->param( $label );
	my %st_data;

	# hmm. what is this for?
	my @stValList = $factory->findObjects($st);

	my $currentImage = $factory->loadObject( 'OME::Image',$currentImageID);

	
	# If the template is using a loop, the variable names will be different
	if( $use_st_loop ) {
	    $st_data{ 'st.Name' } = $self->Renderer()->render( $st, 'ref');
	    $st_data{ "st.id" } = $st->id();
	    print STDERR "rendering val list. st is " .$st->name .	"\n";
	    print STDERR "# of vals.. " . scalar(@stValList) . "\n";
	    $st_data{ "st.val/render-list_of_options" } = 
		$self->Renderer()->renderArray( 
		\@stValList,'list_of_options', { default_value => $stVal, type => $st }
		);
	    push( @st_loop_data, \%st_data );
	} 
    }
    
    $tmpl_data->{ 'st.loop' } = \@st_loop_data
	if( $use_st_loop );
}

1;
