#!/usr/bin/perl -w
use strict;
use Config;
use Cwd;
my $cwd = getcwd;
my $libDir = $Config{installprivlib};


my $moduleRepository = 'http://ome1-sorger.mit.edu/packages/perl';
my $badTestsFatal = 0;

$ENV{PATH} .= ':/usr/local/bin';

# Add module specs here:
my @modules = ({
	Name => 'DBI',
	repositoryFile => 'DBI-1.19.tar.gz',
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
	Name => 'DBD::Pg',
	repositoryFile => 'DBD-Pg-0.95.tar.gz',
	checkVersion => \&DBD_Pg_VersionOK,
	installModule => \&DBD_Pg_Install
	},{
	Name => 'Image::Magick',
	repositoryFile => 'ImageMagick-5.3.6-OSX.tar.gz',
	installModule => \&ImageMagickInstall
	}
);

#####################
# Da 'main' program:

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

# Make symlinks between the private perl module directory and OME modules:
# Where to install private libs: $Config{installprivlib}
my @OMEmodules = ('OMEpl.pm','OMEDataset.pm','OMEDataset','OMEfeature.pm','OMEwebLogin.pm');
foreach (@OMEmodules) {
	if (-e $libDir.'/'.$_) {
		unlink ("$libDir/$_") or die "Could't delete '$libDir/$_': $!\n";
	}
	symlink ("$cwd/$_", "$libDir/$_") or die "Could't make a symbolic link to '$cwd/$_' from '$libDir/$_':  $!";
}
######################



######################
#  Version checks:
sub DBI_VersionOK {
my $version = shift;
	return (1) if $version ge 1.15 and $version le 1.19;
	return (0);
}

sub DBD_Pg_VersionOK {
my $version = shift;
	return (1) if $version eq 0.95;
	return (1) if $version eq 1.01;
	return (0);
}


############################
# Special installation subs:
sub DBD_Pg_Install {
my $module = shift;
my (undef,$pgVersion) = split (' ',`pg_config --version`);
my $installTarBall = $module->{repositoryFile};
my $installDir;
	if ($installTarBall =~ /(.*)\.tar\.gz/) {$installDir = $1};
my $error;


	die "Postgres version must be >= 7.1\n" unless $pgVersion ge '7.1';

	my $incDir = `pg_config --includedir`;
	$incDir =~ s/^\s+//;$incDir =~ s/\s+$//;
	$ENV{POSTGRES_INCLUDE} = $incDir;
	my $libDir = `pg_config --libdir`;
	$libDir =~ s/^\s+//;$libDir =~ s/\s+$//;
	$ENV{POSTGRES_LIB} = "$libDir -lssl";
	
	if ($^O eq 'darwin') {
		print "\nranlib $libDir/libpq.a","\n";
		die "Couldn't run ranlib on $libDir/libpq.a\n" if system ("ranlib $libDir/libpq.a");
	}
	
	InstallModule ($module);
}


sub ImageMagickInstall {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $installDir;
	if ($installTarBall =~ /(.*)\.tar\.gz/) {$installDir = $1};
my $error;
my @configFlags = (
	'--enable-shared',
	'--without-magick-plus-plus',
	'--enable-lzw',
	'--prefix=/usr'
	);

	chdir $installDir or die "Couldn't change working directory to $installDir.\n";
	
	if ($^O eq 'darwin') {
		push (@configFlags,'--without-x');
		}

	if (not -e 'Makefile' ) {
		print "\nRunning configure script...\n";
		die "Couldn't execute configure script\n" if system ('./configure '.join (' ',@configFlags) );
	}
	
	print "\nRunning make...\n";
	die "Compilation errors - script aborted.\n" if system ('make');
#	die "Test errors - script aborted.\n" if system ('make test') and $badTestsFatal;
	print "\nInstalling...\n";
	die "Install errors - script aborted.\n" if system ('make install');
	if ($^O eq 'darwin') {
		print "\nFixing library links...\n";
		die "Install errors - couldn't fix library links:\n$@.\n"
			if system ('cd /usr/lib;ln -s libMagick.5.0.36.dylib libMagick.5.dylib');
		}
	chdir '..';

}


##################################################################
# Should not have to modify below here when specifying new modules
sub CheckModule {
my $module = $_;
my $moduleName = $module->{Name};
my $repositoryFile = $module->{repositoryFile};
my $moduleVersion;
my $checkVersion;
my $installModule;
$checkVersion = $module->{checkVersion} if exists $module->{checkVersion}
	and defined $module->{checkVersion} and $module->{checkVersion};
$installModule = $module->{installModule} if exists $module->{installModule}
	and defined $module->{installModule} and $module->{installModule};
$installModule = \&InstallModule unless defined $installModule;


	
	$moduleVersion = GetModuleVersion ($moduleName);

	if (not (defined $moduleVersion and $moduleVersion)) {
		print "Couldn't find a functioning $moduleName\n";
		DownloadModule ($repositoryFile);
		&{$installModule}($module);
	} elsif (defined $checkVersion and not &{$checkVersion}($moduleVersion)) {
		print "$moduleName version is $moduleVersion - not supported\n";
		DownloadModule ($repositoryFile);
		&{$installModule}($module);
	} else {
		print "$moduleName version is $moduleVersion - OK\n";
	}

}

sub GetModuleVersion {
my $moduleName = shift;
my $moduleVersion;
my $command = "perl -e 'require $moduleName;print \$$moduleName"."::VERSION'";
	
	$moduleVersion = `$command`;
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
			die "Couldn't download $moduleURL" if $error;

			if (not -e $installTarBall) {die "Couldn't find $installTarBall.\n";}
		}

		print "\nUnpacking $installTarBall\n";
		die "Couldn't unpack $installTarBall.\n" if system ("tar -zxvf $installTarBall");
	}

	if (not -e $installDir) {die "Couldn't find $installDir.\n";}


	chdir $installDir or die "Couldn't change working directory to $installDir.\n";
	chdir '..';
}


sub InstallModule {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $installDir;
	if ($installTarBall =~ /(.*)\.tar\.gz/) {$installDir = $1};
my $error;

	print "\nInstalling $installDir\n";
	chdir $installDir or die "Couldn't change working directory to $installDir.\n";

	die "Couldn't execute perl script 'Makefile.PL'.\n" if system ('perl Makefile.PL');
	die "Compilation errors - script aborted.\n" if system ('make');
	die "Test errors - script aborted.\n" if system ('make test') and $badTestsFatal;
	die "Install errors - script aborted.\n" if system ('make install');
	chdir '..';
}
