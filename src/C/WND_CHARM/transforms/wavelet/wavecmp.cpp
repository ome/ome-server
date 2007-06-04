/*
 * wavelet compressor - designed to take
 * 2-D and 3-D datasets and perform
 * lossy wavelet transforms that result
 * in high compression
 * 
 * main file
 * 
 * chris fleizach - chris@fleizach.com
 */


#include <iostream>
#include <string>
using namespace std;

#include "DataGrid.h"
#include "DataGrid3D.h"
#include "DataGrid2D.h"
#include "DataGrid1D.h"
#include "Wavelet.h"
#include "WaveletHigh.h"
#include "WaveletMedium.h"
#include "WaveletLow.h"
#include "Output.h" 
#include "OutputCompressor.h"
#include "Common.h"

double limit = -1;

void usage() {
	cout << "Usage: wavecomp [options] source " << endl;
	cout << "Options: " << endl;
	cout << "\t-c		compression mode (1=high compress/high error, 2=medium/low, 3=low/low)" << endl;
	cout << "\t-d <D>		dimension of data (<D>= 1, 2, 3)" << endl;
	cout << "\t-l <lim>	zero limit (ex: .0001 removes all abs(values) < .0001)" << endl;
	cout << "\t-p -m -s <IP> <IP>	3-Node parallel mode where this machine is master and 2 slaves are <IP> <IP>" << endl;
	cout << "\t-p -s		Parallel mode where this machine is a slave" << endl;
	cout << "\t-v		verbose" << endl;
	cout << "\t-i		data format instructions" << endl;
	cout << endl;
	exit(0);
}

void instructions() {
	cout << "wavecomp Data Format" << endl;
	
	cout << "The data must indicate the size of the data with the " <<
	"values. \nFor 1D data, the first double must be the size. \nSimilarly " <<
	"for 2D data, the first two doubles must be the size. \nThe rest of " <<
 	"the data must be composed of that many number of doubles" << endl;
	
	exit(0);
}

DataGrid * loadData(string filename, int dimension) {
	
	DataGrid * data = NULL;
	
	switch(dimension) {
		case 1:
			data = new DataGrid1D(filename,COMPRESS);
			break;
		case 2:
			data = new DataGrid2D(filename,COMPRESS);
			break;
		case 3:
			data = new DataGrid3D(filename,COMPRESS);	
			break;	
	}
	
	//data->output();
	return data;
}

void waveletTransform(DataGrid * data, int mode) {
	Wavelet * wave = NULL;
	
	switch(mode) {
		case WAVELET_HIGH:
			wave = new WaveletHigh(limit);
			data->setMode(WAVELET_HIGH);
			break;	
		case WAVELET_MED:
			wave = new WaveletMedium(limit);
			data->setMode(WAVELET_MED);
			break;
		case WAVELET_LOW:
		default:
			wave = new WaveletLow(limit);
			data->setMode(WAVELET_LOW);
			break;
	}	
	
	wave->transform(data);
}

double output(DataGrid * data, string filename, int mode) {

	Output * compress = new OutputCompressor(data,filename,mode);
	compress->write();	
	double ratio = compress->getStats();
	return ratio;
}

int main(int argc, char * argv[]) {
	
	string filename;
	int mode = 1;
	int dimension = 0;
	string ip;
	
	if (argc < 2) { 
		usage();	
	}
	
	int j = 1;
	while (j < argc-1) {
		if (strcmp ("-c", argv [j]) == 0) {
			j++;
			if (j >= argc)
				usage ();
			mode = atoi (argv [j]);
		}
		else if (strcmp ("-d", argv [j]) == 0) {
			j++;
			if (j >= argc)
				usage ();
			dimension = atoi (argv [j]);
		}
		else if (strcmp ("-l", argv [j]) == 0) {
			j++;
			if (j >= argc)
				usage ();
			limit = atof (argv [j]);
		}
		else if (strcmp("-v",argv[j]) == 0) {
			verbose = true;
		}
		else if (strcmp("-i",argv[j]) == 0) {
			instructions();
		}
		else if (strcmp("-p",argv[j]) == 0) {
			parallel = true;
			j++;
			if (j >= argc) usage ();
			if (strcmp("-m",argv[j]) == 0) {
				master = true;
				j++;
				if (j >= argc) usage();
				if (strcmp("-s",argv[j]) == 0) {
					j++;
					if (j >= argc) usage();
					slave1 = argv[j];
					j++;
					if (j >= argc) usage();
					slave2 = argv[j];
				}
				else {
					usage();	
				}
			}
			else if (strcmp("-s",argv[j]) == 0) {
				master = false;	
			}
			else {
				usage();	
			}
		}
		j++;
	}
	
	// only care about the dimension and file if this
	// is the master
	if ((j >= argc || dimension == 0) && master == true) {
		usage();
	}
	else if (master) {	
		filename = argv[j];
	}
	
	if (parallel && !master) {
		cout << "Wavelet compressor started in SLAVE mode. " << endl;
		cout << "Awaiting connections... " << endl;	
		RemoteProcessor * remote = new RemoteProcessor();
		remote->awaitCommand();
	}
	else {
		cout << "Wavelet " << dimension << "D compressor started with file: " 
			<< filename << " in mode = " << mode << endl << endl;	
	}
	
	if (parallel && master) {
		cout << "Parallel mode enabled ";
		cout << " in MASTER mode with " << slave1 << " and " << slave2 << " as SLAVEs "<< endl;	
	}
	
	DataGrid * data = loadData(filename,dimension);;
	waveletTransform(data,mode);
	double ratio = output(data,filename,mode);

	cout << "Compression Ratio: " << ratio << endl;

	return 0;	
}
