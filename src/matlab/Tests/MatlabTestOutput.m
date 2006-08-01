%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2003 Open Microscopy Environment
%       Massachusetts Institue of Technology,
%       National Institutes of Health,
%       University of Dundee
%
%
%
%    This library is free software; you can redistribute it and/or
%    modify it under the terms of the GNU Lesser General Public
%    License as published by the Free Software Foundation; either
%    version 2.1 of the License, or (at your option) any later version.
%
%    This library is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%    Lesser General Public License for more details.
%
%    You should have received a copy of the GNU Lesser General Public
%    License along with this library; if not, write to the Free Software
%    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Written by:  Tom Macura <tmacura@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% This function is used by the Matlab Test OME module to test the Matlab Handler
% in all ways imaginable

function [StringTest, BooleanTest, DoubleTest, SingleTest, SmallIntTest, ...
IntegerTest, BigIntTest, VectorTest1, VectorTest2, PixelTest, PlusInf, MinusInf, NotANumber] = MatlabTestOutput()

StringTest = 'OME Welcomes You';
BooleanTest = 1;
DoubleTest = exp(1);
SingleTest = pi;

SmallIntTest = int16(16);
IntegerTest = int32(32);
BigIntTest = int64(64);
VectorTest1 = double([ 0.1 0.2 0.3]);
VectorTest2 = [111 222 333];

PixelTest = single(rand(5,5));

PlusInf = 1/0;
MinusInf = -1/0;
NotANumber = 0/0;