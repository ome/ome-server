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

	# Create and edit several DBObject's via the factory
	$session->commitTransaction();

	# Create and edit several DBObject's via the factory, but make
	# a mistake halfway through
	$session->rollbackTransaction();

=head1 DESCRIPTION

To come.

=cut

use OME;
our $VERSION = $OME::VERSION;

use strict;

use Carp;
use OME::DBObject;
use base qw(OME::DBObject Class::Accessor);
use POSIX;

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

=cut

sub closeSession {
    my ($self) = @_;

    # When we log out, break any circular links between the Session
    # and other objects, to allow them all to get garbage-collected.
    $self->{Factory} = undef;
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

# get a scratch directory under a repository
sub getScratchDirRepository {
    my $self = shift;
    my %params = @_;
    my $repository = $params{repository} ||
    	die "OME::Session->getScratchDirRepository was called incorectly!\n";

	return $self->getScratchDir( $params{progName}, $params{extension}, $repository->Path() );

}

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
	
	local *DH;
    do {
		$base_name = sprintf("%s/%s-%03d.%s", $tmpRoot,$progName,$count,$extension);
		$base_name =~ s/\/\//\//g;
	    if( opendir( DH, $base_name ) ) {
	    	closedir DH;
	    } else {
	    	$dir = $base_name;
	    }
    } while ( not defined $dir || $count++ > 999);
    if (defined $dir ) {
		mkdir $dir
			or die "Couldn't make directory $dir\n";
		return ($dir);
    } else {
		closedir (DH);
		return ();
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

