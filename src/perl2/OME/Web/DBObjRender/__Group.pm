# OME/Web/RenderData/__Group.pm
#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
#		National Institutes of Health,
#		University of Dundee
#
#
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:  
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::RenderData::__Group;

=pod

=head1 NAME

OME::Web::RenderData::__Group - Specialized rendering for Group Attribute

=head1 DESCRIPTION

Provides custom behavior for rendering a Group Attribute

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Session;
use base qw(OME::Web::RenderData);

=head2 getRefToObject

Overrides default behavior, html format uses the name for the link.

=cut

sub getRefToObject {
	my ($proto,$obj,$format) = @_;
	
	for( $format ) {
		if( /^txt$/ ) {
			return $obj->id();
		}
		if( /^html$/ ) {
			my $type = $proto->_getType( $obj );
			my $id   = $obj->id();
			my $name = "$id. ".$obj->Name();
			my $ref  = "<a href='serve.pl?Page=OME::Web::ObjectDetail&Type=$type&ID=$id'>$name</a>";
			return $ref;
		}
	}
}

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
