# OME/Web/Graph/ChainExecution.pm

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


package OME::Web::Graph::ChainExecution;

use strict;
use vars qw($VERSION);
use Log::Agent;
use OME;
$VERSION = $OME::VERSION;

use SVG::TT::Graph::TimeSeries;


use base qw(OME::Web::Authenticated);

sub getPageTitle {
	return "Open Microscopy Environment - Graph the timing of a Chain Execution" ;
}

{
	my $menu_text = "Graph the timinb of a Chain Execution";

	sub getMenuText { return $menu_text }
}


# Override's OME::Web


sub getPageBody {
	my	$self = shift ;
	my 	$q = $self->CGI() ;
	my	$session=$self->Session();
    my  $factory = $session->Factory();
	
	my $chexID = $q->param( 'chain_execution' );

	return( 'HTML', $self->print_form() )
		unless $chexID;
	
	# Load stuff
	my $chex = $factory->loadObject( 'OME::AnalysisChainExecution', $chexID )
		or die "Couldn't load chex, id: $chexID";
	my $chain = $chex->analysis_chain;
	my @nodes = $chain->nodes( __order => 'module.name' );


	my 	$graphTitle = "Executions of nodes within the chain execution: ".
		$self->Renderer()->getName( $chex );
	my %nodeTimingDat;
	
	my $txt = $graphTitle."\n".
	          "MEX ID\tTimestamp\tTotal time\tRead time\tExecution time\tWrite time\n\n";
	
	foreach my $node ( @nodes ) {
		my $module = $node->module;
		$txt .= "Node: ".$self->Renderer()->getName( $node ).", id: ".$node->id."\n";
		$nodeTimingDat{ $node->id }{ name } = $self->Renderer()->getName( $node );
		my @nexs = $chex->node_executions( 
			analysis_chain_node => $node,
			__order => 'module_execution.timestamp'
		);
		foreach my $nex ( @nexs ) {
			my $mex = $nex->module_execution();
			my $timestamp = $mex->timestamp;
			$timestamp =~ s/^(\d\d\d\d-\d\d-\d\d\s+\d\d:\d\d:\d\d)(\.\d+)?/$1/;
			$txt .= join( "\t", (
				$mex->id,
				$mex->timestamp, 
				$mex->total_time,
				$mex->read_time,
				$mex->execution_time,
				$mex->write_time
			) )."\n";
			push( 
				@{ $nodeTimingDat{ $node->id }{ data } }, 
				$timestamp, $mex->total_time
			);
		}
		$txt .= "\n";
	}

	# Give them text if that's what they want
	if( $q->param( 'download_text' ) ) {
		return( 'TXT', $txt );
	}

	my $timescale_divisions = 
		$q->param( 'timescale_divisions' ) ||
		'10 hours';
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
		'key_position'      => 'right'
	});
	
	foreach my $node_id ( keys %nodeTimingDat ) {
		if( scalar( $nodeTimingDat{ $node_id }{ data } ) > 0 ) {
			$graph->add_data({
				'data'  => $nodeTimingDat{ $node_id }{ data },
				'title' => $nodeTimingDat{ $node_id }{ name },
			});
		}
	}

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
	$html.= $q->checkbox( -name => 'download_text', -value => 'OFF', -label => 'Download as Tab delimited spreadsheet' );
	$html.="<br>";
	$html.=$q->submit(-name=>'Graph!');
	$html.=$q->endform;

	return $html;
}


1;
