# OME/Web/ViewExecutedChain.pm

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


package OME::Web::ViewExecutedChain;

use strict;
use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use OME::DBObject;
use OME::Web::Helper::JScriptFormat;
use OME::Analysis::AnalysisEngine;
use OME::Tasks::ChainManager;

use base qw{ OME::Web };

my $popupFunction = <<ENDJS;
<script language="JavaScript">
<!--
function popupMEXresultsViewer(id){
	MEXresultsViewer = window.open(
		"serve.pl?Page=OME::Web::ViewMEXresults&MEX_ID=" + id,
		"MEXresultsViewer",
		"toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=500"
	);
}
-->
</script>
ENDJS


sub getPageTitle {
	return "Open Microscopy Environment - Execute Analysis Chain";
}

sub getPageBody {
	my $self = shift;
	my $body = "";
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $cgi = $self->CGI();
	
	if( $cgi->param( 'chain_execution_id' ) ) {
		my $chain_execution_id = $cgi->param( 'chain_execution_id' );
	
		my $analysis_chain_execution = $factory->loadObject( "OME::AnalysisChainExecution", $chain_execution_id )
			or die "Could not load chain execution (id=$chain_execution_id)";
			
		# display results
		$body .= "Results of ".$analysis_chain_execution->analysis_chain->name." execution.<br><br>";
		$body .= "<table><tr><td width=50>&nbsp;</td><td>";
		my %u;
		foreach my $mex ( map( $_->module_execution, $analysis_chain_execution->node_executions ) ){
# hack to bypass bug in analysis engine resulting in duplicate mex's in the chain execution
			next if exists $u{$mex->id}; $u{$mex->id}= undef;
			
			$body .= $popupFunction;
			$body .= "<a href='#' onClick='return popupMEXresultsViewer(".$mex->id.")'>";
#			$body .= "<a href='serve.pl?Page=OME::Web::ViewMEXresults&MEX_ID=".$mex->id."'>";
			$body .= $cgi->b($mex->module->name . '(' . $mex->id . ')' );
			$body .= "</a><br>";
		}
		$body .= "</tr></td></table>"
		
	} else {
		$body .= $self->print_form();
	}

	return ('HTML',$body);
}

sub print_form{
	my $self = shift;
	my $session = $self->Session();
	my $factory = $session->Factory();
	my $cgi     = $self->CGI();

# expand to allow MEX retrieval by more methods (e.g. browse by module name, etc) ?
	my $text;
	$text .= "<h3>Type the Module Chain Execution ID you wish to see results for.</h3>";

	$text .= $cgi->startform();
	$text .= $cgi->start_table({-border => 0, -cellspacing => 4, -cellpadding => 0});
	$text .= $cgi->Tr({-align => 'left', -valign => 'middle'},
		  $cgi->td($cgi->b("Chain Execution ID"),
			   $cgi->textfield(-name => 'chain_execution_id',
					   -size => 10)), 
		  $cgi->td({-colspan => 2},
			   $cgi->submit({-name  => 'display_results',
					 -value => 'Display Results'})));
	$text .= $cgi->end_table;

	$text .= $cgi->endform();

  	return $text;
}

1;
