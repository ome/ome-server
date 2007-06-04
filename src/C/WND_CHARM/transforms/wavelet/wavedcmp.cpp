/*
 * wavelet compressor - designed to take
 * 2-D and 3-D datasets and perform
 * lossy wavelet transforms that result
 * in high compression
 * 
 * chris fleizach - chris@fleizach.com
 */

#include <iostream>
#include <string>
using namespace std;

#include "DataGrid.h"
#include "DataGrid1D.h"
#include "DataGrid2D.h"
#include "DataGrid3D.h"
#include "Wavelet.h"
#include "WaveletHigh.h"
#include "WaveletMedium.h"
#include "WaveletLow.h"
#include "Output.h"
#include "OutputDecompressor.h"
#include "RemoteProcessor.h"
#include "Common.h"

extern bool verbose;

void usage() {
	cout << "Usage: wavedec source " << endl;
	cout << "Options: " << endl;
	cout << "\t-v	verbose" << endl;
	cout << endl;
	exit(0);
}

DataGrid * loadData(string filename) {
	DataGrid * data = NULL;
	
	int dimension = DataGrid::determineDimension(filename);
	
	if (verbose) cout << "Data Dimension: " << dimension << endl;
	
	switch(dimension) {
		case 1:
			data = new DataGrid1D(filename,DECOMPRESS);
			break;
		case 2:
			data = new DataGrid2D(filename,DECOMPRESS);
			break;
		case 3:
			data = new DataGrid3D(filename,DECOMPRESS);	
			break;	
	}
	
	return data;
}

void waveletInverseTransform(DataGrid * data, int mode) {
	Wavelet * wave = NULL;
	
	switch(mode) {
		case WAVELET_HIGH:
			wave = new WaveletHigh(0);
			break;	
		case WAVELET_MED:
			wave = new WaveletMedium(0);
			break;
		case WAVELET_LOW:
			wave = new WaveletLow(0);
			break;
		default:
			cout << "Can't find compression mode... exiting " << endl;
			exit(0);
			break;
	}	
	
	wave->inverseTransform(data);
}

void output(DataGrid * data, string filename, int mode) {
	Output * decompress = new OutputDecompressor(data,filename);
	decompress->write();	

}

int main(int argc, char * argv[]) {
	
	string filename;
	int mode;
	verbose = false;
	
	if (argc < 2) { 
		usage();	
	}
	
	int j = 1;
	while (j < argc-1) {
		if (strcmp("-v",argv[j]) == 0) {
			verbose = true;
		}
		j++;
	}
	
	if (j >= argc) { 
		usage();
	}
		
	filename = argv[j];

	
	cout << "Wavelet de-compressor started with file: " << filename << endl;
	
	DataGrid * data = loadData(filename);
	waveletInverseTransform(data,data->getMode());
	output(data,filename,mode);

	return 0;	
}
