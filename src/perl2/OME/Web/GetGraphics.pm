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
use base qw{ OME::Web };

use Benchmark;

=pod

=head1 NAME

OME::Web::GetGraphics - Web based Image Viewer

=head1 DESCRIPTION

GetGraphics is an Image Viewer built with SVG technology. 
It is part of the web UI and can be accessed with any internet browser that has an SVG plug-in.

=head1 Access

It is controlled by url parameters of ImageID.
http://localhost/perl2/serve.pl?Page=GetGraphics&ImageID=57

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
	my @params = $cgi->url_param();

	# Error trap
	my $ImageID	  = $cgi->url_param('ImageID');
	if( not defined $ImageID ) {
		die (ref $self)."->createOMEpage() needs ImageID as a url parameters.";
	} else {
		# this validates the imageID by trying to load it.
		$self->getImage();
	}

	# switchboard
	if ( $cgi->url_param('BuildSVGviewer') ) {
		return('SVG', $self->BuildSVGviewer());
	} elsif ( $cgi->url_param('ImageID')) {
		return('HTML', $self->FrameImageViewer());
	}
}


sub FrameImageViewer {
	my $self	  = shift;
	my $cgi		  = $self->CGI();
	my $ImageID	  = $cgi->url_param("ImageID");
	my $HTML='';
	
	$self->contentType('text/html');
	# Embedding in frames instead of object allows Mozilla > v1 to run it.
	$HTML .= <<ENDHTML;
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<title>Image viewer</title>
	<frameset rows="*">
		<frame src="serve.pl?Page=OME::Web::GetGraphics&BuildSVGviewer=1&ImageID=$ImageID">
	</frameset>
</html>
ENDHTML

	return ($HTML);
}


sub getImage {
	my $self = shift;
	my $cgi	 = $self->CGI();
	
	return $self->{image} if exists $self->{image} and defined $self->{image};	
	$self->{image} = $self->Session()->Factory()->loadObject("OME::Image",$cgi->url_param('ImageID'))
		or die "Could not retreive Image from ImageID=".$cgi->url_param('ImageID')."\n";
	return $self->{image};
}


sub _getJSData {
	my $self	= shift;
	my $cgi		= $self->CGI();
	my $JSinfo	= {};
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $imageManager = OME::Tasks::ImageManager->new($session); 
	my $ImageID = $cgi->url_param('ImageID');

	my $image = $self->Session()->Factory()->loadObject("OME::Image",$ImageID)
		or die "Could not retreive Image from ImageID=$ImageID\n";

	# get Dimensions from image and make them readable
	my ($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bpp,$path)=$imageManager->getImageDim($image);
	my $dims = [ $sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bpp];
	
	# get channelLabels from image and make them JavaScript readable
	my @JSchannelLabels;
	my $channelLabels= $imageManager->getImageWavelengths($image);
	foreach my $channel (@$channelLabels){
		push @JSchannelLabels, "${$channel}{WaveNum}:\"${$channel}{Label}\"";
	}

	#######################
	# Get Stack Statistics, convert to string representation of JS 3d associative array
	my $sh; # stats hash
	$sh =$imageManager->getImageStats($image)
		or die "Could not find Stack Statistics for image (id=$ImageID).\n";
	my @ar1; # array 1
	for( my $c = 0;$c<scalar(@$sh);$c++) {
		my @ar2; # array 2
		for( my $t = 0; $t<scalar(@{$sh->[$c]}); $t++) {
			my $str = '{ '.join( ',', map( $_.': '.$sh->[$c][$t]->{$_}, keys %{ $sh->[$c][$t] } ) ).' }';
			push @ar2, $str;
		}
		push @ar1, '['.join( ',', @ar2 ).']';
	}
	my $JSstats = '['.join( ',', @ar1 ).']';
		
	###############
	# compile info
	$JSinfo->{ ImageID }			= $ImageID;
	$JSinfo->{ Stats }				= $JSstats;
	$JSinfo->{ channelLabels }		= '{'.join(',',@JSchannelLabels).'}';
	$JSinfo->{ Dims }				= '['.join (',', @$dims).']';
	$JSinfo->{ CGI_URL }			= '/cgi-bin/OME_JPEG';
	$JSinfo->{ CGI_optionStr }		= '&Path='.$path;
	$JSinfo->{ SaveDisplayCGI_URL } = '/perl2/serve.pl?Page=OME::Web::SaveViewerSettings';

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
		$JSinfo->{ toolBoxScale } = 1;
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
	my $DatasetID		   = $cgi->url_param('DatasetID') || 'null';
	my $ImageID			   = $JSinfo->{ ImageID };
	my $Stats			   = $JSinfo->{ Stats };
	my $channelLabels      = $JSinfo->{ channelLabels };
	my $Dims			   = $JSinfo->{ Dims };
	my $CGI_URL			   = $JSinfo->{ CGI_URL };
	my $CGI_optionStr	   = $JSinfo->{ CGI_optionStr };
	my $SaveDisplayCGI_URL = $JSinfo->{ SaveDisplayCGI_URL };
	my $theZ			   = $JSinfo->{ theZ };
	my $theT			   = $JSinfo->{ theT };
	my $isRGB			   = $JSinfo->{ isRGB };
	my $CBW				   = $JSinfo->{ CBW };	# known to the svg viewer as WBW - when the svg viewer was developed, ChannelNumber was called Wavenumber. the svg hasn't been updated to reflect this change in nomenclature.
	my $RGBon			   = $JSinfo->{ RGBon };
	my $toolBoxScale	   = $JSinfo->{ toolBoxScale };
	
	my $overlayData		   = $self->_getJSOverlay();
	my $centroidData	   = $overlayData->{ centroids };
	my $featureData		   = $overlayData->{ features };

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
			xlink:href="/JavaScript/SVGviewer/scale.js" />
	<script type="text/ecmascript" a3:scriptImplementation="Adobe"
			xlink:href="/JavaScript/SVGviewer/imageControls.js" />
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
	// GUI components
		var controlsToolBox;
		var infoButton;
		var azap = new AntiZoomAndPan();

	// backend components
		var image;
		var redScale, blueScale, greenScale, greyScale;
		var stats;
		var overlayManager;
		var viewerPreferences;
		var imageControls;
		var featureInfo;
		
	// constants & references
		var channelLabels      = $channelLabels;
		var Stats			   = $Stats;
		var Dims			   = $Dims;
		var DatasetID		   = $DatasetID;
		// Z and T are dims of z and t
		var Z				   = Dims[2];
		var T				   = Dims[4];
		var SaveDisplayCGI_URL = "$SaveDisplayCGI_URL";
		var toolBoxScale	   = $toolBoxScale;

		var supplimentaryWindows = new Array();
		var windowControllers	 = new Array();
		
	// global variables
		// theZ & theT are current values of z & t
		var theZ = $theZ;
		var theT = $theT;

		function init(e) {
			if ( window.svgDocument == null )
				svgDocument = e.ownerDocument;
			
			// initialize back end
			image = new OMEimage($ImageID,$Stats,$Dims,"$CGI_URL","$CGI_optionStr", 
				SaveDisplayCGI_URL, $CBW, $RGBon, $isRGB, DatasetID);
			image.realize( svgDocument.getElementById("image") );

			// initialize frontend
			controlToolBox = new toolBox(
				50, 30, 200, 150,
				skinLibrary["menuBar"],
				skinLibrary["hideControl"],
				skinLibrary["GUIbox"],
				'noclip'
			);
			controlToolBox.setLabel(90,12,"Image Controls")
			controlToolBox.getLabel().setAttributeNS(null, "text-anchor", "middle");
			
			
			// realize the GUI elements in the appropriate containers
			var toolboxLayer  = svgDocument.getElementById("toolboxLayer");
			controlToolBox.realize(toolboxLayer);
			
			imageControls = new ImageControls(	);
			var actions = new Array();
			actions['zSlider']    = updateTheZ;
			actions['zUp']        = zUp;
			actions['zDown']      = zDown;
			actions['zAnimUp']    = zAnimUp;
			actions['zAnimDown']  = zAnimDown;
			actions['tSlider']    = updateTheT;
			actions['tUp']        = tUp;
			actions['tDown']      = tDown;
			actions['tAnimUp']    = tAnimUp;
			actions['tAnimDown']  = tAnimDown;
			actions['OnOffR']     = { obj: image, method: 'setRedOn' };
			actions['OnOffG']     = { obj: image, method: 'setGreenOn' };
			actions['OnOffB']     = { obj: image, method: 'setBlueOn' };
			actions['Save']       = { obj: image, method: 'saveState' };
			actions['preload']    = { obj: image, method: 'prefetchImages' };
			actions['RGB2BW']     = switchRGB_BW;
			actions['openWindow'] = openWindow;
			
			// set up supplimentary windows
			stats = new Statistics( Stats, channelLabels );
			stats.buildToolBox( toolboxLayer );
			setTimeout( "stats.toolBox.hide()", 200 );
			supplimentaryWindows.push('Statistics');
			windowControllers['Statistics'] = stats;
			
			
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
			actions['setGreyLogicalChannel'] = setGreyLogicalChannel;
			actions['showRedScale']    = { obj: (redScale.toolBox), method: 'toggle'};
			actions['showBlueScale']    = { obj: (blueScale.toolBox), method: 'toggle'};
			actions['showGreenScale']    = { obj: (greenScale.toolBox), method: 'toggle'};
			actions['showGreyScale']    = { obj: (greyScale.toolBox), method: 'toggle'};

			viewerPreferences = new ViewerPreferences( controlToolBox  );
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
			viewerPreferences.setWindowControllers( windowControllers );

			controlToolBox.getGUIbox().appendChild( imageControls.buildControls( actions, supplimentaryWindows,channelLabels ) );
			redScale.tieLogicalChannelPopupList( imageControls.redPopupList );
			blueScale.tieLogicalChannelPopupList( imageControls.bluePopupList );
			greenScale.tieLogicalChannelPopupList( imageControls.greenPopupList );
			greyScale.tieLogicalChannelPopupList( imageControls.greyPopupList );

			// finish setup & make controller
			azap.appendNode(toolboxLayer);
			mouseTrap = svgDocument.getElementById("mouseTrap");
			azap.appendNode(mouseTrap); 

			var CBW = image.getCBW();
			setTimeout( "imageControls.redPopupList.setSelectionByValue('"+ 
				imageControls.redPopupList.getItemList()[ CBW[0] ]
				+"')", 0 );
			setTimeout( "imageControls.greenPopupList.setSelectionByValue('"+ 
				imageControls.greenPopupList.getItemList()[ CBW[3] ]
				+"')", 0 );
			setTimeout( "imageControls.bluePopupList.setSelectionByValue('"+ 
				imageControls.bluePopupList.getItemList()[ CBW[6] ]
				+"')", 0 );
			setTimeout( "imageControls.greyPopupList.setSelectionByValue('"+ 
				imageControls.greyPopupList.getItemList()[ CBW[9] ]
				+"')", 0 );
			setTimeout( "viewerPreferences.resizeToolboxes("+(toolBoxScale-1)+")", 500);
			setTimeout( "imageControls.redButton.setState(" + (image.isRedOn() ? true : false) + ", true)", 200 );
			setTimeout( "imageControls.greenButton.setState(" + (image.isGreenOn() ? true : false) + ", true)", 200 );
			setTimeout( "imageControls.blueButton.setState(" + (image.isBlueOn() ? true : false) + ", true)", 200 );
			setTimeout( "imageControls.RGB_BWbutton.setState("+image.isInColor()+", true)", 200 );
//	this next line loads every plane in the image
//			setTimeout( "image.prefetchImages()", 0 );
			zVal = ( Z == 1 ? 0 : theZ/(Z-1)*100 );
			imageControls.zSlider.setValue(zVal,true);
			tVal = ( T == 1 ? 0 : theT/(T-1)*100 );
			imageControls.tSlider.setValue(tVal,true);

		}
		

	// these actions connect GUI with backend
		// newZ has range of 0 to Z-1
		function setTheZ( newZ ) {
			if( Z > 1 )
				updateTheZ( newZ / (Z-1) *100 );
		}
		// this accepts a percentage (0-100)
		function updateTheZ(data) {
			data=Math.round(data/100*(Z-1));
			var sliderVal = (Z==1 ? 0 : Math.round(data/(Z-1)*100) );
			imageControls.zSlider.setValue(sliderVal);
			imageControls.zSlider.setLabel(null, null, (data + 1) + "/" + Z );
			theZ=data;
			
			if( overlayManager ) overlayManager.updateIndex( theZ, theT );
			image.updatePic(theZ,theT);
		}
		function zUp() {
			var newZ = (theZ< Z-1 ? theZ + 1 : theZ)
			var sliderVal = ( Z==1 ? 0 : Math.round( newZ/(Z-1)*100 ) );
			updateTheZ(sliderVal);
		
		}
		function zDown() {
			var data = (theZ> 0 ? theZ - 1 : theZ)
			var sliderVal = ( Z==1 ? 0 : Math.round( data/(Z-1)*100 ) );
			updateTheZ(sliderVal);
		}
		function zAnimUp() {
			if(Z > 1) {
				for(i=theZ;i<Z;i++)
					setTimeout("updateTheZ(" + (i/(Z-1)) + "*100)", (i-theZ)*100);
			}
		}
		function zAnimDown() {
			if(Z > 1) {
				for(i=theZ;i>=0;i--)
					setTimeout("updateTheZ(" + (i/(Z-1)) + "*100)", (theZ-i)*100);
			}
		}

		// newT has range of 0 to Z-1
		function setTheT( newT ) {
			if( T > 1 ) 
				updateTheT( newT / (T-1) *100 );
		}
		// this accepts a percentage (0-100)
		function updateTheT(data) {
			theT=Math.round(data/100*(T-1));
			var sliderVal = ( T==1 ? 0 : Math.round(theT/(T-1)*100) );
			imageControls.tSlider.setValue(sliderVal);
			imageControls.tSlider.setLabel(null, null, "time (" + (theT+1) + "/" + T +")" );
			
			if( overlayManager) overlayManager.updateIndex( theZ, theT );
			image.updatePic(theZ,theT);
			Scale.updateScaleDisplay(theT);
			stats.updateStats(theT);
		}
		function tUp() {
			var data = (theT< T-1 ? theT+1 : theT)
			var sliderVal = ( T==1 ? 0 : Math.round( data/(T-1)*100 ) );
			updateTheT(sliderVal);
		}
		function tDown() {
			var data = (theT> 0 ? theT -1 : theT)
			var sliderVal = ( T==1 ? 0 : Math.round( data/(T-1)*100 ) );
			updateTheT(sliderVal);
		}
		function tAnimUp() {
			if(T>1) {
				for(i=theT;i<T;i++)
					setTimeout("updateTheT(" + (i/(T-1)) + "*100)", (i-theT)*100);
			}
		}
		function tAnimDown() {
			if(T>1) {
				for(i=theT;i>=0;i--)
					setTimeout("updateTheT(" + (i/(T-1)) + "*100)", (theT-i)*100);
			}
		}

		// popupLists controlling channels
		function setGreyLogicalChannel(item) {
			greyScale.setLogicalChannel(item);
			stats.changeWavenumber( item );
		}
		
		function switchRGB_BW(val) {
			//	decide which way to flip
			if(val) {	// val == true means mode = RGB
				imageControls.BWpopupListBox.setAttribute( "display", "none" );
				imageControls.RGBpopupListBox.setAttribute( "display", "inline" );
			}
			else {	// mode = BW
				imageControls.BWpopupListBox.setAttribute( "display", "inline" );
				imageControls.RGBpopupListBox.setAttribute( "display", "none" );
			}
			image.setDisplayRGB_BW(val);
		}
		
		function openWindow(x) {
			windowControllers[ supplimentaryWindows[ x ] ].toolBox.unhide();
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
	my $image = $self->getImage();
	my $pixels = $image->DefaultPixels();
	
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
