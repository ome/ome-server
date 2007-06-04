#ifndef OUTPUTCOMPRESSOR_H_
#define OUTPUTCOMPRESSOR_H_

#include <string>
using namespace std;

#include "Output.h"
#include "DataGrid.h"

class OutputCompressor :  public Output
{
public:
	OutputCompressor(DataGrid * data, const string & filename, int mode);
	virtual ~OutputCompressor();
	
	void write();
	double getStats();
	void bZip(ofstream & output, double * outarray, int size);
	
private:
	double compratio;

	double * write1D(ofstream & output, int & size);
	double * write2D(ofstream & output, int & size);
	double * write3D(ofstream & output, int & size);
	
};

#endif /*OUTPUTCOMPRESSOR_H_*/
