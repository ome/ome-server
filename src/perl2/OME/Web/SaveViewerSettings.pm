# OME/Web/SaveViewerSettings.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Web::SaveViewerSettings;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::DisplaySettings;
use OME::ViewerPreferences;
use base qw{ OME::Web };

sub getPageTitle {
    return "Open Microscopy Environment - Save Viewer Settings";
}

sub getPageBody {
    my $self = shift;
	my $cgi     = $self->CGI();
	my $session = $self->Session();
	my $factory = $session->Factory();

	if( $cgi->param('WBS') ) {
		my @WBS     = split( ',' , $cgi->param('WBS') );
		my @RGBon   = split( ',' , $cgi->param('RGBon') );

		my $isRGB     = $cgi->param('isRGB');
		my $theZ      = $cgi->param('theZ');
		my $theT      = $cgi->param('theT');
		my $imageID   = $cgi->param('ImageID');

		$self->SaveDisplaySettings( $imageID, \@WBS, \@RGBon, $theT, $theZ, $isRGB );
	} elsif ($cgi->param('toolBoxScale') ) {
		my $toolBoxScale = $cgi->param('toolBoxScale');

		$self->SavePreferences( $toolBoxScale );
	}

    return ('HTML','');
}

sub SavePreferences {
	my ($self, $toolBoxScale ) = @_;
	my $session = $self->Session();
	my $factory = $session->Factory();
	
	my $viewerPreferences = $factory->findObject( 'OME::ViewerPreferences', experimenter_id => $session->User()->id() );
	if( $viewerPreferences) {
		$viewerPreferences->toolbox_scale( $toolBoxScale );
	} else {
		my $data = {
			experimenter_id  => $session->User()->id(),
			toolbox_scale    => $toolBoxScale
		};
		$viewerPreferences = $factory->newObject( 'OME::ViewerPreferences', $data )
			or die "Could not create new ViewerPreferences object";
	}
	$viewerPreferences->writeObject()
		or die "Could not write ViewerPreferences object";
	return $viewerPreferences;	
}

sub SaveDisplaySettings {
	my ($self, $imageID, $WBS, $RGBon, $theT, $theZ, $isRGB) = @_;
	my $session = $self->Session();
	my $factory = $session->Factory();

	my $displaySettings = $factory->findObject( 'OME::DisplaySettings', image_id => $imageID );
	if( $displaySettings ) {
		$displaySettings->WBS( @$WBS );
		$displaySettings->RGBon( @$RGBon );
		$displaySettings->theT($theT);
		$displaySettings->theZ($theZ);
		$displaySettings->isRGB( $isRGB );
	} else {
		my $data = {
			image_id          => $imageID,
			red_wavenum       => $WBS->[0] ,
			red_black_level   => $WBS->[1] ,
			red_scale         => $WBS->[2] ,
			green_wavenum     => $WBS->[3] ,
			green_black_level => $WBS->[4] ,
			green_scale       => $WBS->[5] ,
			blue_wavenum      => $WBS->[6] ,
			blue_black_level  => $WBS->[7] ,
			blue_scale        => $WBS->[8] ,
			grey_wavenum      => $WBS->[9] ,
			grey_black_level  => $WBS->[10],
			grey_scale        => $WBS->[11],
			the_z             => $theZ,
			the_t             => $theT,
			is_rgb            => $isRGB,
			display_red       => $RGBon->[0],
			display_green     => $RGBon->[1],
			display_blue      => $RGBon->[2]
		};
		$displaySettings = $factory->newObject( 'OME::DisplaySettings', $data )
			or die "Could not create new DisplaySettings object";
	}
	
	$displaySettings->writeObject()
		or die "Could not write displaySettings";
	return $displaySettings;
}

1;
