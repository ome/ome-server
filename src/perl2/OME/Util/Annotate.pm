# OME/Util/Annotate/Annotate.pm

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


package OME::Util::Annotate::Annotate;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use Getopt::Long;
Getopt::Long::Configure("bundling");
use OME::Web::SpreadsheetImporter::SpreadsheetImporter;

sub getCommands {
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
    spreadsheet      Command for doing bulk annotations based on Excel spreadsheets
   	                 or csv files (e.g. created by the OME annotation wizards) 
    help <command>   Display help information about a specific command

CMDS
}

sub spreadsheet_importer {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    my ($file, $noop);
	GetOptions('f|file=s' => \$file,
   			   'n|noop=s' => \$noop);
   			   
    die "Flag not supported. Inform Tomasz\n" if $noop;
	
	$file = $ARGV[0] if (scalar @ARGV);
	$self->spreadsheet_help($commands) if (not defined $file);
   			   
	my $output = OME::Web::SpreadsheetImporter::SpreadsheetImporter->processFile($file);
	$output =~ s/<br>/\n/;
	print "$output\n";
}

sub spreadsheet_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"CMDS";
Usage:
    $script $command_name [<options>]

This command parses Excel spreadsheets or csv files (e.g. created by the OME
annotation wizards) to create bulk annotations.

Options:
	 -f, --file
	 The Excel or csv spreadsheet that will be parsed to generate annotations.
	 
     -n, --noop
     Do not create any annotations, just report what would be created.
     
CMDS
    CORE::exit(1);
}
1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
