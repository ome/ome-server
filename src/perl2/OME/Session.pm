# OME::Session

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


package OME::Session;

=head1 NAME

OME::Session - a user's login session with OME

=head1 SYNOPSIS

	use OME::SessionManager;
	use OME::Session;

	# To login to OME:
	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);

	# To obtain the session object after login:
	my $session = OME::Session->instance();

	my $factory = $session->Factory();
	my $config = $session->Configuration();

	# Create and edit several DBObject's via the factory
	$session->commitTransaction();

	# Create and edit several DBObject's via the factory, but make
	# a mistake halfway through
	$session->rollbackTransaction();

=head1 DESCRIPTION

All interaction with OME is done in the context of a session object.
This session object encodes the user credentials that were used to
login to the OME system, and encapsulates the Factory object which is
used for all OME database access.

Within the context of a single Perl process, the Session object is a
singleton.  There will only ever be B<I<one>> session for a given
process, fork or thread.  All of the OME Perl code is written around
this assumption.  The C<instance> method should be used to obtain the
singleton Session instance.

Each session has a session key (a string token) which can be used to
refer to a sesson outside the context of the Perl interpreter which
created it.  This allows a user's session to be represented externally
in a file, or in a separate client machine/process.  Session objects
in Perl can be created either with a username/password pair, or with a
session key.  The first case causes a new logical session (with a new
session key) to be created, while the second allows an existing
logical session to persist across Perl processes.  The session key is
short lived, and must be periodically refreshed.

There is no public constructor for this class.  The
OME::SessionManager class should be used to create Session objects.

=head1 METHODS

The following methods are available.

=head2 Factory

	my $factory = $session->Factory();

Returns the session's L<C<OME::Factory>|OME::Factory> object.

=head2 Configuration

	my $config = $session->Configuration();

Returns the session's L<C<OME::Configuration>|OME::Configuration> object.

=head2 SessionKey

	my $key = $session->SessionKey();

Returns the session's SessionKey - a string token that can be used to
recover the session object (using
L<C<OME::SessionManager>|OME::SessionManager>) for a short period of
time.

=head2 User

	my $user = $session->User();

Returns the Experimenter whose username and password were used to log
in.

=head2 dataset

	my $dataset = $session->dataset();

Returns the session's L<C<OME::Dataset>|OME::Dataset> object.

=head2 project

	my $project = $session->project();

Returns the session's L<C<OME::Project>|OME::Project> object.

=cut

use OME;
our $VERSION = $OME::VERSION;

use strict;

use Carp;
use OME::UserState;
use OME::DBObject;
use base qw(Class::Accessor);
use POSIX;
use File::Path;

#use Benchmark::Timer;

__PACKAGE__->mk_ro_accessors(qw(Factory DBH UserState ApacheSession SessionKey Configuration));

our $__soleInstance = undef;

# transparant interface to UserState
sub experimenter_id { return shift->{UserState}->experimenter_id(@_); }
sub experimenter { return shift->{UserState}->experimenter(@_); }
sub User { return shift->{UserState}->User(@_); }
sub host { return shift->{UserState}->host(@_); }
sub project_id { return shift->{UserState}->project_id(@_); }
sub project { return shift->{UserState}->project(@_); }
sub dataset_id { return shift->{UserState}->dataset_id(@_); }
sub dataset { return shift->{UserState}->dataset(@_); }
sub module_execution_id { return shift->{UserState}->module_execution_id(@_); }
sub module_execution { return shift->{UserState}->module_execution(@_); }
sub image_view { return shift->{UserState}->image_view(@_); }
sub feature_view { return shift->{UserState}->feature_view(@_); }
sub last_access { return shift->{UserState}->last_access(@_); }
sub started { return shift->{UserState}->started(@_); }
sub storeObject { return shift->{UserState}->storeObject(@_); }
sub writeObject { return shift->{UserState}->writeObject(@_); }

# __newInstance is truly local; it should never be able to be called
# from outside of this module.

my $__newInstance = sub {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $userState = shift
      or die "Session cannot be initialized without a user state";

    die "User State parameter is not of class OME::UserState"
      unless (ref($userState) eq "OME::UserState") ;

    my $self = $class->SUPER::new();

    $self->{UserState} = $userState;
    $self->{Factory} = OME::Factory->new();
    $self->{Configuration} = OME::Configuration->new( $self->{Factory} );

	# carp "New instance.";
    return $self;
};

=head2 bootstrapInstance

	my $session = OME::Session->bootstrapInstance();

This method is intended for internal use only.  It is used to obtain a
valid Session object which is not keyed to an OME user.  This kind of
session is used by the OME installation code to set up the core OME
database schema before the first user is created.

A Session created via this method only has valid values for the
Factory accessor.  It cannot persist across Perl processes, and has no
SessionKey.  It also does not have a UserState object, and therefore
no User, project, dataset, or Configuration.

When the bootstrap session is no longer needed, it can be destroyed
with the finishBootstrap method.  Usually this is followed immediately
by logging in via the standard OME::SessionManager methods.

=cut

sub bootstrapInstance {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    die "There's already an active session" if defined $__soleInstance;

    my $self = $class->SUPER::new();
    $self->{Factory} = OME::Factory->new();
    $__soleInstance = $self;

    return $self;
}

=head2 finishBootstrap

	$session->finishBootstrap();

Destroys a bootstrap session created with the C<bootstrapInstance>
constructor.

=cut

sub finishBootstrap {
    my $self = shift;
    die "This is not a bootstrap session" if exists $self->{UserState};
    die "There is no active session" unless defined $__soleInstance;
    die "How are there two session instances?" unless $self eq $__soleInstance;
    $__soleInstance->__destroySession();
    $__soleInstance->{Factory}->closeFactory();
    $__soleInstance->{Factory} = undef;
    $__soleInstance = undef;
    return;
}

=head2 instance

	my $session = OME::Session->instance();

	# Internal use only:
	my $session = OME::Session->instance($user_state);

This is the main method those most Perl code will use.  The
SessionManager methods are only needed for the code specifically
related to logging into OME.  Code which needs access to the session
object after login has completed uses this method instead.

When called with no parameters, this method returns the singleton
OME::Session instance.  If the user has not logged in yet, an error
occurs.

Internally, this method is also used by the OME::SessionManager
methods to create a new session object upon login.  When called with a
single parameter (which should be an instance of OME::UserState), a
new session object is created.  If a singleton instance already
exists, it is destroyed and then salvaged with the new user
credentials; otherwise, a new instance is created and initialized with
those credentials.  The SessionManager is the only class which should
ever call the single-parameter version of this method.

=cut

sub instance {
	my $proto = shift;
	my $userState = shift;

    if (defined $userState) {
        # We are trying to create a session, as opposed to just
        # retrieving the singleton instance.

        if (defined $__soleInstance) {
            # We've already created a session in this Perl process, so
            # destroy the old session's resources, and then salvage the
            # old session object with the new user credentials.

            $__soleInstance->__destroySession();
            $__soleInstance->__salvageSession($userState);
        } else {
            # This is the first time we've tried to create a session in
            # this Perl process.

            $__soleInstance = $__newInstance->($proto,$userState);
        }

        die "Could not create session"
          unless defined $__soleInstance;
    } else {
        die "Trying to retrieve a session instance when none exists"
          unless defined $__soleInstance;
    }

	#carp "Returning singleton.";
	return $__soleInstance;
}

sub __salvageSession {
	my $self = shift;

	$self->{UserState} = shift;
    $self->{Configuration} = OME::Configuration->new( $self->{Factory} );
}

sub __destroySession {
    my $self = shift;

    return unless defined $self;

	# This ensures a fresh transaction.
	$self->rollbackTransaction()
      if defined $self->{Factory};

    # Remove any stale temporary files which might still be lying around.
    $self->__finishAllTemporaryFiles();

    # Delete any cached DBObject's
	OME::DBObject->clearAllCaches();

	#carp "Returning salvaged session.";
}

DESTROY {
    my $self = shift;
    $self->__destroySession();
}

=head2 deleteInstance

Explicitly deletes the singleton instance from the process. This
should only be used when a true recycle of the Session object (either
Configuration or UserState is updated) is needed. You will incur a
STDERR warning when using this method.

=cut

sub deleteInstance {
	my $self = shift;
    my $force = shift;

	carp "WARNING: Explicit deletion of OME::Session"
      unless $force;

    $__soleInstance->__destroySession();
	$__soleInstance = undef;

	return 1;
}

# Accessors
# ---------
sub DBH { carp "Noo!!!!!"; return shift->{Factory}->obtainDBH(); }

=head2 commitTransaction

	$session->commitTransaction();

Commits the current database transaction.

=head2 rollbackTransaction

	$session->rollbackTransaction();

Rolls back the current database transaction.  Note that this does not
invalidate any Perl database objects; callers must be careful to not
use any DBObjects that were created or modified during the aborted
transaction.

=cut

# We explicitly return to throw away any return values.
# These methods delegate to their implementations in OME::Factory.

sub commitTransaction { shift->{Factory}->commitTransaction(); return; }
sub rollbackTransaction { shift->{Factory}->rollbackTransaction(); return; }

{
    my %TEMPORARY_FILES;

    sub __markTemporaryFilename {
        my $proto = shift;
        my $filename = shift;

        $TEMPORARY_FILES{$filename} = undef;
    }

    sub __unmarkTemporaryFilename {
        my $proto = shift;
        my $filename = shift;

        delete $TEMPORARY_FILES{$filename};
    }

    sub __getMarkedTemporaryFilenames {
        my $proto = shift;
        my @filenames = keys %TEMPORARY_FILES;
        return \@filenames;
    }

}

=head2 getTemporaryFilename

	my $filename = $session->getTemporaryFilename($progName,$extension);

Returns an absolute path to a temporary file.  The $progName and
$extension parameters are purely informational, and are used to form
the filename.  The filename can be used in a standard Perl C<open>
call to create the temporary file.  When the temporary file is no
longer needed, it should be closed, and the finishTemporaryFile method
should be called.

Any temporary files which are created but not finished will be cleaned
up when the current session finishes, but this behavior should not be
relied upon.  Please clean up after yourself.

=cut

sub getTemporaryFilename {
    my $self = shift;
    my $progName = shift;
    my $extension = shift;

    my ($base_name,$full_path);
	my $tmpRoot = $self->Configuration()->tmp_dir();

    # Find a unique filename for the new pixels
    my $time = time();
    my $nonce = 0;
    my $handle;
    my $again = 1;

    while ($again) {
        $base_name = sprintf("%s-%d-%03d-%d.%s",
                             $progName,
                             $time,
                             ++$nonce,
                             $$,
                             $extension);
        $full_path = File::Spec->catfile($tmpRoot,$base_name);
        $again = -e $full_path;
    }

    $self->__markTemporaryFilename($full_path);
    return $full_path;
}


=head2 getScratchDir

	my $path = $session->getScratchDir($progName, $extension);

Returns an absolute path to a temporary directory within OME's temp
directory.  A filename is first created by calling the
C<getTemporaryFilename> method.  Once a filename is returned, it is
passed to the Perl C<mkdir> function to create a temporary directory.
As with <getTemporaryFilename>, once the directory is no longer
needed, the C<finishTemporaryFile> method should be called.

=cut

# get a scratch directory under OME's tmp dir
sub getScratchDir {
    my $self = shift;
    my $progName = shift;
    my $extension = shift;

    my $filename = $self->getTemporaryFilename($progName,$extension);

    mkdir $filename,0777
      or die "Could not create temporary directory $filename";

	return $filename;
}

=head2 finishTemporaryFile

	$session->finishTemporaryFile($filename);

Removes a temporary file or directory created by the
C<getTemporaryFilename> or C<getScratchDir> method.  Please, please,
please call this method immediately when you're done with a temporary
file.  Do not rely on the automatic session cleanup to remove your
garbage.

This method successfully handles removing the file whether $filename
refers to a simple file or to a directory.  If it refers to a
directory, it and all of its contents are removed, assuming that the
Perl process has write access to everything.

=cut

sub finishTemporaryFile {
    my ($proto,$filename) = @_;
    die "Need a filename"
      unless defined $filename;

    if (-e $filename) {
        eval { rmtree($filename,0,1); };
        warn "Error removing temp file/directory $filename: $@" if $@;
        warn "Error removing temp file/directory $filename: $!" if $!;
    }

    $proto->__unmarkTemporaryFilename($filename);
    return;
}

sub __finishAllTemporaryFiles {
    my $proto = shift;
    my $files = $proto->__getMarkedTemporaryFilenames();
    foreach my $file (@$files) {
        warn "Temporary file not removed via finishTemporaryFile! $file";
        $proto->finishTemporaryFile($file);
    }
}

# added by IGG for benchmarking
#sub BenchmarkTimer {
#	my $self = shift;
#	return $self->{__BenchmarkTimer} if exists $self->{__BenchmarkTimer};
#	$self->{__BenchmarkTimer} = Benchmark::Timer->new();
#	return $self->{__BenchmarkTimer};
#}
1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

