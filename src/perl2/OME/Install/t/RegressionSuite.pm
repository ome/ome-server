# OME/Install/t/RegressionSuite.pm

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

package OME::Install::t::RegressionSuite;

use strict;
use warnings;

use base qw(Test::Unit::TestSuite);


sub new {
    my $class = shift;
    my $self = $class->SUPER::empty_new('OME-Install Regression Test Suite');
    # Build your suite here with add_test or override include_tests
    $self->add_test('OME::Install::t::Environment_scanDir_Test');
    $self->add_test('OME::Install::t::Environment_copyTree_Test1');
    $self->add_test('OME::Install::t::Environment_copyTree_Test2');
    $self->add_test('OME::Install::t::Environment_copyTree_Test3');
    $self->add_test('OME::Install::t::Environment_deleteTree_Test');
    return $self;
}


1;
