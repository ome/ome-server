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

	my $action = $cgi->param('action');
	my @selected = $cgi->param('selected');
 
	my $body;# = $cgi->p({class => 'ome_title', align => 'center'}, 'Export images to an XML file');
	
	if ($action eq 'Export'){
		my $filename = $session->getTemporaryFilename('XMLFileExport','ome')
			or die "OME::Web::XMLFileExport could not obtain temporary filename\n";

		if (@selected) {
			my $imageManager= OME::Tasks::ImageManager->new($session);
			my @list=();
			foreach (@selected){
				push(@list,$imageManager->load($_));
			}
			my $exporter= OME::Tasks::OMEXMLImportExport->new($session);
			$exporter->exportToXMLFile(\@list,$filename);
		
			my $downloadFilename;
			if (scalar @list > 1) {
				$downloadFilename = $session->dataset()->name();
			} else {
				$downloadFilename = $list[0]->name();
			}
			$downloadFilename .= '.ome';

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
	$body .= $self->__printForm();

	return ('HTML',$body);
}


################
sub __printForm {
	my $self = shift;
	my $session = $self->Session();
	my $q = $self->CGI();
	my $tableMaker = OME::Web::DBObjTable->new( CGI => $q );

	my $html = $tableMaker->getTable(  
		{
			title         => 'Export images to an XML file',
			actions       => ['Export'],
			select_column => 1,
			select_name   => 'selected',
			noTxtDownload => 1
		}, 
		"OME::Image", 
		{ accessor => [ 'OME::Dataset', $session->dataset()->id(), 'images' ] }
	);

	return $html;
}




sub cleaning{
 my ($string)=@_;
 chomp($string);
 $string=~ s/^\s*(.*\S)\s*/$1/;
 return $string;

}





1;
