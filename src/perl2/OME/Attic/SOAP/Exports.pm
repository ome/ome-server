# OME/SOAP/Exports.pm

# Copyright (C) 2002 Open Microscopy Environment, MIT
# Author:  Douglas Creager <dcreager@alum.mit.edu>
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


package OME::SOAP::Exports;

use OME::SessionManager;
use OME::Session;
use OME::Experimenter;
use OME::Dataset;
use OME::Project;
use OME::Factory;
use OME::Image;

our @SOAPobjects = qw(
	OME::SessionManager
	OME::Session
	OME::Experimenter
	OME::Dataset
	OME::Project
	OME::Factory
	OME::Image
);


1;
