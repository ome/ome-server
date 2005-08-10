# OME/Web/SpreadsheetImporterPrompt.pm

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

package OME::Web::SpreadsheetImporter::SpreadsheetImporterPrompt;

use strict;
use Carp 'cluck';
use vars qw($VERSION);
use OME::Web::SpreadsheetImporter::SpreadsheetImporter;

use base qw(OME::Web);

sub getPageTitle {
	return "OME: Annotate Images";
}

{
	my $menu_text = "Annotate Images";
	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift;
	my $q = $self->CGI();
	my $session= $self->Session();
	my $factory = $session->Factory();
	my $output;
    
    if ($q->param( 'Annotate' )) {
    	my $fileToParse = $q->param( 'fileToParse' );
    	die "File $fileToParse is invalid\n" unless( $fileToParse );
    	$output = "The file is $fileToParse<br>";
    	$output .= "Finished annotating -<br>Here is what was returned:<br><br>";
		$output .= OME::Web::SpreadsheetImporter::SpreadsheetImporter->processFile( $fileToParse );
	}
    
    # Load & populate the template
	my $tmpl_dir = $self->actionTemplateDir();
	my $tmpl = HTML::Template->new( filename => "SpreadsheetImporterPrompt.tmpl",
									path => $tmpl_dir,
	                                case_sensitive => 1 );
	
	$tmpl->param( 'Output' => $output );
	
	my $html =
		$q->startform().
		$tmpl->output().
		$q->endform();

	return ('HTML',$html);
}

1;