# OME/Intall/Environment.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:
#
#	 This library is free software; you can redistribute it and/or
#	 modify it under the terms of the GNU Lesser General Public
#	 License as published by the Free Software Foundation; either
#	 version 2.1 of the License, or (at your option) any later version.
#
#	 This library is distributed in the hope that it will be useful,
#	 but WITHOUT ANY WARRANTY; without even the implied warranty of
#	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#	 Lesser General Public License for more details.
#
#	 You should have received a copy of the GNU Lesser General Public
#	 License along with this library; if not, write to the Free Software
#	 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


package OME::Install::Environment;

use strict;
use vars qw($VERSION);
$VERSION = 2.000_000;

use File::Copy;



# Internal platform IDs.
my $UNKNOWN = 0;
my $LINUX = 1;
my $DARWIN = 2;
my $HPUX = 3;
my $SUN = 4;
my $FREE_BSD = 5;
my $WINDOWS = 6;
# ... and so on

# The ID of the platform we're running on (set in getInstance).
my platform = 0;

# The singleton instance.
my soleInstance = undef;


# This array contains platform-specific info and routine implementations.
# It is indexed with the platform IDs.
# The platform-specific comprises just the OS family and name. The only specific
# routine implementation is getMAC. If, in future, we'll have more
# platform-specific stuff, then we can refactor the array entries into classes
# that extend this Environment class.
my @os_specific = ();

# Undetected platform.
@os_specific[$UNKNOWN] = { family => "UNKNOWN", name => "UNKNOWN" };
@os_specific[$UNKNOWN] = { getMAC =>
    sub {
        return "";
    }
};

# Linux-specific stuff.
@os_specific[$LINUX] = { family => "Linux", name => "UNKNOWN",
                            distribution => "" };
@os_specific[$LINUX] = { getMAC =>
    sub {
        my @ifinfo = `/sbin/ifconfig eth0`;
        my $macAddr = $ifinfo[0];
        $macAddr =~ s/^.*HWaddr\s+(.*)$/$1/;
        chomp($macAddr);
        return $macAddr;
    }
};

# Darwin-specific stuff.
@os_specific[$DARWIN] = { family => "Darwin", name => "UNKNOWN" };
@os_specific[$DARWIN] = { getMAC =>
    sub {
        my @ifinfo = `/sbin/ifconfig`;
        my $macAddr;
        # Get the first line containing the word 'ether', then set the adress to
        # everything after 'ether'
        foreach (@ifinfo) {
            if ($_ =~ /ether\s+(.*)$/) {$macAddr = $1;last;};
        }
        chomp($macAddr);
        return $macAddr;
    }
};

# HPUX-specific stuff.
@os_specific[$HPUX] = { family => "HPUX", name => "UNKNOWN" };
@os_specific[$HPUX] = { getMAC =>
    sub {
        my @ifinfo = `lanscan`;
        my $macAddr = $ifinfo[2];
        $macAddr =~ s/^.*0x([0-9A-F]+).*$/$1/;
        chomp($macAddr);
        return $macAddr;
    }
};

# Sun-specific stuff.
@os_specific[$SUN] = { family => "SUN", name => "UNKNOWN" };
@os_specific[$SUN] = { getMAC =>
    sub {
        my $macAddr = `ifconfig -a`;  # need to su, & then run ifconfig -a & use
        $macAddr =~ s/.*ether: ([^ \t]+)$/$1/  # the colon separated string after 'ether'
        chomp($macAddr);
        return $macAddr;
    }
};

# FreeBSD-specific stuff.
@os_specific[$FREE_BSD] = { family => "FreeBSD", name => "UNKNOWN" };
@os_specific[$FREE_BSD] = { getMAC =>
    sub {
        my $macAddr = $macAddr = `dmefg`;
        chomp($macAddr);
        return $macAddr;
    }
};

# Windows-specific stuff.
@os_specific[$WINDOWS] = { family => "Windows", name => "UNKNOWN" };
@os_specific[$WINDOWS] = { getMAC =>
    sub {
        my $macAddr = `ipconfig \all`;
        $macAddr =~ s/^.*([0-9A-F][0-9A-F]-[0-9A-F][0-9A-F]-[0-9A-F][0-9A-F]-[0-9A-F][0-9A-F]-[0-9A-F][0-9A-F]-[0-9A-F][0-9A-F]).*$/$1/;
        chomp($macAddr);
        return $macAddr;
    }
};





# Private constructor.
my $new = sub {
    my $self = {};
    bless($self,"OME::Install::Environment");
    return $self;
};

# Class  method to return the singleton instance that deals with the platform
# we're running on.
#
# my $env = OME::Install::Environment->getInstance();
#
sub getInstance {
    my $class = shift;
    if( !soleInstance ) { # first time we're called
        $platform = $UNKNOWN;
        my $os_name = `uname -s`;   # assumes POSIX compliant uname cmnd
        if ($os_name =~ /Linux/) {
            $platform = $LINUX;
        } elsif ($os_name =~ /Darwin/) {
            $platform = $DARWIN;
        } elsif ($os_name =~ /HPUX/) {
            $platform = $HPUX;
        } elsif ($os_name =~ /(Solaris)|(SunOS)|(sunos)/) {
            $platform = $SUN;
        } elsif ($os_name =~ /FreeBSD/) {
            $platform = $FREE_BSD;
        } else ($os_name =~ /MS-DOS/) {    # good luck running on NT
            $platform = $WINDOWS;
        }
        @os_specific[$platform]->{name} = $os_name;
        #Checking for the existance of a Debian/RedHat system
        # FIXME: We really should have something here for OS X, and the BSD's
        #           ... and the others?
        if (-e "/etc/debian_version") {
            @os_specific[$platform]->{distribution} = "DEBIAN";
        } else (-e "/etc/redhat-release") {
            @os_specific[$platform]->{distribution} = "REDHAT";
        }
        # Create the singleton
        $soleInstance = &$new();
    }
    return $soleInstance;
}

# Returns the MAC address (as string) of the machine we're running on. An empty
# string is returned if it wasn't possible to find out the MAC.
#
# my $macAddr = $env->getMAC();
#
sub getMAC {
    my $self = shift;
    my $getMAC = $os_specific[$platform]->{getMAC};
    return &$getMAC();
}

# Recursively copies all files and directories contained in a given origin
# directory to the specified destination directory.
#
# $env->copyTree($from, $to [, $filter]);
#
# $from     Directory to copy contents from. It must be a valid path either
#           absolute or relative to the working directory.
# $to       Directory to copy contents to. It must be a valid path either
#           absolute or relative to the working directory.
# $filter   Optional coderef to filter out the contents of the $from directory.
#           If specified, it is evaluated for each element of $from (locally
#           setting $_ to each element) in order to select the elements for
#           which the expression evaluated to true.
#
# Example:
#
#   $env->copyTree("../C", "/OME/C", sub{ ! /CVS$/i });
#
# The above will copy (recursively) the contents of the C directory (contained
# in the parent directory of the working directory) into /OME/C with the
# exception of CVS directories.
#
sub copyTree {
    my $self = shift;
    my ($from, $to, $filter) = @_;
    my $event;
    my @dir_contents = glob("$from/*");  # grab all files and dirs
    if( ref($filter) eq "CODE" ) {  # filter out unwanted files and dirs
        @dir_contents = grep {local $_=$_; &$filter} @dir_contents;
    }
    foreach my $item (@dir_contents) {  # if @dir_contents is empty, we return
        if( -f $item ) {
            copy($item,$to) || die("Couldn't copy file $item. $!.\n");
        } elsif ( -d $item ) {
            $item =~ s/(.*\/)?(.*)/$+/s;  # strip path out
            mkdir("$to/$item") ||
                die("Couldn't make directory $to/$item. $!.\n");
            copyTree("$from/$item","$to/$item",$filter);
        }
    }
}

