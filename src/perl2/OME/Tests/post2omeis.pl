#!/usr/bin/perl
use strict;
use OME::Image::Server;
use OME::SessionManager;
use Log::Agent;

printUsage()
	if( ! $ARGV[0] || $ARGV[0] eq '--help');
setDebug();

my $manager = OME::SessionManager->new();
my $session = $manager->TTYlogin();
my $factory = $session->Factory();

if( $ARGV[0] =~ m/-p|--postImage/ ) {
	shift( @ARGV );
	foreach my $imageID (@ARGV) {
		print "\n\nposting Image $imageID to omeis.\n";
		my $image = $factory->loadObject( 'OME::Image', $imageID)
			or die "ImageID $imageID would not load.";
		my $pixels = $image->DefaultPixels();
		print "\tpixelsID = ".postPixels($pixels)."\n";
	}
} else {
	print "postImage is the only functionality implemented.\n";
}

sub postPixels {
	my $pixels = shift;
	my $fileID = OME::Image::Server->uploadFile( $pixels->image->getFullPath( $pixels ) );
	my $pixelsID = OME::Image::Server->newPixels( 
		$pixels->SizeX(),
		$pixels->SizeY(),
		$pixels->SizeZ(),
		$pixels->SizeC(),
		$pixels->SizeT(),
		$pixels->BitsPerPixel() / 8,
		0, 0 );
	my $stackSize = $pixels->SizeX() * $pixels->SizeY() * $pixels->SizeZ() * $pixels->BitsPerPixel() / 8;
	for( my $t = 0; $t < $pixels->SizeT(); $t++ ) {
		for( my $c = 0; $c < $pixels->SizeC(); $c++ ) {
			my $offset = ( $t * $pixels->SizeC() + $c ) * $stackSize;
			OME::Image::Server->convertStack( $pixelsID, $c, $t, $fileID, $offset );
		}
	}
	OME::Image::Server->finishPixels( $pixelsID );
	return $pixelsID;
}

sub printUsage {
	my $usage = <<END_STRING;
Usage: postImage2omeis.pl [-ptA]

	-p | --postImage [imageID 1],[imageID 2],...
		posts individual images to image server. Prints the IS Pixels ID. Does not affect the DB.

	-t | --convertPixels [pixelsID],[pixelsID],...
		converts Pixels from a local repository to the image server. Writes changes to the DB.

	-A | --convertAllPixels
		converts all Pixels in local repositories to image server repository.
		
	--help
		display this usage message.
END_STRING
	print $usage;
	exit -1;
}

sub setDebug {
	#
	# Set OME_DEBUG environment variable to turn on debugging.
	#
	if ($ENV{OME_DEBUG} > 0) {
		logconfig(
			-prefix      => "$0",
			-level    => 'debug'
		);
	}
}
