# OME/Remote/Facade.pm

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


package OME::Remote::Facade;
use OME;
our $VERSION = $OME::VERSION;

our @FACADES;

use UNIVERSAL::require;
use OME::SessionManager;
use OME::Session;
use OME::Project;

=head1 NAME

OME::Remote::Facade - implementation of the Remote Framework interface

=cut

BEGIN {
    @FACADES = qw(OME::Remote::Facades::ProjectFacade
                  OME::Remote::Facades::ImportFacade);
    foreach my $facade (@FACADES) { $facade->require() }

    # Fix the XML-RPC server fault constants -- the XML-RPC spec says
    # they must be integers.

    $SOAP::Constants::FAULT_CLIENT = 101;
    $SOAP::Constants::FAULT_SERVER = 102;
    $SOAP::Constants::FAULT_VERSION_MISMATCH = 501;
    $SOAP::Constants::FAULT_MUST_UNDERSTAND = 502;
}

our $SHOW_CALLS = 0;
our $SHOW_RESULTS = 0;
our $SHOW_CACHING = 0;

sub createSession {
    my ($proto, $username, $password) = @_;

    print STDERR "createSession $username\n";

    my $session = OME::SessionManager->createSession($username,$password);
    die "Cannot create session"
      unless defined $session;

    my $result = $session->{SessionKey};
    $session->deleteInstance(1);
    OME::DBObject->clearAllCaches();

    return $result;
}


sub closeSession {
    my ($proto, $sessionKey) = @_;

    print STDERR "closeSession $sessionKey\n";

    my $session = OME::SessionManager->createSession($sessionKey);
    OME::SessionManager->deleteApacheSession($session->{ApacheSession});

    $session->deleteInstance(1);
    OME::DBObject->clearAllCaches();

    return 1;
}


sub dispatch {
    my ($proto,$sessionKey,$method,@params) = @_;
    print STDERR "dispatch $sessionKey $method @params\n";

    my $session = OME::SessionManager->createSession($sessionKey);

    my @result;
    my $executed = 0;

    eval {
      FACADE:
        foreach my $facade (@FACADES) {
            if (UNIVERSAL::can($facade,$method)) {
                $executed = 1;
                @result = $facade->$method(@params);
                last FACADE;
            }
        }
    };

    # If that eval caused an error, we'll need to die.  However, we
    # should save the error message, just in case the session-close
    # statements clobber it.

    my $eval_error = $@;

    $session->deleteInstance(1);
    OME::DBObject->clearAllCaches();

    die $eval_error if $eval_error;

    # If the method never got executed, throw an error.

    die "Could not find a facade which implements $method"
      unless $executed;

    # Otherwise, return the result.

    return @result;
}

1;

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=cut
