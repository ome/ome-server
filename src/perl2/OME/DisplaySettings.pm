# OME/DisplaySettings.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Josiah Johnston <siah@nih.gov>
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


package OME::DisplaySettings;

use strict;
our $VERSION = '1.0';

use OME::DBObject;
use base qw(OME::DBObject);

__PACKAGE__->AccessorNames({
    the_z  => 'theZ',
    the_t  => 'theT',
    is_rgb => 'isRGB'
});

__PACKAGE__->table('display_settings');
__PACKAGE__->sequence('attribute_seq');
__PACKAGE__->columns(Primary => qw(attribute_id));
__PACKAGE__->columns(Essential => qw(image_id the_z the_t is_rgb
                                     red_wavenum red_black_level red_scale display_red
                                     green_wavenum green_black_level green_scale display_green
                                     blue_wavenum blue_black_level blue_scale display_blue
                                     grey_wavenum grey_black_level grey_scale));
__PACKAGE__->hasa('OME::Image' => qw(image_id));

# accessor/mutator for WBS
sub WBS {
    my ($self, $rw, $rb, $rs, $gw, $gb, $gs, $bw, $bb, $bs, $greyW, $greyB, $greyS) = @_;
	
	# we gots mutators - let's mutate!
	if( defined $greyS ) {
		$self->red_wavenum( $rw );
		$self->red_black_level( $rb );
		$self->red_scale( $rs );
		$self->green_wavenum( $gw );
		$self->green_black_level( $gb );
		$self->green_scale( $gs );
		$self->blue_wavenum( $bw );
		$self->blue_black_level( $bb );
		$self->blue_scale( $bs );
		$self->grey_wavenum( $greyW );
		$self->grey_black_level( $greyB );
		$self->grey_scale( $greyS );
	}
	
	my $WBS = [
		$self->red_wavenum( ),
		$self->red_black_level( ),
		$self->red_scale( ),
		$self->green_wavenum( ),
		$self->green_black_level( ),
		$self->green_scale( ),
		$self->blue_wavenum( ),
		$self->blue_black_level( ),
		$self->blue_scale( ),
		$self->grey_wavenum( ),
		$self->grey_black_level( ),
		$self->grey_scale( ),
	];
	
	return $WBS;
}

# accessor/mutator for RGBon
#
# input is 3 booleans - can be t/f or 0/1
sub RGBon {
	my ($self, $r, $g, $b ) = @_;
	
	# we gots mutators - let's mutate!
	if(defined $b) {
		my %BooleanMap = ( 1 => 't', 0 => 'f' );

		$r = $BooleanMap{$r} if ($r eq 1 || $r eq 0);
		$g = $BooleanMap{$g} if ($g eq 1 || $g eq 0);
		$b = $BooleanMap{$b} if ($b eq 1 || $b eq 0);

		$self->display_red($r);
		$self->display_green($g);
		$self->display_blue($b);
		
	}
	
	my $RGBon = [
		$self->display_red(),
		$self->display_green(),
		$self->display_blue(),
	];
	
	return $RGBon;
}

1;

