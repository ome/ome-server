#!/usr/bin/perl -w
# OME/Tasks/Analysis/Engine/BlockingSlaveWorkerCGI.pl

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
# Written by:    Ilya Goldberg <igg@nih.gov>
#
#-------------------------------------------------------------------------------

use strict;
use OME;
our $VERSION = $OME::VERSION;

use OME::Install::Environment;
use OME::Install::Terminal;
use English;

use constant ENV_FILE        => '/etc/ome-install.store';

die (<<ERROR) unless $EUID == 0;
You must be root to run this script!
ERROR

# Get the installation environment
OME::Install::Environment::restore_from (ENV_FILE);
my $environment = initialize OME::Install::Environment;


my $worker_conf = {
	MaxWorkers => $environment->worker_conf() ? $environment->worker_conf()->{MaxWorkers} : 2
};

$worker_conf->{MaxWorkers} = confirm_default ('Maximum workers :', $worker_conf->{MaxWorkers});



$environment->worker_conf($worker_conf);
$environment->store_to (ENV_FILE);
	

