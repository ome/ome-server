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

function [StringTest_class, BooleanTest_class, DoubleTest_class, SingleTest_class, ...
SmallIntTest_class, IntegerTest_class, BigIntTest_class, ConvertTest_class, PixelTest_class] ...
= MatlabTestInput(StringTest, BooleanTest, DoubleTest, SingleTest, ...
SmallIntTest, IntegerTest, BigIntTest, ConvertTest, PixelTest)

StringTest_class   = class(StringTest);
BooleanTest_class  = class(BooleanTest);
DoubleTest_class   = class(DoubleTest);
SingleTest_class   = class(SingleTest);
SmallIntTest_class = class(SmallIntTest);
IntegerTest_class  = class(IntegerTest);
BigIntTest_class   = class(BigIntTest);
ConvertTest_class  = class(ConvertTest);
PixelTest_class    = class(PixelTest);