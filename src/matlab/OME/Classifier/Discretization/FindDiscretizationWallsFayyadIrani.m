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
% Written By: Lawrence David <lad2002@columbia.edu>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


function [walls] = FindDiscretizationWallsFayyadIrani (points, classes, intervals)

% INPUT             points      - the 1-dimensional values of each instance
%                   classes     - class numbers of all points
%                   intervals   - how much you want to break up each smaller 
%                                 section. OPTIONAL. The default is 40. 
%
% OUTPUT            walls       - vector containing all "walls"
% NOTES
%   This is a pretty neat implementation of information theory.  In my empirical
%   observation, this is by far the fastest discretizing metric I've come across.
%   In addition, it seems to be quite accurate.
% CITATIONS
%   code implements Fayyad and Irani's discretization algorithms as described 
%   in Kohavi, Dougherty - 'Supervised and Unsupervised Discretization of
%   Continuous Features' and 'Li, Wong' - Emerging Patterns and Gene Expression 
%   data =>
%   http://hc.ims.u-tokyo.ac.jp/JSBi/journal/GIW01/GIW01F01/GIW01F01.html.
%
% Lawrence David - 2003.  lad2002@columbia.edu
% Tom Macura - 2005. tm289@cam.ac.uk (modified for inclusion in OME)

% warning off MATLAB:colon:operandsNotRealScalar;         % shutup
if (nargin < 3)
	intervals = 40;
end

walls   = [];
points  = double(points);                   % sometimes, data comes in as 'single'
classes = double(classes);

% erect walls between min, max to divide distance into interval intervals
bin_walls       = min(points):(max(points)-min(points))/intervals:max(points);

if ~isempty(bin_walls)          % stop if you split into space with no points
	bin_num         = length(bin_walls);
	N               = length(points);
	
	% compute class entropy and number of unique classes
	[s_ent class_number]   = class_entropy(classes);
	class_info_ent  = [];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% looking for best way to split points in half                  %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
	for i = 1:bin_num
        temp = (points > bin_walls(i)) + 1;         % simple discretization
        s1 = classes(find(temp==1));
        s2 = classes(find(temp==2));
        s1_size = length(s1);
        s2_size = length(s2);
        [s1_ent(i) s1_k(i)] = class_entropy(s1);   % get class entropies
        [s2_ent(i) s2_k(i)] = class_entropy(s2);   % get class entropies
        class_info_ent(i) = (s1_size/N)*s1_ent(i) + (s2_size/N)*s2_ent(i);  % want to minimize this baby
	end
	
	[low_score lsp] = min(class_info_ent);          % where was entropy minimized?
	
	p1 = points(find(points < bin_walls(lsp)));     % number games . . . 
	p2 = points(find(points > bin_walls(lsp)));
	c1 = classes(find(points < bin_walls(lsp)));
	c2 = classes(find(points > bin_walls(lsp)));
	
	gain = s_ent-class_info_ent(lsp);               % do we have enough information gain?
	
	deltaATS = log2(3^class_number - 2) - (class_number*s_ent - s1_k(lsp)*s1_ent(lsp) -s2_k(lsp)*s2_ent(lsp));
	right_side = log2(N-1)/N + deltaATS/N;
	
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% descend recursively                                           %
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
	if ~(gain < right_side)
		%
		% FIXME intervals is hard-coded to 25. WTF?
		%
		intervals = 25;
        walls = [walls bin_walls(lsp) FindDiscretizationWallsFayyadIrani(p1,c1,intervals) FindDiscretizationWallsFayyadIrani(p2,c2,intervals)];
	else
        walls = [];
	end
else
    walls = [];         % if you're having no luck, just give up
end

function [s_ent, class_number] = class_entropy(classes)

% INPUT         classes         - vector full of class instances
% OUTPUT        s_ent           - class entropy
%               class_number    - how many classes were there
% NOTES
%   calculate the class entropy of several points
%   remember that 'classes' deals with true classes, not discretized labels
%
% Lawrence David - 2003.  lad2002@columbia.edu

[class_list]    = unique(classes);
class_number    = length(class_list);
s_count         = 0;

for i = 1:class_number
    s_count(i) = sum(classes==class_list(i));       % count how many different class instances you have
end

s_temp = s_count/(length(classes)+realmin);

if s_temp == 0
    s_ent = 0;
else
    s_ent = -sum(s_temp.*log2(s_temp));
end