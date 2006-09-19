# OME/Web/Graph/NodeExecutions.pm

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
# Written by:    Josiah Johnston <siah@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::Web::Graph::NodeExecutions;

use strict;
use vars qw($VERSION);
use Log::Agent;
use OME;
$VERSION = $OME::VERSION;

use SVG::TT::Graph::TimeSeries;


use base qw(OME::Web::Authenticated);

sub getPageTitle {
	return "Open Microscopy Environment - Graph Node Executions" ;
}

{
	my $menu_text = "Graph Node Executions";

	sub getMenuText { return $menu_text }
}


# Override's OME::Web


sub getPageBody {
	my	$self = shift ;
	my 	$q = $self->CGI() ;
	my	$session=$self->Session();
    my  $factory = $session->Factory();
	
	my $chexID = $q->param( 'chain_execution' );
	my $nodeID = $q->param( 'chain_node' );

	return( 'HTML', $self->print_form() )
		unless $chexID && $nodeID;
	
	my $chex = $factory->loadObject( 'OME::AnalysisChainExecution', $chexID )
		or die "Couldn't load chex, id: $chexID";
	my $node = $factory->loadObject( 'OME::AnalysisChain::Node', $nodeID )
		or die "Couldn't load node, id: $nodeID";

	return( 'HTML', $q->h2( 'Select a node in the chain that was executed' ).$self->print_form() )
		unless( $chex->analysis_chain->id == $node->analysis_chain->id);

	my @nexs = $chex->node_executions( 
		analysis_chain_node => $node,
		__order => 'module_execution.timestamp'
	);
	my 	$graphTitle = "Executions of the node ".$self->Renderer()->getName( $node ).
		" within the chain execution: ".$self->Renderer()->getName( $chex );
		
	if( $q->param( 'download_text' ) ) {
		my $txt;
		$txt .= $graphTitle."\n";
		$txt .= "MEX ID\tTimestamp\tTotal time\tRead time\tExecution time\tWrite time\n\n";
		foreach my $nex( @nexs ) {
			my $mex = $nex->module_execution();
			my $timestamp = $mex->timestamp;
			$timestamp =~ s/^(\d\d\d\d-\d\d-\d\d\s+\d\d:\d\d:\d\d)(\.\d+)?/$1/;
			$txt .= join( "\t", (
				$mex->id,
				$timestamp, 
				$mex->total_time,
				$mex->read_time,
				$mex->execution_time,
				$mex->write_time,
			) )."\n";
		}
		return( 'TXT', $txt );
	}
		
	my (@totalTime, @readTime, @executionTime, @writeTime );
	foreach my $nex( @nexs ) {
		my $mex = $nex->module_execution();
		my $timestamp = $mex->timestamp;
		$timestamp =~ s/^(\d\d\d\d-\d\d-\d\d\s+\d\d:\d\d:\d\d)(\.\d+)?/$1/;
		push( @totalTime, $timestamp, $mex->total_time );
		push( @readTime, $timestamp, $mex->read_time );
		push( @executionTime, $timestamp, $mex->execution_time );
		push( @writeTime, $timestamp, $mex->write_time );
	}
	
	my $timescale_divisions = 
		$q->param( 'timescale_divisions' ) ||
		'30 minutes';
	my $graph = SVG::TT::Graph::TimeSeries->new({
		# Layout settings
		'height' => '500',
		'width' => '1000',
		'show_data_values'  => 0,
#		'rollover_values'   => 1,
		# X-axis settings
		'timescale_divisions' => $timescale_divisions,
		'rotate_x_labels'     =>  1, 
		'show_x_title'        => 1,
		'x_title'             => 'Execution initiation time',
		# Y-axis settings
		'show_y_title'      => 1,
		'y_title'           => 'Total execution time',        
		# Graph Semantics
		'show_graph_title'  => 1,
		'graph_title'       => $graphTitle,
		'key'               => 1,
		'key_position'      => 'bottom'
	});
	
	$graph->add_data({
		'data' => \@totalTime,
		'title' => 'Total time',
	});
  	$graph->add_data({
  		'data' => \@readTime,
  		'title' => 'Read time',
  	});
  	$graph->add_data({
  		'data' => \@executionTime,
  		'title' => 'Execution time',
  	});
  	$graph->add_data({
  		'data' => \@writeTime,
  		'title' => 'Write time',
  	});

	$self->contentType("image/svg+xml");
	return ('SVG',$graph->burn());
	
}




############
sub print_form{
	my ($self )=@_;
	my 	$q = $self->CGI() ;
	my $html="";

	# html ouput
	$html .= $q->h3("Select a node and chain Execution to see it graphed");
	$html .= $q->startform( { -name => 'primary' } );
	$html .= 'Select a Chain Execution: ';
	$html .= $self->SearchUtil()->getObjectSelectionField( 
		'OME::AnalysisChainExecution', 
		'chain_execution',
		{ select_one => 1 }
	);
	$html.="<br>";
	$html .= 'Select a Node in that Chain: ';
	$html .= $self->SearchUtil()->getObjectSelectionField( 
		'OME::AnalysisChain::Node', 
		'chain_node',
		{ select_one => 1 }
	);
	$html.="<br>";
	$html.= $q->checkbox( -name => 'download_text', -value => 'OFF', -label => 'Download as Tab delimited spreadsheet' );
	$html.="<br>";
	$html.=$q->submit(-name=>'Graph!');
	$html.=$q->endform;

	return $html;
}


1;
