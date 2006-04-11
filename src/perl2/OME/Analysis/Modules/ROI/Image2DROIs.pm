# OME/Analysis/Modules/ROI/Image2DROIs.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2005 Open Microscopy Environment
#		Massachusetts Institue of Technology,
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
# Written by:	 Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------

package OME::Analysis::Modules::ROI::Image2DROIs;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use IO::File;
use Log::Agent;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use Time::HiRes qw(gettimeofday tv_interval);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(@_);

	bless $self,$class;
	return $self;
}

sub startImage {
	my ($self,$image) = @_;
	$self->SUPER::startImage($image);

	my $mex = $self->getModuleExecution();
    my $session = OME::Session->instance();

	my $start_time = [gettimeofday()];
    my $pixels = $self->getCurrentInputAttributes("Pixels")->[0];
	$mex->read_time(tv_interval($start_time));
	
	$start_time = [gettimeofday()];
	
	for (my $z=0; $z<$pixels->SizeZ(); $z++) {
		for (my $c=0; $c<$pixels->SizeC(); $c++) {
			for (my $t=0; $t<$pixels->SizeT(); $t++) {

			my $feature = $self->newFeature("Image 2D ROI",$image);
			my $featureID = $feature->id();

			$self->newAttributes('Image ROIs',
								{
								 feature_id => $featureID,
								 Parent => $pixels,
								 StartX => 0,
								 EndX   => $pixels->SizeX() - 1,
								 StartY => 0,
								 EndY   => $pixels->SizeY() - 1,
								 StartZ => $z,
								 EndZ   => $z,
								 StartC => $c,
								 EndC   => $c,
								 StartT => $t,
								 EndT   => $t,
								});
			}
		}
	}
                        
	$mex->write_time(tv_interval($start_time));
	$mex->storeObject();
}

1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
