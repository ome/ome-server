# OME/Web/DBObjDetail/__Category.pm

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


package OME::Web::DBObjDetail::__Category;

=pod

=head1 NAME

OME::Web::DBObjDetail::__Category

=head1 DESCRIPTION

implements _takeAction to allow Categorization of Images

=cut

#*********
#********* INCLUDES
#*********

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::AnnotationManager;
use OME::Tasks::CategoryManager;

use Log::Agent;
use base qw(OME::Web::DBObjDetail);

sub getPageBody {
	my $self = shift;
	my $html = ( $self->_takeAction( ) || '' );

	my $q = $self->CGI();
	my $obj = $self->_loadObject();
	my $mode = 'detail';
	
	( $self->{ form_name } = $q->param( 'Type' ).$q->param( 'ID' ) ) =~ s/[:@]/_/g;
	
	#
	# basically do $self->Renderer()->render($obj, $mode) with a twist by filling
	# extra template variable
	#
	
	# load a template
	my ($tmpl, %tmpl_data);
	my $tmpl_path = $self->Renderer()->_findTemplate( $obj, $mode, 'one' );
	$tmpl_path = $self->Session()->Configuration()->template_dir().'/generic_'.$mode.'.tmpl'
		unless $tmpl_path;
	die "Could not find a specialized or generic template to match Object $obj with mode $mode"
		unless -e $tmpl_path;
	$tmpl = HTML::Template->new( filename => $tmpl_path, case_sensitive => 1 );

	# get data for it	
	%tmpl_data = $self->Renderer()->_populate_object_in_template( $obj, $tmpl, undef);

	# fill template variable if category contains atleast one image
	my @imgs_in_category = OME::Tasks::CategoryManager->getImagesInCategory($obj);
	$tmpl_data{'imgs_in_category'} = scalar @imgs_in_category if ( scalar @imgs_in_category > 0);

	# populate template
	$tmpl->param( %tmpl_data );
	
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
	my $obj = $self->_loadObject();
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $q = $self->CGI();
	my $message = '';
	
	if( $q->param( 'action' ) eq 'SaveChanges' ) {
# [Bug 479] http://bugs.openmicroscopy.org.uk/show_bug.cgi?id=479
	  # $obj->Name( $q->param( 'name' ) );
		$obj->Description( $q->param( 'description' ) );
		$obj->storeObject();
		$self->Session()->commitTransaction();
	}
	
	# allow image declassification
	my $image_id_to_declassify = $q->param( 'declassifyImage' );
	if( $image_id_to_declassify ) {
		my $image = $factory->loadObject( 'OME::Image', $image_id_to_declassify )
			or die "Couldn't load image (id=$image_id_to_declassify)";
		OME::Tasks::CategoryManager->declassifyImage( $image, $obj );
		$message .= "Declassified image ".$self->Renderer()->render( $image, 'ref' ).".<br>";
	}
	
	my $image_ids = $q->param( 'images_to_categorize' );
	$message .= $self->CategoryUtil()->classify( $image_ids, $obj )
		if( $image_ids );
	
	return $message;
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
