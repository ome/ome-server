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

#*********
#********* INCLUDES
#*********

use warnings;
use strict;
use Carp;
use Storable;

#*********
#********* GLOBALS AND DEFINES
#*********

# The singleton instance.
my $sole_instance = undef;

# Private constructor.
my $new = sub {
    my $self = {};
    return bless($self);
};

#*********
#********* RESTORE SUBROUTINE
#*********

# Restoration subroutine to restore the singleton instance from an
# existing OME::Install::Environment instance that has be stored
# using the Storable module.
#
sub restore_from {
    my $env_file = shift;

    $sole_instance = retrieve ($env_file);

    return $sole_instance;
}

#*********
#********* CLASS METHODS
#*********

# Class method to return the singleton instance.
#
# my $environment = initialize OME::Install::Environment;
#
sub initialize {
    unless ($sole_instance) { # first time we're called
        # Create the singleton
        $sole_instance = &$new();
    }

    return $sole_instance;
}

# Class method to store the singleton instance of OME::Install:Environment
# using the Storable module.
#
sub store_to {
    my ($self, $env_file) = @_;
    print "Storing OME::Install::Environment in \"$env_file\"\n";

    store ($sole_instance, $env_file) or croak "Unable to store instance in \"$env_file\". $!";

    return 1;
}


# Class methods to get or set specific flags.
#
sub set_flag {
    my ($self, $flag) = @_;

    return unless $flag;

    $self->{flags}->{$flag} = 1;
    return;
}

sub get_flag {
	my ($self, $flag) = @_;
    
	return unless $flag;

    return $self->{flags}->{$flag} ? 1 : 0;
}
    

#*********
#********* STORAGE SUBROUTINES
#*********

sub base_dir {
    my ($self, $base_dir) = @_;

    if ($base_dir) {
	$self->{base_dir} = $base_dir;
    } else {
	return $self->{base_dir} unless not exists $self->{base_dir};
    }

    return;
}

sub omeis_base_dir {
    my ($self, $omeis_base_dir) = @_;

    if ($omeis_base_dir) {
	$self->{omeis_base_dir} = $omeis_base_dir;
    } else {
	return $self->{omeis_base_dir} unless not exists $self->{omeis_base_dir};
    }

    return;
}


sub tmp_dir {
    my ($self, $temp_dir) = @_;

    if ($temp_dir) {
	$self->{temp_dir} = $temp_dir;
    } else {
	return $self->{temp_dir} unless not exists $self->{base_dir};
    }

    return;
}

sub user {
    my ($self, $user) = @_;

    if ($user) {
	$self->{user} = $user;
    } else {
	return $self->{user} unless not exists $self->{user};
    }

    return;
}

sub group {
    my ($self, $group) = @_;

    if ($group) {
	$self->{group} = $group;
    } else {
	return $self->{group} unless not exists $self->{group};
    }

    return;
}

sub apache_user {
    my ($self, $user) = @_;

    if ($user) {
	$self->{apache_user} = $user;
    } else {
	return $self->{apache_user} unless not exists $self->{apache_user};
    }

    return;
}

sub postgres_user {
    my ($self, $user) = @_;

    if($user) {
	$self->{postgres_user} = $user;
    } else {
	return $self->{postgres_user} unless not exists $self->{postgres_user};
    }

    return;
}

sub admin_user {
    my ($self, $user) = @_;

    if($user) {
	$self->{admin_user} = $user;
    } else {
	return $self->{admin_user} unless not exists $self->{admin_user};
    }

    return;
}

1;
