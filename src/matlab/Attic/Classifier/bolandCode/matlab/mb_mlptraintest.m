function [rnetout,tnetout,imin,net]=mb_mlptraintest(ri,ro,ti,to,hidden,epochs)
%  MB_MLPTRAINTEST - Train and test a multilayer perceptron
%  [RNETOUT,TNETOUT,IMIN,NET] = MB_MLPTRAIN(RI,RO,TI,TO,HIDDEN)
%
%  rnetout - output from trained net for training samples
%  tnetout - output from trained net for test samples
%  imin    - epoch at which the sum of squared error was minimized for the 
%            test set.
%  net     - network after training
%
%  ri      - tRaining set inputs. samples are rows, features are columns
%  ro      - tRaining set outputs . samples are rows, net outputs are columns
%  ti, ti  - same for the Test data
%  hidden  - number of hidden nodes
%  epochs  - number of epochs to complete before checking for
%             a minimum in the SSE on the test (stop) data
%
%  Default parameters:
%   momentum = 0.9
%   learning rate = 0.001

% $Id$

net = mlp(size(ri,2), hidden, size(ro,2), 'logistic') ;

roptions = zeros(1,18) ;
roptions(1) = 1 ;   % Output sse values
%roptions(1) = -1 ;  % Output nothing 
roptions(14) = 1 ;  % Number of epochs (train one epoch at a time)
roptions(17) = 0.9 ;
roptions(18) = 0.001 ;

[net,rsse,tsse] = mb_mlptrain(net, roptions, ri, ro, ti, to, epochs) ;

%
% Round tsse to the nearest 0.001 to avoid long training sessions
%  with little progress
%
[min,imin] = min(round(tsse*1000)/1000) ;
pass=1 ;

%
% Continue training until the minimum SSE occurs less than 90% 
%  of the way through the last pass.
%
while ((imin ./ pass) > 0.9*epochs)
  rssesave = rsse ;
  tssesave = tsse ;
  [net,rsse,tsse] = mb_mlptrain(net,roptions,ri,ro,ti,to,epochs) ;
  rsse = [rssesave rsse] ;
  tsse = [tssesave tsse] ;
  [min,imin] = min(round(tsse*1000)/1000) ;
%  plot([1:length(rsse)], rsse, 'r-', [1:length(tsse)], tsse, 'b-') ;
  pass=pass+1 ;
  pass
  min
  imin
end

%plot([1:length(rsse)], rsse, 'r-', [1:length(tsse)], tsse, 'b-') ;

net = mlp(size(ri,2), hidden, size(ro,2), 'logistic') ;

[net,rsse,tsse] = mb_mlptrain(net, roptions, ri, ro, ti, to, imin) ;

rnetout = mlpfwd(net, ri) ;
tnetout = mlpfwd(net, ti) ;

