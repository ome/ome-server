# OME/Tasks/CategoryManager.pm

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


package OME::Tasks::CategoryManager;
use strict;
use OME;
use OME::Session;
our $VERSION = $OME::VERSION;

=head1 NAME

OME::Tasks::CategoryManager

=head1 SYNOPSIS

	use OME::Tasks::CategoryManager;

=head1 DESCRIPTION

The OME::Tasks::CategoryManager


=head1 METHODS

=head2 getImagesInCategory()

	my @images = OME::Tasks::CategoryManager->getImagesInCategory($category);

Finds all images in the given category

=cut

sub getImagesInCategory {
	my ($proto, $category) = @_;
	my @classifications = $category->ClassificationList( );
# for some unknown reason, using 
#	Valid    => [ "is not", 0 ]
# as a filtering parameter consistently fails with the message
# "DBD::Pg::st execute failed: ERROR:  parser: parse error at or near "'" at /Users/josiah/OME/cvs/OME/src/perl2//OME/Factory.pm line 1069."
# so i'll just filter the list with grep
	@classifications = grep( ( ( not defined $_->Valid ) || $_->Valid ne 0 ), @classifications );
	my @images = sort( { $a->name cmp $b->name } map( $_->image, @classifications ) );
	return @images;
}


=head1 AUTHOR

Josiah Johnston <siah@nih.gov>

=cut

1;

