# OME/Web/UploadImage.pm
# OME local image browser and importer for the OME Web interface.

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
# Written by:    Josiah Johnston <siah@mac.com>
#
#-------------------------------------------------------------------------------

package OME::Web::UploadImage;

use strict;
use warnings;
use vars qw($VERSION);
use Carp;

use OME;
use OME::Tasks::ImageTasks;

$VERSION = $OME::VERSION;
use base qw(OME::Web);

# Override's OME::Web
sub getPageTitle {
	return "Open Microscopy Environment - Upload Image";
}

# Override's OME::Web
{
	my $menu_text = "Upload";

	sub getMenuText { return $menu_text }
}

# Override's OME::Web
sub getPageBody {
	my $self = shift;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $q = $self->CGI();
	my $body;

	# pick up the dataset.
	my $dataset_id = $q->param( 'Dataset' );
	my $dataset;
	$dataset = $factory->loadObject( 'OME::Dataset', $dataset_id )
		or die "Couldn't load dataset (id=$dataset_id)"
		if( $dataset_id && $dataset_id ne '' );
	
	# Import if they just uploaded a file?
	if( $q->param('original_image_file') ) {
		my $original_file_name = $q->param('original_image_file');
		my $file_handle = $q->upload( 'original_image_file' );
		return ( 'ERROR', $q->cgi_error )
			if( !$file_handle && $q->cgi_error );
		unless( $dataset ) {
			$body .= "<font color='red'>You must pick a dataset to import into.</font><br>"
		} else {
# FIXME: Import file. I don't know an efficient and portable way to do this. 
# forkedImportFiles() expects a path, so we have to turn the filehandle into a path.

# Simple solution: copy from the file handle to 
#	/tmp/dir/from/session/$original_file_name
# Better solution?: find the temp name of the file somehow, make a hard link
# to it from /tmp/dir/from/session/$original_file_name

# Also, remember to clean up $original_file_name because, (from CGI documentation)
# 	"Different browsers will return slightly different things for the name. 
# Some browsers return the filename only. Others return the full path to the
# file, using the path conventions of the user's machine. Regardless, the 
# name returned is always the name of the file on the user's machine, and is 
# unrelated to the name of the temporary file that CGI.pm creates during upload 
# spooling (see below)."

#			OME::Tasks::ImageTasks::forkedImportFiles($dataset, [ $path_to_file ] );
#			return( 'REDIRECT', 'serve.pl?Page=OME::Web::TaskProgress');
			return( 'HTML', "<h1><blink>No import for you!</blink></h1>");
		}
	}

	# Load & populate the template
	my $tmpl_dir = $self->Session()->Configuration()->template_dir();
	my $tmpl_path = $tmpl_dir."/UploadImage.tmpl";
	my $tmpl = HTML::Template->new( filename => $tmpl_path,
	                                case_sensitive => 1 );
	$tmpl->param( 'Dataset' => $self->Renderer()->render( $dataset, 'ref' ) )
		if( $dataset );
	$tmpl->param( 
		'file_field' => $q->filefield( -name => 'original_image_file' ) );
	
	$body .= 
		$q->start_multipart_form().
		$tmpl->output().
		$q->hidden   ( -name => 'Dataset' ).
		$q->end_form();

	return ('HTML',$body);
	
	
}
