use strict;
use OME::Tasks::OMEExport;
use OME::SessionManager;
use XML::LibXML;
use Log::Agent;

# This is a 2x speed-up.
use OME::DBObject;
OME::DBObject->Caching(1);


if( ! $ARGV[0] ) {
	print "Usage is:\n\t perl ExportSession.pl [--file outputFile] [--exportSTDs] [ [All] | [ [Global] [User] [Group] [Project] [Dataset] [Images] [Features]] ]\n";
	exit -1;
}

if ($ENV{OME_DEBUG} > 0) {	
	logconfig(
		-prefix      => "$0",
		-level    => 'debug'
	);
}

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
#$session->DBH()->trace(3);
my $OMEExporter = OME::Tasks::OMEExport->new( session => $session);
my $file;
my @exportObjects;
my $factory = $session->Factory();
my $ExportSTDs;


my @featureAttributes = $factory->findObjects("OME::SemanticType",granularity => 'F');
my @datasetAttributes = $factory->findObjects("OME::SemanticType",granularity => 'D');
my @imageAttributes = $factory->findObjects("OME::SemanticType",granularity => 'I');
my ($object,$attribute);

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
		push (@exportObjects, $session->User());
	}
	if ($ARGV[$i] eq 'Group' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Group';
		push (@exportObjects, $session->User()->Group());
	}
	if ($ARGV[$i] eq 'Project' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Project';
		push (@exportObjects, $session->project());
	}
	if ($ARGV[$i] eq 'Dataset' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Dataset';
		push (@exportObjects, $session->dataset());
	}
	if ($ARGV[$i] eq 'Images' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Images';
		if ($session->dataset()) {
			my @images = $session->dataset()->images();
			foreach my $image (@images) {
				push (@exportObjects, $image);
				foreach $attribute (@imageAttributes) {
					my @objects = $factory->findAttributes($attribute->name(),$image->id());
					if (@objects > 0) {
						logdbg "debug", "Adding Image attribute '".$attribute->name()."'";
						push (@exportObjects,@objects);
					}
				}
			}
		}
	}
	if ($ARGV[$i] eq 'Features' or $ARGV[$i] eq 'All') {
		logdbg "debug", 'Adding Features';
		if ($session->dataset()) {
			my @images = $session->dataset()->images();
			foreach my $image (@images) {
				my @features = $image->all_features();
				foreach my $feature (@features) {
					push (@exportObjects, $feature);
					foreach $attribute (@featureAttributes) {
						my @objects = $factory->findAttributes($attribute->name(),$feature->id());
						if (@objects > 0) {
							logdbg "debug", "Adding Feature attribute '".$attribute->name()."'";
							push (@exportObjects,@objects);
						}
					}
				}
			}
		}
	}
}

logdbg "debug", 'Building DOM';
$OMEExporter->buildDOM (\@exportObjects, ResolveAllRefs => 1, ExportSTDs => $ExportSTDs);

if (defined $file) {
	logdbg "debug", "Exporting to $file";
	$OMEExporter->exportFile ($file);
} else {
	logdbg "debug", "Exporting to stdout";
	print $OMEExporter->exportXML ($file);
}

