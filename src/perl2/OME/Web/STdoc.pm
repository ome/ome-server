# OME/Web/STdoc.pm

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


package OME::Web::STdoc;

use strict;
use warnings; 
use Carp;

# OME Modules
use OME;
use vars qw($VERSION);
$VERSION = $OME::VERSION;
use base qw(OME::Web);

sub getPageTitle {
	return "Open Microscopy Environment - Semantic Type Documentation";
}

{
	my $menu_text = "ST doc";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my $self = shift;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $q = $self->CGI();
	
	my $ST_name = $q->param( 'ST_name' );
	if( (defined $ST_name) && ($ST_name ne '') ) {
		my $st = $factory->findObject( 'OME::SemanticType',
			name => $ST_name
		) or die "Could not find a Semantic Type named '$ST_name'";
		return( 'REDIRECT', $self->getObjDetailURL( $st, Popup => 1 ) );
	}
	
	my $SE_id = $q->param( 'SE_id' );
	if( (defined $SE_id) && ($SE_id ne '') ) {
		my $se = $factory->loadObject( 'OME::SemanticType::Element', $SE_id )
			or die "Could not load Semantic Element (id='$SE_id')";
		return( 'REDIRECT', $self->getObjDetailURL( $se, Popup => 1 ) );
	}
	
	die "expected url paramenter ST_name or SE_id not given!";
}


1;
