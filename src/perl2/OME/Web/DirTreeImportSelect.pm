# OME/Web/DirTreeImportSelect.pm

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
# Written by:    Ilya G. Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::DirTreeImportSelect;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::DBObject;
use OME::Dataset;		
use OME::Tasks::OMEXMLImportExport;
use OME::Web::Helper::HTMLFormat;

use base qw{ OME::Web };


sub getPageTitle {
	return "Open Microscopy Environment - Import XML file";
}

sub getPageBody {
	my $self = shift;
	my $rootName = "Home";
	my $cgi = $self->CGI();
	my $session=$self->Session();
	my $userID=$session->User()->id();
	my $usergpID=$session->User()->Group()->id();
	my $rootDir=$self->User()->DataDirectory();

	my $htmlFormat=new OME::Web::Helper::HTMLFormat;

	my @selections = ();
	my $selection;
	my @paths;
	my $body = '';
	foreach $selection ($cgi->url_param()) {
		$selection = $cgi->unescape($selection);
		if ( not ($selection eq 'action' or $selection eq 'keywords' or $selection eq 'Page' or not $selection)) {
			push (@selections,$selection);
			push (@paths,$rootDir.$selection);
		}
	}
	
	@selections = sort {uc($a) cmp uc($b)} @selections;
	if (scalar (@selections) > 0) {

		if ($cgi->param('Import')) {
			my $importer= OMEXMLImportExport->new($session);
			$importer->importXMLfile(\@paths);

	 	}else {
		# If we have a selection, but import button wasn't clicked, print the form:
		$body .= print_form($session,$cgi,$htmlFormat,\@selections);
		}
	
	# If we got no selection, just print a handy hint.
	} else {
		$body .=  "<h4>Select Files and Folders in the menu tree on the left.</h4>";
	}

	return ('HTML', $body);

}


sub print_form {
	my ($session,$cgi,$htmlFormat,$refSelection) = @_;
	my $text = '';
	my @listFiles=();
	foreach (@$refSelection){
		my @pathElements = split ('/',$_);
		my $n=scalar(@pathElements);
		push(@listFiles,$pathElements[$n-1]);

	}
	$text .="<h3>XML file to Import.</h3>";
	$text .= $cgi->startform;
	$text .=$htmlFormat->formImportExportXML(\@listFiles,"Import","Import XML file");
	$text .= $cgi->endform;
	return $text;
}



1;
