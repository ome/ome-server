# OME/Web/GuestFooterBuilder.pm
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
# Written by: Harry Hochheiser <hsh@nih.gov>, for Mouse Gene Index
#             Ilya Goldberg <igg@nih.gov> as a default footer
#
#-------------------------------------------------------------------------------


package OME::Web::GuestFooterBuilder;

#*********
#********* INCLUDES
#*********

use strict;
use vars qw($VERSION);
use CGI;
use Carp;

# OME Modules
use OME;
use OME::Task;
use OME::Web;

#*********
#********* GLOBALS AND DEFINES
#*********

$VERSION = $OME::VERSION_STRING;

#*********
#********* PRIVATE METHODS
#*********

# Session Macro (Pseudo-private)
sub Session { OME::Session->instance() };

#*********
#********* PUBLIC METHODS
#*********

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {};

	return bless($self,$class);
}


sub getPageFooter {
return <<HTML
<hr />
<p class="ome_footer" align="center">Powered by OME technology &copy 1999-2007  
<a target="_ome" class="ome_footer" href="http://www.openmicroscopy.org/">Open Microscopy Environment</a>
</p>
HTML

}

1;
