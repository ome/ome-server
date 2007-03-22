# OME/Util/OMECommander.pm

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
# Written by:   Tom Macura <tmacura@nih.gov>
#-------------------------------------------------------------------------------


package OME::Util::OMECommander;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);
use Getopt::Long;
Getopt::Long::Configure("bundling");

sub getCommands {
    return
      {
       'admin'      => ['OME::Util::Admin::OMEAdmin'],
       'annotate'   => ['OME::Util::Annotate'],
       'data'       => ['OME::Util::Data::dbAdmin'],
       'dev'        => ['OME::Util::Dev'],
       'import'     => ['OME::Util::Import'],
       'execute'    => ['OME::Util::ExecuteChain'],
       'top'        => ['OME::Util::Top'],
       'self-document' => 'selfDocument',
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

ome commands are:
    admin            Commands for administering OME users and settings
    annotate         Commands for mass annotation of OME objects
    data             Commands for managing OME data
    dev              Advance Commands used by OME Developers
    execute          Command for executing OME analysis chains
    import           Command for importing files to OME
    top              Command for displaying progress info about OME tasks
    help <command>   Display help information about a specific command

Global options are:
    --OMEUser, --ou       Specify the OME username (i.e. --ou igg)
    --OMEPassword, --opw  Specify the OME password (i.e. --opw abc123)
    --OMESessionKey, --ok Specify the OME SessionKey (i.e. --ok ABC123HKL456)
    
Note that most of these commands will require you to log in as an
already-existing OME administrative user.
CMDS
# Note that the following options are temporarily defeated:
#    --DataSource, --db    Specify the OME database (i.e. --db ome)
#    --DBUser, --dbu       Specify the database user (i.e. --dbu postgres)
#    --DBPassword, --dbpw  Specify the database password (i.e. --dbpw def456)
}

my $TOC_HTML;
sub selfDocument {
	my ($self) = @_;
	# don't need it
	my $commands = $self->getCommands();
	my $session = $self->getSession(); # log-in, just in case (login required to
									   # display ome import help message

	my ($output_dir);
	GetOptions ('o|output=s' => \$output_dir);

	# idiot traps
	if (not defined $output_dir) {
		die "The Output Directory needs to be specified.\n"; 
	}
	
	# Write the TOC html that will be injected (via javascript) into the various
	# help pages
	open ($TOC_HTML, ">$output_dir/toc.html");
	print $TOC_HTML <<HTMLSTART;
<h1>OME Commander Reference</h1>
HTMLSTART
    print ($TOC_HTML "<ul>\n");
	$self->create_TOC ($output_dir, $self, $commands);
    print ($TOC_HTML "</ul>\n");
    
	print $TOC_HTML <<HTMLEND;
HTMLEND
	close $TOC_HTML;
	
	open (INDEX_HTML, ">$output_dir/index.html");
	print INDEX_HTML <<HTMLCONTENTS;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
	<meta http-equiv="content-type" content="text/html;charset=utf-8">
	<meta http-equiv="Content-Script-Type" content="text/javascript">
	<link href="http://www.openmicroscopy.org.uk/earthy.css" rel="stylesheet" type="text/css" media="all">
	<script src="http://www.openmicroscopy.org.uk/templates.js"></script>
	<script src="http://www.openmicroscopy.org.uk/site.js"></script>
	<script src="http://www.openmicroscopy.org.uk/sarissa.js"></script>
  </head>

  <body bgcolor="#ffffff" onload="injectHTML('help_toc','toc.html');">
	<div class="menu help_toc" id="help_toc"> </div>
  </body>
</html>
HTMLCONTENTS
	close INDEX_HTML;
}

sub create_TOC {
	my ($self, $output_dir, $global_class, $commands, $supercommands) = @_;
    $supercommands = [] unless defined $supercommands;
    
	foreach my $command (sort keys %$commands) {
		my @supercommands_command = @$supercommands;
		if (@$supercommands[-1] ne $command) {
        	push @supercommands_command, $command;
        }
        print "@supercommands_command\n";
        
        my $base_method = $commands->{$command};        
        if (ref($base_method) eq 'ARRAY') {
			my $class = $base_method->[0];
            $class->require();
            my $next_commands = $class->getCommands();
            
            my $print_in_bullet_list = 0;
            
            # decides whether to print_in_bullet_list or not
            if (scalar keys %$next_commands > 1){
            	$print_in_bullet_list = 1;
            } else {
            	my @next_commands_array = keys %$next_commands;
				my $next_command = $next_commands_array[0];
				if ($next_command eq $command){
					$print_in_bullet_list = 0; # don't print cause duplicate command names
				} else {
					$print_in_bullet_list = 1;
				}
            }
            
            if ($print_in_bullet_list) {
            	# it's a grouping so MAKE an html file listing available commands 
            	$self->write_method_help ($output_dir, $class, [@supercommands_command], '$class->listCommands($supercommands);');
            	
				# list the grouping's commands
            	print ($TOC_HTML "<ul>\n");
				$self->create_TOC($output_dir, $class, $class->getCommands(), [@supercommands_command]);
				print ($TOC_HTML "</ul>\n");
			
			} else {
				# we ignore this grouping cause it isn't real e.g. ome admin configure configure
				$self->create_TOC($output_dir, $class, $class->getCommands(), [@supercommands_command]);
			}
        
        } else {
 			if (UNIVERSAL::can($global_class,${base_method}."_help")) { 			
				# write some HTML 			
            	$self->write_method_help ($output_dir, $global_class, [@supercommands_command], '$class->'.${base_method}.'_help'.'($supercommands);');
 			} else {
 				# No help available
				print ($TOC_HTML "<li>".$command."</li>\n") unless ($command eq "self-document");
 			}

        }
    }
}

sub write_method_help {
	my ($self, $output_dir, $class, $supercommands, $print_method_str) = @_;
	my @cmds = @$supercommands;
	print STDERR "@cmds\n";
	
	# get method's help information into a tmp file
	open (STDOUT, ">$output_dir/output_redirect") || die "Can't redirect stdout";
	eval $print_method_str;
	close(STDOUT);
	
	# read the file, fix escape characters and write the html file
	open (OUTPUT_STDOUT, "<$output_dir/output_redirect");
	my @output_stdout = <OUTPUT_STDOUT>;
	close (OUTPUT_STDOUT);

	my $output_html = join ("_", @cmds).".html";				
	open (OUTPUT_HTML, ">$output_dir/$output_html") || die "Couldn't write HTML file";
	print($TOC_HTML '<li><a href="'.$output_html.'">'.$cmds[-1]."</a></li>\n");
	print OUTPUT_HTML <<HTMLSTART2;
			
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
  <head>
	<meta http-equiv="content-type" content="text/html;charset=utf-8">
	<meta http-equiv="Content-Script-Type" content="text/javascript">
	<link href="http://www.openmicroscopy.org.uk/earthy.css" rel="stylesheet" type="text/css" media="all">
	<script src="http://www.openmicroscopy.org.uk/templates.js"></script>
	<script src="http://www.openmicroscopy.org.uk/site.js"></script>
	<script src="http://www.openmicroscopy.org.uk/sarissa.js"></script>
  </head>

  <body bgcolor="#ffffff" onload="injectHTML('help_toc','toc.html');">
    <script> startDocument(); </script>
	<table>
	<tr>
		<td style="vertical-align: top;">	
		<div class="menu help_toc" id="help_toc"> </div>
		</td>
		<td style="vertical-align: top;">	
		<a href="../index.html">Back to OME Commander Documentation</a>
<PRE>
HTMLSTART2
				print OUTPUT_HTML "<h1>ome @cmds</h1>\n";
				
				foreach (@output_stdout) {
					while($_ =~ s/</&lt;/){;}
					while($_ =~ s/>/&gt;/){;}
					print OUTPUT_HTML $_;
				}
				
				print OUTPUT_HTML <<HTMLEND2;
</PRE>
		</td>
	</tr>
	</table>
    <script> endDocument(); </script>
  </body>
</html>

</div>
</body>
</html>
HTMLEND2
}
1;

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>,
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut

