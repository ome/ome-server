#!/usr/bin/perl

# A script used to compile the Inline C for the dynamic library perl packages.
# Must be compiled before running a chain, or else it won't be compiled properly
# in the Matlab Handler - handler will fail and revert to engine.

use strict;

my %_matlab_instances;

# Will compile the default libraries, unless the user specifies which libraries to compile
my @packageNames = ( 'Classifier', 'Filters', 'Maths', 'Segmentation', 'Statistics', 'Transforms', 'Utility' );
@packageNames = ( @ARGV ) if @ARGV;

foreach my $package ( @packageNames ) {
	my $useDec = 'OME::Matlab::Lib::'.$package;
	print "Compiling $useDec\n";
	eval "use $useDec";
	print STDERR "There were problems compiling this library!\n\t$@" and next if  $@;
	my $instance = $useDec->new();
	$_matlab_instances{ $package } = $instance;
}