# OME/Install/t/Environment_deleteTree_Test.pm

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
# Written by:     Andrea Falconi <a.falconi@dundee.ac.uk>
#
#-------------------------------------------------------------------------------


package OME::Install::t::Environment_deleteTree_Test;

use strict;
use warnings;

use File::Spec;
use OME::Install::Environment;
use base qw(Test::Unit::TestCase);



# Fixture is an Environment instance, the base directory (containing two files,
# and empty subdir and another subdir with one file).
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_) ;
    # state definition for fixture
    $self->{env} = undef;
    $self->{base} = undef;
    $self->{empty_sub} = undef;
    $self->{sub} = undef;
    $self->{file_1} = undef;
    $self->{file_2} = undef;
    $self->{file_3} = undef;
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

# Create fixture. The base directory structure is as follows:
#
#   delete_tree_test
#       |
#       +--- _cVs                (empty dir)
#       +--- file_1             (empty file)
#       +--- x.y			    (empty file)
#       +--- CVS                (dir)
#               |
#               +--- Root       (empty file)
#
# The above is the base dir and is rooted by a tmp dir.
#
sub set_up {
    # fixture initialization
    my $self = shift;
    my $tmp_dir = File::Spec->rel2abs(File::Spec->tmpdir());
    $self->{base} = File::Spec->catdir($tmp_dir,"delete_tree_test");
    $self->{empty_sub} = File::Spec->catdir($self->{base},"_cVs");
    $self->{file_1} = File::Spec->catfile($self->{base},"file_1");
    $self->{file_2} = File::Spec->catfile($self->{base},"x.y");
    $self->{sub} = File::Spec->catdir($self->{base},"CVS");
    $self->{file_3} = File::Spec->catfile($self->{sub},"Root");
    umask(0000);
    mkdir($self->{base}) or die("Couldn't make test tmp directory. $!.\n");
    mkdir($self->{empty_sub}) or die("Couldn't make test tmp directory. $!.\n");
    $self->touch($self->{file_1});
    $self->touch($self->{file_2});
    mkdir($self->{sub}) or die("Couldn't make test tmp directory. $!.\n");
    $self->touch($self->{file_3});
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
    $self->remove($self->{base});
    return;
}

# Verify that deleteTree deletes all contents of the base directory.
sub test_delete_all {
    my $self = shift;
    $self->{env}->deleteTree($self->{base});
    $self->assert( -e $self->{base},
      "Deleted the base directory: ".$self->{base});
    $self->assert( !(-e $self->{file_1}),
      "This file should have been deleted: ".$self->{file_1});
    $self->assert( !(-e $self->{file_2}),
      "This file should have been deleted: ".$self->{file_2});
    $self->assert( !(-e $self->{file_3}),
      "This file should have been deleted: ".$self->{file_3});
    $self->assert( !(-e $self->{empty_sub}),
      "This directory should have been deleted: ".$self->{empty_sub});
    $self->assert( !(-e $self->{sub}),
      "This directory should have been deleted: ".$self->{sub});
    return;
}

# Verify that deleteTree only deletes the CVS dirs (verify filter).
sub test_delete_some {
    my $self = shift;
    $self->{env}->deleteTree($self->{base},sub{ /(CVS$)|(Root)/i });
    $self->assert( -e $self->{base},
      "Deleted the base directory: ".$self->{base});
    $self->assert( -e $self->{file_1},
      "Deleted wrong file: ".$self->{file_1});
    $self->assert( -e $self->{file_2},
      "Deleted wrong file: ".$self->{file_2});
    $self->assert( !(-e $self->{file_3}),
      "This file should have been deleted: ".$self->{file_3});
    $self->assert( !(-e $self->{empty_sub}),
      "This directory should have been deleted: ".$self->{empty_sub});
    $self->assert( !(-e $self->{sub}),
      "This directory should have been deleted: ".$self->{sub});
    return;
}

# Verify that deleteTree deletes no file (verify filter).
sub test_delete_none {
    my $self = shift;
    $self->{env}->deleteTree($self->{base},sub{/ZZZ/});
    $self->assert( -e $self->{base},
      "Deleted the base directory: ".$self->{base});
    $self->assert( -e $self->{file_1},
      "This file shouldn't have been deleted: ".$self->{file_1});
    $self->assert( -e $self->{file_2},
      "This file shouldn't have been deleted: ".$self->{file_2});
    $self->assert( -e $self->{file_3},
      "This file shouldn't have been deleted: ".$self->{file_3});
    $self->assert( -e $self->{empty_sub},
      "This directory shouldn't have been deleted: ".$self->{empty_sub});
    $self->assert( -e $self->{sub},
      "This directory shouldn't have been deleted: ".$self->{sub});
    return;
}



1;
