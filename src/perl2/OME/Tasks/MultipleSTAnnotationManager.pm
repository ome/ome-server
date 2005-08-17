# OME/Tasks/MultipleSTAnnotationManager.pm

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
# Written by:    Harry Hochheiser <hsh@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Tasks::MultipleSTAnnotationManager;


=head1 NAME

OME::Tasks::MultipleSTAnnotationManager - Create multiple instances of Semantic Types 

=head1 DESCRIPTION

Procedures for creating multiple STs in one shot.
=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;

use OME::Tasks::AnnotationManager;


=head2 createGroupAnnotations

Takes a hash, keyed by semantic type names.  The value for each entry
is a hash of field names & respective values.

Returns a hash keyed by the ST name, with the value for ST being the
newly created instance of the given type.
=cut
sub createGroupAnnotations {
    my $class =shift;

    my $vals = shift;
    # vals is a hash, keyed by 

    my $mex;
    my $objs;
    my %results;
    foreach my $st (keys %$vals) {
	my $data = $vals->{$st};
	print STDERR "Creating ST for type $st\n";
	# we're only creating one object of each type (via one data hash)
	($mex,$objs)=
	    OME::Tasks::AnnotationManager->annotateGlobal($st,$data);
	# so store that object in the result has that I'm returning.
	$results{$st} = $objs->[0];
    }
    return \%results;
}
