# OME/Remote/Dispatcher.pm

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


package OME::Remote::Dispatcher;
our $VERSION = '1.00';

use strict;

use OME::SessionManager;
use OME::Session;
use OME::Factory;

use OME::Remote::Prototypes;


sub versionInfo {
    my ($proto) = @_;

    return {
            Version => '1.0',
            Host    => 'bob.com',
           };
}

sub createSession {
    my ($proto, $username, $password) = @_;

    my $session = OME::SessionManager->createSession($username,$password);
    die "Cannot create session"
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

    OME::SessionManager->deleteApacheSession($session->{ApacheSession});
    OME::Remote::Utils::deleteSessionObjects($sessionKey);

    return 1;
}


sub dispatch {
    my ($proto,$sessionRef,$objectRef,$method,@params) = @_;
    my $session = OME::Remote::Utils::getObject(">>SESSIONS",$sessionRef);
    my $sessionKey = $session->{SessionKey};

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

    print "Calling ${objectProto}->${method}\n";

    # Lookup the method's prototype
    die "Cannot find method $method in class $objectClass"
      if (!exists $OME::Remote::Prototypes::prototypes{$objectClass}->{$method});

    my $prototypes =
      $OME::Remote::Prototypes::prototypes{$objectClass}->{$method};

    my ($paramProto,$returnProto) = @$prototypes;
    die "Parameters do not match prototype"
      unless OME::Remote::Utils::verifyParameterList('P',\@params,$paramProto,
                                                    $sessionKey);

    my @result = $objectProto->$method(@params);

    die "Return value does not match prototype"
      unless OME::Remote::Utils::verifyParameterList('R',\@result,$returnProto,
                                                    $sessionKey);

    print "  (",join(",",@result),")\n";
    return @result;
}




# These functions exist in another package so that they aren't
# exported as SOAP methods.

package OME::Remote::Utils;
our $VERSION = '1.00';

use strict;

my %remoteReferences;
my %remoteObjects;

sub saveObject {
    my ($sessionKey,$reference,$object) = @_;
    print "Saving object ",ref($object)," $sessionKey/$reference\n";
    $remoteObjects{$sessionKey}->{$reference} = $object;
}

sub deleteObject {
    my ($sessionKey,$reference) = @_;
    print "Deleting object $reference\n";
    delete $remoteObjects{$sessionKey}->{$reference};
}

sub getObject {
    my ($sessionKey,$reference) = @_;

    $reference = xmlEscape('P',$reference);
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
    my $class = ref($object);

    # Maybe here I should check whether it's actually blessed.
    die "Cannot create reference on unblessed object"
      if (!$class);

    my $reference = $class."::".$object;
    #print STDERR "$object\n  -> $reference\n";

    my $cryptRef;

    if (exists $remoteReferences{$sessionKey}->{$reference}) {
        $cryptRef = $remoteReferences{$sessionKey}->{$reference};
    } else {
        my $salt = join('',('.','/',0..9,'A'..'Z','a'..'z')[rand 64,rand 64]);
        $cryptRef = ">>OBJ:".crypt($reference,$salt);
        $remoteReferences{$sessionKey}->{$reference} = $cryptRef;
    }

    if ($sessionKey eq ">>SESSIONS") {
        my $realSessionKey = $object->{SessionKey};
        $remoteReferences{$realSessionKey}->{$reference} = $cryptRef;
    }

    #print STDERR "  -> $cryptRef\n";
    return $cryptRef;
}


sub deleteSessionObjects {
    my ($sessionKey) = @_;

    foreach my $reference (keys %{$remoteReferences{$sessionKey}}) {
        my $cryptRef = $remoteReferences{$sessionKey}->{$reference};
        deleteObject($sessionKey,$cryptRef);
    }

    $remoteReferences{$sessionKey} = {};
}


sub verifyParameterType {
    my ($kind,$param,$type,$sessionKey) = @_;
    my $ref = ref($param);

    #print STDERR "    $kind - $param $ref $type \n";

    if ($type eq '$') {
        # Function expects a single scalar
        $_[1] = xmlEscape($kind,$param);
        return !$ref;
    }

    if ($type eq '@') {
        # Function expects an array reference
        return $ref eq "ARRAY";
    }

    if ($type eq '%') {
        # Function expects a hash reference
        return $ref eq "HASH";
    }

    if (ref($type) eq "ARRAY") {
        return verifyParameterList($kind,$param,$type,$sessionKey);
    }

    if ($kind eq 'P') {
        my $object;
        eval {
            $object = getObject($sessionKey,$kind,$param);
        };
        return 0 if $@;

        if (UNIVERSAL::isa($object,$type)) {
            # Replace the object reference with the object in the
            # parameter list.
            $_[1] = $object;
            return 1;
        } else {
            return 0;
        }
    } else {
        if (UNIVERSAL::isa($param,$type)) {
            # Replace the object with its reference.
            my $reference = getObjectReference($sessionKey,$param);
            saveObject($sessionKey,$reference,$param);
            $_[1] = $reference;
            return 1;
        } else {
            return 0;
        }
    }
}



sub verifyParameterList {
    my ($kind,$params,$types,$sessionKey) = @_;

    return 0 if ref($params) ne "ARRAY";

    my @types = (@$types);
    my $lastType;
    my $currentType = shift(@types);
    foreach my $param (@$params) {
        return 0 unless defined $currentType;

        my $typeToCheck =
          $currentType eq "*"? $lastType: $currentType;

        return 0 unless defined $typeToCheck;
        return 0 unless verifyParameterType($kind,$param,
                                            $typeToCheck,$sessionKey);

        if ($currentType ne "*") {
            $lastType = $currentType;
            $currentType = shift(@types);
        }
    }

    return 1;
}


1;
