#!/usr/bin/perl
# Author:  Ilya G. Goldberg (igg@mit.edu)
# Copyright 1999-2001 Ilya G. Goldberg
# This file is part of OME.
# 
#     OME is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     OME is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with OME; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
#

use strict;
use OMEpl;
use Image::Magick;
use CGI;
use vars qw ($OME $cgi);
$cgi = new CGI;

my $datasetID = $cgi->url_param('ID');
$datasetID = $cgi->param('DatasetID') unless defined $datasetID;
die "DatasetID must be specified in the URL (i.e. ?ID=123) or in the POST request (DatasetID=123)"
	unless defined $datasetID;
if ($cgi->url_param('JPEG')) {
	DrawJPEG ($datasetID);
} else {
	DrawForm ($datasetID);
}


sub DrawForm {
my $datasetID = shift;
$OME = new OMEpl;
$cgi = $OME->cgi;
my ($datasetName,$datasetPath,$filePath);

my ($brightness,$contrast,$normalize);

	my $datasetJS = MakeJSdataset ($datasetID);	

	print $OME->CGIheader (-type   => 'text/html',
							-expires => '-1d');
	print $cgi->start_html (-title => $cgi->param('DatasetName'));
	print '<CENTER>',$cgi->h3($cgi->param('DatasetName')),'</CENTER>';
	
	print qq %
<script language="JavaScript">
	<!--

function MakeImageURL (form,oldURL) {
var ImageTypeElements = form.ImageType;
var ImageType;
var i;
var newURL;
var params = [form.DatasetID,form.DatasetName,form.DatasetPath,form.Width,form.Height,form.TheZ,form.TheT,form.Thresholds,form.Clips,form.Waves];
	for (i = 0; i < ImageTypeElements.length; i++) {
		if (ImageTypeElements[i].checked) ImageType = ImageTypeElements[i].value;
	}

	if (oldURL.indexOf("?") > 0) {
		newURL = oldURL.substr(0,oldURL.indexOf("?")+1);
	} else {
		newURL = oldURL.valueOf + "?";
	}
	newURL += "ImageType="+ImageType;
	
	for (i=0; i<params.length; i++ ) {
		newURL += ";"+escape(params[i].name)+"="+escape(params[i].value);
	}
	
	newURL += ";JPEG=1";
	return newURL;
}

function MakeGETURL(form,oldURL) {
	numElements = form.length;
	if (oldURL.indexOf("?") > 0) {
		newURL = oldURL.substr(0,oldURL.indexOf("?")+1);
	} else {
		newURL = oldURL.valueOf + "?";
	}

	for (i=0;i<numElements; i++) {
		element = form.elements[i];
		if (element.type != "radio" || element.checked == "1") {
			newURL += ";"+escape(element.name)+"="+escape(element.value);
		}
	}
	return newURL;
}

function ReloadImage (theForm,theImage,theDataset) {
	VerifyForm (theForm,theDataset);
	theImage.src = MakeImageURL (theForm,theImage.src);
}

function AddVal (theElement,theProperty,theValue) {
	theElement[theProperty] = Number ( Number(theElement[theProperty]) + theValue );
	ReloadImage(document.forms[0],document.theImage,document.dataset);
}

function SetMin (theDataset,theElement,theRGBidx) {
	var waveElements = theDataset.WaveElements[theRGBidx];
	waveElements[theElement] = theDataset.statsMin[theDataset.waves[theRGBidx]][theDataset.theT];
	ReloadImage(document.forms[0],document.theImage,document.dataset);
}

function SetMean (theDataset,theElement,theRGBidx) {
	var waveElements = theDataset.WaveElements[theRGBidx];
	waveElements[theElement] = theDataset.statsMean[theDataset.waves[theRGBidx]][theDataset.theT];
	ReloadImage(document.forms[0],document.theImage,document.dataset);
}

function SetMax (theDataset,theElement,theRGBidx) {
	var waveElements = theDataset.WaveElements[theRGBidx];
	waveElements[theElement] = theDataset.statsMax[theDataset.waves[theRGBidx]][theDataset.theT];
	ReloadImage(document.forms[0],document.theImage,document.dataset);
}

function AddSigma (theDataset,theElement,theRGBidx,numSigmas) {
	var waveElements = theDataset.WaveElements[theRGBidx];
//	var oldVal = waveElements[theElement];
	waveElements[theElement] += (theDataset.statsSigma[theDataset.waves[theRGBidx]][theDataset.theT])*numSigmas;
//	alert ("Adding "+numSigmas+" * "+theDataset.statsSigma[theDataset.waves[theRGBidx]][theDataset.theT]+" To "+oldVal+" = "+waveElements[theElement]);
	ReloadImage(document.forms[0],document.theImage,document.dataset);
}

function round(number,X) {
// rounds number to X decimal places, defaults to 2
X = (!X ? 2 : X);
return Math.round(number*Math.pow(10,X))/Math.pow(10,X);
}

function FormatSigmaString (theNum) {
	sigmas = round (theNum,1);
	var sigmaString="";
	if (sigmas >= 0) {sigmaString = String("+");} else {sigmaString = String("-");}
	if (sigmas >-1 && sigmas < 1 && String(sigmas).indexOf("0") != 0) {sigmaString += String("0");}
	sigmaString += String(Math.abs(sigmas));
	if (sigmaString.indexOf(".") == -1) {sigmaString += ".0";}
	return "mean"+sigmaString+"s";
}

function ChangeClipThreshType (theElement) {
	if (theElement.selectedType == "Statistic") {
		theElement.selectedType = "Manual"
	} else {
		theElement.selectedType = "Statistic"
	}
}

function VerifyWaveControls (theDataset,time,theRGBidx) {
	var waveElements = theDataset.WaveElements[theRGBidx];
	var waveElement = waveElements.Wave;
	var wave = Number (waveElement.wavenumber);
	var thresh = waveElements.ThresholdValue;
	var clip = waveElements.ClipValue;

//	alert (waveElements.Wave.name+",thresh: "+thresh+", clip: "+clip);

	if (wave >= theDataset.numWaves) {wave = theDataset.numWaves-1;}
	if (wave < 0) {wave = 0;}
	if (wave != theDataset.waves[theRGBidx]) {
//		alert (waveElements.Wave.name+" changed to "+wave);
		waveElements.ThresholdValue = theDataset.thresholds[wave];
		waveElements.ClipValue = theDataset.clips[wave];
	}

	waveElement.wavenumber = theDataset.waves[theRGBidx] = wave;
	waveElement.value = theDataset.wavelengths[wave];
	if (time != theDataset.theT) {
//		alert ("Time changed to "+time);
		waveElements.ThresholdValue = theDataset.statsMean[wave][time] + (theDataset.statThresholds[wave] * theDataset.statsSigma[wave][time]);
		waveElements.ClipValue = theDataset.statsMean[wave][time] + (theDataset.statClips[wave] * theDataset.statsSigma[wave][time]);
	}

	thresh = waveElements.ThresholdValue;
	clip = waveElements.ClipValue;

	if (thresh > clip) {
		clip = theDataset.clips[wave];
		thresh = theDataset.thresholds[wave];
	}
	if (thresh < theDataset.statsMin[wave][time]) thresh = theDataset.statsMin[wave][time];
	if (thresh > theDataset.statsMax[wave][time]) thresh = theDataset.statsMax[wave][time];
	if (clip < theDataset.statsMin[wave][time]) clip = theDataset.statsMin[wave][time];
	if (clip > theDataset.statsMax[wave][time]) clip = theDataset.statsMax[wave][time];

	if (thresh != theDataset.thresholds[wave]) {
//		alert (waveElement.name+": Threshold changed for wave #"+wave);
		theDataset.thresholds[wave] = thresh;
		DisplayClipThresh (theDataset);
	}
	if (clip != theDataset.clips[wave]) {
//		alert (waveElement.name+": Clip changed for wave #"+wave);
		theDataset.clips[wave] = clip;
		DisplayClipThresh (theDataset);
	}

	waveElements.ThresholdValue = thresh;
	waveElements.ClipValue = clip;

	theDataset.statThresholds[wave] = (thresh - theDataset.statsMean[wave][time]) / theDataset.statsSigma[wave][time];
	theDataset.statClips[wave] = (clip - theDataset.statsMean[wave][time]) / theDataset.statsSigma[wave][time];

	
}

function DisplayClipThresh (theDataset) {
var waveElements;
var waveElement;
var threshTypeElement;
var threshTextElement;
var clipTypeElement;
var clipTextElement;
var wave;
var thresh;
var clip;
var threshType;
var clipType;
var theRGBidx;

	for (theRGBidx=0;theRGBidx<4;theRGBidx++) {
		waveElements = theDataset.WaveElements[theRGBidx];
		waveElement = waveElements.Wave;
		threshTypeElement = waveElements.ThreshType;
		threshTextElement = waveElements.ThreshText;
		clipTypeElement = waveElements.ClipType;
		clipTextElement = waveElements.ClipText;
		wave = Number (waveElement.wavenumber);
		thresh = theDataset.thresholds[wave];
		clip = theDataset.clips[wave];

		waveElements.ThresholdValue = thresh;
		waveElements.ClipValue = clip;



		if (threshTypeElement.selectedIndex > -1) {
			var threshSelected = threshTypeElement.options[threshTypeElement.selectedIndex];
			threshType = threshSelected.text;
		}
		if (clipTypeElement.selectedIndex > -1){
			var clipSelected = clipTypeElement.options[clipTypeElement.selectedIndex];
			clipType = clipSelected.text;
		}
	
		if (threshType == "Statistic") {
			threshTextElement.value = FormatSigmaString(theDataset.statThresholds[wave]);
		} else {
			threshTextElement.value = Math.round(thresh);
		}
		if (clipType == "Statistic") {
			clipTextElement.value = FormatSigmaString(theDataset.statClips[wave]);
		} else {
			clipTextElement.value = Math.round(clip);
		}
	}
}

function VerifyForm (theForm,theDataset) {
	var time = Math.round(Number (theForm.TheT.value));
	var theZ = Math.round(Number (theForm.TheZ.value));
	if (theZ > theDataset.numZ-1) {theZ = theDataset.numZ-1;}
	if (theZ < 0) {theZ = 0;}
	if (time > theDataset.numT-1) {time = theDataset.numT-1;}
	if (time < 0) {time = 0;}
	theForm.TheT.value = time;
	theForm.TheZ.value = theZ;
	VerifyWaveControls (theDataset,time,0);
	VerifyWaveControls (theDataset,time,1);
	VerifyWaveControls (theDataset,time,2);
	VerifyWaveControls (theDataset,time,3);
	DisplayClipThresh (theDataset);
	theForm.Clips.value = theDataset.clips.join(',');
	theForm.Thresholds.value = theDataset.thresholds.join(',');
	theForm.Waves.value = theDataset.waves.join(',');
	theForm.StatThresholds.value = theDataset.statThresholds.join(',');
	theForm.StatClips.value = theDataset.statClips.join(',');
	
	theDataset.theT = time;
	theDataset.theZ = theZ;



//	alert ("Min: "+theForm.Min.value+"\\nMax: "+theForm.Max.value+"\\nMean: "+theForm.Mean.value+"\\nSigma: "+theForm.Sigma.value);
//	alert ("Wavelength: "+theDataset.wavelengths[wave]);
}

$datasetJS
	document.dataset = dataset;

	focus();
	//-->
</script>
%;


	print $cgi->startform(-name=>'datasetPreviewForm');

	print $cgi->hidden('DatasetID');
	print $cgi->hidden('DatasetName');
	print $cgi->hidden('DatasetPath');
	print $cgi->hidden('Width');
	print $cgi->hidden('Height');
	print $cgi->hidden('NumZ');
	print $cgi->hidden('NumT');
	print $cgi->hidden('NumWaves');
	print $cgi->hidden('Wavelengths');
	print $cgi->hidden('Waves');

	print $cgi->hidden('Clips');
	print $cgi->hidden('Thresholds');
	print $cgi->hidden('ClipTypes');
	print $cgi->hidden('ThreshTypes');
	print $cgi->hidden('StatClips');
	print $cgi->hidden('StatThresholds');

	my @tableRows;
	my ($col,$row);
	my @radioButtons;

	@radioButtons = $cgi->radio_group(-name=>'ImageType',-values=>['Greyscale','RGB'],
		-default=>$cgi->param('ImageType'),-override=>1,
		-onClick=>'ReloadImage (this.form,theImage,document.dataset)');
	$col = $radioButtons[0].' &nbsp &nbsp &nbsp '.$radioButtons[1];
	$row = $cgi->td({align=>'center',nowrap=>undef},$col);
	push (@tableRows,$row);

	$col=qq /<hr align="center" noshade size="2">/;
	$row = $cgi->td({nowrap=>undef,height=>'2'},$col);
	push (@tableRows,$row);
	
	$col = "Z Section: ".$cgi->textfield(-name=>'TheZ',-size=>3);
	$col .= PlusMinusControl ('TheZ');
	$col .= ' &nbsp &nbsp ';
	
	$col .= "Timepoint: ".$cgi->textfield(-name=>'TheT',-size=>3);
	$col .= PlusMinusControl ('TheT');
	$row = $cgi->td({nowrap=>undef,height=>'20',valign=>'middle'},$col);
	push (@tableRows,$row);
	
	$col=qq /<hr align="center" noshade size="2">/;
	$row = $cgi->td({nowrap=>undef,height=>'2'},$col);
	push (@tableRows,$row);

	my $JS = '';
#	my $table;
	DrawControls ('Grey',\@tableRows,\$JS);
	$col=qq /<hr align="center" noshade size="3">/;
	$row = $cgi->td({nowrap=>undef,height=>'3'},$col);
	push (@tableRows,$row);
#	$table = $cgi->Tr(\@tableRows);
#	@tableRows = ();

	DrawControls ('Red',\@tableRows,\$JS);
#	$table .= $cgi->Tr({bgcolor=>"#FF6666"},\@tableRows);
	$col=qq /<hr align="center" noshade size="3">/;
	$row = $cgi->td({nowrap=>undef,height=>'3'},$col);
	push (@tableRows,$row);
#	$table .= $cgi->Tr($row);
#	@tableRows = ();

	DrawControls ('Green',\@tableRows,\$JS);
#	$table .= $cgi->Tr({bgcolor=>"#00FF66"},\@tableRows);
	$col=qq /<hr align="center" noshade size="3">/;
	$row = $cgi->td({nowrap=>undef,height=>'3'},$col);
	push (@tableRows,$row);
#	$table .= $cgi->Tr($row);
#	@tableRows = ();

	DrawControls ('Blue',\@tableRows,\$JS);
#	$table .= $cgi->Tr({bgcolor=>"#0066FF"},\@tableRows);

	print $cgi->table({-border=>0,-cellspacing=>0,-cellpadding=>0,-align=>'left'},
#		$table
		$cgi->Tr(\@tableRows)
		);

	print $cgi->endform();
	print qq %
<script language="JavaScript">
	<!--
	$JS
	VerifyForm (document.forms[0],dataset);
	//-->
</script>
%;

	my $JPEG_URL = $cgi->self_url.';JPEG=1;baslkdas=12,234,234';
	print qq (<img name='theImage' src="$JPEG_URL" align="right">);
	print $cgi->end_html();
	$OME->Finish();
}

# MakeJSdataset
# This subroutine is supposed to build up a JavaScript version of the dataset object so that the browser can
# request new images by specifying all the parameters in the URL instead of doing a form submission.
# This sub also sets a bunch of CGI parameters to cache these which will end up as hidden form elements.
# Probably should be one or the other.
# The other thing we want to accomplish eventually is for the user settings to remain "sticky" when
# datasets are switched.  To do the stickyness, pass the URL parameters collected below for the old dataset along with the new dataset ID.
# Essentially, we want to construct a dataset object consistent with the ID that we got (its fatal not to have one).
# Since this sub is called only once when a new dataset if being viewed, the DB connection overhead isn't too bad, so
# we go ahead and construct a full JavaScript dataset object from its DB counterpart.
# The stickyness should be implemented like so:
#   The selected wavelengths (red, green, blue grey) are preserved if they exist in the new dataset.
#     * The preserved value is the EmWavelength, not the wave number.
#   The selected clips and thresholds are preserved.
#     If the clips/thresholds are manual, then the raw value is preserved.
#     If the clips/thresholds are statistical then the statistical value is preserved, not the raw value.
#   The current Z section and timepoint are preserved.
# What happens to clips/thresholds when the user changes wavelengths/z sections/timepoints on the form?
#   The clip/thresh and its manual/statistical setting goes along with the wavelength.
#   Changing the Z section doesn't affect clips/thresholds.
#   Changing the timepoint should set the clip/thresh to the statistical equivalent (if statistical is selected) for the
#     new timepoint.  Otherwise (in manual setting) the clip/thresh retains its raw value.
#     The question is:  Should the clips/thresholds be "stuck to" their respective timepoints?
#        The scenario is the user adjusts clip/thresh, then starts going through timpoints.
#        Seems like the new timepoint should retain the previous timepoint's clip/thresh settings,
#        and not use any clip/thresh settings previously stored for the new timepoint.
#
# The JS object (structure, more like) looks something like:
# {width,height,numZ,numT,numWaves,theZ,theT  // dataset dimensions and the currently selected Z-section and timepoint.
#  	statsMin[numWaves][numT],
#   statsMax[numWaves][numT],
#   statsMean[numWaves][numT],
#   statsSigma[numWaves][numT],
#   wavelengths[numWaves],     // The EmWavelengths in wavenumber order.  If EmWavelengths are NULL, then they are the wavenumbers+1.
#// These are cached user settings.
#   threshTypes[numWaves],     // Threshold types (Manual or Statistic)
#   clipTypes[numWaves],
#   thresholds[numWaves],      // A threshold and clip is stored for each wave.  These are raw values.
#   clips[numWaves],
#   statClips[numWaves],       // These are statistical (+/- number of sigmas above/below the mean)
#   statThresholds[numWaves],  // They are used as URL parameters when switching datasets to preserve settings from previous dataset.
#// The array elements correspond to Red, Green, Blue, Grey
#   waves[4],  // The wave number for each of red, green, blue, grey
#   WaveElements[4]={     // These are the form elements controlling each wave.  Another structure with the following parts:
#      Wave:document.forms[0].$waveName,
#      ThreshType:document.forms[0].$threshTypeName,
#      ThreshText:document.forms[0].$threshTextName,
#      Clip:document.forms[0].$clipName,
#      ClipType:document.forms[0].$clipTypeName,
#      ClipText:document.forms[0].$clipTextName,
#      ThresholdValue:dataset.thresholds[$waveNum],
#      ClipValue:dataset.clips[$waveNum]
#      },
#   };
sub MakeJSdataset {
my $datasetID = shift;
my $dataset = $OME->NewDataset (ID => $datasetID);
my $filePath;
my ($datasetName,$datasetPath);
my ($theZ,$theT) = (
	$cgi->param('TheZ'),
	$cgi->param('TheT')
	);
my ($width,$height,$numZ,$numT,$numWaves);
my ($imageType) = (
	$cgi->param('ImageType')
	);
my @threshTypes = split(',',$cgi->param('ThreshTypes'));
my @statThresholds = split(',',$cgi->param('StatThresholds'));
my @clipTypes = split(',',$cgi->param('ClipTypes'));
my @statClips = split(',',$cgi->param('StatClips'));
my @wavesOLD = split(',',$cgi->param('Waves'));
my @wavelengthsOLD = $cgi->param('Wavelengths');
my @meansOLD = split(',',$cgi->param('Means'));
my @sigmasOLD = split(',',$cgi->param('Sigmas'));

# These are to hold the same values for the new dataset.
my (@thresholds,@clips,@waves,@wavelengths,@mins,@maxs,@means,@sigmas);
# These are sorted by wavelength
my @wavelengthSorted;
# a hash that relates wavelength to wave number.
my %waveNumbers;
my $dbh = $OME->DBIhandle();
my ($i,$j)=(0,0);




	($width,$height,$numZ,$numT,$numWaves) = (
		$dataset->SizeX,
		$dataset->SizeY,
		$dataset->SizeZ,
		$dataset->NumTimes,
		$dataset->NumWaves
		);


	$datasetName = $dataset->Name;
	$datasetPath = $dataset->Path;
	$filePath = $datasetPath.$datasetName;
	
	$imageType = 'Greyscale' unless defined $imageType;

	$theT = 0 unless defined $theT;
	$theZ = $numZ/2 unless defined $theZ;

	$i=0;
	@wavelengths = ();
	my $datasetWavelengths = $dataset->Wavelengths();
	foreach (@$datasetWavelengths) {
		$wavelengths[$i] = $_->{EmWavelength} if exists $_->{EmWavelength} and defined $_->{EmWavelength} and $_->{EmWavelength};
		$wavelengths[$i] = $i+1 unless defined $wavelengths[$i];
		$waveNumbers{$wavelengths[$i]} = $i;
		$i++;
	}

	# sort numerically descending to make @wavelengthSorted go from red to blue.
	@wavelengthSorted = sort {$b <=> $a} @wavelengths;


	my $datasetJS = qq /dataset = {width:$width,height:$height,numZ:$numZ,numT:$numT,numWaves:$numWaves,theZ:$theZ,theT:$theT};\n/;
	$datasetJS .= 'dataset.wavelengths = ['.join(',',@wavelengths)."];\n";
	
	my (@minStat,@maxStat,@meanStat,@sigmaStat);
	my ($w,$t);
	my $XYZinfo = $dataset->XYZinfo();
	for ($w=0;$w<$numWaves;$w++) {
		for ($t=0;$t<$numT;$t++) {
			$minStat[$w][$t]   = $XYZinfo->[$w][$t]->{Min};
			$maxStat[$w][$t]   = $XYZinfo->[$w][$t]->{Max};
			$meanStat[$w][$t]  = $XYZinfo->[$w][$t]->{Mean};
			$sigmaStat[$w][$t] = $XYZinfo->[$w][$t]->{Sigma};
		}
	}

	my @statsJSstat;
	for ($i=0;$i<$numWaves;$i++) {
		push (@statsJSstat,'['.join (',',@{$minStat[$i]}[0..$numT-1]).']');
	}
	$datasetJS .= 'dataset.statsMin=['.join (',',@statsJSstat)."];\n";

	@statsJSstat=();
	for ($i=0;$i<$numWaves;$i++) {
		push (@statsJSstat,'['.join (',',@{$maxStat[$i]}[0..$numT-1]).']');
	}
	$datasetJS .= 'dataset.statsMax=['.join (',',@statsJSstat)."];\n";

	@statsJSstat=();
	for ($i=0;$i<$numWaves;$i++) {
		push (@statsJSstat,'['.join (',',@{$meanStat[$i]}[0..$numT-1]).']');
	}
	$datasetJS .= 'dataset.statsMean=['.join (',',@statsJSstat)."];\n";

	@statsJSstat=();
	for ($i=0;$i<$numWaves;$i++) {
		push (@statsJSstat,'['.join (',',@{$sigmaStat[$i]}[0..$numT-1]).']');
	}
	$datasetJS .= 'dataset.statsSigma=['.join (',',@statsJSstat)."];\n";

# Set the waves array to the appropriate waves from the parameter.
# At this point, the wavelengths array is set for the new dataset.
# The waves parameter contains the wavenumbers passed in as a parameter, which refer to the old dataset's wavenumbers.
# We want the wavelengths to be sticky, not the wave numbers, so we convert the waves parameter to the corresponding wavelengths (@wavelengthsOLD),
# then re-assign it to the new dataset's wavenumbers.
	for ($i=0;$i<4;$i++) {
		$waves[$i] = $waveNumbers{$wavelengthsOLD[$wavesOLD[$i]]}
			if defined $wavesOLD[$i] and defined $wavelengthsOLD[$wavesOLD[$i]] and exists $waveNumbers{$wavelengthsOLD[$wavesOLD[$i]]};
	}

# The default wavelength assignments are red for most red-shifted wavelength, blue for most blue-shifted and green for "middle" wavelength.
	$waves[0] =  $waveNumbers{$wavelengthSorted[0]}           unless defined $waves[0]; #red
	$waves[1] =  $waveNumbers{$wavelengthSorted[$numWaves/2]} unless defined $waves[1]; #green
	$waves[2] =  $waveNumbers{$wavelengthSorted[$numWaves-1]} unless defined $waves[2]; #blue
	$waves[3] =  0                                            unless defined $waves[3]; #grey

# Now we do the same for the clips+thresholds - convert from the statistical equivalent for the old dataset,
# to the statistical equivalent and raw value for the new dataset.
	for ($i=0;$i<$numWaves;$i++) {
		my $oldWaveNum = $waveNumbers{$wavelengthsOLD[$i]} if defined $wavelengthsOLD[$i] and exists $waveNumbers{$wavelengthsOLD[$i]};
		if (defined $oldWaveNum and defined $statThresholds[$oldWaveNum] and $statThresholds[$oldWaveNum]) {
			$thresholds[$i]= $meanStat[$i][$theT] + ($statThresholds[$oldWaveNum] * $sigmaStat[$i][$theT]);
		}
		$thresholds[$i] = $minStat[$i][$theT] if defined $thresholds[$i] and $thresholds[$i] < $minStat[$i][$theT];
		$thresholds[$i] = $maxStat[$i][$theT] if defined $thresholds[$i] and $thresholds[$i] > $maxStat[$i][$theT];

		if (defined $oldWaveNum and defined $statClips[$oldWaveNum] and $statClips[$oldWaveNum]) {
			$clips[$i]= $meanStat[$i][$theT] + ($statClips[$oldWaveNum] * $sigmaStat[$i][$theT]);
		}
		$clips[$i] = $minStat[$i][$theT] if defined $clips[$i] and $clips[$i] < $minStat[$i][$theT];
		$clips[$i] = $maxStat[$i][$theT] if defined $clips[$i] and $clips[$i] > $maxStat[$i][$theT];
		
		$thresholds[$i] = $clips[$i] if defined $clips[$i] and defined $thresholds[$i] and $clips[$i] < $thresholds[$i];
	
	# At this point the thresholds+clips were successfully converted and are valid, or they are still undefined.
		$thresholds[$i] = $meanStat[$i][$theT] unless defined $thresholds[$i];
		$clips[$i] = $meanStat[$i][$theT] + ($sigmaStat[$i][$theT]*4) unless defined $clips[$i];

	# Make statClips and statThresholds for the new dataset.
		$statClips[$i]      = ($clips[$i] - $meanStat[$i][$theT]) / $sigmaStat[$i][$theT];
		$statThresholds[$i] = ($thresholds[$i] - $meanStat[$i][$theT]) / $sigmaStat[$i][$theT];

		$threshTypes[$i] = "Statistic" unless defined $threshTypes[$i] and $threshTypes[$i] eq "Manual";
		$clipTypes[$i] = "Statistic" unless defined $clipTypes[$i] and $clipTypes[$i] eq "Manual";
	}

	$datasetJS .= 'dataset.threshTypes = ["'.join('","',@threshTypes).qq/"];\n/;
	$datasetJS .= 'dataset.thresholds = ['.join(',',@thresholds)."];\n";
	$datasetJS .= 'dataset.statThresholds = ['.join(',',@statThresholds)."];\n";
	$datasetJS .= 'dataset.clipTypes = ["'.join('","',@clipTypes).qq/"];\n/;
	$datasetJS .= 'dataset.clips = ['.join(',',@clips)."];\n";
	$datasetJS .= 'dataset.statClips = ['.join(',',@statClips)."];\n";
	$datasetJS .= 'dataset.waves = ['.join(',',@waves)."];\n";

	$datasetJS .= "dataset.WaveElements = new Array (4);\n";
	


	$cgi->param('DatasetID',$datasetID);
	$cgi->param('DatasetName',$datasetName);
	$cgi->param('DatasetPath',$datasetPath);

	$cgi->param('Width',$width);
	$cgi->param('Height',$height);
	$cgi->param('NumZ',$numZ);
	$cgi->param('NumT',$numT);
	$cgi->param('NumWaves',$numWaves);
	$cgi->param('Wavelengths',join (',',@wavelengths));

	$cgi->param('ImageType',$imageType);

	$cgi->param('TheZ',$theZ);
	$cgi->param('TheT',$theT);
	$cgi->param('Waves',join(',',@waves));
	$cgi->param('Thresholds',join(',',@thresholds));
	$cgi->param('StatThresholds',join(',',@statThresholds));
	$cgi->param('ThreshTypes',join(',',@threshTypes));
	$cgi->param('Clips',join(',',@clips));
	$cgi->param('StatClips',join(',',@statClips));
	$cgi->param('ClipTypes',join(',',@clipTypes));

	return $datasetJS;

}

sub DrawJPEG {
my ($datasetName,$datasetPath) = (
	$cgi->param('DatasetName'),
	$cgi->param('DatasetPath')
	);
my $filePath = $datasetPath.$datasetName;
my ($imageType) = (
	$cgi->param('ImageType')
	);
my ($width,$height) = (
	$cgi->param('Width'),
	$cgi->param('Height')
	);
my ($theZ,$theT) = (
	$cgi->param('TheZ'),
	$cgi->param('TheT')
	);
my @DSthresholds = split(',',$cgi->param('Thresholds'));
my @DSclips = split(',',$cgi->param('Clips'));
my @waves = split(',',$cgi->param('Waves'));
my (@thresholds,@clips);
my $i;

my $error;
my $image;




#print STDERR "DrawJPEG:  DatasetID: $datasetID, Name: $datasetName, Path: $datasetPath, Brightness: $brightness, Contrast: $contrast, theZ: $theZ, theT: $theT, theWave: $theWave\n";

	for ($i=0;$i<4;$i++) {
		$thresholds[$i] = $DSthresholds[$waves[$i]];
		$clips[$i] = $DSclips[$waves[$i]];
	}

	if ($imageType eq 'Greyscale') {
		$image = Image::Magick->new (magick=>'gray',size=>$width.'x'.$height,depth=>8,'cache-threshold'=>64);
		warn "$image" unless ref($image);
		my ($greyWave,$greyThresh,$greyClip) = ($waves[3],$thresholds[3],$clips[3]);
		my $scale = ($greyClip - $greyThresh) / 255;
		open(DATA, "/OME/dev/SoftWorxSlice Path='$filePath' Wave=$greyWave z=$theZ t=$theT thresh=$greyThresh clip=$greyClip scale=$scale |");
		$error = $image->Read(file=>*DATA);
		warn "$error" if "$error";
		close(DATA);
	} else {
		$image = Image::Magick->new (magick=>'RGB',size=>$width.'x'.$height,depth=>8,interlace=>'None','cache-threshold'=>64);
		warn "$image" unless ref($image);
		my ($redWave,$greenWave,$blueWave,$redThresh,$greenThresh,$blueThresh,$redClip,$greenClip,$blueClip) = (
			$waves[0],$waves[1],$waves[2],$thresholds[0],$thresholds[1],$thresholds[2],$clips[0],$clips[1],$clips[2]);
		my ($redScale,$greenScale,$blueScale) = (
			($redClip - $redThresh) / 255,
			($greenClip - $greenThresh) / 255,
			($blueClip - $blueThresh) / 255 );
		my $waveParams = "RedWave=$redWave RedThresh=$redThresh RedClip=$redClip RedScale=$redScale";
		$waveParams .= " GreenWave=$greenWave GreenThresh=$greenThresh GreenClip=$greenClip GreenScale=$greenScale";
		$waveParams .= " BlueWave=$blueWave BlueThresh=$blueThresh BlueClip=$blueClip BlueScale=$blueScale";
	print STDERR "Wave parameters: $waveParams\n";
		open(DATA, "/OME/dev/SoftWorxSlice Path='$filePath' z=$theZ t=$theT $waveParams |");
		$error = $image->Read(file=>*DATA);
		warn "$error" if "$error";
		close(DATA);
	}


	$image->Set (magick=>'jpeg');
	print $image->ImageToBlob();
	undef $image;
	
}

sub SigmaControl {
my $element = shift;
my $waveIdx = shift;
my $mapName = $element.$waveIdx.'MAP';
#	return (qq %
#		<MAP NAME="$mapName">
#			<AREA NAME="Min"   COORDS="0,0,24,13" 
#				HREF="javascript:dataset.$element[$waveIdx]=dataset.mins[$waveIdx];ReloadImage(document.forms[0],document.theImage,dataset);">
#			<AREA NAME="Down1" COORDS="28,0,63,13"
#				HREF="javascript:dataset.$element[$waveIdx]-=dataset.sigmas[$waveIdx]);ReloadImage(document.forms[0],document.theImage,dataset);">
#			<AREA NAME="Down2" COORDS="67,0,102,13"
#				HREF="javascript:dataset.$element[$waveIdx]-=dataset.sigmas[$waveIdx]*0.1);ReloadImage(document.forms[0],document.theImage,dataset);">
#			<AREA NAME="Mean"  COORDS="106,0,137,13"
#				HREF="javascript:dataset.$element[$waveIdx]=dataset.means[$waveIdx];ReloadImage(document.forms[0],document.theImage,dataset);">
#			<AREA NAME="Up2"   COORDS="141,0,176,13"
#				HREF="javascript:dataset.$element[$waveIdx]+=dataset.sigmas[$waveIdx]*0.1);ReloadImage(document.forms[0],document.theImage,dataset);">
#			<AREA NAME="Up1"   COORDS="180,0,215,13"
#				HREF="javascript:dataset.$element[$waveIdx]+=dataset.sigmas[$waveIdx]);ReloadImage(document.forms[0],document.theImage,dataset);">
#			<AREA NAME="Max"   COORDS="218,0,246,13"
#				HREF="javascript:dataset.$element[$waveIdx]=dataset.maxs[$waveIdx];ReloadImage(document.forms[0],document.theImage,dataset);">
#		</MAP>
#		<IMG SRC="/images/SigmaControlStrip.gif" ALIGN="left" HEIGHT="14" WIDTH="248" USEMAP="#$mapName" BORDER="0">
#	%);
# {width,height,numZ,numT,numWaves,theZ,theT  // dataset dimensions and the currently selected Z-section and timepoint.
#  	statsMin[numWaves][numT],
#   statsMax[numWaves][numT],
#   statsMean[numWaves][numT],
#   statsSigma[numWaves][numT],
	return (qq %
		<MAP NAME="$mapName">
			<AREA NAME="Min"   COORDS="0,0,24,13" 
				HREF="javascript:SetMin (document.dataset,'$element',$waveIdx);">
			<AREA NAME="Down1" COORDS="28,0,63,13"
				HREF="javascript:AddSigma (document.dataset,'$element',$waveIdx,-1.0);">
			<AREA NAME="Down2" COORDS="67,0,102,13"
				HREF="javascript:AddSigma (document.dataset,'$element',$waveIdx,-0.1);">
			<AREA NAME="Mean"  COORDS="106,0,137,13"
				HREF="javascript:SetMean (document.dataset,'$element',$waveIdx);">
			<AREA NAME="Up2"   COORDS="141,0,176,13"
				HREF="javascript:AddSigma (document.dataset,'$element',$waveIdx,0.1);">
			<AREA NAME="Up1"   COORDS="180,0,215,13"
				HREF="javascript:AddSigma (document.dataset,'$element',$waveIdx,1.0);">
			<AREA NAME="Max"   COORDS="218,0,246,13"
				HREF="javascript:SetMax (document.dataset,'$element',$waveIdx);">
		</MAP>
		<IMG SRC="/images/SigmaControlStrip.gif" ALIGN="left" HEIGHT="14" WIDTH="248" USEMAP="#$mapName" BORDER="0">
	%);
}


sub PlusMinusControl {
my $element = shift;
my $property = shift;
$property = 'value' unless defined $property;
my $mapName = $element.'MAP';
	return (qq %
		<MAP NAME="$mapName">
			<AREA NAME="Plus"   COORDS="0,0,11,8" 
				HREF="javascript:AddVal(document.forms[0].$element,'$property',1);">
			<AREA NAME="Minus" COORDS="0,9,11,17"
				HREF="javascript:AddVal(document.forms[0].$element,'$property',-1);">
		</MAP>
		<IMG SRC="/images/PlusMinus.gif" ALIGN="absmiddle" HEIGHT="18" WIDTH="12" USEMAP="#$mapName" BORDER="0">
	%);
}


sub DrawControls {
my $color = shift;
my $tableRows = shift;
my $JS = shift;

my $waveName = $color.'Wave';
my $threshTextName = $color.'ThreshText';
my $threshTypeName = $color.'ThreshType';
my $threshName = 'ThresholdValue';
my $clipTextName = $color.'ClipText';
my $clipTypeName = $color.'ClipType';
my $clipName = 'ClipValue';
my $elementsName = $color.'Elements';
my ($col,$row);
my %waveIndexes = ('Red' => 0,'Green' => 1, 'Blue' => 2, 'Grey' => 3);
my $RGBnum = $waveIndexes{$color};
my @thresholds = split(',',$cgi->param('Thresholds'));
my @clips = split(',',$cgi->param('Clips'));
my @waves = split(',',$cgi->param('Waves'));
my @wavelengths = split(',',$cgi->param('Wavelengths'));
my @threshTypes = split(',',$cgi->param('ThreshTypes'));
my @clipTypes = split(',',$cgi->param('ClipTypes'));
my $wavenumber = $waves[$RGBnum];

	$col = "<B>$color</B> Wavelength: ".$cgi->textfield(-name=>$waveName,-size=>3,-default=>$wavelengths[$waves[$RGBnum]],-override=>1);
	$col .= PlusMinusControl ($waveName,'wavenumber');
	$row = $cgi->td({nowrap=>undef,height=>'20',valign=>'middle'},$col);
	push (@$tableRows,$row);

	$col = "<B>Threshold:</B> ".$cgi->textfield(-name=>$threshTextName,-size=>12);
	$col .= $cgi->popup_menu(-name=>$threshTypeName,-values=>['Manual','Statistic'],-default=>$threshTypes[$waves[$RGBnum]],-override=>1,
		-onChange=>'VerifyForm (this.form,dataset);');
	$row = $cgi->td({nowrap=>undef,align=>'right'},$col);
	push (@$tableRows,$row);
	$row = $cgi->td({width=>'260',align=>'center',nowrap=>undef},SigmaControl ( $threshName,$RGBnum));
	push (@$tableRows,$row);

	$col=qq /<hr align="center">/;
	$row = $cgi->td({nowrap=>undef,height=>'3'},$col);
	push (@$tableRows,$row);

	$col = "<B>Clip:</B> ".$cgi->textfield(-name=>$clipTextName,-size=>12);
	$col .= $cgi->popup_menu(-name=>$clipTypeName,-values=>['Manual','Statistic'],-default=>$clipTypes[$waves[$RGBnum]],-override=>1,
		-onChange=>'VerifyForm (this.form,dataset);');
	$row = $cgi->td({nowrap=>undef,align=>'right'},$col);
	push (@$tableRows,$row);
	$row = $cgi->td({width=>'260',align=>'center',nowrap=>undef},SigmaControl ($clipName,$RGBnum));
	push (@$tableRows,$row);
	
	
	$$JS .= qq %
document.forms[0].$waveName.wavenumber = $wavenumber;
var $elementsName = {
	Wave:document.forms[0].$waveName,
	ThreshType:document.forms[0].$threshTypeName,
	ThreshText:document.forms[0].$threshTextName,
	Clip:document.forms[0].$clipName,
	ClipType:document.forms[0].$clipTypeName,
	ClipText:document.forms[0].$clipTextName,
	ThresholdValue:dataset.thresholds[$wavenumber],
	ClipValue:dataset.clips[$wavenumber]
};
	dataset.WaveElements[$RGBnum] = $elementsName;
	%;
#	$$JS .= qq %
#	$elementsName.Wave = document.forms[0].$waveName;
#	$elementsName.Threshold = document.forms[0].$threshName;
#	$elementsName.ThreshType = document.forms[0].$threshTypeName;
#	$elementsName.ThreshText = document.forms[0].$threshTextName;
#	$elementsName.Clip = document.forms[0].$clipName;
#	$elementsName.ClipType = document.forms[0].$clipTypeName;
#	$elementsName.ClipText = document.forms[0].$clipTextName;
#	dataset.WaveElements[$waveNum] = $elementsName;
#	%;
#	$$JS .= qq %
#	dataset.WaveElements[$waveNum] = {
#	Wave:document.forms[0].$waveName,
#	Threshold:document.forms[0].$threshName,
#	ThreshType:document.forms[0].$threshTypeName,
#	ThreshText:document.forms[0].$threshTextName,
#	Clip:document.forms[0].$clipName,
#	ClipType:document.forms[0].$clipTypeName,
#	ClipText:document.forms[0].$clipTextName
#	};
#	%;

}
