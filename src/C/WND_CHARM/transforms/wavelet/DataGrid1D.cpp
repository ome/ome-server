#include "DataGrid1D.h"
#include "CompressionUtils.h"
#include "Common.h"
#include <fstream>
#include <iostream>
using namespace std;
#include <bzlib.h>
#include <math.h>

DataGrid1D::DataGrid1D(const string & filename, bool compress)  {
	x = 1;
	y = 1;
	z = -1;
	mode = 1;
	
	dimension = 1;
	
	loadData(filename, compress);
}

DataGrid1D::DataGrid1D(int xval, int yval, int zval)  { 
	x = xval;
	y = yval;
	z = zval;
	
	origx = xval;
	origy = yval;
	origz = zval;
	
	dimension = 1;
	
	mode = 0;
	
	data = new double[x];
	bzero(data,x);
}

void DataGrid1D::resize(int newx, int newy, int newz, bool copy) {
	double * newdata = new double[newx];
	bzero(newdata,newx);	
	
	if (copy) {
		for (int k = 0; k < x; k++) {
			newdata[k] = data[k];	
		}
	}	

	delete data;
	data = newdata;
	x = newx;	
}


DataGrid1D::~DataGrid1D() {
	delete data;
}

void DataGrid1D::setData(int xval, int yval, int zval, double value) {
	if (data == NULL || xval > x) {
		return;
	}
	
	data[xval] = value;
}

double DataGrid1D::getData(int xval, int yval, int zval) {
	if (data == NULL || xval > x) {
		return 0;
	}
	return data[xval];
}

void DataGrid1D::loadCompressedData(ifstream & input) {
	
	data = CompressionUtils::inflate(this,input);
}

void DataGrid1D::loadData(const string & filename, bool compress) {
	
	ifstream input(filename.c_str(), ios::in | ios::binary);
	
	input.seekg(0);
	
	int xsize, dimension, original; 

	// if we are decompressin	
	if (!compress) {
		
		input.read((char*)&dimension, sizeof (int));
		input.read((char*)&xsize, sizeof (int));	
		input.read((char*)&original, sizeof (int));	
		
		this->origx = original;
		
		if (verbose) cout << "data is sized x: " << xsize << " : " << dimension 
			<< " but originally sized: " << origx <<endl;	
	}
	else {
		double xs;
		input.read((char*)&xs, sizeof (double));
		this->origx = (int) xs;	
		mode = 0;	
		xsize = (int) xs;
		
		if (verbose) cout << "Data has a size of " << xsize << endl;
	}
	
	x = (int) xsize;
	
	if (x <= 0) {
		cout << "The X value is not correct (" << x <<  "). " <<
		"Perhaps, this is not the correct dimension, or the file is" << 
		" not formatted correctly" << endl;	
		exit(0);
	}
	
	originalFileSize = x*sizeof(double) + sizeof(double);
		
	data = new double[(int)x];
	
	// if we are decompressin
	if (!compress) {
		this->loadLevels(input);
		this->loadCompressedData(input);
		return;
	}
	
	input.read((char*)data, sizeof (double)*x);
	input.close();
}

void DataGrid1D::loadLevels(ifstream & input) {
	input.read((char*)&mode, sizeof (int));
	
	int l;
	input.read((char*)&l, sizeof (int));
	(this->levels) = l;
	if (verbose) cout << "levels: " << this->levels << endl; 
	this->levelStructure = new int[this->levels];
	for (int k = 0; k < this->levels; k++) {
		input.read((char *)&(this->levelStructure[k]),sizeof(int));
		if (verbose) cout << "level size: " << k << " = " << this->levelStructure[k] << endl;
	}
	
	return;	
}

void DataGrid1D::output() {
	
	for (int j = 0; j < x; j++) {
		cout << this->getData(j,0,0) << " ";
	}	
	
	cout << " sized: " << x << endl;
}

void DataGrid1D::copyTo(DataGrid * newData) {

	for (int k =0; k < x; k++) {
		double val = this->getData(k,0,0);
		newData->setData(k,0,0,val);
	}
}

void DataGrid1D::stripZeros(double limit) {
	
	int count = 0;
	for (int k = 0; k < x; k++) {
		double val = this->getData(k,0,0);
		if (fabs(val) < limit) {
			count++;
			val = 0;	
		}
		this->setData(k,0,0,val);
	}		

	if (verbose) cout << "Thresholding " << 
	" removed : " << count << " zeros with limit: " << limit << endl;
}
