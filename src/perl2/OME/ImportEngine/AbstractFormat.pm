# OME/ImportEngine/AbstractFormat.pm

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


package OME::ImportEngine::AbstractFormat;

=head1 NAME

OME::ImportEngine::AbstractFormat - the superclass of all proprietary
image format importers

=head1 SYNOPSIS

	use OME::ImportEngine::AbstractFormat;
	my $format = OME::ImportEngine::AbstractFormat->
	                 new();
	my $groups = $format->getGroups($filenames);
	my $sha1 = $format->getSHA1($group);
	my $image = $format->importGroup($group);
	$format->cleanup();

=head1 DESCRIPTION

The import engine delegates most of the work of importing an image to
subclasses of this class.  Each image format that the import engine
supports is defined as a separate subclass of AbstractFormat.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;
use OME::Tasks::ImportManager;
use OME::Tasks::PixelsManager;

use File::Basename;
use Log::Agent;

=head1 CONTRACT

The following public methods must be available for a class to be used
by the import engine to import images.

=head2 new

	my $format = OME::ImportEngine::AbstractFormat->new();

Creates a new instance of this format import class.  Any new
attributes created by this importer should point to the appropriate
import module executions, otherwise they will not be visible to any
future analysis chains.  This MEX's can be obtained via the get*MEX
methods in the OME::Tasks::ImportManager class.

This is the only contract method which has a non-abstract
implementation in AbstractFormat.  Any subclasses should be sure to
call $self->SUPER::new() in their own constructors.

=cut

sub new {
    my ($proto) = @_;
    my $class = ref($proto) || $proto;

    my $self = {};

    bless $self, $class;
    return $self;
}

=head2 getGroups

	my $groups = $format->getGroups($filenames);

Searches the list of filenames for files that this class can import.
It should perform any necessary grouping if this format stores a
single 5D image in multiple files.  It should not actually import the
image, it should just determine which files in the list it is able to
import.

Each group of files that would comprise a single OME image should be
grouped together.  Programmatically, this group can be represented by
any Perl scalar; the import engine will not do anything to it other
than use it as a parameter to the getSHA1 and importGroup methods.  At
the very least, the group should store the names of the files that
will be imported to form the image; the import engine does not track
this information for you.

Any files which can be imported should be removed from the $filenames
array.  (Since it's a reference, these changes will be visible to the
import engine and to the other format classes.)  A helper method
(C<__removeFilenames>) is provided to aid in this.  If the files are
not removed from the list, other format classes will have a chance to
import the file as well, creating duplicates.  This is almost never
the correct behavior.

This method has an abstract implementation in AbstractFormat;
subclasses should I<not> call the superclass method from their
overridden methods.

=cut

sub getGroups {
    my ($self,$filenames) = @_;
    die "AbstractFormat->getGroups is abstract";
}

=head2 getSHA1

	my $sha1 = $format->getSHA1($group);

The import engine will call this method to determine whether an image
has already been imported into OME.  If it has, the import engine will
skip this group (and therefore not call the importGroup method on it.)

This method should return a unique SHA-1 digest for the image group.
Usually, this is accomplished by calculating the SHA-1 of one of the
files in the image group.  However, this must be done against a file
which does not appear in any other image.  (Header files describing
filename schemes or plate arrangements would not qualify, as they
would be used by more than one image.)

A helper method (C<__getFileSHA1>) is provided to aid in the
calculation of the SHA-1 digest.

This method has an abstract implementation in AbstractFormat;
subclasses should I<not> call the superclass method from their
overridden methods.

=cut

sub getSHA1 {
    my ($self,$group) = @_;
    die "AbstractFormat->getSHA1 is abstract";
}

=head2 importGroup

	my $image = $format->importGroup($group);

Imports one of the groups returned by the getGroups method.  This
method will be caused once for each group that should be imported.
This method is responsible for creating a new OME::Image instance to
represent the image, for creating a new repository file (and
corresponding Pixels attribute) to store the imported pixels, and for
creating attributes to represent any other metadata in the external
image files.  Further, this method should create instances of
OME::Image::ImageFilesXYZWT for each file in the group.

Helper methods will be provided to aid in this as soon as I figure out
what they should be.

This method has an abstract implementation in AbstractFormat;
subclasses should I<not> call the superclass method from their
overridden methods.

=cut

sub importGroup {
    my ($self,$group) = @_;
    die "AbstractFormat->importGroup is abstract";
}

=head2 cleanup

	$format->cleanup();

This method will be called once the import finishes (regardless of
whether the import was successful).  If any persistent resources need
to be created during the import process for your format, they can be
freed in this method.

=cut

sub cleanup {
}

=head1 HELPER METHODS

The following methods are available to subclasses of AbstractFormat.
They are intended to factor out the tasks common to all formats.
B<NOTE:> In the following prototypes, the object is called $self, to
represent the fact that these methods are to be called from within
overrides of the above contract methods, and are not meant to be
called publicly.

=head2 Session

	my $session = $self->Session();

Returns the session that was given as a parameter to the C<new> method.
Note that this will only return a correct value if the overridden
C<new> method calls its superclass C<new> method.

=cut

sub Session { return OME::Session->instance(); }


=head2 __getRegexGroups

This method is called from an importer and is passed a reference to a hash
whose values are OME files.  This method will look for a Semantic Type that
specifies a regular expression.  If any are found, it compares the filenames
to the regular expression.  If there's a match, the method will group these
elements together by basename in a hash, %groups.

A FilenamePattern Semantic Type is specified in src/xml/OME/Import/FilenamePattern.ome.
An example of how to specify your own regular expression can be found in this file
as a Custom Attribute.

An example of a hash in the array returned by findObjects() is below:

my $FileNameGroups = {
	Format    => 'OME::ImportEngine::TIFFreader',
 	RegEx     => '(basename)_t(\d+)_z(\d+)_c(\d+)',
 	Name 	  => 'foo',
	BaseName  => 1,
	T         => 2,
	Z         => 3,
	C		  => 4

A hash of the number of Z's, C's and T's found is created during the method
call:
		my $maxZ = $infoHash->{ $pattern }->{ maxZ };

To get a file out of @groups, use my $file = $groups{$basename}[$z][$t][$c];

Usage:
my ($groups, $infoHash) = $self->__getRegexGroups(\%file_list);
	
};

=cut

sub __getRegexGroups {
    my ($self, $read_only_file_list) = @_;

    my $session = $self->Session();
    my $factory = $session->Factory();
    my %groups;
    my $maxZ;
    my $maxT;
    my $maxC;
    
    # A hash containing the number of patterns, as well as numZ, C, T, for each pattern
    my $infoHash;
    
    # make a copy of the list so we can delete elements without screwing with the original list
    my %file_list_copy = %$read_only_file_list;
    
    my $format = ref( $self );
    # See if there is a FilenamePattern ST in this DB.
	my $ST = $factory->findObject("OME::SemanticType",name => 'FilenamePattern');
    return (\%groups, $infoHash) unless defined $ST;

    # Get the array of filenamePattern hashes
    my @filenamePatternList = $factory->findObjects( 
    	'@FilenamePattern',
    	{ Format => $format }
    );
    
    # apply regular expressions to group %file_list_copy
    # store results in @groups
    # an entry in @groups should look something like:
    # 	$group_entry[$filePatternNumber][$z][$t][$c] = $file;
	my $filenamePattern;
	my %regexes;
    foreach $filenamePattern ( @filenamePatternList )
    {
    	# this naively assumes that the regular expression we get is safe :(
    	# see ImportExport/ModuleImport.pm for some regex validity/safety checking
    	# Do validity checking of the regular expression.
    	my $regex = $filenamePattern->RegEx();
    	eval { "" =~ /$regex/; };
		die "Invalid regular expression pattern: $regex\n" if $@;
    	
    	# There has to be a name in the file or you won't be able to group.
    	# Die if there isn't a name!
    	my $base = $filenamePattern->BaseName();
		die "No name in filePattern!" unless $base and $base > 0;

		$regexes{$regex} = {
			Base => $base,
			RE   => qr/$regex/,
			Z    => $filenamePattern->TheZ(),
			C    => $filenamePattern->TheC(),
			T    => $filenamePattern->TheT(),
		}
	}
	
	# $patterns{$regex}->{$basename}->{Z}->{$z}
	# $patterns{$regex}->{$basename}->{C}->{$c}
	# $patterns{$regex}->{$basename}->{T}->{$t}
	# Then we'll sort the Z C T to get
	# $groups{ $basename }[$z][$t][$c] = $file;
	my %patterns;
	my ($regex,$name);
	my ($Z,$C,$T);

	
	my $file;

	foreach $file ( values %file_list_copy )
	{
		my $filename = $file->getFilename();
		my $parts;
		while ( ($regex,$parts) = each %regexes ) {
			logdbg "debug",  "Checking $filename for $regex\n";
			if( $filename =~ $parts->{RE}) {
				eval ('$name = $'.$parts->{Base});
				die "When grouping files, Name capture failed with error: $@\n" if $@;
				logdbg "debug",  "\t got name $name\n";
				next unless $name;

				($Z,$C,$T) = (undef,undef,undef);
				if ( $parts->{Z} ) {
					# Grab the Z from the file based on the regular expression
					eval ('$Z = $'.$parts->{Z});
					die "When grouping files, Z capture failed with error: $@\n" if $@;
					logdbg "debug",  "\t got Z $Z\n";
				}
				if ( $parts->{C} ) {
					# Grab the C from the file based on the regular expression
					eval ('$C = $'.$parts->{C});
					die "When grouping files, C capture failed with error: $@\n" if $@;
					logdbg "debug",  "\t got C $C\n";
				}
				if ( $parts->{T} ) {
					# Grab the T from the file based on the regular expression
					eval ('$T = $'.$parts->{T});
					die "When grouping files, T capture failed with error: $@\n" if $@;
					logdbg "debug",  "\t got T $T\n";
				}

				$Z = '' unless defined $Z;
				$C = '' unless defined $C;
				$T = '' unless defined $T;
				$patterns{$regex}->{$name}->{Z}->{$Z} = 1;
				$patterns{$regex}->{$name}->{C}->{$C} = 1;
				$patterns{$regex}->{$name}->{T}->{$T} = 1;
				die "$filename matches more than one pattern.  ".
					"Previous pattern: Name ($name), Z ($Z), C ($C), T ($T)\n"
					 if exists $patterns{$regex}->{$name}->{File}->{$Z.':-:'.$C.':-:'.$T};
				$patterns{$regex}->{$name}->{File}->{$Z.':-:'.$C.':-:'.$T} = $file;
				
			}
		} # end going through the regexes
	} # end going through the files
	
	my $pattern;
	my @Zs;
	my @Cs;
	my @Ts;
	my ($z,$c,$t);
	foreach $regex (values %patterns) {
		while ( ($name,$pattern) = each %$regex) {
			@Zs = sort { $a <=> $b } keys %{$pattern->{Z}};
			@Cs = sort { $a <=> $b } keys %{$pattern->{C}};
			@Ts = sort { $a <=> $b } keys %{$pattern->{T}};
			$infoHash->{ $name }->{ maxZ } = scalar (@Zs);
			$infoHash->{ $name }->{ maxC } = scalar (@Cs);
			$infoHash->{ $name }->{ maxT } = scalar (@Ts);
			logdbg "debug",  "Group name $name Zs: @Zs Cs: @Cs Ts: @Ts\n";

			($z,$c,$t) = (0,0,0);
			foreach $Z (@Zs) {
				$c=0;
				foreach $C (@Cs) {
					$t=0;
					foreach $T (@Ts) {
						$groups{ $name }->[$z][$c][$t] = {
							File => $pattern->{File}->{$Z.':-:'.$C.':-:'.$T},
							Z    => $Z,
							C    => $C,
							T    => $T,
						};
						logdbg "debug",  "\tFile ".
							$pattern->{File}->{$Z.':-:'.$C.':-:'.$T}->getFilename().
							", pattern $name (Z,C,T)=($Z,$C,$T) at z[$z],c[$c],t[$t]\n";
						$t++;
					}
					$c++;
				}
				$z++
			}
		}
	}
	
    return (\%groups, $infoHash);
}


=head2 __newImage

	my $image = $self->__newImage($image_name);

Calls the session's Factory to create a new image object. Those attributes
that are known before the import are recorded in the new image.

=cut

sub __newImage {
    my ($self, $fn, $creation) = @_;

    my $session = $self->Session();
    my $guid = $session->Configuration()->mac_address();

    my $experimenter_id = $session->User()->id();
    my $user_group = $session->User()->Group();
    my $group_id = defined $user_group? $user_group->id(): undef;

    $creation = 'now' unless defined $creation;
    my $insertion = 'now';

    my $recordData = {'name' => $fn,
		      'image_guid' => $guid,
		      'description' => "",
		      'experimenter_id' => $experimenter_id,
		      'group_id' => $group_id,
		      'created' => $creation,
		      'inserted' => $insertion,
              };

    my $image = $session->Factory->newObject("OME::Image", $recordData);

    return $image;
}


=head2 __getFileSHA1

	my $sha1 = $self->__getFileSHA1($filename);

Calculates the SHA-1 digest of the contents of the given file.  If the
file could not be read, or any other error occurred during the
calculation of the digest, this method returns C<undef>.

=cut

sub __getFileSHA1 {
    my ($self,$filename) = @_;

    my $cmd = "openssl sha1 $filename |";
    my $sh;
    my $sha1;

    open (STDOUT_PIPE,$cmd);
    chomp ($sh = <STDOUT_PIPE>);
    $sh =~ m/^.+= +([a-fA-F0-9]*)$/;
    $sha1 = $1;
    close (STDOUT_PIPE);

    return $sha1;
}

=head2 __touchOriginalFile

	my $file_attribute = $self->__touchOriginalFile($filename,$format);

Should be called once for each file which constitutes an image.
Creates an OriginalFile attribute for this file.  If this file is
touched more than once during the import process, only one attribute
will be created.

=cut

sub __touchOriginalFile {
    my ($self,$file,$format) = @_;
    my $session = $self->Session();
    my $factory = $session->Factory();
    my $file_mex = OME::Tasks::ImportManager->getOriginalFilesMEX();

    logdbg "debug",  "Touch '$format' $file\n";

    return OME::Tasks::PixelsManager->
      createOriginalFileAttribute($file,$format,$file_mex);
}

=head2 __storeChannelInfo

    $self->__storeChannelInfo($numWaves, @channelInfo);

Stores metadata about each channel (wavelength) in the image. Each
channel may have measures for excitation wavelength, emission wavelength,
flourescense, and filter. Each channel is assigned a number starting at 0,
corresponding to the sequence in which the channels were illuminated.

Each physical channel becomes a single logical channel.

The routine takes as input the number of channels being 
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
    my ($self, $numWaves, @channelData) = @_;
    # FIXME:  This has GOT to go...
    my $image = $self->{image};
    my $pixels = $self->{pixels};
    my $factory = $self->Session()->Factory();
    my $module_execution = OME::Tasks::ImportManager->
      getImageImportMEX($image);
      
    foreach my $channel (@channelData){
		my $logical = $factory->
			newAttribute("LogicalChannel",$image,$module_execution,
				 {
					 ExcitationWavelength      => $channel->{'ExWave'},
					 EmissionWavelength        => $channel->{'EmWave'},
					 Fluor                     => $channel->{'Fluor'},
					 NDFilter                  => $channel->{'NDfilter'},
					 PhotometricInterpretation => 'monochrome',
				 });
		
		my $component = $factory->
			newAttribute("PixelChannelComponent",$image,$module_execution,
				 {
					 Pixels         => $pixels->id(),
					 Index          => $channel->{chnlNumber},
					 LogicalChannel => $logical->id(),
				 });
	}

}


=head2 __storeChannelInfoRGB

    $self->__storeChannelInfoRGB($numWaves, @channelInfo);

Stores metadata about an RGB composite channel.  The channelInfo array
should contain the three RGB channels, which will be stored as channel
components of a single logical channel.

Each channel info hash is keyed thusly:
     chnlNumber
     ExWave
     EmWave
     Flour
     NDfilter
This channel info is pulled from the first channel in the array and used to
define the single logical channel.  The chnlNumber is used from each of the 3
channels to store the channel component index (index into Pixels).

=cut

sub __storeChannelInfoRGB {
    my ($self, $numWaves, @channelData) = @_;
    # FIXME:  This has GOT to go...
	my $pixels = $self->{pixels};
	my $image = $self->{image};
    my $factory = $self->Session()->Factory();

    my $module_execution = OME::Tasks::ImportManager->
      getImageImportMEX($image);
      
 	my $logical = $factory->
		newAttribute("LogicalChannel",$image,$module_execution,
			 {
				 ExcitationWavelength      => $channelData[0]->{'ExWave'},
				 EmissionWavelength        => $channelData[0]->{'EmWave'},
				 Fluor                     => $channelData[0]->{'Fluor'},
				 NDFilter                  => $channelData[0]->{'NDfilter'},
				 PhotometricInterpretation => 'RGB',
			 });
				 
    foreach my $channel (@channelData){
		my $component = $factory->
			newAttribute("PixelChannelComponent",$image,$module_execution,
				 {
					 Pixels         => $pixels->id(),
					 Index          => $channel->{chnlNumber},
					 LogicalChannel => $logical->id(),
				 });
	}

}

=head2 __storeDisplayOptions

    $self->__storeDisplayOptions($numWaves, @channelInfo);

Stores metadata about an RGB composite channel.  The channelInfo array
should contain the three RGB channels, which will be stored as channel
components of a single logical channel.

Each channel info hash is keyed thusly:
     chnlNumber
     ExWave
     EmWave
     Flour
     NDfilter
This channel info is pulled from the first channel in the array and used to
define the single logical channel.  The chnlNumber is used from each of the 3
channels to store the channel component index (index into Pixels).

=cut


sub __storeDisplayOptions {
	my ($self, $opts) = @_;
    # FIXME:  This has GOT to go...
	my $pixels = $self->{pixels};
	my $image = $self->{image};
	
	my ($min, $max);
	if (defined $opts) {
	    croak ("min/max/center hashref required.") unless ref($opts) eq 'HASH';
		$min    = $opts->{min}    if exists ($opts->{min});
		$max    = $opts->{max}    if exists ($opts->{max});
	}
	
	my $factory = $self->Session()->Factory();
	    
	my $module_execution = OME::Tasks::ImportManager->
      getImageImportMEX($image);
      
	my $pixels_data = OME::Tasks::PixelsManager->loadPixels($pixels);
	my $pixels_attr = $pixels;
	my $theT=0;
	my %displayData = (
		Pixels => $pixels->id(),
		ZStart => sprintf( "%d", $pixels->SizeZ() / 2 ),
		ZStop  => sprintf( "%d", $pixels->SizeZ() / 2 ),
		TStart => 0,
		TStop  => 0,
		DisplayRGB => 1,
		ColorMap   => 'RGB',
	);
	
	# set display channels
	my (%displayChannelData, $channelIndex, @channelOrder);
	my $statsHash = $pixels_data->getStackStatistics();

	 # set up red shift channel ordering 
	my @channelComponents = $factory->findAttributes( "PixelChannelComponent", 
							{ Pixels => $pixels_attr } ); 
	
	if( @channelComponents && ( ! grep( (not defined $_->LogicalChannel()->EmissionWavelength()), @channelComponents ) ) ) { 
			@channelComponents = sort { $b->LogicalChannel()->EmissionWavelength() <=> $a->LogicalChannel()->EmissionWavelength() } 
			@channelComponents;
			@channelOrder = map( $_->Index(), @channelComponents ); 
	# There's no basis to do redshift ordering. This pixels is lacking channelComponents, which probably means it was computationally derived. 
	} else { 
		@channelOrder = (0..($pixels_attr->SizeC - 1)); 
	} 

	# Red Channel
	$displayData{RedChannelOn} = 1;
	$channelIndex = $channelOrder[0];
	$displayChannelData{ ChannelNumber } = $channelIndex;
	if (not defined $max or not defined $min) {
		( $displayChannelData{ BlackLevel }, $displayChannelData{ WhiteLevel } ) = 
		__defaultBlackWhiteLevels( $statsHash, $channelIndex, $theT );
	} else {
		$displayChannelData{BlackLevel} = $min;
		$displayChannelData{WhiteLevel} = $max;
	}
	$displayChannelData{ Gamma } = 1.0;
	my $displayChannel = $factory->newAttribute( "DisplayChannel", $image, $module_execution, \%displayChannelData );
	$displayData{ RedChannel } = $displayChannel;

	# Gray Channel
	$displayData{ GreyChannel } = $displayChannel;
	if( $pixels_attr->SizeC == 1 ) {
		$displayData{ DisplayRGB } = 0;
	}
	
	# Green Channel
	if( $pixels_attr->SizeC > 1 ) {
		$displayData{GreenChannelOn} = 1;
		$channelIndex = $channelOrder[1];
		$displayChannelData{ ChannelNumber } = $channelIndex;
		if (not defined $max or not defined $min) {
			( $displayChannelData{ BlackLevel }, $displayChannelData{ WhiteLevel } ) = 
			__defaultBlackWhiteLevels( $statsHash, $channelIndex, $theT );
		} else {
			$displayChannelData{BlackLevel} = $min;
			$displayChannelData{WhiteLevel} = $max;
		}
		$displayChannelData{ Gamma } = 1.0;
		$displayChannel = $factory->newAttribute( "DisplayChannel", $image, $module_execution, \%displayChannelData );
	} else {
		$displayData{GreenChannelOn} = 0;
	}
	$displayData{ GreenChannel } = $displayChannel;


	# Blue Channel
	if( $pixels_attr->SizeC > 2 ) {
		$displayData{BlueChannelOn} = 1;
		$channelIndex = $channelOrder[2];
		$displayChannelData{ ChannelNumber } = $channelIndex;
		if (not defined $max or not defined $min) {
			( $displayChannelData{ BlackLevel }, $displayChannelData{ WhiteLevel } ) = 
			__defaultBlackWhiteLevels( $statsHash, $channelIndex, $theT );
		} else {
			$displayChannelData{BlackLevel} = $min;
			$displayChannelData{WhiteLevel} = $max;
		}
		$displayChannelData{ Gamma } = 1.0;
		$displayChannel = $factory->newAttribute( "DisplayChannel", $image, $module_execution, \%displayChannelData );
	} else {
		$displayData{BlueChannelOn} = 0;
	}
	$displayData{ BlueChannel } = $displayChannel;

	# Make DisplayOptions
	$factory->newAttribute( "DisplayOptions", $image, $module_execution, \%displayData )
		or die "Couldn't make a new DisplayOptions";
}


sub __defaultBlackWhiteLevels {
	my ( $statsHash, $channelIndex, $theT ) = @_;
	my ( $blackLevel, $whiteLevel );
	
	$blackLevel = int( 0.5 + $statsHash->{ $channelIndex }{ $theT }->{Geomean} );
	$blackLevel = $statsHash->{ $channelIndex }{ $theT }->{Minimum}
		if $blackLevel < $statsHash->{ $channelIndex }{ $theT }->{Minimum};
	$whiteLevel = int( 0.5 + $statsHash->{ $channelIndex }{ $theT }->{Geomean} + 4*$statsHash->{ $channelIndex }{ $theT }->{Geosigma} );
	$whiteLevel = $statsHash->{ $channelIndex }{ $theT }->{Maximum}
		if $whiteLevel > $statsHash->{ $channelIndex }{ $theT }->{Maximum};
	return ( $blackLevel, $whiteLevel );
}


=head2 __storeOneFileInfo

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


=head2 __storeInputFileInfo

    __storeInputFileInfo(\@infoArray)

Stores metadata about each input file that contributed pixels to the
OME image. The $self hash has an array of hashes that contain all the
input file information - one hash per input file. This routine writes
this input file metadata to the database.

=cut

sub __storeInputFileInfo {
    my ($self,$inarr) = @_;

    foreach my $file_info (@$inarr) {
        my $file_attr = $self->{super}->
          __touchOriginalFile($file_info->{file},
                              $file_info->{format});
        OME::Tasks::ImportManager->
            markImageFiles($file_info->{image_id},$file_attr);
    }

}


=head2 __storePixelDimensionInfo

    __storePixelDimensionInfo(\@pixelInfo)

Stores metadata about the size of the input pixel. The dimensions are
passed in via an array, which may be partially empty.

=cut

sub __storePixelDimensionInfo {
    my ($self, $pixarr) = @_;

    my $image = $self->{image};
    my $factory = $self->Session()->Factory();
    $factory->newAttribute("Dimensions",$image,$self->{module_execution},
			   {PixelSizeX => $pixarr->[0],
			    PixelSizeY => $pixarr->[1],
			    PixelSizeZ => $pixarr->[2]});
}
    



=head2 __storeInstrumemtInfo

        $self->storeInstrumemtInfo($image,$model, $manufacturer, $orientation, $sn);

Creates an Instruments attribute for this image. Parameters are ordered
in expected frequency of occurrence; unknown parameters may be left off
the end of the argument string. Should be called once per image if there
is any instrument data to store. This will not accurately handle the
creation of an image composed from input images taken by different instruments.

=cut

sub __storeInstrumemtInfo {
    my ($self,$image,$model,$manufacturer,$orientation,$serialnum) = @_;
    my $factory = $self->Session()->Factory();
    my $img_mex = OME::Tasks::ImportManager->getImageImportMEX($image);

    $factory->newAttribute("Instrument", undef, $img_mex,
			   {
			       Model => $model,
			       Manufacturer => $manufacturer,
			       SerialNumber => $serialnum,
			       Type => $orientation,
			   });
}


=head2 __getFileSQLTimestamp

    __getSQLTimestamp($filename)

Returns the GMT last modification time of $filename formated in a form 
acceptable to Postgres as a timestamp. Currently, this routine outputs 
the string Mnth-dd-yyyy hh:mm:ss GMT enclosed in single quotes. For instance,
'Jan-28-2004 19:23:05 GMT'

=cut

# TODO:  make sure timestamp string is in vanilla SQL form

sub __getFileSQLTimestamp {
    my ($self,$filename) = @_;
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
	my $self = shift;
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
    my ($self,$sliceCallback) = @_;
    if ($sliceCallback) {
	$sliceCallback->();
    }
}



=head2 __removeFiles

	$self->__removeFiles($files,$to_remove);

Takes in two array references of files.  After this method returns,
none of the members of the $to_remove list will exist in the $files
list.

=cut

sub __removeFiles {
    my ($self,$file_list,$to_remove) = @_;

    foreach my $file (@$to_remove) {
        my $filename = $file->getFilename();
        delete $file_list->{$filename};
    }

    return;
}


=head2 __nameOnly

	my $basename = $self->__nameOnly($full_pathname);

Takes in a fully qualified file name, and returns just the base filename.
No path components and no extension will be returned.

=cut

sub __nameOnly {
    shift;
    my $basenm = basename($_[0]);

    # remove filetype extension from filename.
	# Assume that the last field (delimited by .) is the 
	# filetype extension. So $basenm of tiff.any.tiff is tiff.any 
	if ($basenm =~ /.*\..*/) {
		$basenm =~ m/(^.*\.)/;
		$basenm = $1;
		chop($basenm); # chop the trailing . 
	}
    return $basenm;
}



=head2 __createRepositoryFile

	my ($pixels_attribute,$pix_object) = $self->
	    __createRepositoryFile($image,$sizeX,$sizeY,$sizeZ,
	                           $sizeC,$sizeT,$bitsPerPixel,
	                           [$isSigned],[$isFloat]);

Creates a new repository file for the given image, creates a Pixels
attribute to refer to it ($pixels_attribute), and creates an instance
of OME::Image::Pixels to access the pixel data ($pix_object).  The
dimensions of the image must be specified before the repository file
is created.

The Pixels attribute will not be very useful to most import code,
except that any newly created attributes which require a reference to
a Pixels will point to it.  The import code will use the
OME::Image::Pixels instance much more, as it provides the low-level
access to the repository file.

=cut


sub __createRepositoryFile {
    my ($self,$image,$sizeX,$sizeY,$sizeZ,$sizeC,$sizeT,
        $bitsPerPixel,$isSigned,$isFloat) = @_;

    $isSigned ||= 0;
    $isFloat ||= 0;

    my $factory = $self->Session()->Factory();
    my $module_execution = OME::Tasks::ImportManager->
      getImageImportMEX($image);
    my $bytesPerPixel = $self->__bitsPerPixel2bytesPerPixel($bitsPerPixel);
	my $pixelType = 
      OME::Tasks::PixelsManager->getPixelType($bytesPerPixel,$isSigned,$isFloat);

    my %image_hash = (SizeX => $sizeX,
		      SizeY => $sizeY,
		      SizeZ => $sizeZ,
		      SizeC => $sizeC,
		      SizeT => $sizeT,
		      PixelType => $pixelType);
    my ($pixels,$attr) = OME::Tasks::PixelsManager->
	createPixels($image,$module_execution, \%image_hash);

    $image->pixels_id( $attr->id() ); # Josiah's viewer hack
    $image->storeObject();

    return ($attr,$pixels);
}





=head2  __bitsPerPixel2bytesPerPixel

        __bitsPerPixel2bytesPerPixel($bitsPerPixel)

logic figures out the correct byte size based on bits.  
this allows for TIFF files with un-natural pixel depth (i.e. 12bits per pixel)
use this instead of bytesPerPixel = bitsPerPixel/8

=cut

sub __bitsPerPixel2bytesPerPixel {
	my ($self,$bitsPerPixel) = @_;
	my $bytesPerPixel;
	
    if ($bitsPerPixel<=8 ){
	    $bytesPerPixel = 1;     
	}elsif ( $bitsPerPixel>8 && $bitsPerPixel<=16 ){
		$bytesPerPixel = 2;
	}else{
		$bytesPerPixel = 4;
    }
	return $bytesPerPixel;
}


=head2  __destroyRepositoryFile

        __destroyRepositoryFile($pixels, $pix)

Destroy the repository file referenced by $pixels/$pix. This would normally
be called if an import fails after __createRepositoryFile() has been
successfully called.

=cut

sub __destroyRepositoryFile {
    my ($self, $pixels, $pix) = @_;

#    ** TODO**  Implement this
}



=head1 AUTHORS

Douglas Creager (dcreager@alum.mit.edu)
Arpun Nagaraja

=head1 SEE ALSO

L<OME::ImportEngine::ImportEngine|OME::ImportEngine::ImportEngine>

=cut

1;
