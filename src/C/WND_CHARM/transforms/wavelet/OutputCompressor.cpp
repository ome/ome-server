#include "OutputCompressor.h"
#include "CompressionUtils.h"
#include "Common.h"
#include <fstream>
#include <iostream>
using namespace std;

extern bool verbose;

OutputCompressor::OutputCompressor(DataGrid * d, const string & file, int m)  {
	filename = file;
	data = d;
	mode = m;
	compratio = 0;
}

OutputCompressor::~OutputCompressor()
{
	
}

double * OutputCompressor::write1D(ofstream & output, int & size) {
	int xOrig = data->getOriginalX();
	int x = data->getX();
	int mode =  data->getMode();
	int levels = data->levels;
	
	output.write((char *)&x,sizeof(int));
	output.write((char *)&xOrig,sizeof(int));
	output.write((char *)&mode,sizeof(int));

	output.write((char *)&levels,sizeof(int));
	for (int k = 0; k < data->levels; k++) {
		output.write((char *)&(data->levelStructure[k]),sizeof(int));
	}
	
	if (verbose) cout << "Writing data sized x: " << x << " with mode = " << mode << 
	" and levels = " << levels << endl;
	
	size = (int)(x);
	double * outarray = new double[size];
	
	for (int k =0; k < x; k++) {
		double num = data->getData(k,0,0);
		outarray[k] = num;
	}
	
	return outarray;
}

double * OutputCompressor::write2D(ofstream & output, int & size) {

	int xOrig = data->getOriginalX();
	int yOrig = data->getOriginalY();
	
	int x = data->getX();
	int y = data->getY();
	int mode = data->getMode();
	int levels = data->levels;
	
	output.write((char *)&x,sizeof(int));
	output.write((char *)&y,sizeof(int));	
	output.write((char *)&xOrig,sizeof(int));
	output.write((char *)&yOrig,sizeof(int));
	output.write((char *)&mode,sizeof(int));

	output.write((char *)&levels,sizeof(int));
	for (int k = 0; k < data->levels*2; k+=2) {
		output.write((char *)&(data->levelStructure[k]),sizeof(int));
		output.write((char *)&(data->levelStructure[k+1]),sizeof(int));
	}
	
	if (verbose) cout << "writing data sized x: " << x << " with mode = " << mode << 
	" and levels = " << levels << endl;
		
	size = (int)(x*y);
	double * outarray = new double[size];
	
	int index = 0;
	for (int k =0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			double num = data->getData(k,j,0);
			outarray[index] = num;
			index++;		
		}	
	}
		
	return outarray;
	
}


double * OutputCompressor::write3D(ofstream & output, int & size) {
	int xOrig = data->getOriginalX();
	int yOrig = data->getOriginalY();
	int zOrig = data->getOriginalZ();
	
	int x = data->getX();
	int y = data->getY();
	int z = data->getZ();
	int mode = data->getMode();
	int levels = data->levels;
	
	output.write((char *)&x,sizeof(int));
	output.write((char *)&y,sizeof(int));	
	output.write((char *)&z,sizeof(int));	
	output.write((char *)&xOrig,sizeof(int));
	output.write((char *)&yOrig,sizeof(int));
	output.write((char *)&zOrig,sizeof(int));
	output.write((char *)&mode,sizeof(int));

	output.write((char *)&levels,sizeof(int));
	for (int k = 0; k < data->levels*3; k+=3) {
		output.write((char *)&(data->levelStructure[k]),sizeof(int));
		output.write((char *)&(data->levelStructure[k+1]),sizeof(int));
		output.write((char *)&(data->levelStructure[k+2]),sizeof(int));
	}
	
	if (verbose) cout << "writing data sized x: " << x << 
	" with mode = " << mode << 
	" and levels = " << levels << endl;
		
	size = (int)(x*y*z);
	double * outarray = new double[size];
	
	int index = 0;
	for (int k =0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			for (int i = 0; i < z; i++) {
				double num = data->getData(k,j,i);
				outarray[index] = num;
				index++;
			}		
		}	
	}
	
	return outarray;

}


void OutputCompressor::write() {
	string outfile = filename + ".wcm"; 
	ofstream output(outfile.c_str(), ios::out | ios::binary);
	
	int dimension = data->getDimension();
	
	output.write((char *)&dimension,sizeof(int));
	double * outarray = NULL; 
	int size = 0;

	switch ((int)dimension) {
		case 1:
			outarray = write1D(output,size);
			break;
		case 2:
			outarray = write2D(output,size);
			break;
		case 3:
			outarray = write3D(output,size);
			break;
	}

	double newsize = CompressionUtils::deflate(output,outarray,size);
	compratio = data->getOriginalFileSize() / newsize;
	output.close();
}



double OutputCompressor::getStats() {
	return compratio;	
}
