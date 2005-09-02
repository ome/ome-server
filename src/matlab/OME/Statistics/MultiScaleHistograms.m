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
% Written by:  Nikita Orlov <norlov@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


%% Function computes signatures based on "multiscale histograms" idea.
%% Idea of multiscale histogram came from the belief of a unique representativity of an
%% image through infinite series of histograms with sequentially increasing number of bins.
%% Here we used 4 histograms with number of bins being 3,5,7,9.
%%
%% Nikita Orlov
%% Computational Biology Unit, LG,NIA/NIH
%% :: revision :: 02-12-2005
%%
%% output:  1x24 vector (for the default bin sizes)
%% input :  im (image)
%%
%% Example
%% mh = multiScaleHistSigs(im);
%%

function hh = MultiScaleHistograms(im), im = im(:);
nn = [3 5 7 9]; hh = [];
for ii = 1:length(nn), hh = [hh hist(im,nn(ii))];end
hh = hh./max(hh(:));
%hh = uint16(hh);
return;

