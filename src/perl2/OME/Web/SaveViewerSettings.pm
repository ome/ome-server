# OME/Web/SaveViewerSettings.pm

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


package OME::Web::SaveViewerSettings;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;
use CGI;
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

	my $image = $self->Session()->Factory()->loadObject("OME::Image",$imageID)
		or die "Could not retreive Image from ImageID=$imageID\n";

	# get Dimensions from image and make them readable
	my $pixels = $image->DefaultPixels()
		or die "Could not a primary set of Pixels for this image\n";

	###########################################################################
	# get statistics for $pixels
	#
	my $stackStats = $factory->findObject( "OME::Module", name => 'Stack statistics' )
		or die "Stack statistics must be installed for this viewer to work!\n";
	my $pixelsFI = $factory->findObject( "OME::Module::FormalInput", 
		module_id => $stackStats->id(),
		name       => 'Pixels' )
		or die "Cannot find 'Pixels' formal input for module 'Stack Statistics'.\n";
	my $actualInput = $factory->findObject( "OME::ModuleExecution::ActualInput",
		formal_input_id   => $pixelsFI->id(),
		input_module_execution_id => $pixels->module_execution()->id() )
		or die "Stack Statistics has not been run on the Pixels to be displayed.\n";
	my $stackStatsAnalysisID = $actualInput->module_execution()->id();
	my @gmeans = grep( $_->module_execution()->id() eq $stackStatsAnalysisID, 
		$factory->findAttributes( "StackGeometricMean", $image ) );
	my @sigma  = grep( $_->module_execution()->id() eq $stackStatsAnalysisID, 
		$factory->findAttributes( "StackSigma", $image ) );
	my $sh; # stats hash
	foreach( @gmeans ) {
		$sh->[ $_->TheC() ][ $_->TheT() ]->{geomean} = $_->GeometricMean(); }
	foreach( @sigma ) {
		$sh->[ $_->TheC() ][ $_->TheT() ]->{sigma} = $_->Sigma(); }
	#
	###########################################################################

	my $displayOptions = [$factory->findAttributes( 'DisplayOptions', $imageID )];
	my ( $redChannel, $greenChannel, $blueChannel, $greyChannel );

	if( $displayOptions ) {
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
			image_id       => $imageID,
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
			DisplayRGB     => $isRGB
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
