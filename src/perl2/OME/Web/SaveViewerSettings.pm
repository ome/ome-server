# OME/Web/SaveViewerSettings.pm

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


package OME::Web::SaveViewerSettings;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use CGI;
use Log::Agent;
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

	if( $cgi->param('CBW') ) {
		my @CBW     = split( ',' , $cgi->param('CBW') );
		my @RGBon   = split( ',' , $cgi->param('RGBon') );

		my $isRGB     = $cgi->param('isRGB');
		my $theZ      = $cgi->param('theZ');
		my $theT      = $cgi->param('theT');
		my $imageID   = $cgi->param('ImageID');
		my $pixelsID   = $cgi->param('PixelsID');
		my $pixels;
		$pixels = $factory->loadAttribute( "Pixels", $pixelsID ) if( $pixelsID);
		$self->SaveDisplaySettings( $imageID, \@CBW, \@RGBon, $theT, $theZ, $isRGB, $pixels );
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
		$viewerPreferences->storeObject();
	} else {
		my $data = {
			experimenter_id  => $session->User()->id(),
			toolbox_scale    => $toolBoxScale
		};
		$viewerPreferences = $factory->newObject( 'OME::ViewerPreferences', $data )
			or die "Could not create new ViewerPreferences object";
	}
	$session->commitTransaction();
	return $viewerPreferences;	
}

sub SaveDisplaySettings {
	my ($self, $imageID, $CBW, $RGBon, $theT, $theZ, $isRGB, $pixels) = @_;
	my $session = $self->Session();
	my $factory = $session->Factory();

	my $image = $self->Session()->Factory()->loadObject("OME::Image",$imageID)
		or die "Could not retreive Image from ImageID=$imageID\n";

	# get Dimensions from image and make them readable
	$pixels = $image->DefaultPixels()
		unless $pixels;

	my $displayOptions = $factory->findAttribute( 'DisplayOptions', $imageID );
	my ( $redChannel, $greenChannel, $blueChannel, $greyChannel );

	if( $displayOptions ) {
		$redChannel = $displayOptions->RedChannel();
		$redChannel->ChannelNumber  ( $CBW->[0] );
		$redChannel->BlackLevel     ( $CBW->[1] );
		$redChannel->WhiteLevel     ( $CBW->[2] );
		$greenChannel = $displayOptions->GreenChannel();
		$greenChannel->ChannelNumber( $CBW->[3] );
		$greenChannel->BlackLevel   ( $CBW->[4] );
		$greenChannel->WhiteLevel   ( $CBW->[5] );
		$blueChannel = $displayOptions->BlueChannel();
		$blueChannel->ChannelNumber ( $CBW->[6] );
		$blueChannel->BlackLevel    ( $CBW->[7] );
		$blueChannel->WhiteLevel    ( $CBW->[8] );
		$greyChannel = $displayOptions->GreyChannel();
		$greyChannel->ChannelNumber ( $CBW->[9] );
		$greyChannel->BlackLevel    ( $CBW->[10] );
		$greyChannel->WhiteLevel    ( $CBW->[11] );
		$displayOptions->RedChannelOn( $RGBon->[0] );
		$displayOptions->GreenChannelOn( $RGBon->[1] );
		$displayOptions->BlueChannelOn( $RGBon->[2] );
		$displayOptions->TStart($theT);
		$displayOptions->TStop($theT);
		$displayOptions->ZStart($theZ);
		$displayOptions->ZStop($theZ);
		$displayOptions->DisplayRGB( $isRGB );
		$displayOptions->Pixels( $pixels );

		$displayOptions->storeObject();
		$redChannel->storeObject();
		$greenChannel->storeObject();
		$blueChannel->storeObject();
		$greyChannel->storeObject();
	} else {
		my $data = {
			ChannelNumber => $CBW->[0],
			BlackLevel    => $CBW->[1],
			WhiteLevel    => $CBW->[2]
		};
		$redChannel = $factory->newAttribute( 'DisplayChannel', $image, undef, $data )
			or die "Could not create new DisplayChannel attribute\n";
		$data = {
			ChannelNumber => $CBW->[3],
			BlackLevel    => $CBW->[4],
			WhiteLevel    => $CBW->[5]
		};
		$greenChannel = $factory->newAttribute( 'DisplayChannel', $image, undef, $data )
			or die "Could not create new DisplayChannel attribute\n";
		$data = {
			ChannelNumber => $CBW->[6],
			BlackLevel    => $CBW->[7],
			WhiteLevel    => $CBW->[8]
		};
		$blueChannel = $factory->newAttribute( 'DisplayChannel', $image, undef, $data )
			or die "Could not create new DisplayChannel attribute\n";
		$data = {
			ChannelNumber => $CBW->[9],
			BlackLevel    => $CBW->[10],
			WhiteLevel    => $CBW->[11]
		};
		$greyChannel = $factory->newAttribute( 'DisplayChannel', $image, undef, $data )
			or die "Could not create new DisplayChannel attribute\n";
		$data = {
			RedChannel     => $redChannel->id(),
			GreenChannel   => $greenChannel->id(),
			BlueChannel    => $blueChannel->id(),
			GreyChannel    => $greyChannel->id(),
			RedChannelOn   => $RGBon->[0],
			GreenChannelOn => $RGBon->[1],
			BlueChannelOn  => $RGBon->[2],
			TStart         => $theT,
			TStop          => $theT,
			ZStart         => $theZ,
			ZStop          => $theZ,
			DisplayRGB     => $isRGB,
			Pixels         => $pixels
		};
		$displayOptions = $factory->newAttribute( 'DisplayOptions', $image, undef, $data )
			or die "Could not create new DisplayOptions attribute\n";			
	}
	
	$session->commitTransaction();

	return $displayOptions;
}

1;
