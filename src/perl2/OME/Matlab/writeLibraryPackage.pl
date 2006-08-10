#!/usr/bin/perl

# Use this script to automatically generate the necessary Perl packages for each 
# library.

# Usage:
# perl writeLibraryPackage.pl libName relative/or/absolute/path/to/library
use OME::Install::Environment;
use Cwd;
use File::Path;
use strict;

die "Usage: perl writeLibraryPackage.pl libName relative/or/absolute/path/to/library\n"
	unless ( @ARGV );

my $environment = initialize OME::Install::Environment;
my $ome_lib_root = $environment->base_dir().'/lib';

my ( $packageName, $path ) = ( @ARGV );

my $src_dir = getcwd()."/Lib/";

# This will be used when we integrate the script into the installer, in lieu of
# the line above
#my $src_dir = getcwd()."/src/perl2/OME/Matlab/Lib/";

mkpath($src_dir, 0, 02775) unless ( -d $src_dir);

# Regular expression magic to ensure proper library names and paths
$packageName = $1 if $packageName =~ m/^lib(\S+)OME$/;
my $libName = $packageName.'OME';

# If you have a relative path, add the ome_lib_root to the beginning
my $full_path = $path;
$full_path = $ome_lib_root."/matlab_compiled/".$path unless ( $path =~ m/^(\/\S+)+/ );

my $file = $full_path."/lib$libName\_mcc_component_data.c";
print "The file is $file\n";

# TODO: Figure this out dynamically, as it will be different once we have the
# full compiler
my $include_dir = "/Applications/MATLAB72/extern/include";

# Now, write the package!
open FILE, "< $file"  or die "Cannot open file: $file\n";
open PACKAGE, "> $src_dir\/$packageName.pm" or die "Cannot create file $packageName in directory $src_dir\n";

print PACKAGE "# This file was automatically generated using a script.\n\n";

print PACKAGE "package OME::Matlab::Lib::$packageName;
use strict;
use warnings;
use Carp;

use base qw(OME::Matlab::Compiled);

my \$CACHE_DIRECTORY;
my \$full_path;

BEGIN {
	# This gets reset if you specify a relative path - this value is only used when
	# you specify an absolute path.
	\$full_path = \"$full_path\";

	use OME::Install::Environment;
	my \$environment = initialize OME::Install::Environment;
	if (\$environment and \$environment->base_dir()) {
		\$CACHE_DIRECTORY = \$environment->base_dir().'/Inline';
	} else {
		croak \"OME::Matlab::Lib::$packageName was loaded without an OME installation environment!\";
	}
	if (not -d \$CACHE_DIRECTORY) {
		mkpath \$CACHE_DIRECTORY
			or croak \"Could not create cache directory for OME::Matlab::Lib::$packageName\";
	}

";

 # If we have a relative path, get the ome lib root in the package itself
unless ( $path =~ m/^(\/\S+)+/ ) {
	print PACKAGE "	my \$ome_lib_root = \$environment->base_dir().'/lib';
	\$full_path = \$ome_lib_root.\"/matlab_compiled/$path\";
";
}

print PACKAGE "}
# Changing the directory to the location of the ctf archive is an alternative
# to setting dyld_library_path.
die \"couldn't change directory\" 
unless chdir( \$full_path );

use Inline ( Config => DIRECTORY => \$CACHE_DIRECTORY );

use Inline (
	C       => 'DATA',
	INC		  => \"-I$include_dir\",
	LIBS	  => [\"-L\$full_path -l$libName\"],
);

Inline->init;

sub new {
	shift->SUPER::new();
}

1;

__DATA__

__C__

";

my @contents = <FILE>;
foreach my $line ( @contents ) {
	print PACKAGE "$line";
}
print PACKAGE "SV *getComponentData(char* class) {
	SV *obj_ref = newSV(0);
	SV *obj = sv_setref_pv(obj_ref, NULL, (void*) &__MCC_lib$libName\_component_data);
	return obj;
}";

close FILE;
close PACKAGE;