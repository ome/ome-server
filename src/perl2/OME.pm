# OME.pm

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
# Written by:  
#-------------------------------------------------------------------------------


package OME;
use strict;
our $VERSION = 2.001_000;

use Config;
use Log::Agent;
our $THREADS_AVAILABLE;
our $BIG_ENDIAN;

sub THREADS_AVAILABLE {
    $THREADS_AVAILABLE = $Config{useithreads} && $ENV{OME_USE_THREADS}
      unless defined $THREADS_AVAILABLE;

    return $THREADS_AVAILABLE;
}

sub BIG_ENDIAN {
    $BIG_ENDIAN =
      ($Config{byteorder} != 1234) &&
      ($Config{byteorder} != 12345678)
        unless defined $BIG_ENDIAN;
    return $BIG_ENDIAN;
}

if (defined $ENV{OME_DEBUG} && $ENV{OME_DEBUG} > 0) {	
	logconfig(
		-prefix      => "$0",
		-level    => 'debug'
	);
}

=head1 NAME

OME - The Open Microscopy Environment

More information about the Perl OME API can be obtained by looking at
documentation for the individual classes:

=over

=item OME::Factory

Database access layer

=item OME::ModuleExecution

Analysis engine

=item OME::Remote

(Highly experimental) remote access API

=back

=head1 AUTHORS

Ilya Goldberg (igg@nih.gov), Doug Creager (dcreager@alum.mit.edu),
Brian Hughes (bshughes@mit.edu), Josiah Johnston (siah@nih.gov),
Andrea Falconi (a.falconi@dundee.ac.uk), Jean-Marie Burel
(j.burel@dundee.ac.uk), Chris Allan (callan@blackcat.ca)

http://openmicroscopy.org/

=head1 COPYRIGHT

This program is free software licensed under the...

	The GNU Lesser General Public License (LGPL)
	Version 2.1, February 1999

The full text of the license can be found in the
LICENSE file included with this module.



=cut


1;

__END__

