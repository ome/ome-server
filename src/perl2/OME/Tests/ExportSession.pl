use strict;
use OME::Tasks::OMEExport;
use OME::SessionManager;
use XML::LibXML;
use Log::Agent;

if( ! $ARGV[0] ) {
	print "Usage is:\n\t perl ExportSession.pl [--file outputFile] [--exportSTDs] [ [All] | [ [User] [Group] [Project] [Dataset] [Images] [Features]] ]\n";
	exit -1;
}

if ($ENV{OME_DEBUG} > 0) {	
	logconfig(
		-prefix      => "$0",
		-level    => 'debug'
	);
}

my $session = OME::SessionManager->TTYlogin();
#$session->DBH()->trace(3);
my $OMEExporter = OME::Tasks::OMEExport->new( session => $session);
my $file;
my @objects;
my $factory = $session->Factory();
my $ExportSTDs;

for (my $i=0; $i < @ARGV; $i++) {
	if ($ARGV[$i] eq '--file') {
		$file = $ARGV[$i+1];
		$i++;
	}
	if ($ARGV[$i] eq '--exportSTDs') {
		logdbg "debug", 'Will be exporting STDs';
		$ExportSTDs = 1;
	}
	if ($ARGV[$i] eq 'User' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding User';
		push (@objects, $session->User());
	}
	if ($ARGV[$i] eq 'Group' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Group';
		push (@objects, $session->User()->Group());
	}
	if ($ARGV[$i] eq 'Project' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Project';
		push (@objects, $session->project());
	}
	if ($ARGV[$i] eq 'Dataset' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Dataset';
		push (@objects, $session->dataset());
	}
	if ($ARGV[$i] eq 'Images' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Images';
		push (@objects, $session->dataset()->images());
	}
	if ($ARGV[$i] eq 'Features' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Features';
		my @images = $session->dataset()->images();
		foreach (@images) {
			my @features = $_->all_features();
			foreach (@features) {
				logdbg "debug", 'Adding Bounds feature '.$_->id();
				push (@objects, $factory->findAttributes('Bounds',$_->id()));
			}
		}
	}
}

logdbg "debug", 'Building DOM';
$OMEExporter->buildDOM (\@objects, ResolveAllRefs => 1, ExportSTDs => $ExportSTDs);

if (defined $file) {
	logdbg "debug", "Exporting to $file";
	$OMEExporter->exportFile ($file);
} else {
	logdbg "debug", "Exporting to stdout";
	print $OMEExporter->exportXML ($file);
}

