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


#

=head1 NAME

OME::ImportEngine::TIFFreader.pm  -  single & group TIFF image importer


=head1 SYNOPSIS

    use OME::ImportEngine::TIFFreader
    my $tiffFormat = new TIFFreader($session, $module_execution)
    my $groups = $tiffFormat->getGroups(\@filenames)
    my $image = $tiffFormat->importGroup(\@filenames)

=head1 DESCRIPTION

This importer class handles regular TIFF format images. The getGroups()
method discovers which files in a set of files have the TIFF format,
and the importGroup() method imports TIFF format files into OME 5D
image files and metadata.

See http://partners.adobe.com/asn/developer/pdfs/tn/TIFF6.pdf for the
complete TIFF specification.

The  getGroups() method will assemble groups of TIFF files that
together comprise a 5D image, as well as identifying single stand-alone
TIFF files. The importGroup() method will import a multi-file
group, stitching together the individual TIFF images into a single
5D OME image. It will also import a single file 'group' into an OME
5D image. All relevant metadata carried in the TIFF files will be
stored in the OME database.

This module will take ownership of any input file that has the
base TIFF format. But various 3rd party image files are also based
on the TIFF format, with additional custom features of their own.
If these files get passed to this importer, it will pull them in,
losing any custom metadata or formatting carried in these files.
For this reason, all TIFF variant importers must be called before 
this importer gets called.

=cut



package OME::ImportEngine::TIFFreader;
use Class::Struct;
use strict;
use File::Basename;
use Carp;
use OME::ImportEngine::Params;
use OME::ImportEngine::ImportCommon;
use OME::ImportEngine::TIFFUtils;
use base qw(OME::ImportEngine::AbstractFormat);

use vars qw($VERSION);
use OME;
$VERSION = $OME::VERSION;

use constant WHITE_IS_ZERO => 0;

=head2 Patterns Defining Groups

All the files in a TIFF file group will have the same filename pattern. 
Each filename will have a common base, and a variable part that identifies 
the instance of a group variable that the file represents. For instance,
a TIFF group that has images of the same plate well taken at 2 different
illumination wavelengths could have files named "plate4_well54_w1.tiff"
and "plate4_well54_w2.tiff".

Currently, this module only scans for 2 filename patterns:
    <name>_w<n>.tif{f} and <name>_w<n><name2>.tif{f}
where <name> and <name2> means any set of valid filename characters,
and <n> represents any digit between 1 and 9.

These patterns should be dynamically expandable by per site or per user
configuration records.


=cut

use constant LONE_TIFF => '.+\.[tT][iI][fF][fF]?$';

my %fmts = (fpat1 => '^(\w+)(_w)([1-9])(.tif+)$',
             fpat2 => '^(\w+)(_w)([1-9])(\w+)(.tif+)$',
            );


=head1 METHODS

The following public methods are available:


=head2 B<new>


    my $importer = OME::ImportEngine->TIFFreader->new($session, $module_execution)

Creates a new instance of this class. The other public methods of this
class are accessed through this instance.  The caller, which would
normally be OME::ImportEngine::ImportEngine, should already
have created the session and the module_execution.

=cut




sub new {

    my $invoker = shift;
    my $class = ref($invoker) || $invoker;   # called from class or instance

    my $self = {};
    my $session = shift;
    my $module_execution = shift;

    bless $self, $class;
    $self->{super} = $self->SUPER::new();

    my %paramHash;
    $self->{params} = new OME::ImportEngine::Params(\%paramHash);
    return $self;
}


=head2 B<getGroups> S< > S< > S< >

    my $group_output_list = $importer->getGroups(\@filepaths)

This method examines the list of filenames that is passed in by
reference. If a file contains the TIFF identifyer bytes in its begining,
it is declared to be TIFF format. Any files on the list that are 
declared TIFF files are removed from the input list and added to the 
output list. 

If a set of these TIFF files match any of the criteria that define a 
group, that set is added as an array to the output list. Any TIFF file 
that does not belong to such a group is placed into its own array (a 
group of 1) and placed on the output list. 

For each group, this method also determines what the OME repository 
image filename will be for that group. It then pushes this output name 
onto the arrary of input filenames; the importGroup() method will later 
extract it and create it in the repository to hold the new import.

=cut


sub getGroups {
    my $self = shift;
    my $fref = shift;
    my $digits = '[1-9]';
    my @inlist = sort keys %$fref;
    my @outlist;

    while (my $fn = shift @inlist) {
        my $file = $fref->{$fn};

        next
          unless (defined(is_tiff($file)));

        my $bn = basename($fn);
        my $matched = 0;
        my @grp;
        foreach my $k (keys %fmts) {
            my $pattern = $fmts{$k};
            if ($bn =~ m/$pattern/i) { # found a file that matches a pattern
                $matched = 1;
                my $subp = $5 ? "$4$5" : "$4";
                my $outname = defined($5) ? "$1$4" : "$1";
                my $subpattern = "$1$2$digits$subp";
                @grp = ($file);
                delete $fref->{$fn};
                while (1) {    #    now find all similarly named files
                    if ($fn = shift @inlist) {
                        $file = $fref->{$fn};
                        $bn = basename($fn);
                        if ($bn =~ m/$subpattern/i) {
                            push @grp, $file;
                            delete $fref->{$fn};
                            $matched++;
                        } else {
                            unshift @inlist, $fn;
                            last;
                        }
                    } else {
                        last;
                    }
                }
                if ($matched > 1) {
                    push @grp, $outname;
                } else {
                    push @grp, $bn;
                }
                push @outlist, \@grp;
                last;
            }
        }
        if ($matched == 0) {
            if ($fn =~ LONE_TIFF) {
                push @grp, $file;
		push @grp, $self->{super}->__nameOnly($fn);
                push @outlist, \@grp;
                delete $fref->{$fn};
            }
        }
    }

    return \@outlist;

}


=head2 importGroup

    my $image = $importer->importGroup(\@filenames)

This method imports a group of related TIFF files into a single
OME 5D image. The caller passes the ordered set of input files 
comprising the group (plus the name of the output file to create)
by reference. This method opens each file in turn, extracting its 
metadata and pixels, and adding them to the accumulating OME pixels
and metadata.

TIFF files carry metadata in one or more sections called IFDs. Each IFD
holds a set of information fields called tag fields. These fields hold
metadata values as bytes, shorts, longs, rationals, or ASCII strings.
This method, via the helper method readTiffIFD, locates and reads all
the tag values. It stores values of interest to OME into the OME
database.

TIFF files carry pixel data in one or more sections called strips. Each
strip contains an integral number of consequetive image I<rows>. Each
row contains one image width number of pixels. This method reads
the rows from the strips, and assembles them into planes in the 5D OME
image. Each input file contains the pixels for one plane.

If all goes well, this method returns a pointer to a freshly created
OME::Image. In that case, the caller should commit any outstanding
image creation database transactions. If the module detects an error,
it will return I<undef>, signalling the caller to rollback any associated
database transactions.

=cut

sub importGroup {
    my ($self, $grp, $callback) = @_;

    my $session = ($self->{super})->Session();
    my $factory = $session->Factory();
    my $params  = $self->{params};
    my $status = "";
    my ($file, $fn);

    # getGroups has left the output image file name at the end of @$grp
    my $ofn = pop @$grp;

    # Use the 1st file's parameters to get the X, Y, pixel size
    $file = $grp->[0];
    $file->open('r');
    my $tags =  readTiffIFD($file);
    $file->close();
    $params->endian($tags->{__Endian});
    my $xref = $params->{xml_hash};
    $xref->{'Image.SizeX'} = $tags->{TAGS->{ImageWidth}}->[0];
    $xref->{'Image.SizeY'} = $tags->{TAGS->{ImageLength}}->[0];
    $xref->{'Data.BitsPerPixel'} = $tags->{TAGS->{BitsPerSample}}->[0];
    $params->byte_size($xref->{'Data.BitsPerPixel'}/8);
    $self->{plane_size} = $xref->{'Image.SizeX'} * $xref->{'Image.SizeY'};

    # This assumes that a group has multiple wavelengths, but only 1 T & 1 Z
    # TODO - generalize to handle multiple T & Z too
    $params->xml_hash->{'Image.SizeZ'} = 0;
    $params->xml_hash->{'Image.NumTimes'} = 0;
    $params->xml_hash->{'Image.NumWaves'} = scalar(@$grp);

    my $image = ($self->{super})->__newImage($ofn);
    $self->{image} = $image;
    
    my $zs = ($xref->{'Image.SizeZ'} > 0) ? $xref->{'Image.SizeZ'} : 1;
    my $cs = ($xref->{'Image.NumWaves'} > 0) ? $xref->{'Image.NumWaves'} : 1;
    my $ts = ($xref->{'Image.NumTimes'} > 0) ? $xref->{'Image.NumTimes'} : 1;
    my ($pixels, $pix) = 
	($self->{super})->__createRepositoryFile($image, 
						 $xref->{'Image.SizeX'},
						 $xref->{'Image.SizeY'},
						 $zs,
						 $cs,
						 $ts,
						 $xref->{'Data.BitsPerPixel'});
    $self->{pix} = $pix;
    $self->{pixels} = $pixels;

    # for each channel (wavelength) read an input file and append to output
    my (@finfo, @channelInfo);
    for (my $c = 0; $c < scalar(@$grp); $c++) {
        $file = $grp->[$c];
        $file->open('r');
        $params->fref($file);
        $tags =  readTiffIFD($file)
          unless ($c == 0);     # 1st file's tags already read
        $status = readWritePixels($self, $tags, $c, $callback);
	if ($status ne "") {
	    $file->close();
	    last;
	}
        # Store summary info about each input file
        $self->__storeOneFileInfo(\@finfo, $file, $params, $image,
                                  0, $xref->{'Image.SizeX'}-1,
                                  0, $xref->{'Image.SizeY'}-1,
                                  0, 0,
                                  $c, $c,
                                  0, 0,
                                  "TIFF");

        # Store info about each input channel (wavelength)
        push @channelInfo, {chnlNumber => $c,
                            ExWave     => undef,
                            EmWave     => undef,
                            Fluor      => undef,
                            NDfilter   => undef};

        $file->close();
    }

    if ($status eq "") {
	$self->__storeInputFileInfo($session, \@finfo);
	$self->__storeChannelInfo($session, scalar(@$grp), @channelInfo);
	return  $image;
    } else {
	die $status;
    }

}



sub readWritePixels {
    my $self = shift;
    my $tags = shift;
    my $theC = shift;
    my $callback =shift;

    my $theY = 0;
    my $buf;
    my $params  = $self->{params};
    my $xref = $params->{xml_hash};
    my $sz_read = 0;
    my $fih      = $params->fref;
    my $status = "";

    $self->{pix}->convertPlaneFromTIFF($fih,0,$theC,0);
    $self->{pix}->finishPixels();
    doSliceCallback($callback);

    return $status;

}



sub is_tiff {
    my $file = shift;

    $file->open('r');
    my $tags =  readTiffIFD($file);
    $file->close();

    return $tags;
}


sub getSHA1 {
    my $self = shift;
    my $grp = shift;

    my $fn = $grp->[0];
    my $sha1 = $fn->getSHA1();

    return $sha1;
}


=head1 Author

Brian S. Hughes

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine>

=cut

1;







