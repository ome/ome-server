# OME/Web/FindSpots.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  JM Burel <j.burel@dundee.ac.uk>
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


package OME::Web::FindSpots;

use strict;
use vars qw($VERSION);
$VERSION = '1.0';
use CGI;
use OME::Web::Helper::JScriptFormat;
use OME::Web::Helper::HTMLFormat;
use OME::Tasks::AEFacade;


use base qw(OME::Web);

sub getPageTitle {
	return "Open Microscopy Environment - FindSpots" ;

}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my	$session=$self->Session();
	my 	$body="" ;	
	my 	$HTMLFormat=new OME::Web::Helper::HTMLFormat;
	

	if ($cgi->param('Execute')){
		my %h=();
		$h{MinimumSpotVolume}=$cgi->param('MinSpotVolume');
		$h{Channel}=$cgi->param('Channel'); 
		$h{ThresholdType}=$cgi->param('ThresholdType');
		$h{ThresholdValue}=$cgi->param('ThresholdValue');
		##################################
		if ($cgi->param('startTime') eq 'Begining'){
			$h{TimeStart}="";
		}else{
			$h{TimeStart}=$cgi->param('Start');
		}
		if ($cgi->param('stopTime') eq 'End'){
			$h{TimeStop}="";
		}else{
			$h{TimeStop}=$cgi->param('Stop');
		}

		my $attributeType="FindSpotsInputs";
		my $facade= OME::Tasks::AEFacade->new($session);
		$facade->executeView($session->dataset(),"Find and track spots","Parameters","Find spots",\%h,$attributeType);
	 
	
	}else{
		my @ref=$session->dataset()->images();
	
		$body.= "<b>Selected dataset: </b>".$session->dataset()->name()."<br>";
		if (scalar(@ref)==0){
			$body.="The selected dataset contains no images";
			return ('HTML',$body);
		}
		$body.=print_form($cgi); 
	}
	return ('HTML',$body);
	
}




############
sub print_form{
	my ($cgi)=@_;
	my $html="";
	my @tableRows=();
	my @tableColumns=();
	my @radioGrp=();
	
	##################################
	#$tableColumns[0]=$cgi->th('Time');
	#$tableColumns[1]='<b>From:</b>'.$cgi->textfield(-name=>'TimeStart',-size=>4);
	#@tableColumns = $cgi->td (\@tableColumns);
	#push (@tableRows,@tableColumns);
	#@tableColumns = ();
	#$tableColumns[0]=$cgi->td(' ');
	#$tableColumns[1]='<b>To:</b>'.$cgi->textfield(-name=>'TimeStop',-size=>4);
	#@tableColumns = $cgi->td (\@tableColumns);
	#push (@tableRows,@tableColumns);
	#@tableColumns = ();
	###################################

	$tableColumns[0]=$cgi->th('Time: From/to');
	#$tableColumns[1]='<b>From:</b>';
	@radioGrp = $cgi->radio_group(-name=>'startTime',
			-values=>['Begining','timePoint'],-default=>'Begining',-nolabels=>1);
	$tableColumns[1] = $radioGrp[0]."Begining ".$radioGrp[1]."Timepoint".$cgi->textfield(-name=>'Start',-size=>4);

	#$tableColumns[2] = $radioGrp[1]."Timepoint".$cgi->textfield(-name=>'Start',-size=>4);
	@tableColumns = $cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();

	$tableColumns[0]=$cgi->td(' ');
	#$tableColumns[1]='<b>To:</b>';
	@radioGrp = $cgi->radio_group(-name=>'stopTime',
			-values=>['End','timePoint'],-default=>'End',-nolabels=>1);
	$tableColumns[1] = $radioGrp[0]."End  ".$radioGrp[1]."Timepoint".$cgi->textfield(-name=>'Stop',-size=>4);
	#$tableColumns[2] = $radioGrp[1]."Timepoint".$cgi->textfield(-name=>'Stop',-size=>4);
	@tableColumns = $cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();









	
	# channel
	$tableColumns[0] = $cgi->th ('Channel');
	$tableColumns[1] = $cgi->textfield(-name=>'Channel',-size=>4,default=>'0');
	@tableColumns = $cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();


	$tableColumns[0] = $cgi->th ('ThresholdType');
	$tableColumns[1] = $cgi->popup_menu(-name=>'ThresholdType',
				-values=>['Absolute','RelativeToMean','RelativeToGeometricMean','MaximumEntropy','Kittler','MomentPreservation','Otsu'],
				default=>'RelativeToGeometricMean');
	@tableColumns = $cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();

	$tableColumns[0] = $cgi->th ('ThresholdValue');
	$tableColumns[1] = $cgi->textfield(-name=>'ThresholdValue',-size=>4,default=>'4.5');
	@tableColumns = $cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();


	$tableColumns[0] = $cgi->th ('Min Spot volume');
	$tableColumns[1] = $cgi->textfield(-name=>'MinSpotVolume',-size=>4,default=>'10');
	@tableColumns = $cgi->td (\@tableColumns);
	push (@tableRows,@tableColumns);
	@tableColumns = ();


	# html ouput
	$html.=$cgi->h3("Enter parameters for findSpots");
	$html.=$cgi->startform;

	$html.=$cgi->table({-border=>1,-cellspacing=>1,-cellpadding=>1},
		$cgi->Tr(\@tableRows)
		);
	$html.="<br>";
	$html.=$cgi->submit(-name=>'Execute',-value=>'Run FindSpots');
	$html.=$cgi->endform;

	return $html;


}


1;
