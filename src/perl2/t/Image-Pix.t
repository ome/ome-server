# -*- perl -*-

# t/040_load.t - check module loading and create testing directory

use Test::More tests => 23;

BEGIN { use_ok( 'OME::Image::Pix' ); }
END {unlink ('pixTest16');unlink('pixTestROI');unlink('pixTestROI2');}


my $nPix = 5*5*5*5*5;
my $pix;
my $pix = new OME::Image::Pix ('pixTest16',5,5,5,5,5,2) || die "Could not instantiate OME::Image::Pix object";
isa_ok ($pix, 'OME::Image::Pix');

my @pixArray = (0..$nPix-1);
my $pix8 = pack("C*",@pixArray);
my $pix16 = pack("S*",@pixArray);
my $nOut = $pix->SetPixels ($pix16);
die "Expecting to write ".scalar (@pixArray)." pixels, wrote $nOut\n" unless $nOut == @pixArray;
ok ($nOut == @pixArray,'Image::Pix->SetPixels()');

my $pixels = $pix->GetPixels () || die "Could not allocate buffer\n";
my @testPix = unpack ("S*",$pixels);
die "GetPix() returned ".scalar(@testPix)." pixels, expecting ".scalar(@pixArray).".\n" unless @testPix == @pixArray;
for (my $i = 0; $i < @pixArray; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPix[$i] == $pixArray[$i];
}
ok (1,'Image::Pix->SetPixels() -> Image::Pix->GetPixels');

my $pixROI = new OME::Image::Pix ('pixTestROI',5,5,5,5,5,2) || die "Could not instantiate OME::Image::Pix object";
my $nPixROI = 5*5*5*5*5;
my @pixArrayROI = (0..$nPixROI-1);
my $pix16ROI = pack("S*",@pixArrayROI);
my $nOutROI = $pixROI->SetROI ($pix16ROI,0,0,0,0,0,5,5,5,5,5);
die "Expecting to write ".scalar (@pixArrayROI)." pixels, wrote $nOutROI\n" unless $nOutROI == @pixArrayROI;
ok (1,'Image::Pix->SetROI()');

my $pixelsROI = $pixROI->GetPixels () || die "Could not allocate buffer for ROI\n";
my @testPixROI = unpack ("S*",$pixelsROI);
die "GetPix() returned ".scalar(@testPixROI)." pixels, expecting ".scalar(@pixArray).".\n" unless @testPixROI == @pixArray;
for (my $i = 0; $i < @pixArray; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixROI[$i] == $pixArray[$i];
}
ok (1,'Image::Pix->SetROI() -> Image::Pix->GetPixels()');

my $pixROI = new OME::Image::Pix ('pixTestROI2',5,5,5,5,5,2) || die "Could not instantiate OME::Image::Pix object\n";
my $nPixROI = 2*2*2*2*2;
my @pixArrayROI = (0..$nPixROI-1);
my $pix16ROI = pack("S*",@pixArrayROI);
my $nOutROI = $pixROI->SetROI ($pix16ROI,1,1,1,1,1,3,3,3,3,3);
die "Expecting to write ".scalar (@pixArrayROI)." pixels, wrote $nOutROI\n" unless $nOutROI == @pixArrayROI;
ok (1,'Image::Pix->SetROI()');

my $pixelsROI = $pixROI->GetROI (1,1,1,1,1,3,3,3,3,3) || die "Could not allocate buffer\n";
my @testPixROI = unpack ("S*",$pixelsROI);
die "GetPixROI() returned ".scalar(@testPixROI)." pixels, expecting ".scalar(@pixArrayROI).".\n" unless @testPixROI == @pixArrayROI;
for (my $i = 0; $i < @pixArrayROI; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixROI[$i] == $pixArrayROI[$i];
}
ok (1,'Image::Pix->SetROI() -> GetROI');

my $nPixPlane = 5*5;
my @pixArrayPlane = (0..$nPixPlane-1);
my $pix16Plane = pack("S*",@pixArrayPlane);
my $nOutPlane = $pixROI->SetROI ($pix16Plane,0,0,4,1,1,5,5,5,2,2);
die "Expecting to write ".scalar (@pixArrayPlane)." pixels, wrote $nOutPlane\n" unless $nOutPlane == @pixArrayPlane;
ok (1,'Image::Pix->SetROI()');

my $pixelsPlane = $pixROI->GetPlane (4,1,1) || die "Could not allocate buffer\n";
my @testPixPlane = unpack ("S*",$pixelsPlane);
die "GetPixPlane() returned ".scalar(@testPixPlane)." pixels, expecting ".scalar(@pixArrayPlane).".\n" unless @testPixPlane == @pixArrayPlane;
for (my $i = 0; $i < @pixArrayPlane; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixPlane[$i] == $pixArrayPlane[$i];
}
ok (1,'Image::Pix->SetROI() -> Image::Pix->GetPlane()');

my $nPixStack = 5*5*5;
my @pixArrayStack = (0..$nPixStack-1);
my $pix16Stack = pack("S*",@pixArrayStack);
my $nOutStack = $pixROI->SetROI ($pix16Stack,0,0,0,2,2,5,5,5,3,3);
die "Expecting to write ".scalar (@pixArrayStack)." pixels, wrote $nOutStack\n" unless $nOutStack == @pixArrayStack;
ok (1,'Image::Pix->SetROI()');

my $pixelsStack = $pixROI->GetStack (2,2) || die "Could not allocate buffer\n";
my @testPixStack = unpack ("S*",$pixelsStack);
die "GetPixStack() returned ".scalar(@testPixStack)." pixels, expecting ".scalar(@pixArrayStack).".\n" unless @testPixStack == @pixArrayStack;
for (my $i = 0; $i < @pixArrayStack; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixStack[$i] == $pixArrayStack[$i];
}
ok (1,'Image::Pix->GetStack()');

my $nPixPlane = 5*5;
my @pixArrayPlane = (0..$nPixPlane-1);
my $pix16Plane = pack("S*",@pixArrayPlane);
my $nOutPlane = $pixROI->SetPlane ($pix16Plane,4,4,3);
die "Expecting to write ".scalar (@pixArrayPlane)." pixels, wrote $nOutPlane\n" unless $nOutPlane == @pixArrayPlane;
ok (1,'Image::Pix->SetPlane()');

my $pixelsPlane = $pixROI->GetROI (0,0,4,4,3,5,5,5,5,4) || die "Could not allocate buffer\n";
my @testPixPlane = unpack ("S*",$pixelsPlane);
die "GetPixPlane() returned ".scalar(@testPixPlane)." pixels, expecting ".scalar(@pixArrayPlane).".\n" unless @testPixPlane == @pixArrayPlane;
for (my $i = 0; $i < @pixArrayPlane; $i++) {
	die "GetPixPlane() returned different pixels than SetPix(). Index=$i\n" unless $testPixPlane[$i] == $pixArrayPlane[$i];
}
ok (1,'Image::Pix->SetPlane() -> GetROI()');

my $nPixStack = 5*5*5;
my @pixArrayStack = (0..$nPixStack-1);
my $pix16Stack = pack("S*",@pixArrayStack);
my $nOutStack = $pixROI->SetStack ($pix16Stack,4,0);
die "Expecting to write ".scalar (@pixArrayStack)." pixels, wrote $nOutStack\n" unless $nOutStack == @pixArrayStack;
ok (1,'Image::Pix->SetStack()');

my $pixelsStack = $pixROI->GetROI (0,0,0,4,0,5,5,5,5,1) || die "Could not allocate buffer\n";
my @testPixStack = unpack ("S*",$pixelsStack);
die "GetPixStack() returned ".scalar(@testPixStack)." pixels, expecting ".scalar(@pixArrayStack).".\n" unless @testPixStack == @pixArrayStack;
for (my $i = 0; $i < @pixArrayStack; $i++) {
	die "GetPix() returned different pixels than SetPix(). Index=$i\n" unless $testPixStack[$i] == $pixArrayStack[$i];
}
ok (1,'Image::Pix->SetStack() -> GetROI()');

my $pixROI = new OME::Image::Pix ('',5,5,5,5,5,2);
die "not ok 17:  new() Failed to return undef with no path spec." if $pixROI;
ok (1,'Image::Pix->new() with empty path spec (fault test)');

my $pix16 = $pix->GetPlane (10,10,10);
die "not ok 18:  GetPlane Failed to return undef with bogus plane spec." if $pixROI;
ok (1,'Image::Pix->GetPlane() with bogus plane spec');

my $nOut = $pix->SetPlane ($pix16Plane,10,10,10);
die "not ok 19:  SetPlane Failed to return 0 with bogus plane spec." if $pixROI;
ok (1,'Image::Pix->SetPlane() with bogus plane spec');

my $pix16 = $pix->GetStack (10,10);
die "not ok 20:  GetStack Failed to return undef with bogus stack spec." if $pixROI;
ok (1,'Image::Pix->GetStack() with bogus stack spec');

my $nOut = $pix->SetStack ($pix16Stack,10,10);
die "not ok 21:  SetStack Failed to return 0 with bogus plane spec." if $pixROI;
ok (1,'Image::Pix->SetStack() with bogus stack spec');

my $pix16 = $pix->GetROI (0,0,0,4,0,5,10,5,5,1);
die "not ok 22:  GetROI Failed to return 0 with bogus plane spec." if $pixROI;
ok (1,'Image::Pix->GetROI() with bogus ROI');

my $nOut = $pix->SetROI ($pix16ROI,0,0,10,4,0,5,5,5,5,1);
die "not ok 23:  SetROI Failed to return 0 with bogus plane spec." if $pixROI;
ok (1,'Image::Pix->SetROI() with bogus ROI');
