use strict;
use warnings;

print STDERR "Processing OME-startup.pl\n";
use Carp;

use CGI qw/-no_xhtml/;
CGI->compile(':all');


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

use OME::Install::CoreDatabaseTablesTask;
use OME::Web;
use OME::Web::Ping;

use OME::Install::Environment;
OME::Install::Environment->initialize();

foreach my $class (@OME::Install::CoreDatabaseTablesTask::core_classes) {
	$class->require();
}


1;
