#!/usr/bin/perl -w

# perlCheck.pl

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




#-------------------------------------------------------------------------------
#
# Written by:    
#
#-------------------------------------------------------------------------------


use strict;
use Config;
use Cwd;
my $cwd = getcwd;
my $libDir = $Config{installprivlib};
use File::Spec;
use Getopt::Std;

my $moduleRepository = 'http://openmicroscopy.org/packages/perl';
my $DEFAULT_badTestsFatal = 0;
my $installCommand = 'make install';
my $ranlibCommand = 'ranlib';

$ENV{PATH} .= ':/usr/local/bin';

# Add module specs here:
my @modules = ({
	Name => 'DBI',
	repositoryFile => 'DBI-1.30.tar.gz',
	checkVersion => \&DBI_VersionOK
	},{
	Name => 'Digest::MD5',
	repositoryFile => 'Digest-MD5-2.13.tar.gz'
	},{
	Name => 'MD5',
	repositoryFile => 'MD5-2.02.tar.gz'
	},{
	Name => 'MIME::Base64',
	repositoryFile => 'MIME-Base64-2.12.tar.gz'
	},{
	Name => 'Storable',
	repositoryFile => 'Storable-1.0.13.tar.gz'
	},{
	Name => 'Apache::Session',
	repositoryFile => 'Apache-Session-1.54.tar.gz'
	},{
	Name => 'Log::Agent',
	repositoryFile => 'Log-Agent-0.208.tar.gz'
	},{
	Name => 'Tie::IxHash',
	repositoryFile => 'Tie-IxHash-1.21.tar.gz'
	},{
	Name => 'Sort::Array',
	repositoryFile => 'Sort-Array-0.26.tar.gz',
	},{
	Name => 'Test::Harness',
	repositoryFile => 'Test-Harness-2.26.tar.gz',
	checkVersion => \&Test_HarnessOK,
	},{
	Name => 'Test::Simple',
	repositoryFile => 'Test-Simple-0.47.tar.gz',
	},{
	Name => 'IPC::Run',
	repositoryFile => 'IPC-Run-0.75.tar.gz',
	},{
	Name => 'DBD::Pg',
	repositoryFile => 'DBD-Pg-1.21.tar.gz',
	checkVersion => \&DBD_Pg_VersionOK,
	installModule => \&DBD_Pg_Install
	},{
	Name => 'Term::ReadKey',
	repositoryFile => 'TermReadKey-2.21.tar.gz',
	},{
	Name => 'Carp::Assert',
	repositoryFile => 'Carp-Assert-0.17.tar.gz',
	},{
	Name => 'Class::Accessor',
	repositoryFile => 'Class-Accessor-0.17.tar.gz',
	},{
	Name => 'Class::Data::Inheritable',
	repositoryFile => 'Class-Data-Inheritable-0.02.tar.gz',
	},{
	Name => 'IO::Scalar',
	repositoryFile => 'IO-stringy-2.108.tar.gz',
	},{
	Name => 'Class::Trigger',
	repositoryFile => 'Class-Trigger-0.05.tar.gz',
	},{
	Name => 'File::Temp',
	repositoryFile => 'File-Temp-0.12.tar.gz',
	},{
	Name => 'Text::CSV_XS',
	repositoryFile => 'Text-CSV_XS-0.23.tar.gz',
	},{
	Name => 'SQL::Statement',
	repositoryFile => 'SQL-Statement-1.004.tar.gz',
	},{
	Name => 'DBD::CSV',
	repositoryFile => 'DBD-CSV-0.2002.tar.gz',
	},{
	Name => 'Class::Fields',
	repositoryFile => 'Class-Fields-0.14.tar.gz',
	},{
	Name => 'Class::WhiteHole',
	repositoryFile => 'Class-WhiteHole-0.03.tar.gz',
	},{
	Name => 'Ima::DBI',
	repositoryFile => 'Ima-DBI-0.27.tar.gz',
	},{
	Name => 'Exporter::Lite',
	repositoryFile => 'Exporter-Lite-0.01.tar.gz',
	},{
	Name => 'UNIVERSAL::exports',
	repositoryFile => 'UNIVERSAL-exports-0.03.tar.gz',
	},{
	Name => 'Date::Simple',
	repositoryFile => 'Date-Simple-2.04.tar.gz',
	},{
	Name => 'Class::DBI',
	repositoryFile => 'Class-DBI-0.90.tar.gz',
	checkVersion => \&Class_DBI_VersionOK,
	},{
	Name => 'tiff',
	getVersion => \&tiffGetVersion,
	checkVersion => \&tiff_VersionOK,
	repositoryFile => '../source/tiff-v3.5.7-OSX-LZW.tar.gz',
	installModule => \&tiffInstall,
	},{
	Name => 'GD',
	repositoryFile => 'GD-1.33.tar.gz',
	},{
	Name => 'Image::Magick',
	repositoryFile => 'ImageMagick-5.5.6.tar.gz',
	installModule => \&ImageMagickInstall
	},{
	Name => 'XML::NamespaceSupport',
	repositoryFile => 'XML-NamespaceSupport-1.08.tar.gz'
	},{
	Name => 'XML::Sax',
	repositoryFile => 'XML-SAX-0.12.tar.gz',
	getVersion => \&XML_SAX_getVersion
	},{
	Name => 'bzlib',
	getVersion => \&bzlibGetVersion,
	checkVersion => \&bzlib_VersionOK,
	repositoryFile => '../source/bzip2-1.0.2.tar.gz',
	installModule => \&bzlibInstall,
	},{
	Name => 'zlib',
	getVersion => \&zlibGetVersion,
	checkVersion => \&zlib_VersionOK,
	repositoryFile => '../source/zlib-1.1.4.tar.gz',
	installModule => \&zlibInstall,
	},{
	Name => 'libxml2',
	getVersion => \&libXMLgetVersion,
	checkVersion => \&libXML_VersionOK,
	repositoryFile => '../source/libxml2-2.5.7.tar.gz',
	installModule => \&LibXMLInstall,
	},{
	Name => 'libxslt',
	getVersion => \&libXSLTgetVersion,
	checkVersion => \&libXSLT_VersionOK,
	repositoryFile => '../source/libxslt-1.0.30.tar.gz',
	installModule => \&LibXSLTInstall,
	},{
	Name => 'XML::LibXML::Common',
	repositoryFile => 'XML-LibXML-Common-0.12.tar.gz'
	},{
	Name => 'XML::LibXML',
	repositoryFile => 'XML-LibXML-1.53.tar.gz',
	},{
	Name => 'XML::LibXSLT',
	repositoryFile => 'XML-LibXSLT-1.53.tar.gz',
	}
);

#####################
# Da 'main' module:

# Grab command line options (POSIX)
my %options;
getopts('ihfcs', \%options);	# -i (Interactive) [Default]
				# -h (Help)
				# -f (Force module installs from OME repository)
				# -c (Only perform version checks)
                                # -s (Install via the sudo command)

if ($options{h}) { die "Usage: perl perlcheck.pl [OPTIONS]\nPerforms version checks and installs for OME's required libraries.\n\nMain options:\n-i,\tInteractive installation mode [default]\n-h\tHelp (This screen)\n-f\tForce module installs for missing or incompatible modules\n-c\tPerform *only* version checks (no installs are performed, even if needed)\n-f\tUse the sudo command to perform any installations\n\nReport bugs to <ome-devel\@mit.edu>." }

$installCommand = 'sudo make install'
    if ($options{s});
$ranlibCommand = 'sudo ranlib'
    if ($options{s});


# Make sure there is a modules directory, and cwd into it.
if ( -e 'modules' and not -d 'modules' ) {
	unlink ('modules') or die "Couldn't delete file 'modules': $!\n";
}

if (not -e 'modules') {
	mkdir ('modules') or die "Couldn't make a directory 'modules': $!\n";
}

chdir ('modules') or die "Couldn't change working directory to modules: $!\n";


# loop through the perl modules and install them.
foreach (@modules) {
	CheckModule ($_);
}

# chdir back to the OME perl directory
chdir ('..') or die "Couldn't change working directory to '..': $!\n";

#IGG 2/25/2003: removed this old OME 1.0 stuff.  There's now a proper Makefile.PL for OME 2.0
# Make symlinks between the private perl module directory and OME modules:
# Where to install private libs: $Config{installprivlib}
#my @OMEmodules = ('OMEpl.pm','OMEDataset.pm','OMEDataset','OMEfeature.pm','OMEwebLogin.pm');
#foreach (@OMEmodules) {
#	if (-l $libDir.'/'.$_) {
#		unlink ("$libDir/$_") or die "Could't delete '$libDir/$_': $!\n";
#	}
#	symlink ("$cwd/$_", "$libDir/$_") or die "Could't make a symbolic link to '$cwd/$_' from '$libDir/$_':  $!";
#}

print "\nInstallation of OME Perl Module dependencies is complete.\n";
print   "---------------------------------------------------------\n";

######################



######################
#  Version checks:
sub DBI_VersionOK {
my $version = shift;
	return (1) if $version == 1.35;
	return (1) if $version == 1.30;
	return (1) if $version == 1.32;
	return (0);
}

sub DBD_Pg_VersionOK {
my $version = shift;
	return (1) if $version == 0.95;
	return (1) if $version == 1.01;
	return (1) if $version == 1.20;
	return (1) if $version == 1.21;
#	return (1) if $version == 1.22; # Stability problems with new DBObject.  No longer OK.
	return (0);
}


sub Test_HarnessOK {
my $version = shift;
	return (1) if $version > 2.03;
	return (0);
}

sub Class_DBI_VersionOK {
my $version = shift;
	return (1) if $version == 0.90;
	return (0);
}

sub libXML_VersionOK {
my $version = shift;
# XML::LibXML requires 2.5.7
	return (1) if $version ge '2.5.7';
	return (0);
}

sub libXSLT_VersionOK {
my $version = shift;
# XML::LibXSLT requires 1.0.30
	return (1) if $version ge '1.0.30';
	return (0);
}

sub zlib_VersionOK {
my $version = shift;
	return (1) if $version ge '1.1.4';
	return (0);
}

sub bzlib_VersionOK {
my $version = shift;
	return (1) if $version ge '1.0';
	return (0);
}

sub tiff_VersionOK {
my $version = shift;
	return (1) if $version ge '3.5.7';
	return (0);
}


############################
# Special installation subs:
sub DBD_Pg_Install {
my $module = shift;
my (undef,$pgVersion) = split (' ',`pg_config --version`);
my $installTarBall = $module->{repositoryFile};
my $installDir = $module->{installDir};
my $error;


	die "Could not determine Postgres version using pg_config.  Are you sure the postgres development package is installed?\n" unless defined $pgVersion;
	die "Postgres version must be >= 7.1\n" unless $pgVersion ge '7.1';

	my $incDir = `pg_config --includedir`;
	$incDir =~ s/^\s+//;$incDir =~ s/\s+$//;
	$ENV{POSTGRES_INCLUDE} = $incDir unless exists $ENV{POSTGRES_INCLUDE} and defined $ENV{POSTGRES_INCLUDE};
	my $libDir = `pg_config --libdir`;
	$libDir =~ s/^\s+//;$libDir =~ s/\s+$//;
	$ENV{POSTGRES_LIB} = "$libDir -lssl" unless exists $ENV{POSTGRES_LIB} and defined $ENV{POSTGRES_LIB};
	
	if ($^O eq 'darwin') {
		print "\nranlib $libDir/libpq.a","\n";
		die "Couldn't run ranlib on $libDir/libpq.a\n" if system ($ranlibCommand." $libDir/libpq.a") != 0;
	}
	
	InstallModule ($module);
}


sub ImageMagickInstall {
my $module = shift;
my $badTestsFatal;
$badTestsFatal = $module->{badTestsFatal} if exists $module->{badTestsFatal};
$badTestsFatal = $DEFAULT_badTestsFatal unless defined $badTestsFatal;
my $installTarBall = $module->{repositoryFile};
my $installDir = $module->{installDir};
my $error;
my @configFlags = (
	'--enable-shared',
	'--without-magick-plus-plus',
	'--enable-lzw',
	'--prefix=/usr/local'
	);
my %oldENV;

	chdir $installDir or die "Couldn't change working directory to $installDir.\n";
	
	if ($^O eq 'darwin') {
		push (@configFlags,'--without-x');
		$oldENV{LDFLAGS}  = $ENV{LDFLAGS}  if exists $ENV{LDFLAGS};
		$oldENV{CFLAGS}   = $ENV{CFLAGS}   if exists $ENV{CFLAGS};   
		$oldENV{CPPFLAGS} = $ENV{CPPFLAGS} if exists $ENV{CPPFLAGS}; 
		$ENV{LDFLAGS} = '-L/usr/local/lib -L/sw/lib';
		$ENV{CFLAGS} = '-I/usr/local/include -I/sw/include';
		$ENV{CPPFLAGS} = '-I/usr/local/include -I/sw/include';
		}

	if (not -e 'Makefile' ) {
		print "\nRunning configure script...\n";
		die "Couldn't execute configure script\n" if system ('./configure '.join (' ',@configFlags) ) != 0;
	}

	if ($^O eq 'darwin') {
		$ENV{LDFLAGS}  = $oldENV{LDFLAGS}  if exists $oldENV{LDFLAGS};
		$ENV{CFLAGS}   = $oldENV{CFLAGS}   if exists $oldENV{CFLAGS};
		$ENV{CPPFLAGS} = $oldENV{CPPFLAGS} if exists $oldENV{CPPFLAGS};
	}	
	print "\nRunning make...\n";
	die "Compilation errors - script aborted.\n" if system ('make') != 0;
#	die "Test errors - script aborted.\n" if system ('make test') and $badTestsFatal;
	print "\nInstalling...\n";
	die "Install errors - script aborted.\n" if system ($installCommand) != 0;
#	if ($^O eq 'darwin') {
#		print "\nFixing library links...\n";
#		die "Install errors - couldn't fix library links:\n$@.\n"
#			if system ('cd /usr/lib;ln -s libMagick.5.0.36.dylib libMagick.5.dylib') != 0;
#		}
	chdir '..';

}


sub LibXMLInstall {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $installDir = $module->{installDir};
my $error;


	print "\nInstalling $installDir\n";
	chdir $installDir or die "Couldn't change working directory to $installDir.\n";

	die "Couldn't execute configure script.\n" if system ('./configure') != 0;
	die "Compilation errors - script aborted.\n" if system ('make') != 0;
	die "Install errors - script aborted.\n" if system ($installCommand) != 0;
	my $libXMLVersion = `xml2-config --version`;
	chomp ($libXMLVersion);

	die "Installation error:  libxml2 seems to have installed OK, but 'xml2-config' looks funny ('$libXMLVersion')\n" 
		unless defined $libXMLVersion and length ($libXMLVersion ) > 1;
	chdir '..';
	
}


sub LibXSLTInstall {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $installDir = $module->{installDir};
my $error;


	print "\nInstalling $installDir\n";
	chdir $installDir or die "Couldn't change working directory to $installDir.\n";

	die "Couldn't execute configure script.\n" if system ('./configure') != 0;
	die "Compilation errors - script aborted.\n" if system ('make') != 0;
	die "Install errors - script aborted.\n" if system ($installCommand) != 0;
	
	
	my $libXSLTVersion = libXSLTgetVersion($module);

	die "Installation error:  libxslt seems to have installed OK, but 'xslt-config' looks funny ('$libXSLTVersion')\n" 
		unless libXSLT_VersionOK ($libXSLTVersion);
	chdir '..';
	
}

sub bzlibInstall {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $installDir = $module->{installDir};
my $error;


	print "\nInstalling $installDir\n";
	chdir $installDir or die "Couldn't change working directory to $installDir.\n";

	die "Compilation errors - script aborted.\n" if system ('make') != 0;
	die "Install errors - script aborted.\n" if system ($installCommand) != 0;

	chdir '..';
	
}

sub zlibInstall {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $installDir = $module->{installDir};
my $error;


	print "\nInstalling $installDir\n";
	chdir $installDir or die "Couldn't change working directory to $installDir.\n";

	die "Compilation errors - script aborted.\n" if system ('make') != 0;
	die "Install errors - script aborted.\n" if system ($installCommand) != 0;

	chdir '..';
	
}

sub tiffInstall {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $installDir = $module->{installDir};
my $error;


	print "\nInstalling $installDir\n";
	chdir $installDir or die "Couldn't change working directory to $installDir.\n";

	die "Couldn't execute configure script.\n" if system ('./configure') != 0;
	die "Compilation errors - script aborted.\n" if system ('make') != 0;
	die "Install errors - script aborted.\n" if system ($installCommand) != 0;

	chdir '..';
	
}


##################################################################
# Special GetVersion subs:

#XML::SAX v0.12 doesn't report a VERSION even if it loads in perl 5.6.0
#XML::SAX won't load this way in perl 5.6.1
#XML::SAX::ParserFactory loads OK and reports proper VERSION string in both cases.
sub XML_SAX_getVersion {
my $moduleName = shift->{Name};
my $moduleVersion;
my $loadModule = "use XML::SAX::ParserFactory; ".'$moduleVersion = $XML::SAX::ParserFactory::VERSION;';

	eval ($loadModule);
	print "Eval errors: $@\n" if $@;

	$moduleVersion = '' if not $@ and not defined $moduleVersion;

	return $moduleVersion;
}

# get the version of libxml2
sub libXMLgetVersion {
my $module = shift;
my $libXMLVersion = `xml2-config --version`;

	chomp ($libXMLVersion);
	
	return ($libXMLVersion);
	
}

# get the version of libxslt
sub libXSLTgetVersion {
my $module = shift;
my $libXSLTVersion = `xslt-config --version`;

	chomp ($libXSLTVersion);
	
	return ($libXSLTVersion);
	
}

# returns ' ' if it can find an installation, else returns 0
sub zlibGetVersion {
my $module = shift;
my $location;

	foreach( ("/usr/local","/usr","/sw") ) {
		open( IN, "ls $_/include/zlib.h 2>&1 1>/dev/null |" );
		my $err = <IN>;
		close( IN );
		$location = $_;
		last if( !$err );
	}
	open( IN, "< $location/include/zlib.h" ) or
		die "Could not open $location/include/zlib.h for version check";
	while(<IN>) {
		chomp;
		if( m/version ([0-9\.]+)/ ) {
			close(IN);
			return $1;
		}
	}
	return 0;
}

# returns ' ' if it can find an installation, else returns 0
sub bzlibGetVersion {
my $module = shift;
my $location;

	foreach( ("/usr/local","/usr","/sw") ) {
		open( IN, "ls $_/include/bzlib.h 2>&1 1>/dev/null |" );
		my $err = <IN>;
		close( IN );
		$location = $_;
		last if( !$err );
	}
	open( IN, "< $location/include/bzlib.h" ) or
		die "Could not open $location/include/bzlib.h for version check";
	while(<IN>) {
		chomp;
		if( m/bzip2\/libbzip2 version ([0-9\.]+)/ ) {
			close(IN);
			return $1;
		}
	}
	return 0;
}

# returns ' ' if it can find an installation, else returns 0
sub tiffGetVersion {
my $module = shift;
my $location;

	foreach( ("/usr/local","/usr","/sw") ) {
		open( IN, "ls $_/include/tiffvers.h 2>&1 1>/dev/null |" );
		my $err = <IN>;
		close( IN );
		$location = $_;
		last if( !$err );
	}
	open( IN, "< $location/include/tiffvers.h" ) or
		die "Could not open $location/include/tiffvers.h for version check";
	while(<IN>) {
		chomp;
		if( m/LIBTIFF[\s\W]+Version[\s\W]+([0-9\.]+)/ ) {
			close(IN);
			return $1;
		}
	}
	return 0;
}

##################################################################
# Should not have to modify below here when specifying new modules
sub CheckModule {
my $module = $_;
my $moduleName = $module->{Name};
my $repositoryFile = $module->{repositoryFile};
my $moduleVersion;
my $getVersion;
my $checkVersion;
my $installModule;

	$getVersion = $module->{getVersion} if exists $module->{getVersion}
		and defined $module->{getVersion} and $module->{getVersion};
	$getVersion = \&GetModuleVersion unless defined $getVersion;

	$checkVersion = $module->{checkVersion} if exists $module->{checkVersion}
		and defined $module->{checkVersion} and $module->{checkVersion};
	$installModule = $module->{installModule} if exists $module->{installModule}
		and defined $module->{installModule} and $module->{installModule};
	$installModule = \&InstallModule unless defined $installModule;


	
	$moduleVersion = &{$getVersion} ($module);

	if (not defined $moduleVersion) {
		print "Couldn't find a functioning $moduleName.\n";
		if ($options{f}) {	# If we've been ARGV forced Just Do It(tm)
			$module->{installDir} = DownloadModule ($repositoryFile);
			&{$installModule}($module);
		} elsif (!$options{c}) {		# Else just do things interactively
			print "Would you like to install from the OME repository? (Y/[N]):";
			my $yorn = <STDIN>;
			chomp $yorn;
			$yorn = uc($yorn);
			if ($yorn eq 'Y' || $yorn eq 'YES') {
				$module->{installDir} = DownloadModule ($repositoryFile);
				&{$installModule}($module);
			} else { print "**** WARNING: Not installing required and missing module $moduleName from repository.\n"; }
		}
	} elsif (defined $checkVersion and not &{$checkVersion}($moduleVersion)) {
		print "$moduleName version is $moduleVersion - *NOT SUPPORTED*.\n";
		if ($options{f}) {	# If we've been ARGV forced Just Do It(tm)
			$module->{installDir} = DownloadModule ($repositoryFile);
			&{$installModule}($module);
		} elsif (!$options{c}) {		# Else just do things interactively
			print "Would you like to install from the OME repository? (Y/[N]):";
			my $yorn = <STDIN>;
			chomp $yorn;
			$yorn = uc($yorn);
			if ($yorn eq 'Y' || $yorn eq 'YES') {
				$module->{installDir} = DownloadModule ($repositoryFile);
				&{$installModule}($module);
			} else { print "**** WARNING: Not installing compatible missing module $moduleName from repository.\n"; }
		}
	} else { print "$moduleName version is $moduleVersion - OK\n"; }
}

sub GetModuleVersion {
my $moduleName = shift->{Name};
my $moduleVersion;
#my $command = "perl -e 'use $moduleName;print \$$moduleName"."::VERSION'";
my $eval = "use $moduleName; ".'$moduleVersion = $'.$moduleName.'::VERSION;';

	eval ($eval);
	print "Eval errors: $@\n" if $@;
	
	$moduleVersion = '' if not $@ and not defined $moduleVersion;
	
	return $moduleVersion;
}

# This results in an unpacked module directory or death.
# If the module's directory doesn't exist, the tar file is unpacked
# if the tar file doesn't exist, it is downloaded.
sub DownloadModule {
my $installTarBall = shift;
my $wget;
my $error;
my $moduleURL = "$moduleRepository/$installTarBall";
my $installDir;

	(undef,undef,$installTarBall) = File::Spec->splitpath( $installTarBall );

	if ($installTarBall =~ /(.*)\.tar\.gz/) {$installDir = $1};

	if (not -e $installDir) {
		if (not -e $installTarBall) {
			$wget = 'curl';
			$error = `$wget -V 2>&1 1>/dev/null`;
			if (not $error) {
				print "\nDownloading $moduleURL using $wget...\n";
				$error = system ("$wget -O $moduleURL 2>&1 1>/dev/null");
			} else {
				$wget = 'wget';
				$error = `$wget -V 2>&1 1>/dev/null`;
				if (not $error) {
					print "\nDownloading $moduleURL using $wget...\n";
					$error = system ("$wget -nv $moduleURL 2>&1 1>/dev/null");
				}
			}
			die "Couldn't download $moduleURL" if $error != 0;

			if (not -e $installTarBall) {die "Couldn't find $installTarBall.\n";}
		}

		print "\nUnpacking $installTarBall\n";
		die "Couldn't unpack $installTarBall.\n" if system ("tar -zxvf $installTarBall") != 0;
	}

	if (not -e $installDir) {die "Couldn't find $installDir.\n";}


	chdir $installDir or die "Couldn't change working directory to $installDir.\n";
	chdir '..';
	return ($installDir);
}


sub InstallModule {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $badTestsFatal;
$badTestsFatal = $module->{badTestsFatal} if exists $module->{badTestsFatal};
$badTestsFatal = $DEFAULT_badTestsFatal unless defined $badTestsFatal;
my $installDir = $module->{installDir};
my $error;

	print "\nInstalling $installDir\n";
	chdir $installDir or die "Couldn't change working directory to $installDir.\n";

	die "Couldn't execute perl script 'Makefile.PL'.\n" if system ('perl Makefile.PL') != 0;
	die "Compilation errors - script aborted.\n" if system ('make') != 0;
	my $testStatus = system ('make test');
	die "Test errors - script aborted.\n" if $testStatus != 0 and $badTestsFatal;
	if ($testStatus != 0 and not $badTestsFatal) {
		print "\n**** Test Errors - attempt install anyway? [NO] ";
		my $yorn = <STDIN>;
		chomp $yorn;
		$yorn = uc ($yorn);
		if (not ($yorn eq 'Y' or $yorn eq 'YES') ) {
				die "\n Script aborted \n";
		}
	}
	
	die "Install errors - script aborted.\n" if system ($installCommand) != 0;
	chdir '..';
}
