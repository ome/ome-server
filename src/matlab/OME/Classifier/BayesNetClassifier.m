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

% INPUT NEEDED      
%   'discData_int'  - Discretized signature for a particular instance.
%                     Discretization walls and signatures must correspond to 
%                     the signatures ultimately (i.e. after feature subset
%                     selection) used to train the Bayesian Network
%   'bnet'          - Trained Bayesian Network 
%
% OUTPUT GIVEN
%   'marginal_probs' - vector of doubles storing with what predicted 
%                      probabilities the instance belongs to those classes
% 
% Tom Macura - 2005. tm289@cam.ac.uk

function [marginal_probs] = BayesNetClassifier (bnet, discData_inst);
[hei len] = size(discData_inst);
engin = jtree_inf_engine(bnet);       % VROOM VROOM goes the inference engine

evidence = cell(1, hei+1);            % the +1 refers to the node that has

% load evidence
for u = 1:hei
	evidence{u}=discData_inst(u,:);
end

[engin, loglik] = enter_evidence(engin,evidence);
marginal_probs  = marginal_nodes(engin,hei+1);
marginal_probs  = marginal_probs.T';
