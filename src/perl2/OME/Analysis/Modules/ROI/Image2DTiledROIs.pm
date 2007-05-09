# OME/Analysis/Modules/ROI/Image2DTiledROIs.pm

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

package OME::Analysis::Modules::ROI::Image2DTiledROIs;

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
    my @numOfTilesOptional = $self->getCurrentInputAttributes("Number of Tiles");
    my @selectedPlanesOptional = $self->getCurrentInputAttributes("Selected Planes");

	$mex->read_time(tv_interval($start_time));
	$mex->execution_time(0);
	$start_time = [gettimeofday()];
	
	# parse @selectedPlaneOptional to limit the z,c,t s
	my %z; my %c; my %t;
	my @z; my @c; my @t;
	if (scalar (@selectedPlanesOptional)) {
		foreach (@selectedPlanesOptional) {
			die "malformed ROI SelectedPlanes" unless
				(defined($_->theZ()) and defined($_->theC()) and defined($_->theT()));
			
			$z{$_->theZ()}= undef;
			$c{$_->theC()}= undef;
			$t{$_->theT()}= undef;
		}
		@z = keys %z;
		@c = keys %c;
		@t = keys %t;
	} else {
		@z = (0 .. $pixels->SizeZ()-1);
		@c = (0 .. $pixels->SizeC()-1);
		@t = (0 .. $pixels->SizeT()-1);
	}

	foreach my $z (@z) {
		foreach my $c (@c) {
			foreach my $t (@t) {
				# Make Tiles
				if (scalar (@numOfTilesOptional) > 0) {
				    my $numOfTiles = $numOfTilesOptional[0];    
					my $width  = int($pixels->SizeX() / $numOfTiles->NumOfHorizontalTiles());
					my $height = int($pixels->SizeY() / $numOfTiles->NumOfVerticalTiles());
					
					# tiling
					for (my $i=0; $i<$numOfTiles->NumOfHorizontalTiles(); $i++) {
						for (my $j=0; $j<$numOfTiles->NumOfVerticalTiles(); $j++) {
			
							my $feature;
							if (scalar (@z) or scalar (@c) or scalar (@t)) {
								$feature = $self->newFeature("2D Tile ROI $i $j (z:$z c:$c t:$t)",$image);
							} else {
								$feature = $self->newFeature("2D Tile ROI $i $j",$image);
							}
							my $featureID = $feature->id();
							
							$self->newAttributes('Image ROIs',
												{
												 feature_id => $featureID,
												 Parent => $pixels,
												 StartX => $i*$width,
												 EndX   => ($i+1)*$width-1,
												 StartY => $j*$height,
												 EndY   => ($j+1)*$height-1,
												 StartZ => $z,
												 EndZ   => $z,
												 StartC => $c,
												 EndC   => $c,
												 StartT => $t,
												 EndT   => $t,
												});
						}
					}
				} else {
					my $feature;
					if (scalar (@z) or scalar (@c) or scalar (@t)) {
						$feature = $self->newFeature("2D ROI (z:$z c:$c t:$t)",$image);
					} else{
						$feature = $self->newFeature("2D ROI",$image);
					}
					
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
