# OME/Web/DBObjDetail/__OME_Dataset.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DBObjDetail::__OME_Dataset;

=pod

=head1 NAME

OME::Web::DBObjDetail::__OME_Dataset

=head1 DESCRIPTION

_takeAction() sets Session->dataset to the dataset displayed and
implements adding images to the dataset and
implements editing name or description and.

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::DatasetManager;
use OME::Tasks::CategoryManager;
use OME::Web::DBObjDetail::__Category;

use Log::Agent;
use base qw(OME::Web::DBObjDetail);

sub getPageBody {
	my $self = shift;
	my $html = ( $self->_takeAction( ) || '' );
	my $q = $self->CGI();
	my $dataset = $self->_loadObject();
	my $factory = $self->Session()->Factory();

	my $tmpl_path = $self->Renderer()->_findTemplate( 'OME::Dataset', 'detail' );
	my $tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );
	my %tmpl_data = $self->Renderer()->_populate_object_in_template( $dataset, $tmpl );
	
	my @hidden_fields;
	my %cgi_params = $q->Vars();
	
	my %unique_cg_hash;
	if (exists $cgi_params{cg_list}) {
		my @cg_ids = $q->param( 'cg_list' );
		my @cgs = $factory->findObjects ('@CategoryGroup', id => ['in',\@cg_ids]);
		%unique_cg_hash = map
			{ $_->id() => $_ }
			@cgs;
	} else {
		my @cgs = $factory->findObjects ('@CategoryGroup');
		%unique_cg_hash = map
			{ $_->id => $_ }
			@cgs;
	}

	push (@hidden_fields,$q->hidden ({
		-name => 'cg_list',
	# Making -default an empty list causes the parameter to be not set!
		-default => keys %unique_cg_hash ? [keys %unique_cg_hash] : [0]
		}));


	# If the user selected another CG with the Search or Create link,
	# then include that in the drop down list of CGs
	my $cg_id = $q->param( 'selected_cg' );
	if( ( defined $cg_id ) && 
	    ( $cg_id ne '' ) &&
		( not exists $unique_cg_hash{ $cg_id } ) ) {
		my $cg = $factory->loadObject( '@CategoryGroup', $cg_id )
			or die "Couldn't load CategoryGroup id='$cg_id'";
		$unique_cg_hash{ $cg_id } = $cg if $cg;
	}
	$cg_id = $q->param( 'group_images_by_cg' )
		unless $cg_id;

	# actually make the popup list
	my @cg_list = sort{ $a->Name cmp $b->Name } values %unique_cg_hash ;
	$tmpl_data{ categories_used } = (
		@cg_list ?
		$q->popup_menu(
			-name     => 'group_images_by_cg',
			'-values' => ['', map( $_->id, @cg_list) ],
			-default  => ( $cg_id || '' ),
			-override => 1,
			-labels   => { 
				'' => "(no selection)",
				( map { $_->id => $_->Name } @cg_list )
			},
			-onChange => "javascript: document.forms[0].submit();"
		) : '(No CategoryGroups are used by this Dataset)'
	);

	# Use selected CategoryGroup (if there is one) to group images.
	if( $cg_id and exists $unique_cg_hash{$cg_id}) {
		my $cg = $unique_cg_hash{$cg_id};
		my %image_classifications;
		my $image_iter = $dataset->images();
		my $image;
		while ($image = $image_iter->next()) {
			my $classification = OME::Tasks::CategoryManager->
				getImageClassification( $image, $cg );
			# Watch out for multiple classifications
			if( ref( $classification ) eq 'ARRAY' ) {
				$html .= "<font color='red'>Image ".$self->Renderer()->render( $image, 'ref' ).
					" has more than one classification under CategoryGroup ".
					$self->Renderer()->render( $cg, 'ref' ).
					". This display can only handle one classification per image.</font>";
				# Flag for "can't display classification"
				%image_classifications = ();
				last;
			# This image hasn't been classified
			} elsif( not defined $classification ) {
				push( @{ $image_classifications{0} }, $image );
			} else {
				push( @{ $image_classifications{ $classification->Category->id } }, $image );
			}
		}
		# %image_classifications works as a "can't display classification" flag.
		# If 'selected_category_group' isn't set, the template will
		# revert to a big list of images. So only set it if we can
		# handle this category group.
		if( %image_classifications ) {
			$tmpl_data{ selected_category_group_ref } = $self->Renderer()->render( $cg, 'ref' );
			my @category_list = sort( { $a->Name cmp $b->Name } $cg->CategoryList() );
			$tmpl_data{ available_categories } = $q->popup_menu(
				-name     => 'category_to_classify_with',
				'-values' => [ map( $_->id, @category_list) ],
				-labels   => { map { $_->id => $_->Name } @category_list }
			) if @category_list;
			foreach my $category ( @category_list ) {
				my @sorted_images = sort( 
					{ $a->name cmp $b->name }
					@{ $image_classifications{ $category->id } || [] }
				);
				push( @{ $tmpl_data{ _CategoryList } }, {
					CategoryRef => $self->Renderer()->render( $category, 'ref' ),
					images      => $self->Renderer()->renderArray( 
						\@sorted_images, 'bare_ref_mass_no_map', { type => 'OME::Image' } 
					),
				} );
			}
			my @unclassified_images = sort( 
				{ $a->name cmp $b->name }
				@{ $image_classifications{ 0 } || [] }
			);
			unshift( @{ $tmpl_data{ CategoryList } }, {
				CategoryRef => 'Unclassified',
				images      => $self->Renderer()->renderArray( \@unclassified_images, 'bare_ref_mass_no_map', { type => 'OME::Image' } ),
			} );
		}
	}
	
	
	$tmpl->param( %tmpl_data );
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	$html .= $q->startform( { -name => $self->{ form_name } } ).
	         $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	         $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	         $q->hidden({-name => 'action', -default => ''}).
	         join (' ',@hidden_fields).
	         $tmpl->output().
	         $q->endform();

	return ('HTML', $html);
}


sub _takeAction {
	my $self = shift;
	my $dataset = $self->_loadObject();
	my $q = $self->CGI();
	my $message;
	my $factory = $self->Session()->Factory();

	# make this dataset the "most recent"
	$self->Session()->dataset( $dataset );
	$self->Session()->storeObject();
	$self->Session()->commitTransaction();
	
	# Edits
	if( $q->param( 'action' ) && $q->param( 'action' ) eq 'Save' ) {
		# Edit name or description
		if( $q->param( 'description' ) || $q->param( 'name' ) ) {
			$dataset->description( $q->param( 'description' ) );
			$dataset->name( $q->param( 'name' ) );
			$dataset->storeObject();
			$self->Session()->commitTransaction();
		}
		# Edit annotation
		if( $q->param( 'annotation' ) ) {
			OME::Tasks::DatasetManager->writeAnnotation( 
				$dataset, { Content => $q->param( 'annotation' ) }
			);
			$self->Session()->commitTransaction();
		}
	}
	
	# Delete Annotation
	if( $q->param( 'action' ) eq 'DeleteAnnotation' ) {
		OME::Tasks::DatasetManager->deleteCurrentAnnotation( $dataset );
		$self->Session()->commitTransaction();
	}

	# Add images
	my $image_ids = $q->param( 'images_to_add' );
	if( $image_ids ) {
		$message .= $self->DatasetUtil()->addImages($image_ids);
	}
	
	# Declassify image
	my $image_id_to_declassify = $q->param( 'declassifyImage' );
	if( $image_id_to_declassify && $image_id_to_declassify ne '' ) {
		my $image = $factory->loadObject( 'OME::Image', $image_id_to_declassify )
			or die "Couldn't load image (id=$image_id_to_declassify)";
		my $cg_id = $q->param( 'group_images_by_cg' );
		die "No category group selected."
			unless ( $cg_id && $cg_id ne '' );
		my $cg = $factory->loadObject( '@CategoryGroup', $cg_id )
			or die "Couldn't load CategoryGroup ID=$cg_id";
		my $classification = OME::Tasks::CategoryManager->
			getImageClassification( $image, $cg );
		if (not defined $classification ) {
			$message .= "<font color='red'>Image ".$self->Renderer()->render( $image, 'ref' )." is already unclassified.</font><br>";
		} elsif ( ref( $classification ) eq 'ARRAY' ) {
			$message .= "<font color='red'>Image ".$self->Renderer()->render( $image, 'ref' )." has multiple (".
			scalar( @$classification ).") classifications in this CategoryGroup. This page isn't capable of dealing with that.</font><br>";
		} else {
			OME::Tasks::CategoryManager->
				declassifyImage( $image, $classification->Category() );
			$message .= "Declassified image ".$self->Renderer()->render( $image, 'ref' ).".<br>";
		}
	}
	
	# allow image classification
	my $image_id_to_classify = $q->param( 'classifyImage' );
	if( $image_id_to_classify && $image_id_to_classify ne '') {
		my $category_id = $q->param( 'category_to_classify_with' );
		$message .= $self->CategoryUtil()->
			classify( $image_id_to_classify, $category_id );
	}
	
	return $message;
}



=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
