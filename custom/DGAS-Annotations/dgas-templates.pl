#!/usr/bin/perl

use strict;
use Carp qw(cluck croak confess carp);
use Sys::Hostname;

use OME::SessionManager;
use OME::Tasks::ModuleExecutionManager;
use OME::Tasks::ImageTasks;
use OME::Tasks::ImageManager;

my $DATASET_NAME = 'Automated Import';
my $DATASET_DESCRIPTION = 'Images imported by nightly background task';
my $PROJECT_NAME = 'ES Bank';
my $PROJECT_DESCRIPTION = 'Genetic Manipulation of Embryonic Stem Cells';

# my $session = OME::SessionManager->TTYlogin();
my $session = su_session(); # Gets an OME superuser session
my $factory = $session->Factory();

die "Could not make session for ".$session->User()->OMEName() unless $session;

# Set up a global MEX
my $global_module = $factory->findObject( 'OME::Module', name => 'Global import' )
		or die "couldn't load Global import module";
my $globalMEX = OME::Tasks::ModuleExecutionManager->createMEX($global_module,'G',
	undef, undef, undef, # These don't apply to global MEXes
	$session->User(), undef             # These make the MEX public, but owned by the specified owner
	) or die "Couldn't get mex for Spreadsheet Global import";



#create the browse templates
my $browse = $factory->maybeNewAttribute('BrowseTemplate',undef,$globalMEX,{
	Name =>'GeneProbeTable',
	Template=>'Browse/GeneProbeTable.tmpl',
	ImplementedBy=>'OME::Web::TableBrowse'
});
my $browse = $factory->maybeNewAttribute('BrowseTemplate',undef,$globalMEX,{
	Name =>'GeneManipulationTable',
	Template=>'Browse/GeneManipulationTable.tmpl',
	ImplementedBy=>'OME::Web::TableBrowse'
});


# create the display templates.
# note that the name of this template must be the same as the name
# for the BrowseTemplate instance that was just created. 
my $display = $factory->maybeNewAttribute('DisplayTemplate',undef,$globalMEX,
  {Name =>'GeneProbeTable',
   Template=>'Display/One/OME/Image/GeneProbeTable.tmpl',
   ObjectType=>'OME::Image',
   Arity=>'one',
   Mode=>'ref'});
my $display = $factory->maybeNewAttribute('DisplayTemplate',undef,$globalMEX,
  {Name =>'GeneManipulationTable',
   Template=>'Display/One/OME/Image/GeneManipulationTable.tmpl',
   ObjectType=>'OME::Image',
   Arity=>'one',
   Mode=>'ref'});

# create the annotation templates
my $annotation = $factory->maybeNewAttribute('AnnotationTemplate',undef,$globalMEX,
  {Name => 'DGASannotations',
   Template=>'/Actions/Annotator/ProbeStage.tmpl'});


# All the outputs are untyped for this MEX, so see if we have any and delete the MEX if not.
my @untyped_outputs = $globalMEX->untypedOutputs();
if (scalar (@untyped_outputs)) {
	print "Storing global MEX\n";
	$globalMEX->status( 'FINISHED' );
	$globalMEX->storeObject();
} else {
	print "deleting global MEX\n";
	$globalMEX->deleteObject();
}

$session->commitTransaction();




sub su_session {
#	croak "You must be root to create an OME superuser session" unless $< == 0;
#	my $DSN = OME::Database::Delegate->getDefaultDelegate()->getDSN();
#	croak "You can only create an OME superuser session on a local database" if $DSN =~ /host/;
	
    my $factory = OME::Factory->new();
    croak "Couldn't create a new factory" unless $factory;
    
	my $var = $factory->findObject('OME::Configuration::Variable',
			configuration_id => 1, name => 'super_user');
    my $experimenterID = $var->value();
    
   
	croak "The super_user Expreimenter is not defined in the configuration table.\n"
		unless $experimenterID;
	my $userState = OME::SessionManager->makeOrGetUserState ($factory, experimenter_id => $experimenterID);

    print "  \\__ Getting session for user state ID=".$userState->id()."\n";
    # N.B.: In this case, we are not specifying the visible groups and users - they are all visible.
    my $session = OME::Session->instance($userState, $factory);

    croak "Could not create session from userState.  Something is probably very very wrong" unless defined $session;

    $userState->storeObject();
    $session->commitTransaction();

    return $session;
}

sub sudo_session {
	my $session = shift;
	my $username = shift;
	my $factory = $session->Factory();
#	croak "You can only call sudo_session on a super_user session"
#		unless $factory->Configuration()->super_user() == $session->experimenter_id();

	my $userState = OME::SessionManager->makeOrGetUserState ($factory, OMEName => $username);
	croak "Could not get user state for $username" unless $userState;

	# N.B.:  This disables ACL on the sudo session
	return ( OME::Session->instance($userState, $factory,undef) );
	
}
