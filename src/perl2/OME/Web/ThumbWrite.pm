# OME/Web/Thumbwrite.pm
# This module builds and returns a JPEG for a given OME::Image

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
# Written by:    Jean-Marie Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::ThumbWrite;
use strict;
use vars qw($VERSION);
use CGI;
use Carp;

# OME Includes
use OME::Tasks::Thumbnails;
use OME::SessionManager;
use OME;

# OME Defines
$VERSION = $OME::VERSION;
use base qw(OME::Web);


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    return $self;
}

sub serve {
	my $self = shift;
	my $cgi=$self->CGI();
	my $id= $cgi->url_param('ImageID');
	my $sid=$cgi->url_param('sid');
	my $s_manager=new OME::SessionManager; 

	my $session=$s_manager->createSession($sid);
	my $factory=$session->Factory();
	my $generator= new OME::Tasks::Thumbnails($session);
	my $image=$factory->loadObject("OME::Image",$id);
	my $out=$generator->generateOMEimage($image);
	print $self->CGI()->header(-type =>"image/jpeg");

	if (not defined $out){
		# $out = read img
  		my $no_img="../../images/no_img.jpeg";
		open(IM, "< $no_img") || die ("Error reading file, ",$no_img," ",$!);
		while(<IM>){
			print $_;
		};
		close(IM);		
	}else{
		my $thumbnail=$generator->generateOMEthumbnail($out);
		print $thumbnail;
	}


}

1;
