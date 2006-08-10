# OME/Install/MatlabTask.pm
# This task builds and installs the OME-MATLAB framework

#-------------------------------------------------------------------------------
#
# Copyright (C) 2006 Open Microscopy Environment
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

package OME::Install::MatlabTask;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use Carp;
use English;
use Term::ANSIColor qw(:constants);
use File::Path;
use File::Basename;
use Cwd;

use OME::Install::Util;
use OME::Install::Environment;
use OME::Util::cURL;
use base qw(OME::Install::InstallationTask);


#*********
#********* GLOBALS AND DEFINES
#*********

# Default package repository
my $REPOSITORY = "http://openmicroscopy.org/packages/perl";

# Default ranlib command
my $RANLIB= "ranlib";

# Global logfile filehandle and name
my $LOGFILE_NAME = "MatlabTask.log";
my $LOGFILE;

# Our basedirs and user which we grab from the environment
my ($OME_BASE_DIR, $OME_TMP_DIR, $OME_USER, $APACHE_USER);
my ($MATLAB, $APACHE);

# OME user information
my ($OME_UID, $OME_GID);

# Installation home
my $INSTALL_HOME;

sub execute {
	# This is eval'ed because it contains a dependency on Term::ReadKey which
	# May not be resolved for other parts of the installer, but is required
	# at this point.
    eval "use OME::Install::Terminal";
    croak "Errors loading module: $@\n" if $@;

	my $retval;
	
	# Our OME::Install::Environment
    my $environment = initialize OME::Install::Environment;

    # Set our globals
    $OME_BASE_DIR = $environment->base_dir()
		or croak "Unable to retrieve OME_BASE_DIR!";
    $OME_TMP_DIR = $environment->tmp_dir()
		or croak "Unable to retrieve OME_TMP_DIR!";
    $OME_USER = $environment->user()
		or croak "Unable to retrieve OME_USER!";
	$APACHE_USER  = $environment->apache_user()
		or croak "Apache user is not set!\n";
	$APACHE = $environment->apache_conf();

    # Store our IWD so we can get back to it later
    my $iwd = getcwd ();

    # Retrieve some user info from the password database
    $OME_UID = getpwnam($OME_USER) or croak "Failure retrieving user id for \"$OME_USER\", $!";

    # Set our installation home
    $INSTALL_HOME = "$OME_TMP_DIR/install";
    
	#
	# MATLAB PERL MODULES
	#
	my $MATLAB_CONF_DEF = {
		INSTALL     => 0,
		USER        => undef,
		MATLAB_INST => undef,
		EXEC => undef,
		EXEC_FLAGS => undef,
		AS_DEV      => 0,
		MATLAB_SRC  => undef,		
	};
	$MATLAB = defined $environment->matlab_conf()  ? $environment->matlab_conf()  : $MATLAB_CONF_DEF;
	
	print "\n";
	print_header ("Optional OME-MATLAB Setup");
	print "(All verbose information logged in $INSTALL_HOME/$LOGFILE_NAME)\n\n";

    # Get our logfile and open it for reading
    open ($LOGFILE, ">", "$INSTALL_HOME/$LOGFILE_NAME")
		or croak "Unable to open logfile \"$INSTALL_HOME/$LOGFILE_NAME\".$!";

	# Confirm all flag
	my $confirm_all;
	
	while (1) {
		if ($environment->get_flag("UPDATE") or $confirm_all) {
		
			if ( $MATLAB->{INSTALL} ) {
				print "Testing MATLAB configuration \n";
				
				# Change the MATLAB_SRC path always to the current directory
				# if the dev configuration option is elected
				if ( $MATLAB->{AS_DEV} == 1) {				
					print " \\_ Checking if path to MATLAB .m files is stale ";

					if ($MATLAB->{MATLAB_SRC} eq getcwd ()."/src/matlab") {
						print BOLD, "[SUCCESS]", RESET, ".\n";
					} else {
						print BOLD, "[FAILURE]", RESET, ".\n";
						print "Path was stale. Reset ".$MATLAB->{MATLAB_SRC}." to ".getcwd ()."/src/matlab \n";
						print $LOGFILE "Path was stale. Reset".$MATLAB->{MATLAB_SRC}." to ".getcwd ()."/src/matlab \n";
						
						$MATLAB->{MATLAB_SRC} = getcwd ()."/src/matlab";
					}
				}
				
				
				# Required for people updating from 2.4.0 where MATLAB_EXEC and MATLAB_EXEC_FLAGS were added
				if (!$MATLAB->{EXEC}) {
					# MATLAB_EXEC, path to binary wasn't defined so default was set
					$MATLAB->{EXEC} = normalize_path(resolve_sym_links($MATLAB->{MATLAB_INST}))."/bin/matlab";	
					print $LOGFILE "MATLAB_EXEC, path to binary wasn't defined so it was set to default".
						$MATLAB->{EXEC}."\n";
				}
				if (!$MATLAB->{EXEC_FLAGS}) {					
					$MATLAB->{EXEC_FLAGS} = "-nodisplay -nojvm";
					print $LOGFILE "MATLAB_EXEC_FLAGS, flags to use when calling MATLAB weren't defined so setting".
							"to default".$MATLAB->{EXEC_FLAGS}."\n";
				}
				
				# try to run matlab as the specified user. if the specified user
				# is not licensed to run matlab, parse the license file to guess
				# a licensed user
				print " \\_ Checking if user $MATLAB->{USER} is licensed to run $MATLAB->{EXEC} ";
				print $LOGFILE "Checking if user $MATLAB->{USER} is licensed to run $MATLAB->{EXEC} ... \n ";
				
				my $script_path = write_matlab_test_script();
				my $script_output = try_to_run_matlab ($script_path);
				print "\n"; # spacing
			}
			
			# Ask user to confirm his/her original entries
			print BOLD,"MATLAB Perl API configuration:\n",RESET;
			print " Install MATLAB Perl API?: ", BOLD, $MATLAB->{INSTALL} ? 'yes':'no', RESET, "\n";
			print "              MATLAB User: ", BOLD, $MATLAB->{USER}, RESET, "\n"                if $MATLAB->{INSTALL};
			print "              MATLAB Path: ", BOLD, $MATLAB->{MATLAB_INST}, RESET, "\n"         if $MATLAB->{INSTALL};
			print "              MATLAB Exec: ", BOLD, $MATLAB->{EXEC}, RESET, "\n"                if $MATLAB->{INSTALL};
			print "        MATLAB Exec Flags: ", BOLD, $MATLAB->{EXEC_FLAGS}, RESET, "\n"          if $MATLAB->{INSTALL};
			print "   Config MATLAB for dev?: ", BOLD, $MATLAB->{AS_DEV} ? 'yes':'no', RESET, "\n" if $MATLAB->{INSTALL};
			print "     MATLAB .m files Path: ", BOLD, $MATLAB->{MATLAB_SRC},  RESET, "\n"         if $MATLAB->{INSTALL};
			print "\n";  # Spacing

			y_or_n ("Are these values correct ?",'y') and last;
		}
		
		if (y_or_n ("Install analysis engine interface to MATLAB ?")) {
			$MATLAB->{INSTALL} = 1;
			
			if ($environment->admin_user()) {
				$MATLAB->{USER} = $environment->admin_user();
			} elsif ($environment->user()) {
				$MATLAB->{USER} = $environment->user();
			} else {
				$MATLAB->{USER} = "matlab";			
			}
			$MATLAB->{USER}  = confirm_default ("The user which MATLAB should be run under", $MATLAB->{USER});
			if ($MATLAB->{USER} eq $APACHE_USER) {
				print " -- Apache user is the MATLAB licensed user -- \n";
			}
			
			if (! $MATLAB->{MATLAB_INST}) {
				$MATLAB->{MATLAB_INST} = normalize_path(resolve_sym_links(which('matlab')));
				$MATLAB->{MATLAB_INST} =~ s|/bin/matlab$||;
			}
			$MATLAB->{MATLAB_INST} = confirm_path ("Path to MATLAB installation", $MATLAB->{MATLAB_INST});
			
			if (! $MATLAB->{EXEC}) {
				$MATLAB->{EXEC} = $MATLAB->{MATLAB_INST}."/bin/matlab";
			}
			$MATLAB->{EXEC} = confirm_path ("Path to MATLAB binary", $MATLAB->{EXEC});

			if (! $MATLAB->{EXEC_FLAGS}) {
				$MATLAB->{EXEC_FLAGS} = "-nodisplay -nojvm";
			}
			$MATLAB->{EXEC_FLAGS} = confirm_path ("Flags to use when calling MATLAB", $MATLAB->{EXEC_FLAGS});

			if (y_or_n ("Configure MATLAB Perl API for developers?")){
				$MATLAB->{AS_DEV} = 1;
				$MATLAB->{MATLAB_SRC} = getcwd ()."/src/matlab";
			} else {
				$MATLAB->{AS_DEV} = 0;
				$MATLAB->{MATLAB_SRC} = "$OME_BASE_DIR/matlab";
			}
			$MATLAB->{MATLAB_SRC} = confirm_path ("Path to OME's matlab src files", $MATLAB->{MATLAB_SRC} );
		} else {
			$MATLAB->{INSTALL} = 0;
		}
		print "\n";  # Spacing
		$confirm_all = 1;
	}
	
	if ($MATLAB->{INSTALL}) {
		# try to run matlab as the specified user. if the specified user
		# is not licensed to run matlab, parse the license file to guess
		# a licensed user
		print " \\_ Double checking if user $MATLAB->{USER} is licensed to run $MATLAB->{EXEC} ";
		print $LOGFILE "Checking, [SECOND TEST], if user $MATLAB->{USER} is licensed to run $MATLAB->{EXEC} ... ";
		
		my $script_path = write_matlab_test_script();
		my $script_output = try_to_run_matlab ($script_path);

		print " \\_ Gathering information about your MATLAB installation\n";
		print $LOGFILE "Gathering information about your MATLAB installation\n";

		my %MATLAB_INFO = matlab_info ($script_output);

		print $LOGFILE "Matlab Vers: ",$MATLAB_INFO{"VERS"},"\n";
		print $LOGFILE "Matlab Arch: ", $MATLAB_INFO{"ARCH"}, "\n";
		print $LOGFILE "Matlab Root: ", $MATLAB_INFO{"ROOT"}, "\n";
		print $LOGFILE "Include: ", $MATLAB_INFO{"INCLUDE"}, "\n";
		print $LOGFILE "Lib:     ", $MATLAB_INFO{"LIB"}, "\n\n";

		print "Matlab Vers: ", BOLD, $MATLAB_INFO{"VERS"}, RESET, "\n";
		print "Matlab Arch: ", BOLD, $MATLAB_INFO{"ARCH"}, RESET, "\n";
		print "Matlab Root: ", BOLD, $MATLAB_INFO{"ROOT"}, RESET, "\n";
		print "Include: ", BOLD, $MATLAB_INFO{"INCLUDE"}, RESET, "\n";
		print "Lib:     ", BOLD, $MATLAB_INFO{"LIB"}, RESET, "\n\n";
	
		print "Installing MATLAB Perl API \n";
		
		# Copy the necessary libraries to the root OME directory so we can
		# modify them without messing with MATLAB
		# N.B. This works only on Matlab version 7+
		my $matlab_lib_src = $MATLAB_INFO{"ROOT"}."/bin/".$MATLAB_INFO{"ARCH"};
		my $matlab_lib_dir = $MATLAB_INFO{"LIB"};
		my $target_dir = $1 if $matlab_lib_dir =~ m/-L(\S+)/;
		print $LOGFILE "target dir is $target_dir\n";
		print $LOGFILE "matlab lib src is $matlab_lib_src\n";
		
		# Make sure we are not copying to the same directory - this will ensure the
		# patching does not occur to the libraries themselves. Then, patch the paths in them
		# before we run all that 'make' stuff - but this patching only works so
		# far on Mac OS X, and not on Linux. However, the library problem
		# may not exist on Linux.
		
		if ($target_dir ne $matlab_lib_src && $MATLAB_INFO{"ARCH"} eq 'mac') {
			print "  \\_ Copying Libraries ";
			
			# Makes the target directory if it doesn't exist
			# and does the copy.
			# Dies in OME::Install::Util if there's a problem
			
			mkpath($target_dir, 0, 02755) unless ( -d $target_dir);			
			copy_dir( $matlab_lib_src, $target_dir );
			print $LOGFILE "Copying matlab libraries...\n";
			print BOLD, "[SUCCESS]", RESET, ".\n";
			
			# Patch!
			print "  \\_ Patching Libraries ";
			print $LOGFILE "Patching matlab libraries...\n";
			my @libs_to_patch = get_file_list( $target_dir );
			$retval = patch_matlab_dylibs ( $target_dir, \@libs_to_patch );
			if ( scalar(@$retval) > 0 ) {
				print $LOGFILE "Errors:\n";
				print $LOGFILE join("\n\t", @$retval)."\n";
				print BOLD, "[FAILURE]", RESET, ".\n"
					and croak "Error patching matlab libraries, see $LOGFILE_NAME for details."
			}
			
			print BOLD, "[SUCCESS]", RESET, ".\n";
			print $LOGFILE "\tNo Errors\n\n";
		}
		
		# Configure 
		print "  \\_ Configuring ";
		
		$retval = configure_module("src/perl2/OME/Matlab/", $LOGFILE, 
			{options => '-include="'.$MATLAB_INFO{"INCLUDE"}.'" -lib="'.$MATLAB_INFO{"LIB"}.'"' });
			
		print BOLD, "[FAILURE]", RESET, ".\n"
			and croak "Unable to configure module, see $LOGFILE_NAME for details."
			unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";

		# Compile
		print "  \\_ Compiling ";
		$retval = compile_module ("src/perl2/OME/Matlab/", $LOGFILE);
	
		print BOLD, "[FAILURE]", RESET, ".\n"
			and croak "Unable to compile module, see $LOGFILE_NAME for details."
			unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";

		# Testing
		print "  \\_ Testing ";

		if ($MATLAB->{USER} eq $APACHE_USER) {
			print $LOGFILE  "Skipping MATLAB-Perl Test beacuse of Apache User \n";
			print BOLD, "[SKIPPING]", RESET, ".\n";
		} else {
			my $copy_path = which('cp');
			foreach (`$copy_path -pr src/perl2/OME/Matlab $OME_TMP_DIR/install 2>&1`) {
				croak "Couldn't copy src/perl2/OME/Matlab for testing to $OME_TMP_DIR/install : $_";
			}
			
			# prepare ENV variables
			my $matlab_lib_path = $MATLAB_INFO{"LIB"};
			$matlab_lib_path = $1
				if ($matlab_lib_path =~ m/-L(\S+)/ );
			
			my $env_str;
			if ($MATLAB_INFO{"ARCH"} eq "mac") {
				$env_str = "PERL_DL_NONLAZY=1 DYLD_LIBRARY_PATH=$matlab_lib_path";
			} else {
				$env_str = "PERL_DL_NONLAZY=1 LD_LIBRARY_PATH=$matlab_lib_path";
			}
			my $iwd = getcwd();
			chdir("$OME_TMP_DIR/install/Matlab/");
			my @outputs = `su $MATLAB->{USER} -c '$env_str perl -Iblib/lib -Iblib/arch test.pl "$MATLAB->{EXEC}" "$MATLAB->{EXEC_FLAGS}"'`;
			print $LOGFILE "su $MATLAB->{USER} -c '$env_str perl -Iblib/lib -Iblib/arch test.pl \"$MATLAB->{EXEC}\" \"$MATLAB->{EXEC_FLAGS}\"'\n";
			
			chdir($iwd);
			
			if ($? != 0) {
				print BOLD, "[FAILURE]", RESET, ".\n";
				print $LOGFILE "FAILURE -- OUTPUT: \n\"@outputs\"\n\n"
					and croak "Tests failed, see $LOGFILE_NAME for details."
			} else {
				print BOLD, "[SUCCESS]", RESET, ".\n";
				print $LOGFILE  "SUCCESS -- OUTPUT: \n\"@outputs\"\n\n";
			}
			rmtree("$OME_TMP_DIR/install/Matlab"); # problems here result in croaks
		}
		
		# Install
		print "  \\_ Installing ";
		euid(0);
		$retval = install_module ("src/perl2/OME/Matlab/", $LOGFILE);

		print BOLD, "[FAILURE]", RESET, ".\n"
			and croak "Unable to install module, see $LOGFILE_NAME for details."
			unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";
		
		#
		# OMEIS MATLAB Interface
		#
		print "Installing MEX Interface to omeis-http\n";
		
		# Configure
		print "  \\_ Configuring omeis-http with MATLAB bindings ";
		$retval = configure_module ("src/C/omeis-http", $LOGFILE,
			{options => "--with-matlab ".
						"--with-matlab-include=$MATLAB_INFO{'INCLUDE'}"});
		
		print BOLD, "[FAILURE]", RESET, ".\n"
		and croak "Unable to configure omeis-http, see $LOGFILE_NAME for details."
		unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";
		
		# Compile
		print "  \\_ Compiling omeis-http with MATLAB bindings ";
		$retval = compile_module ("src/C/omeis-http", $LOGFILE);
		
		print BOLD, "[FAILURE]", RESET, ".\n"
		and croak "Unable to compile omeis-http, see $LOGFILE_NAME for details."
		unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";
		
		#
		# OME MATLAB .m files
		#
		print "Installing OME MATLAB .m files \n";
		
		# Compile
		print "  \\_ Compiling MEX files ";
		
		$retval = compile_module ("src/matlab/", $LOGFILE);
		
		print BOLD, "[FAILURE]", RESET, ".\n"
			and croak "Unable to compile MATLAB .m files, see $LOGFILE_NAME for details."
			unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";
		
		# Installing
		print "  \\_ Installing ";
		print $LOGFILE "Copying Matlab source files from ".cwd()."/src/matlab to $OME_BASE_DIR/matlab \n"; 
		copy_tree("src/matlab", "$OME_BASE_DIR", sub{!/CVS$/i});
		$retval = 1; # if there was a problem in copy_tree, it would have
					 # croaked and died.
		print BOLD, "[FAILURE]", RESET, ".\n"
			and croak "Unable to install MATLAB .m files, see $LOGFILE_NAME for details."
			unless $retval;
		print BOLD, "[SUCCESS]", RESET, ".\n";			
	}
	$environment->matlab_conf($MATLAB);
	return 1;
}

sub try_to_run_matlab {
	my $script_path = shift;
	
	if ($MATLAB->{USER} eq $APACHE_USER) {
		return try_to_run_matlab_as_apache ($script_path);
	}
	
	print $LOGFILE "trying to run $script_path via command line ... ";
	my @outputs = `su $MATLAB->{USER} -c 'perl $script_path'`;
	
	my $matlab_ran;
	foreach (@outputs) {
		$matlab_ran = 1 if $_ =~ /\s*< M A T L A B >\s*/;
	}
	
	if ($matlab_ran) {
		print BOLD, "[SUCCESS]", RESET, ".\n";
		print $LOGFILE "[SUCCESS] \n Output From Matlab: '@outputs'";
	} else {
		print BOLD, "[FAILURE]", RESET, ".\n";
		print $LOGFILE "[FAILURE] \n Output From Matlab: '@outputs'";
		
		print "MATLAB won't start. $MATLAB->{USER} is probably not licensed to run MATLAB.\n";
		
		read_matlab_license_file_to_guess_matlab_user();
	}
	return "@outputs";
}

sub try_to_run_matlab_as_apache {
	my $script_path = shift;

	print $LOGFILE "trying to run $script_path as Apache via http\n";
	
	# Run the test script as a cgi
	my $url = 'http://localhost/perl2/matlab_test_script.pl';
	print $LOGFILE "Getting response from $url\n";
	my $curl = OME::Util::cURL->new ();
	my $response = $curl->GET($url);
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "matlab-apache-test Did not get a response from $url.\n" and
		croak "Did not get a response from $url.\n".
			  "See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $response;

	print $LOGFILE "Checking response from $url\n";
	print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "matlab-apache-test  Got an error response from $url:\n".
			"$response\n" and
		croak "Got an error response from $url:\n".
			"$response\n".
			"See $OME_TMP_DIR/install/$LOGFILE_NAME for more details."
	unless $curl->status == 200;

	print $LOGFILE "Parsing response from $url\n";
	
	if ($response =~ /\s*< M A T L A B >\s*/) {
		print BOLD, "[SUCCESS]", RESET, ".\n";
		print $LOGFILE "[SUCCESS] \n Output From Matlab: $response";
	} else {
		print BOLD, "[FAILURE]", RESET, ".\n";
		print $LOGFILE "[FAILURE] \n Output From Matlab: $response";
		
		print "MATLAB won't start. $MATLAB->{USER} is probably not licensed to run MATLAB.\n";
		
		read_matlab_license_file_to_guess_matlab_user();
	}
	print "\n"; # spacing
	return $response;
}

sub write_matlab_test_script {
	# create a matlab test script and write it to the proper place
	my $script = matlab_test_script_text();
	print $LOGFILE "Generated MATLAB test script:\n>>$script<<\n";
	
	my $script_path = $OME_BASE_DIR.'/perl2/matlab_test_script.pl';
	$script_path = 'src/perl2/matlab_test_script.pl' if $APACHE->{DEV_CONF};
	print $LOGFILE "Writing script to $script_path\n";
	
	# Write the test script into the proper place
	open(FILE, ">", $script_path) or 
		print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Can't open $script_path for writing: $!\n" and
		croak "Can't open $script_path for writing: $!";
	
	print FILE $script;
	close (FILE);
	chmod (0755,$script_path) or
		print BOLD, "[FAILURE]", RESET, ".\n" and
		print $LOGFILE "Could not chmod $script_path: $!\n" and
		croak "Could not chmod $script_path: $!";
	
	return $script_path;
}

sub matlab_test_script_text {
	my $script_start = <<'SCRIPT_START';
#!/usr/bin/perl -w
use strict;
use CGI qw/-no_xhtml/;

my $CGI = CGI->new();
print $CGI->header(-type => 'text/plain'),
SCRIPT_START
	my $script_middle = "\n".
						"my \$MATLAB_EXEC = '$MATLAB->{EXEC}'; \n".
						"my \$MATLAB_EXEC_FLAGS = '$MATLAB->{EXEC_FLAGS}'; \n".
						"\n";

	my $script_end = <<'SCRIPT_END';	
# try to run MATLAB
print `$MATLAB_EXEC $MATLAB_EXEC_FLAGS -r quit`;

# Display final environment variables, arguments, and other diagnostic
# information about MATLAB. MATLAB is not run
print `$MATLAB_EXEC $MATLAB_EXEC_FLAGS -n`;

1;

SCRIPT_END

	return $script_start.$script_middle.$script_end;
}

sub read_matlab_license_file_to_guess_matlab_user {		
	# make an educated guess
	open (MATLAB_LICENSE_FILE, "< ".$MATLAB->{MATLAB_INST}."/etc/MLM.opt") or
		print $LOGFILE "Couldn't open $MATLAB->{MATLAB_INST}"."/etc/MLM.opt for reading" and
		croak "Couldn't open $MATLAB->{MATLAB_INST}"."/etc/MLM.opt for reading";
	my @matlab_license_file = <MATLAB_LICENSE_FILE>;
	close (MATLAB_LICENSE_FILE);
	
	foreach (@matlab_license_file) {
		$_ =~ s/#.*\n//; # remove comment lines						
		$MATLAB->{USER} = $1 if $_ =~ m/USER\s*(\w*)/;
	}		
	
	print $LOGFILE "$MATLAB->{MATLAB_INST}"."/etc/MLM.opt couldn't be parsed" and
		croak "$MATLAB->{MATLAB_INST}"."/etc/MLM.opt couldn't be parsed"
		unless $MATLAB->{USER} ne '';	
	print "According to MLM.opt, $MATLAB->{USER} is a licensed MATLAB user. This user will now be used for OME install purposes.\n";
	print $LOGFILE "$MATLAB->{USER} is a licensed MATLAB user.\n";
	
	return;
}

sub matlab_info {
	my $script_output = shift;
	my @outputs = split (/\n/, $script_output);
	
	my ($matlab_arch, $matlab_root, $matlab_vers);
	foreach (@outputs) {
		$matlab_arch = $1 if $_ =~ /\s+ARCH\s+=\s+(.+)$/;
		$matlab_root = $1 if $_ =~ /\s+MATLAB\s+=\s(.+)$/;
		$matlab_vers = $1 if $_ =~ /^\s*Version\s*(\S+)\s+/;
	}
	die "Could not parse out matlab architecture.\n" unless $matlab_arch;
	die "Could not parse out matlab home.\n" unless $matlab_root;
	die "Could not parse out matlab version.\n" unless $matlab_vers;
	
	# Figure out the required Matlab lib and includes, this varies version to version
	# and architecture to architecture
	my ($matlab_include, $matlab_lib, $matlab_lib_cmd);
	if ($matlab_vers =~ /6\.5\.0.+/) {
		$matlab_include = "-I$matlab_root/extern/include";
		$matlab_lib = "$matlab_root/extern/lib/$matlab_arch";
		$matlab_lib_cmd = "-L$matlab_lib -lmx -leng -lut -lmat";
		$matlab_lib_cmd .= " -L$matlab_root/sys/os/mac -ldl" if $matlab_arch eq 'mac';
		
	} elsif ($matlab_vers =~ /7\.0\.0.+/ or $matlab_vers =~ /7\.0\.1.+/
		or $matlab_vers =~ /7\.0\.4.+/ or $matlab_vers =~/7\.2\.0.+/ )  {
		$matlab_include = "-I$matlab_root/extern/include";
		$matlab_lib = "$matlab_root/bin/$matlab_arch";
		$matlab_lib = "$OME_BASE_DIR/lib/matlab_".$matlab_vers if $matlab_arch eq 'mac';
		$matlab_lib_cmd = "-L$matlab_lib -lmx -leng -lut -lmat -licudata -licui18n -licuuc -lustdio -lz";		
	} else {
		print STDERR "WARNING Matlab Version $matlab_vers not supported.\n";
		# make an educated guess
		$matlab_include = "-I$matlab_root/extern/include";
		$matlab_lib = "$matlab_root/bin/$matlab_arch";
		$matlab_lib = "$OME_BASE_DIR/lib/matlab_".$matlab_vers if $matlab_arch eq 'mac';
		$matlab_lib_cmd = "-L$matlab_lib -lmx -leng -lut -lmat -licudata -licui18n -licuuc -lustdio -lz";
	}
	
	return ("ARCH"    => $matlab_arch,
			"ROOT"    => $matlab_root,
			"VERS"    => $matlab_vers,
			"INCLUDE" => $matlab_include,
			"LIB"     => $matlab_lib_cmd);
}

sub get_file_list {
	my $root_dir = shift;
	opendir( DH, $root_dir );
	my @files;
	while( defined (my $file = readdir DH )) {
		next unless $file =~ m/\S+.dylib[1-9.]*/;
		next if $file =~ m/\S+.csf/;
		my $full_path = $root_dir."/".$file;
		push @files, $full_path;
	}
	closedir( DH);
	return @files;
}

# Usage:
# patch_matlab_dylibs ( $preferred_path, \@files_to_patch );
# DO NOT USE THIS ON PRIMARY COPIES OF LIBRARIES. THAT WILL BREAK THINGS!!!

sub patch_matlab_dylibs {
	my $preferred_DYLD_PATH = shift;
	my $dylibs_to_patch = shift;
	my @errors;
	
	foreach my $dylib_path ( @$dylibs_to_patch ) {
		my $dylib_file_name = $dylib_path;
		$dylib_file_name =~ s/^(.*\/)?(\S+)/$2/;
		
		# Use otool to probe a dynamic library (e.g. *.dylib, *.bundle) for 
		# dependencies, then 
		my $otool_dump = `otool -L $dylib_path`;
		# Make sure we can patch this file.
		`chmod u+w $dylib_path`;
		my @dependencies = split( /\n/, $otool_dump );
		
		# The first line is just the path to the dylib file we're working on
		shift( @dependencies );	
		
		my $dependency_changed_count = 0;
		foreach my $line ( @dependencies ) {
			# First, look for dependencies with relative paths. All of these need
			# to be patched
			die "Could not parse otool output" unless( $line =~ m/^\t(\S+)/ );
			my $dependency = $1;
			# If the dependency has a relative path or an absolute path that does
			# not exist, attempt to find it in our copy of the matlab lib directory,
			# and change the reference to refer to our copy with an absolute path
			if( ( $dependency =~ m/^[^\/]/ ) || 
			    ( ! -e $dependency ) ) {
				# Remove all leading directories from the path string, retaining
				# only the file name.
				my $referenced_library_file_name = $dependency;
				$referenced_library_file_name =~ s/^(.*\/)?(\S+)/$2/;
				my $probable_path = $preferred_DYLD_PATH.'/'.$referenced_library_file_name;
				if( ! -e $probable_path ) {
					print $LOGFILE "cannot find $referenced_library_file_name in $preferred_DYLD_PATH.\n";
					next;
				}
				my $command = "install_name_tool -change $dependency $probable_path $dylib_path";
				# The first dependency is the ID of the dylib file - we need to execute a 
				# different command on this one to change it.
				$command = "install_name_tool -id $probable_path $dylib_path"
					if( $referenced_library_file_name =~ m/^$dylib_file_name((\.\d+)+)?$/);
				
				my $return_value = `$command`;
				if( $return_value ) {
					push (@errors, "ERROR from command:\n$command\nERROR MSG:\n$return_value\n");
					next;
				} else {
					$dependency_changed_count++;
				}
			} 
		}
	
	
		# Change the file back to write-protected
		`chmod u-w $dylib_path`;
		
		print $LOGFILE "\tChanged $dependency_changed_count dependencies in $dylib_path.\n";
	}
	return \@errors;
}

sub rollback {
    croak "Rollback!\n";

    # Stub for the moment.
    return 1;
}

1;
