# OME/Remote/Dispatcher.pm

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


package OME::Remote::Dispatcher;
use OME;
our $VERSION = $OME::VERSION;

=head1 NAME

OME::Remote::Dispatcher - the OME Remote Access dispatcher

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

=head1 PUBLISHED METHODS

(NOTE: In the following descriptions, the method prototypes are
presented in their Perl syntax.  However, they will usually be called
via an RPC protocol.  The parameters and return values will be
consistent across protocol.)

The following methods are published by OME::Remote::Dispatcher:

=head2 versionInfo

	my $info = OME::Remote::Dispatcher->versionInfo();

Returns some useful information about the OME Remote Accesss server,
including the version of the underlying OME API.  This method can be
used by remote clients to verify that there is a working Remote Access
server at an RPC URL before attempting to create a session.

=head2 createSession

	my $session = OME::Remote::Dispatcher->
	    createSession($username, $password);

Logs into OME with the given username and password, and returns an
OME::Session object which can be used with the dispatch method to make
further OME API calls.

=head2 closeSession

	OME::Remote::Dispatcher->closeSession($session);

Ends an OME session.  Currently this method I<must> be called in order
for the Remote Access server to clean out the object cache of the
objects created by this session.  If a client fails to call this
method, the server will quickly leak memory.

(NOTE: This is, of course, going to change in the future, most likely
by having the server check every so often and automatically close any
sessions which are open and have not been recently used.)

=head2 dispatch

	OME::Remote::Dispatcher->
	    dispatch($session,$object,$methodName,@params);

The workhouse of the Remote Access dispatcher.  Has the same effect as
calling

	$object->$methodName(@params);

from a Perl interpreter which has logged in with $session.  The method
must be listed in %OME::Remote::Prototypes::prototypes in order for
the dispatcher to properly delegate the method call.  Type-checking is
performed on both the input parameters and return values; if either do
not match the prototype, and RPC fault is returned.  If any of the
parameters/return values are of an object type, they are encoded into
or decoded from, respectively, a string reference which can be passed
across the RPC channel.  The object and its reference are stored in a
cache, so that it can be referred to in later dispatch calls.

=head2 freeObject

	OME::Remote::Dispatcher->freeObject($session,$object);

Tells the Dispatcher that the given object will no longer be used by
the client.  Allows the Dispatcher to remove the object from the
cache, allowing the Perl garbage collector to free the object.

Note that logging out (by calling closeSession) performs an implicit
call to freeObject for any objects remaining in the cache for the
session.

Returns 1 if the object was deleted successfully; throws an error if
not.

=cut

use strict;

use Carp;
use Log::Agent;
use OME::SessionManager;
use OME::Session;
use OME::Factory;

use OME::Remote::Prototypes ();  # don't import anything

BEGIN {
    # Load in all of the classes that have prototypes defined.
    foreach (keys %OME::Remote::Prototypes::prototypes) {
        die "Malformed class name $_"
          unless /^[A-Za-z0-9_]+(\:\:[A-Za-z0-9_]+)*$/;
        eval "require $_";
    }

    # Fix the XML-RPC server fault constants -- the XML-RPC spec says
    # they must be integers.

    $SOAP::Constants::FAULT_CLIENT = 101;
    $SOAP::Constants::FAULT_SERVER = 102;
    $SOAP::Constants::FAULT_VERSION_MISMATCH = 501;
    $SOAP::Constants::FAULT_MUST_UNDERSTAND = 502;
}

our $SHOW_CALLS = 0; # was 1
our $SHOW_RESULTS = 0;
our $SHOW_CACHING = 0;

sub _die {
    print "  ",@_,"\n" if $SHOW_CALLS;
    die @_;
}

sub versionInfo {
    my ($proto) = @_;

    print "versionInfo(",join(',',map {$_ = OME::Remote::Utils::xmlEscape('P',$_);} @_[1..$#_]),")\n"
      if $SHOW_CALLS;

    return {
            Version => '1.0',
            Host    => 'bob.com',
           };
}

sub createSession {
    my ($proto, $username, $password) = @_;

    print "createSession(",join(',',map {$_ = OME::Remote::Utils::xmlEscape('P',$_);} @_[1..$#_]),")\n"
      if $SHOW_CALLS;

    my $session = OME::SessionManager->createSession($username,$password);
    _die "Cannot create session"
      unless defined $session;

    my $reference = OME::Remote::Utils::getObjectReference(">>SESSIONS",$session);
    OME::Remote::Utils::saveObject(">>SESSIONS",$reference,$session);

    my $sessionKey = $session->{SessionKey};
    OME::Remote::Utils::saveObject($sessionKey,$reference,$session,1);

    return $reference;
}


sub closeSession {
    my ($proto, $sessionRef) = @_;
    my $session = OME::Remote::Utils::getObject(">>SESSIONS",$sessionRef);
    my $sessionKey = $session->{SessionKey};

    print "closeSession(",join(',',map {$_ = OME::Remote::Utils::xmlEscape('P',$_);} @_[1..$#_]),")\n"
      if $SHOW_CALLS;

    OME::SessionManager->deleteApacheSession($session->{ApacheSession});
    OME::Remote::Utils::deleteSessionObjects($sessionKey);

    return 1;
}


sub dispatch {
    my ($proto,$sessionRef,$objectRef,$method,@params) = @_;
    my $session = OME::Remote::Utils::getObject(">>SESSIONS",$sessionRef);
    my $sessionKey = $session->{SessionKey};

    my @result;
    my $context;

    eval {
        print "dispatch(",
          join(',',
               map {$_ = OME::Remote::Utils::xmlEscape('P',$_);} @_[1..$#_]),
          ")\n"
          if $SHOW_CALLS;

        my ($objectProto,$objectClass);

        $objectRef = OME::Remote::Utils::xmlEscape('P',$objectRef);
        if ($objectRef =~ /\>\>OBJ\:/) {
            # This looks like an object reference
            $objectProto = OME::Remote::Utils::getObject($sessionKey,$objectRef);
            #print STDERR "    op $objectProto\n";
            $objectClass = ref($objectProto);
            #print STDERR "    oc $objectClass\n";
        } else {
            # It doesn't look like an object reference, assume it's a
            # class name.
            $objectProto = $objectClass = $objectRef;
        }

        $method = OME::Remote::Utils::xmlEscape('P',$method);

        # Lookup the method's prototype
        my $prototype =
          OME::Remote::Prototypes::findPrototype($objectClass,$method);

        croak "Cannot find method $method in class $objectClass"
          if (!defined $prototype);

        # Fix XML escape characters

        $_ = OME::Remote::Utils::xmlEscape('P',$_) foreach @params;
        _die "Parameters do not match prototype"
          unless OME::Remote::Prototypes::verifyInputPrototype
            ($prototype,
             \@params,
             \&OME::Remote::Utils::inputMarshaller,
             $sessionKey);

        $context = $prototype->{context};
        my $realMethod = $prototype->{method};

        # Call the method appropriate to the context in the prototype

        eval {
            if ($context eq 'void') {
                $objectProto->$realMethod(@params);
                @result = ();
            } elsif ($context eq 'scalar') {
                my $scalar = $objectProto->$realMethod(@params);
                @result = ($scalar);
            } else {
                @result = $objectProto->$realMethod(@params);
            }
        };

        if ($@) {
            print STDERR "*** REMOTE SERVER ERROR:\n$@\n";
            _die $@;
        }

        _die "Return value does not match prototype"
          unless OME::Remote::Prototypes::verifyOutputPrototype
            ($prototype,
             \@result,
             \&OME::Remote::Utils::outputMarshaller,
             $sessionKey);

        print "  (",join(",",@result),")\n"
          if $SHOW_RESULTS;
    };

    if ($@) {
        print STDERR "*** REMOTE SERVER ERROR:\n$@\n";
        die $@;
    }

    # RPC protocols usually require a method to return exactly one
    # return value, so any list-context methods should have their
    # results returned as an array.

    if ($context eq 'list') {
        return \@result;
    } else {
        return @result;
    }
}


sub freeObject {
    my ($proto,$sessionRef,$objectRef) = @_;
    my $session = OME::Remote::Utils::getObject(">>SESSIONS",$sessionRef);
    my $sessionKey = $session->{SessionKey};

    print "freeObject(",join(',',map {$_ = OME::Remote::Utils::xmlEscape('P',$_);} @_[1..$#_]),")\n"
      if $SHOW_CALLS;

    #$objectRef = OME::Remote::Utils::xmlEscape('P',$objectRef);

    # Try to load it in the specified object, just to make sure it
    # exists.  (getObject will throw an error if it doesn't.)
    OME::Remote::Utils::getObject($sessionKey,$objectRef);

    # It exists, so delete it.
    OME::Remote::Utils::deleteObject($sessionKey,$objectRef);

    return 1;
}


# These functions exist in another package so that they aren't
# exported as SOAP methods.

package OME::Remote::Utils;
use OME;
our $VERSION = $OME::VERSION;

use strict;

my %remoteReferences;
my %remoteObjects;

use OME::Remote::Prototypes qw(NULL_REFERENCE);

sub saveObject {
    my ($sessionKey,$reference,$object) = @_;

    # Only store the object if it's not already there.
    if (!exists $remoteObjects{$sessionKey}->{$reference}) {
        #print "  Saving object ",ref($object)," $sessionKey/$reference\n"
        #  if $OME::Remote::Dispatcher::SHOW_CACHING;
        $remoteObjects{$sessionKey}->{$reference} = $object;
    }
}

sub deleteObject {
    my ($sessionKey,$reference) = @_;
    $reference = xmlEscape('P',$reference);
    if (exists $remoteObjects{$sessionKey}->{$reference}) {
        print "  Deleting object $reference, ",ref($remoteObjects{$sessionKey}->{$reference}),"\n"
          if $OME::Remote::Dispatcher::SHOW_CACHING;
        delete $remoteObjects{$sessionKey}->{$reference};
    } else {
        print "  Already deleted $reference!\n"
          if $OME::Remote::Dispatcher::SHOW_CACHING;
    }
}

sub getObject {
    my ($sessionKey,$reference) = @_;

    $reference = xmlEscape('P',$reference);
    return undef if ($reference eq NULL_REFERENCE);

    my $object = $remoteObjects{$sessionKey}->{$reference};
    die "That object ($reference) does not exist"
      unless defined $object;

    return $object;
}

sub xmlEscape {
    my ($kind,$param) = @_;

    #print STDERR "**** xml $kind\n";
    if ($kind eq 'R') {
        #$param =~ s/\&/\&amp;/g;
        #$param =~ s/</\&lt;/g;
        #$param =~ s/>/\&gt;/g;
        #$param =~ s/\"/\&quot;/g;
        #$param =~ s/\'/\&apos;/g;
    } else {
        $param =~ s/\&amp;/\&/g;
        $param =~ s/\&lt;/</g;
        $param =~ s/\&gt;/>/g;
        $param =~ s/\&quot;/\"/g;
        $param =~ s/\&apos;/\'/g;
    }
    return $param;
}

sub getObjectReference {
    my ($sessionKey,$object) = @_;

    return NULL_REFERENCE unless defined $object;

    my $class = ref($object);

    # Maybe here I should check whether it's actually blessed.
    die "Cannot create reference on unblessed object"
      if (!$class);

    my $reference = $class."::".$object;

    my $cryptRef;

    if (exists $remoteReferences{$sessionKey}->{$reference}) {
        $cryptRef = $remoteReferences{$sessionKey}->{$reference};
    } else {
        #my $salt = join('',('.','/',0..9,'A'..'Z','a'..'z')[rand 64,rand 64]);
        #$cryptRef = ">>OBJ:".crypt($reference,$salt);
        $cryptRef = ">>OBJ:$object";
        $remoteReferences{$sessionKey}->{$reference} = $cryptRef;
    }

    if ($sessionKey eq ">>SESSIONS") {
        my $realSessionKey = $object->{SessionKey};
        $remoteReferences{$realSessionKey}->{$reference} = $cryptRef;
    }

    return $cryptRef;
}


sub deleteSessionObjects {
    my ($sessionKey) = @_;

    $remoteReferences{$sessionKey} = undef;
}


sub inputMarshaller {
    # $param is an object reference
    my ($param,$sessionKey) = @_;

    # Try to load in the cached object corresponding to the reference.
    my $object;
    eval {
        $object = getObject($sessionKey,$param);
    };
    return 0 if $@;

    # First result  - object to test for inheritance
    # Second result - value to place into parameter list given to Perl
    #                 method
    return (1,$object,$object);
}

sub outputMarshaller {
    # $param is a Perl object
    my ($param,$sessionKey) = @_;

    # Get the remote reference for the object, creating a new one if
    # necessary.
    my $reference = getObjectReference($sessionKey,$param);

    # Save the object into the cache
    saveObject($sessionKey,$reference,$param);

    #print STDERR "  output $param $reference\n";

    # First result  - object to test for inheritance
    # Second result - value to place into parameter list sent over RPC
    #                 channel
    return (1,$param,$reference);
}



=head1 AUTHOR

Douglas Creager (dcreager@alum.mit.edu)

=head2 SEE ALSO

L<OME::Remote||OME::Remote>,
L<OME::Remote::Prototypes|OME::Remote::Prototypes>

=cut

1;
