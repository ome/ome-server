#include "CompressionUtils.h"
#include "DataGrid.h"
#include "Common.h"
#include <bzlib.h>
#include <zlib.h>
#include <iostream>
#include <fstream>
using namespace std;

double CompressionUtils::deflate(ofstream & output, double * outarray, int size) {
	
	//return none(output,outarray,size);
	return zip(output,outarray,size);
	//return bZip(output,outarray,size);
}

double * CompressionUtils::inflate(DataGrid * data, ifstream & input) {
	//return unnone(data,input);
	return unzip(data,input);
	//return bUnzip(data,input);
}


double CompressionUtils::none(ofstream & output, double * outarray, int size) {

	if (verbose) cout << "Not Compressing data  " << endl;	
	double compratio = 1;
	
	for (int k = 0; k < size; k++) {
		output.write((char*)&(outarray[k]), sizeof (double));
	}
	
	output.close();
	
	return (double)size;
}

double * CompressionUtils::unnone(DataGrid * data, ifstream & input) {
	
	
	unsigned int destsize = (int)data->getX();
	
	if (data->getDimension() > 1) {
		destsize *= (int) data->getY();
		if (data->getDimension() > 2) {
			destsize *= (int) data->getZ();
		}
	}
	
	double * dest = new double[destsize];
	int k;
	
	for (k = 0; !input.eof(); k++) {
		input.read((char*)&(dest[k]), sizeof (double));	
	}
	input.close();
	
	return (double*)dest;
}

double CompressionUtils::zip(ofstream & output, double * outarray, int size) {

	if (verbose) cout << "Compressing data using Gzip method " << endl;	
	double compratio = 1;
	
	int cdiff = sizeof(double)/sizeof(Bytef);
	
	// if we don't take any zeros, the compresssed sized will actually
	// be bigger
	unsigned int destsize = size*cdiff*2;
	
	Bytef * dest = new Bytef[destsize];
		
	int status = compress2 ( dest, (uLongf*) &destsize, 
		(const Bytef*) outarray, (uLong) size*cdiff, 9);
                
	if (status == Z_OK) {
		if (verbose) cout << "Compressed data: old length: " << cdiff*size << " new length: " << destsize 
			<< endl;	
		compratio = (double)(cdiff*size+sizeof(double)*3)/(double)destsize;
	}
	else {
		cout << "zip compression failed" << status << endl;	
	}

	for (int k = 0; k < destsize; k++) {
		output.write((const char *) &(dest[k]), sizeof (Bytef));
	}
	
	//output.write((char*)outarray, destsize*sizeof (double));
	output.close();
	
	return destsize;
}

double * CompressionUtils::unzip(DataGrid * data, ifstream & input) {
	
	int cdiff = sizeof(double)/sizeof(Bytef);
	
	unsigned int destsize = (int)data->getX() * cdiff * 2 ;
	
	if (data->getDimension() > 1) {
		destsize *= (int) data->getY();
		if (data->getDimension() > 2) {
			destsize *= (int) data->getZ();
		}
	}
	
	char * dest = new char[destsize];
	char * source = new char[destsize];
	
	int k;
	
	for (k = 0; !input.eof(); k++) {
		input.read((char*)&(source[k]), sizeof (char));	
	}
	input.close();
	
	
	int status = uncompress( (Bytef*) dest,(uLongf*)&destsize,
		(const Bytef*) source,k);
 
	if (status == Z_OK) {
		if (verbose) cout << "Data decompresssion succeeded: dest size = " << destsize << endl;	
	}
	else {
		cout << "bzip DEcompression failed" << " in size: " << k << " out size: " << destsize << " -> " << status << endl;	
	
		cout << Z_STREAM_END << endl;
		cout << Z_NEED_DICT << endl;
		cout << Z_ERRNO << endl;
		cout << Z_STREAM_ERROR << endl;
		cout << Z_DATA_ERROR << endl;	
		cout << Z_MEM_ERROR << endl;
		cout << Z_BUF_ERROR << endl;		
	}
	
	
	return (double*)dest;
}

double * CompressionUtils::bUnzip(DataGrid * data, ifstream & input) {
	
	int cdiff = sizeof(double)/sizeof(char);
	
	unsigned int destsize = (int)data->getX() * cdiff *2 ;
	
	if (data->getDimension() == 2) {
		destsize *= (int) data->getY();
	}
	if (data->getDimension() == 3) {
		destsize *= (int) data->getZ();
	}
			
	char * dest = new char[destsize];
	char * source = new char[destsize];
	
	int k;
	
	for (k = 0; !input.eof(); k++) {
		input.read((char*)&(source[k]), sizeof (char));	
	}	
	input.close();
	
	
	int status = BZ2_bzBuffToBuffDecompress( (char*) dest,&destsize,
		(char*) source,k,1,0);
 
                              
	if (status == BZ_OK) {
		if (verbose) cout << "Data decompresssion succeeded: dest size = " << destsize << endl;	
	}
	else {
		cout << "bzip DEcompression failed" << " in size: " << k << " out size: " << destsize << " -> " << status << endl;	
		cout << BZ_CONFIG_ERROR << endl;
		cout << BZ_PARAM_ERROR << endl;
		cout << BZ_MEM_ERROR << endl;
		cout << BZ_OUTBUFF_FULL << endl;
		cout << BZ_DATA_ERROR << endl;	
		cout << BZ_DATA_ERROR_MAGIC << endl;
		cout << BZ_UNEXPECTED_EOF << endl;		
	}
	
	
	return (double*)destsize;

}

double CompressionUtils::bZip(ofstream & output, double * outarray, int size) {
	
	if (verbose) cout << "Compressing data using Bzip method " << endl;	
	
	double compratio = 1;
	int compresslevel = 9;
	int cdiff = sizeof(double)/sizeof(char);
	
	// if we don't take any zeros, the compresssed sized will actually
	// be bigger
	unsigned int destsize = size*cdiff*2;
	
	char * dest = new char[destsize];
	
	int status = BZ2_bzBuffToBuffCompress( dest,
		&destsize, (char*)outarray,size*cdiff,
		compresslevel, 0, 30);
            
	if (status == BZ_OK) {
		if (verbose)  cout << "compresssion succeeded: old length: " << cdiff*size << " new length: " << destsize 
			<< endl;	
		compratio = (double)(cdiff*size+sizeof(double)*3)/(double)destsize;
	}
	else {
		cout << "bzip compression failed" << status << endl;	
	}
	
	output.write((char*)outarray, size*sizeof (double));
	output.close();
	
	return compratio;
}
