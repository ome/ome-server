# OME/Analysis/Modules/Tests/FauxSignature.pm

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


package OME::Analysis::Modules::Tests::FauxSignature;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Analysis::Handler;

use base qw(OME::Analysis::Handler);

sub execute {
    my ($self,$dependence,$target) = @_;
    my $factory = OME::Session->instance()->Factory();

    my $mex = $self->getModuleExecution();
    my $module = $mex->module();

    my @formal_outputs = $factory->findObjects(
    	'OME::Module::FormalOutput',
		{ module => $module }
	);

	foreach my $output ( @formal_outputs ) {
		my $data_hash;
		my $counter = 0;
		foreach my $se ( $output->semantic_type()->semantic_elements() ) {
			$data_hash->{ $se->name } = $counter++;
		}
		$data_hash->{ target } = $mex->image;
		$self->newAttributes( $output, $data_hash );
	}
}

1;
