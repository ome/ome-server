function [mins,maxs,means,sigmas,geomeans,centroids] = ome_planeStatistics(pixels)
% ome_planeStatistics(pixels) calculates statistics of each plane
% of pixels.

% If we're given an index, pull the appropriate Pixels structure
% out of the ome_Pixels array.

global ome_Pixels

if ~isstruct(pixels)
  pixels = ome_Pixels(pixels);
end

sx = pixels.SizeX;
sy = pixels.SizeY;
sz = pixels.SizeZ;
sc = pixels.SizeC;
st = pixels.SizeT;

nextstat = 1;

xs = repmat([0:sx-1],sy,1);
ys = repmat([0:sy-1]',1,sx);

% Preallocate the output arrays
outsize = sz*sc*st;
mins = repmat(struct('TheZ',{},'TheC',{},'TheT',{},'Minimum',{}),outsize);
maxs = repmat(struct('TheZ',{},'TheC',{},'TheT',{},'Maximum',{}),outsize);
means = repmat(struct('TheZ',{},'TheC',{},'TheT',{},'Mean',{}),outsize);
sigmas = repmat(struct('TheZ',{},'TheC',{},'TheT',{},'Sigma',{}),outsize);
geomeans = repmat(struct('TheZ',{},'TheC',{},'TheT',{},'GeometricMean',{}),outsize);
centroids = repmat(struct('TheZ',{},'TheC',{},'TheT',{}, ...
                          'X',{},'Y',{}),outsize);

for t = 0:st-1
  for c = 0:sc-1
    for z = 0:sz-1
      tic;
      pix = ome_readPixelsPlane(pixels,z,c,t);
      
      mins(nextstat).TheZ = z;
      mins(nextstat).TheC = c;
      mins(nextstat).TheT = t;
      mins(nextstat).Minimum = min(pix(:));
      
      maxs(nextstat).TheZ = z;
      maxs(nextstat).TheC = c;
      maxs(nextstat).TheT = t;
      maxs(nextstat).Maximum = max(pix(:));
      
      means(nextstat).TheZ = z;
      means(nextstat).TheC = c;
      means(nextstat).TheT = t;
      means(nextstat).Mean = mean(pix(:));
      
      sigmas(nextstat).TheZ = z;
      sigmas(nextstat).TheC = c;
      sigmas(nextstat).TheT = t;
      sigmas(nextstat).Sigma = std(pix(:));
      
      geomeans(nextstat).TheZ = z;
      geomeans(nextstat).TheC = c;
      geomeans(nextstat).TheT = t;
      geomeans(nextstat).GeometricMean = geomean(pix(:));

      %plane_stats(nextstat).SumX = sumx;
      %plane_stats(nextstat).SumY = sumy;
      %plane_stats(nextstat).SumI = sumi;
      
      sumx = sum(sum(pix .* xs));
      sumy = sum(sum(pix .* ys));
      sumi = sum(sum(pix));
      
      centroids(nextstat).TheZ = z;
      centroids(nextstat).TheC = c;
      centroids(nextstat).TheT = t;
      centroids(nextstat).X = sumx/sumi;
      centroids(nextstat).Y = sumy/sumi;
      nextstat = nextstat + 1;
      toc
    end
  end
end
