function [train_norm, test_norm] = mb_featurenorm(train, test)
% MB_FEATURENORM - Normalize training and test data
%
% [TRAIN_NORM, TEST_NORM] = MB_FEATURENORM(TRAIN, TEST)
%    Normalizes the data in train to have mean=0 and variance=1.
%    The values used to normalize train are also used to normalize test.
%
% M. Boland - 18 Jan 1999

% $Id$

%
% R - number of training samples
% T - number of test samples
%


R = size(train,1) ;
T = size(test,1) ;

%
% Avoid division by 0 by mapping var~0 to var=1
%  NOTE: empirically not necessary -- added after processing
%         an incorrect data set (i.e. a single class)
train_sdev = sqrt(var(train)) ;
% train_sdev = train_sdev + (train_sdev < 1e-10 ) ;
%
% Why was this here?
%test_sdev = sqrt(var(test)) ;
% test_sdev = test_sdev + (test_sdev < 1e-10) ;

train_norm = (train-(ones(R,1)*mean(train))) ./ (ones(R,1)*train_sdev);
if (T > 0)
  test_norm = (test-(ones(T,1)*mean(train))) ./ (ones(T,1)*train_sdev);
else
  test_norm = [] ;
end

