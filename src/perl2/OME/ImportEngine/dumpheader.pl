#!/usr/bin/perl -w
#
# OME::ImportEngine::TIFFreader.pm
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


=head1 NAME

OME::ImportEngine::dumpheader.pl  -  dump TIFF header 


=head1 SYNOPSIS

    perl -I ../.. OME::ImportEngine::dumpheader <tiff file>

=head1 DESCRIPTION

Reads a TIFF file, dumping out the information in the header. Reports that the
file is not a TIFF file if it does not contain a valid TIFF preamble.

=cut

use OME::ImportEngine::TIFFUtils;
my $fn = shift;

readHeader($fn);




sub readHeader {
    my $fn  = shift;

    my $status = "";
    my $fh;

    print "\n";

    open $fh,$fn
	or return undef; 
    binmode($fh);
    print "Reading $fn\n";
    OME::ImportEngine::TIFFUtils::initDump();
    my $tags =  OME::ImportEngine::TIFFUtils::readTiffIFD($fh);
    if (!defined $tags) {
	print "\tNot a TIFF file\n";
    }
    close($fh);
}



=head1 Author

Brian S. Hughes

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>
L<OME::ImportEngine::TIFFreader>

=cut

1;

