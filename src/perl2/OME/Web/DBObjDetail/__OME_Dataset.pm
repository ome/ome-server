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
	
	# Gather Category Groups used in this dataset & make a popup list from them
	my %image_ids = map{ $_->id => undef } $dataset->images();
	if( %image_ids ) {
		my @classifications = $factory->
			findObjects( '@Classification',
			image_id => ['in', [ keys %image_ids ] ]
		);
		my %unique_cg_hash = map
			{ $_->Category->CategoryGroup->id => $_->Category->CategoryGroup }
			@classifications;
		my @cg_list = sort{ $a->Name cmp $b->Name } values %unique_cg_hash ;
		$tmpl_data{ categories_used } = (
		@cg_list ?
		$q->popup_menu(
			-name     => 'group_images_by_cg',
			'-values' => ['', map( $_->id, @cg_list) ],
			-default  => ( $q->param( 'group_images_by_cg' ) || '' ),
			-labels   => { 
				'' => "Don't partition",
				( map { $_->id => $_->Name } @cg_list )
			},
			-onChange => "javascript: document.forms[0].submit();"
		) :
		'(No images in this dataset have been classified)'
		);
	}

	# Use selected CG (if there is one) to group images.
	my $cg_id = $q->param( 'group_images_by_cg' );
	if( $cg_id && $cg_id ne '' ) {
		my $cg = $factory->loadObject( '@CategoryGroup', $cg_id )
			or die "Couldn't load CategoryGroup ID=$cg_id";
		$tmpl_data{ selected_category_group } = $self->Renderer()->render( $cg, 'ref' );
		my %classified_images;
		foreach my $category ( sort( { $a->Name cmp $b->Name } $cg->CategoryList() ) ) {
			my @images = grep( 
				(exists $image_ids{ $_->id } ),
				OME::Tasks::CategoryManager->getImagesInCategory( $category )
			);
			$classified_images{ $_->id() } = undef
				foreach @images;
			push( @{ $tmpl_data{ CategoryList } }, {
				CategoryRef => $self->Renderer()->render( $category, 'ref' ),
				images      => $self->Renderer()->renderArray( \@images, 'bare_ref_mass', { type => 'OME::Image' } ),
			} );
		}
		my @unclassified_images = grep( 
			( not exists $classified_images{ $_->id() } ),
			$dataset->images()
		);
		push( @{ $tmpl_data{ CategoryList } }, {
			CategoryRef => 'Unclassified',
			images      => $self->Renderer()->renderArray( \@unclassified_images, 'bare_ref_mass', { type => 'OME::Image' } ),
		} );
	}
	
	
	$tmpl->param( %tmpl_data );
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	$html .= $q->startform( { -name => $self->{ form_name } } ).
	           $q->hidden({-name => 'Type', -default => $q->param( 'Type' ) }).
	           $q->hidden({-name => 'ID', -default => $q->param( 'ID' ) }).
	           $q->hidden({-name => 'action', -default => ''}).
	           $tmpl->output().
	           $q->endform();

	return ('HTML', $html);
}


sub _takeAction {
	my $self = shift;
	my $dataset = $self->_loadObject();
	my $q = $self->CGI();

	# make this dataset the "most recent"
	$self->Session()->dataset( $dataset );
	$self->Session()->storeObject();
	$self->Session()->commitTransaction();
	
	# allow editing of dataset name & description
	if( $q->param( 'action' ) && $q->param( 'action' ) eq 'SaveChanges' ) {
		$dataset->description( $q->param( 'description' ) );
		$dataset->name( $q->param( 'name' ) );
		$dataset->storeObject();
		$self->Session()->commitTransaction();
	}
	
	# allow adding images to a dataset
	my $image_ids = $q->param( 'images_to_add' );
	if( $image_ids ) {
		OME::Tasks::DatasetManager->addImages( [ split( m',', $image_ids ) ] );
	}
	return;
}



=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
