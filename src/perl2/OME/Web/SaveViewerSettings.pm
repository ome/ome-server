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
		my @WBS     = split( ',' , $cgi->param('CBW') );
		my @RGBon   = split( ',' , $cgi->param('RGBon') );

		my $isRGB     = $cgi->param('isRGB');
		my $theZ      = $cgi->param('theZ');
		my $theT      = $cgi->param('theT');
		my $imageID   = $cgi->param('ImageID');
		my $pixelsID   = $cgi->param('PixelsID');
		my $pixels;
		$pixels = $factory->loadAttribute( "Pixels", $pixelsID ) if( $pixelsID);
		$self->SaveDisplaySettings( $imageID, \@WBS, \@RGBon, $theT, $theZ, $isRGB, $pixels );
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
	$viewerPreferences->storeObject()
		or die "Could not write ViewerPreferences object";
	$session->commitTransaction();
	return $viewerPreferences;	
}

sub SaveDisplaySettings {
	my ($self, $imageID, $WBS, $RGBon, $theT, $theZ, $isRGB, $pixels) = @_;
	my $session = $self->Session();
	my $factory = $session->Factory();

	my $image = $self->Session()->Factory()->loadObject("OME::Image",$imageID)
		or die "Could not retreive Image from ImageID=$imageID\n";

	# get Dimensions from image and make them readable
	$pixels = $image->DefaultPixels()
		unless $pixels;

	my $displayOptions = [$factory->findAttributes( 'DisplayOptions', $imageID )];
	my ( $redChannel, $greenChannel, $blueChannel, $greyChannel );

	if( $displayOptions->[0] ) {
		die "More than one DisplayOptions attribute found for this image. That is invalid.\n"
			if( scalar( @$displayOptions ) > 1 );
		$displayOptions = $displayOptions->[0];
		$redChannel = $displayOptions->RedChannel();
		$redChannel->ChannelNumber  ( $WBS->[0] );
		$redChannel->BlackLevel     ( $WBS->[1] );
		$redChannel->WhiteLevel     ( $WBS->[2] );
		$greenChannel = $displayOptions->GreenChannel();
		$greenChannel->ChannelNumber( $WBS->[3] );
		$greenChannel->BlackLevel   ( $WBS->[4] );
		$greenChannel->WhiteLevel   ( $WBS->[5] );
		$blueChannel = $displayOptions->BlueChannel();
		$blueChannel->ChannelNumber ( $WBS->[6] );
		$blueChannel->BlackLevel    ( $WBS->[7] );
		$blueChannel->WhiteLevel    ( $WBS->[8] );
		$greyChannel = $displayOptions->GreyChannel();
		$greyChannel->ChannelNumber ( $WBS->[9] );
		$greyChannel->BlackLevel    ( $WBS->[10] );
		$greyChannel->WhiteLevel    ( $WBS->[11] );
		$displayOptions->RedChannelOn( $RGBon->[0] );
		$displayOptions->GreenChannelOn( $RGBon->[1] );
		$displayOptions->BlueChannelOn( $RGBon->[2] );
		$displayOptions->TStart($theT);
		$displayOptions->TStop($theT);
		$displayOptions->ZStart($theZ);
		$displayOptions->ZStop($theZ);
		$displayOptions->DisplayRGB( $isRGB );
		$displayOptions->Pixels( $pixels );
	} else {
		my $data = {
			ChannelNumber => $WBS->[0],
			BlackLevel    => $WBS->[1],
			WhiteLevel    => $WBS->[2]
		};
		$redChannel = $factory->newAttribute( 'DisplayChannel', $image, undef, $data )
			or die "Could not create new DisplayChannel attribute\n";
		$data = {
			ChannelNumber => $WBS->[3],
			BlackLevel    => $WBS->[4],
			WhiteLevel    => $WBS->[5]
		};
		$greenChannel = $factory->newAttribute( 'DisplayChannel', $image, undef, $data )
			or die "Could not create new DisplayChannel attribute\n";
		$data = {
			ChannelNumber => $WBS->[6],
			BlackLevel    => $WBS->[7],
			WhiteLevel    => $WBS->[8]
		};
		$blueChannel = $factory->newAttribute( 'DisplayChannel', $image, undef, $data )
			or die "Could not create new DisplayChannel attribute\n";
		$data = {
			ChannelNumber => $WBS->[9],
			BlackLevel    => $WBS->[10],
			WhiteLevel    => $WBS->[11]
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
	
	$displayOptions->storeObject();
	$redChannel->storeObject();
	$greenChannel->storeObject();
	$blueChannel->storeObject();
	$greyChannel->storeObject();
	$session->commitTransaction();

	return $displayOptions;
}

1;
