# OME/Web/ThumbCurrentDataset.pm

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
# Written by:    Jean-Marie Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::ThumbCurrentDataset;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Web::Helper::JScriptFormat;
use OME::Web::Helper::HTMLFormat;

use base qw(OME::Web);




sub getPageTitle {
	return "Open Microscopy Environment - Thumbnails/Current Dataset" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my	$session=$self->Session();
	my 	$body="" ;
	my $jscriptFormat=new OME::Web::Helper::JScriptFormat;
	my $HTMLFormat=new OME::Web::Helper::HTMLFormat;

	my @ref=$session->dataset()->images();
	
	my @result=();
	foreach my $object (@ref){
		my $text=$HTMLFormat->formatThumbnail($object);
		push(@result,$text);
	}
	$body.= $jscriptFormat->popUpImage();  
	$body.=$HTMLFormat->gallery(\@result);


	return ('HTML',$body);

		
}




1;
