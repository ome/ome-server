#!/usr/bin/perl -w
use strict;

my $moduleRepository = 'http://ome1-sorger.mit.edu/packages/perl';

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
	return ($version >= 1.15 and $version <= 1.19);
}

sub DBD_Pg_VersionOK {
my $version = shift;
	return ($version = 0.95);
}

# Should have to modify below here when specifying new modules
sub CheckModule {
my $module = $_;
my $moduleName = $module->{Name};
my $repositoryFile = $module->{repositoryFile};
my $moduleVersion;
my $checkVersion;
$checkVersion = $module->{checkVersion} if exists $module->{checkVersion}
	and defined $module->{checkVersion} and $module->{checkVersion};

	eval qq /require $moduleName;\$moduleVersion = \$$moduleName/.qq/::VERSION;/;
	
	if ($@) {
		print "$@\n";
		print "Downloading $moduleRepository/$repositoryFile...\n";
		DownloadModule ("$moduleRepository/$repositoryFile");
	} elsif (defined $checkVersion and not &{$checkVersion}($moduleVersion)) {
		print "$moduleName version is $moduleVersion - not supported\n";
		DownloadModule ("$moduleRepository/$repositoryFile");
	} else {
		print "$moduleName version is $moduleVersion - OK\n";
	}

}



sub DownloadModule {
my $module = shift;
my $wget;
my $error;

	print "Downloading $module...\n";
	
	$wget = 'curl';
	$error = `$wget -V 2>&1 1>/dev/null`;
	if (not $error) {
		$error = system ("$wget -O $module 2>&1 1>/dev/null");
	}
	return unless $error;

	$wget = 'wget';
	$error = `$wget -V 2>&1 1>/dev/null`;
	if (not $error) {
		$error = system ("$wget -nv $module 2>&1 1>/dev/null");
	}
	return unless $error;
	
	print STDERR "Could not download $module.\n";
}
