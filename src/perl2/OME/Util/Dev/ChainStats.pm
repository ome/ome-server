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
  --chex <id>
     ID of Analysis chain executions

USAGE
    CORE::exit(1);
}

sub chex_stats {
	my $self = shift;
	
	my ($chex_id );
	
	GetOptions ('chex=i' => \$chex_id );

	die "Need a chex id" unless $chex_id;

    my $session = $self->getSession();	
	my $factory = $session->Factory();
	
	my $chex = $factory->loadObject( 'OME::AnalysisChainExecution', $chex_id )
		or die "Couldn't load chex $chex_id";
	my @total_nodes = $chex->analysis_chain->nodes( __distinct => 'id' );
	my @executed_nodes = $chex->node_executions( __distinct => 'analysis_chain_node' );
	@executed_nodes = map( $_->analysis_chain_node, @executed_nodes );
	
	print scalar( @executed_nodes )." of ".scalar( @total_nodes )." nodes have been executed.\n";
	
	
	my @executions_per_node = map( $chex->count_node_executions( analysis_chain_node => $_ ), @executed_nodes );
	my $sum = 0; 
	my %mode_bucket;
	map{ $mode_bucket{ $_ } = 0 } @executions_per_node;
	foreach ( @executions_per_node ) {
		$sum += $_;
		$mode_bucket{ $_ }++;
	}
	my @mode_bucket_indexes; @mode_bucket_indexes = keys( %mode_bucket );
	sort { $mode_bucket{ $b } cmp $mode_bucket{ $a } } @mode_bucket_indexes;
	my $mode = $mode_bucket_indexes[0];
	my $average = $sum / scalar( @executed_nodes );
	
	print "there have been an average of $average executions per node.\n";
	print "the mode is $mode.\n";
	print "the sum is $sum.\n";

}

1;
