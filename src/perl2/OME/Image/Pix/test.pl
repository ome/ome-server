# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..25\n"; }
END {print "not ok 1\n" unless $loaded;
	unlink ('pixTest16');
	unlink('pixTestROI');
	unlink('pixTestROI2');
	unlink('testTIFF16.tiff');
	unlink('testTIFF8.tiff');}
use OME::Image::Pix;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;
my $nPix = 5*5*5*5*5;
my $pix;
my $pix = new OME::Image::Pix ('pixTest16',5,5,5,5,5,2) || die "Could not instantiate OME::Image::Pix object";
print "ok 2\n";

my @pixArray = (0..$nPix-1);
my $pix8 = pack("C*",@pixArray);
my $pix16 = pack("S*",@pixArray);
my $nOut = $pix->SetPixels ($pix16);
die "Expecting to write ".scalar (@pixArray)." pixels, wrote $nOut\n" unless $nOut == @pixArray;
print "ok 3\n";

my $pixels = $pix->GetPixels () || die "Could not allocate buffer\n";
my @testPix = unpack ("S*",$pixels);
die "GetPix() returned ".scalar(@testPix)." pixels, expecting ".scalar(@pixArray).".\n" unless @testPix == @pixArray;
for (my $i = 0; $i < @pixArray; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPix[$i] == $pixArray[$i];
}
print "ok 4\n";

my $pixROI = new OME::Image::Pix ('pixTestROI',5,5,5,5,5,2) || die "Could not instantiate OME::Image::Pix object";
my $nPixROI = 5*5*5*5*5;
my @pixArrayROI = (0..$nPixROI-1);
my $pix16ROI = pack("S*",@pixArrayROI);
my $nOutROI = $pixROI->SetROI ($pix16ROI,0,0,0,0,0,5,5,5,5,5);
die "Expecting to write ".scalar (@pixArrayROI)." pixels, wrote $nOutROI\n" unless $nOutROI == @pixArrayROI;
print "ok 5\n";

my $pixelsROI = $pixROI->GetPixels () || die "Could not allocate buffer for ROI\n";
my @testPixROI = unpack ("S*",$pixelsROI);
die "GetPix() returned ".scalar(@testPixROI)." pixels, expecting ".scalar(@pixArray).".\n" unless @testPixROI == @pixArray;
for (my $i = 0; $i < @pixArray; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixROI[$i] == $pixArray[$i];
}
print "ok 6\n";

my $pixROI = new OME::Image::Pix ('pixTestROI2',5,5,5,5,5,2) || die "Could not instantiate OME::Image::Pix object\n";
my $nPixROI = 2*2*2*2*2;
my @pixArrayROI = (0..$nPixROI-1);
my $pix16ROI = pack("S*",@pixArrayROI);
my $nOutROI = $pixROI->SetROI ($pix16ROI,1,1,1,1,1,3,3,3,3,3);
die "Expecting to write ".scalar (@pixArrayROI)." pixels, wrote $nOutROI\n" unless $nOutROI == @pixArrayROI;
print "ok 7\n";

my $pixelsROI = $pixROI->GetROI (1,1,1,1,1,3,3,3,3,3) || die "Could not allocate buffer\n";
my @testPixROI = unpack ("S*",$pixelsROI);
die "GetPixROI() returned ".scalar(@testPixROI)." pixels, expecting ".scalar(@pixArrayROI).".\n" unless @testPixROI == @pixArrayROI;
for (my $i = 0; $i < @pixArrayROI; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixROI[$i] == $pixArrayROI[$i];
}
print "ok 8\n";

my $nPixPlane = 5*5;
my @pixArrayPlane = (0..$nPixPlane-1);
my $pix16Plane = pack("S*",@pixArrayPlane);
my $nOutPlane = $pixROI->SetROI ($pix16Plane,0,0,4,1,1,5,5,5,2,2);
die "Expecting to write ".scalar (@pixArrayPlane)." pixels, wrote $nOutPlane\n" unless $nOutPlane == @pixArrayPlane;
print "ok 9\n";

my $pixelsPlane = $pixROI->GetPlane (4,1,1) || die "Could not allocate buffer\n";
my @testPixPlane = unpack ("S*",$pixelsPlane);
die "GetPixPlane() returned ".scalar(@testPixPlane)." pixels, expecting ".scalar(@pixArrayPlane).".\n" unless @testPixPlane == @pixArrayPlane;
for (my $i = 0; $i < @pixArrayPlane; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixPlane[$i] == $pixArrayPlane[$i];
}
print "ok 10\n";

my $nPixStack = 5*5*5;
my @pixArrayStack = (0..$nPixStack-1);
my $pix16Stack = pack("S*",@pixArrayStack);
my $nOutStack = $pixROI->SetROI ($pix16Stack,0,0,0,2,2,5,5,5,3,3);
die "Expecting to write ".scalar (@pixArrayStack)." pixels, wrote $nOutStack\n" unless $nOutStack == @pixArrayStack;
print "ok 11\n";

my $pixelsStack = $pixROI->GetStack (2,2) || die "Could not allocate buffer\n";
my @testPixStack = unpack ("S*",$pixelsStack);
die "GetPixStack() returned ".scalar(@testPixStack)." pixels, expecting ".scalar(@pixArrayStack).".\n" unless @testPixStack == @pixArrayStack;
for (my $i = 0; $i < @pixArrayStack; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixStack[$i] == $pixArrayStack[$i];
}
print "ok 12\n";

my $nPixPlane = 5*5;
my @pixArrayPlane = (0..$nPixPlane-1);
my $pix16Plane = pack("S*",@pixArrayPlane);
my $nOutPlane = $pixROI->SetPlane ($pix16Plane,4,4,3);
die "Expecting to write ".scalar (@pixArrayPlane)." pixels, wrote $nOutPlane\n" unless $nOutPlane == @pixArrayPlane;
print "ok 13\n";

my $pixelsPlane = $pixROI->GetROI (0,0,4,4,3,5,5,5,5,4) || die "Could not allocate buffer\n";
my @testPixPlane = unpack ("S*",$pixelsPlane);
die "GetPixPlane() returned ".scalar(@testPixPlane)." pixels, expecting ".scalar(@pixArrayPlane).".\n" unless @testPixPlane == @pixArrayPlane;
for (my $i = 0; $i < @pixArrayPlane; $i++) {
	die "GetPixPlane() returned different pixels than SetPix(). Index=$i\n" unless $testPixPlane[$i] == $pixArrayPlane[$i];
}
print "ok 14\n";

my $nPixStack = 5*5*5;
my @pixArrayStack = (0..$nPixStack-1);
my $pix16Stack = pack("S*",@pixArrayStack);
my $nOutStack = $pixROI->SetStack ($pix16Stack,4,0);
die "Expecting to write ".scalar (@pixArrayStack)." pixels, wrote $nOutStack\n" unless $nOutStack == @pixArrayStack;
print "ok 15\n";

my $pixelsStack = $pixROI->GetROI (0,0,0,4,0,5,5,5,5,1) || die "Could not allocate buffer\n";
my @testPixStack = unpack ("S*",$pixelsStack);
die "GetPixStack() returned ".scalar(@testPixStack)." pixels, expecting ".scalar(@pixArrayStack).".\n" unless @testPixStack == @pixArrayStack;
for (my $i = 0; $i < @pixArrayStack; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixStack[$i] == $pixArrayStack[$i];
}
print "ok 16\n";

my $pixROI = new OME::Image::Pix ('',5,5,5,5,5,2);
die "not ok 17:  new() Failed to return undef with no path spec." if $pixROI;
print "ok 17\n";

my $pix16 = $pix->GetPlane (10,10,10);
die "not ok 18:  GetPlane Failed to return undef with bogus plane spec." if $pix16;
print "ok 18\n";

my $nOut = $pix->SetPlane ($pix16Plane,10,10,10);
die "not ok 19:  SetPlane Failed to return 0 with bogus plane spec." if $nOut;
print "ok 19\n";

my $pix16 = $pix->GetStack (10,10);
die "not ok 20:  GetStack Failed to return undef with bogus stack spec." if $pix16;
print "ok 20\n";

my $nOut = $pix->SetStack ($pix16Stack,10,10);
die "not ok 21:  SetStack Failed to return 0 with bogus plane spec." if $nOut;
print "ok 21\n";

my $pix16 = $pix->GetROI (0,0,0,4,0,5,10,5,5,1);
die "not ok 22:  GetROI Failed to return 0 with bogus plane spec." if $pix16;
print "ok 22\n";

my $nOut = $pix->SetROI ($pix16ROI,0,0,10,4,0,5,5,5,5,1);
die "not ok 23:  SetROI Failed to return 0 with bogus plane spec." if $nOut;
print "ok 23\n";

my $nOut = $pix->Plane2TIFF (2,2,2,'testTIFF16.tiff');
die "not ok 24:  Plane2TIFF did not write the correct number of pixels." if $nOut != 5*5;
print "ok 24\n";

my $nOut = $pix->Plane2TIFF8 (4,4,4,'testTIFF8.tiff',256/3125,0);
die "not ok 25:  Plane2TIFF did not write the correct number of pixels." if $nOut != 5*5;
print "ok 25\n";
