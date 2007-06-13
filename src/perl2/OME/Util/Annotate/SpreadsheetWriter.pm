# OME/Util/Annotate/SpreadsheetWriter

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

package OME::Util::Annotate::SpreadsheetWriter;

=pod

=head1 NAME

OME::Util::Annotate::SpreadsheetWriter - Package for auto-generating bulk-annotation
										spreadsheets for OME

=head1 DESCRIPTION

A package to derive Project, Dataset, Category Group, and Category annotations
from directory strucutre and write these annotations into a tsv spreadsheet.
These spreadsheets can be imported into OME by SpreadsheetReader.

=head1 METHODS

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use Carp;
use Cwd;
use File::Glob ':glob'; # for bsd_glob
use File::Spec; # for splitpath

=head2 processFile

	processFile ("tmp.tsv", $cg_age, $cg_body_part, $cg_quality);

This is a utility function that converts a set of image annotation rules
into a tsv spreadsheet. Although it is used by the OME annotation wizards to
make simple annotations, it is more powerful when used as a PERL API.

This function is intended to be used by OME users who have some experience with
PERL to do infer bulk annotations that are more complicated than the wizards
allow.

Each rule is a hash ref (e.g.  $cg_age) that corresponds to a single column of
the resulting spreadsheet. The hash must contain the key "ColumnName" which
specifies the column's name. The rest of the hash is a set of (key, value) pairs:
value is a filename (typically containing wildcards) that references a set of
files which will be assigned the column value set based on "key". You can use the
optional key "DefaultColumnValue" to insert that value for all files that don't
match any of this column's filename patterns.

If the string '_RelativePaths' is passed in as a parameter following the file 
name, and the file locations are given as relative paths, then the images will
be identified by their relative paths in the spreadsheet. This is a useful 
option if you are programatically creating a temporary directory for images
subsequent to upload, and the temporary directory name contains no useful 
information. In such a scenanario, you must be careful to import the images
using the same relative paths that you use in this call. 
See OME::Web::Wizards::ImportAndAnnotateImages for an example of this usage
scenario.

my $root = "/Users/tmacur1/Images/worms/";
my $cg_age = {
	ColumnName => "Age",
	"$root/day1/*" => "Day 1", 
	"$root/day2/*" => "Day 2", 
	"$root/day4/*" => "Day 4",
	"$root/day6/*" => "Day 6",
	"$root/day8/*" => "Day 8", 
};

my $cg_body_part = {
	ColumnName => "Body Part",
	DefaultColumnValue => "body",
	"$root/*/day*head*" => "head",
};

my $cg_quality = {
	ColumnName => "Quality",
#	DefaultColumnValue => "Average",	
	"$root/*/day*blurry*" => Blurry,
	"$root/*/day*windy*" => Windy,
};

processFile ("tmp.tsv", $cg_age, $cg_body_part, $cg_quality);

Returns 0 if a spreadsheet could not be written (because of mistaken rules)
and 1 otherwise.

=cut 


=head1 METHODS

=cut

sub processFile{
	my ($self, $fn, @classification_rules) = @_;
	my %master_hash;
	my $cg_list; # a hash ref
	my $useRelativePaths = 0;
	
	foreach my $classification_rule (@classification_rules) {
		if( $classification_rule eq '_RelativePaths' ) {
			$useRelativePaths = 1;
			next;
		}
	
		# get Category Group name
		my $cg = $classification_rule->{"ColumnName"};
		die "Input Hash needs to have a field `ColumnName`" unless $cg;
		delete $classification_rule->{'ColumnName'};

		# get Default Category name
		my $default_category;
		delete $classification_rule->{"DefaultColumnValue"}
			if ($default_category = $classification_rule->{"DefaultColumnValue"});

		$cg_list->{$cg} = $default_category;

		# for each category
		foreach my $file_pattern_rule (keys %$classification_rule) {
			foreach my $file (bsd_glob ($file_pattern_rule)) {
				next if (not -f $file); # skip directories				
#				print "`$file` `$cg` `".$classification_rule->{$file_pattern_rule}."`\n";
				$master_hash{$file}{$cg} = $classification_rule->{$file_pattern_rule};
			}
		}
	}
	
	# check the master hash size
	return 0 if (not keys %master_hash);
	
	# Use the master hash to write-out a tsv file
	open (FILEOUT, "> $fn") or die "Couldn't open $fn for writing: $!\n";
	my @array_cg_list = sort keys (%$cg_list);
	print FILEOUT "Image.FilePath\t".join ("\t", @array_cg_list)."\n";

	foreach my $file (sort keys %master_hash) {
		my $path = ( $useRelativePaths ? 
			$file :
			Cwd::realpath($file)
		);
		print FILEOUT $path."\t";

		foreach my $cg (@array_cg_list) {
			my $category = $master_hash{$file}{$cg};
			if (defined $category) {
				print FILEOUT "$category\t";
			} else {
				# $cg_list->{$cg} might be  undefined that's fine. It just means
				# that an image shouldn't be classfied in any category for that
				# category group
				if (defined $cg_list->{$cg}) {
					print FILEOUT $cg_list->{$cg}."\t";
				} else {
					print FILEOUT "\t";
				}
			}
		}
		print FILEOUT "\n";
	}

	close (FILEOUT);
	return 1;
}

__END__

=head1 AUTHOR

Tom Macura <tmacura@nih.gov>
Open Microscopy Environment, NIH

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
