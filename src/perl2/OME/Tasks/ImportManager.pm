# OME/Tasks/ImportManager.pm

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


package OME::Tasks::ImportManager;

=head1 NAME

OME::Tasks::ImportManager - Workflow methods for handling data import

=head1 SYNOPSIS

	# Within any import code
	OME::Tasks::ImportManager->startImport();

	# For the original files
	my $original_files_mex = OME::Tasks::ImportManager->getOriginalFilesMEX();

	# For any global attributes which are created
	my $global_mex = OME::Tasks::ImportManager->getGlobalImportMEX();

	# For any dataset attributes which are created
	my $dataset_mex = OME::Tasks::ImportManager->getDatasetImportMEX($dataset);

	# For any image attributes which are created
	my $image_mex = OME::Tasks::ImportManager->getImageImportMEX($image);

	OME::Tasks::ImportManager->finishImport();

=head1 DESCRIPTION

This class contains helper methods for performing imports into OME.
All data in OME must have a full data history.  Not all imported data
will have an associated history, either because the data comes from a
proprietary format which does not encode a history, or because it came
from an OME XML file which did not contain a data history section.  We
use the somewhat sarcastic name of the "black hole" to refer to the
source of data about which we can infer nothing about its history.
The root of most data dependency trees is this black hole, which is
represented by a set of four dummy import modules.

The first module is the "Original files" module.  It represents the
original data files (whether proprietary or XML) emerging from the
black hole.  As such, it has no formal inputs, and a single formal
output of type OriginalFile.  These OriginalFiles are global
attributes, since they might contain any kind of data (they cannot
always be tied directly to one dataset or image).

The act of importing data is then represented by one or more of the
remaining three modules: Global import, Dataset import, and Image
import.  They each take in a single OriginalFiles formal input, and
represent the translation of the contents of that file into attributes
of the appropriate granularity.

The ImportManager class is provided to automatically create the
appropriate module executions for these modules.  Any code which is
responsible for importing data into OME should use these methods to
obtain the MEX's which should be assigned to any attributes which are
imported.

As with all logic classes in OME, the ImportManager only supports one
instance per process.  All of the methods in this class enforce this
restriction.

=cut

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Session;
use OME::Tasks::ModuleExecutionManager;

# Being a logic object, we cannot maintain any instance state.  This
# limits us to one active import per process.

my $self;

=head1 METHODS

NOTE: Several of these methods create new database objects.  None of
them commit any database transactions.

=head2 startImport

	OME::Tasks::ImportManager->startImport();

Initializes the ImportManager, and creates a MEX of the Original Files
module.  This MEX can be obtained via the getOriginalFilesMEX method.
Before this call, all of the get*MEX methods will throw an error.
Once the import process is finished, the finishImport method should be
called.  If the startImport method is called a second time before
finishImport is called, an error will be thrown.

=cut

sub startImport {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    die "Cannot have two active imports per process!"
      if defined $self;

    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    my $config = $session->Configuration();

    # Create the original files module
    my $original_files_module = $config->original_files_module();
    my $original_files = OME::Tasks::ModuleExecutionManager->
      createMEX($original_files_module,'G',undef);

    $self = {
             original_files => $original_files,
             global_import  => undef,
             dataset_import => {},
             image_import   => {},
            };
    bless $self, $class;

    return;
}

=head2 finishImport

	OME::Tasks::ImportManager->finishImport();

Signals that the import process started by startImport is finished.
All internal state is thrown away.  After this call, all of the
get*MEX methods will throw an error.  It is the responsibility of the
caller to commit any database transactions.

=cut

sub finishImport {
    my $class = shift;
    die "No active import!" unless defined $self;

    $self = undef;
}

=head2 getOriginalFilesMEX

	my $original_files_mex = OME::Tasks::ImportManager->getOriginalFilesMEX();

Returns the MEX of the Original Files module for this import.  Any
files which are parsed to obtain the imported data should have
OriginalFiles attributes created for them, and those attributes should
be keyed to this MEX.

=cut

sub getOriginalFilesMEX {
    my $class = shift;
    die "No active import!" unless defined $self;
    return $self->{original_files};
}

=head2 getGlobalImportMEX

	my $global_mex = OME::Tasks::ImportManager->getGlobalImportMEX();

Returns the MEX of the Global Import module for this import.  Unlike
the Original Files MEX, this MEX is not created until it is asked for.
Any global attributes which are created as a result of the data import
should be keyed to this MEX.

=cut

sub getGlobalImportMEX {
    my $class = shift;
    die "No active import!" unless defined $self;

    # Don't create a global import MEX until it's needed

    unless (defined $self->{global_import}) {
        # Find the Global Import module
        my $config = OME::Session->instance()->Configuration();
        my $global_import_module = $config->global_import_module();

        # Create the MEX
        my $global_import = OME::Tasks::ModuleExecutionManager->
          createMEX($global_import_module,'G',undef);

        # Link it to the Original Files MEX
        OME::Tasks::ModuleExecutionManager->
            addActualInput($self->{original_files},$global_import,'Files');

        # And save it
        $self->{global_import} = $global_import;
    }

    return $self->{global_import};
}

=head2 getDatasetImportMEX

	my $dataset_mex = OME::Tasks::ImportManager->getDatasetImportMEX($dataset);

Returns a MEX of the Dataset Import module for this import.  There
should be one MEX of this module for each dataset which has attributes
created by the importer.  (Datasets which are created by the importer,
but which do not contain any dataset attributes, do not need a Dataset
Import MEX.  Datasets which were created through some other process,
but which have new dataset attributes created by the importer, do need
a Dataset Import MEX.)  This method can be called multiple times with
the same dataset; the ImportManager ensures that only one Dataset
Import MEX is created for a single dataset.

=cut

sub getDatasetImportMEX {
    my $class = shift;
    die "No active import!" unless defined $self;

    my ($dataset) = @_;

    # Don't create a dataset import MEX until it's needed
    # NOTE: These are keyed in the instance hash by dataset ID.

    unless (defined $self->{dataset_import}->{$dataset->id()}) {
        # Find the Dataset Import module
        my $config = OME::Session->instance()->Configuration();
        my $dataset_import_module = $config->dataset_import_module();

        # Create the MEX
        my $dataset_import = OME::Tasks::ModuleExecutionManager->
          createMEX($dataset_import_module,'D',$dataset);

        # Link it to the Original Files MEX
        OME::Tasks::ModuleExecutionManager->
            addActualInput($self->{original_files},$dataset_import,'Files');

        # And save it
        $self->{dataset_import}->{$dataset->id()} = $dataset_import;
    }

    return $self->{dataset_import}->{$dataset->id()};
}

=head2 getImageImportMEX

	my $image_mex = OME::Tasks::ImportManager->getImageImportMEX($image);

Returns a MEX of the Image Import module for this import.  There
should be one MEX of this module for each image which has attributes
created by the importer.  (Images which are created by the importer,
but which do not contain any image attributes, do not need a Image
Import MEX.  Images which were created through some other process, but
which have new image attributes created by the importer, do need a
Image Import MEX.)  This method can be called multiple times with the
same image; the ImportManager ensures that only one Image Import MEX
is created for a single image.

=cut

sub getImageImportMEX {
    my $class = shift;
    die "No active import!" unless defined $self;

    my ($image) = @_;

    # Don't create a image import MEX until it's needed
    # NOTE: These are keyed in the instance hash by image ID.

    unless (defined $self->{image_import}->{$image->id()}) {
        # Find the Image Import module
        my $config = OME::Session->instance()->Configuration();
        my $image_import_module = $config->image_import_module();

        # Create the MEX
        my $image_import = OME::Tasks::ModuleExecutionManager->
          createMEX($image_import_module,'D',$image);

        # Link it to the Original Files MEX
        OME::Tasks::ModuleExecutionManager->
            addActualInput($self->{original_files},$image_import,'Files');

        # And save it
        $self->{image_import}->{$image->id()} = $image_import;
    }

    return $self->{image_import}->{$image->id()};
}


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=head1 SEE ALSO

L<OME>, http://www.openmicroscopy.org/

=cut
