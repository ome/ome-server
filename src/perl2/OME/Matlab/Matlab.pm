# OME/Matlab.pm

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
# Written by:    Douglas Creager <dcreager@alum.mit.edu>
#
#-------------------------------------------------------------------------------


package OME::Matlab;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS =
  (complexities => [qw(
                       $mxREAL $mxCOMPLEX
                      )],
   classes      => [qw(
                       $mxUNKNOWN_CLASS $mxCELL_CLASS $mxSTRUCT_CLASS
                       $mxOBJECT_CLASS $mxCHAR_CLASS $mxLOGICAL_CLASS
                       $mxDOUBLE_CLASS $mxSINGLE_CLASS $mxINT8_CLASS
                       $mxUINT8_CLASS $mxINT16_CLASS $mxUINT16_CLASS
                       $mxINT32_CLASS $mxUINT32_CLASS $mxINT64_CLASS
                       $mxUINT64_CLASS $mxFUNCTION_CLASS
                      )],
  );

$EXPORT_TAGS{constants} = [
                           @{$EXPORT_TAGS{'complexities'}},
                           @{$EXPORT_TAGS{'classes'}}
                          ];

$EXPORT_TAGS{all} = [
                     @{$EXPORT_TAGS{'complexities'}},
                     @{$EXPORT_TAGS{'classes'}}
                    ];

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT = (@{$EXPORT_TAGS{'constants'}});

use OME;
our $VERSION = $OME::VERSION;

our ($mxREAL,$mxCOMPLEX);
our ($mxUNKNOWN_CLASS,$mxCELL_CLASS,$mxSTRUCT_CLASS,$mxOBJECT_CLASS,
     $mxCHAR_CLASS,$mxLOGICAL_CLASS,$mxDOUBLE_CLASS,$mxSINGLE_CLASS,
     $mxINT8_CLASS,$mxUINT8_CLASS,$mxINT16_CLASS,$mxUINT16_CLASS,
     $mxINT32_CLASS,$mxUINT32_CLASS,$mxINT64_CLASS,$mxUINT64_CLASS,
     $mxFUNCTION_CLASS);

bootstrap OME::Matlab $VERSION;

$mxREAL = __mxREAL();
$mxCOMPLEX = __mxCOMPLEX();

$mxUNKNOWN_CLASS = __mxUNKNOWN_CLASS();
$mxCELL_CLASS = __mxCELL_CLASS();
$mxSTRUCT_CLASS = __mxSTRUCT_CLASS();
$mxOBJECT_CLASS = __mxOBJECT_CLASS();
$mxCHAR_CLASS = __mxCHAR_CLASS();
$mxLOGICAL_CLASS = __mxLOGICAL_CLASS();
$mxDOUBLE_CLASS = __mxDOUBLE_CLASS();
$mxSINGLE_CLASS = __mxSINGLE_CLASS();
$mxINT8_CLASS = __mxINT8_CLASS();
$mxUINT8_CLASS = __mxUINT8_CLASS();
$mxINT16_CLASS = __mxINT16_CLASS();
$mxUINT16_CLASS = __mxUINT16_CLASS();
$mxINT32_CLASS = __mxINT32_CLASS();
$mxUINT32_CLASS = __mxUINT32_CLASS();
$mxINT64_CLASS = __mxINT64_CLASS();
$mxUINT64_CLASS = __mxUINT64_CLASS();
$mxFUNCTION_CLASS = __mxFUNCTION_CLASS();

# Preloaded methods go here.

1;

__END__
