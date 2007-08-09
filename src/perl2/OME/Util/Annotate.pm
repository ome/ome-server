# OME/Util/Annotate.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2004 Open Microscopy Environment
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
# Written by:    Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------


package OME::Util::Annotate;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Getopt::Long;
use OME::Util::Annotate::SpreadsheetReader;

sub getCommands {
    my $self = shift;
    return
      {
       'wizard' => ['OME::Util::Annotate::AnnotationWizards'],
       'spreadsheet' => 'spreadsheet_importer',
      };
}

sub listCommands {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name <command> [<options>]

$script $command_name commands are:
    wizard           Various wizards to help users define image annotations based 
                     on their directory structure.
    spreadsheet      Command for doing bulk annotations based on Excel or tsv 
                     spreadsheets (e.g. created by the OME annotation wizards) 
    help <command>   Display help information about a specific command

CMDS
}

sub spreadsheet_importer {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);

    my ($file, $noop);
    GetOptions('f|file=s' => \$file,
   			   'n|noop!'   => \$noop);
   			   
	die "Specify the input filename with the -f flag\n" unless $file;
	
	$file = $ARGV[0] if (scalar @ARGV);
	$self->spreadsheet_importer_help($commands) and return if (not defined $file);
	
	my $session = $self->getSession();
	my $results = OME::Util::Annotate::SpreadsheetReader->processFile($file,$noop);
	my $output;
	if (!ref $results) {
		$output .= "Error annotating: \n";
		$output .= $results;
	} else {
		$output .= "Finished annotating: \n";
		$output .= OME::Util::Annotate::SpreadsheetReader->printSpreadsheetAnnotationResultsCL($results);
	}

	# format HTML output so it looks nice when printed out to the command-line
	print "$output";
}

sub spreadsheet_importer_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>]

This command parses Excel or tsv spreadsheets (e.g. created by the OME
annotation wizards) to create bulk annotations.

Options:
     -f, --file
     The Excel or tsv spreadsheet that will be parsed to generate annotations.
	 
     -n, --noop
     Do not create any annotations, just report what would be created.
     
CMDS
}
1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

