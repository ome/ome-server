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
use Text::Wrap;
use OME::Install::Util;
use OME::Install::Environment;

require Exporter;

#*********
#********* GLOBALS AND DEFINES
#*********

our @ISA = qw(Exporter);
our @EXPORT = qw(confirm_path
		 print_header
		 confirm_default
		 get_password
		 y_or_n
		 multiple_choice
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

sub confirm_path {
    my ($text, $default) = @_; 

    print "$text [", BOLD, $default, RESET, "]: ";
    my $input = ReadLine 0;
    chomp $input;
    ($input = $default) unless $input;

    # Rip trailing slash
    if ($input =~ /^(.*)\/$/) { $input = $1 }
    
    # log the question and the user's selected choice
    my $environment = initialize OME::Install::Environment;
    if ($environment->tmp_dir()) {
   		my $logfileName = $environment->tmp_dir()."/install/"."UserSelectedOptions.log";
   		`touch $logfileName`;
 	   	open  (FILEOUT, ">> $logfileName") or croak "can't open $logfileName for appending: $!\n";
 	   	print FILEOUT "$text ", BOLD, "[", $input, "]\n", RESET;
 	   	close (FILEOUT);
    }
    return $input;
}

sub confirm_default {
    my ($text, $default) = @_; 

    print "$text ", BOLD, "[$default]", RESET, ": ";
    my $input = ReadLine 0;
    chomp $input;
    ($input = $default) unless $input;
    
    # log the question and the user's selected choice
    my $environment = initialize OME::Install::Environment;
    if ($environment->tmp_dir()) {
   		my $logfileName = $environment->tmp_dir()."/install/"."UserSelectedOptions.log";
   		`touch $logfileName`;
 	   	open  (FILEOUT, ">> $logfileName") or croak "can't open $logfileName for appending: $!\n";
 	   	print FILEOUT "$text ", BOLD, "[", $input, "]\n", RESET;
 	   	close (FILEOUT);
    }
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
    my $def_yorn = shift;
    my $y_or_n;
    my $environment = initialize OME::Install::Environment;
    my $retVal=1;
    
    $def_yorn = 'n' unless defined $def_yorn;
    
    return 1 if ($environment->get_flag ("ANSWER_Y"));
    
   	# keep asking the question until the user answers it properly
   	my $semaphore = 1;
   	while ($semaphore) {
		if ($def_yorn eq 'n') {
			print wrap("", "", $text), " [y/", BOLD, "n", RESET, "]: ";
		} else {
			print wrap("", "", $text), " [", BOLD, "y", RESET, "/n]: ";
		}
		
		$y_or_n = ReadLine 0;
		chomp $y_or_n;
		
		# tests whether user's input is proper
		$semaphore = 0;
		if (lc($y_or_n) eq "y") {
			$retVal = 1;
		} elsif (lc($y_or_n) eq "n") {
			$retVal = 0;
		} elsif (lc($y_or_n) eq "") {
			if ($def_yorn eq 'y'){ 
				$retVal = 1;
			} else {
				$retVal = 0;
			}
		} else{
			$semaphore = 1;
		}
	}
        
   	# log the question and the user's selected choice
    if ($environment->tmp_dir()) {
   		my $logfileName = $environment->tmp_dir()."/install/"."UserSelectedOptions.log";
   		`touch $logfileName`;
 	   	open  (FILEOUT, ">> $logfileName") or croak "can't open $logfileName for appending: $!\n";
 	   	print FILEOUT "$text";
 	   	if ($retVal eq 1) {
 	   		print FILEOUT BOLD, " [YES]\n", RESET;
 	   	} else {
	 	   	print FILEOUT BOLD, " [NO]\n", RESET;
 	   	}
 	   	close (FILEOUT);
    }
   	return $retVal;
}

sub multiple_choice {
	my $text = shift;
	my $default = shift;
	my @choices = @_;
	my $i;
	
	for ($i=0; $i < scalar @choices; $i++) {
		last if lc ($choices[$i]) eq lc ($default);
	}
	croak "multipe_choice incorrectly called\n" unless $i = scalar (@choices);

	my $environment = initialize OME::Install::Environment;
	
	while (1) {
		print wrap("","", $text," [");
		for ($i = 0; $i < scalar(@choices); $i++){
			print "/" unless ($i eq 0);
			if (lc ($choices[$i]) ne lc ($default)){
				print "$choices[$i]";
			} else {
				print BOLD, "$choices[$i]", RESET;
			}
		}
		print "]: ";
		
		my $selected_choice = ReadLine 0;
		chomp $selected_choice;
		if ($selected_choice eq "") {
			return $default;
		}

		for ($i=0; $i < scalar @choices; $i++) {
			return ($choices[$i]) if lc ($choices[$i]) eq lc ($selected_choice);
		}
   	}
}
