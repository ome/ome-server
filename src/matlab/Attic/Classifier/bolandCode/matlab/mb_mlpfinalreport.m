function mb_mlpfinalreport(trainnetout,trainclass,trainidx,stopnetout,stopclass,stopidx,testnetout,testclass,testidx,names,fileroot)
%  MB_MLPFINALREPORT -
%
%  MB_MLPFINALREPORT(TRINNETOUT,TRAINCLASS,TRAINIDX,STOPNETOUT,STOPCLASS,
%                     STOPIDX,TESTNETOUT,TESTCLASS,TESTIDX,NAMES,FILEROOT)
%
%    Outputs:
%
%    Inputs:
%
%
%    M. Boland - 21 May 1999
%

% $Id$

%
% Find the best thresholds for each network trial
%
thresholds = [0.05:0.05:0.95] ;
onlyone=1 ;
[bestthresh] = mb_mlpthreshtest(stopnetout,stopclass,thresholds,onlyone) ;
%
% Combine the confusion matrices from the network trials
%
[trainconfmats]=mb_mlpconfmatall(trainnetout,trainclass,bestthresh,onlyone) ;
[stopconfmats] = mb_mlpconfmatall(stopnetout,stopclass,bestthresh,onlyone) ;
[testconfmats] = mb_mlpconfmatall(testnetout,testclass,bestthresh,onlyone) ;
%
% Summarize the confusion matrices
%
[trainsummary] = mb_mlpclasssummary(trainconfmats) ;
[stopsummary] = mb_mlpclasssummary(stopconfmats) ;
[testsummary] = mb_mlpclasssummary(testconfmats) ;
%
% write the output to a file
%
diary(strcat(fileroot,'_conf_thresh.txt')) ;
disp('Training Data')
trainsummary.confusion 
trainsummary.confusion_nounk
trainsummary.Pc_mean
trainsummary.Pc_var

disp('Stop Data')
stopsummary.confusion 
stopsummary.confusion_nounk
stopsummary.Pc_mean
stopsummary.Pc_var

disp('Test Data')
testsummary.confusion 
testsummary.confusion_nounk
testsummary.Pc_mean
testsummary.Pc_var

diary
%
% write LaTeX tables for the test data
%
mb_latextable(strcat(fileroot,'_test_thresh.tex'),testsummary.confusion*100,...
              {'DNA','ER','Giantin','GPP130','LAMP2','Mito.','Nucle.',...
               'Actin','TfR','Tubul.'}) ;
mb_latextable(strcat(fileroot,'_test_thresh_nounk.tex'),...
              testsummary.confusion_nounk*100,...
              {'DNA','ER','Giantin','GPP130','LAMP2','Mito.','Nucle.',...
               'Actin','TfR','Tubul.'}) ;

%
% Combine the confusion matrices from the network trials, NO thresholding
%
[trainconfmats]=mb_mlpconfmatall(trainnetout,trainclass,0,0) ;
[stopconfmats] = mb_mlpconfmatall(stopnetout,stopclass,0,0) ;
[testconfmats] = mb_mlpconfmatall(testnetout,testclass,0,0) ;
%
% Summarize the confusion matrices
%
[trainsummary] = mb_mlpclasssummary(trainconfmats) ;
[stopsummary] = mb_mlpclasssummary(stopconfmats) ;
[testsummary] = mb_mlpclasssummary(testconfmats) ;
%
% write the output to a file
%
diary(strcat(fileroot,'_conf.txt')) ;
disp('Training Data')
trainsummary.confusion 
trainsummary.confusion_nounk
trainsummary.Pc_mean
trainsummary.Pc_var

disp('Stop Data')
stopsummary.confusion 
stopsummary.confusion_nounk
stopsummary.Pc_mean
stopsummary.Pc_var

disp('Test Data')
testsummary.confusion 
testsummary.confusion_nounk
testsummary.Pc_mean
testsummary.Pc_var

diary
%
% write LaTeX tables for the test data
%
mb_latextable(strcat(fileroot,'_test.tex'),testsummary.confusion*100,...
              {'DNA','ER','Giantin','GPP130','LAMP2','Mito.','Nucle.',...
               'Actin','TfR','Tubul.'}) ;
mb_latextable(strcat(fileroot,'_test_nounk.tex'),...
              testsummary.confusion_nounk*100,...
              {'DNA','ER','Giantin','GPP130','LAMP2','Mito.','Nucle.',...
               'Actin','TfR','Tubul.'}) ;




[testnames missed assignedto] = mb_misclassnames(names,testidx,testconfmats) ;

mb_misclassnamesprint(strcat(fileroot,'_missed.txt'),missed,assignedto) ;


