# OME/Install/t/Environment_copyTree_Test1.pm

# Copyright (C) 2003 Open Microscopy Environment
# Author:   Andrea Falconi <a.falconi@dundee.ac.uk>
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

package OME::Install::t::Environment_copyTree_Test1;

use strict;
use warnings;

use File::Spec;
use OME::Install::Environment;
use base qw(Test::Unit::TestCase);



# Fixture is an Environment instance, the from directory (containing no file)
# and the to directory (empty as well).
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_) ;
    # state definition for fixture
    $self->{env} = undef;
    $self->{from} = undef;
    $self->{to} = undef;
    return $self;
}

# Deletes file or directory. Don't pass anything different from a file or dir
# path. If you want to delete a dir, then you first have to delete all its
# contents. No action taken if passed item doesn't exist.
sub remove {
  my ($self,$item) = @_;
  if( -e $item ) {
    if( -f $item ) {
      unlink($item) or die("Couldn't delete tmp file $item. $!.\n");
    } else {
      rmdir($item) or die("Couldn't remove tmp directory $item. $!.\n");
    }
  }
  return;
}

# Create fixture. The from dir is copy_tree_test and is rooted by a tmp dir.
# The to dir is rooted by the same tmp dir and its name is copy_tree_test_to.
#
sub set_up {
    # fixture initialization
    my $self = shift;
    my $tmp_dir = File::Spec->rel2abs(File::Spec->tmpdir());
    $self->{from} = File::Spec->catdir($tmp_dir,"copy_tree_test");
    $self->{to} = File::Spec->catdir($tmp_dir,"copy_tree_test_to");
    umask(0000);
    mkdir($self->{from}) or die("Couldn't make test tmp directory. $!.\n");
    mkdir($self->{to}) or die("Couldn't make test tmp directory. $!.\n");
    $self->{env} = OME::Install::Environment->getInstance();
    return;
}

# Clean up after test. Get rid of test directries.
sub tear_down {
    my $self = shift;
    $self->remove($self->{from});
    $self->remove($self->{to});
    return;
}

# Verify that copyTree copies no file into to.
# Portability issue: we invoke scanDir with {! /^\.{1,2}$/} filter.
# OK for Unix and Win, what about other OS?
sub test_copy_all {
    my $self = shift;
    $self->{env}->copyTree($self->{from},$self->{to});
    my $contents = $self->{env}->scanDir($self->{to},sub{! /^\.{1,2}$/});
    my @k = keys(%$contents);
    $self->assert_equals(0,scalar(@k));
    return;
}



1;
