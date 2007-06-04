#ifndef OUTPUTDECOMPRESSOR_H_
#define OUTPUTDECOMPRESSOR_H_

#include "Output.h"

class OutputDecompressor : public Output
{
public:
	OutputDecompressor(DataGrid * data, const string & filename);
	virtual ~OutputDecompressor();
	
	void write();
	
	double * write1D(ofstream & output, int & size);
	double * write2D(ofstream & output, int & size);
	double * write3D(ofstream & output, int & size);
	
	double getStats() {};
};

#endif /*OUTPUTDECOMPRESSOR_H_*/

