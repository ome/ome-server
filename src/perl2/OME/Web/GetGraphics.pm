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
use CGI;
use OME::Tasks::ImageManager;
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
http://localhost/perl2/serve.pl?Page=GetGraphics&PixelsID=48

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
	
	$self->contentType('text/html');
	# Embedding in frames instead of object allows Mozilla > v1 to run it.
	$HTML .= <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<title>$nombre</title>
	<frameset rows="*">
		<frame src="serve.pl?Page=OME::Web::GetGraphics&BuildSVGviewer=1&PixelsID=$PixelsID">
	</frameset>
</html>
ENDHTML

	return ($HTML);
}


sub getImageAndPixels {
	my $self = shift;
	my $cgi	 = $self->CGI();
	
	return ( $self->{image}, $self->{pixels} )
		if $self->{image};
	
	if( $cgi->url_param('PixelsID') ) {
		$self->{pixels} = $self->Session()->Factory()->loadAttribute( 'Pixels', $cgi->url_param('PixelsID') )
			or die "Could not retreive Pixels attribute from PixelsID (".$cgi->url_param('PixelsID').")";
		$self->{image} = $self->{pixels}->image();
	} elsif( $cgi->url_param('ImageID') ) {
		$self->{image} = $self->Session()->Factory()->loadObject("OME::Image",$cgi->url_param('ImageID'))
			or die "Could not retreive Image from ImageID (".$cgi->url_param('ImageID').")";
		$self->{pixels} = $self->{image}->default_pixels();
	} else {
		die (ref $self)."->createOMEpage() needs ImageID or PixelsID as a url parameters.";	
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

	$JSinfo->{ imageID } = $imageID;
	$JSinfo->{ pixelsID } = $pixelsID;

	#######################
	# get Dimensions from image and make them readable
	my ($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bpp,$path)=$imageManager->getImageDim($image);
	my @dims = ( $sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bpp);
	$JSinfo->{ Dims } = '['.join (',', @dims).']';
	
	#######################
	# get channelLabels from image and make them JavaScript readable
	my @JSchannelLabels;
	my $channelLabels= $imageManager->getImageWavelengths($image);
	foreach my $channel (@$channelLabels){
		push @JSchannelLabels, "${$channel}{WaveNum}:\"${$channel}{Label}\"";
	}
	$JSinfo->{ channelLabels } = '{'.join(',',@JSchannelLabels).'}';

	#######################
	# Get Stack Statistics, convert to string representation of JS 3d associative array
	my $sh; # stats hash
	$sh = $imageManager->getImageStats($image)
		or die "Could not find Stack Statistics for image (id=$imageID).\n";
	my @ar1; # array 1
	for( my $c = 0;$c<scalar(@$sh);$c++) {
		my @ar2; # array 2
		for( my $t = 0; $t<scalar(@{$sh->[$c]}); $t++) {
			my $str = '{ '.join( ',', map( $_.': '.$sh->[$c][$t]->{$_}, keys %{ $sh->[$c][$t] } ) ).' }';
			push @ar2, $str;
		}
		push @ar1, '['.join( ',', @ar2 ).']';
	}
	$JSinfo->{ Stats } = '['.join( ',', @ar1 ).']';

	#######################
	# Compile Image Info
	my @imgInfo = (
		"name: '".$image->name()."'",
		'id: '  .$image->id(),
		"'primary pixels id': ".$image->DefaultPixels()->id(),
		"owner: '".$image->experimenter()->FirstName().' '.$image->experimenter()->LastName()."'"
	);
	$JSinfo->{ ImageInfo } = '{'.join( ', ', @imgInfo ).'}';


	#######################
	# Pixel list
	my @pixelList = $factory->findAttributes( "Pixels", image_id => $image->id() );
	$JSinfo->{ PixelList } = '['.join( ', ', map( $_->id(), @pixelList ) ).']';
		
	###############
	# transition to the image server
	if( $pixels->Repository()->IsLocal() ) {
		$JSinfo->{ CGI_URL }        = '"/cgi-bin/OME_JPEG"';
		$JSinfo->{ CGI_optionStr }  = '"&Path='.$path.'"';
		$JSinfo->{ use_omeis }     = 'false';
	} else {
		$JSinfo->{ CGI_URL }       = '"'.$pixels->Repository()->ImageServerURL().'"';
		$JSinfo->{ CGI_optionStr } = '""';
		$JSinfo->{ ImageServerID } = $pixels->ImageServerID();
		$JSinfo->{ use_omeis }     = 'true';
	}

	###############
	# additional URLs of CGIs
	$JSinfo->{ SaveDisplayCGI_URL } = '"/perl2/serve.pl?Page=OME::Web::SaveViewerSettings"';
	$JSinfo->{ SavePrefsCGI_URL } = '"/perl2/serve.pl?Page=OME::Web::SaveViewerSettings"';

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
	my $pixelsID           = $JSinfo->{ pixelsID };
	my $imageServerID      = $JSinfo->{ ImageServerID };
	my $imageInfo          = $JSinfo->{ ImageInfo };
	my $pixelList          = $JSinfo->{ PixelList };
	my $Stats              = $JSinfo->{ Stats };
	my $channelLabels      = $JSinfo->{ channelLabels };
	my $Dims               = $JSinfo->{ Dims };
	my $CGI_URL            = $JSinfo->{ CGI_URL };
	my $CGI_optionStr      = $JSinfo->{ CGI_optionStr };
	my $SaveDisplayCGI_URL = $JSinfo->{ SaveDisplayCGI_URL };
	my $SavePrefsCGI_URL   = $JSinfo->{ SavePrefsCGI_URL };
	my $theZ               = $JSinfo->{ theZ };
	my $theT               = $JSinfo->{ theT };
	my $isRGB              = $JSinfo->{ isRGB };
	my $CBW                = $JSinfo->{ CBW };
	my $RGBon              = $JSinfo->{ RGBon };
	my $toolBoxScale       = $JSinfo->{ toolBoxScale };
	my $use_omeis          = $JSinfo->{ use_omeis };

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
			xlink:href="/JavaScript/SVGviewer/ImageInfo.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/scale.js" />
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
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"><![CDATA[
ENDSVG

# dynamic initialization of JS objects goes here:
$SVG .= <<ENDSVG;
	// global variables
		var azap = new AntiZoomAndPan();

		// visualization & logic objects
		var image;
		var redScale, blueScale, greenScale, greyScale;
		var stats;
		var overlayManager;
		var viewerPreferences;
		var xyPlaneControls;
		var featureInfo;
		
		// theZ & theT are current values of z & t
		var theZ = $theZ;
		var theT = $theT;

		function init(e) {
			if ( window.svgDocument == null )
				svgDocument = e.ownerDocument;
			
			var channelLabels        = $channelLabels;
			var Stats			     = $Stats;
			var toolBoxScale	     = $toolBoxScale;
			var supplimentaryWindows = new Array();
			var windowControllers	 = new Array();

			image = new OMEimage($imageID,$pixelsID,Stats,$Dims,$CGI_URL,$CGI_optionStr, 
			                     $SaveDisplayCGI_URL, $CBW, $RGBon, $isRGB, $use_omeis,
			                     $imageServerID);
			image.realize( svgDocument.getElementById("image") );
			
			var actions = new Array();
			actions['zSlider']    = setTheZ;
			actions['tSlider']    = setTheT;
			
			// set up windows
			var toolboxLayer  = svgDocument.getElementById("toolboxLayer");

			stats = new Statistics( Stats, channelLabels );
			stats.buildToolBox( toolboxLayer );
			setTimeout( "stats.toolBox.hide()", 200 );
			supplimentaryWindows.push('Statistics');
			windowControllers['Statistics'] = stats;

			imgInfo = new ImageInfo( $imageInfo, $pixelList );
			imgInfo.buildToolBox( toolboxLayer );
			setTimeout( "imgInfo.toolBox.hide()", 200 );
			supplimentaryWindows.push('Image Info');
			windowControllers['Image Info'] = imgInfo;

			Scale.setClassData( image, channelLabels );
			redScale = new Scale('Red', toolboxLayer);
			blueScale = new Scale('Blue', toolboxLayer);
			greenScale = new Scale('Green', toolboxLayer);
			greyScale = new Scale('Grey', toolboxLayer);
			windowControllers['RedScale'] = redScale;
			windowControllers['BlueScale'] = blueScale;
			windowControllers['GreenScale'] = greenScale;
			windowControllers['GreyScale'] = greyScale;
			Scale.updateScaleDisplay(theT);
			setTimeout( "redScale.toolBox.hide()", 200 );
			setTimeout( "greenScale.toolBox.hide()", 200 );
			setTimeout( "blueScale.toolBox.hide()", 200 );
			setTimeout( "greyScale.toolBox.hide()", 200 );
			actions['setRedLogicalChannel']    = { obj: redScale, method: 'setLogicalChannel'};
			actions['setBlueLogicalChannel']    = { obj: blueScale, method: 'setLogicalChannel'};
			actions['setGreenLogicalChannel']    = { obj: greenScale, method: 'setLogicalChannel'};
			actions['setGreyLogicalChannel'] = { obj: greyScale, method: 'setLogicalChannel'};;
			actions['showRedScale']    = { obj: (redScale.toolBox), method: 'toggle'};
			actions['showBlueScale']    = { obj: (blueScale.toolBox), method: 'toggle'};
			actions['showGreenScale']    = { obj: (greenScale.toolBox), method: 'toggle'};
			actions['showGreyScale']    = { obj: (greyScale.toolBox), method: 'toggle'};

			viewerPreferences = new ViewerPreferences( $SavePrefsCGI_URL );
			viewerPreferences.buildToolBox( toolboxLayer );
			supplimentaryWindows.push('Preferences');			 
			windowControllers['Preferences'] = viewerPreferences;
			setTimeout( "viewerPreferences.toolBox.hide()", 200 );

ENDSVG

#################
# insert centroid data
if( $centroidData ) {
$SVG .= <<ENDSVG;
			var overlayBox  = svgDocument.getElementById("overlays");
			centroids = new CentroidOverlay( $centroidData );
			overlayBox.appendChild( centroids.makeOverlay() );
			overlayManager = new OverlayManager( overlayBox );
			overlayManager.addLayer( "Spots", centroids );

			overlayManager.buildToolBox( toolboxLayer );
			supplimentaryWindows.push('Overlay');			 
			windowControllers['Overlay'] = overlayManager;
			setTimeout( "overlayManager.switchOverlay(0)", 200 );
			setTimeout( "overlayManager.turnLayerOnOff(false)", 200 );
			setTimeout( "overlayManager.toolBox.hide()", 200 );
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
			supplimentaryWindows.push('Features');
			windowControllers['Features'] = featureInfo;

ENDSVG
}


$SVG .= <<ENDSVG;

			xyPlaneControls = new XYPlaneControls( actions, supplimentaryWindows,channelLabels, image );
			xyPlaneControls.buildToolBox( toolboxLayer );
			windowControllers['xyPlaneControls'] = xyPlaneControls;

			xyPlaneControls.setWindowControllers( windowControllers );
			viewerPreferences.setWindowControllers( windowControllers );

			redScale.tieLogicalChannelPopupList( xyPlaneControls.redPopupList );
			blueScale.tieLogicalChannelPopupList( xyPlaneControls.bluePopupList );
			greenScale.tieLogicalChannelPopupList( xyPlaneControls.greenPopupList );
			greyScale.tieLogicalChannelPopupList( xyPlaneControls.greyPopupList );
			greyScale.tieLogicalChannelPopupList( stats.logicalChannelPopupList );

			// finish setup & make controller
			azap.appendNode(toolboxLayer);
			mouseTrap = svgDocument.getElementById("mouseTrap");
			azap.appendNode(mouseTrap); 

			var CBW = image.getCBW();
			setTimeout( "xyPlaneControls.redPopupList.setSelectionByValue('"+ 
				xyPlaneControls.redPopupList.getItemList()[ CBW[0] ]
				+"')", 0 );
			setTimeout( "xyPlaneControls.greenPopupList.setSelectionByValue('"+ 
				xyPlaneControls.greenPopupList.getItemList()[ CBW[3] ]
				+"')", 0 );
			setTimeout( "xyPlaneControls.bluePopupList.setSelectionByValue('"+ 
				xyPlaneControls.bluePopupList.getItemList()[ CBW[6] ]
				+"')", 0 );
			setTimeout( "xyPlaneControls.greyPopupList.setSelectionByValue('"+ 
				xyPlaneControls.greyPopupList.getItemList()[ CBW[9] ]
				+"')", 0 );
			setTimeout( "viewerPreferences.resizeToolboxes("+toolBoxScale+", true)", 500);
			setTimeout( "xyPlaneControls.redButton.setState(" + (image.isRedOn() ? true : false) + ", true)", 200 );
			setTimeout( "xyPlaneControls.greenButton.setState(" + (image.isGreenOn() ? true : false) + ", true)", 200 );
			setTimeout( "xyPlaneControls.blueButton.setState(" + (image.isBlueOn() ? true : false) + ", true)", 200 );
			setTimeout( "xyPlaneControls.RGB_BWbutton.setState("+image.isInColor()+", true)", 200 );
//	this next line loads every plane in the image
//			setTimeout( "image.prefetchImages()", 0 );
			xyPlaneControls.setImageURL(image.getImageURL());
		}
		

	// these methods glue widgets to doing stuff
		// newZ has range of 0 to Z-1
		function setTheZ( newZ ) {
			theZ = Math.round(newZ);
			xyPlaneControls.zSlider.setValue(theZ);
			xyPlaneControls.zSlider.setLabel(null, null, (theZ + 1) + "/" + image.getDimZ() );
			if( overlayManager ) overlayManager.updateIndex( theZ, theT );
			var image_url = image.updatePic(theZ,theT);
			xyPlaneControls.setImageURL(image_url);
		}

		// newT has range of 0 to T-1
		function setTheT( newT ) {
			theT = Math.round(newT);
			xyPlaneControls.tSlider.setValue(theT);
			xyPlaneControls.tSlider.setLabel(null, null, "time (" + (theT+1) + "/" + image.getDimT() +")" );
			
			if( overlayManager) overlayManager.updateIndex( theZ, theT );
			var image_url = image.updatePic(theZ,theT);
			Scale.updateScaleDisplay(theT);
			stats.updateStats(theT);
			xyPlaneControls.setImageURL(image_url);
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
	<g id="overlays">
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
	
	my $factory = $self->Session()->Factory();
	
	my @spots = $factory->findObjects( "OME::Feature", image_id => $image->id(), tag => 'SPOT' );

	my $centroidDataJS;
	my @centroidData;
	my %moduleExecutions;
	my %features;
	my @featureData;
	my $featureDataJS;
	my @locations;
	
	push @locations, $factory->findAttributes( "Location", $_ ) 
		foreach ( @spots );
	
	foreach my $location( @locations ) { 

		my ($theX, $theY, $theZ) = map( sprintf( "%i", $_ + 0.5 ), ( $location->TheX, $location->TheY, $location->TheZ ) );

		my $moduleExecution = $location->module_execution();
		my $feature = $location->feature();
		$moduleExecutions{ $moduleExecution } = undef 
			unless exists $moduleExecutions{ $moduleExecution };
		$features{ $feature->id() } = $feature
			unless exists $features{ $feature->id() };

		my @timepoints = $factory->findAttributes( "Timepoint", $feature )
			or die "this spot (".$feature->id.") has no Timepoint\n";
		die "this spot (".$feature->id.")has multiple Timepoint" if @timepoints > 1;
		my $theT = $timepoints[0]->TheT();
		push ( @centroidData, 
			"{ theX: $theX, theY: $theY, theZ: $theZ, theT: $theT, moduleExecutionID: ".$moduleExecution->id().", featureID: ".$feature->id()." }" );
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
