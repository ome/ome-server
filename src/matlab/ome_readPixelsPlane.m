function pixels = ome_readPixelsPlane(pixels,z,c,t,flat,nodouble)
% ome_openPixels Opens a file to read a Pixels attribute.
% ome_openPixels(pixels_index) ensures that there is a file open for
% the given Pixels attribute.  The attribute can be specified
% either as a Pixels structure, or as an index into the ome_Pixels
% array.  This function returns a logical value indicating whether
% the Pixels's file was already open before the call.

% flat and nodouble have a default value
if nargin < 6, nodouble = false; end;
if nargin < 5, flat = false; end;

% If we're given an index, pull the appropriate Pixels structure
% out of the ome_Pixels array.

global ome_Pixels

if ~isstruct(pixels)
  pixels = ome_Pixels(pixels);
end

filename = ome_getRepositoryFilename(pixels);

fid = fopen(filename,'r');
if fid < 0
  error('Error opening pixel file!');
end

% bbp = BYTES per pixel
bbp = ceil(pixels.BitsPerPixel/8);

if nodouble
  if bbp == 1
    ptype = 'uint8=>uint8';
  elseif bbp == 2
    ptype = 'uint16=>uint16';
  elseif bbp == 4
    ptype = 'uint32=>uint32';
  else
    error('Unsupported pixel type!');
  end
else
  if bbp == 1
    ptype = 'uint8';
  elseif bbp == 2
    ptype = 'uint16';
  elseif bbp == 4
    ptype = 'uint32';
  else
    error('Unsupported pixel type!');
  end
end

sx = pixels.SizeX;
sy = pixels.SizeY;
sz = pixels.SizeZ;
sc = pixels.SizeC;
st = pixels.SizeT;

floc = ((t*sc + c)*sz + z)*sy*sx*bbp;
npix = sx*sy;

if fseek(fid,floc,'bof') ~= 0
  fclose(fid);
  error('Error seeking while reading pixel file!');
end

% Matlab's fread reads the pixels into a matrix in column-major
% ordering, which requires the dims to be passed in as [sizex sizey]
% (which is backwards from Matlabs row by column order).  This also
% means that we have to transpose the matrix afterwards.  If this
% becomes too inefficient, we can rewrite this to read in the pixels
% one row at a time, directly into a properly-oriented matrix.

if flat
  [pixels,count] = fread(fid,npix,ptype);
else
  [pixels,count] = fread(fid,[sx,sy],ptype);
end

fclose(fid);

if count ~= npix
  error('Error reading from pixel file!');
end

if ~flat, pixels = pixels'; end;
