# OME/Install/Util.pm
# This module includes the utility functions used by the installer. You are of
# course free to use this module anywhere else as well.

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institue of Technology,
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

package OME::Install::Util;

#*********
#********* INCLUDES
#*********

use strict;
use warnings;
use English;
use Carp;
use File::Copy;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;

require Exporter;

#*********
#********* GLOBALS AND DEFINES
#*********

# Exporter details
our @ISA = qw(Exporter);
our @EXPORT = qw(add_user add_group delete_tree copy_tree get_module_version);

# Distribution detection
#        if (-e "/etc/debian_version") {
#            $os_specific[$platform]->{distribution} = "DEBIAN";
#        } elsif (-e "/etc/redhat-release") {
#            $os_specific[$platform]->{distribution} = "REDHAT";
#        } elsif (-e "/etc/SuSE-release") {
#	    $os_specific[$platform]->{distribution} = "SUSE";		
#	}


my %os_specific = (
    # Linux specific stuff.
    linux => { 
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

	add_user => sub {
	    my ($user, $homedir, $group) = @_;

	    return system("/usr/sbin/useradd -d $homedir -g $group -s /bin/false $user -c \"OME User\"") == 0 ? 1 : 0;
	},

	add_group => sub {
	    my $group = shift;

	    return system ("/usr/sbin/groupadd $group") == 0 ? 1 : 0;
	},
    },

    # Darwin (Mac OS X) specific stuff
    darwin => {
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
    },

    # HP-UX specific stuff
    # XXX: This is basically an unsupported platform at the moment
    hpux => {
	family => "HPUX",
	name => "UNKNOWN", 
	getMAC => sub {
	    my @ifinfo = `lanscan`;
	    my $macAddr = $ifinfo[2];
	    $macAddr =~ s/^.*0x([0-9A-F]+).*$/$1/;
	    chomp($macAddr);

	    return $macAddr;
	},
	
	add_user => sub {
	    my $user = shift;

	    carp "Unsupported adduser() platform, please create the user \"$user\" manually";

	    return undef;
	},

	add_group => sub {
	    my $group = shift;

	    carp "Unsupported addgroup() platform, please create the group  \"$group\"manually";

	    return undef;
	},
    },
    
    # Solaris specific stuff
    solaris => {
	family => "Solaris",
	name => "UNKNOWN",
	getMAC => sub {
	    my $macAddr = `ifconfig -a`;  # need to su, & then run ifconfig -a & use
	    $macAddr =~ s/.*ether: ([^ \t]+)$/$1/; # the colon separated string after 'ether'
	    chomp($macAddr);

	    return $macAddr;
	},
	
	add_user => sub {
	    my ($user, $homedir, $group) = @_;

	    return system("/usr/sbin/useradd -d $homedir -g $group -s /bin/false $user -c \"OME User\"") == 0
		? 1 : 0;
	},
	
	add_group => sub {
	    my $group = shift;

	    return system ("/usr/sbin/groupadd $group") == 0 ? 1 : 0;
	},
    },

    # FreeBSD specific stuff
    freebsd => {
	family => "FreeBSD",
	name => "UNKNOWN",
	getMAC => sub {
	    my @buf = `dmesg`;
	    @buf = grep(/Ethernet address/, @buf);
	    chomp($buf[0]);
	    my ($macAddr) = ($buf[0] =~ /^.*address\s(.*[^\s]).*/);
	    chomp($macAddr);

	    return $macAddr;
	},

	add_user => sub {
	    my ($user, $homedir, $group) = @_;

	    return system("/usr/sbin/pw useradd $user -d $homedir -g $group -s /bin/false -c \"OME User\"") == 0
		? 1 : 0;
	},

	add_group => sub {
	    my $group = shift;

	    return system ("/usr/sbin/pw groupadd $group") == 0 ? 1 : 0;
	}

    }
);

#*********
#********* LOCAL SUBROUTINES
#*********

# Returns a hash ref whose keys are the names of the entries in the specified
# directory and whose values are their absolute paths.
#
# my %contents = scan_dir($dir [, $filter]);
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
#   my %contents = scan_dir("../C", sub{ ! /^\.{1,2}$/ });
#
# The above will return the contents of the C directory (contained in the parent
# directory of the working directory) with the exception of the . and ..
# entries. Notice that the hash values are absolute paths, even if $dir is
# relative.
#

sub scan_dir {
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

#*********
#********* EXPORTED SUBROUTINES
#*********

sub add_user {
    my ($user, $homedir, $group) = @_;
    my $add_user = $os_specific{$OSNAME}->{add_user};

    return &$add_user($user, $homedir, $group);
}

sub add_group {
    my ($group) = shift;
    my $add_group = $os_specific{$OSNAME}->{add_group};

    return &$add_group($group);
}
# Recursively copies all files and directories contained in a given origin
# directory to the specified destination directory.
#
# copy_tree($from, $to [, $filter]);
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
#   copy_tree("../C", "/OME/C", sub{ ! /CVS$/i });
#
# The above will copy (recursively) the contents of the C directory (contained
# in the parent directory of the working directory) into /OME/C with the
# exception of CVS directories.
#

sub copy_tree {
    my ($from,$to,$filter) = @_;
    $from = File::Spec->rel2abs($from);  # does clean up as well
    $to = File::Spec->rel2abs($to);

    if ( ! -e $to ) {
	mkdir($to) or die("Couldn't make directory $to. $!.\n");
    }

    my $paths = scan_dir($from,sub{ ! /^\.{1,2}$/ }); #filter . and .. out
    my @entries = keys(%$paths);  # just names, no path

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
            copy_tree(File::Spec->catdir($from,$item),
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
# my $deleted = delete_tree($base [, $filter]);
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
#   my $deleted = delete_tree("/OME", sub{ ! /^.userAddedSpecialInfo$/ });
#
# The above will get rid (recursively) of everything in the OME directory with
# the exception of files or directories named .userAddedSpecialInfo. Notice
# that if a subdirectory X contains a file named .userAddedSpecialInfo, then
# X won't be deleted.
#

sub delete_tree {
    my ($base,$filter) = @_;

    $base = File::Spec->rel2abs($base);  # does clean up as well
    my $paths = scan_dir($base,sub{ ! /^\.{1,2}$/ }); #filter . and .. out
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
            if(delete_tree($item,$filter)) {  # dir is empty
                rmdir($item) or die("Couldn't remove directory $item. $!.\n");
                $deleted++;
            } # if not empty, $filter didn't grab all contents in a leaf
        }
    }

    return  $total_entries==$deleted ? 1 : 0 ;
}


# Gets a Perl module's $VERSION
#
# RETURNS	The module version as a scalar if the module is found and a
#		version is returned.
# 		Undef if the module is not installed or returns no $VERSION.
sub get_module_version {
    my $module = shift;
    my $version;
    my $eval = "use $module;".'$version = $'.$module.'::VERSION;';

    eval($eval);

    # Populate the errors back to the caller
    #$! = $@ if $@;

    return $version ? $version : undef;
}

1;
