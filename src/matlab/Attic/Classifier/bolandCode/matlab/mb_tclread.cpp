//////////////////////////////////////////////////////////////////////////
//
//
//                            mb_tclread.cpp 
//
//
//                           Michael Boland
//                            04 July 1998
//
//  Revisions:
//
//////////////////////////////////////////////////////////////////////////



#include "mex.h"
#include "matrix.h"
#include <math.h>
#include <iostream.h>
#include <fstream.h>
#include <stdlib.h>
#include <sys/types.h>

struct TCLheader {
  u_int16_t bytesPPixe;                 // length:   2; byte: 000-001 
  u_int16_t imageWidth;                 // length:   2; byte: 002-003
  u_int16_t imageHeight;                // length:   2; byte: 004-005
  u_int16_t seqNumber;                  // length:   2; byte: 006-007
  u_int16_t bitsPPixel;                 // length:   2; byte: 008-009
  u_int16_t reserved[27];               // length:  54; byte: 010-063
  u_int8_t  userData[192];              // length: 192; byte: 064-255
  u_int8_t  userText[152];              // length: 152; byte: 256-407
  u_int8_t  date[30];                   // length:  30; byte: 408-437
  u_int8_t  descText[74];               // length:  74; byte: 438-511
} ;

//
// void mb_swab() - swap n bytes in from and place in to.
//
void mb_swab(const char *from, char *to, size_t n)
{
  register int index ; 

  for (index=0; index < n; index += 2)
  {
    *(to+index+1) = *(from+index);
    *(to+index)   = *(from+index+1);
  }

  return;
}


void mexFunction(
		 int nlhs,
		 mxArray *plhs[], 
		 int nrhs,
		 const mxArray *prhs[])
{
    ifstream tclfile ;       // input TCL file
    TCLheader tclheader ;    // TCL header with proper byte order
    TCLheader swapheader ;   // TCL header with ?? byte order
    int swapbytes = 0 ;      // Do bytes need to be swapped?
    char* buf ;              // buffer for string value
    int buflen ;             // Lentgh of string buffer
    int status ;             // Storage for return values
    double* output ;         // Return value to Matlab
    int imgsize[2] ;         // Array of the image dimensions (row,col)
    int imgindex[2] ;        // Indices for traversing the image (row,col)
    int offset ;             // Offset for traversing the image array ;

    if (nrhs != 1) {
      mexErrMsgTxt("mb_tclread() requires a single input argument.") ;
    } else if (nlhs != 1) {
      mexErrMsgTxt("mb_tclread() returns a single output.") ;
    }

    if (!mxIsChar(prhs[0])) {
      mexErrMsgTxt("The argument to mb_tclread() should be a string.") ;
    }

    buflen = (mxGetM(prhs[0]) * mxGetN(prhs[0]) * sizeof(mxChar)) + 1 ;
    buf    = (char *)mxCalloc(buflen, sizeof(char)) ;
    if (buf == NULL)
      mexErrMsgTxt("Failure to allocate memory for string mxGetString.") ;
    status = mxGetString(prhs[0], buf, buflen) ;
    if (status == 0)
      mexPrintf("Input File: %s\n", buf) ;
    else
      mexErrMsgTxt("String conversion unsuccessful.") ;

    tclfile.open(buf,ios::in) ;
    if (!tclfile.good()) {
      mexErrMsgTxt("Invalid input file.") ;
    }


    if (! tclfile.read((char*) &swapheader, sizeof(TCLheader)) ) {
      mexErrMsgTxt("Cannot read the header from the input file.");
    }
    
    //
    // The only valid value for bitsPPixel is 16
    // 
    if (swapheader.bitsPPixel != 16) swapbytes=1 ;
    
    if (swapbytes) {
      mb_swab((char *)&swapheader, (char *)&tclheader, sizeof(TCLheader)) ;
      
      if (tclheader.bitsPPixel != 16) {
	mexErrMsgTxt("This program can only handle 16 bit/pixel images.") ;
      }
    } else tclheader = swapheader ;
    
    u_int16_t * pixels = 
      new u_int16_t[tclheader.imageWidth*tclheader.imageHeight] ;
    
    // 
    // Read in pixel values, swap if necessary
    //
    if (swapbytes) {
      u_int16_t * swappixels = 
	new u_int16_t[tclheader.imageWidth*tclheader.imageHeight] ;
      if (! tclfile.read((char*) swappixels, 
			 sizeof(short)*tclheader.imageWidth 
			 * tclheader.imageHeight) ) {
	mexErrMsgTxt("Error reading the input file data.") ;
      }
      mb_swab((char *)swappixels, (char *)pixels, 
	      (sizeof(u_int16_t)*tclheader.imageWidth 
	       * tclheader.imageHeight)) ;
      delete [] swappixels ;
    } else {
      if (! tclfile.read((char*) pixels, sizeof(u_int16_t) * 
			 tclheader.imageWidth*tclheader.imageHeight) ) {
	mexErrMsgTxt("Error reading the input file data.") ;
      }
    }

    //
    // Place the pixel values into the returned array
    //
    imgsize[1] = tclheader.imageWidth ;
    imgsize[0] = tclheader.imageHeight ;
    plhs[0] = mxCreateNumericArray(2, imgsize, mxDOUBLE_CLASS, mxREAL) ;
    output = mxGetPr(plhs[0]) ;

    for(imgindex[0] = 0 ; imgindex[0] < imgsize[0] ; imgindex[0]++) 
      for(imgindex[1] = 0 ; imgindex[1] < imgsize[1] ; imgindex[1]++ ) {
	offset = mxCalcSingleSubscript(plhs[0], 2, imgindex) ;
	output[offset] = (double)pixels[imgindex[0]*imgsize[1]+imgindex[1]] ;
      }

    return ;
}

