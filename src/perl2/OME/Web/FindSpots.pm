# OME/Web/FindSpots.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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
# Written by:    JM Burel <j.burel@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Web::FindSpots;

use strict;
use vars qw($VERSION);
use Log::Agent;
use OME;
$VERSION = $OME::VERSION;
use CGI;
use OME::Analysis::Engine;
use OME::Tasks::AnnotationManager;
use OME::Tasks::ChainManager;
use OME::Tasks::AEFacade;
use OME::Tasks::ImageManager;


use base qw(OME::Web);

sub getPageTitle {
	return "Open Microscopy Environment - FindSpots" ;

}

{
	my $menu_text = "Find Spots";

	sub getMenuText { return $menu_text }
}

sub getPageBody {
	my	$self = shift ;
	my 	$cgi = $self->CGI() ;
	my	$session=$self->Session();
    my  $factory = $session->Factory();
	my 	$body="" ;	
	

	if ($cgi->param('Execute')){
		my %h=();
		$h{MinimumSpotVolume}=$cgi->param('MinSpotVolume');
		$h{Channel}=$cgi->param('Channel');
		$h{ThresholdType}=$cgi->param('ThresholdType');
		$h{ThresholdValue}=$cgi->param('ThresholdValue');
		
		#if (($h{ThresholdValue}<0.6) and ($h{ThresholdType} eq 'RelativeToGeometricMean')){

		#	$body.="<b>The ThresholdValue must be > 0.6 if the type is the GeometricMean.</b><br>";
		#	$body.=$self->print_form($cgi); 
		#	return ('HTML',$body);

		#}


		##################################
		if ($cgi->param('startTime') ne 'Begining'){
			$h{TimeStart}=$cgi->param('Start');
		} else {
            $h{TimeStart} = undef;
        }
		if ($cgi->param('stopTime') ne 'End'){
			$h{TimeStop}=$cgi->param('Stop');
		} else {
            $h{TimeStop} = undef;
		}

        # Create a user input MEX for the user inputs
		my $attributeType="FindSpotsInputs";
        my $mex = OME::Tasks::AnnotationManager->
          annotateGlobal($attributeType,\%h);
        my $cmanager = OME::Tasks::ChainManager->new();
        my $chain = $cmanager->getChain('Find and track spots');
        my $node  = $cmanager->getNode($chain,'Find spots');
        my $input = $cmanager->getFormalInput($chain,$node,'Parameters');
        my $user_inputs = { $input->id() => $mex };
        my $chain_execution;
        eval {
            $chain_execution = OME::Analysis::Engine->
                executeChain($chain,$session->dataset(),$user_inputs);
        };

	 	if ($@) {
			$body.="There was an error executing this chain:<br><b>$@</b>";
			return ('HTML',$body);

		} else {
            $body.="Done!";
            return ( 'REDIRECT', 
            	$self->pageURL( 'OME::Web::DBObjDetail', {
            		Type => 'OME::AnalysisChainExecution',
            		ID   => $chain_execution->id()
            	} )
            );
        }
	
	}else{
		if (my $d = $session->dataset) {
			my @ref=$d->images();
	
			$body.= "<b>Selected dataset: </b>".$d->name()."<br>";
			if (scalar(@ref)==0){
				$body.="The selected dataset contains no images";
				return ('HTML',$body);
			}
			$body.=$self->print_form($cgi); 
		} else {
			$body.= $cgi->p({class => 'ome_error'}, "You currently have no datasets.");
		}
	}
	return ('HTML',$body);
	
}




############
sub print_form{
	my ($self, $cgi)=@_;
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

	my $session = $self->Session();
	my $imageManager = OME::Tasks::ImageManager->new($session); 
	my @image_list = $session->dataset()->images();
	my $image = $image_list[0];
	my $channelLabels= $imageManager->getImageWavelengths($image);
	my %labels = map{ $_->{WaveNum} => $_->{Label} } @$channelLabels ;
	$tableColumns[1] = $cgi->popup_menu( 
		-name	=> 'Channel',
		-values => map( $_->{WaveNum}, @$channelLabels ),
		-default => $cgi->param('Channel') || undef,
		-labels	 => \%labels
	);
#	$tableColumns[1] = $cgi->textfield(-name=>'Channel',-size=>4,default=>'0');


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
	$tableColumns[1] = $cgi->textfield(-name=>'ThresholdValue',-size=>4,default=>'1.5');
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
