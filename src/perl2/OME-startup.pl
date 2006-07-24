use strict;
use warnings;

print STDERR "Processing OME-startup.pl\n";
use Carp;

use CGI qw/-no_xhtml/;

our @OME_WEB_CLASSES = qw/
	OME::Web
	OME::Web::Ping
/;
eval {
	Apache::DBI->require();
};
if ($@) {
	print STDERR "Not using Apache::DBI - no cached DB handles";
}

use OME;
use OME::Session;
use OME::DBObject;
use OME::Factory;
use OME::Database::Delegate;
use OME::SessionManager;
use OME::Tasks::ImageTasks;
use OME::Tasks::SemanticTypeManager;
use OME::ImportExport::ChainImport;
use OME::Tasks::OMEImport;
use OME::Tasks::ModuleExecutionManager;

use OME::Util::cURL;


use OME::Install::Environment;
my $env = OME::Install::Environment->initialize()
	or die "OME installation environment (/etc/ome-install.store) could not be initialized";

use OME::Install::CoreDatabaseTablesTask;
foreach my $class (@OME::Install::CoreDatabaseTablesTask::core_classes) {
	$class->require();
}


use OME::Install::Util ();
# Get a temporary factory
my $old_euid;
my $session;
eval {
	$session = bootstrap_session();
};
if ($@ or not $session) {
	print STDERR "Tring to get a session as the Apache user...\n";
	eval {
		my $apacheUID = getpwnam($env->apache_user());
		$old_euid = OME::Install::Util::euid ( $apacheUID );
		$session = bootstrap_session();
	};
	if ($@) {
		print STDERR "Could not get an OME::Session object:\n$@";
	}
	
}

use OME::SemanticType;
if ($session) {
	my $factory = OME::Session->instance()->Factory();
	OME::Configuration->preload($factory);
	my @STs = $factory->findObjects ('OME::SemanticType');
	print STDERR "Pre-loading SemanticTypes...\n";
	foreach my $ST (@STs) {
		$ST->requireAttributeTypePackage($factory);
	}

	$factory = undef;
	$session->deleteInstance();
	$session = undef;
}

if (defined $old_euid) {
	OME::Install::Util::euid ($old_euid);
}

my $class;

# Import OME::Web stuff if we're using OME::Web
if ($env->apache_conf()->{WEB}) {
# recursively find all files with a matching package declaration
# grep -r '^[^#]*package OME::Web' OME
	print STDERR "Pre-loading classes for OME::Web...\n";
	CGI->compile(':all');
	foreach my $class (@OME_WEB_CLASSES) {
		$class->require();
	}
}



sub bootstrap_session {
    my $factory = OME::Factory->new();
	my $experimenterObj = $factory->
		findObject('OME::SemanticType::BootstrapExperimenter',OMEName => $env->ome_exper()->{OMEName});
    my $userState = $factory->findObject('OME::UserState',experimenter_id => $experimenterObj->id());
    return OME::Session->instance($userState, $factory);
}

1;
