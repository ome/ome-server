#!/usr/bin/perl -w

# Release 1.0
# Author:  Daniel R. Rines (drrines@mit.edu)
# Copyright 2001 Daniel R. Rines
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
# ClickySpots is part of the OME project developed at the Massachusetts Inst. of
# Technology. Usage and modification of this program is governed by the GNU General
# Public License as described above. 
# 
# ClickySpots processes manually evalutated coordinate information from a
# users softWoRx image file. ClickySpots expects to find a ".pts" file in the 
# same directory as the orignal softWoRx image file. The coordinate information 
# is read into an array before chromosome and spindle dynamics values are 
# calculated and stored in another array. Both sets of feature related information is 
# finally written to the OME system. This program essentially replaces the manSpots 
# program. However, it still only functions on single chromosome tagged/SPB datasets. 
# Fixed cell datasets still needs to be developed.

use strict;

use CGIBook::Error;
use Math::Cephes qw(:all);
use OMEpl;

use vars qw ($OME $programName @spot @spindle);

########################################################################################################################################
#																											#
#													MAIN														#
#																											#
########################################################################################################################################

$programName = "ClickySpots";
$OME = new OMEpl;

$OME->StartAnalysis();

 
if ($OME->gotBrowser) {
	print_form ();
	do_Analysis () if ($OME->cgi->param('Execute'));
} else {
	do_Analysis();
}

$OME->Finish();
undef $OME;

print STDERR "CLICKYSPOTS:  Analysis Completed!\n";


########################################################################################################################################
#																											#
#												Subroutines													#
#																											#
########################################################################################################################################

sub print_form {
my $cgi = $OME->cgi;
my ($row,@tableRows);

	print $OME->CGIheader();
	my $progDescr = $OME->DBIhandle->selectrow_array("SELECT description FROM programs WHERE program_name='$programName'");
	print $OME->cgi->h3("$programName: $progDescr");

	print $OME->cgi->startform;
	print "<BR><BR>";

	print $OME->cgi->submit(-name=>'Execute',-value=>"Run $programName");
	print "</CENTER>";
	print $OME->cgi->endform;
	print $OME->cgi->end_html;

}


sub do_Analysis {
my $datasets = $OME->GetSelectedDatasetIDs();
my %parameters;

my @spot = (										#ARRAY OF HASHES CONTAINING SPOT COORDINATE INFO.
	 {
		 feature_ID =>		0,
		 class =>			" ",						#"a" & "b" = SPINDLE POLES, "alpha-beta", "alpha" or "beta" = CHROMOSOME TAGS.
		 col =>			0,
		 row =>			0,
		 section =>		0,
		 wavelength =>		0,
		 time_pt =>		0,
		 X =>			0,
		 Y =>			0,
		 Z =>			0
	 }
);

my @spindle = (									#ARRAY OF HASHES CONTAINING KINETIC SPINDLE INFORMATION.
	 {
		 feature_ID =>		0,
		 time_pt =>		0,
		 elapsed_time =>	0,
		 d_alpha =>		0,						#Linear distance between chromosome tag (alpha) and spindle pole (a).
		 d_beta =>		0,						#Linear distance between chromosome tag (beta) and spindle pole (b).
		 d_gamma =>		0,						#Linear distance between chromosome tag (beta) and spindle pole (a).
		 d_epsilon =>		0,						#Linear distance between chromosome tag (alpha) and spindle pole (b).
		 d_alphabeta =>	0,						#Linear distance between the two chromosome tags (alpha) and (beta).
		 l_alpha =>		0,						#Relative position of chromosome tag (alpha) from spindle pole (a).
		 l_beta =>		0,						#Relative position of chromosome tag (beta) from spindle pole (b).
		 l_gamma =>		0,						#Relative position of chromosome tag (beta) from spindle pole (a).
		 l_epsilon =>		0,						#Relative position of chromosome tag (alpha) from spindle pole (b).
		 l_ab =>			0,						#Length of the spindle (between "a" and "b").
		 rho_alpha =>		0,
		 rho_beta =>		0,
		 rho_gamma =>		0,
		 rho_epsilon =>	0,
		 theta_alpha =>	0,
		 theta_beta =>		0,
		 theta_gamma =>	0,
		 theta_epsilon =>	0,
		 phi_alpha =>		0,
		 phi_beta =>		0,
		 delta_ab =>		0,
		 delta_alpha =>	0,
		 delta_beta =>		0,
		 delta_gamma =>	0,
		 delta_rho_alpha =>	0,
		 delta_rho_beta =>	0,
		 delta_alphabeta =>	0,
		 delta_a =>		0,
		 delta_b =>		0,
		 nu_ab =>			0,
		 nu_alpha =>		0,
		 nu_beta =>		0,
		 nu_gamma =>		0,
		 nu_rho_alpha =>	0,
		 nu_rho_beta =>	0,
		 nu_alphabeta =>	0,
		 nu_a =>			0,
		 nu_b =>			0,
	 }
);

my %spot_attributes = (
	'class'      => ['SPINDLE_SPOT_CLASS','CLASS'],
	'col'        => ['LOCATION','X'],
	'row'        => ['LOCATION','Y'],
	'section'    => ['LOCATION','Z'],
	'wavelength' => ['SIGNAL','WAVELENGTH'],
	'time_pt'    => ['TIMEPOINT','TIMEPOINT']
);

my %spindle_attributes = (
	'time_pt'         => ['SPINDLE_DYNAMICS','TIME_PT'],
	'elapsed_time'    => ['SPINDLE_DYNAMICS','ELAPSED_TIME'],
	'd_alpha'         => ['SPINDLE_DYNAMICS','D_ALPHA'],	
	'd_beta'          => ['SPINDLE_DYNAMICS','D_BETA'],		
	'd_gamma'         => ['SPINDLE_DYNAMICS','D_GAMMA'],				
	'd_epsilon'       => ['SPINDLE_DYNAMICS','D_EPSILON'],				
	'd_alphabeta'     => ['SPINDLE_DYNAMICS','D_ALPHABETA'],					
	'l_alpha'         => ['SPINDLE_DYNAMICS','L_ALPHA'],						
	'l_beta'          => ['SPINDLE_DYNAMICS','L_BETA'],						
	'l_gamma'         => ['SPINDLE_DYNAMICS','L_GAMMA'],						
	'l_epsilon'       => ['SPINDLE_DYNAMICS','L_EPSILON'],						
	'l_ab'            => ['SPINDLE_DYNAMICS','L_AB'],						
	'rho_alpha'       => ['SPINDLE_DYNAMICS','RHO_ALPHA'],
	'rho_beta'        => ['SPINDLE_DYNAMICS','RHO_BETA'],
	'rho_gamma'       => ['SPINDLE_DYNAMICS','RHO_GAMMA'],
	'rho_epsilon'     => ['SPINDLE_DYNAMICS','RHO_EPSILON'],
	'theta_alpha'     => ['SPINDLE_DYNAMICS','THETA_ALPHA'],
	'theta_beta'      => ['SPINDLE_DYNAMICS','THETA_BETA'],
	'theta_gamma'     => ['SPINDLE_DYNAMICS','THETA_GAMMA'],
	'theta_epsilon'   => ['SPINDLE_DYNAMICS','THETA_EPSILON'],
	'phi_alpha'       => ['SPINDLE_DYNAMICS','PHI_ALPHA'],
	'phi_beta'        => ['SPINDLE_DYNAMICS','PHI_BETA'],
	'delta_ab'        => ['SPINDLE_DYNAMICS','DELTA_AB'],
	'delta_alpha'     => ['SPINDLE_DYNAMICS','DELTA_ALPHA'],
	'delta_beta'      => ['SPINDLE_DYNAMICS','DELTA_BETA'],
	'delta_gamma'     => ['SPINDLE_DYNAMICS','DELTA_GAMMA'],
	'delta_rho_alpha' => ['SPINDLE_DYNAMICS','DELTA_RHO_ALPHA'],
	'delta_rho_beta'  => ['SPINDLE_DYNAMICS','DELTA_RHO_BETA'],
	'delta_alphabeta' => ['SPINDLE_DYNAMICS','DELTA_ALPHABETA'],
	'delta_a'         => ['SPINDLE_DYNAMICS','DELTA_A'],
	'delta_b'         => ['SPINDLE_DYNAMICS','DELTA_B'],
	'nu_ab'           => ['SPINDLE_DYNAMICS','NU_AB'],
	'nu_alpha'        => ['SPINDLE_DYNAMICS','NU_ALPHA'],
	'nu_beta'         => ['SPINDLE_DYNAMICS','NU_BETA'],
	'nu_gamma'        => ['SPINDLE_DYNAMICS','NU_GAMMA'],
	'nu_rho_alpha'    => ['SPINDLE_DYNAMICS','NU_RHO_ALPHA'],
	'nu_rho_beta'     => ['SPINDLE_DYNAMICS','NU_RHO_BETA'],
	'nu_alphabeta'    => ['SPINDLE_DYNAMICS','NU_ALPHABETA'],
	'nu_a'            => ['SPINDLE_DYNAMICS','NU_A'],
	'nu_b'            => ['SPINDLE_DYNAMICS','NU_B']
);

my @spotsPerTimePoint = 0;
my @elapsedTime = 0;
my %logFileData;
my $name;

	foreach (@$datasets) {
		$parameters{datasetID} = $_;
		$parameters{filename} = $OME->GetDatasetName($parameters{datasetID});
		$parameters{path} = $OME->GetDatasetPath($parameters{datasetID});
		$parameters{filetype} = 'live';
		$parameters{orientation} = 'reverse';
		$parameters{CSV} = 'noCSV';
		$parameters{totalTimePoints} = 0;
		$parameters{totalSpots} = 0;
		$parameters{maxSpindleLength} = 0;
		%logFileData = $OME->GetPixelSizes($parameters{datasetID});		#GLOBAL HASH THAT CONTAINS THE MICROSCOPE/IMAGE RELATED INFO.
		
		my @basename;
		($basename[0], $basename[1]) = split(/\./, $parameters{filename});
		$parameters{pathPlusFilename} = $parameters{path}."$basename[0]";
		
		@spotsPerTimePoint = 0;
		@elapsedTime = 0;

		my $base;
		if ($name =~ /(.*)\./) {$base = $1;}; 				# Get the base name - everything before the final '.'
		ObtainDataset(\%parameters, \@spot, \@spotsPerTimePoint, \@elapsedTime, \%logFileData);
		AnalyzeDataset(\%parameters, \@spot, \@spindle, \@spotsPerTimePoint, \@elapsedTime);
		DrawWebPage(\%parameters, \@spot, \@spindle);
		if ($parameters{CSV} eq "CSV") {
			GenerateCSVfile(\%parameters, \@spindle);
		}
		$parameters{analysisID} = $OME->RegisterAnalysis(
			datasetID    => $parameters{datasetID},
			programName  => $programName
		);
		$OME->WriteFeatures ($parameters{analysisID}, \@spot, \%spot_attributes);
		$OME->WriteFeatures ($parameters{analysisID}, \@spindle, \%spindle_attributes);
		$OME->PurgeDataset($parameters{datasetID});
		$OME->FinishAnalysis();
	}
}


sub ObtainDataset {
my $params = shift;
my $spot = shift;
my $spotsPerTP = shift;
my $elapsed_time = shift;
my $imageAttributes = shift;

	ReadDVHeader($params, $elapsed_time);

	if ($params->{filetype} eq "live") {
		$params->{totalTimePoints} = LoadDataFromFile($params, $imageAttributes, $spot, $spotsPerTP);		#FUNCTION TO LOAD ALL THE VALUES INTO AN ARRAY OF HASHES FROM A FILE.
	}
	
	return;
}


sub ReadDVHeader {
my $params = shift;
my $elapsed_time = shift;
	
my $HEADER = '/usr/bin/rdhdr';
my %header;
my ($m, $t) = (0, 0);
my $dummy;
my $imageFileName = $params->{pathPlusFilename};

	print STDERR "Obtaining extended Header Values for file: $imageFileName \n"; 
	
	local *PIPE;
	
	open (PIPE, "$HEADER \"$imageFileName.r3d\" |") || die "Cannot open pipe to $HEADER: $!";
	
	$t = 1;
	for ($m = 0; <PIPE>; $m++) {
		chomp;
		if ($m eq 0) {
			$dummy = $_;
		}
		
		($header{iZ}, $header{iW}, $header{iT}, $header{dPhotoSen}, $header{dTime}, $header{dX}, $header{dY}, $header{dZ}, $header{dMin}, $header{dMax}, $header{dMean}, $header{dExpTime}, $header{dND}, $header{dEXWave}, $header{dEMWave}, $header{dInterScale}) = split (/\t/, $_);
	
		if ($header{iZ} eq 0 && $m ne 0) {
			$elapsed_time->[$t] = $header{dTime};
			$t++;
		}
	}
	return;
}


sub LoadDataFromFile {													#FUNCTION TO EXTRACT THE COORDINATE DATA FROM A TEXT FILE.
my $params = shift,
my $imageAttributes = shift;												#ARRAY OF HASHES CONTAINING ALL THE COORDINATE DATA.
my $spots = shift;
my $spotsPerTP = shift;

my $dataFileName = $params->{pathPlusFilename};								#EXPECTS A FILENAME FROM THE CALLING PROGRAM. RETURNS AN
	
my ($i, $t, $j, $k) = (0, 0, 0, 0);	
my $spotCount = 0;														#SCALAR USED TO COUNT TOTAL NUMBER OF SPOTS PER TIME POINT.
my $totalSpots = 0;

	open(DATAFILE, "$dataFileName.pts") || die "I can't open the data file: $dataFileName.pts?"; 

	$t = 0;
	for ($i = 1; <DATAFILE>; $i++) {
		chomp;

		$spots->[$i]{feature_ID} = $i;									#FEATURE ID WILL BE DETERMINED IN OME SYSTEM.
		
		($spots->[$i]{col}, $spots->[$i]{row}, $spots->[$i]{section}, $spots->[$i]{wavelength}, $spots->[$i]{time_pt}) = split(/ /, $_);

		if ($spots->[$i]{time_pt} > $spots->[$i-1]{time_pt}) {
			$spotCount = 1;
			$t++;
		}
		else {
			$spotCount++;												#INCREMENT THE SPOT COUNTER.
		}
		
		$spots->[$i]{X} = $spots->[$i]{col} * $imageAttributes->{X};			#CONVERT EVERYTHING INTO REALSPACE DISTANCES.
		$spots->[$i]{Y} = $spots->[$i]{row} * $imageAttributes->{Y};			#IN THE FUTURE, THIS INFORMATION WILL BE MORE ACCURATE
		$spots->[$i]{Z} = $spots->[$i]{section} * $imageAttributes->{Z};			#AND WILL BE DETERMINED IN MATLAB PROGRAM.
		
		if ($spotCount == 1) {
			$spots->[$i]{class} = "a";									#THE FIRST SPOT SHOULD ALWAYS BE THE REFERENCE SPB (a).
		}
		elsif ($spotCount == 2) {										#THE SECOND SPOT SHOULD ALWAYS BE THE OTHER SPB (b).
			$spots->[$i]{class} = "b";
		}
		elsif ($spotCount == 3) {
			$spots->[$i]{class} = "alpha-beta";
		}
		elsif ($spotCount == 4) {										#IN THIS CASE, THE CHROMOSOME TAGS MUST HAVE SEPARATED.
			$j = hypot(hypot(abs($spots->[$i-1]{X} - $spots->[$i-3]{X}), abs($spots->[$i-1]{Y} - $spots->[$i-3]{Y})), abs($spots->[$i-1]{Z} - $spots->[$i-3]{Z}));
			$k = hypot(hypot(abs($spots->[$i]{X} - $spots->[$i-3]{X}), abs($spots->[$i]{Y} - $spots->[$i-3]{Y})), abs($spots->[$i]{Z} - $spots->[$i-3]{Z}));
			
			if ($j <= $k) {											#WHICHEVER SPOT IS CLOSEST TO REFERENCE SPB(a) WILL
				$spots->[$i-1]{class} = "alpha";							#BE CONSIDERED TO BE THE CHROMOSOME TAG (alpha), WHILE THE
				$spots->[$i]{class} = "beta";								#ONE THAT IS THE FUTHEREST, WILL BE ASSUMED TO BE (beta).
			}
			else {
				$spots->[$i-1]{class} = "beta";
				$spots->[$i]{class} = "alpha";
			}
		}
		
		$spotsPerTP->[$t] = $spotCount;									#SET THE NUMBER OF SPOTS PER TIME POINT INTO A GLOBAL ARRAY.
		$totalSpots++;
	}
	close (DATAFILE);
	
	$params->{totalSpots} = $totalSpots;
	return $t;														#RETURNS THE TOTAL NUMBER OF TIME POINTS.
}


sub AnalyzeDataset {
my $params = shift;
my $spot = shift;
my $spindle = shift;
my $spotsPerTP = shift;
my $elapsed_time = shift;

my ($i, $t) = (0, 0);
my $fileName = $params->{pathPlusFilename};
my (%a, %b, %alpha, %beta, %prev_a, %prev_b) = (0, 0, 0, 0, 0, 0);


	 if ($params->{filetype} eq "live") {
		 if ($params->{orientation} eq "reverse") {
			 SwapSpindleOrientation($params, $spot);
		 }

		 $i = 1;
		 for ($t = 1; $t <= $params->{totalTimePoints}; $t++) {					#LOOP THROUGH THE TIME POINTS ($t REPRESENTS THE CURRENT TIME POINT).

			 $spindle->[$t]{time_pt} = $t;									#CURRENTLY THIS IS SET TO $t, BUT I MAY WANT TO CHANGE THIS TO REAL TIME (mins/sec)...
			 $spindle->[$t]{elapsed_time} = $elapsed_time->[$t];

			 if ($spot->[$i]{class} eq "a") {
				 $a{X} = $spot->[$i]{X};										#ASSIGN SPOT COORDINATES TO TEMPORARY ARRAY OF HASHES.
				 $a{Y} = $spot->[$i]{Y};										#$i IS USED TO MARK POSITION IN THE SPOT STACK.
				 $a{Z} = $spot->[$i]{Z};										#THIS FIRST SET OF NUMBERS REPRESENTS SPB (a).
			 }
			 elsif ($spot->[$i+1]{class} eq "a") {
				 $a{X} = $spot->[$i+1]{X};							
				 $a{Y} = $spot->[$i+1]{Y};
				 $a{Z} = $spot->[$i+1]{Z};
			 }
			 elsif ($spot->[$i+2]{class} eq "a" && $spot->[$i+2]{time_pt} == $spot->[$i]{time_pt}) {
				 $a{X} = $spot->[$i+2]{X};							
				 $a{Y} = $spot->[$i+2]{Y};
				 $a{Z} = $spot->[$i+2]{Z};
			 }
			 elsif ($spot->[$i+3]{time_pt} == $spot->[$i]{time_pt}) {
				 $a{X} = $spot->[$i+3]{X};							
				 $a{Y} = $spot->[$i+3]{Y};
				 $a{Z} = $spot->[$i+3]{Z};
			 }		

			 if ($spot->[$i]{class} eq "b") {
				 $b{X} = $spot->[$i]{X};							
				 $b{Y} = $spot->[$i]{Y};							
				 $b{Z} = $spot->[$i]{Z};							
			 }
			 elsif ($spot->[$i+1]{class} eq "b") {
				 $b{X} = $spot->[$i+1]{X};							
				 $b{Y} = $spot->[$i+1]{Y};
				 $b{Z} = $spot->[$i+1]{Z};
			 }
			 elsif ($spot->[$i+2]{class} eq "b" && $spot->[$i+2]{time_pt} == $spot->[$i]{time_pt}) {
				 $b{X} = $spot->[$i+2]{X};							
				 $b{Y} = $spot->[$i+2]{Y};
				 $b{Z} = $spot->[$i+2]{Z};
			 }
			 elsif ($spot->[$i+3]{time_pt} == $spot->[$i]{time_pt}) {
				 $b{X} = $spot->[$i+3]{X};							
				 $b{Y} = $spot->[$i+3]{Y};
				 $b{Z} = $spot->[$i+3]{Z};
			 }		

			 if ($spot->[$i]{class} eq "alpha-beta") {				
				 $alpha{X} = $spot->[$i]{X};					
				 $alpha{Y} = $spot->[$i]{Y};
				 $alpha{Z} = $spot->[$i]{Z};
				 $beta{X} = $spot->[$i]{X};
				 $beta{Y} = $spot->[$i]{Y};
				 $beta{Z} = $spot->[$i]{Z};
			 }
			 elsif ($spot->[$i+1]{class} eq "alpha-beta") {
				 $alpha{X} = $spot->[$i+1]{X};					
				 $alpha{Y} = $spot->[$i+1]{Y};
				 $alpha{Z} = $spot->[$i+1]{Z};
				 $beta{X} = $spot->[$i+1]{X};
				 $beta{Y} = $spot->[$i+1]{Y};
				 $beta{Z} = $spot->[$i+1]{Z};
			 }
			 elsif ($spot->[$i+2]{class} eq "alpha-beta" && $spot->[$i+2]{time_pt} == $spot->[$i]{time_pt}){
				 $alpha{X} = $spot->[$i+2]{X};					
				 $alpha{Y} = $spot->[$i+2]{Y};
				 $alpha{Z} = $spot->[$i+2]{Z};
				 $beta{X} = $spot->[$i+2]{X};
				 $beta{Y} = $spot->[$i+2]{Y};
				 $beta{Z} = $spot->[$i+2]{Z};
			 }
			 else {
				 if ($spot->[$i]{class} eq "alpha") {				
					 $alpha{X} = $spot->[$i]{X};
					 $alpha{Y} = $spot->[$i]{Y};
					 $alpha{Z} = $spot->[$i]{Z};
				 }
				 elsif ($spot->[$i+1]{class} eq "alpha") {					
					 $alpha{X} = $spot->[$i+1]{X};
					 $alpha{Y} = $spot->[$i+1]{Y};
					 $alpha{Z} = $spot->[$i+1]{Z};
				 }
				 elsif ($spot->[$i+2]{class} eq "alpha" && $spot->[$i+2]{time_pt} == $spot->[$i]{time_pt}) {					
					 $alpha{X} = $spot->[$i+2]{X};
					 $alpha{Y} = $spot->[$i+2]{Y};
					 $alpha{Z} = $spot->[$i+2]{Z};
				 }
				 elsif ($spot->[$i+3]{time_pt} == $spot->[$i]{time_pt})  {					
					 $alpha{X} = $spot->[$i+3]{X};
					 $alpha{Y} = $spot->[$i+3]{Y};
					 $alpha{Z} = $spot->[$i+3]{Z};
				 }

				 if ($spot->[$i]{class} eq "beta") {				
					 $beta{X} = $spot->[$i]{X};
					 $beta{Y} = $spot->[$i]{Y};
					 $beta{Z} = $spot->[$i]{Z};
				 }
				 elsif ($spot->[$i+1]{class} eq "beta") {					
					 $beta{X} = $spot->[$i+1]{X};
					 $beta{Y} = $spot->[$i+1]{Y};
					 $beta{Z} = $spot->[$i+1]{Z};
				 }
				 elsif ($spot->[$i+2]{class} eq "beta" && $spot->[$i+2]{time_pt} == $spot->[$i]{time_pt}) {					
					 $beta{X} = $spot->[$i+2]{X};
					 $beta{Y} = $spot->[$i+2]{Y};
					 $beta{Z} = $spot->[$i+2]{Z};
				 }
				 elsif ($spot->[$i+3]{time_pt} == $spot->[$i]{time_pt})  {					
					 $beta{X} = $spot->[$i+3]{X};
					 $beta{Y} = $spot->[$i+3]{Y};
					 $beta{Z} = $spot->[$i+3]{Z};
				 }
			 }


			 $spindle->[$t]{l_ab} = distance("hyp", \%a, \%b);

			 $spindle->[$t]{d_alpha} = distance("hyp", \%a, \%alpha);
			 $spindle->[$t]{d_beta} = distance("hyp", \%b, \%beta);
			 $spindle->[$t]{d_gamma} = distance("hyp", \%a, \%beta);
			 $spindle->[$t]{d_epsilon} = distance("hyp", \%b, \%alpha);
			 $spindle->[$t]{d_alphabeta} = distance("hyp", \%alpha, \%beta);

			 if ($spindle->[$t]{l_ab} > $params->{maxSpindleLength}) {
				 $params->{maxSpindleLength} = $spindle->[$t]{l_ab};
			 }

			 $spindle->[$t]{theta_alpha} = angle("adj", $spindle->[$t]{d_epsilon}, $spindle->[$t]{d_alpha}, $spindle->[$t]{l_ab});
			 $spindle->[$t]{theta_beta} = angle("opp", $spindle->[$t]{d_beta}, $spindle->[$t]{d_gamma}, $spindle->[$t]{l_ab});
			 $spindle->[$t]{theta_gamma} = angle("adj", $spindle->[$t]{d_beta}, $spindle->[$t]{d_gamma}, $spindle->[$t]{l_ab});
			 $spindle->[$t]{theta_epsilon} = angle("opp", $spindle->[$t]{d_epsilon}, $spindle->[$t]{d_alpha}, $spindle->[$t]{l_ab});

			 $spindle->[$t]{l_alpha} = distance("adj", $spindle->[$t]{d_alpha}, $spindle->[$t]{theta_alpha});
			 $spindle->[$t]{l_beta} = distance("adj", $spindle->[$t]{d_beta}, $spindle->[$t]{theta_beta});
			 $spindle->[$t]{l_gamma} = distance("adj", $spindle->[$t]{d_gamma}, $spindle->[$t]{theta_gamma});
			 $spindle->[$t]{l_epsilon} = distance("adj", $spindle->[$t]{d_epsilon}, $spindle->[$t]{theta_epsilon});

			 $spindle->[$t]{rho_alpha} = distance("opp", $spindle->[$t]{d_alpha}, $spindle->[$t]{theta_alpha});
			 $spindle->[$t]{rho_beta} = distance("opp", $spindle->[$t]{d_beta}, $spindle->[$t]{theta_beta});
			 $spindle->[$t]{rho_gamma} = distance("opp", $spindle->[$t]{d_gamma}, $spindle->[$t]{theta_gamma});
			 $spindle->[$t]{rho_epsilon} = distance("opp", $spindle->[$t]{d_epsilon}, $spindle->[$t]{theta_epsilon});


			 if ($t > 1) {													#EVALUATE THESE PROPERTIES AS LONG AS IT IS NOT THE 1st TP.
				 $spindle->[$t]{delta_ab} = $spindle->[$t]{l_ab} - $spindle->[$t-1]{l_ab};
				 $spindle->[$t]{delta_alphabeta} = $spindle->[$t]{d_alphabeta} - $spindle->[$t-1]{d_alphabeta};
				 $spindle->[$t]{delta_alpha} = $spindle->[$t]{d_alpha} - $spindle->[$t-1]{d_alpha};
				 $spindle->[$t]{delta_beta} = $spindle->[$t]{d_beta} - $spindle->[$t-1]{d_beta};
				 $spindle->[$t]{delta_gamma} = $spindle->[$t]{d_gamma} - $spindle->[$t-1]{d_gamma};
				 $spindle->[$t]{delta_epsilon} = $spindle->[$t]{d_epsilon} - $spindle->[$t-1]{d_epsilon};

				 $spindle->[$t]{delta_a} = distance("hyp", \%a, \%prev_a);
				 $spindle->[$t]{delta_b} = distance("hyp", \%b, \%prev_b);

				 $spindle->[$t]{delta_rho_alpha} = $spindle->[$t]{rho_alpha} - $spindle->[$t-1]{rho_alpha};
				 $spindle->[$t]{delta_rho_beta} = $spindle->[$t]{rho_beta} - $spindle->[$t-1]{rho_beta};

				 $spindle->[$t]{nu_ab} = $spindle->[$t]{delta_ab} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});
				 $spindle->[$t]{nu_alphabeta} = $spindle->[$t]{delta_alphabeta} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});
				 $spindle->[$t]{nu_alpha} = $spindle->[$t]{delta_alpha} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});
				 $spindle->[$t]{nu_beta} = $spindle->[$t]{delta_beta} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});
				 $spindle->[$t]{nu_gamma} = $spindle->[$t]{delta_gamma} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});
				 $spindle->[$t]{nu_epsilon} = $spindle->[$t]{delta_epsilon} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});

				 $spindle->[$t]{nu_a} = $spindle->[$t]{delta_a} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});
				 $spindle->[$t]{nu_b} = $spindle->[$t]{delta_b} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});

				 $spindle->[$t]{nu_rho_alpha} = $spindle->[$t]{delta_rho_alpha} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});
				 $spindle->[$t]{nu_rho_beta} = $spindle->[$t]{delta_rho_beta} / ($spindle->[$t]{elapsed_time} - $spindle->[$t-1]{elapsed_time});
			 }
			 else {														#OTHERWISE, SET THEM TO ZERO.
				 $spindle->[$t]{delta_ab} = 0;
				 $spindle->[$t]{delta_alphabeta} = 0;
				 $spindle->[$t]{delta_alpha} = 0;
				 $spindle->[$t]{delta_beta} = 0;
				 $spindle->[$t]{delta_gamma} = 0;
				 $spindle->[$t]{delta_epsilon} = 0;

				 $spindle->[$t]{delta_a} = 0;
				 $spindle->[$t]{delta_b} = 0;

				 $spindle->[$t]{delta_rho_alpha} = 0;
				 $spindle->[$t]{delta_rho_beta} = 0;

				 $spindle->[$t]{nu_ab} = 0;
				 $spindle->[$t]{nu_alphabeta} = 0;
				 $spindle->[$t]{nu_alpha} = 0;
				 $spindle->[$t]{nu_beta} = 0;
				 $spindle->[$t]{nu_gamma} = 0;
				 $spindle->[$t]{nu_epsilon} = 0;

				 $spindle->[$t]{nu_a} = 0;
				 $spindle->[$t]{nu_b} = 0;

				 $spindle->[$t]{nu_rho_alpha} = 0;
				 $spindle->[$t]{nu_rho_beta} = 0;
			 }

			 $spindle->[$t]{phi_alpha} = 0;
			 $spindle->[$t]{phi_beta} = 0;
			
			 $prev_a{X} = $a{X};							#ASSIGN SPOT COORDINATES TO TEMPORARY ARRAY OF HASHES.
			 $prev_a{Y} = $a{Y};							#$i IS USED TO MARK POSITION IN THE SPOT STACK.
			 $prev_a{Z} = $a{Z};							#THIS FIRST SET OF NUMBERS REPRESENTS SPB (a).

			 $prev_b{X} = $b{X};							#THIS SECOND SET OF NUMBERS REPRESENTS SPB (b).
			 $prev_b{Y} = $b{Y};
			 $prev_b{Z} = $b{Z};

#			 $x_axis[$t] = sprintf("%.2f", $t * ($spindle->[$t]{elapsed_time} / 60));
#			 $y_spindleLength[$t] = $spindle->[$t]{l_ab};
#			 $y_MT_Length_alpha[$t] = $spindle->[$t]{d_alpha};
#			 $y_MT_Length_beta[$t] = $spindle->[$t]{d_gamma};
#			 $y_rel_Length_alpha[$t] = $spindle->[$t]{l_alpha};
#			 $y_rel_Length_beta[$t] = $spindle->[$t]{l_gamma};

			 if ($params->{maxSpindleLength} < $spindle->[$t]{l_ab}) {
				 $params->{maxSpindleLength} = $spindle->[$t]{l_ab};
			 }

			 $i = $i + $spotsPerTP->[$t];

		 }
	}
}


sub SwapSpindleOrientation {
my $params = shift;
my $spots = shift;
	
my $i = 0;
	
	for ($i = 1; $i < $params->{totalSpots}; $i++) {					#LOOP THROUGH THE TIME POINTS ($t REPRESENTS THE CURRENT TIME POINT).
		if ($spots->[$i]{class} eq "a") {
			$spots->[$i]{class} = "b";
		}
		elsif ($spots->[$i]{class} eq "b") {
			$spots->[$i]{class} = "a";
		}
		elsif ($spots->[$i]{class} eq "alpha") {
			$spots->[$i]{class} = "beta";
		}
		elsif ($spots->[$i]{class} eq "beta") {
			$spots->[$i]{class} = "alpha";
		}
	}
	
	return;
}


sub distance {															
	my $value = 0;														#POINTS IN 3D SPACE. EXPECTS THE DESIRED SIDE, X1, X2, Y1, Y2, Z1, & Z2.
	my $side = shift;													#RETURNS A SCALAR CONTAINING THE DISTANCE VALUE.
	my $coordinate1 = shift;
	my $coordinate2 = shift;
																	#THE FIRST ARRAY ELEMENT REQUESTS THE INFORMATION TO BE RETURNED.
																	#"hyp", "opp" or "adj" ARE THE EXPECTED KEY WORDS.
	if ($side eq "hyp") {
		$value = hypot(hypot(abs($coordinate2->{X} - $coordinate1->{X}), abs($coordinate2->{Y} - $coordinate1->{Y})), abs($coordinate2->{Z} - $coordinate1->{Z}));
	}
	elsif ($side eq "adj") {
		$value = $coordinate1 * cos($coordinate2);						#DERIVED FROM "x = r * cos(theta)" $coordinate[1] = r, $coordinate[2] = theta.
	}
	elsif ($side eq "opp") {
		$value = $coordinate1 * sin($coordinate2);						#DERIVED FROM "y = r * sin(theta)" $coordinate[1] = r, $coordinate[2] = theta.
	}
	else {
		die "You didn't tell the subroutine which type of value to return!\n";
	}
	
	return $value;
}


sub angle {														#FUNCTION TO CALCULATE ANY ANGLE OF A TRIANGLE
my $value = 0;														#BASED ON THE LENGTHS OF THE THREE SIDES OF THE TRIANGLE.
my @triangle_sides = @_;												#FUNCTION EXPECTS DESIRED ANGLE, SIDE a, b, and c.
																#RETURNS A SCALAR CONTAINING THE ANGLE IN DEGREES.
my $a = $triangle_sides[1];
my $b = $triangle_sides[2];
my $c = $triangle_sides[3];
	
	if ($triangle_sides[0] eq "adj") {
		$value = acos(($b**2 + $c**2 - $a**2) / (2 * $b * $c));			#DERIVED FROM THE LAW OF COSINES - A or "adj" ANGLE.
	}
	elsif ($triangle_sides[0] eq "opp") {
		$value = acos(($a**2 + $c**2 - $b**2) / (2 * $a * $c));			#DERIVED FROM THE LAW OF COSINES - B or "opp" ANGLE.
	}
	elsif ($triangle_sides[0] eq "hyp") {
		$value = acos(($a**2 + $b**2 - $c**2) / (2 * $a * $b));			#DERIVED FROM THE LAW OF COSINES - C or "hyp" ANGLE.
	}
	else {
		die "You didn't ask for the approriate angle value!\n";
	}
	
	return $value;
}


sub degrees {
my @radians = @_;
	
	return ($radians[0] * (180 / $PI));
}

sub DrawWebPage {
my $params = shift;
my $spots = shift;
my $spindles = shift;

my $dataFileName = $params->{pathPlusFilename};
my $totalSpots = $params->{totalSpots};
my $totalTimePoints = $params->{totalTimePoints};
my $max_Distance = $params->{maxSpindleLength};

my($i, $t) = (0, 0);
	
	print "Content-type: text/html\n\n";
	print "<HTML><HEAD><TITLE>Clicky Spot Data: $dataFileName.pts</TITLE></HEAD>\n";
	print "<BODY bgcolor=\"#FFFFFF\">\n";
	
	print "<TABLE border=\"pixels\" cellpadding=\"10\" frame=\"border\" title=\"Spot Data\">\n";
	print "<TR><TH>Class</TH><TH>X (pixel)</TH><TH>Y (pixel)</TH><TH>Z (pixel)</TH><TH>Time Point</TH></TR>\n";
	for ($i = 1; $i <= $params->{totalSpots}; $i++) {
		print "<TR>\n";
		print "<TD>".$spots->[$i]{class}."</TD>\n";
		printf ("<TD>%6.4f (%3d)</TD>\n", $spots->[$i]{X}, $spots->[$i]{col});
		printf ("<TD>%6.4f (%3d)</TD>\n", $spots->[$i]{Y}, $spots->[$i]{row});
		printf ("<TD>%6.4f (%3d)</TD>\n", $spots->[$i]{Z}, $spots->[$i]{section});
		printf ("<TD>%3d</TD>\n", $spots->[$i]{time_pt});
		print "</TR>\n";
	}
	print "</TABLE>\n";
	

	print "<TABLE align=\"center\" border=\"pixels\" cellpadding=\"10\" frame=\"border\" title=\"Spindle Data\">\n";
	print "<TR><TH>Time (sec)</TH><TH>Spindle (ab)</TH><TH>Kin (alpha)</TH><TH>Kin (beta)</TH><TH>Vel (alpha)</TH><TH>Vel (beta)</TH></TR>\n";
	for ($t = 1; $t <= $params->{totalTimePoints}; $t++) {
		print "<TR>\n";
		printf ("<TD>%6.2f</TD>\n", $spindles->[$t]{elapsed_time});
		printf ("<TD>%6.4f</TD>\n", $spindles->[$t]{l_ab});
		printf ("<TD>%6.4f</TD>\n", $spindles->[$t]{d_alpha});
		printf ("<TD>%6.4f</TD>\n", $spindles->[$t]{d_beta});
		printf ("<TD>%6.4f</TD>\n", $spindles->[$t]{nu_alpha});
		printf ("<TD>%6.4f</TD>\n", $spindles->[$t]{nu_beta});
		print "</TR>\n";
	}
	print "</TABLE>\n";

	print "\nAll Done\n";	
	print "</BODY></HTML>\n";
	return;
}


sub GenerateCSVfile {
my $params = shift;
my $spindles = shift;

my $t = 0;
my $dataFileName = $params->{pathPlusFilename}."_clicky";
	
	print STDERR "OUTPUT: Generating the Excel (CSV) file: $dataFileName.csv\n";
	
	open(CSVFILE, ">$dataFileName.csv") || die "Cannot open $dataFileName.csv?";
	
	print CSVFILE "time_pt,elapsed_time,d_alpha,d_beta,d_gamma,d_epsilon,d_alphabeta,l_alpha,l_beta,l_gamma,l_epsilon,l_ab,rho_alpha,rho_beta,rho_gamma,rho_epsilon,theta_alpha,";
	print CSVFILE "theta_beta,theta_gamma,theta_epsilon,phi_alpha,phi_beta,delta_ab,delta_alpha,delta_beta,delta_gamma,delta_rho_alpha,delta_rho_beta,delta_alphabeta,";
	print CSVFILE "delta_a,delta_b,nu_ab,nu_alpha,nu_beta,nu_gamma,nu_rho_alpha,nu_rho_beta,nu_alphabeta,nu_a,nu_b\n";
	
	for ($t = 1; $t <= $params->{totalTimePoints}; $t++) {
		print CSVFILE $spindles->[$t]{time_pt}.",";
		print CSVFILE $spindles->[$t]{elapsed_time}.",";
		print CSVFILE $spindles->[$t]{d_alpha}.",";
		print CSVFILE $spindles->[$t]{d_beta}.",";
		print CSVFILE $spindles->[$t]{d_gamma}.",";
		print CSVFILE $spindles->[$t]{d_epsilon}.",";
		print CSVFILE $spindles->[$t]{d_alphabeta}.",";
		print CSVFILE $spindles->[$t]{l_alpha}.",";
		print CSVFILE $spindles->[$t]{l_beta}.",";
		print CSVFILE $spindles->[$t]{l_gamma}.",";
		print CSVFILE $spindles->[$t]{l_epsilon}.",";
		print CSVFILE $spindles->[$t]{l_ab}.",";
		print CSVFILE $spindles->[$t]{rho_alpha}.",";
		print CSVFILE $spindles->[$t]{rho_beta}.",";
		print CSVFILE $spindles->[$t]{rho_gamma}.",";
		print CSVFILE $spindles->[$t]{rho_epsilon}.",";
		print CSVFILE $spindles->[$t]{theta_alpha}.",";
		print CSVFILE $spindles->[$t]{theta_beta}.",";
		print CSVFILE $spindles->[$t]{theta_gamma}.",";
		print CSVFILE $spindles->[$t]{theta_epsilon}.",";
		print CSVFILE $spindles->[$t]{phi_alpha}.",";
		print CSVFILE $spindles->[$t]{phi_beta}.",";
		print CSVFILE $spindles->[$t]{delta_ab}.",";
		print CSVFILE $spindles->[$t]{delta_alpha}.",";
		print CSVFILE $spindles->[$t]{delta_beta}.",";
		print CSVFILE $spindles->[$t]{delta_gamma}.",";
		print CSVFILE $spindles->[$t]{delta_rho_alpha}.",";
		print CSVFILE $spindles->[$t]{delta_rho_beta}.",";
		print CSVFILE $spindles->[$t]{delta_alphabeta}.",";
		print CSVFILE $spindles->[$t]{delta_a}.",";
		print CSVFILE $spindles->[$t]{delta_b}.",";
		print CSVFILE $spindles->[$t]{nu_ab}.",";
		print CSVFILE $spindles->[$t]{nu_alpha}.",";
		print CSVFILE $spindles->[$t]{nu_beta}.",";
		print CSVFILE $spindles->[$t]{nu_gamma}.",";
		print CSVFILE $spindles->[$t]{nu_rho_alpha}.",";
		print CSVFILE $spindles->[$t]{nu_rho_beta}.",";
		print CSVFILE $spindles->[$t]{nu_alphabeta}.",";
		print CSVFILE $spindles->[$t]{nu_a}.",";
		print CSVFILE $spindles->[$t]{nu_b}."\n";
	}
	
	close (CSVFILE);
	return;
}

