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
use File::Basename;
use Cwd;
use File::Spec::Functions qw(rel2abs rootdir updir canonpath splitpath splitdir catdir catpath);

require Exporter;

#*********
#********* GLOBALS AND DEFINES
#*********

# Exporter details
our @ISA = qw(Exporter);
our @EXPORT = qw(
		add_user
		add_group
		add_user_to_group
		delete_tree
		copy_tree
		fix_ownership
		fix_permissions
		get_module_version
		download_package
		unpack_archive
		configure_module
		configure_library
		compile_module
		test_module
		test_module_as_user
		install_module
		normalize_path
		path_in_tree
		which
		get_mac
		);

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

	get_mac => sub {
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

	    (system ("/usr/sbin/groupadd $group") == 0) or return 0;
	},

	# XXX: In order to add a user to a group in Linux without modifying the /etc/group file by hand
	#      we first need to search for the user in every group, then allow usermod to work it's magic.
	add_user_to_group => sub {
	    my ($user, $group) = @_;
	    my @groups;

	    open (GR_FILE, "/etc/group") or croak "Unable to open /etc/group. $!";

	    # Search the group file for groups that the user is in
	    while (<GR_FILE>) {
		chomp;
		my ($group_name, $member_string) = (split (/:/, $_))[0,3];  # ($groupname, $password, $gid, $members)
		my @members = split (/,/, $member_string) if $member_string or undef;

		if (@members) {
		    foreach my $member (@members) {
			push (@groups, $group_name) if $user eq $member;
		    }
		}
	    }
	    close (GR_FILE);

	    push (@groups, $group);

	    return system ("/usr/sbin/usermod -G " . join (",", @groups) . " $user") == 0 ? 1 : 0;
	}
    },

    # Darwin (Mac OS X) specific stuff
    darwin => {
	family => "Darwin",
	name => "UNKNOWN",

	get_mac => sub {
	    my @ifinfo = `/sbin/ifconfig`;
	    @ifinfo = grep(/ether/, @ifinfo);
	    chomp($ifinfo[0]);
	    my ($macAddr) = ($ifinfo[0] =~ /^.*ether\s(.*[^\s]).*/);
	    chomp($macAddr);

	    return $macAddr;
	},

	# XXX: Since OS X is braindead and has no useradd commands we have to do the whole thing ourselves.
	add_user => sub {
	    my ($user, $homedir, $group) = @_;
	    my $uid;

	    my $gid = getgrnam ($group);
	    my @uids = `nireport / /users uid`;
	    if ($? == 0) {
		@uids = sort {$a <=> $b} @uids;
		$uid = ++$uids[$#uids];  # Value of the last element plus one
	    } else { return 0 }

	    (system ("nicl / -create /users/$user uid $uid") == 0) or return 0;
	    (system ("nicl / -create /users/$user gid $gid") == 0) or return 0;
	    # XXX: OS X prefers /dev/null for its null shells
	    (system ("nicl / -create /users/$user shell /dev/null") == 0) or return 0;
	    (system ("nicl / -create /users/$user home $homedir") == 0) or return 0;
	    (system ("nicl / -create /users/$user realname \"OME User\"") == 0) or return 0;
	    (system ("nicl / -create /users/$user passwd \'\*\'") == 0) or return 0;

	    return 1;
	},

	# XXX: Once again, since we've got no groupadd command either we have to do the whole thing ourselves.
	add_group => sub {
	    my $group = shift;
	    my $gid;

	    my @gids = `nireport / /groups gid`;
	    if ($? == 0) {
		@gids = sort {$a <=> $b} @gids;
		$gid = ++$gids[$#gids];  # Value of the last element plus one
	    } else { return 0 }

	    (system ("nicl / -create /groups/$group gid $gid") == 0) or return 0;
	    (system ("nicl / -create /groups/$group passwd \'\*\'") == 0) or return 0;

	    return 1;
	},

	# XXX: This is about the only thing that's easier in OS X, and *much* easier it is, a single command.
	#      In addition, it's semi-intelligent, the -merge NetInfo flag won't add a user to a group if he/she
	#      is already a member.
	add_user_to_group => sub {
	    my ($user, $group) = @_;
	    
	    (system ("nicl / -merge /groups/$group users $user") == 0) or return 0;
	}

    },

    # HP-UX specific stuff
    # XXX: This is basically an unsupported platform at the moment
    hpux => {
	family => "HPUX",
	name => "UNKNOWN", 
	get_mac => sub {
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

	    carp "Unsupported addgroup() platform, please create the group \"$group\"manually";

	    return undef;
	},
    },
    
    # Solaris specific stuff
    solaris => {
	family => "Solaris",
	name => "UNKNOWN",
	get_mac => sub {
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
	get_mac => sub {
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
	},

	# XXX: See the linux implementation of add_user_to_group () for more details.
	add_user_to_group => sub {
	    my ($user, $group) = @_;
	    my @groups;

	    open (GR_FILE, "/etc/group") or croak "Unable to open /etc/group. $!";

	    # Search the group file for groups that the user is in
	    while (<GR_FILE>) {
		chomp;
		my ($group_name, $member_string) = (split (/:/, $_))[0,3];  # ($groupname, $password, $gid, $members)
		my @members = split (/,/, $member_string) if $member_string or undef;

		if (@members) {
		    foreach my $member (@members) {
			push (@groups, $group_name) if $user eq $member;
		    }
		}
	    }
	    close (GR_FILE);

	    push (@groups, $group);

	    return system ("/usr/sbin/pw usermod -G " . join (",", @groups) . " $user") == 0 ? 1 : 0;
	}

    }
);

#*********
#********* LOCAL SUBROUTINES
#*********

# Returns an array of files with the filter removed, each value returned is an
# absolute path.
#
# my @contents = scan_dir($dir, $filter);
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
#   my @contents = scan_dir("../C", sub{ ! /^\.{1,2}$/ });
#
# The above will return the contents of the C directory (contained in the parent
# directory of the working directory) with the exception of the . and ..
# entries. Notice that the values are absolute paths, even if $dir is
# relative.
#

sub scan_dir {
    my ($dir, $filter) = @_;
    my (@files, @contents);

    $dir = File::Spec->rel2abs($dir);  # does clean up as well

    opendir(DIR, $dir) or croak "Couldn't open directory $dir $!";

    if( ref($filter) eq "CODE" ) {
		@files = grep { &$filter } readdir(DIR);
    } else {
		@files = readdir(DIR);
	}

	closedir(DIR);

	foreach (@files) {
		push(@contents, File::Spec->catfile($dir, $_));
	}
			
	return @contents;
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
    my $group = shift;

    my $add_group = $os_specific{$OSNAME}->{add_group};

    return &$add_group($group);
}

sub add_user_to_group {
    my ($user, $group) = @_;

    my $add_user_to_group = $os_specific{$OSNAME}->{add_user_to_group};

    return &$add_user_to_group($user, $group);
}

sub get_mac {
    my $get_mac = $os_specific{$OSNAME}->{get_mac};

    return &$get_mac;
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
    my ($from, $to, $filter, $user) = @_;
    my ($uid, $gid);

    $from = File::Spec->rel2abs($from);  # does clean up as well
    $to = File::Spec::->catdir(File::Spec->rel2abs($to), basename($from));

	unless (-d $from) { croak "OME::Install::Util::copy_tree() can only operate on directories. While copying '$from', $!" }

    unless (-e $to) { mkdir($to) or croak "Couldn't make directory $to: $!" }

    my @paths = scan_dir($from,sub{ ! /^\.{1,2}$/ });  #filter . and .. out

    if( ref($filter) eq "CODE" ) {  # filter out unwanted files and dirs
        @paths = grep { &$filter } @paths;
    }

    foreach my $item (@paths) {  # if @paths is empty, we return
        if ( -l $item ) {
			carp "copy_tree() not copying or following symlink $item";
		} elsif (-f $item) {
			copy($item, $to) or croak "Couldn't copy file $item: $!";
        } elsif ( -d $item ) {
			copy_tree($item, $to, $filter, $user);
		} else {
			carp "copy_tree() not copying device or other filetype $item";
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
	# FIXME delete_tree() needs to be ported to the new scan_dir() which uses
	# arrays, not hashrefs.
	croak ("delete_tree() functionality disabled");


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

# Fixes the ownership (owner, group) of a given set of filesystem items
# fix_ownership({owner => 'foo', group => 'bar'}, @items);
#
# RETURNS
#	1 on success, dies on failure.
sub fix_ownership {
    my ($o_and_g, @items) = @_;
	
	croak ("Owner/group hashref required.") unless ref($o_and_g) eq 'HASH';	

	# No point traversing any further unless we actually have something to do
	return 1 if (scalar(@items) < 1);

    my $uid;
    if (exists $o_and_g->{'owner'}) {
    	$uid = getpwnam($o_and_g->{'owner'})
			or croak "Unable to find user: \"", $o_and_g->{'owner'}, "\"";
	}
	
    my $gid;
    if (exists $o_and_g->{'group'}) {
    	$gid = getgrnam($o_and_g->{'group'})
			or croak "Unable to find group: \"", $o_and_g->{'group'}, "\"";
	}

	my @stat;
	while (my $item = shift @items) {
		# Just do a full chown, no harm in doing both if we only need one or
		# not at all.
		# XXX We're not following symlinks.
		fix_ownership($o_and_g, glob ("$item/*")) if (-d $item);
		
		$uid = (stat ($item))[4] unless defined $uid;
		$gid = (stat ($item))[5] unless defined $gid;
		chown ($uid, $gid, $item) or croak "Unable to change owner of $item, $!";
	}

	return 1;
}

# Fixes the permissions (mode) of a given set of filesystem items
# fix_permissions($mode, @items);
#
# RETURNS
#	1 on success, dies on failure.
sub fix_permissions {
    my ($options, @items) = @_;
	croak ("recurse/mode hashref required.") unless ref($options) eq 'HASH';	

	# No point traversing any further unless we actually have something to do
	return 1 if (scalar(@items) < 1);

	while (my $item = shift @items) {
		# Just do a full chown, no harm in doing both if we only need one or
		# not at all.
		# XXX We're not following symlinks.
		if (-d $item and $options->{'recurse'}) {
			fix_permissions( {
					mode => $options->{'mode'},
					recurse => 1,
				}, glob ("$item/*"));
		}
		
		chmod ($options->{'mode'}, $item)
			or croak "Unable to change permissions (", $options->{'mode'}, "of $item, $!";
	}

	return 1;
}

# Checks the specified acess modes (r,w,x) of a given set of filesystem items
# for the specified user.
# check_permissions($options, @items);
#  options->{user} - username
#  options->{recurse} - recursive or not
#  Will check the following modes if the corresponding hash keys exist
#  options->{r}
#  options->{w}
#  options->{x}
#
# RETURNS
#	1 on success, 0 on failure.
sub check_permissions {
    my ($options, @items) = @_;
	croak ("user/mode hashref required.") unless ref($options) eq 'HASH';	


	# No point traversing any further unless we actually have something to do
	return 1 if (scalar(@items) < 1);

	# Save current euid, and set it to the specified user.
	my $old_euid = $EUID;
	$EUID = getpwnam($options->{'user'})
		or croak "Unable to find user: \"", $options->{'user'}, "\"";

	my $ret_val = 1;
	while (my $item = shift @items) {
		# XXX We're not following symlinks.
		if (-d $item and $options->{'recurse'}) {
			check_permissions($options, glob ("$item/*"));
		}
		
		if (exists $options->{r}) {
			if (not -r $item) {
				$ret_val = 0;
				last;
			}
		}
		
		if (exists $options->{w}) {
			if (not -w $item) {
				$ret_val = 0;
				last;
			}
		}
		
		if (exists $options->{x}) {
			if (not -x $item) {
				$ret_val = 0;
				last;
			}
		}
	}
	
	$EUID = $old_euid;
	return $ret_val;
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

    return $version ? $version : undef;
}

sub download_package {
    my ($package, $logfile) = @_;
    my $package_url = $package->{repository_file};
    my $downloader;

    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    # Find a useable download app (curl|wget)
    $downloader = 'wget -nv -N' if which ("wget");
    $downloader = 'curl -O' if which ("curl") and not $downloader;
    $downloader = whereis ("wget")
	or croak "Unable to find a suitable downloader for \"$package->{name}\", please install either curl or wget."
    unless $downloader;

    my @output = `$downloader $package_url 2>&1`;
    
    if ($? == 0) {
	print $logfile "SUCCESS DOWNLOADING PACKAGE -- OUTPUT FROM DOWNLOADER \"$downloader\": \"@output\"\n\n";

	return 1;
    }
    
    print $logfile "ERRORS DOWNLOADING MODULE -- OUTPUT FROM DOWNLOADER \"$downloader\": \"@output\"\n\n";

    return 0;
}

sub unpack_archive {
    my ($archive_path, $logfile) = @_;
    my ($filename, $wd);
    my $iwd = getcwd ();  # Initial working directory
    
    # Expand our relative archive path to an absolute one
    $archive_path = rel2abs ($archive_path);

    # Parse out our working directory and filename
    ($filename, $wd) = fileparse ("$archive_path");

    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    chdir ($wd) or croak "Unable to chdir into \"$wd\". $!";

    my @output = `tar zxf $filename 2>&1`;

    if ($? == 0) {
	print $logfile "SUCCESS EXTRACTING ",$wd,$filename,"\n\n";

	chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	return 1;
    } 

    print $logfile "FAILURE EXTRACTING ",$wd,$filename," -- OUTPUT FROM TAR: \"@output\"\n\n";
    chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";

    return 0;
}

sub configure_module {
    my ($path, $logfile, @options) = @_;
    my $iwd = getcwd ();  # Initial working directory
    
    # Expand our relative path to an absolute one
    $path = rel2abs ($path);

    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

	my @output;

	if (-e 'Makefile.PL') {
		# IGG 12/12/03:  Doing a make realclean in case there's old stuff hidden away in there
		# was getting occasional mysterious errors with OME's modules when re-installing.
		# Not sure why, but they seemed to be related to 'use' statements for other OME modules
		# BTW, we're just going to ignore anything that goes wrong here.
    	`make realclean 2>&1`;

		print $logfile "USING PERL CONFIGURE SCRIPT -- \"Makefile.pl\"\n\n";
    	@output = `perl Makefile.PL @options 2>&1`;
	} elsif (-e 'configure') {
		print $logfile "USING C CONFIGURE SCRIPT -- \"configure\"\n\n";

		`make clean 2>&1`;
		@output = `./configure @options 2>&1`;
	} elsif (-e 'autogen.sh') {
		print $logfile "USING C CONFIGURE/AUTOCONF/AUTOMAKE SCRIPT -- \"autogen.sh\"\n\n";
		
		`make clean 2>&1`;
		@output = `./autogen.sh @options 2>&1`;
	} else {
		print $logfile "UNABLE TO LOCATE SUITABLE CONFIGURE SCRIPT\n\n";
	}

	if ($? == 0) {
		print $logfile "SUCCESS CONFIGURING MODULE -- OUTPUT: \"@output\"\n\n";

		chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
		return 1;
	}

	print $logfile "FAILURE CONFIGURING MODULE -- OUTPUT: \"@output\"\n\n";
	chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";

	return 0;
}

sub configure_library {
    my ($path, $logfile) = @_;
    my $iwd = getcwd ();  # Initial working directory
    
    # Expand our relative path to an absolute one
    $path = rel2abs ($path);
    
    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

    my @output = `./configure 2>&1`;

    if ($? == 0) {
	print $logfile "SUCCESS CONFIGURING LIBRARY -- OUTPUT: \"@output\"\n\n";

	chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	return 1;
    }

    print $logfile "FAILURE CONFIGURING LIBRARY -- OUTPUT: \"@output\"\n\n";
    chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";

    return 0;
}

sub compile_module {
    my ($path, $logfile) = @_;
    my $iwd = getcwd ();  # Initial working directory
    
    # Expand our relative path to an absolute one
    $path = rel2abs ($path);
    
    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

    my @output = `make 2>&1`;

    if ($? == 0) {
	print $logfile "SUCCESS COMPILING MODULE -- OUTPUT: \"@output\"\n\n";

	chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	return 1;
    }
    
    print $logfile "FAILURE COMPILING MODULE -- OUTPUT: \"@output\"\n\n";
    chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";

    return 0;
}

sub test_module {
    my ($path, $logfile) = @_;
    my $iwd = getcwd ();  # Initial working directory
    
    # Expand our relative path to an absolute one
    $path = rel2abs ($path);
    
    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

    my @output = `make test 2>&1`;

    if ($? == 0) {
	print $logfile "SUCCESS TESTING MODULE -- OUTPUT: \"@output\"\n\n";

	chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	return 1;
    }

    print $logfile "FAILURE TESTING MODULE -- OUTPUT: \"@output\"\n\n";
    chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";

    return 0;
}

sub test_module_as_user {
    my ($path, $logfile, @user_name) = @_;
    my $iwd = getcwd ();  # Initial working directory
    
    # Expand our relative path to an absolute one
    $path = rel2abs ($path);
    
    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    chdir ($path) or croak "Unable to chdir into \"$path\". $!";

    my @output = `sudo -u @user_name make test 2>&1`;

    if ($? == 0) {
	print $logfile "SUCCESS TESTING MODULE -- OUTPUT: \"@output\"\n\n";

	chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	return 1;
    }

    print $logfile "FAILURE TESTING MODULE -- OUTPUT: \"@output\"\n\n";
    chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";

    return 0;
}

sub install_module {
    my ($path, $logfile) = @_;
    my $iwd = getcwd ();  # Initial working directory
    
    # Expand our relative path to an absolute one
    $path = rel2abs ($path);

    $logfile = *STDERR unless ref ($logfile) eq 'GLOB';

    chdir ($path) or croak "Unable to chdir into \"$path\". $!";
    my @output = `make install 2>&1`;

    if ($? == 0) {
	print $logfile "SUCCESS INSTALLING MODULE -- OUTPUT: \"@output\"\n\n";

	chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";
	return 1;
    }

    print $logfile "FAILURE INSTALLING MODULE -- OUTPUT: \"@output\"\n\n";
    chdir ($iwd) or croak "Unable to return to \"$iwd\". $!";

    return 0;
}

# This sub normalizes a path.  It is made absolute, cleaned using File::Spec::canonpath()
# then all of the ../ are collapsed.
# Its assumed that the path does not terminate with a file, but this only makes
# a difference on non-unix systems.
sub normalize_path {
	my $path;

	$path = rel2abs (shift);

	my ($vol,$dir,undef) = splitpath ($path,1);
	my @dirs = splitdir($dir);
	my $i;
	for ($i=0; $i < scalar (@dirs); $i++) {
		if ($i+1 < scalar (@dirs) and $dirs[$i+1] eq updir()) {
			splice (@dirs,$i,2);
			$i-=2;
			if ($i < -1) {
				$dirs[0] = rootdir();
				$i = -1;
			}
		}
	}
	return catpath ($vol,catdir (@dirs));

}

# path_in_tree ($tree,$path)
# This sub returns true if $path exists anywhere within the directory tree
# specified by $tree.  This is done with path manipulation - not an actual
# file system check.
sub path_in_tree {
	my ($tree,$path) = @_;
	my $iwd = $path;
	while ($iwd ne rootdir()) {
		return 1 if $iwd eq $tree;
		my ($vol,$dir,undef) = splitpath ($iwd,1);
		my @dirs = splitdir($dir);
		pop (@dirs);
		$iwd = catpath ($vol,catdir (@dirs));
	}
	
	return 0;
}

# Ported from FreeBSD's /usr/bin/which
#
# Copyright (c) 1995 Wolfram Schneider <wosch@FreeBSD.org>. Berlin.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

# Implements the standard "which" functionality, searching the path for a
# certain binary.
#
# RETURNS	The absolute path to the binary or 0 if nothing is found
#

sub which {
    my $prog = shift;

    my @path = split(/:/, $ENV{'PATH'});
    if ($ENV{'PATH'} =~ /:$/) {
        $#path = $#path + 1;
        $path[$#path] = "";
    }

	push (@path,'/usr/sbin');

    if ("$prog" =~ '/' && -x "$prog" && -f "$prog") {
        return $prog;
    } else {
        foreach my $dir (@path) {
            $dir = "." if !$dir;
            if (-x "$dir/$prog" && -f "$dir/$prog") {
                return "$dir/$prog";
            }
        }
    }

    return 0;
}

# END modified BSD Licensed code


1;
