# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded; unlink ('pixTest16');unlink('pixTestROI');unlink('pixTestROI2');}
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
my $nOut = $pix->SetPix ($pix16);
die "Expecting to write ".scalar (@pixArray)." pixels, wrote $nOut\n" unless $nOut == @pixArray;
print "ok 3\n";

my $pixels = $pix->GetPix () || die "Could not allocate buffer\n";
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
my $nOutROI = $pixROI->SetPixROI ($pix16ROI,0,0,0,0,0,5,5,5,5,5);
die "Expecting to write ".scalar (@pixArrayROI)." pixels, wrote $nOutROI\n" unless $nOutROI == @pixArrayROI;
print "ok 5\n";

my $pixelsROI = $pixROI->GetPix () || die "Could not allocate buffer for ROI\n";
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
my $nOutROI = $pixROI->SetPixROI ($pix16ROI,1,1,1,1,1,3,3,3,3,3);
die "Expecting to write ".scalar (@pixArrayROI)." pixels, wrote $nOutROI\n" unless $nOutROI == @pixArrayROI;
print "ok 7\n";

my $pixelsROI = $pixROI->GetPixROI (1,1,1,1,1,3,3,3,3,3) || die "Could not allocate buffer\n";
my @testPixROI = unpack ("S*",$pixelsROI);
die "GetPixROI() returned ".scalar(@testPixROI)." pixels, expecting ".scalar(@pixArrayROI).".\n" unless @testPixROI == @pixArrayROI;
for (my $i = 0; $i < @pixArrayROI; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixROI[$i] == $pixArrayROI[$i];
}
print "ok 8\n";

my $nPixPlane = 5*5;
my @pixArrayPlane = (0..$nPixPlane-1);
my $pix16Plane = pack("S*",@pixArrayPlane);
my $nOutPlane = $pixROI->SetPixROI ($pix16Plane,0,0,4,1,1,5,5,5,2,2);
die "Expecting to write ".scalar (@pixArrayPlane)." pixels, wrote $nOutPlane\n" unless $nOutPlane == @pixArrayPlane;
print "ok 9\n";

my $pixelsPlane = $pixROI->GetPixPlane (4,1,1) || die "Could not allocate buffer\n";
my @testPixPlane = unpack ("S*",$pixelsPlane);
die "GetPixPlane() returned ".scalar(@testPixPlane)." pixels, expecting ".scalar(@pixArrayPlane).".\n" unless @testPixPlane == @pixArrayPlane;
for (my $i = 0; $i < @pixArrayPlane; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixPlane[$i] == $pixArrayPlane[$i];
}
print "ok 10\n";

my $nPixStack = 5*5*5;
my @pixArrayStack = (0..$nPixStack-1);
my $pix16Stack = pack("S*",@pixArrayStack);
my $nOutStack = $pixROI->SetPixROI ($pix16Stack,0,0,0,2,2,5,5,5,3,3);
die "Expecting to write ".scalar (@pixArrayStack)." pixels, wrote $nOutStack\n" unless $nOutStack == @pixArrayStack;
print "ok 11\n";

my $pixelsStack = $pixROI->GetPixStack (2,2) || die "Could not allocate buffer\n";
my @testPixStack = unpack ("S*",$pixelsStack);
die "GetPixStack() returned ".scalar(@testPixStack)." pixels, expecting ".scalar(@pixArrayStack).".\n" unless @testPixStack == @pixArrayStack;
for (my $i = 0; $i < @pixArrayStack; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixStack[$i] == $pixArrayStack[$i];
}
print "ok 12\n";

my $nPixPlane = 5*5;
my @pixArrayPlane = (0..$nPixPlane-1);
my $pix16Plane = pack("S*",@pixArrayPlane);
my $nOutPlane = $pixROI->SetPixPlane ($pix16Plane,4,4,3);
die "Expecting to write ".scalar (@pixArrayPlane)." pixels, wrote $nOutPlane\n" unless $nOutPlane == @pixArrayPlane;
print "ok 13\n";

my $pixelsPlane = $pixROI->GetPixROI (0,0,4,4,3,5,5,5,5,4) || die "Could not allocate buffer\n";
my @testPixPlane = unpack ("S*",$pixelsPlane);
die "GetPixPlane() returned ".scalar(@testPixPlane)." pixels, expecting ".scalar(@pixArrayPlane).".\n" unless @testPixPlane == @pixArrayPlane;
for (my $i = 0; $i < @pixArrayPlane; $i++) {
	die "GetPixPlane() returned different pixels than SetPix(). Index=$i\n" unless $testPixPlane[$i] == $pixArrayPlane[$i];
}
print "ok 14\n";

my $nPixStack = 5*5*5;
my @pixArrayStack = (0..$nPixStack-1);
my $pix16Stack = pack("S*",@pixArrayStack);
my $nOutStack = $pixROI->SetPixStack ($pix16Stack,4,0);
die "Expecting to write ".scalar (@pixArrayStack)." pixels, wrote $nOutStack\n" unless $nOutStack == @pixArrayStack;
print "ok 15\n";

my $pixelsStack = $pixROI->GetPixROI (0,0,0,4,0,5,5,5,5,1) || die "Could not allocate buffer\n";
my @testPixStack = unpack ("S*",$pixelsStack);
die "GetPixStack() returned ".scalar(@testPixStack)." pixels, expecting ".scalar(@pixArrayStack).".\n" unless @testPixStack == @pixArrayStack;
for (my $i = 0; $i < @pixArrayStack; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixStack[$i] == $pixArrayStack[$i];
}
print "ok 16\n";
