#!/usr/bin/perl -w
#
# OME::ImportEngine::ImportCommon.pm
#
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
# Written by:    Brian S. Hughes
#
#-------------------------------------------------------------------------------


#

=head1 NAME

 OME::ImportEngine::ImportCommon - contains importer helper routines


=head1 SYNOPSIS

  use OME::ImportEngine::ImportCommon qw(/^.*/)
    or qw(routine_of_interest) 


=head1 DESCRIPTION

    This class contains methods that are common to the core importers,
    but may not be usable by all importers.


=cut




package OME::ImportEngine::ImportCommon;

use strict;
use Carp;

use File::stat;
use Exporter;
use OME;
use base qw(Exporter);


our @EXPORT = qw(getCommonSHA1 __storeChannelInfo __storeOneFileInfo __storeInputFileInfo __storePixelDimensionInfo doSliceCallback);

use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use OME::Tasks::ImportManager;

=head2 B<getCommonSHA1>

    getCommonSHA1($fileHandle)

Get the SHA1 digest of the file whose open handle is passed. This just
turns around and calls the universal __getFileSHA1 routine. 

=cut


sub getCommonSHA1 {
    my ($self,$fh) = @_;
    return $self->__getFileSHA1($fh);
}


=head2 B<__storeChannelInfo>

    $self->__storeChannelInfo($session, $numWaves, @channelInfo);

Stores metadata about each channel (wavelength) in the image. Each
channel may have measures for excitation wavelength, emission wavelength,
flourescense, and filter. Each channel is assigned a number starting at 0,
corresponding to the sequence in which the channels were illuminated.

The routine takes as input the session, the number of channels being 
recorded, and an array containg <channel> number of hashes of each 
channel's measurements. This routine writes this channel information 
metadata to the database.

Each channel info hash is keyed thusly:
     chnlNumber
     ExWave
     EmWave
     Flour
     NDfilter

=cut

sub __storeChannelInfo {
    my ($self, $session, $numWaves, @channelData) = @_;
    my $image = $self->{image};
    my $module_execution = OME::Tasks::ImportManager->
      getImageImportMEX($image);

    my $channel;
    for (my $w = 0; $w < $numWaves; $w++) {
	$channel = $channelData[$w];
	# Clean up hash if it's empty or has incorrect number
	if ($channel->{chnlNumber} ne $w) {
	    $channel->{chnlNumber} = $w;
	    $channel->{ExWave} = undef;
	    $channel->{EmWave} = undef;
	    $channel->{Fluor} = undef;
	    $channel->{NDfilter} = undef;

	}
	my $logical = $session->Factory()->
	    newAttribute("LogicalChannel",$image,$module_execution,
			 {
			     ExcitationWavelength   => $channel->{'ExWave'},
			     EmissionWavelength   => $channel->{'EmWave'},
			     Fluor    => $channel->{'Fluor'},
			     NDFilter => $channel->{'NDfilter'},
			     PhotometricInterpretation => 'monochrome',
			 });
	
	my $component = $session->Factory()->
	    newAttribute("PixelChannelComponent",$image,$module_execution,
			 {
			     Pixels         => $self->{pixels}->id(),
			     Index          => $w,
			     LogicalChannel => $logical->id(),
			 });
    }

}


=head2 B<__storeOneFileInfo>

   __storeOneFileInfo($self, $info_aref, $fn, $params, $image, $st_x $end_x,
		      $st_y, $end_y, $st_z, $end_z, $st_c, $end_c,
		      $st_t, $end_z, $fileformat)

Helper method for recording input file information.
Packs the passed metadata about one input file into the info_array
that is passed by reference. 

=cut

sub __storeOneFileInfo {
    my ($self, $info_aref, $fn, $params, $image, $st_x, $end_x,
	$st_y, $end_y, $st_z, $end_z, $st_c, $end_c,
	$st_t, $end_t,$format) = @_;


    push @$info_aref, { file => $fn,
                        path => $fn->getFilename(),
		      bigendian => ($params->{endian} eq "big"),
		      image_id => $image->id(),
		      x_start => $st_x,
		      x_stop => $end_x,
		      y_start => $st_y,
		      y_stop => $end_y,
		      z_start => $st_z,
		      z_stop => $end_z,
		      w_start => $st_c,
		      w_stop => $end_c,
		      t_start => $st_t,
		      t_stop => $end_t,
              format => $format};
}


=head2 B<__storeInputFileInfo>

    __storeInputFileInfo($session, \@infoArray)

Stores metadata about each input file that contributed pixels to the
OME image. The $self hash has an array of hashes that contain all the
input file information - one hash per input file. This routine writes
this input file metadata to the database.

=cut

sub __storeInputFileInfo {
    my $self = shift;
    my $session = shift;
    my $inarr = shift;

    foreach my $file_info (@$inarr) {
        $self->{super}->__touchOriginalFile($file_info->{file},
                                            $file_info->{format});
    }

}


=head2 B<__storePixelDimensionInfo>

    __storePixelDimensionInfo($session, \@pixelInfo)

Stores metadata about the size of the input pixel. The dimensions are
passed in via an array, which may be partially empty.

=cut

sub __storePixelDimensionInfo {
    my $self = shift;
    my ($session, $pixarr) = @_;

    my $image = $self->{image};
    my $factory = $session->Factory();
    $factory->newAttribute("Dimensions",$image,$self->{module_execution},
			   {PixelSizeX => $pixarr->[0],
			    PixelSizeY => $pixarr->[1],
			    PixelSizeZ => $pixarr->[2]});
}
    


=head2 B<__getFileSQLTimestamp>

    __getSQLTimestamp($filename)

Returns the GMT last modification time of $filename formated in a form 
acceptable to Postgres as a timestamp. Currently, this routine outputs 
the string Mnth-dd-yyyy hh:mm:ss GMT enclosed in single quotes. For instance,
'Jan-28-2004 19:23:05 GMT'

=cut

# TODO:  make sure timestamp string is in vanilla SQL form

sub __getFileSQLTimestamp {
    my $filename = shift;
    my $sb = stat($filename);
    my @crtimes = split " ", scalar gmtime $sb->mtime;
    my $crtime = "\'".$crtimes[1]."-".$crtimes[2]."-".$crtimes[4]." ".$crtimes[3]." GMT\'";

    return $crtime;
}


=head2 B<__getNowTime>

    __getNowTime()

Returns the current GMT time formated in a form acceptable to Postgres as 
a timestamp. Currently, this routine outputs the string Mnth-dd-yyyy 
hh:mm:ss GMT enclosed in single quotes. For instance, 
'Jan-28-2004 19:23:05 GMT'

=cut

sub __getNowTime {
    my @now = split " ", scalar gmtime;
    my $now = "\'".$now[1]."-".$now[2]."-".$now[4]." ".$now[3]." GMT\'";

    return $now;
}




=head2 doSliceCallback

         doSliceCallback(\&callback)

Routine to call a passed callback routine after successfully
importing a slice. If there is an input argument, treat it as
a function reference to the callback routine, and call it.

=cut

sub doSliceCallback {
    my $sliceCallback = shift;
    if ($sliceCallback) {
	$sliceCallback->();
    }
}




=head1 Author

Brian S. Hughes

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>

=cut

