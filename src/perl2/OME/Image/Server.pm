# OME/Image/Server.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------




#-------------------------------------------------------------------------------
#
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------

package OME::Image::Server;

=head1 NAME

OME::Image::Server - interface into the OME Image Server

=head1 SYNOPSIS

	use OME::Image;

	# Acquire a factory from your session. See OME::Session for more details

	# Load an image
	my $image = $factory->loadObject( OME::Image, $imageID );

	# Load an OME::Image::Pix object
	# acquire a Pixels attribute
	my $pix = $image->GetPix( $pixels );

=head1 DESCRIPTION

This class provides a Perl interface into the OME image server.

=head2 Local vs. remote installations

The default behavior of the image server is to communicate via HTTP,
allowing the image server and any client code to reside on different
computers.  However, if it is known that the image server is running
on the same machine as the client code, a performance increase can be
gained by calling the image server directly.  In this case, the
communication with the server uses the standard input/output pipes
provided by the OS.

Client code can switch between using a local or remote installation
via the C<useLocalServer> and C<useRemoteServer> methods.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use English '-no_match_vars';
use URI;
use HTTP::Request::Common;
use LWP::UserAgent;

our $SHOW_CALLS = 0;

=head1 CONSTANTS

The following constants are used by this class.

=head2 DEFAULT_LOCAL_PATH

	my $path = OME::Image::Server::DEFAULT_LOCAL_PATH;
	# defaults to "/OME/bin/omeis"

Stores the default location of a local installation of the image
server.  If this class is configured to use a local image server, but
no path to the omeis executable is specified, this path will be used.

=head2 DEFAULT_REMOTE_URL

	my $url = OME::Image::Server::DEFAULT_REMOTE_URL;
	# defaults to URI->new("http://localhost/cgi-bin/omeis")

Stores the default location of a remote installation of the image
server.  If this class is configured to use a remote image server, but
no omeis URL is specified, this URL will be used.

=cut

use constant DEFAULT_LOCAL_PATH => '/OME/bin/omeis';
use constant DEFAULT_REMOTE_URL =>
  URI->new('http://localhost/cgi-bin/omeis');

# Class defaults to a remote installation found at DEFAULT_REMOTE_URL

my $local_server = 0;
my $server_path = DEFAULT_REMOTE_URL;
my $user_agent;

=head1 METHODS

=head2 useLocalServer

	OME::Image::Server->useLocalServer($path);

Causes the various omeis methods to use a local installation of the
image server.  The path to the image server executable should be given
as a parameter; if it is not given, the DEFAULT_LOCAL_PATH constant
will be used.  If the specified (or default) path is not an executable
file, this method will throw an error.

=cut

sub useLocalServer {
    my $proto = shift;
    my $path = shift || DEFAULT_LOCAL_PATH;

    die "$path is not a valid executable file"
      unless -x $path;

    $local_server = 1;
    $server_path = $path;
}

=head2 useRemoteServer

	OME::Image::Server->useRemoteServer($url);

Causes the various omeis methods to use a remote installation of the
image server.  The URL to the image server should be given
as a parameter; if it is not given, the DEFAULT_REMOTE_URL constant
will be used.

=cut

sub useRemoteServer {
    my $proto = shift;
    my $url = shift || DEFAULT_REMOTE_URL;

    $url = URI->new($url) unless ref($url);
    die "Could not create a URI for the remote image server"
      unless defined($url) && UNIVERSAL::isa($url,"URI");

    print STDERR ref($url)," $url\n";

    $local_server = 0;
    $server_path = $url;
}

=head2 __safeBacktick

	my $stdout = __safeBacktick($cmd,@args);

This function is equivalent to the backtick operator, but makes
several security-related precautions as outlined in the perlsec
manpage.  This includes dropping any setuid privileges the script
might have, and cleaning up the environment before calling the
program.  It also bypasses shell expansion of the command and
arguments.

Be careful if you expect the program to return a large amount of data
on STDOUT; just like the backtick operator, Perl will load all of this
data into a single scalar variable, possibly causing a severe case of
memory bloat.

=cut

sub __safeBacktick {
    # This is copied out of the perlsec manpage.

    my $pid;
    die "Can't fork: $!" unless defined ($pid = open(KID,"-|"));
    if ($pid) {
        # Parent process

        local($/) = undef;  # slurp in the entire contents of the pipe
        my $result = <KID>;
        close KID;
        return $result;
    } else {
        # Child process

        my @temp = ($EUID,$EGID);
        my $orig_uid = $UID;
        my $orig_gid = $GID;
        $EUID = $UID;
        $EGID = $GID;

        # Drop privileges
        $UID = $orig_uid;
        $GID = $orig_gid;

        # Make sure privileges are really gone
        ($EUID,$EGID) = @temp;
        die "Can't drop privileges"
          unless $UID == $EUID && $GID eq $EGID;

        # Sanitize the environment
        $ENV{PATH} = "/bin:/usr/bin";
        delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

        # The indirect object form of the exec call forces @_ to be
        # executed directly, without passing it to the shell for
        # wildcard expansion etc.
        exec {$_[0]} @_ or die "Can't exec: $!";
    }
}

=head2 __createUserAgent

	OME::Image::Server->__createUserAgent();

This method is used to instantiate the private class variable
$user_agent.  This is an instance of the C<LWP::UserAgent> class, and
is used to perform the actual HTTP communication of a remote image
server call.  It should never be called from client code; it is called
as necessary by the C<__callOMEIS> method, which is called by all of
the image server methods.

=cut

sub __createUserAgent {
    my $proto = shift;

    $user_agent = LWP::UserAgent->new();
}

=head2 __callOMEIS

	my $result = OME::Image::Server->__callOMEIS(%params);

This method makes a call into the image server.  If the class has been
configured to use a local copy of the image server (with the
C<useLocalServer> method), the call will be made via the equivalent of
the Perl backtick operator.  (It actually uses the C<__safeBacktick>
method, which performs some additional security checks before calling
the external program.)  If the class has been configured to use a
remote copy of the image server (with the C<useRemoteServer> method),
the call will be made via an HTTP connection.

The parameters to the image server are specified in the %params hash.
The "Method" parameter is always required; other parameters might also
be needed, depending on the particular image server method being
called.

In particular, the "UploadFile" and "Set*" methods require binary data
(either an original image file, or a block of pixels) to be sent to
the image server.  Currently, the only supported way of specifying
this data is with a filename.  These methods expect the binary data to
be in either the "File" or "Pixels" parameter, and no other methods
use a parameter of this name.  Therefore, this method will
automatically assume that any value for the "File" or "Pixels"
parameter is a filename, and send that file to the image server.  (For
local installations, the filename is sent, and the image server reads
the file directly.  For remote installations, the file is sent via a
multi-part form POST.)  These methods will also assume that an
"UploadSize" parameter is present, containing the length of the
external file; this value will be automatically calculated and placed
into the parameter hash before making the method call.

The result of the method will be the text that was printed to stdout
by the image server.  The server will format this as an HTTP response,
but this method will strip any HTTP header before returning the
result.

=cut

sub __callOMEIS {
    my $proto = shift;
    my %params = @_;

    if ($local_server) {
        # If there is a File or Pixels parameter, pull it out of the
        # %params hash, and save the filename.  We also calculate the
        # size of the specified file (dying if it doesn't exist), and
        # save a new parameter called UploadSize with this value.  We
        # will then pipe the file into the image server over stdin.
        # (The two shouldn't ever both appear, but if they do, both
        # will be removed, and the Pixels parameter will be sent to the
        # server.)

        my $stdin_filename;
        my $stdin_size;

        if (exists $params{File}) {
            $stdin_filename = $params{File};
        }

        if (exists $params{Pixels}) {
            $stdin_filename = $params{Pixels};
        }

        if (defined $stdin_filename) {
            die "Cannot find file $stdin_filename"
              unless -r $stdin_filename;
            $stdin_size = -s $stdin_filename;
            $params{UploadSize} = $stdin_size;
            $params{IsLocalFile} = 1;
        }

        my @params;
        while (my ($k,$v) = each %params) {
            push @params, "$k=$v";
        }

        if ($SHOW_CALLS) {
            print STDERR "Calling local OMEIS: $server_path\n";
            print STDERR "  Params: ",join(' ',@params),"\n";
        }

        my $result = __safeBacktick($server_path,@params);
        if ($result =~ /Status: 500 (.*?)\015?\012/) {
            # There was a problem reported as an HTTP error
            die $1;
        } else {
            # Remove the HTTP header from the result
            $result =~ s/^.*?\015?\012\015?\012//s;
        }
        return $result;
    } else {
        # The File and/or Pixels parameters should be transformed into
        # the appropriate filename reference for the POST request.

        $params{File} = [$params{File}]
          if (exists $params{File});

        $params{Pixels} = [$params{Pixels}]
          if (exists $params{Pixels});

        # This prevents the request object created below from loading
        # the entire file into memory.  Since the images could easily
        # run to 1GB in size, this is quite necessary.
        $HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

        my $request =
          POST($server_path,
               Content_Type => 'form-data',
               Content      => \%params);

        if ($SHOW_CALLS) {
            print STDERR "Calling remote OMEIS: $server_path\n";
            print STDERR "  Params: ",join(' ',keys %params),"\n";
        }

        $proto->__createUserAgent() unless defined $user_agent;
        my $response = $user_agent->request($request);

        if ($response->is_success()) {
            return $response->content();
        } else {
            die $response->message();
        }
    }
}

=head2 newPixels

	my $pixelsID = OME::Image::Server->
	    newPixels($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,
	              $bytesPerPixel,$isSigned,$isFloat);

Creates a new pixels file on the image server.  The dimensions of the
pixels must be known beforehand, and must be specified to this method.
All of the dimensions must be positive integers.

Each pixel in the new file must have the same storage type.  This type
is specified by the $bytesPerPixel, $isSigned, and $isFloat
parameters.

This method returns the pixels ID generated by the image server.  Note
that this is not the same as the attribute ID of a Pixels attribute.
The pixels ID can be used in the get*, set*, and convert* methods
(among others) to perform pixel I/O with the image server.

The new pixels file will be created in write-only mode.  The set* and
convert* methods should be used to populate the pixel array.  Once the
array is fully populated, the finishPixels method should be used to
place the file in read-only mode.  At this point, the get* methods can
be called to retrieve the pixels.

=cut

sub newPixels {
    my $proto = shift;
    my ($sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,
        $bytesPerPixel,$isSigned,$isFloat) = @_;
    my $dims = "$sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,$bytesPerPixel";
    my $result = $proto->__callOMEIS(Method   => 'NewPixels',
                                     Dims     => $dims,
                                     IsSigned => $isSigned,
                                     IsFloat  => $isFloat);
    die "Error creating pixels" unless defined $result;
    chomp($result);
    die "Error creating pixels" unless $result > 0;
    return $result;
}

=head2 getPixels

	my $pixels = OME::Image::Server->getPixels($pixelsID,$bigEndian);

This method returns the entire pixel file for the given pixel ID.  Be
very careful, these can easily be friggin-huge in size.  You probably
don't ever want to call this method, unless you've made the
appropriate checks on the dimensions of the pixels to ensure that it
won't be too large.

You should also specify whether you want to receive a big-endian or
little-endian pixel array.  The image server will take care of
performing the appropriate conversion for you.  If the endian-ness is
not specified, it will default to network-order (big-endian).  Intel
boxes are little-endian, so the default might not be what you want.

If the specified pixel file isn't in read-only mode on the image
server, an error will be thrown.

=cut

sub getPixels {
    my $proto = shift;
    my ($pixelsID,$bigEndian) = @_;
    my %params = (Method   => 'GetPixels',
                  PixelsID => $pixelsID);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error retrieving pixels" unless defined $result;
    return $result;
}

=head2 getStack

	my $pixels = OME::Image::Server->
	    getStack($pixelsID,$theC,$theT,$bigEndian);

This method returns a pixel array of the specified stack.  The stack
is specified by its C and T coordinates, which have 0-based indices.
While this method is less likely to be a memory hog as the getPixels
method, it is still possible for large images with few timepoints to
cause problems.  As usual when dealing with large images, care must be
taken to use your computational resources appropriately.

You should also specify whether you want to receive a big-endian or
little-endian pixel array.  The image server will take care of
performing the appropriate conversion for you.  If the endian-ness is
not specified, it will default to network-order (big-endian).  Intel
boxes are little-endian, so the default might not be what you want.

If the specified pixel file isn't in read-only mode on the image
server, an error will be thrown.

=cut

sub getStack {
    my $proto = shift;
    my ($pixelsID,$theC,$theT,$bigEndian) = @_;
    my %params = (Method   => 'GetStack',
                  PixelsID => $pixelsID,
                  theC     => $theC,
                  theT     => $theT);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error retrieving pixels" unless defined $result;
    return $result;
}

=head2 getPlane

	my $pixels = OME::Image::Server->
	    getPlane($pixelsID,$theZ,$theC,$theT,$bigEndian);

This method returns a pixel array of the specified plane.  The plane
is specified by its Z, C and T coordinates, which have 0-based
indices.  While this method is the least likely to be a memory hog,
care must still be taken to use your computational resources
appropriately.

You should also specify whether you want to receive a big-endian or
little-endian pixel array.  The image server will take care of
performing the appropriate conversion for you.  If the endian-ness is
not specified, it will default to network-order (big-endian).  Intel
boxes are little-endian, so the default might not be what you want.

If the specified pixel file isn't in read-only mode on the image
server, an error will be thrown.

=cut

sub getPlane {
    my $proto = shift;
    my ($pixelsID,$theZ,$theC,$theT,$bigEndian) = @_;
    my %params = (Method   => 'GetPlane',
                  PixelsID => $pixelsID,
                  theZ     => $theZ,
                  theC     => $theC,
                  theT     => $theT);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error retrieving pixels" unless defined $result;
    return $result;
}

=head2 getROI

	my $pixels = OME::Image::Server->
	    getROI($pixelsID,
	           $x0,$y0,$z0,$c0,$t0,
	           $x1,$y1,$z1,$c1,$t1,
	           $bigEndian);

This method returns a pixel array of an arbitrary hyper-rectangular
region of an image.  The region is specified by two coordinate
vectors, which have 0-based indices.  The region boundaries must be
well formed.  (Each coordinate must be within the range of valid
values for that dimension, and each "0" coordinate must be less than
or equal to the respective "1" coordinate.)

You should also specify whether you want to receive a big-endian or
little-endian pixel array.  The image server will take care of
performing the appropriate conversion for you.  If the endian-ness is
not specified, it will default to network-order (big-endian).  Intel
boxes are little-endian, so the default might not be what you want.

If the specified pixel file isn't in read-only mode on the image
server, an error will be thrown.

=cut

sub getROI {
    my $proto = shift;
    my ($pixelsID,
        $x0,$y0,$z0,$c0,$t0,
        $x1,$y1,$z1,$c1,$t1,
        $bigEndian) = @_;
    my $ROI = "$x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1";
    my %params = (Method   => 'GetROI',
                  PixelsID => $pixelsID,
                  ROI      => $ROI);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error retrieving pixels" unless defined $result;
    return $result;
}

=head2 setPixels

	my $bytesWritten = OME::Image::Server->
	    setPixels($pixelsID,$filename,$bigEndian);

This method sends an entire array of pixels for the given pixels ID.
The pixels are specified by an external file, which should be a raw
pixel dump.  The endian-ness of the pixels in this file should be
specified; if no value is given for the $bigEndian parameter, network
order (big-endian) is assumed.

If the specified pixel file isn't in write-only mode on the image
server, an error will be thrown.

The number of bytes successfully written by the image server will be
returned.  This value can be used as an additional error check by
client code.

=cut

sub setPixels {
    my $proto = shift;
    my ($pixelsID,$filename,$bigEndian) = @_;
    my %params = (Method   => 'SetPixels',
                  PixelsID => $pixelsID,
                  Pixels   => $filename);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error sending pixels" unless defined $result;
    chomp $result;
    return $result;
}

=head2 setStack

	my $bytesWritten = OME::Image::Server->
	    setStack($pixelsID,$theC,$theT,$filename,$bigEndian);

This method sends an array of pixels for a single stack of the given
pixels ID.  The stack is specified by its C and T coordinates, which
have 0-based indices.  The pixels are specified by an external file,
which should be a raw pixel dump.  The endian-ness of the pixels in
this file should be specified; if no value is given for the $bigEndian
parameter, network order (big-endian) is assumed.

If the specified pixel file isn't in write-only mode on the image
server, an error will be thrown.

The number of bytes successfully written by the image server will be
returned.  This value can be used as an additional error check by
client code.

=cut

sub setStack {
    my $proto = shift;
    my ($pixelsID,$theC,$theT,$filename,$bigEndian) = @_;
    my %params = (Method   => 'SetStack',
                  PixelsID => $pixelsID,
                  Pixels   => $filename,
                  theC     => $theC,
                  theT     => $theT);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error sending pixels" unless defined $result;
    chomp $result;
    return $result;
}

=head2 setPlane

	my $bytesWritten = OME::Image::Server->
	    setPlane($pixelsID,$theZ,$theC,$theT,$filename,$bigEndian);

This method sends an array of pixels for a single plane of the given
pixels ID.  The plane is specified by its Z, C and T coordinates,
which have 0-based indices.  The pixels are specified by an external
file, which should be a raw pixel dump.  The endian-ness of the pixels
in this file should be specified; if no value is given for the
$bigEndian parameter, network order (big-endian) is assumed.

If the specified pixel file isn't in write-only mode on the image
server, an error will be thrown.

The number of bytes successfully written by the image server will be
returned.  This value can be used as an additional error check by
client code.

=cut

sub setPlane {
    my $proto = shift;
    my ($pixelsID,$theZ,$theC,$theT,$filename,$bigEndian) = @_;
    my %params = (Method   => 'SetPlane',
                  PixelsID => $pixelsID,
                  Pixels   => $filename,
                  theZ     => $theZ,
                  theC     => $theC,
                  theT     => $theT);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error sending pixels" unless defined $result;
    chomp $result;
    return $result;
}

=head2 setROI

	my $pixels = OME::Image::Server->
	    setROI($pixelsID,
	           $x0,$y0,$z0,$c0,$t0,
	           $x1,$y1,$z1,$c1,$t1,
	           $filename,
	           $bigEndian);

This method sends an array of pixels for an arbitrary
hyper-rectangular region of the given pixels ID.  The region is
specified by two coordinate vectors, which have 0-based indices.  The
region boundaries must be well formed.  (Each coordinate must be
within the range of valid values for that dimension, and each "0"
coordinate must be less than or equal to the respective "1"
coordinate.)  The pixels are specified by an external file, which
should be a raw pixel dump.  The endian-ness of the pixels in this
file should be specified; if no value is given for the $bigEndian
parameter, network order (big-endian) is assumed.

If the specified pixel file isn't in write-only mode on the image
server, an error will be thrown.

The number of bytes successfully written by the image server will be
returned.  This value can be used as an additional error check by
client code.

=cut

sub setROI {
    my $proto = shift;
    my ($pixelsID,
        $x0,$y0,$z0,$c0,$t0,
        $x1,$y1,$z1,$c1,$t1,
        $filename,
        $bigEndian) = @_;
    my $ROI = "$x0,$y0,$z0,$c0,$t0,$x1,$y1,$z1,$c1,$t1";
    my %params = (Method   => 'SetROI',
                  PixelsID => $pixelsID,
                  Pixels   => $filename,
                  ROI      => $ROI);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error sending pixels" unless defined $result;
    chomp $result;
    return $result;
}

=head2 uploadFile

	my $fileID = OME::Image::Server->uploadFile($filename);

Transfers the specified file to the image server, returning a file ID.
This ID can then be used in calls to the convert* methods, allowing a
new pixels file to be created from the contents of the original file.
If there is an error calling the image server, this method will die.

=cut

sub uploadFile {
    my $proto = shift;
    my ($filename) = @_;
    my $result = $proto->__callOMEIS(Method => 'UploadFile',
                                     File   => $filename);
    die "Error uploading file" unless defined $result;
    chomp($result);
    die "Error uploading file" unless $result > 0;
    return $result;
}

=head2 getFileInfo

	my ($filename,$length) = OME::Image::Server->getFileInfo($fileID);

This method returns the original filename and the length of a
previously uploaded file.

=cut

sub getFileInfo {
    my $proto = shift;
    my ($fileID) = @_;
    my $result = $proto->__callOMEIS(Method => 'FileInfo',
                                     FileID => $fileID);
    die "Error retrieving file info" unless defined $result;
    die "Unexpected return result"
      unless $result =~ /^Name=(.*?)\015?\012Length=(.*?)\015?\012/;
    return ($1,$2);
}

=head2 convertStack

	my $bytesWritten = OME::Image::Server->
	    convertStack($pixelsID,$theC,$theT,
	                 $filesID,$offset,$bigEndian);

Copies pixels from an original file into a new pixels file.  The
original file should have been previously uploaded via the uploadFile
method.  The pixels file should have been previously created via the
newPixels method.  The server will start reading the pixels from the
specified offset, which should be expressed as bytes from the
beginning of the file.

This method copies a single XYZ stack of pixels.  The pixels in the
original file should be in XYZ order, and should match the storage
type declared for the new pixels file.  The stack is specified by its
C and T coordinates, which have 0-based indices.  The endian-ness of
the uploaded file should be specified; if this differs from the
declared endian-ness of the new pixels file, byte swapping will be
performed by the server.

If the specified pixel file isn't in write-only mode on the image
server, an error will be thrown.

The number of bytes successfully written by the image server will be
returned.  This value can be used as an additional error check by
client code.

=cut

sub convertStack {
    my $proto = shift;
    my ($pixelsID,$theC,$theT,
        $fileID,$offset,$bigEndian) = @_;
    my %params = (Method   => 'ConvertStack',
                  PixelsID => $pixelsID,
                  theC     => $theC,
                  theT     => $theT,
                  FileID   => $fileID,
                  Offset   => $offset);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error converting pixels" unless defined $result;
    chomp $result;
    return $result;
}

=head2 convertPlane

	my $bytesWritten = OME::Image::Server->
	    convertPlane($pixelsID,$theZ,$theC,$theT,
	                 $fileID,$offset,$bigEndian);

Copies pixels from an original file into a new pixels file.  The
original file should have been previously uploaded via the uploadFile
method.  The pixels file should have been previously created via the
newPixels method.  The server will start reading the pixels from the
specified offset, which should be expressed as bytes from the
beginning of the file.

This method copies a single XY plane of pixels.  The pixels in the
original file should be in XY order, and should match the storage type
declared for the new pixels file.  The plane is specified by its Z, C
and T coordinates, which have 0-based indices.  The endian-ness of the
uploaded file should be specified; if this differs from the declared
endian-ness of the new pixels file, byte swapping will be performed by
the server.

If the specified pixel file isn't in write-only mode on the image
server, an error will be thrown.

The number of bytes successfully written by the image server will be
returned.  This value can be used as an additional error check by
client code.

=cut

sub convertPlane {
    my $proto = shift;
    my ($pixelsID,$theZ,$theC,$theT,
        $fileID,$offset,$bigEndian) = @_;
    my %params = (Method   => 'ConvertPlane',
                  PixelsID => $pixelsID,
                  theZ     => $theZ,
                  theC     => $theC,
                  theT     => $theT,
                  FileID   => $fileID,
                  Offset   => $offset);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error converting pixels" unless defined $result;
    chomp $result;
    return $result;
}

=head2 convertRows

	my $bytesWritten = OME::Image::Server->
	    convertRows($pixelsID,$theY,$numRows,$theZ,$theC,$theT,
	                $fileID,$offset,$bigEndian);

Copies pixels from an original file into a new pixels file.  The
original file should have been previously uploaded via the uploadFile
method.  The pixels file should have been previously created via the
newPixels method.  The server will start reading the pixels from the
specified offset, which should be expressed as bytes from the
beginning of the file.

This method copies a subset of rows of a single plane of pixels.  The
pixels in the original file should be in XY order, and should match
the storage type declared for the new pixels file.  The rows are
specified by their Z, C and T coordinates, and by an initial Y
coordinate and number of rows to copy.  All of the coordinates have
0-based indices.  The endian-ness of the uploaded file should be
specified; if this differs from the declared endian-ness of the new
pixels file, byte swapping will be performed by the server.

If the specified pixel file isn't in write-only mode on the image
server, an error will be thrown.

The number of bytes successfully written by the image server will be
returned.  This value can be used as an additional error check by
client code.

=cut

sub convertRows {
    my $proto = shift;
    my ($pixelsID,$theY,$numRows,$theZ,$theC,$theT,
        $fileID,$offset,$bigEndian) = @_;
    my %params = (Method   => 'ConvertRows',
                  PixelsID => $pixelsID,
                  theY     => $theY,
                  nRows    => $numRows,
                  theZ     => $theZ,
                  theC     => $theC,
                  theT     => $theT,
                  FileID   => $fileID,
                  Offset   => $offset);
    $params{BigEndian} = $bigEndian if defined $bigEndian;
    my $result = $proto->__callOMEIS(%params);
    die "Error converting pixels" unless defined $result;
    chomp $result;
    return $result;
}

=head2 finishPixels

	OME::Image::Server->finishPixels($pixelsID);

This method ends the writable phase of the life of a pixels file in
the image server.

Pixels files in the image server can only be written to immediately
after they are created.  Once the pixels file is fully populated, it
is marked as being completed (via this method).  As this point, all of
the writing methods (set*, convert*) become unavailable for the pixels
file, and the reading methods (get*) become available.

=cut

sub finishPixels {
    my $proto = shift;
    my ($pixelsID) = @_;
    my $result = $proto->__callOMEIS(Method   => 'FinishPixels',
                                     PixelsID => $pixelsID);
    die "Error finishing pixels"
      unless defined $result && $result == $pixelsID;
    return;
}

=head2 getPlaneStatistics

	my $statsHash = OME::Image::Server->getPlaneStatistics($pixelsID);

This method returns a hash containing basic pixel statistics for the
specified pixels file.  The hash is of the form:

	$statsHash->{$z}->{$c}->{$t}->{$stat} = $value;

Where $z, $c, and $t are the coordinates of a plane, and $stat has one
of the following values:

	Minimum, Maximum, Mean, Sigma, Geomean, Geosigma,
	CentroidX, CentroidY, SumI, SumI2, SumLogI,
	SumXI, SumYI, SumZI

If the specified pixel file isn't in read-only mode on the image
server, an error will be thrown.

=cut

sub getPlaneStatistics {
    my $proto = shift;
    my ($pixelsID) = @_;
    my $result = $proto->__callOMEIS(Method   => 'GetPlaneStats',
                                     PixelsID => $pixelsID);
    die "Error retrieving statistics" unless defined $result;
    my %hash;

    my @rows = split(/\015?\012/,$result);
    foreach my $row (@rows) {
        my ($c,$t,$z,$min,$max,$mean,$geomean,$sigma,
            $centroidX,$centroidY,$i,$i2,$logI,$xi,$yi,$zi,$geosigma) =
              split(/\t/,$row);
        $hash{$c}{$t}{$z} = {
                             Minimum   => $min,
                             Maximum   => $max,
                             Mean      => $mean,
                             Sigma     => $sigma,
                             Geomean   => $geomean,
                             Geosigma  => $geosigma,
                             CentroidX => $centroidX,
                             CentroidY => $centroidY,
                             SumI      => $i,
                             SumI2     => $i2,
                             SumLogI   => $logI,
                             SumXI     => $xi,
                             SumYI     => $yi,
                             SumZI     => $zi,
                            };
    }

    return \%hash;
}

1;

__END__

=head1 AUTHORS

=over

=item Image server

Ilya Goldberg <igg@nih.gov>

=item Perl interface

Douglas Creager <dcreager@alum.mit.edu>

=back

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut


