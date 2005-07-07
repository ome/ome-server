# OME/ImportEngine/BMPUtils.pm

#
# OME::ImportEngine::BMPUtils
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
# Written by:    Nico Stuurman <nicos@itsa.ucsf.edu>
#
#-------------------------------------------------------------------------------


=head1 NAME

OME::ImportEngine::BMPUtils - contains helper routines for BMP fileaccess

=head1 SYNOPSIS

use OME::ImportEngine::BMPUtils 

=cut



package OME::ImportEngine::BMPUtils;

use strict;
use OME;
#use Carp;
#use Carp qw'cluck';
our $VERSION = $OME::VERSION;

#use Exporter;
#use base qw(Exporter);

our @EXPORT = qw(readBMPinfo verifyBMP);


sub readBMPinfo {
   my $file = shift;
   my $BMPinfo;

   $file->setCurrentPosition(0,0);
   # Read in header: 
   # 0: magic ('B'), 
   # 1: magic ('M'),
   # 2: 4 byte size, 
   # 3-4: 2x2byte reserved, 
   # 5: 4 byte offset to image data
   # Do we need to figure out endianism of the file or is it always little endian???
   my $buf=$file->readData(14);
   my @buf=unpack('CCVSSV',$buf);
   # $buf[0]=66 && $buf[1]==77 for genuine BMPs
   $BMPinfo->{ 'filesize' }=$buf[2];
   $BMPinfo->{ 'offset' }=$buf[5];

   
   # Read in Image info: 
   # 0: 2 byte header size, 
   # 1: 2 byte width, 
   # 2: 2 byte height, 
   # 3: 1 byte # of planes, 
   # 4: 1 byte bits per pixel, 
   # 5: 2 byte compression type, 
   # 6: 2 byte image size in bytes, 
   # 7: 2 bytes x pixels/meter, 
   # 8: 2 bytes y pixels/metes, 
   # 9: 2 bytes number of colors, 
   # 10: 2 bytes important colors
   my $imageinfo=$file->readData(40);
   my @imageinfo=unpack('VVVvvVVVVVV',$imageinfo);
   $BMPinfo->{'sizeX'}=$imageinfo[1];
   $BMPinfo->{'sizeY'}=$imageinfo[2];
   $BMPinfo->{'bpp'}=$imageinfo[4];
   $BMPinfo->{'ctype'}=$imageinfo[5];
   $BMPinfo->{'xpm'}=$imageinfo[7];
   $BMPinfo->{'ypm'}=$imageinfo[9];

   return $BMPinfo;
}
   
   



=head2 verifyBMP

Check whether the current file is a BMP file by looking at the first two bytes.
Returns the offset to the data when the magic bytes ('BM') are found

=cut

sub verifyBMP {
    my $file = shift;
    my ($buf,@buf,$offset);

    # Read the BMP header to 

    eval {
		return undef
         if $file->getLength() < 14;
      $file->setCurrentPosition(0,0);
      $buf = $file->readData(14);
      @buf = unpack('CCVSSV',$buf);

      if ($buf[0] == 66 && $buf[1] == 77) {
         $offset = $buf[5];
       } else {
         return undef;
       }
    };

    if ($@) {
        warn $@;
        return undef;
    }
    return ($offset);
}
