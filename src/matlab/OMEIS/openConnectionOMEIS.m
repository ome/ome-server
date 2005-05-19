function [is] = openConnectionOMEIS(url, sessionkey);
% function [is] = openConnectionOMEIS.m (url, sessionkey) Create OMEIS connection
% 	Returns a struct encapsulating information about connection with OMEIS
%	required to pass to almost all other omeis-http functions

if nargin < 2
	sessionkey='00000';
end
is.url = url;
is.sessionkey = sessionkey;