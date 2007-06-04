#include "DataGrid.h"
#include "Common.h"
#include <fstream>
#include <iostream>
using namespace std;


int DataGrid::determineDimension(const string & filename) {
	
	int dimension;
	
	ifstream input(filename.c_str(), ios::in | ios::binary);
	input.seekg(0);
	input.read((char*)&dimension, sizeof (int));
	input.close();
	
	if (dimension <= 0 || dimension > 3) {
		cout << "The dimension of the data is incorrect: " << dimension << 
		". The program cannot continue " << endl;
		exit(0);
	}
		
	return dimension;

}

