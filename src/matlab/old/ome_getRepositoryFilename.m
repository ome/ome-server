function filename = ome_getRepositoryFilename(pixels)
% ome_getRepositoryFilename Calculate a full pathname for a repository file.
% ome_getRepositoryFilename(pixels) calculates the full pathname of a
% repository file.  The file is specified either as a Pixels
% structure, or as an index into the ome_Pixels array.

% If we're given an index, pull the appropriate Pixels structure
% out of the ome_Pixels array.

global ome_Pixels

if ~isstruct(pixels)
  pixels = ome_Pixels(pixels);
end

repository = pixels.Repository;

filename = [repository.Path pixels.Path];
