#!/usr/bin/perl -w
use strict;

my $moduleRepository = 'http://ome1-sorger.mit.edu/packages/perl';
my $badTestsFatal = 0;

$ENV{PATH} .= ':/usr/local/bin';

# Add module specs here:
my @modules = ({
	Name => 'DBI',
	repositoryFile => 'DBI-1.19.tar.gz',
	checkVersion => \&DBI_VersionOK,
	loadOrder => 0
	},{
	Name => 'Digest::MD5',
	repositoryFile => 'Digest-MD5-2.13.tar.gz',
	loadOrder => 1
	},{
	Name => 'MD5',
	repositoryFile => 'MD5-2.02.tar.gz',
	loadOrder => 2
	},{
	Name => 'MIME::Base64',
	repositoryFile => 'MIME-Base64-2.12.tar.gz',
	loadOrder => 3
	},{
	Name => 'Storable',
	repositoryFile => 'Storable-1.0.13.tar.gz',
	loadOrder => 4
	},{
	Name => 'Apache::Session',
	repositoryFile => 'Apache-Session-1.54.tar.gz',
	loadOrder => 5
	},{
	Name => 'Log::Agent',
	repositoryFile => 'Log-Agent-0.208.tar.gz',
	loadOrder => 6
	},{
	Name => 'DBD::Pg',
	repositoryFile => 'DBD-Pg-0.95.tar.gz',
	checkVersion => \&DBD_Pg_VersionOK,
	installModule => \&DBD_Pg_Install,
	loadOrder => 7
	}
);

# Da 'main' loop:
foreach (@modules) {
	CheckModule ($_);
}


#  Version checks:
sub DBI_VersionOK {
my $version = shift;
	return (1) if $version ge 1.15 and $version le 1.19;
	return (0);
}

sub DBD_Pg_VersionOK {
my $version = shift;
	return (1) if $version eq 0.95;
	return (0);
}

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
	$ENV{POSTGRES_LIB} = $libDir;
	
	if ($^O eq 'darwin') {
		print "ranlib2 $libDir/libpq.a","\n";
		die "Couldn't run ranlib on $libDir/libpq.a\n" if system ("ranlib $libDir/libpq.a");
	}
	
	InstallModule ($module);
}


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


	eval qq /require $moduleName;\$moduleVersion = \$$moduleName/.qq/::VERSION;/;
	
	if ($@) {
		print "$@\n";
		DownloadModule ("$moduleRepository/$repositoryFile");
		&{$installModule}($module);
	} elsif (defined $checkVersion and not &{$checkVersion}($moduleVersion)) {
		print "$moduleName version is $moduleVersion - not supported\n";
		DownloadModule ("$moduleRepository/$repositoryFile");
		&{$installModule}($module);
	} else {
		print "$moduleName version is $moduleVersion - OK\n";
	}

}



sub DownloadModule {
my $module = shift;
my $wget;
my $error;

	
	$wget = 'curl';
	$error = `$wget -V 2>&1 1>/dev/null`;
	if (not $error) {
		print "Downloading $module using $wget...\n";
		$error = system ("$wget -O $module 2>&1 1>/dev/null");
	}
	return unless $error;

	$wget = 'wget';
	$error = `$wget -V 2>&1 1>/dev/null`;
	if (not $error) {
		print "Downloading $module using $wget...\n";
		$error = system ("$wget -nv $module 2>&1 1>/dev/null");
	}
	return unless $error;
	
	print STDERR "Could not download $module.\n";
}


sub InstallModule {
my $module = shift;
my $installTarBall = $module->{repositoryFile};
my $installDir;
	if ($installTarBall =~ /(.*)\.tar\.gz/) {$installDir = $1};
my $error;

	print "Installing $installTarBall\n";
	die "Couldn't unpack $installTarBall.\n" if system ("tar -zxvf $installTarBall");
	chdir $installDir or die "Couldn't change working directory to $installDir.\n";

	die "Couldn't execute perl script 'Makefile.PL'.\n" if system ('perl Makefile.PL');
	die "Compilation errors - script aborted.\n" if system ('make');
	die "Test errors - script aborted.\n" if system ('make test') and $badTestsFatal;
	die "Install errors - script aborted.\n" if system ('make install');
	chdir '..';
}
