function mb_hela_v01(imagefile, dnafile, dicfile, cropfile)
% MB_HELA_V01 Version 1 of the HeLa image processing routine
% MB_HELA_V01(IMAGEFILE, DNAFILE, DICFILE, CROPFILE), 
%    where IMAGEFILE is the image 
%    to be processed, DNAFILE contains the DNA image, DICFILE
%    contains the DIC image, and CROPFILE contains a binary
%    image defining a region of interest. 
%    Use <file>='' for any files that are not defined.
%    If DICFILE and CROPFILE are both defined, the cropped
%    image will be placed in the file CROPFILE after 
%    interactive ROI extraction.  If DICFILE is specified
%    and CROPFILE is not, the cropped image will be 
%    placed in a new file.  If CROPFILE is specified alone 
%    and DICFILE is not, the binary ROI image will be read
%    from CROPFILE.
%
% 07 Aug 98 - M.V. Boland

% $Id$

if (nargin ~=4)
	error('mb_hela_v01 requires four arguments.  Use <file>='' for any undefined file names') ;
end

if ~(ischar(imagefile) & ischar(dnafile) & ischar(dicfile) & ...
		ischar(cropfile))
	error('All arguments must be strings.  Use <file>='' for any undefined file names') ;
end

if (isempty(imagefile))
	error('You must specify a main file for processing') ;
end


%
% If the DIC file is specified, use it for cropping
%
if (~isempty(dicfile))
	dicimage = mb_tclread(dicfile) ;
	if (dicimage)
		cropimage = roipoly(mb_imgscale(dicimage)) ;
	else
		error('Unable to read your DICFILE') ;
	end
	%
	% if the crop file is specified, use that name for output
	%
	if (~isempty(cropfile))
		imwrite(cropimage, cropfile, 'tiff') ;
	else
		imwrite(cropimage, 'cropfixme.tiff', 'tiff') ;
	end
%
% If there is ONLY a crop file specified and not a DIC file, read the
%  cropfile.  It must be in Matlab-readable format.
%
elseif (cropfile ~= '')
	cropimage = imread(cropfile) ;
else
	error('You must specify either a DIC file, a crop file, or both.') ;
end


image = mb_tclread(imagefile) ;
imagemask = mb_cropthresh(image, cropimage) ;

if (~isempty(dnafile))
	dnaimage = mb_tclread(dnafile) ;
	dnamask = mb_cropthresh(dnaimage, cropimage) ;
end

imshow(imagemask) ;
pause ;
imshow(dnamask) ;	



