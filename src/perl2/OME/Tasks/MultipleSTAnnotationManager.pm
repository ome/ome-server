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

Takes a hash prototype for annotations, done as a nested hash, and turns
    it into a set of annotations. 
    

=cut
sub createGroupAnnotations {
    my $class =shift;

    my $vals = shift;
    # vals is a hash, keyed by 

    my $mex;
    my $objs;
    my %res;
    foreach my $st (keys %$vals){
	# if data is a  ref (another hash) must create a  
	# new ST. If data is an atomic value,
	# or an ST, 
	my $data = $vals->{$st};
	$res{$st} = 
	    OME::Tasks::MultipleSTAnnotationManager->createSTVals($st,$data);
    }
    return \%res;
}


=head2 createSTVals

   Given a $data hash of arbitrary depth representing a tree of ST
   data, recursively create STs for each of the children of the root,
    and then use those to create an ST of the final desired result
   type. Store each object as created.
    

=cut
sub createSTVals {
    my ($class,$st,$data) = @_;

    foreach my $field (keys %$data) {
	if (ref ($data->{$field}) eq 'HASH') {
	    # this is the recurse case.
	    $data->{$field} =
		OME::Tasks::MultipleSTAnnotationManager->createSTVals($field,$data->{$field});
	}
    }
    my $mex;
    my $objs;
    
    my $stVal;

    ($mex,$objs) = 
	OME::Tasks::AnnotationManager->annotateGlobal($st,$data);
    
    $stVal = $objs->[0];
    $stVal->storeObject();
    return $stVal;
}


