package OME::Image::Pix;

require 5.005;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use OME::Image::Pix ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ();

our @EXPORT_OK = ();

our @EXPORT = ();
our $VERSION = '1.00';

bootstrap OME::Image::Pix $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

OME::Image::Pix - A Perl interface to the OME libpix library

=head1 SYNOPSIS

  use OME::Image::Pix;
  my $pix = new OME::Image::Pix ('/OME/repository/123456.orf',
  	$sizeX,$sizeY,$sizeZ,$numWaves,$numTimes,$bytesPerPixel)
  	|| die "Could not instantiate OME::Image::Pix object";

  # Get the entire 5-D image
  my $pixels = $pix->GetPix () || die "Could not allocate buffer\n";

  # The returned scalar can be unpacked into an array.  This is probably never a good idea:
  my @pixArray = unpack ("S*",$pixels);

  # Get an XY plane of pixels by specifying theZ, theW, and theT
  my $plane = $pix->GetPixPlane (4,1,1) || die "Could not allocate buffer\n";

  # Get an XYZ stack of pixels by specifying theW, and theT
  my $stack = $pix->GetPixStack (3,4) || die "Could not allocate buffer\n";

  # Get a 5D ROI by specifying x0,y0,z0,w0,t0,x1,y1,z1,w1,t1
  my $ROI = $pix->GetPixROI (1,1,1,1,1,3,3,3,3,3) || die "Could not allocate buffer\n";


  # Set the entire 5-D image.
  # $nPixOut is the number of pixels written to the file.  This value should be checked.
  my $nPixOut = $pix->SetPix ($pixels);

  # Set an XY plane of pixels by specifying theZ, theW, and theT
  my $nPixOut = $pix->SetPixPlane ($plane,4,1,2) || die "Could not allocate buffer\n";

  # Set an XYZ stack of pixels by specifying theW, and theT
  my $nPixOut = $pix->SetPixStack ($stack,0,4) || die "Could not allocate buffer\n";

  # Set a 5D ROI by specifying x0,y0,z0,w0,t0,x1,y1,z1,w1,t1
  my $nPixOut = $pix->SetPixROI ($ROI,3,3,3,3,3,5,5,5,5,5) || die "Could not allocate buffer\n";


=head1 DESCRIPTION

This is implemented by blessing the C struct used in libpix (returned by libpix->new())
into the Perl class OME::Image::Pix.
The purpose of this class is to provide some pixel get/set and manipulation methods implemented in C.
This package should really only be used by OME::Image.  It is fully independent of it, but not very useful without it.

=head2 EXPORT

Nothing is exported.


=head1 AUTHOR

Ilya G. Goldberg (igg@nih.gov)

=head1 SEE ALSO

OME::Image.

=cut
