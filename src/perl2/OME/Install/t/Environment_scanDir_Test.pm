# OME/Install/t/Environment_scanDir_Test.pm

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

package OME::Install::t::Environment_scanDir_Test;

use strict;
use warnings;

use File::Spec;
use OME::Install::Environment;
use base qw(Test::Unit::TestCase);



# Fixture is an Environment instance, an empty directory and a directory
# containing the empty directory and two files.
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_) ;
    # state definition for fixture
    $self->{env} = undef;
    $self->{empty_dir} = undef;
    $self->{dir} = undef;
    $self->{file_1} = undef;
    $self->{file_2} = undef;
    return $self;
}

# Creates a file.
sub touch {
    my ($self,$file) = @_;
    open(FILE,"+> $file") or die("Couldn't create file $file. $!.\n");
    close(FILE);
    return;
}

# Create fixture. The directory structure is as follows:
#
#   scan_dir_test
#       |
#       +-------- empty     (empty dir)
#       +-------- file_1    (empty file)
#       +-------- x.y       (empty file)
#
# The above dir is rooted by a tmp dir.
#
sub set_up {
    # fixture initialization
    my $self = shift;
    my $tmp_dir = File::Spec->rel2abs(File::Spec->tmpdir());
    $self->{dir} = File::Spec->catdir($tmp_dir,"scan_dir_test");
    $self->{empty_dir} = File::Spec->catdir($self->{dir},"empty");
    $self->{file_1} = File::Spec->catfile($self->{dir},"file_1");
    $self->{file_2} = File::Spec->catfile($self->{dir},"x.y");
    umask(0000);
    mkdir($self->{dir}) or die("Couldn't make test tmp directory. $!.\n");
    mkdir($self->{empty_dir}) or die("Couldn't make test tmp directory. $!.\n");
    $self->touch($self->{file_1});
    $self->touch($self->{file_2});
    $self->{env} = OME::Install::Environment->getInstance();
    return;
}

# Clean up after test. Get rid of test directries and files.
sub tear_down {
    my $self = shift;
    unlink($self->{file_1}) or die("Couldn't delete tmp file ",$self->{file_1},
        ". $!.\n");
    unlink($self->{file_2}) or die("Couldn't delete tmp file ",$self->{file_2},
        ". $!.\n");
    rmdir($self->{empty_dir}) or die("Couldn't remove directory ",
        $self->{empty_dir},". $!.\n");
    rmdir($self->{dir}) or die("Couldn't remove directory ",$self->{dir},
        ". $!.\n");
    return;
}

# Verify that scanDir returns . and .. for the empty dir.
# Portability issue: OK for Unix and Win, what about other OS?
sub test_empty_1 {
    my $self = shift;
    my $contents = $self->{env}->scanDir($self->{empty_dir});
    $self->assert_not_null($contents);
    my @entries = sort(keys(%$contents));
    $self->assert_equals(2,$#entries+1);
    $self->assert_equals('.',$entries[0]);
    $self->assert_equals('..',$entries[1]);
    return;
}

# Verify that scanDir returns an empty hash for the empty dir if invoked with
# {! /^\.{1,2}$/} filter.
# Portability issue: OK for Unix and Win, what about other OS?
sub test_empty_2 {
    my $self = shift;
    my $contents = $self->{env}->scanDir($self->{empty_dir},sub{! /^\.{1,2}$/});
    $self->assert_not_null($contents);
    my @entries = keys(%$contents);
    $self->assert_equals(0,scalar(@entries));
    return;
}

# Invoke scanDir on dir, filtering out . and .., then verify that the returned
# hash has as many elements as in the fixture.
# Portability issue: OK for Unix and Win, what about other OS?
sub test_dir_number {
    my $self = shift;
    my $contents = $self->{env}->scanDir($self->{dir},sub{! /^\.{1,2}$/});
    $self->assert_not_null($contents);
    my @entries = keys(%$contents);
    $self->assert_equals(3,$#entries+1);
    return;
}

# Invoke scanDir on dir, filtering out . and .., then verify that the absolute
# paths returned are as in the fixture.
sub test_paths {
    my $self = shift;
    my $contents = $self->{env}->scanDir($self->{dir},sub{! /^\.{1,2}$/});
    $self->assert_not_null($contents);
    my (undef,undef,$empty) = File::Spec->splitpath($self->{empty_dir});
    my (undef,undef,$file_1) = File::Spec->splitpath($self->{file_1});
    my (undef,undef,$file_2) = File::Spec->splitpath($self->{file_2});
    $self->assert_equals($self->{empty_dir},$contents->{$empty});
    $self->assert_equals($self->{file_1},$contents->{$file_1});
    $self->assert_equals($self->{file_2},$contents->{$file_2});
    return;
}

# Invoke scanDir on dir, filtering out . and .., then verify that the entry
# names returned are as in the fixture.
sub test_names {
    my $self = shift;
    my $contents = $self->{env}->scanDir($self->{dir},sub{! /^\.{1,2}$/});
    $self->assert_not_null($contents);
    my (undef,undef,$empty) = File::Spec->splitpath($self->{empty_dir});
    my (undef,undef,$file_1) = File::Spec->splitpath($self->{file_1});
    my (undef,undef,$file_2) = File::Spec->splitpath($self->{file_2});
    $self->assert(exists($contents->{$empty}),"$empty is not a key");
    $self->assert(exists($contents->{$file_1}),"$file_1 is not a key");
    $self->assert(exists($contents->{$file_2}),"$file_2 is not a key");
    return;
}



1;
