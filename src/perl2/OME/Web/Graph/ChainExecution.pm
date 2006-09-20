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
use Date::Manip;

use base qw(OME::Web::Authenticated);

sub getPageTitle {
	return "Open Microscopy Environment - Graph the timing of a Chain Execution" ;
}

{
	my $menu_text = "Graph the timing of a Chain Execution";

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
		if( (not defined $chexID ) or 
		    ( $q->param( 'action' ) && $q->param( 'action' ) eq 'refresh' ) );
	
	if( $q->param( 'graph_as' ) eq 'time_series_by_node' ) {
		return $self->time_series_by_node();
	} elsif( $q->param( 'graph_as' ) eq 'worker_occupancy' ) {
		return $self->worker_occupancy();
	} elsif( $q->param( 'graph_as' ) eq 'tab_delimited_data' ) {
		return $self->tab_delimited_data();
	}
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
	$html .= "<br>";
	$html .= $q->p( "Graph results as:" );
	$html.= $q->radio_group(
		-name      => 'graph_as',
		'-values'  => ['time_series_by_node', 'worker_occupancy', 'tab_delimited_data' ],
		-default   => 'time_series_by_node',
		-linebreak => 'true',
		-labels    => { 
			'time_series_by_node' => 
				'Time Series by node. If the chain is complex, this can be a very busy graph.',
			'worker_occupancy' =>
				"Worker Occupancy. Shows which workers were occupied when. Useful for evaluating the DAE's scheduler. This graph will be screwed up if the chain execution re-used any previous results.",
			'tab_delimited_data' =>
				'Download a tab delimited text file of timing information.'
		}
	);
	$html .=" <br>";
	$q->param( 'action', '' );
	$html .= $q->hidden('action');
	$html .= $q->submit(-name=>'Graph!');
	$html .= $q->endform;

	return $html;
}

sub tab_delimited_data {
	my	$self = shift ;
	my 	$q = $self->CGI() ;
	my	$session=$self->Session();
    my  $factory = $session->Factory();
	
	my $chexID = $q->param( 'chain_execution' );
	
	# Load stuff
	my $chex = $factory->loadObject( 'OME::AnalysisChainExecution', $chexID )
		or die "Couldn't load chex, id: $chexID";
	my $chain = $chex->analysis_chain;
	my @nodes = $chain->nodes( __order => 'module.name' );


	my 	$graphTitle = "Executions of nodes within the chain execution: ".
		$self->Renderer()->getName( $chex );

	my $txt = $graphTitle."\n".
	          "MEX ID\tTimestamp\tTotal time\tRead time\tExecution time\tWrite time\n\n";
	
	foreach my $node ( @nodes ) {
		my $module = $node->module;
		$txt .= "Node: ".$self->Renderer()->getName( $node ).", id: ".$node->id."\n";
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
				$timestamp, 
				$mex->total_time,
				$mex->read_time,
				$mex->execution_time,
				$mex->write_time
			) )."\n";
		}
		$txt .= "\n";
	}

	return( 'TXT', $txt );

}

sub worker_occupancy {
	my	$self = shift ;
	my 	$q = $self->CGI() ;
	my	$session=$self->Session();
    my  $factory = $session->Factory();
	
	# Load stuff
	my $chexID = $q->param( 'chain_execution' );
	my $chex = $factory->loadObject( 'OME::AnalysisChainExecution', $chexID )
		or die "Couldn't load chex, id: $chexID";
	my @usedWorkers = $factory->findObjects( 
		'OME::Analysis::Engine::Worker', 
		'module_executions.node_executions.analysis_chain_execution' => $chex,
		__distinct => 'id',
		__order    => 'id'
	);

	# Constants for the graph
	my $graphWidth = 1000;
	my $graphHeight;
	my $leftMargin = 10;
	my $rightMargin = 10;
	my $topMargin = 10;
	my $bottomMargin = 10;
	my $textRowSpacingFactor = 1.2;
	
	my $graphTitleFontSize = 22;
	my $graphTitleLinkFontSize = 14;
	my $graphTitleHeight = $textRowSpacingFactor * ( $graphTitleFontSize + $graphTitleLinkFontSize ) + 4 * $topMargin;
	
	my $workerLabelFontSize = 16;
	my $workerLabelWidth = 200;
	my $workerRowHeight = $textRowSpacingFactor * $workerLabelFontSize;
	my $workerRowSpacing = 10;
	my $workerBlockStrokeWidth = 0;
	
	my $workingGraphSpace = $graphWidth - $leftMargin - $workerLabelWidth - $rightMargin;
	my $pixelsPerSecond = $workingGraphSpace / $chex->total_time;

	# Initialize Date::Manip's timezone to an arbitrary one.
	# This prevents it from crashing on my OS X installation. 
	# The timezone used doesn't matter because I'm only using Date::Manip to 
	# convert a timestamp into number of seconds from an arbitrary point so I 
	# can readily calculate distance between time events.
	Date_Init( "TZ=GMT" );

	# Determine the time window this chain executed in. 
	# This allows to determine the graph's scale and pixel offsets
	my $minMex = $factory->findObject( 
		'OME::ModuleExecution', 
		'node_executions.analysis_chain_execution' => $chex,
		__order => 'timestamp',
		__limit => 1
	);
	my $minT = UnixDate(
		ParseDate( $minMex->timestamp ), 
		,"%s"
	);
	my $maxT = $minT + $chex->total_time;
	
	my $svg = <<END;
<?xml version="1.0" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" 
"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">

<svg width="$graphWidth" height="100%" version="1.1"
xmlns="http://www.w3.org/2000/svg">
END

	# Print the graph title
	$svg .= sprintf( "<text x='%d' y='%d' text-anchor='middle' font-size='%d'>%s</text>\n", 
		( $graphWidth / 2 ),
		( $topMargin + $graphTitleFontSize ), 
		$graphTitleFontSize, 
		"Worker occupancy graph for chain execution ".
		$self->Renderer()->getName( $chex )
	);
	# Print a link to more info about this chex
	my $safeUrl = $self->getObjDetailURL( $chex );
	$safeUrl =~ s/&/;/g;
	$svg .= sprintf( "<a xlink:href='%s'><text x='%d' y='%d' text-anchor='middle' font-size='%d'>more information on this chain execution</text></a>\n",
		$safeUrl, 
		( $graphWidth / 2 ),
		( $topMargin + $textRowSpacingFactor * $graphTitleFontSize + $graphTitleLinkFontSize), 
		$graphTitleLinkFontSize, 
	);

	# Begin 
	my $verticalOffset = $graphTitleHeight;
	$svg .= "<g id='WorkerRows'>\n";
	foreach my $worker( @usedWorkers ) {
		my @executedModules = $factory->findObjects( 
			'OME::ModuleExecution', 
			'node_executions.analysis_chain_execution' => $chex,
			executed_by_worker => $worker, 
			__order => 'timestamp'
		);
		$svg .= sprintf( "\t<g id='WorkerRow%d' transform='translate( %d, %d )'>\n", 
			$worker->id, 
			$leftMargin, 
			$verticalOffset
		). 
		sprintf( "\t\t<text id='WorkerLabel%d' x='0' y='%d' text-anchor='start' font-size='%d'>Worker %d</text>\n", 
			$worker->id, 
			$workerLabelFontSize, 
			$workerLabelFontSize, 
			$worker->id, 
		).
		sprintf( "\t\t<g id='Worker%d-Jobs' transform='translate( %d, 0 )'>\n", 
			$worker->id, 
			$workerLabelWidth, 
		);
		foreach my $mex ( @executedModules ) {
			my $startTime = UnixDate(
				ParseDate( $mex->timestamp ), 
				,"%s"
			);
			my $horizontalOffet = $pixelsPerSecond * ( $startTime - $minT );
			my $width = $pixelsPerSecond * $mex->total_time;
			my $safeUrl = $self->getObjDetailURL( $mex );
			$safeUrl =~ s/&/;/g;
			$svg .= sprintf( "\t\t\t<a xlink:href='%s'>\n", $safeUrl );
			if( $q->url_param( 'NoMEXBreakdown' ) || $q->param( 'NoMEXBreakdown' ) ) {
				$svg .= sprintf( 
						"\t\t\t\t<rect x='%f' y='0' width='%f' height='%f' fill='green' stroke='black' stroke-width='%f'/>\n", 
					$horizontalOffet, 
					$width, 
					$workerRowHeight,
					$workerBlockStrokeWidth
				);
			} else {
				my $Rwidth = $pixelsPerSecond * $mex->read_time;
				my $Xwidth = $pixelsPerSecond * $mex->execution_time;
				my $Wwidth = $pixelsPerSecond * $mex->write_time;
				my $Owidth = $width - $Rwidth - $Xwidth - $Wwidth;
				$svg .= 
				# Outline the total time
				sprintf( 
						"\t\t\t\t<rect x='%f' y='0' width='%f' height='%f' fill='none' stroke='black' stroke-width='%f'/>\n", 
					$horizontalOffet, 
					$width, 
					$workerRowHeight,
					$workerBlockStrokeWidth
				# Read time: red
				).sprintf( 
						"\t\t\t\t<rect x='%f' y='0' width='%f' height='%f' fill='red'/>\n", 
					$horizontalOffet, 
					$Rwidth, 
					$workerRowHeight
				# Read time: yellow
				).sprintf( 
						"\t\t\t\t<rect x='%f' y='0' width='%f' height='%f' fill='yellow'/>\n", 
					$horizontalOffet + $Rwidth, 
					$Xwidth, 
					$workerRowHeight
				# Read time: blue
				).sprintf( 
						"\t\t\t\t<rect x='%f' y='0' width='%f' height='%f' fill='blue'/>\n", 
					$horizontalOffet + $Rwidth + $Xwidth, 
					$Wwidth, 
					$workerRowHeight
				# Unaccounted time: orange
				).sprintf( 
						"\t\t\t\t<rect x='%f' y='0' width='%f' height='%f' fill='orange'/>\n", 
					$horizontalOffet  + $Rwidth + $Xwidth + $Wwidth,
					$Owidth, 
					$workerRowHeight
				);
			}
			$svg .= "\t\t\t</a>\n";
		}
		$verticalOffset += $workerRowHeight + $workerRowSpacing;
		$svg .= "\t\t</g>\n\t</g>\n\n";
	}
	
	$svg .= "</g>\n</svg>\n";

	$self->contentType("image/svg+xml");
	return( 'SVG', $svg );
}

sub time_series_by_node {
	my	$self = shift ;
	my 	$q = $self->CGI() ;
	my	$session=$self->Session();
    my  $factory = $session->Factory();
	
	my $chexID = $q->param( 'chain_execution' );
	
	# Load stuff
	my $chex = $factory->loadObject( 'OME::AnalysisChainExecution', $chexID )
		or die "Couldn't load chex, id: $chexID";
	my $chain = $chex->analysis_chain;
	my @nodes = $chain->nodes( __order => 'module.name' );


	my 	$graphTitle = "Executions of nodes within the chain execution: ".
		$self->Renderer()->getName( $chex );
	my %nodeTimingDat;
	
	foreach my $node ( @nodes ) {
		my $module = $node->module;
		$nodeTimingDat{ $node->id }{ name } = $self->Renderer()->getName( $node );
		my @nexs = $chex->node_executions( 
			analysis_chain_node => $node,
			__order => 'module_execution.timestamp'
		);
		foreach my $nex ( @nexs ) {
			my $mex = $nex->module_execution();
			my $timestamp = $mex->timestamp;
			$timestamp =~ s/^(\d\d\d\d-\d\d-\d\d\s+\d\d:\d\d:\d\d)(\.\d+)?/$1/;
			push( 
				@{ $nodeTimingDat{ $node->id }{ data } }, 
				$timestamp, $mex->total_time
			);
		}
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
		if( $nodeTimingDat{ $node_id }{ data } &&
		    scalar( $nodeTimingDat{ $node_id }{ data } ) > 0 ) {
			$graph->add_data({
				'data'  => $nodeTimingDat{ $node_id }{ data },
				'title' => $nodeTimingDat{ $node_id }{ name },
			});
		}
	}

	$self->contentType("image/svg+xml");
	return ('SVG',$graph->burn());
}

1;
