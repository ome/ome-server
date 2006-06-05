# OME/Util/Annotate/AnnotationWizards.pm

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


package OME::Util::Annotate::AnnotationWizards;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);
use Getopt::Long;
use File::Spec::Functions qw(rel2abs);

use OME::Install::Util; # for scan_dir
use OME::Util::Annotate::SpreadsheetWriter;

sub getCommands {
    return
      {
       'PDI'  => 'pdi_wizard',
       'CGC' =>  'cgc_wizard',
 #     'SPW' =>  'spw_wizard',
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

    These wizards programatically generate image annotations by interpreting
    directory structure under the guidance of the user.
    
$script $command_name commands are:
    PDI    Wizard for organising images into a projects/datasets/images heirarchy
           
    CGC    Wizard for organising images into a category-group/category/images
           heirarchy 
	       
    SPW    Wizard for organising images into a screens/plates/wells/images
           heirarchy [NOT IMPLEMENTED]
	      
    help <command>   Display help information about a specific command

CMDS
}

sub pdi_wizard {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    my ($file, $root, $short, @exclude_dir);
	GetOptions('f|file=s' => \$file,
   			   'r|root=s' => \$root,
   			   's|short'  => \$short,
   			   'x|exclude=s' => \@exclude_dir);
   	@exclude_dir = split(/,/,join(',', @exclude_dir));
   	
	$self->pdi_wizard_help($commands) unless (defined $file and defined $root);
	die "root parameter is not a directory" if (not -d $root);
	$root = rel2abs($root);

	foreach (@exclude_dir) {
		die "exclude parameter: $_ is not a directory\n"
			unless (-d $_);
#		die "exclude parameter: $_ is not a sub-directory of root\n"
#			unless (path_in_tree(rel2abs($root), rel2abs($_)));
	}
	
	my @project_dir;
	if (not $short) {
		foreach my $proj_dir (scan_dir($root, sub{ (!/^\.{1,2}$/) && ( -d "$root/$_" ) })) {
			$proj_dir = rel2abs($proj_dir);
			
			my $skip;
			foreach (@exclude_dir) {
				$skip = 1 if ($proj_dir eq rel2abs($_));
			}
			next if $skip;
			push (@project_dir, $proj_dir);
		}
	} else {
		my $skip;
		foreach $_ (@exclude_dir) {
			$skip = 1 if rel2abs($root) eq rel2abs($_);
		}
		$project_dir[0] = $root unless $skip;
	}
	
	my @dataset_dir;
	foreach my $project_directory (@project_dir) {
		# Add all the subdirectories to the dataset list, excluding '.' and '..'
		push @dataset_dir, scan_dir($project_directory, sub{ (!/^\.{1,2}$/) && ( -d "$project_directory/$_" ) });
	}

	my $project_column;
	if (not $short) {
		$project_column = {ColumnName => "Project"};	
		foreach (@project_dir) {
			my ($vol, $dir, $final_dir) = File::Spec->splitpath($_);
			$project_column->{$final_dir} = "$_/*/*";
		}
	}
	
	my $dataset_column = {ColumnName => "Dataset"};
	foreach (@dataset_dir) {
		my ($vol, $dir, $final_dir) = File::Spec->splitpath($_);
		$dataset_column->{$final_dir} = "$_/*";
	}
	my $result;
	if (not $short) {
		$result = OME::Util::Annotate::SpreadsheetWriter->processFile($file, $dataset_column, $project_column);
	} else {
		$result = OME::Util::Annotate::SpreadsheetWriter->processFile($file, $dataset_column);	
	}
	
	print STDERR "tsv spreadsheet wasn't written. The directory structure under the specified root is incorrect.\n" unless ($result);
}
sub pdi_wizard_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This command examines a directory structure to associate images with datasets and
and projects. A tsv spreadsheet is written that can be parsed by OME using
e.g. the command-line tool "ome annotate spreadsheet".

All directories one level under the root directory become projects. All
directories two levels under the root become datasets and their files the 
images. N.B: The previous rules are superseded in so far as no empty projects or
datasets will be created. 

E.G:
	Suppose the file structure is:
	/
	/Proj1/
	/Proj2/
	/Proj2/Dataset1/
	/Proj2/Dataset2/
	/Proj2/Dataset2/ImageA
	/Proj2/Dataset2/ImageB
	/Proj2/Dataset2/etc/
	/Proj2/Dataset2/etc/funny
	/Proj3/Dataset3
	
If the root is pointed at / then the Project-Dataset-Image heirarchy will be:
	Proj2
	 \\_ Dataset 2
	    \\_ ImageA
	    \\_ ImageB
	    
if the command is called with the -s parameter and the root is pointed at /Proj2
then the Dataset-Image heirarchy will be:
	 
	 Dataset 2
	  \\_ ImageA
	  \\_ ImageB
	    
Options:
	 -f, --file
	 The name of the tsv spreadsheet that will be written.
	 
	 -s, --short
	 This signifies that the root points to the Dataset-Image heirarchy.
	 
	 -r, --root
	 Path to the root directory.
	 
	 -x, --exclude
	 Ignore the specified root subdirectories.
	 
USAGE
    CORE::exit(1);
}


sub cgc_wizard {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    my ($file, $root, $short, @exclude_dir);
	GetOptions('f|file=s'  => \$file,
   			   'r|root=s'  => \$root,
   			   's|short'   => \$short,
   			   'x|exclude=s' => \@exclude_dir);
   	@exclude_dir = split(/,/,join(',',@exclude_dir));

   	$self->cgc_wizard_help($commands) unless (defined $file and defined $root);
	die "root parameter is not a directory" if (not -d $root);
	$root = rel2abs($root);
	
	foreach (@exclude_dir) {
		die "exclude parameter: $_ is not a directory\n"
			unless (-d $_);
#		die "exclude parameter: $_ is not a sub-directory of root\n"
#			unless (path_in_tree(rel2abs($root), rel2abs($_)));
	}
	
	# Get CategoryGroups
	my @cg_dir;
	if (not $short) {
		# iterate through the subdirectories, excluding '.' and '..'
		foreach my $dir (scan_dir($root, sub{ (!/^\.{1,2}$/) && ( -d "$root/$_" ) })) {
			$dir = rel2abs($dir);

			my $skip;
			foreach (@exclude_dir) {
				$skip = 1 if ($dir eq rel2abs($_))
			}
			next if $skip;
			push (@cg_dir, $dir);
		}
	} else {
		my $skip;
		foreach $_ (@exclude_dir) {
			$skip = 1 if rel2abs($root) eq rel2abs($_);
		}
		$cg_dir[0] = $root unless $skip;
	}
	
	my @cg_columns;
	foreach my $categoryGroupDirectory (@cg_dir) {
		# get Categories for this CategoryGroup
		my @category_dir_list = scan_dir($categoryGroupDirectory, sub{ (!/^\.{1,2}$/) && ( -d "$categoryGroupDirectory/$_" ) });
		# make the hash
		my ($vol, $dir, $final_dir) = File::Spec->splitpath($categoryGroupDirectory);
		print STDERR "ColumnName => $final_dir\n";
		my $cg_column = {ColumnName => "$final_dir"};		
		foreach my $category_dir (@category_dir_list) {
			($vol, $dir, $final_dir) = File::Spec->splitpath($category_dir);
			print STDERR "\t$final_dir => $category_dir/*\n";
			$cg_column->{$final_dir} = "$category_dir/*";
		}
		push (@cg_columns, $cg_column);
	}

	my $result = OME::Util::Annotate::SpreadsheetWriter->processFile($file, @cg_columns);
	
	print STDERR "tsv spreadsheet wasn't written. The directory structure under the specified root is incorrect.\n" unless ($result);
}
sub cgc_wizard_help {
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This command examines a directory structure to associate images with CategoryGroups and
and Categories. A tsv spreadsheet is written that can be parsed by OME using
e.g. the command-line tool "ome annotate spreadsheet".

All directories one level under the root directory become CategoryGroups. All
directories two levels under the root become Categories and their files the 
images. N.B: The previous rules are superseded in so far as no empty Categories or
CategoryGroups will be created. 

E.G:
	Suppose the file structure is:
	/
	/TestImages/
	/Worms/Day1/
	/Worms/Day2/
	/Worms/Day3/ImageA
	/Worms/Day3/ImageB
	/Worms/Day3/etc/
	/Worms/Day3/etc/README
	/Worms/Day4
	
If the root is pointed at / then the CategoryGroup-Category-Image heirarchy will be:

	Worms
	 \\_ Day 3
	    \\_ ImageA
	    \\_ ImageB
	    
the same heirarchy will be constructed if the -s flag is used and the root is
pointed at /Worms

Options:
	 -f, --file
	 The name of the tsv spreadsheet that will be written.
	 
	 -s, --short
	 This signifies that the root directory name is used to form the CategoryGroup.
	 
	 -r, --root
	 Path to the root directory.
	 
	 -x, --exclude
	 Ignore the specified root subdirectories.
USAGE
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

