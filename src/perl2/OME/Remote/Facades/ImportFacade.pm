# OME/Remote/Facades/ImportFacade.pm

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


package OME::Remote::Facades::ImportFacade;
use OME;
our $VERSION = $OME::VERSION;

use POSIX;
use OME::SessionManager;
use OME::Session;
use OME::ImportEngine::ImportEngine;
use OME::Image::Server::File;
use OME::Tasks::PixelsManager;
use OME::Tasks::ImportManager;
use OME::Analysis::Engine;

=head1 NAME

OME::Remote::Facades::ImportFacade - implementation of remote facade
methods pertaining to image-import methods

=cut

sub startImport {
    my $proto = shift;
    my $fileIDs = pop;
    my $datasetID = pop;

    die "startImport expects an array of file ID's"
      unless ref($fileIDs) eq 'ARRAY';

    # We need to start the import process before forking, so that we
    # can return the Import DTO (which contains information about the
    # global import MEX among other things).

    my $importer = OME::ImportEngine::ImportEngine->new(AllowDuplicates => 1);
    my $session = OME::Session->instance();
    my $factory = $session->Factory();
    my $dataset;

    if (defined $datasetID) {
        $dataset = $factory->loadObject("OME::Dataset",$datasetID);
        die "Dataset #${datasetID} does not exist"
          unless defined $dataset;
    } else {
        $dataset = $factory->
          newObject("OME::Dataset",
                    {
                     name => "ImportFacade Dummy Dataset",
                     description => "Images imported by Remote Importer",
                     locked => 0,
                     owner_id => $session->experimenter_id(),
                    });
        die "Cannot create import dataset"
          unless defined $dataset;
    }

    my $files_mex = $importer->startImport($dataset);
    my $session_key = $session->SessionKey();

    # Fork off the child process

    my $parent_pid = $$;
    my $pid = fork;

    if (!defined $pid) {
        # Fork failed, record as such in the ModuleExecution and return
        print STDERR "Bad fork\n";
        die "Could not fork off a process to perform the import";
    } elsif ($pid) {
        # Parent process

        print STDERR "Parent\n";
        OME::Tasks::ImportManager->forgetImport();

        # TODO:  Define a better Import DTO, encode it, and return it.
        return $files_mex->id();
    } else {
        # Child process

        print STDERR "Child\n";

        # Start a new session so we loose our controling terminal
        POSIX::setsid () or die "Can't start a new session. $!";

        OME::Session->forgetInstance();

# I believe this line can replace OME::Remote::Facades::ImportFacade::Child::importChild
# Is that possible? If not, then it can replace the innards of importChild
#OME::Tasks::ImageTasks::importFiles($dataset, \@file_names, \%opts);
        eval {
            OME::Remote::Facades::ImportFacade::Child::importChild
                ($session_key,$importer,$dataset,$fileIDs);
        };

        print STDERR $@ if $@;

        print STDERR "Exiting....\n";
        CORE::exit(0);
    }
}

######################
# Put the following methods in a separate package so that they cannot
# be called via XML-RPC.

package OME::Remote::Facades::ImportFacade::Child;

use Carp;

sub importChild ($$$$) {
    #local $SIG{__DIE__} = sub { print STDERR "*** DIE DIE DIE CHILD $$\n",@_,"\n"; };

    my ($sessionKey,$importer,$dataset,$fileIDs) = @_;
    print STDERR "Child\n";

    my $session = OME::SessionManager->createSession($sessionKey);
    print STDERR "  Session $session\n";

    my $factory = $session->Factory();
    print STDERR "  Factory $factory\n";

    my $repository = $session->findRemoteRepository();
    print STDERR "  Repository $repository\n";

    $session->activateRepository($repository);

    my @files;
    foreach my $id (@$fileIDs) {
        print STDERR "  File $id\n";
        push @files, OME::Image::Server::File->new($id);
    }

    print STDERR "  Importing\n";
    $importer->importFiles(\@files);
    $importer->finishImport();

    print STDERR "  Executing chain\n";
    my $chain = $session->Configuration()->import_chain();
    if (defined $chain) {
        $OME::Analysis::Engine::DEBUG = 0;
        OME::Analysis::Engine->executeChain($chain,$dataset,{});
    }

    return;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
