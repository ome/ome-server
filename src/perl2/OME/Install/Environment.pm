# OME/Install/Environment.pm
# The environment module for the OME installer and subsequent tasks. Used to 
# keep state and perform various operations on the environment itself.

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

package OME::Install::Environment;

use warnings;
use strict;

use File::Copy;
use File::Spec;
use Carp;
use OME::Install::Terminal;

# Internal platform IDs.
use constant UNKNOWN => 0;
use constant LINUX => 1;
use constant DARWIN => 2;
use constant HPUX => 3;
use constant SOLARIS => 4;
use constant FREEBSD => 5;
use constant WINDOWS => 6;
# ... and so on

# The ID of the platform we're running on (set in initialize ()).
my $platform = 0;

# Default OME user/group
my $OMEName = "ome";

# The singleton instance.
my $soleInstance = undef;

# This array contains platform-specific info and routine implementations.
# It is indexed with the platform IDs.
my @os_specific = ();

# Undetected platform.
$os_specific[UNKNOWN] = (
    {
	family => "UNKNOWN",
	name => "UNKNOWN",
	getMAC => sub { return ""; }
    }
);

# Linux-specific stuff.
$os_specific[LINUX] = (
    {
	family => "Linux",
	name => "UNKNOWN",
	distribution => "",
	getMAC => sub {
	    my @ifinfo = `/sbin/ifconfig eth0`;
	    my $macAddr = $ifinfo[0];
	    ($macAddr) = ($macAddr =~ /^.*HWaddr\s(.*[^\s])\s/);
	    chomp($macAddr);

	    return $macAddr;
	},
	adduser => sub {
	    my ($user, $homedir, $group) = @_;

	    return system("/usr/sbin/useradd -d $homedir -g $group -s /bin/false $user -c \"OME User\"") == 0 ? 1 : 0;
	},
	addgroup => sub {
	    my $group = shift;

	    return system ("/usr/sbin/groupadd $group") == 0 ? 1 : 0;
	}
    }
);

# Darwin-specific stuff.
$os_specific[DARWIN] = (
    {
	family => "Darwin",
	name => "UNKNOWN",
	getMAC => sub {
	    my @ifinfo = `/sbin/ifconfig`;
	    @ifinfo = grep(/ether/, @ifinfo);
	    chomp($ifinfo[0]);
	    my ($macAddr) = ($ifinfo[0] =~ /^.*ether\s(.*[^\s]).*/);
	    chomp($macAddr);

	    return $macAddr;
	}
    }
);

# HPUX-specific stuff.
$os_specific[HPUX] = (
    {
	family => "HPUX",
	name => "UNKNOWN", 
	getMAC => sub {
	    my @ifinfo = `lanscan`;
	    my $macAddr = $ifinfo[2];
	    $macAddr =~ s/^.*0x([0-9A-F]+).*$/$1/;
	    chomp($macAddr);

	    return $macAddr;
	}
    }
);

# Solaris-specific stuff.
$os_specific[SOLARIS] = (
    {
	family => "Solaris",
	name => "UNKNOWN",
	getMAC => sub {
	    my $macAddr = `ifconfig -a`;  # need to su, & then run ifconfig -a & use
	    $macAddr =~ s/.*ether: ([^ \t]+)$/$1/; # the colon separated string after 'ether'
	    chomp($macAddr);

	    return $macAddr;
	}
    }
);

# FreeBSD-specific stuff.
$os_specific[FREEBSD] = (
    {
	family => "FreeBSD",
	name => "UNKNOWN",
	getMAC => sub {
	    my @buf = `dmesg`;
	    @buf = grep(/Ethernet address/, @buf);
	    chomp($buf[0]);
	    my ($macAddr) = ($buf[0] =~ /^.*address\s(.*[^\s]).*/);
	    chomp($macAddr);

	    return $macAddr;
	}
    }
);


# Private constructor.
my $new = sub {
    my $self = {};
    return bless($self);
};

# Class method to return the singleton instance that deals with the platform
# we're running on.
#
# my $env = OME::Install::Environment->initialize();
#
sub initialize {
    my $class = shift;
    if( !$soleInstance ) { # first time we're called
        $platform = UNKNOWN;

        if 	($^O eq "linux") 	{ $platform = LINUX }
	elsif 	($^O eq "darwin") 	{ $platform = DARWIN }
	elsif 	($^O eq "hpux") 	{ $platform = HPUX }
	elsif 	($^O eq "sunos") 	{ $platform = SOLARIS }
	elsif 	($^O eq "freebsd") 	{ $platform = FREEBSD }

        $os_specific[$platform]->{name} = $^O;

        # Distribution detection
        if (-e "/etc/debian_version") {
            $os_specific[$platform]->{distribution} = "DEBIAN";
        } elsif (-e "/etc/redhat-release") {
            $os_specific[$platform]->{distribution} = "REDHAT";
        } elsif (-e "/etc/SuSE-release") {
	    $os_specific[$platform]->{distribution} = "SUSE";		
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

# Returns a hash ref whose keys are the names of the entries in the specified
# directory and whose values are their absolute paths.
#
# $env->scanDir($dir [, $filter]);
#
# $dir      Directory to scan. It must be a valid path either absolute or
#           relative to the working directory.
# $filter   Optional coderef to filter out the contents of the $dir directory.
#           If specified, it is evaluated for each element of $dir (locally
#           setting $_ to each element) in order to select the elements for
#           which the expression evaluated to true.
# DIES      If $dir can't be opened for reading.
#
# Example:
#
#   $env->scanDir("../C", sub{ ! /^\.{1,2}$/ });
#
# The above will return the contents of the C directory (contained in the parent
# directory of the working directory) with the exception of the . and ..
# entries. Notice that the hash values are absolute paths, even if $dir is
# relative.
#
sub scanDir {
    my $self = shift;
    my ($dir,$filter) = @_;
    my %contents = ();
    my $item;
    if( ref($filter) ne "CODE" ) {  # not passed or not valid
        $filter = sub{1};  # no filter
    }
    $dir = File::Spec->rel2abs($dir);  # does clean up as well
    opendir(DIR,$dir) or die "Couldn't open directory $dir. $!";
    while( $item = readdir(DIR) ) {
        local $_ = $item;
        if( &$filter ) {
            $contents{$_} = File::Spec->catfile($dir,$_);  # portable path
        }
    }
    closedir(DIR);
    return \%contents;
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
# DIES      If a dir can't be opened for reading or a new dir can't be made or
#           a file can't be copied.
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
    my ($from,$to,$filter) = @_;
    $from = File::Spec->rel2abs($from);  # does clean up as well
    $to = File::Spec->rel2abs($to);
    if ( ! -e $to ) {
	mkdir($to) or die("Couldn't make directory $to. $!.\n");
    }
    my $paths = $self->scanDir($from,sub{ ! /^\.{1,2}$/ }); #filter . and .. out
    my @entries = keys(%$paths);  # just names, no path
    # the above grabs all files and dirs except . and ..
    # portability issue: what are the equivalents of . and .. on OS other than
    # Unix and Win?
    if( ref($filter) eq "CODE" ) {  # filter out unwanted files and dirs
        @entries = grep {local $_=$_; &$filter} @entries;
    }
    my $x;
    foreach my $item (@entries) {  # if @entries is empty, we return
        $x = $paths->{$item};  # abs path of current entry
        if( -f $x ) {
            copy($x, $to) or die("Couldn't copy file $x. $!.\n");
        } elsif ( -d $x ) {
            $x = File::Spec->catdir($to,$item);  # portable path
            mkdir($x) or die("Couldn't make directory $x. $!.\n");
            $self->copyTree(File::Spec->catdir($from,$item),
                File::Spec->catdir($to,$item),$filter);
        }
    }
    return;
}

# Recursively deletes all files and directories contained in a given base
# directory - this is never deleted though. If a filter is specified, then only
# the matching items are deleted. Moreover, directories are removed only if
# their name matches the pattern and every contained element matches as well or
# the directory is empty.
#
# my $deleted = $env->deleteTree($base [, $filter]);
#
# $base     Directory containing the items to delete. It must be a valid path
#           either absolute or relative to the working directory.
# $filter   Optional coderef to filter out the contents of the $base directory.
#           If specified, it is evaluated for each element of $base (locally
#           setting $_ to each element) in order to select the elements for
#           which the expression evaluated to true.
# RETURNS   True only if the whole content of $base has been deleted.
# DIES      If a dir can't be opened for reading or a dir can't be removed
#           or a file can't be unlinked.
#
# Example:
#
#   $env->deleteTree("/OME", sub{ ! /^.userAddedSpecialInfo$/ });
#
# The above will get rid (recursively) of everything in the OME directory with
# the exception of files or directories named .userAddedSpecialInfo. Notice
# that if a subdirectory X contains a file named .userAddedSpecialInfo, then
# X won't be deleted.
#
sub deleteTree {
    my $self = shift;
    my ($base,$filter) = @_;
    $base = File::Spec->rel2abs($base);  # does clean up as well
    my $paths = $self->scanDir($base,sub{ ! /^\.{1,2}$/ }); #filter . and .. out
    # the above grabs all files and dirs except . and ..
    # portability issue: what are the equivalents of . and .. on OS other than
    # Unix and Win?
    my @to_delete = keys(%$paths);  # just names, no path
    my ($total_entries,$deleted) = (scalar(@to_delete),0);
    if( ref($filter) eq "CODE" ) {  # filter out files and dirs we don't delete
        @to_delete = grep {local $_=$_; &$filter} @to_delete;
    }
    foreach my $item (@to_delete) {  # if @to_delete is empty, block is skipped
        $item = $paths->{$item};  # abs path of current entry
        if( -f $item ) {
            unlink($item) or die("Couldn't delete file $item. $!.\n");
            $deleted++;
        } elsif ( -d $item ) {
            if($self->deleteTree($item,$filter)) {  # dir is empty
                rmdir($item) or die("Couldn't remove directory $item. $!.\n");
                $deleted++;
            } # if not empty, $filter didn't grab all contents in a leaf
        }
    }
    return  $total_entries==$deleted ? 1 : 0 ;
}

sub apacheUser {
    my $user;

    # Grab our Apache user from the password file
    open (PW_FILE, "<", "/etc/passwd") or croak ("Couldn't open /etc/passwd ", $!, "\n");
    while (<PW_FILE>) {
	chomp;
	$user = (split ":")[0];
	if ($user =~ /httpd|apache|www-data|www/) {
	    close (PW_FILE);
	    return $user;
	}
    }

    # We couldn't get the username from the password file so lets ask for it
    while (not $user) {
	$user = question ("Could not determine Apache user.\nWhat is the unix name that Apache runs under ?: ");
	if (not getpwname($user)) {
	    print "Invalid user \"$user\"!.";
	    $user = undef;
	}
    }

    close (PW_FILE);

    return $user;
}

sub OMEUser {
    my $self = shift;

    carp "Shouldn't be using this.";
    return undef;
}

sub adduser {
    my ($self, $user, $homedir, $group) = @_;
    my $adduser = $os_specific[$platform]->{adduser};

    return &$adduser($user, $homedir, $group);
}

sub addgroup {
    my ($self, $group) = @_;
    my $groupadd = $os_specific[$platform]->{addgroup};

    return &$groupadd($group);
}

1;
