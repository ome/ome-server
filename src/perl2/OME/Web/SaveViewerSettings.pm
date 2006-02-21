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
use base qw{ OME::Web };

use Log::Agent;
use OME::ViewerPreferences;
use OME::Tasks::PixelsManager;


sub getPageTitle {
    return "Open Microscopy Environment - Save Viewer Settings";
}

our $ONE_PIXEL_GIF = pack("H1614", join ('',qw /
	47494638396101000100f70031ffffffffffccffff99ffff66ffff33ffff00ff
	ccffffccccffcc99ffcc66ffcc33ffcc00ff99ffff99ccff9999ff9966ff9933
	ff9900ff66ffff66ccff6699ff6666ff6633ff6600ff33ffff33ccff3399ff33
	66ff3333ff3300ff00ffff00ccff0099ff0066ff0033ff0000ccffffccffcccc
	ff99ccff66ccff33ccff00ccccffcccccccccc99cccc66cccc33cccc00cc99ff
	cc99cccc9999cc9966cc9933cc9900cc66ffcc66cccc6699cc6666cc6633cc66
	00cc33ffcc33cccc3399cc3366cc3333cc3300cc00ffcc00cccc0099cc0066cc
	0033cc000099ffff99ffcc99ff9999ff6699ff3399ff0099ccff99cccc99cc99
	99cc6699cc3399cc009999ff9999cc9999999999669999339999009966ff9966
	cc9966999966669966339966009933ff9933cc99339999336699333399330099
	00ff9900cc99009999006699003399000066ffff66ffcc66ff9966ff6666ff33
	66ff0066ccff66cccc66cc9966cc6666cc3366cc006699ff6699cc6699996699
	666699336699006666ff6666cc6666996666666666336666006633ff6633cc66
	33996633666633336633006600ff6600cc66009966006666003366000033ffff
	33ffcc33ff9933ff6633ff3333ff0033ccff33cccc33cc9933cc6633cc3333cc
	003399ff3399cc3399993399663399333399003366ff3366cc33669933666633
	66333366003333ff3333cc3333993333663333333333003300ff3300cc330099
	33006633003333000000ffff00ffcc00ff9900ff6600ff3300ff0000ccff00cc
	cc00cc9900cc6600cc3300cc000099ff0099cc00999900996600993300990000
	66ff0066cc0066990066660066330066000033ff0033cc003399003366003333
	0033000000ff0000cc000099000066000033ee0000dd0000bb0000aa00008800
	0077000055000044000022000011000000ee0000dd0000bb0000aa0000880000
	77000055000044000022000011000000ee0000dd0000bb0000aa000088000077
	000055000044000022000011eeeeeeddddddbbbbbbaaaaaa8888887777775555
	5544444422222211111100000021f904010000ff002c00000000010001000008
	0400ff0504003b
/));


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
	$self->contentType ('image/gif');
    return ('IMAGE', $ONE_PIXEL_GIF);
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

	my $displayOptions = OME::Tasks::PixelsManager->getDisplayOptions( $pixels );

	my ( $redChannel, $greenChannel, $blueChannel, $greyChannel );

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
	OME::Tasks::PixelsManager->saveThumb( $pixels, $displayOptions );
	
	$session->commitTransaction();

	return $displayOptions;
}

1;
