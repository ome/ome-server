# OME/Web/DBObjRender/__OriginalFile.pm
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


package OME::Web::DBObjRender::__OriginalFile;

=pod

=head1 NAME

OME::Web::DBObjRender::__OriginalFile - specialized rendering of OriginalFile ST

=head1 DESCRIPTION

Provides custom behavior for rendering OriginalFile ST

=head1 METHODS

=cut

use strict;
use vars qw($VERSION);
use OME;
use OME::Web;
use base qw(OME::Web::DBObjRender);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);
	
	$self->{ _fieldTitles } = {
	'Path'             => "Name",
	};
	
	return $self;
}

=head2 _renderData

makes Path link to original file from image server if format is html

=cut

sub _renderData {
	my ($proto, $obj, $field_names, $format, $mode, $options) = @_;

	return () unless( grep( /Path/, @$field_names ) and $format eq 'html' );

	my %record;	
	my $path = $proto->_trim( $obj->Path, $options );
	my $originalFile_url = $obj->Repository()->ImageServerURL() . '?Method=ReadFile&FileID='.$obj->FileID();
	$record{Path} = "<a href='$originalFile_url'>".$path."</a>";

	return %record;
}


=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

1;
