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

	my $manager = OME::SessionManager->new();
	my $session = $manager->createSession($username,$password);

	my $factory = $session->Factory();
	my $config = $session->Configuration();

	# Create and edit several DBObject's via the factory
	$session->commitTransaction();

	# Create and edit several DBObject's via the factory, but make
	# a mistake halfway through
	$session->rollbackTransaction();

=head1 DESCRIPTION

All interaction with OME is done in the context of a session object.
This object is created by L<C<OME::SessionManager>|OME::SessionManager>
depending on the method by which OME is used - Web browser (L<C<OME::Web>|OME::Web>), L<C<OME::Remote>|OME::Remote> client or command-line tool.
The session object maintains the user's state regardless of the client used for access.
A user's session never expires.  A session key (a string token) is exchanged between the client and the server
to refer to a session object.  This token is short lived, and must be periodically refreshed.

=cut

use OME;
our $VERSION = $OME::VERSION;

use strict;

use Carp;
use OME::DBObject;
use base qw(OME::DBObject Class::Accessor);
use POSIX;

__PACKAGE__->Caching(0);

#use Benchmark::Timer;

use fields qw(Factory Manager DBH ApacheSession SessionKey Configuration);
__PACKAGE__->mk_ro_accessors(qw(Factory Manager DBH ApacheSession SessionKey Configuration));

__PACKAGE__->newClass();
__PACKAGE__->setDefaultTable('ome_sessions');
__PACKAGE__->setSequence('session_seq');
__PACKAGE__->addPrimaryKey('session_id');
__PACKAGE__->addColumn(experimenter_id => 'experimenter_id',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'experimenters',
                        NotNull => 1
                       });
__PACKAGE__->addColumn(host => 'host',{SQLType => 'varchar(256)'});
__PACKAGE__->addColumn(project_id => 'project_id');
__PACKAGE__->addColumn(project => 'project_id','OME::Project',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'projects',
                       });
__PACKAGE__->addColumn(dataset_id => 'dataset_id');
__PACKAGE__->addColumn(dataset => 'dataset_id','OME::Dataset',
                       {
                        SQLType => 'integer',
                        ForeignKey => 'datasets',
                       });
__PACKAGE__->addColumn(module_execution_id => 'module_execution_id');
__PACKAGE__->addColumn(module_execution => 'module_execution_id',
                       {SQLType => 'integer'});
__PACKAGE__->addColumn(image_view => 'image_view',{SQLType => 'text'});
__PACKAGE__->addColumn(feature_view => 'feature_view',{SQLType => 'text'});
__PACKAGE__->addColumn(last_access => 'last_access',
                       {
                        SQLType => 'timestamp',
                        Default => 'now',
                       });
__PACKAGE__->addColumn(started => 'started',
                       {
                        SQLType => 'timestamp',
                        Default => 'now',
                       });



=head1 METHODS

The following methods are available in addition to those defined by
L<OME::DBObject>.

=head2 Factory

Returns the session's L<C<OME::Factory>|OME::Factory> object.

=head2 Manager

Returns the session's L<C<OME::SessionManager>|OME::SessionManager> object.

=head2 Configuration

Returns the session's L<C<OME::Configuration>|OME::Configuration> object.

=head2 SessionKey

Returns the session's SessionKey - a string token that can be used to recover
the session object (using L<C<OME::SessionManager>|OME::SessionManager>) for a short period of time.

=head2 User

Returns the session's Experimenter attribute.

=head2 dataset

Returns the session's L<C<OME::Dataset>|OME::Dataset> object.

=head2 project

Returns the session's L<C<OME::Project>|OME::Project> object.

=head2 closeSession

	$session->closeSession();

This method breaks any circular dependencies when logging out.
This is normally called by L<C<OME::SessionManager>|OME::SessionManager>C<-E<gt>logout()>;

=cut

sub closeSession {
    my ($self) = @_;

    # When we log out, break any circular links between the Session
    # and other objects, to allow them all to get garbage-collected.
	$self->{Factory}->closeFactory();
	$self->{__session} = undef;
    $self->{Manager} = undef;
}


# Accessors
# ---------
sub DBH { carp "Noo!!!!!"; return shift->{Factory}->obtainDBH(); }
#sub DBH { my $self = shift; return $self->{Manager}->DBH(); }
sub User {
    my $self = shift;
    return $self->Factory()->loadAttribute("Experimenter",
                                           $self->experimenter_id());
}

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

=head2 getTemporaryFilename

	$session->getTemporaryFilename($progName,$extension);

returns an absolute path to a temporary file.  The file must be opened for use, and it must be deleted prior
to exit.

=cut

sub getTemporaryFilename {
    my $self = shift;
    my $progName = shift;
    my $extension = shift;
    my $count=-1;

    my $base_name;
	my $tmpRoot = $self->Configuration()->tmp_dir();
	
	local *FH;
    until (defined(fileno(FH)) || $count++ > 999)
    {
	$base_name = sprintf("%s/%s-%03d.%s", 
				$tmpRoot,
			     $progName,$count,$extension);
	sysopen(FH, $base_name, O_WRONLY|O_EXCL|O_CREAT);
    }
    if (defined(fileno(FH)) )
    {
	close (FH);
	return ($base_name);
    } else {
	return ();
    }
}

=head2 getTemporaryFilenameRepository

	$session->getTemporaryFilenameRepository(repository => $repository, progName => 'Foo', extension => 'bar');

Returns a relative path to a temporary file within the repository directory.
This is useful when a copy between filesystems is undesireable when reading or writing repository files.
The repository parameter is an L<C<OME::Repository>|OME::Repository> object.
The progName parameter will be used as a prefix followed by a number, followed by a '.' and the extension.

=cut

sub getTemporaryFilenameRepository {
    my $self = shift;
    my %params = @_;
    my ($progName, $extension, $repository) = ($params{progName}, $params{extension}, $params{repository} );
    my $count=-1;

    my $base_name;
	my $tmpRoot = $repository->Path();
	
	local *FH;
    until (defined(fileno(FH)) || $count++ > 999)
    {
	$base_name = sprintf("%s-%03d.%s", 
			     $progName,$count,$extension);
    my $fullPath = $tmpRoot."/".$base_name;
	sysopen(FH, $fullPath, O_WRONLY|O_EXCL|O_CREAT);
    }
    if (defined(fileno(FH)) )
    {
	close (FH);
	return ($base_name);
    } else {
	return ();
    }
}


=head2 getScratchDirRepository

	$session->getScratchDirRepository(repository => $repository, progName => 'Foo', extension => 'foo');

Returns an absolute path to a temporary directory within the repository directory.
This is useful when a copy between filesystems is undesireable when reading or writing repository files.
The repository parameter is an L<C<OME::Repository>|OME::Repository> object.
The progName parameter will be used as a prefix followed by a number, followed by a '.' and the extension.

=cut

sub getScratchDirRepository {
    my $self = shift;
    my %params = @_;
    my $repository = $params{repository} ||
    	die "OME::Session->getScratchDirRepository was called incorectly!\n";

	return $self->getScratchDir( $params{progName}, $params{extension}, $repository->Path() );

}


=head2 getScratchDir

	$session->getScratchDir($progName, $extension);

Returns an absolute path to a temporary directory within OME's temp directory.
The progName parameter will be used as a prefix followed by a number, followed by a '.' and the extension.

=cut

# get a scratch directory under OME's tmp dir
sub getScratchDir {
    my $self = shift;
    my $progName = shift;
    my $extension = shift;
    my $tmpRoot = shift;
    $tmpRoot = $self->Configuration()->tmp_dir()
    	unless $tmpRoot;
    my $count=0;
    my $base_name;
	my $dir = undef;
	
	if ($extension) {
		$extension = '.'.$extension;
	} else {
		$extension = '';
	}
	
    do {
		$base_name = sprintf("%s/%s-%03d%s", $tmpRoot,$progName,$count,$extension);
		$base_name =~ s/\/\//\//g;
		$dir = $base_name if mkdir ($base_name,0777);
    } while ( not defined $dir || $count++ > 999);

	print STDERR "Could not make a temporary directory $tmpRoot/$progName-xxx$extension.  Giving up after $count tries."
		unless defined $dir;
	return ($dir);
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

