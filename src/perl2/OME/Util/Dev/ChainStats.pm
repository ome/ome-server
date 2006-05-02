# OME/Util/ChainStats.pm

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

package OME::Util::ChainStats;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use Getopt::Long;

use OME::Session;
use OME::SessionManager;
use Term::ReadKey;

# I really hate those "method clash" warnings, especially since these
# methods are now deprecated.
no strict 'refs';
undef &Class::DBI::min;
undef &Class::DBI::max;
use strict 'refs';

use Getopt::Long;
Getopt::Long::Configure("bundling");


sub getCommands {
    return
      {
       'chex_stats'     => 'chex_stats',
      };
}

sub chex_stats_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:  
    $script $command_name [<options>]

This command displays statistics about a chain execution.

Options:
  -c | --chex <id>
     ID of Analysis chain executions
  -v | --verbose
     print more information

USAGE
    CORE::exit(1);
}

sub chex_stats {
	# Setup variables
	my $self = shift;
    my $session = $self->getSession();	
	my $factory = $session->Factory();	
	my ($chex_id, $verbose );
	
	# Collect inputs
	GetOptions ('c|chex=i' => \$chex_id,
	            'v|verbos' => \$verbose,
	           );

	# Load data
	die "Need a chex id" unless $chex_id;
	my $chex = $factory->loadObject( 'OME::AnalysisChainExecution', $chex_id )
		or die "Couldn't load chex $chex_id";
		
	my @total_nodes    = $chex->analysis_chain->nodes();
	my @executed_nodes = $chex->node_executions( __distinct => 'analysis_chain_node' );
	@executed_nodes    = map( $_->analysis_chain_node, @executed_nodes );
	my @error_nodes    = $chex->node_executions( 'module_execution.status' => 'ERROR', __distinct => 'analysis_chain_node' );
	@error_nodes       = map( $_->analysis_chain_node, @error_nodes );
	
	# Derive NEX/Node stats
	my @executions_per_node = map( $chex->count_node_executions( analysis_chain_node => $_ ), @executed_nodes );
	my $sum = 0; 
	my %histogram;
	map{ $histogram{ $_ } = 0 } @executions_per_node;
	foreach ( @executions_per_node ) {
		$sum += $_;
		$histogram{ $_ }++;
	}
	my $mode = $executions_per_node[0];
	# find the index of highest histogram value. That's the mode.
	foreach ( keys( %histogram ) ) {
		$mode = $_
			if( $histogram{ $mode } < $histogram{ $_ } );
	}
	my $average = $sum / scalar( @executed_nodes );


	# Derive MEX stats, including timing info
	my @nexes            = $chex->node_executions();
	my @mexes            = map( $_->module_execution, @nexes );
	my $reused_mex_count = grep( $_->count_node_executions > 1, @mexes );
	my ($mex_total_time, $mex_total_time_breakdown, 
	    $mex_execution_time, $mex_db_retrieval_time, $mex_db_storage_time ) = 
	   (0,0,0,0,0);
	my $mexes_w_time = 0;
	my %mexes_wo_time;
	foreach my $mex (@mexes) {
		$mex_total_time += $mex->total_time;
		if ( $mex->read_time or
			 $mex->write_time or
			 $mex->execution_time ) {
				$mex_total_time_breakdown += $mex->total_time;
				
				$mex_execution_time += $mex->execution_time
					if (defined $mex->execution_time);
				$mex_db_retrieval_time += $mex->read_time
					if (defined $mex->read_time);
				$mex_db_storage_time += $mex->write_time
					if (defined $mex->write_time);
				$mexes_w_time++;
		} else {
				$mexes_wo_time{ $mex->module->name }++;
		}
	}

	# Derive DAE information
	my %mexes_per_DAE_worker;

	foreach my $mex (@mexes) {
		next unless (defined $mex->executed_by_worker());
		
		if ( not defined $mexes_per_DAE_worker{$mex->executed_by_worker()->id()} ){
			$mexes_per_DAE_worker{$mex->executed_by_worker()->id()} = 1;
		} else {
			$mexes_per_DAE_worker{$mex->executed_by_worker()->id()} = 
				$mexes_per_DAE_worker{$mex->executed_by_worker()->id()} + 1;
		}
	}

	# Print Overview
	print "Displaying information about chain ".$chex->analysis_chain->name." (id:".$chex->analysis_chain->id.") ".
	      "executed against dataset ".$chex->dataset->name." (id:".$chex->dataset->id.") on ".$chex->timestamp.".\n";
	print "	The dataset contains ".$chex->dataset->count_images." images.\n";
		print scalar( @executed_nodes )." of ".scalar( @total_nodes )." nodes have been executed.\n";
	print "	Of those, ".scalar( @error_nodes )." nodes had at least one error.\n"
		if scalar( @error_nodes );
	printf( "Chain's Execution Time: %.2f sec\n",$chex->total_time());
	printf( "Chain Overhead Time: %.2f sec\n", $chex->total_time() - $mex_total_time);
	
	
	# Print NEX/Node stats
	print "\nNode execution stats:\n";
	print "	average executions per node: $average\n";
	print "	mode:                        $mode\n";
	print "	sum:                         $sum\n";
	if( $verbose ) {
		print "Executed nodes:\n"
			if ( scalar( @executed_nodes  ) );
		foreach my $node ( @executed_nodes ) {
			print "\t".$node->module->name()." x ".$chex->count_node_executions( analysis_chain_node => $node )."\n";
		}
		print "Nodes with errors:\n"
			if ( scalar( @error_nodes  ) );
		foreach my $node ( @error_nodes ) {
			print "\t".$node->module->name().": ".
				$chex->count_node_executions( analysis_chain_node => $node, 'module_execution.status' => 'ERROR' )." errors\n";
		}
		my @non_executed_nodes = $chex->analysis_chain->nodes( id => [ 'not in', \@executed_nodes ] );
		print "Non-executed nodes:\n"
			if ( scalar( @non_executed_nodes  ) );
			
		foreach my $node ( @non_executed_nodes ) {
			print "\t".$node->module->name()."\n";
		}
	}
	
	# Print MEX stats
	printf( "\nModule execution stats:\n" );
	printf( "	Modules executed: %.0f\n", scalar( @mexes ) );
	printf( "	Reused MEXes:     %.0f\n", $reused_mex_count );
	printf( "	Total time spent executing modules: %.2f sec\n", $mex_total_time );
	printf( "Detailed timing information available for %.0f of %.0f MEXs\n", $mexes_w_time, scalar( @mexes ) );
	if( $mexes_w_time ) {
		printf( "	Execution time: %.2f sec (%.2f%%)\n", $mex_execution_time, $mex_execution_time/$mex_total_time_breakdown * 100 );
		printf( "	Input retrieval time: %.2f sec (%.2f%%)\n", $mex_db_retrieval_time, $mex_db_retrieval_time/$mex_total_time_breakdown * 100 );
		printf( "	Output storage time: %.2f sec (%.2f%%)\n", $mex_db_storage_time, $mex_db_storage_time/$mex_total_time_breakdown * 100 );
		printf( "	Other: %.2f sec (%.2f%%)\n", 
				($mex_total_time_breakdown - $mex_execution_time - $mex_db_retrieval_time - $mex_db_storage_time), 
				(($mex_total_time_breakdown - $mex_execution_time - $mex_db_retrieval_time - $mex_db_storage_time)/$mex_total_time_breakdown * 100 )
		);
		printf( "	Total time executing these modules: %.2f sec\n", $mex_total_time_breakdown );
	}
	if( $verbose ) {
		print "These modules did not record the breakdown of their execution time.\n";
		print "	[module name]	[num times it appears in this chex]\n";
		foreach my $module_name ( sort( keys( %mexes_wo_time )) ) {
			print "	$module_name	".$mexes_wo_time{ $module_name }."\n";
		}
	}
	
	# print DAE stats
	my @DAE_worker_IDs = keys %mexes_per_DAE_worker;
	if (scalar @DAE_worker_IDs) {
		print ( "\nDAE Statistics \n" );
		foreach (sort @DAE_worker_IDs) {
			my $worker = $factory->loadObject ('OME::Analysis::Engine::Worker', $_);
			printf("   Worker %s executed %d MEXs.\n", $worker->URL(), $mexes_per_DAE_worker{$_});
		}
	}
}

1;
