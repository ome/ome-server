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

    # annnotate
    $self->annotateImages($sts,$maps);

    # display images
    my $currentImageID = $self->populateImageDetails(\%tmpl_data);
    
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
    my $tmpl_data = shift;

    # Get the list of ID's that are left to annotate
    my $concatenated_image_ids = $q->param( 'images_to_annotate' );
    
    # sort by name
    my @unsorted_image_ids = split( /,/, $concatenated_image_ids );
    my @image_ids = sort( { ($factory->loadObject( 'OME::Image', $a))->name cmp ($factory->loadObject( 'OME::Image', $b))->name } @unsorted_image_ids );
    my @image_thumbs;
    my $currentImageID;
    
    # if no image is displayed, the ID you need is in the array
    if ($q->param( 'currentImageID' ) eq '') { $currentImageID = shift(@image_ids); }
    else { $currentImageID = $q->param( 'currentImageID' ); }
    
    my $image = $factory->loadObject( 'OME::Image', $currentImageID);
    
    # If they want to annotate this image, get the next ID and load that image
    if ($q->param( 'SaveAndNext' )) {
	$currentImageID = shift(@image_ids);
	$image = $factory->loadObject( 'OME::Image', $currentImageID);
    }
    $tmpl_data->{ 'image_large' } = $self->Renderer()->render( $image, 'large');
    
    # set the ID of the current image on display
    $tmpl_data->{ 'current_image_id' } = $currentImageID;
    
    # Update the list of images left to annotate
    foreach my $image_id ( @image_ids ) {
	push( @image_thumbs, $factory->loadObject( 'OME::Image', $image_id ) );
    }
    
    $tmpl_data->{ 'image_thumbs' } = $self->Renderer()->renderArray( \@image_thumbs, 'bare_ref_mass', { type => 'OME::Image' });
    $tmpl_data->{ 'image_id_list' } = join( ',', @image_ids); # list of ID's to annotate

    return $currentImageID;
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
	    # this is ok for now!!!!1
	    # If there's actually an image there.
	    if ($currentImage) {
		$st_data{ 'st.classification' } = "Classified as <b>$stVal</b>"
		    if $stVal;
		$st_data{ 'st.classification' } = "<i>Unclassified</i>"
		    unless $stVal;
	    }
	    push( @st_loop_data, \%st_data );
	} 
    }
    
    $tmpl_data->{ 'st.loop' } = \@st_loop_data
	if( $use_st_loop );
}

1;
