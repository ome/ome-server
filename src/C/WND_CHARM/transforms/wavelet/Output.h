#ifndef OUTPUT_H_
#define OUTPUT_H_

#include <string>
using namespace std;
#include "DataGrid.h"

class Output
{
public:
	Output();
	virtual ~Output();
	
	virtual void write() = 0;
	virtual double getStats() {};

protected:
	string filename;
	int mode;
	DataGrid * data;
};

#endif /*OUTPUT_H_*/
