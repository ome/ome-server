# OME/Remote.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::Remote;

=head1 NAME

OME::Remote - the OME Remote Access API

=head1 INCLUDED CLASSES

=over

=item *

OME::Remote::Dispatcher

=item *

OME::Remote::Prototypes

=item *

OME/SOAP/StandaloneServer.pl

=back

=head1 TAKE HEED

The Remote Access API is currently I<very> experimental.  Use it at
your own risk.

=head1 DESCRIPTION

The classes in OME::Remote allow developers to access the OME API from
languages other than Perl, by providing an interface to the API over
an RPC protocol.  The Remote Access framework has been written to be
independent of the specific RPC protocol involved; we have
experimented with both SOAP and XML-RPC.  The XML-RPC server seems to
interact better with other clients.

=head1 OME::Remote::Dispatcher

The OME::Remote::Dispatcher object is responsible for translating
received RPC calls into the appropriate Perl API calls.  All method
calls are executed in the context of an OME session.  All objects
created by the Perl methods are serialized into the RPC messages as
object references; the objects themselves are kept in a cache on the
server side.  This has two benefits: First, the objects maintain their
integrity even in the absence of object-oriented method call support
in the RPC protocol (i.e, XML-RPC).  Second, this enforces object
encapsulation across the RPC channel, adding a small extra layer of
security.  Malevolent and/or buggy user code cannot create and modify
objects to trick the Remote Access server into doing something that it
shouldn't; Remote Access clients only have access to Perl objects
explicitly created by the methods of the Perl API.

Please see L<OME::Remote::Dispatcher|OME::Remote::Dispatcher> for more
information.

=head1 OME::Remote::Prototypes

The methods in the Perl API which are accessible via the Remote Access
server are specified in the OME::Remote::Prototypes class.  This
allows us to prevent certain methods from being available to remote
clients, and also provides a better type-checking facility than is
provided by Perl itself.

Please see L<OME::Remote::Prototypes|OME::Remote::Prototypes> for more
information.

=head1 OME/SOAP/StandaloneServer.pl

The StandaloneServer.pl script is the executable that starts the RPC
daemon used by the Remote Access layer.  It runs as a foreground
process, and can listen on a non-privileged port, allowing the script
to be run by a normal user.  It also can be configured to act as
either a SOAP server or an XML-RPC server.  In either case, it
publishes the methods in the OME::Remote::Dispatcher class.

=head2 Usage

	perl StandaloneServer.pl <port number> <"SOAP" or "XMLRPC">

where <port number> is the TCP port to bind the RPC server to, and the
second parameter determines whether the script will start a SOAP
server or an XML-RPC server.  The script will display on STDOUT the
URL to connect RPC clients to.

In the case of the SOAP server, the OME::Remote::Dispatcher methods
are served out of the OME/Remote/Dispatcher namespace.  For the
XML-RPC server, the methods are served out unqualified.

=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head1 SEE ALSO

L<OME::Remote::Dispatcher|OME::Remote::Dispatcher>,
L<OME::Remote::Prototypes|OME::Remote::Prototypes>

=cut


1;
