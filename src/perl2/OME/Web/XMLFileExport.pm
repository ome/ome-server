# OME/Web/XMLFileExport.pm

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
# Written by:    Ilya G. Goldberg <igg@nih.gov> (based on Jean-Marie Burel <j.burel@dundee.ac.uk>)
#
#-------------------------------------------------------------------------------


package OME::Web::XMLFileExport ;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Web::DBObjTable;
use OME::Tasks::OMEXMLImportExport;
use OME::Tasks::ImageManager;


use base qw(OME::Web);


sub getPageTitle {
	return "Open Microscopy Environment - Export OME XML to browser" ;
}

{
	my $menu_text = "Export Image(s)";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift;
	my $cgi = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();

	my $action = $cgi->param('action');
	my $image_ids = $cgi->param('images_to_export');
	my @images = map( $factory->loadObject( 'OME::Image', $_ ), split( m',', $image_ids ) );

	my $body;# = $cgi->p({class => 'ome_title', align => 'center'}, 'Export images to an XML file');
	
	if ($action eq 'Export'){
		my $filename = $session->getTemporaryFilename('XMLFileExport','ome')
			or die "OME::Web::XMLFileExport could not obtain temporary filename\n";

		if (@images) {
			my $exporter= OME::Tasks::OMEXMLImportExport->new($session);
			$exporter->exportToXMLFile(\@images,$filename);
		
			my $downloadFilename = $cgi->param( 'filename' );
			if( not defined $downloadFilename || $downloadFilename eq '' ) {
				if (scalar @images > 1) {
					$downloadFilename = $session->dataset()->name();
				} else {
					$downloadFilename = $images[0]->name();
				}
			}
			$downloadFilename =~ s/(\.ome)?$/\.ome/;

			$self->contentType('application/ome+xml');
			return ('FILE',{
				filename => $filename,
				temp => 1,
				downloadFilename => $downloadFilename}) ;
		} else {
			$body .= $cgi->p({class => 'ome_error'}, 'No image(s) selected. Please try again.');
		}
	}

	$self->contentType('text/html');
	my $tmpl_dir = $self->Session()->Configuration()->template_dir();
	my $tmpl = HTML::Template->new( filename => 'XMLFileExport.tmpl', path => $tmpl_dir );
	$tmpl->param( selected_images => $self->Renderer()->renderArray( \@images, 'ref_mass' ) )
		if( @images );
	$body .= 
		$cgi->startform( -action => $self->pageURL( 'OME::Web::XMLFileExport' ) ).
		$tmpl->output().
		$cgi->hidden( -name => 'images_to_export' ).
		$cgi->endform();		

	return ('HTML',$body);
}

1;
