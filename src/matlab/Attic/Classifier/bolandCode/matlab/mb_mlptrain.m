function [net, rsse, tsse] = mb_mlptrain(net, roptions, ri, ro, ti, to, epochs)
%  MB_MLPTRAIN(NET,ROPTIONS,RI,RO,TI,TO,EPOCHS)
%  [NET,RSSE,TSSE] = MB_MLPTRAIN(NET,ROPTIONS,RI,RO,TI,TO,EPOCHS)
%
%    Outputs:
%     NET - neural network after training
%     RSSE - vector of sum of squared error for the training data
%     TSSE - vector of sum of squared error for the test data
%
%    Inputs:
%     NET - neural network before training
%     ROPTIONS - 18 element vector of net options
%     RI - training data inputs
%     RO - training data outputs
%     TI - test data inputs
%     TO - test data outputs
%     EPOCHS - number of training epochs
%
%    To generate NET:
%     net=mlp(nin, nhidden, nout, func), where func is 'linear',
%         'logistic', or 'softmax'.
%
%    To generate ROPTIONS:
%     roptions = zeros(1,18) ; 
%     roptions(14) = 1 ;     % Number of iterations
%     roptions(1) = 1 ;      % Does not work unless this option is set hmmm...
%     roptions(17) = 0.9 ;   % Momentum
%     roptions(18) = 0.001 ; % Learning Rate
%
%    After training:
%     rnetout = mlpfwd(net, ri) ;
%     tnetout = mlpfwd(net, ti) ;
%     [rcmat, rcrate, rmissed] = mb_confmat(rnetout, rclass) ;
%     [tcmat, tcrate, tmissed] = mb_confmat(tnetout, tclass) ;
%
%    M. Boland - 16 Feb 1999
%

% $Id$

tsse = [] ;
rsse = [] ;

for i = 1:epochs,
	[net, roptions] = netopt(net, roptions, ri, ro, 'graddesc') ;
	rsse = [rsse roptions(1,8)] ;
	tsse = [tsse mlperr(net, ti, to)] ;
end

