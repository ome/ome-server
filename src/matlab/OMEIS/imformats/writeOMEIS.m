%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Copyright (C) 2005 Open Microscopy Environment
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
% Written By: Tom Macura <tmacura@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% This function is an implementation of MATLAB's imwrite function for
% OMEIS based files
function writeOMEIS (data, map, filename, varargin);

if (length(varargin) ~=2) 
	error('Four parameters expected. e.g. imwrite(ah, `tmp.omeis`, `url`, `http://localhost/cgi-bin/omeis`)');
end

if (~strcmp(varargin{1}, 'url'))
	error('First parameter must be `url`. Second parameter must be the url e.g. `http://localhost/cgi-bin/omeis`');
end
url = varargin{2};

% write file to OMEIS remote server
head = MATLABtoOMEISDatatype(data);
[head.dx head.dy head.dz head.dc head.dt] = size (data);
is = openConnectionOMEIS(url);
id = newPixels(is, head);
pix = setPixels(is, id, data);
if ( pix ~= prod(size(data)) )
	error ('all pixels couldn`t be written');
end
id = finishPixels (is, id);

% record info to local .omeis file
file = fopen(filename, 'w');
fprintf(file, '#OMEIS-LOCAL\n');
fprintf(file, '%s\n', url);
fprintf(file, 'PixelsID=%d\n', id);
fclose(file);

return