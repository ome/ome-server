# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
#
package OMEtestAnalysis;
use OMEpl;
@ISA = qw(OMEpl);
use strict;

# Over-ride SelectDatasets by calling SetSelectedDatasets with a list of datasets
sub SelectDatasets()
{
	my $self = attr shift;
	$self->SetSelectedDatasets(10,11,12);
}

# Here we set some attributes for a dataset's existing features.
# For now, the parameters are a list of feature attributes
# We'll try an array of 
# $Feature[1]{'ID'}
sub Execute()
{
}





1;
