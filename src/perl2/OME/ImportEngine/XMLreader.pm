# OME/ImportEngine/MetamorphHTDFormat.pm

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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------


package OME::ImportEngine::XMLreader;

use strict;
use OME;
our $VERSION = $OME::VERSION;
use Carp;
use Log::Agent;

use OME::Image::Server;
use OME::Tasks::OMEImport;

use base qw(OME::ImportEngine::AbstractFormat);
use OME::ImportEngine::ImportCommon qw(doSliceCallback);


# We call OMEIS to tell us if files are in XML format (IsOMExml)
# It returns a 0 or a 1.
sub getGroups {
my $self = shift;
my $fhash = shift;
my @inlist = values %$fhash;
my @outlist;
my $file;

	foreach (@inlist) {
		$file = $_ or next;
		push (@outlist,$file)
			if OME::Image::Server->isOMExml ( $file->getFileID() );
	}
	logdbg "debug", ref ($self)."->getGroups: XML files: ".scalar @outlist;


    # Clean out the $filenames list.
    $self->__removeFiles($fhash,\@outlist);

	return \@outlist;
}



sub importGroup {
    my ($self,$file, $callback) = @_;
    my $session = $self->Session();
    my @images;
    my $object;
    my $omeImport = OME::Tasks::OMEImport-> new(
	    session => $session,
	    # XXX: Debugging off.
	    #debug => 1
	);
	logdbg "debug", ref ($self)."->importGroup: Importing XML file: ".$file->getFilename();
	my $objects = $omeImport->importFile($file,
		NoDuplicates           => 0,
		IgnoreAlterTableErrors => 1)
	or return (undef);
	logdbg "debug", ref ($self)."->importGroup: XML objects: ".scalar @$objects;

	foreach $object (@$objects) {
		if (UNIVERSAL::isa($object,'OME::Image')) {
			foreach my $pixels ($object->pixels() ) {
				OME::Tasks::PixelsManager->saveThumb( $pixels );
			}
			OME::Tasks::ImportManager->markImageFiles(
				$object,
				$self->__touchOriginalFile ($file,'OME XML'));
			logdbg "debug", ref ($self)."->importGroup: Image Name: ".$object->name();
			push (@images,$object) ;
		}
	}
	
	doSliceCallback($callback);
	
	return \@images;
}

sub getSHA1 {
    my $self = shift;
    my $file = shift;
    return $file->getSHA1();
}


1;
