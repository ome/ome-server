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
% Written by:  Lawrence David <lad2002@columbia.edu>
%              Nikita Orlov <orlovni@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


% Computes 3 area characteristics:
%       AreaStat_BlobNum -- Number of blobs (Area elements)
%       AreaStat_HistN -- Histogram element for Area (out of 10)
%       AreaStat_Mean -- Mean Area
% Example:
%	AreaStat = ome_AreaStat(image);
%	myf=[];flds=fieldnames(AreaStat);nfld=length(flds);for ii=1:nfld,myf=[myf AreaStat.(flds{ii})];end

function [AreaStat]=ome_AreaStat(image),

level = graythresh(image);

save areaStatDump;
bw = im2bw(image,level);
[lab num] = bwlabel(bw,4);                  % num = how many 'blobs' are there
idata = regionprops(lab,'basic');
histo = hist([idata.Area],10);              % histogram of the binary image, based on 'blob' size
meany = mean([idata.Area]);                 % average blob size
%myf = [num histo meany];    
save areaStatDump;

fld=sprintf('NumBlobs');
AreaStat.(fld) = num;
for ii=1:10,fld=sprintf('Histogram%d',ii);AreaStat.(fld) = histo(ii);end
fld=sprintf('Mean');AreaStat.(fld) = meany;
save areaStatDump;
%myf=[];flds=fieldnames(AreaStat);nfld=length(flds);for ii=1:nfld,myf=[myf AreaStat.(flds{ii})];end

return;

