# OME/Install/t/Environment_copyTree_Test3.pm

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

package OME::Install::t::Environment_copyTree_Test3;

use strict;
use warnings;

use File::Spec;
use OME::Install::Environment;
use base qw(Test::Unit::TestCase);



# Fixture is an Environment instance, the from directory (containing two files,
# and empty subdir and another subdir with one file) and the to directory
#(initially empty).
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_) ;
    # state definition for fixture
    $self->{env} = undef;
    $self->{from} = undef;
    $self->{to} = undef;
    $self->{empty_sub} = undef;
    $self->{sub} = undef;
    $self->{file_1} = undef;
    $self->{file_2} = undef;
    $self->{file_3} = undef;
    $self->{empty_sub_copy} = undef;
    $self->{sub_copy} = undef;
    $self->{file_1_copy} = undef;
    $self->{file_2_copy} = undef;
    $self->{file_3_copy} = undef;
    return $self;
}

# Creates a file.
sub touch {
    my ($self,$file) = @_;
    open(FILE,"+> $file") or die("Couldn't create file $file. $!.\n");
    close(FILE);
    return;
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

# Create fixture. The from directory structure is as follows:
#
#   copy_tree_test
#       |
#       +--- _cVs                (empty dir)
#       +--- file_1             (empty file)
#       +--- x.y			    (empty file)
#       +--- CVS                (dir)
#               |
#               +--- Root       (empty file)
#
# The above is the from dir and is rooted by a tmp dir. The to dir is rooted by
# the same tmp dir and its name is copy_tree_test_to.
#
sub set_up {
    # fixture initialization
    my $self = shift;
    my $tmp_dir = File::Spec->rel2abs(File::Spec->tmpdir());
    $self->{from} = File::Spec->catdir($tmp_dir,"copy_tree_test");
    $self->{empty_sub} = File::Spec->catdir($self->{from},"_cVs");
    $self->{file_1} = File::Spec->catfile($self->{from},"file_1");
    $self->{file_2} = File::Spec->catfile($self->{from},"x.y");
    $self->{sub} = File::Spec->catdir($self->{from},"CVS");
    $self->{file_3} = File::Spec->catfile($self->{sub},"Root");
    $self->{to} = File::Spec->catdir($tmp_dir,"copy_tree_test_to");
    $self->{empty_sub_copy} = File::Spec->catdir($self->{to},"_cVs");
    $self->{file_1_copy} = File::Spec->catfile($self->{to},"file_1");
    $self->{file_2_copy} = File::Spec->catfile($self->{to},"x.y");
    $self->{sub_copy} = File::Spec->catdir($self->{to},"CVS");
    $self->{file_3_copy} = File::Spec->catfile($self->{sub_copy},"Root");
    umask(0000);
    mkdir($self->{from}) or die("Couldn't make test tmp directory. $!.\n");
    mkdir($self->{empty_sub}) or die("Couldn't make test tmp directory. $!.\n");
    $self->touch($self->{file_1});
    $self->touch($self->{file_2});
    mkdir($self->{sub}) or die("Couldn't make test tmp directory. $!.\n");
    $self->touch($self->{file_3});
    mkdir($self->{to}) or die("Couldn't make test tmp directory. $!.\n");
    $self->{env} = OME::Install::Environment->getInstance();
    return;
}

# Clean up after test. Get rid of test directories and files.
sub tear_down {
    my $self = shift;
    $self->remove($self->{file_1});
    $self->remove($self->{file_2});
    $self->remove($self->{file_3});
    $self->remove($self->{empty_sub});
    $self->remove($self->{sub});
    $self->remove($self->{from});
    $self->remove($self->{file_1_copy});
    $self->remove($self->{file_2_copy});
    $self->remove($self->{file_3_copy});
    $self->remove($self->{empty_sub_copy});
    $self->remove($self->{sub_copy});
    $self->remove($self->{to});
    return;
}

# Verify that copyTree copies all from contents into to.
sub test_copy_all {
    my $self = shift;
    $self->{env}->copyTree($self->{from},$self->{to});
    $self->assert( -e $self->{empty_sub_copy} && -d $self->{empty_sub_copy},
      "Failed to copy ".$self->{empty_sub_copy});
    $self->assert( -e $self->{file_1_copy} && -f $self->{file_1_copy},
      "Failed to copy ".$self->{file_1_copy});
    $self->assert( -e $self->{file_2_copy} && -f $self->{file_2_copy},
      "Failed to copy ".$self->{file_2_copy});
    $self->assert( -e $self->{sub_copy} && -d $self->{sub_copy},
      "Failed to copy ".$self->{sub_copy});
    $self->assert( -e $self->{file_3_copy} && -f $self->{file_3_copy},
      "Failed to copy ".$self->{file_3_copy});
    return;
}

# Verify that copyTree doesn't copy CVS dirs in from into to (verify filter).
sub test_copy_some {
    my $self = shift;
    $self->{env}->copyTree($self->{from},$self->{to},sub{ ! /CVS$/i });
    $self->assert( -e $self->{file_1_copy} && -f $self->{file_1_copy},
      "Failed to copy ".$self->{file_1_copy});
    $self->assert( -e $self->{file_2_copy} && -f $self->{file_2_copy},
      "Failed to copy ".$self->{file_2_copy});
    $self->assert( !(-e $self->{empty_sub_copy}),
      "This directory shouldn't exists: ".$self->{empty_sub_copy});
    $self->assert( !(-e $self->{sub_copy}),
      "This directory shouldn't exists: ".$self->{sub_copy});
    return;
}

# Verify that copyTree copies no file in from into to (verify filter).
sub test_copy_none {
    my $self = shift;
    $self->{env}->copyTree($self->{from},$self->{to},sub{/ZZZ/});
    $self->assert( !(-e $self->{file_1_copy}),
      "This file shouldn't exists: ".$self->{file_1_copy});
    $self->assert( !(-e $self->{file_2_copy}),
      "This file shouldn't exists: ".$self->{file_2_copy});
    $self->assert( !(-e $self->{empty_sub_copy}),
      "This directory shouldn't exists: ".$self->{empty_sub_copy});
    $self->assert( !(-e $self->{sub_copy}),
      "This directory shouldn't exists: ".$self->{sub_copy});
    return;
}



1;
