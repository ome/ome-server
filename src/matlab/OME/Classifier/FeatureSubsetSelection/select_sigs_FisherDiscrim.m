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
% Written By: Nikita Orlov <orlovni@nih.gov>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Alternative way to seek for the best signatures is based on the score reported by the 
% Fisher Discriminant (minimum variation within the class, maximum difference between classes)
%
% Example:
%	[best_sigs all_scores] = select_sigs_FisherDiscrim(1,DDB,class_vec,Ncla,sig_labels);
%%place_ind = select_sigs_FisherDiscrim(50,DDB,class_vec,Ncla,sig_labels);


function [place_ind all_scores discrDDB] = select_sigs_FisherDiscrim(nrep,DDB,class_vec,Ncla,sig_labels),

[DDB,get_rid,labelIndex] = discr_data(DDB,Ncla,sig_labels);
discrDDB = DDB;


%........................
idump = 0;
if idump, hei = size(DDB,1); 
 dump_discr_data(DDB,sig_labels,Ncla,hei,1:hei);
 error(':: discr_data saved, abort mission ::');
end
%........................


%nums = [5 17 25 49 121 193 217 241 265 289 313 343 373 403 433 448 472 496 520 544 568 616 664 712 760 808];
%labs = {'blob/region','edge/hull','Haralick','Zernike','Zernike(FFT)','Haralick(FFT)','Haralick(WL)', ...
%    'Haralick(WL(fft))','Haralick(Cheb)','Haralick(Cheb(fft))','Cheb short','Cheb(fft) short', ...
%    'Cheb-Forier','Cheb-Forier(fft)','Gabor','multi-scale hist','msh(WL)','msh(WL(fft))','msh(Cheb)','msh(Cheb(fft))', ...
%    'Radon','4-comb moments','4-cm(FFT)','4-cm(WL)','4-cm(Cheb)','Tamura'};

dtaPartition = 0.00;
givenList = 1:Ncla;

[sorted_sig_index foo all_scores] = runFD_1time(DDB,Ncla,dtaPartition,class_vec,givenList,sig_labels);
place_ind = sorted_sig_index;
return;


function dump_discr_data(DDB,sig_labels,class_number,hei,good_sigs),
discType  = cellstr('FI'); class_vec = DDB(end,:);
dummy = zeros(hei,size(DDB,2)); dummy(end,:) = class_vec;
labs{hei-1} = [];
for ii = 1:length(good_sigs), ind = good_sigs(ii);
 dummy(ind,:) = DDB(ii,:); labs{ind} = sig_labels{ii};
end
DDB = dummy;
save('cla_du_Discr_DDB.mat','DDB','class_vec','sig_labels','good_sigs','-V6'); 
fprintf('.. discr. matrix saved ..\n');
return;


function [discrData,get_rid,labelIndex] = discr_data(DDB,Ncla,sig_labels),
class_vec = DDB(end,:);
[hei len]    = size(DDB);                     % remove all of the useless features quickly with the 
get_rid      = [];                          % help of FI discretization
class_number = Ncla;    % how many classes are there
for ii = 1:hei-1
 temp3 = findBestDiscFIa(DDB(ii,:),40,DDB(end,:));
 if length(temp3)==0, get_rid = [get_rid ii]; end
end
goodies = mysetdiff(1:(hei),get_rid);               % these are the signatures to explore
good_sigs0 = goodies;
fprintf('there were %d original signatures\n',hei);
fprintf('there are now %d signatures left\n',length(good_sigs0));
ddb = DDB; ddb(get_rid,:) = 0; ddb(end,:) = DDB(end,:);
order = 1:size(DDB,1); labelIndex = order(goodies);
[discrData junk] = discretize(ddb,'FI',Ncla);
return;


function varargout = runFD_1time(DDB,Ncla,dtaPartition,class_vec,givenList,sig_labels),

learn = DDB; target = class_vec; Ncla2 = max(givenList);
if Ncla2~=Ncla,
 [DDB, class_vec] = leaveNclasses(learn,target,Ncla,givenList); clear learn;
end
[len_SType,unique_labels] = countLabelSizes(sig_labels,1);

%% here is what are sig sizes after the discretization threw away some of them...
%%for ii = 1:length(unique_labels), fprintf(' #%02u . . [%3u]: %s\n',ii,len_SType(ii),cell2mat(unique_labels(ii)));end

if dtaPartition > eps,
 [DDB,class_vec] = reduceData_in_classes(dtaPartition,DDB);
end

% how many of the best to show up...
Nbest = size(DDB,1)-1; 

% upper threshold: do not go further than sig number 'upperSig'
upperSig = size(DDB,1);

[m,n] = size(DDB); Nbest = min(m-1,Nbest);

%%[nums,labs] = constrainLabs(upperSig,nums,labs);
nums = len_SType; labs = unique_labels;

[sorted_sig_index,G,sig_labels_best] = sord_by_FD(DDB,class_vec,Nbest,1,sig_labels,0); % with pre-alignment
%%disp(sorted_sig_index(1:10));error(':: stop');

sorted_sig_index = screen_by_chunks(sorted_sig_index,nums);
varargout{1} = sorted_sig_index;

Sig_place = 1:length(sorted_sig_index);
varargout{2} = Sig_place;
varargout{3} = G;
return;

%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
%% Here we want to constrain the seleclted sigs to only those that
%% belongs to different 'chunks' of sigs 
%% (so that there are no 2 different selected sigs that belongs to the same
%% chunk)
%% Use:
%% sorted_sig_index = screen_by_chunks(sorted_sig_index,nums);

function screened_signal = screen_by_chunks(in_signal,chunks),
screened_signal = []; used_chunks = [];
chunks = [0 cumsum(chunks)];       % tails of chunk
for ii = 1:length(in_signal),curr_sig = in_signal(ii);
 current_chunk_begin = find(curr_sig > chunks);
 current_chunk_begin = max(current_chunk_begin);
 if (isempty(current_chunk_begin))|(~isempty(intersect(current_chunk_begin,used_chunks))),continue;end
 screened_signal = [screened_signal curr_sig];
 used_chunks = [used_chunks current_chunk_begin];
end
return;

%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function [nums,labs] = constrainLabs(Nbest,nums0,labs0),
ii = 1:length(nums0);
nums = nums0(nums0<=Nbest); last = length(nums);
labs = labs0(1:last);
return;


%::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function  [A,class_vec] = reduceData_in_classes(part,DDB),
A = []; class_vec = DDB(end,:); ut = unique(class_vec);
part = 1 - part;
for ii = 1:length(ut), cla = find(class_vec==ut(ii));
 tmp = DDB(:,cla);  n = size(tmp,2);
 jsz = min(n,floor(part*n)); if jsz > n | jsz < 1, jsz = n; end
 jlen(ii) = jsz;
end
jsz = min(jlen);
for ii = 1:length(ut), cla = find(class_vec==ut(ii));
%tmp = DDB(:,cla);  n = size(tmp,2); jtmp = randperm(n); jtmp = jtmp(1:jsz); A = [A tmp(:,jtmp)];
%tmp = DDB(:,cla);  n = size(tmp,2); jtmp = randperm(jsz); A = [A tmp(:,jtmp)];
 tmp = DDB(:,cla);  n = size(tmp,2); jtmp = 1:(jsz); jtmp = jtmp(1:jsz); A = [A tmp(:,jtmp)];
end
class_vec = A(end,:);
return;


function print_sig_labels(unique_labels,b0,b1,PRkey),
if PRkey,
 for ii = 1:length(unique_labels),fprintf('%03u ..%26s.. %03u:%03u\n',ii,unique_labels{ii},b0(ii),b1(ii));end
else,
 fprintf('%s\n',num2str(b0,' %03u'));
 fprintf('%s\n',num2str(b1,' %03u'));
end %% if
return;


function [myb,G,sig_labels_best] = sord_by_FD(DDB,class_vec,nmax,alignKey,sig_labels,verbose)
mddb=mean(DDB,2);

mddb=DDB-mddb*ones(1,size(DDB,2)); 
sddb=std(DDB,0,2); sddb(sddb<1e-15)=1;mddb=mddb./(sddb*ones(1,size(DDB,2))); DDB0 = mddb;
[L,n] = size(DDB0);
%-----------------------------------------------
% compute statistics for ALL signatures
% (either with pre-alignment of data of without it)
if alignKey,
 [Sw,Sb,nc] = getStats(DDB0,class_vec);
else,
 [Sw,Sb,nc] = getStats(DDB,class_vec);
end
disp([Sw(1:20) Sb(1:20)]);
for ii=1:L-1,
 G(ii) = Sb(ii)./(Sw(ii)+eps);
end
%-----------------------------------------------
[junk,ix]=sort(-G);
myb = ix(1:nmax);
Gfd = G(myb); sig_labels_best = sig_labels(myb);
if ~verbose,return;end
ddb = DDB(myb,:);
cnt = 0;
for ii = myb, cnt = cnt + 1; 
 row = ddb(cnt,:);
 fprintf('%03u  %13.4e (%11.3e/%11.3e)   [ #%03u .. %s ]\n',cnt,Gfd(cnt),mean(row),std(row),ii,sig_labels_best{cnt});
end
return;


function [xi,Ncla,prt] = split2classes(X,class_vec)
uc = unique(class_vec); Ncla = length(uc);
for cla=1:Ncla, 
 ci = find(class_vec==cla); prt(cla) = length(ci); xi{cla} = X(:,ci); 
end
return;

% compute statistics for ALL signatures. 
% Sw: statistics within the class; Sb: statistics between classes (is the common convention).
function [Sw,Sb,nc] = getStats(X,class_vec),
[xi,Ncla,nc] = split2classes(X,class_vec);

N = sum(nc);
avgS = zeros(size(X,1),1);
sumStd = avgS;
for ii = 1:Ncla,
 ma_i(:,ii) = mean(xi{ii},2);
 xxmi = xi{ii} - ma_i(:,ii)*ones(1,size(xi{ii},2)); % (xi - mean xi)
 Si = 1./size(xi,2).*sum(xxmi.^2,2);
 Sw(:,ii) = Si;
end
Sw = (1/Ncla) * sum(Sw,2);
mm = mean(ma_i,2);
for ii = 1:Ncla,
 Sb(:,ii) = (mean(xi{ii},2) - mm).^2;
end
Sb = (1/Ncla) * sum(Sb,2);
% now all vars computed (avgSi,stdSi,avgS,sumStd) 
% are vectors of the size(X,1) ; there needed a projection to select fewer sigs 
return;


%........................................................................
% Block functions for splitting data 'by_signatures'
% Use example: 
%[len_SType,unique_labels] = countLabelSizes(sig_labels,1);
%ddb = divideDDB_by_sigType(DDB,sig_labels,len_SType,unique_labels);

function [ddb,sub_labels,b0,b1] = divideDDB_by_sigType(DDB,sig_labels,len_SType,unique_labels),
DDB = double(DDB); sub_labels{1} = [];
[b0,b1] = partitionBoundaries(len_SType);
Nlabs = length(len_SType);
for indx_sig = 1:Nlabs,
 [ix_start_from,ix_finish_by] = crop_oneSig_Data(indx_sig,b0,b1);
 ddb{indx_sig} = DDB(ix_start_from:ix_finish_by,:);
 sub_labels{indx_sig} = sig_labels(ix_start_from:ix_finish_by);
end
return;

function [ix_start_from,ix_finish_by] = crop_oneSig_Data(indx_sig,b0,b1),
ix_start_from = b0(indx_sig);
ix_finish_by  = b1(indx_sig);
return;

function [b0,b1] = partitionBoundaries(lenSType)
Nlabs = sum(lenSType);
b1 = cumsum(lenSType);  %upper boundaries
b0 = b1-lenSType+1;     %lower boundaries
return;

function [len_SType,reduced_labels] = countLabelSizes(sig_labels,pca_rows),
Nlabs = max(size(sig_labels)); len_SType = [];
cnt = 0; ii = 1; i0 = 1;
while ii < Nlabs, cnt = cnt + 1;
 dummy = sig_labels{ii};
% reduced_labels{cnt} = [dummy(1:end-2)]; 
% Modified for new style of signature label
dots = strfind( dummy, '.' );
reduced_labels{cnt} = [dummy(1:dots(end-1)-1)]; 
 for ll = 2:pca_rows, cnt = cnt + 1;
  reduced_labels{cnt} = [dummy(1:end-2) 'pca ' num2str(ll,'%2u')]; 
 end % for ll
 [n, ii] = countSType(sig_labels,ii,Nlabs);
 len_SType = [len_SType n];
end
return;

% count elements of one Signature type...
function [cnt,ii] = countSType(labelStype,i0,Nlabs),
done = 0; jj = 0; cnt = 0;
mask = labelStype{i0}(1:end-2);
% Modified for new style of signature label
dots = strfind( mask, '.' );
mask = [mask(1:dots(end-1)-1)]; 
while ~done, 
 curr = labelStype{i0+jj};
% Modified for new style of signature label
dots = strfind( curr, '.' );
curr = [curr(1:dots(end-1)-1)]; 
 if ~strcmp(mask,curr),done = 1;end
% if ~strcmp(mask,curr(1:end-2)),done = 1;end
 jj = jj + 1; if ~done, cnt = cnt + 1;end
 if i0+jj > Nlabs, done = 1; end
end;
ii = i0 + cnt;
return;
