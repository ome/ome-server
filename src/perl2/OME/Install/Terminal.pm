# OME/Install/Terminal.pm
# This package exports the terminal functionality used in the OME::Install framework.

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

package OME::Install::Terminal;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use Carp;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
use OME::Install::Util;

require Exporter;

#*********
#********* GLOBALS AND DEFINES
#*********

our @ISA = qw(Exporter);
our @EXPORT = qw(confirm
		 confirm_path
		 print_header
		 question
		 confirm_default
		 get_password
		 y_or_n
		 whereis
		 );

#*********
#********* EXPORTED SUBROUTINES
#*********

sub print_header {
    my $header_text = shift;
    my $strlen = length($header_text) + 2;

    print BOLD;
    print "-" x $strlen, "\n";
    print " $header_text\n";
    print "-" x $strlen, "\n\n";
    print RESET;
}

sub confirm {
    my $text = shift;

    print "Using \"$text\", are you sure ? [y/", BOLD, "n", RESET, "]: ";
    my $y_or_n = ReadLine 0;
    chomp $y_or_n;

    if (lc($y_or_n) eq "y") { return 1 };

    return 0;
}

sub confirm_path {
    my ($text, $default) = @_; 

    print "$text ", BOLD, "[$default]", RESET, ": ";
    my $input = ReadLine 0;
    chomp $input;
    ($input = $default) unless $input;

    # Rip trailing slash
    if ($input =~ /^(.*)\/$/) { $input = $1 }

    return $input;
}

sub confirm_default {
    my ($text, $default) = @_; 

    print "$text ", BOLD, "[$default]", RESET, ": ";
    my $input = ReadLine 0;
    chomp $input;
    ($input = $default) unless $input;

    return $input;
}

sub question {
    my $text = shift;

    print "$text";
    my $input = ReadLine 0;
    chomp $input;

    return $input;
}

sub whereis {
    my $binary = shift;

    while (1) {
	print "Please specify the location of the \"$binary\" binary [q to quit]: ";
	my $input = ReadLine 0;
	chomp $input;
	if (lc($input) eq 'q') { return 0 }
	which ($input) and return $input or print "Unable to locate binary \"$input\", try again.\n" and next;
    }
}

sub get_password {
    my ($text, $min_len) = @_;
    my $input;

    # Lets not choke if someone doesn't pass this parameter
    $min_len = 0 unless $min_len;

    ReadMode(2);

    while (1) {
	print "$text";
	$input = ReadLine 0;
	chomp($input);
	
	print "\n";  # Spacing

	print "Verify: ";
	my $input2 = ReadLine(0);
	chomp($input2);

	print "\n";  # Spacing

	if (length ($input) < $min_len ) {
	    print "Password must be at least 6 characters long.\n" and next;
	} elsif ($input ne $input2) {
	    print "Passwords do not match. Please re-enter.\n" and next;
	}

	last;
    }

    my $salt = join('',('.','/',0..9,'A'..'Z','a'..'z')[rand 64, rand 64]);
    my $crypt = crypt($input,$salt);

    ReadMode(1);
    return ($input, $crypt);
}


sub y_or_n {
    my $text = shift;

    print "$text [y/", BOLD, "n", RESET, "]: ";
    my $y_or_n = ReadLine 0;
    chomp $y_or_n;

    if (lc($y_or_n) eq "y") { return 1 };

    return 0;
}
