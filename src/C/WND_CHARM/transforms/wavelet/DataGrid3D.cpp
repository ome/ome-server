#include "DataGrid3D.h"
#include "CompressionUtils.h"
#include "Common.h"
#include <fstream>
#include <iostream>
using namespace std;
#include <math.h>

DataGrid3D::DataGrid3D(const string & filename, bool compress)  {
	x = 1;
	y = 1;
	z = 1;
	mode = 1;
	
	dimension = 3;
	ex = 0;

	loadData(filename, compress);
}


DataGrid3D::DataGrid3D(int xval, int yval, int zval)  { 
	x = xval;
	y = yval;
	z = zval;
	
	origx = xval;
	origy = yval;
	origz = zval;
	dimension = 3;
	
	mode = 0;
	
	data = new third[x];
	
	for (int k = 0; k < x; k++) {
		data[k].row = new rows[y];
		for (int j = 0; j < y; j++) {
			data[k].row[j].col = new double[z];
			bzero(data[k].row[j].col,sizeof(double)*z);	
		}
	}	
}

DataGrid3D::~DataGrid3D() {
	for (int k =0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			delete data[k].row[j].col;
		}
		delete data[k].row;
	}
	delete data;
}

void DataGrid3D::setData(int xval, int yval, int zval, double value) {
	if (data == NULL || xval > x || yval > y || zval > z) {
		return;
	}
	
	data[xval].row[yval].col[zval] = value;
}

double DataGrid3D::getData(int xval, int yval, int zval) {
	if (xval >= x || yval >= y || zval >= z) {
		cout << "REQUESTING BAD DATA: " << xval << "," << yval <<
		" and max size is: " << x << "," <<yval << endl;
	}
	
	return data[xval].row[yval].col[zval];
}

void DataGrid3D::loadCompressedData(ifstream & input) {
	
	double * result = CompressionUtils::inflate(this,input);
	int index = 0;
		
	for (int k =0; k < x; k++) {
		data[k].row = new rows[y];
		for (int j = 0; j < y; j++) {
			data[k].row[j].col = new double[z];
			bzero(data[k].row[j].col,sizeof(double)*z);
			for (int i = 0; i < z; i++) {
				double val = result[index];
				data[k].row[j].col[i] = val;	
				index++;
			}
		}	
	}
	delete result;

}

void DataGrid3D::output() {
	for (int k =0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			cout << k << "," << j << endl;
			for (int i = 0; i < z; i++) {
				cout <<"\t" << i << " = " << this->getData(k,j,i) << " ";
			}	
			cout << endl;
		}	
	}
	
	cout << " sized: " << x << " " << y << " " << z << endl;
}

void DataGrid3D::resize(int newx, int newy, int newz, bool copy) {
	
	if (verbose) cout << " have to resize final array to: " << newx <<
		"," << newy << "," << newz << endl;
		
	third * newdata = new third[newx];
	
	for (int k = 0; k < newx; k++) {
		newdata[k].row = new rows[newy];
		for (int j = 0; j < newy; j++) {
			newdata[k].row[j].col = new double[newz];
			bzero(newdata[k].row[j].col,sizeof(double)*newz);	
		}
	}	
	
	
	if (copy) {
		for (int k =0; k < x; k++) {
			for (int j = 0; j < y; j++) {
				for (int i = 0; i < z; i++) {
					newdata[k].row[j].col[i] = this->getData(k,j,i);
				}
			}	
		}
	}	

	delete data;
	data = newdata;
	
	x = newx;	
	y = newy;
	z = newz;
}

void DataGrid3D::copyTo(DataGrid * newData) {

	for (int k =0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			for (int i = 0; i < z; i++) {
				double val = this->getData(k,j,i);
				newData->setData(k,j,i,val);
			}
		}	
	}
}

void DataGrid3D::loadData(const string & filename, bool compress) {
	
	ifstream input(filename.c_str(), ios::in | ios::binary);
	
	input.seekg(0);
	
	int dimension, xsize, ysize,  zsize;
	
	// if we are decompressin	
	if (!compress) {
		
		int originalx, originaly, originalz;
		
		input.read((char*)&dimension, sizeof (int));
		input.read((char*)&xsize, sizeof (int));
		input.read((char*)&ysize, sizeof (int));
		input.read((char*)&zsize, sizeof (int));
		input.read((char*)&originalx, sizeof (int));	
		input.read((char*)&originaly, sizeof (int));	
		input.read((char*)&originalz, sizeof (int));	
		
		this->origx =  originalx;
		this->origy =  originaly;
		this->origz =  originalz;
		
		if (verbose) cout << "Data has a current (X,Y,Z): (" << xsize << "," << ysize <<
			"," << zsize << ") with dimension " << dimension << " but is originally sized (X,Y) : (" << 
			origx << "," << origy << "," << origz << ") " << endl;	
	}
	else {
		double xs, ys, zs;
		input.read((char*)&xs, sizeof (double));
		input.read((char*)&ys, sizeof (double));
		input.read((char*)&zs, sizeof (double));
	
		xsize = (int) xs;
		ysize = (int) ys;
		zsize = (int) zs;
	
		this->origx = xsize;
		this->origy = ysize;
		this->origz = zsize;
	
		mode = 0;	
	}
	
	if (x <= 0 || y <= 0 || z <= 0) {
		cout << "The X and Y values are not correct (" << x << "," << y << "). " <<
		"Perhaps, this is not the correct dimension " << endl;	
	}
	
	x =  xsize;
	y =  ysize;
	z =  zsize;
	
	originalFileSize = x*y*z*sizeof(double) + sizeof(double)*3;
	
	if (x != y) {
		cout << "You should use a square matrix. Results may not be accurate" << endl;
	}
	
	data = new third[x];
	
	if (!compress) {
		this->loadLevels(input);
		this->loadCompressedData(input);
		return;
	}
	
	for (int k =0; k < x; k++) {
		data[k].row = new rows[y];
		for (int j =0; j < y; j++) {
			data[k].row[j].col = new double[z];
			bzero(data[k].row[j].col,sizeof(double)*z);
		}
	}
	
	for (int k = 0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			for (int i = 0; i < z; i++) {
				input.read((char*)&data[k].row[j].col[i], sizeof (double));			
			}
		}	
	}

	input.close();
}

void DataGrid3D::loadLevels(ifstream & input) {
	
	input.read((char*)&mode, sizeof (int));
	
	int l;
	input.read((char*)&l, sizeof (int));
	(this->levels) = l;
	if (verbose) cout << "levels: " << this->levels << endl; 
	
	this->levelStructure = new int[this->levels*3];
	
	for (int k = 0; k < this->levels*3; k+=3) {
		input.read((char *)&(this->levelStructure[k]),sizeof(int));
		input.read((char *)&(this->levelStructure[k+1]),sizeof(int));
		input.read((char *)&(this->levelStructure[k+2]),sizeof(int));
		if (verbose)  cout << "level size: " << k << " = " 
			<< this->levelStructure[k] << " x " <<
			this->levelStructure[k+1] << " x " << 
			this->levelStructure[k+2] << endl;
	}
}

void DataGrid3D::stripZeros(double limit) {
	
	int count = 0;
	for (int k = 0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			for (int i = 0; i < z; i++) {
				double val = this->getData(k,j,i);
				if (fabs(val) < limit) {
					count++;
					val = 0;	
				}	
				this->setData(k,j,i,val);
			}
		}		
	}		
	if (verbose)  cout << "Thresholding removed: " << count << " zeros with limit: " << limit << endl;
}
