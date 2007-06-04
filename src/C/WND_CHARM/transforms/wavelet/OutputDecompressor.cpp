#include "OutputDecompressor.h"
#include "Common.h"
#include <fstream>
#include <iostream>
using namespace std;

OutputDecompressor::OutputDecompressor(DataGrid * d, const string & file)  {
	filename = file;
	data = d;
}

OutputDecompressor::~OutputDecompressor()
{
}

double * OutputDecompressor::write1D(ofstream & output, int & size) {
	double x = data->getOriginalX();
		
	cout << " Data sized x: " << x <<  endl;
	
	output.write((char *)&x,sizeof(double));
	for (int k = 0; k < x; k++) {
		double num = data->getData(k,0,0);
		output.write((char *)&num, sizeof (double));
	}

}

double * OutputDecompressor::write2D(ofstream & output, int & size) {
	
	double x = data->getOriginalX();
	double y = data->getOriginalY();
		
	if (verbose) cout << " Data sized x: " << x << " and y: " << y << endl;
	
	output.write((char *)&x,sizeof(double));
	output.write((char *)&y,sizeof(double));
	for (int k = 0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			double num = data->getData(k,j,0);
			output.write((char *)&num, sizeof (double));			
		}	
	}
}

double * OutputDecompressor::write3D(ofstream & output, int & size) {
	double x = data->getOriginalX();
	double y = data->getOriginalY();
	double z = data->getOriginalZ();
		
	if (verbose) cout << " Data sized x: " << x << " and y: " << y << 
		" and z: " << z << endl;
	
	output.write((char *)&x,sizeof(double));
	output.write((char *)&y,sizeof(double));
	output.write((char *)&z,sizeof(double));
	
	for (int k = 0; k < x; k++) {
		for (int j = 0; j < y; j++) {
			for (int i = 0; i < z; i++) {
				double num = data->getData(k,j,i);
				output.write((char *)&num, sizeof (double));
			}			
		}	
	}

}

void OutputDecompressor::write() {
	
	string outfile = filename.substr(0,filename.find(".wcm")); 
	ofstream output(outfile.c_str(), ios::out | ios::binary);

	cout << "Writing to file: " << outfile << endl;
	double * outarray = NULL; 
	int size = 0;

	switch (data->getDimension()) {
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
	
	output.close();
}


