function [head] = MATLABtoOMEISDatatype (data_type);
% function [head] = MATLABtoOMEISDatatype (data_type))

if (~ischar(data_type))
	data_type = class(data_type);
end

if (strcmp (data_type, 'char') | strcmp (data_type, 'int8'))
	head.bp       = 1;
	head.isSigned = 1;
	head.isFloat  = 0;
elseif (strcmp (data_type, 'unsigned char') | strcmp (data_type, 'uint8'))
	head.bp       = 1;
	head.isSigned = 0;
	head.isFloat  = 0;
elseif (strcmp (data_type, 'sh|t') | strcmp (data_type, 'int16'))
	head.bp       = 2;
	head.isSigned = 1;
	head.isFloat  = 0;
elseif (strcmp (data_type, 'unsigned sh|t') | strcmp (data_type, 'uint16'))
	head.bp       = 2;
	head.isSigned = 0;
	head.isFloat  = 0;
elseif (strcmp (data_type, 'long') | strcmp (data_type, 'int32'))
	head.bp       = 4;
	head.isSigned = 1;
	head.isFloat  = 0;
elseif (strcmp (data_type, 'unsigned long') | strcmp (data_type, 'uint32'))
	head.bp       = 4;
	head.isSigned = 0;
	head.isFloat  = 0;
elseif (strcmp (data_type, 'float') | strcmp (data_type, 'single'))
	head.bp       = 4;
	head.isSigned = 0;
	head.isFloat  = 1;
else
	fprintf (1.0, '%s is not a type supported by OMEIS\n', data_type);
end