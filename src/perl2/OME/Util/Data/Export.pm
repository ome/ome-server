# OME/Util/Export.pm

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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------

package OME::Util::Export;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Carp;
use Getopt::Long;

use OME::SessionManager;
use OME::Session;
use OME::ImportExport::ChainExport;

use Getopt::Long;
Getopt::Long::Configure("bundling");



sub getCommands {
    return
      {
       'chains'     => 'chains',
      };
}


sub chains_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>] [<list of chains>]

This utility exports analysis chains into OME XML files.
Analysis chains can be specified by ID or by name

Options:
      
  -f  Specify a filename for the OME XML file.  Otherwise all output goes
      to STDOUT

  -h  Print this help message.
  
  --no_compress  Do not compress the output file. (disabled by default)
  
USAGE
    CORE::exit(1);
}


sub chains {
	my ($self,$commands) = @_;
	my ($filename, $help, $datasetName, $no_compression );
	
	GetOptions(
		'file|f=s' => \$filename,
		'no_compress!' => \$no_compression 
	);
	$no_compression = ( $no_compression ? 0 : undef );
	my @chain_names = @ARGV;
	
	my $session = $self->getSession();
	my $factory = $session->Factory();
	my $chainExport = OME::ImportExport::ChainExport->new();
	my @chains;

	foreach my $chain_name (@chain_names) {
		my $chain;
		if ($chain_name =~ /^\d+$/) {
			$chain = $factory->findObject("OME::AnalysisChain",id => $chain_name);
		} else {
			$chain = $factory->findObject("OME::AnalysisChain",name => $chain_name);
		}
		push (@chains,$chain) if $chain;
	}
	
	$chainExport->buildDOM (\@chains);

	if ($filename) {
		$chainExport->exportFile ($filename, 
			( defined $no_compression ? ( compression => 0 ) : () )
		);
	} else {
		print $chainExport->exportXML();
	}

}

