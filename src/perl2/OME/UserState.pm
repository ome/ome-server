# OME::UserState

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


package OME::UserState;

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


1;

__END__

=head1 AUTHOR

Douglas Creager <dcreager@alum.mit.edu>,
Open Microscopy Environment, MIT

=cut

1;