# OME/Web/GetGraphics.pm
#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#		Massachusetts Institute of Technology,
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
#
# Written by:  
#	Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::GetGraphics;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use OME::Tasks::ImageManager;
use OME::Tasks::PixelsManager;
use OME::ViewerPreferences;
use base qw{ OME::Web };

use Benchmark;

=pod

=head1 NAME

OME::Web::GetGraphics - Web based Image Viewer

=head1 DESCRIPTION

GetGraphics is an Image Viewer built with SVG technology. 
It is part of the web UI and can be accessed with any internet browser that has an SVG plug-in.

=head1 Access

It is controlled by url parameters of ImageID,
	http://localhost/perl2/serve.pl?Page=GetGraphics&ImageID=57
or by Pixels Attribute ID.
http://localhost/perl2/serve.pl?Page=OME::Web::GetGraphics&PixelsID=48
Alternatively, a MEX ID can be provided to display overlays
http://localhost/perl2/serve.pl?Page=OME::Web::GetGraphics&MEX_ID=123

=head1 Author

Josiah Johnston <siah@nih.gov>

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = $class->SUPER::new(@_);

	return $self;
}

sub createOMEPage {
	my $self  = shift;
	my $cgi	  = $self->CGI();

	# switchboard
	if ( $cgi->url_param('BuildSVGviewer') ) {
		return('SVG', $self->BuildSVGviewer());
	} else {
		return('HTML', $self->FrameImageViewer());
	}
}


sub FrameImageViewer {
	my $self	  = shift;
	my $cgi		  = $self->CGI();
	my $HTML='';
	my ($image, $pixels) = $self->getImageAndPixels();
	my $ImageID   = $image->id();
	my $PixelsID  = $pixels->id();
	my $nombre    = $image->name();
	
	my $MEX_ID = $cgi->url_param('MEX_ID');
	my $param = "&BuildSVGviewer=1&PixelsID=$PixelsID";
	$param .= $MEX_ID ? "&MEX_ID=$MEX_ID" : '';

	$self->contentType('text/html');
	# Embedding in frames instead of object allows Mozilla > v1 to run it.
	$HTML .= <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>$nombre</title>
	<!-- Check if browsers have SVG support and record if we need to use
	     VBScript detection method if the number of MIME types is 0. -->
	<script language="JavaScript1.1" type="text/javascript">
	    // Variable to keep track of user's SVG support
	    var hasSVGSupport = false;

	    // Variable to indicate whether we need to use VBScript method to
	    // detect SVG support
	    var useVBMethod = false;

	    // Internet Explorer returns 0 as the number of MIME types,
	    // so this code will not be executed by it. This is our indication
	    // to use VBScript to detect SVG support.
	    if (navigator.mimeTypes != null
		 && navigator.mimeTypes.length > 0) {
	    	if (navigator.mimeTypes["image/svg-xml"] != null) {
		    hasSVGSupport = true;
		}
	    } else {
		useVBMethod = true;
	    }

	</script>

	<!-- Visual Basic Script to detect support of Adobe SVG plugin. This
	     code is not run on browsers which report they have MIME types, and
	     it is also not run by browsers which do not have VBScript support.
	 -->
	<script language="VBScript" type="text/vbscript">
		On Error Resume Next
		If useVBMethod = true Then
			hasSVGSupport = IsObject(CreateObject("Adobe.SVGCtl"))
		End If
	</script>

	<!-- Send user to appropriate URL based on their SVG support -->
	<script language="JavaScript1.1" type="text/javascript">

	    if (hasSVGSupport == true) {
		// Send user to URL which will display SVG images
	    	document.write( '<frameset rows="*"><frame src="serve.pl?Page=OME::Web::GetGraphics$param"></frameset>' );
	    } else {
		// Send user to URL which will display other graphics
	    	document.write( 'You Need an SVG plugin to use this viewer. You can get one for free from Adobe: <a href="http://www.adobe.com/svg/viewer/install/main.html">http://www.adobe.com/svg/viewer/install/main.html</a>');
	    }
	</script>
</head>
</html>
ENDHTML

	return ($HTML);
}


sub getImageAndPixels {
	my $self = shift;
	my $cgi	 = $self->CGI();
	
	return ( $self->{image}, $self->{pixels} )
		if $self->{image};
	
	if ( $cgi->url_param('MEX_ID') ) {
		my $mex = $self->Session()->Factory()->loadObject("OME::ModuleExecution",$cgi->url_param('MEX_ID'))
			or die "Could not retreive ModuleExecution from MEX_ID (".$cgi->url_param('MEX_ID').")";
		$self->{image} = $mex->image();
		$self->{pixels} = $mex->image()->default_pixels() if $self->{image};
	}

	if( $cgi->url_param('PixelsID') ) {
		$self->{pixels} = $self->Session()->Factory()->loadAttribute( 'Pixels', $cgi->url_param('PixelsID') )
			or die "Could not retreive Pixels attribute from PixelsID (".$cgi->url_param('PixelsID').")";
		$self->{image} = $self->{pixels}->image();
	} elsif( $cgi->url_param('ImageID') ) {
		$self->{image} = $self->Session()->Factory()->loadObject("OME::Image",$cgi->url_param('ImageID'))
			or die "Could not retreive Image from ImageID (".$cgi->url_param('ImageID').")";
		$self->{pixels} = $self->{image}->default_pixels();
	}

	unless ($self->{image} and $self->{pixels}) {
		die "Supplied MEX_ID (".$cgi->url_param('MEX_ID').") is not an image MEX, ".
			"and no ImageID or PixelsID parameters were supplied"
			if $cgi->url_param('MEX_ID');
		die "Failed to retreive an Image and a set of Pixels from supplied parameters.";
	}
	return ( $self->{image}, $self->{pixels} );
}


sub _getJSData {
	my $self	= shift;
	my $cgi		= $self->CGI();
	my $JSinfo	= {};
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $imageManager = OME::Tasks::ImageManager->new($session); 
	my ($image, $pixels) = $self->getImageAndPixels();
	my $imageID   = $image->id();
	my $pixelsID  = $pixels->id();

	$JSinfo->{ imageID }   = $imageID;
	$JSinfo->{ imageName } = "'".$image->name()."'";
	$JSinfo->{ pixelsID }  = $pixelsID;

	#######################
	# get Dimensions
	my ($bytesPerPixel, $isSigned, $isFloat) = 
		OME::Tasks::PixelsManager->getPixelTypeInfo( $pixels->PixelType );
	$JSinfo->{ Dims } = '['.join( ', ', (
		$pixels->SizeX, $pixels->SizeY, $pixels->SizeZ, $pixels->SizeC, $pixels->SizeT, $bytesPerPixel
		) ).']';
	
	#######################
	# get channelLabels from image and make them JavaScript readable
	my @JSchannelLabels;
	my $channelLabels= $imageManager->getImageWavelengths($image, $pixels);
	foreach my $channel (@$channelLabels){
		push @JSchannelLabels, "${$channel}{WaveNum}:\"${$channel}{Label}\"";
	}
	$JSinfo->{ channelLabels } = '{'.join(',',@JSchannelLabels).'}';

	#######################
	# Get Stack Statistics, convert to string representation of JS 3d associative array
	my $pixels_data = OME::Tasks::PixelsManager->loadPixels( $pixels );
	my $statsHash = $pixels_data->getStackStatistics();

	my @channel_indexed;
	foreach my $c ( sort keys %$statsHash ) {
		my @timepoint_indexed;
		foreach my $t( sort keys %{ $statsHash->{ $c } } ) {
			my $js_stats_record = 
				'{ '.join( ',', map( 
					$_.': '.$statsHash->{$c}{$t}{$_}, 
					sort grep( !m/^Sum|Centroid/, keys %{ $statsHash->{$c}{$t} } )
				) ).' }';
			push @timepoint_indexed, $js_stats_record;
		}
		push @channel_indexed, '['.join( ',', @timepoint_indexed ).']';
	}
	$JSinfo->{ Stats } = '['.join( ',', @channel_indexed ).']';


	#######################
	# Pixel list
	my @pixelList = $factory->findAttributes( "Pixels", image_id => $image->id() );
	$JSinfo->{ PixelList } = '['.join( ', ', map( $_->id(), @pixelList ) ).']';
		
	###############
	# image server stuff
	$JSinfo->{ ImageServerURL } = '"'.$pixels->Repository()->ImageServerURL().'"';
	$JSinfo->{ ImageServerID }  = $pixels->ImageServerID();

	###############
	# additional URLs of CGIs
	$JSinfo->{ SaveDisplayCGI_URL } = '"/perl2/serve.pl?Page=OME::Web::SaveViewerSettings"';
	$JSinfo->{ SavePrefsCGI_URL } = '"/perl2/serve.pl?Page=OME::Web::SaveViewerSettings"';
	$JSinfo->{ PlaneURLs } = '{'.join( ', ', 
		'imageInfo: "'.$self->getObjDetailURL( $image ).'"',
		# add more URLs here as needed
	).'}';

	###############
	# Saved display settings:
	my $displayOptions = $imageManager->getDisplayOptions($image);
	$JSinfo->{ theZ }  = sprintf( "%d", $displayOptions->{theZ} );
	$JSinfo->{ theT }  = sprintf( "%d", $displayOptions->{theT});
	$JSinfo->{ isRGB } = $displayOptions->{isRGB};
	$JSinfo->{ CBW }   = '[' . join( ',', @{$displayOptions->{CBW}} ) . ']';
	$JSinfo->{ RGBon } = '[' . join(",",@{$displayOptions->{RGBon}}) . ']';

	###############
	# Saved viewer settings:
	my $viewerPreferences = $factory->findObject( 'OME::ViewerPreferences', experimenter_id => $session->User()->id() );
	if( defined $viewerPreferences ) { 
		$JSinfo->{ toolBoxScale } = $viewerPreferences->toolbox_scale();
	} else {
		$JSinfo->{ toolBoxScale } = OME::ViewerPreferences->DefaultScale();
	}

	return $JSinfo;
}



# Build the SVG viewer.
sub BuildSVGviewer {
	# A server link needs to be made to src/JavaScript/ for the SVG JavaScript references to function
	my $self	  = shift;
	my $cgi		  = $self->CGI();
	my $SVG;
	
	my $JSinfo = $self->_getJSData();
	my $DatasetID          = $cgi->url_param('DatasetID') || 'null';
	my $imageID            = $JSinfo->{ imageID };
	my $imageName          = $JSinfo->{ imageName };
	my $pixelsID           = $JSinfo->{ pixelsID };
	my $imageServerID      = $JSinfo->{ ImageServerID };
	my $pixelList          = $JSinfo->{ PixelList };
	my $Stats              = $JSinfo->{ Stats };
	my $channelLabels      = $JSinfo->{ channelLabels };
	my $Dims               = $JSinfo->{ Dims };
	my $ImageServerURL     = $JSinfo->{ ImageServerURL };
	my $SaveDisplayCGI_URL = $JSinfo->{ SaveDisplayCGI_URL };
	my $SavePrefsCGI_URL   = $JSinfo->{ SavePrefsCGI_URL };
	my $planeURLs          = $JSinfo->{ PlaneURLs };
	my $theZ               = $JSinfo->{ theZ };
	my $theT               = $JSinfo->{ theT };
	my $isRGB              = $JSinfo->{ isRGB };
	my $CBW                = $JSinfo->{ CBW };
	my $RGBon              = $JSinfo->{ RGBon };
	my $toolBoxScale       = $JSinfo->{ toolBoxScale };

	my $overlayData        = $self->_getJSOverlay();
	my $centroidData       = $overlayData->{ centroids };
	my $featureData        = $overlayData->{ features };

	$self->contentType("image/svg+xml");
	$SVG = <<'ENDSVG';
<?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20010904//EN"
	"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd" [
	<!ATTLIST svg
		xmlns:a3 CDATA #IMPLIED
		a3:scriptImplementation CDATA #IMPLIED>
	<!ATTLIST script
		a3:scriptImplementation CDATA #IMPLIED>
]>
<svg xml:space="preserve" onload="init(evt)"
	xmlns="http://www.w3.org/2000/svg"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:a3="http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/"
	a3:scriptImplementation="Adobe">
	<!--			GUI classes				-->
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/widget.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/util.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/toolBox.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/multipaneToolBox.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/multipaneToolBox.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/slider.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/popupList.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/button.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/AntiZoomAndPan.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVG_GUI/skinLibrary.js" />
	<!--			Backend classes			-->
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/OMEimage.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/xyPlaneControls.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/featureInfo.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/overlayManager.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/overlay.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/centroid.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/ViewerPreferences.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/stats.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/Channels.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"><![CDATA[
ENDSVG

# dynamic initialization of JS objects goes here:
$SVG .= <<ENDSVG;
	// global variables
		var svgns = "http://www.w3.org/2000/svg";
		var azap = new AntiZoomAndPan();

		// visualization & logic objects
		var image;
		var stats;
		var overlayManager;
		var viewerPreferences;
		var xyPlaneControls;
		var featureInfo;
		var channels;
		
		// theZ & theT are current values of z & t
		var theZ = $theZ;
		var theT = $theT;

		function init(e) {
			var channelLabels        = $channelLabels;
			var Stats			     = $Stats;
			var toolBoxScale	     = $toolBoxScale;
			var windowControllers	 = new Array();

			image = new OMEimage($imageID, $imageName, $pixelsID, Stats, $Dims, $ImageServerURL,
			                     $SaveDisplayCGI_URL, $CBW, $RGBon, $isRGB,
			                     $imageServerID, $theZ, $theT);
			var imageBox = document.getElementById("image");
			image.realize( imageBox );
			
			// set up windows
			var toolboxLayer  = document.getElementById("toolboxLayer");

			stats = new Statistics( Stats, channelLabels, image );
			stats.buildToolBox( toolboxLayer );
			setTimeout( "stats.toolBox.hide()", 200 );
			windowControllers['Statistics'] = stats;

			channels = new Channels( image, channelLabels );
			channels.build_toolbox( toolboxLayer );
			setTimeout( "channels.toolBox.hide()", 500 );
			windowControllers['Channels'] = channels;

			viewerPreferences = new ViewerPreferences( $SavePrefsCGI_URL, image );
			viewerPreferences.buildToolBox( toolboxLayer );
			windowControllers['Preferences'] = viewerPreferences;
			setTimeout( "viewerPreferences.toolBox.hide()", 200 );

ENDSVG

#################
# insert centroid data
if( $centroidData ) {
$SVG .= <<ENDSVG;
			var overlayBox  = document.createElementNS (svgns, "g");
			overlayBox.setAttribute ("id", "overlays");
			imageBox.appendChild (overlayBox);

			centroids = new CentroidOverlay( $centroidData );
			overlayBox.appendChild( centroids.makeOverlay() );
			overlayManager = new OverlayManager( image, overlayBox );
			overlayManager.addLayer( "Spots", centroids );

			overlayManager.buildToolBox( toolboxLayer );
			windowControllers['Overlay'] = overlayManager;
			setTimeout( "overlayManager.switchOverlay(0)", 200 );
			setTimeout( "overlayManager.turnLayerOnOff(false)", 200 );
			setTimeout( "overlayManager.toolBox.hide()", 200 );
			overlayManager.updateIndex();
ENDSVG
}

#################
# insert feature data
if( $featureData ) {
$SVG .= <<ENDSVG;
			// Feature Information
			featureInfo = new FeatureInfo( $featureData );
			featureInfo.buildToolBox( toolboxLayer );
			setTimeout( "featureInfo.toolBox.hide()", 200 );
			windowControllers['Features'] = featureInfo;

ENDSVG
}


$SVG .= <<ENDSVG;

			xyPlaneControls = new XYPlaneControls( $planeURLs, image, stats, viewerPreferences, overlayManager );
			xyPlaneControls.buildToolBox( toolboxLayer );
			windowControllers['xyPlaneControls'] = xyPlaneControls;
			

			viewerPreferences.setWindowControllers( windowControllers );

			// finish setup & make controller
			azap.appendNode(toolboxLayer);
			mouseTrap = document.getElementById("mouseTrap");
			azap.appendNode(mouseTrap); 

			image.registerListener( 'updatePic', xyPlaneControls, 'updatePlaneURL' );

			setTimeout( "viewerPreferences.applyScale("+toolBoxScale+", true)", 500);
//			setTimeout( "image.moveImageLayer( 0, xyPlaneControls.toolBox.getActualHeight() )", 800 );
			setTimeout( "channels.sync()", 200 );
			setTimeout( "xyPlaneControls.sync()", 200 );
//	this next line loads every plane in the image
			setTimeout( "image.prefetchImages()", 0 );
		}
	]]></script>
	<g id="mouseTrap">
		<!-- The mouse only registers over elements. This rect prevents
			 loosing the mouse while moving the toolbox. It is drawn first
			 so it will be placed
			 on bottom so it will not trap mouse events unless nothing
			 else does. -->
		<rect width="100%" height="100%" fill="blue" opacity="0"/>	
	</g>
	<g id="image">
	</g>
	<g id="toolboxLayer">
	</g>
</svg>
ENDSVG
;

	return $SVG;
}

sub _getJSOverlay {
	my $self = shift;
	my ($image,$pixels) = $self->getImageAndPixels();
	my $cgi = $self->CGI();
	my $MEX_ID = $cgi->url_param('MEX_ID');
	return ( {centroids => undef, features => undef} ) unless $MEX_ID;

	my $factory = $self->Session()->Factory();
	
	my $iterator = $factory->findObjects( '@Location', {module_execution_id => $MEX_ID} );

	my $centroidDataJS;
	my @centroidData;
	my %features;
	my @featureData;
	my $featureDataJS;
	my $location;
		
	while ( $location = $iterator->next() ) { 

#		my ($theX, $theY, $theZ) = map( sprintf( "%i", $_ + 0.5 ), ( $location->TheX, $location->TheY, $location->TheZ ) );
		my ($theX, $theY, $theZ) = ($location->TheX(), $location->TheY(), sprintf( "%i", $location->TheZ() + 0.5) );

		my $moduleExecution = $location->module_execution();
		my $feature = $location->feature();
		my $featureID = $feature->id();
		$features{ $feature->id() } = $feature;

		my $timepoint = $factory->findAttribute( "Timepoint", $feature )
			or die "this spot ($featureID) has no Timepoint\n";
		my $theT = $timepoint->TheT();
		push ( @centroidData, 
			"{ theX: $theX, theY: $theY, theZ: $theZ, theT: $theT, moduleExecutionID: $MEX_ID, featureID: $featureID }" );
	}

	foreach my $feature( values %features ) {
		my ( $id, $tag, $name ) = ($feature->id(), $feature->tag(), $feature->name() );
		push ( @featureData, "{ ID: '$id', Tag: '$tag', Name: '$name' }" );
	}
	
	$featureDataJS  = '['.join( ',', @featureData ).']'
		if @featureData;
	$centroidDataJS = '['.join( ',', @centroidData ).']'
		if @centroidData;
	
	return { centroids => $centroidDataJS, features => $featureDataJS };

}

1;
