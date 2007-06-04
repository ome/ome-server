#ifndef DATAGRID1D_H_
#define DATAGRID1D_H_

#include "DataGrid.h"

class DataGrid1D : public DataGrid
{
public:
//	DataGrid1D(const string & filename, bool compress);
	DataGrid1D(int xval, int yval, int zval);
	~DataGrid1D();
	double getData(int x, int y, int z);
	void setData(int xval, int yval, int zval, double value);
	
	void copyTo(DataGrid * newData);
	
	void output();
	
	void stripZeros(double limit);
	
	void resize(int newx, int newy, int newz, bool copy);
	
protected:
//	void loadData(const string & filename, bool compress);
//	void loadCompressedData(ifstream & input);
//	void loadLevels(ifstream & input);
	double * data;
};

#endif /*DATAGRID1D_H_*/
