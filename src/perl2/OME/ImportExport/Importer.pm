#!/usr/bin/perl -w
#
# Importer.pm
# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Brian S. Hughes
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

# OME's image import class. It creates an instance of the Import-reader
# class for each image and has that instance's methods and sub-classes
# do the actual import work.
#

# ---- Public routines -------
# new()

# ---- Private routines ------
# get_base_name()
# sort_and_group()
# groupnames()

package OME::ImportExport::Importer;
use strict;
use OME::ImportExport::Import_reader;
use Carp;
use File::Basename;
use Sort::Array;
use vars qw($VERSION);
$VERSION = '1.0';

sub new {
    my @image_buf;
    my %xml_elements;      # build up DB entries in here keyed by their XML element names
    my $image_group_ref;
    my $image_file;
    my $import_reader;
    my $read_status;
    my @fn_groups;


    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance
    my $image_file_list_ref = shift;         # reference list of input files
    croak "No image file to import"
	unless $image_file_list_ref;
    my $callback = shift;     # ref. to callback routine to which results returned
    sort_and_group($image_file_list_ref, \@fn_groups);

    #foreach $image_file (@$image_file_list_ref) {
    foreach $image_group_ref (@fn_groups) {
	$image_file = $$image_group_ref[0];
	@image_buf = ();     # clear out any old images
	%xml_elements = ();  # clear out any old metadata
	#$xml_elements{'Image.Name'} = get_base_name($image_file);
	$xml_elements{'Image.Name'} = basename($image_file);
	#$import_reader = new Import_reader($image_file, \@image_buf, $project, \%xml_elements);
	$import_reader = new OME::ImportExport::Import_reader($image_group_ref, \@image_buf, \%xml_elements);
	my $fn = $import_reader->Image_reader::image_file;
	$import_reader->check_type;

	if ($import_reader->image_type eq "Unknown") {
	    carp "File $image_file has an unknown type";
	}
	else {
	    $read_status = $import_reader->readFile;
	    if ($read_status ne "") {
		print "Carping: ";
		carp $read_status;
	    }
	    else {
		print "Done with import\n";
		&$callback(\%xml_elements, \@image_buf);
	    }
	}
	$import_reader->DESTROY;
    }
}

sub get_base_name {
    my $fullnm = shift;
    my $fn;
    my @arr;

    @arr = split('/', $fullnm);  # assume Unix style filename
    $fn = $arr[$#arr];
    $fn =~ s/([\w]+).*/$1/;

    return $fn;
}



# Routine sorts the passed list of filenames,discards duplicates, and
# calls groupnames() to assemble the filenames into sibs (sibling groups).

sub sort_and_group {
    my $fns = shift;
    my $out_fns =shift;
    my @cleansed;
    
# First cleanse data by sorting input and eliminating duplicates
    @cleansed = Sort::Array::Discard_Duplicates(
						sorting      => 'ascending',
						empty_fields => 'delete',
						data         => $fns
						);
    @cleansed = reverse @cleansed;
    
# Now break filenames into sets
    groupnames(\@cleansed, $out_fns);

}

# Groups the passed set of sorted names into sets that are
# identical except for a single digit in the imputed wavelength
# field. If a filename doesn't fit into one of the name patterns
# that include a filename field, or if such a filename doesn't
# have any 'wavelength siblings', then the individual filename
# will form a group of 1.
#
# This routine will return a list composed of references to lists
# that each contain the filenames of 1 sibling group.
#
# So far, filenames are grouped only on wavelength sequences, and
# those only if the filenames have a type of ".tif".
# Input filenames will be analyzed in 1 of 3 forms: 
#   <name>_w{1,2}.tif
#   <name>_w{1,2}<more name>.tif
#   other
#
# This routine has been hardcoded for only those 3 forms. Should
# be generalized in the future.

sub groupnames {
    
    my $fns = shift;
    my $outfns = shift;
    my ($fn, $bn);
    my $matched;
    my ($pattern, $subpattern, $subp);
    my $digits = '[1-9]';
    my $fpat1 = '^(\w+_w)([1-9])(.tif+)$';
    my $fpat2 = '^(\w+_w)([1-9])(\w+)(.tif+)$';
    my $anyothers = '^(.+)$';
    my %fmts;
    my $k;
    my $i;

    
    %fmts = (fpat1 => $fpat1,
             fpat2 => $fpat2,
            );

    # if a filename matches one of the above patterns, select
    # out all the other adjacent filenames that match the same pattern.
    # Group them together, since they only vary in the '[1-9]' subfield.
    # If the original sorted filename list is reversed by the caller before
    # passing to this routine, the resulting sets of matching files will
    # be ordered from lowest to highest integer in the '[1-9]' subfield.

    while ($fn = pop @$fns) {
        $bn = basename($fn);
        $matched = 0;
        foreach $k (keys %fmts) {
            $pattern = $fmts{$k};
            if ($bn =~ m/$pattern/i) {    # found a file that matches a pattern
                $matched = 1;
                $subp = $4 ? "$3$4" : "$3";
                $subpattern = "$1$digits$subp";
                my @grp = ($fn);
                while (1) {               #    now find all similarly named files
                    if ($fn = pop @$fns) {
                        $bn = basename($fn);
                        if ($bn =~ m/$subpattern/i) {
                            push @grp, $fn;
                        }
                        else {
                            push @$fns, $fn;
                            last;
                        }
                    }
                    else {
                        last;
                    }
                }
                push @$outfns, \@grp;
            }
        }
        if ($matched == 0) {    # filename didn't match any pattern, so stick it on it's own sublist
            #push @$outfns, \($fn);
            push @$outfns, [$fn];
        }
    }

}



    
1;
