# OME/Install/Terminal.pm
# This package exports the terminal functionality used in the OME::Install framework.

# Copyright (C) 2003 Open Microscopy Environment
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package OME::Install::Terminal;


#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use Carp;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;

require Exporter;

#*********
#********* GLOBALS AND DEFINES
#*********

our @ISA = qw(print_header confirm_default);
our @EXPORT = qw(blarg);

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

sub confirm_default {
    my ($text, $default) = @_; 

    while (1) {
	print "$text ", BOLD, "[$default]", RESET, ": ";
	my $input = ReadLine 0;
	chomp $input;
	($input = $default) unless $input;
	# Rip trailing slash
	if ($input =~ /^(.*)\/$/) { $input = $1 }

	print "Using \"$input\", are you sure ? ", BOLD, "[y/n]", RESET, ": ";
	my $y_or_n = ReadLine 0;
	chomp $y_or_n;

	if (lc($y_or_n) eq "y") { return $input };
    }
}
