#include <stdio.h>
#include <string.h>

#include "mex.h"
#include "matrix.h"
#include "ome-Matlab.h" /* backwards compatiblity to mwSize/mwIndex */

#include "httpOMEIS.h"
#include "httpOMEISaux.h"
#include "httpOMEISaux-MATLAB.h" /* for OMEIStoMATLABDatatype */

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	OID ID;
	
	/* OMEIS data structures */
	omeis* is;
	pixHeader* head;
	void* pixels;
	
	/* MATLAB data structueres */
	mxArray *m_url, *m_sessionkey;
	mxArray *permute_inputs[2];
	int result;
	
	char* url, *sessionkey;
	
	if (nrhs != 12)
		mexErrMsgTxt("\n [pixels] = getROI (is, ID, row0 (OME:y0), column0 (OME:x0), z0, c0, t0, row1 (OME:y1), column1 (OME:x1), z1, c1, t1)");
		
	if (!mxIsStruct(prhs[0]))
		mexErrMsgTxt("getROI requires the first input to be the struct outputed"
					 " from openConnectionOMEIS\n");
					 
	if (!(m_url = mxGetField(prhs[0], 0, "url")))
		mexErrMsgTxt("getROI requires the first input, OMEIS struct, to have field: url");
	if (!(m_sessionkey = mxGetField(prhs[0], 0, "sessionkey")))
		mexErrMsgTxt("getROI requires the first input, OMEIS struct, to have field: sessionkey");
		
	if (!mxIsChar(m_url) || !mxIsChar(m_sessionkey))
		mexErrMsgTxt("OMEIS field aren't character array.\n");		
	
	if (!mxIsNumeric(prhs[1]))
		mexErrMsgTxt("getROI requires the second input to be the PixelsID\n") ;
		
	ID = (OID) mxGetScalar(prhs[1]) ;
	
	/* get ROI */
	/* NB x0/y0 and x1/y1 are switched on purpose because of the different orientations
	 used in MATLAB and OME. See note below */
	int y0 = (int) mxGetScalar(prhs[2]); /* switched */
	int x0 = (int) mxGetScalar(prhs[3]); /* switched */
	int z0 = (int) mxGetScalar(prhs[4]);
	int c0 = (int) mxGetScalar(prhs[5]);
	int t0 = (int) mxGetScalar(prhs[6]);
	int y1 = (int) mxGetScalar(prhs[7]); /* switched */ 
	int x1 = (int) mxGetScalar(prhs[8]); /* switched */
	int z1 = (int) mxGetScalar(prhs[9]);
	int c1 = (int) mxGetScalar(prhs[10]);
	int t1 = (int) mxGetScalar(prhs[11]);

	url = mxArrayToString(m_url);
	sessionkey = mxArrayToString(m_sessionkey);
	
	is = openConnectionOMEIS (url, sessionkey);
	if (!(head = pixelsInfo (is, ID))) {
		char err_str[128];
		sprintf(err_str, "PixelsID %llu or OMEIS URL '%s' is probably wrong\n", ID, is->url);
		
		/* clean up */
		mxFree(url);
		mxFree(sessionkey);
		mxFree(is);
		
		mexErrMsgTxt(err_str);
	}
	
	if (!(pixels = getROI (is, ID, x0, y0, z0, c0, t0, x1, y1, z1, c1, t1))) {
		/* clean up */
		mxFree(url);
		mxFree(sessionkey);
		mxFree(head);
		mxFree(is);
		
		char err_str[128];
		sprintf(err_str, "Couldn't load ROI from pixelsID %llu. ROI dims are probably wrong.\n", ID);
		mexErrMsgTxt(err_str);
	}
	
	/* convert ROI to dims */
	mwSize dims[5];
	dims[0] = (mwSize) (x1-x0+1);
	dims[1] = (mwSize) (y1-y0+1);
	dims[2] = (mwSize) (z1-z0+1);
	dims[3] = (mwSize) (c1-c0+1);
	dims[4] = (mwSize) (t1-t0+1);
	
	/* attach pixels from OMEIS to MATLAB array */
	mwSize tmp_dims[2] = {1,1};
	plhs[0] = mxCreateNumericArray (2, tmp_dims, OMEIStoMATLABDatatype(head), mxREAL);
	
	mxSetData (plhs[0], pixels);
	mxSetDimensions (plhs[0], dims, 5);
	
	/*
		In OMEIS Size_X corresponds to columns and Size_Y corresponds to rows.
		This is diametrically opposite to MATLAB's assumptions.
		hence we do
		"$matlab_var_name = permute($matlab_var_name, [2 1 3 4 5]);" 
		the hard way (groan)
	*/
	permute_inputs[0] = plhs[0];
	permute_inputs[1] = mxCreateDoubleMatrix(1, 5, mxREAL);
	mxGetPr(permute_inputs[1])[0] = 2;
	mxGetPr(permute_inputs[1])[1] = 1;
	mxGetPr(permute_inputs[1])[2] = 3;
	mxGetPr(permute_inputs[1])[3] = 4;
	mxGetPr(permute_inputs[1])[4] = 5;
	/* returns 0 if successful */
	result = mexCallMATLAB(1, plhs, 2, permute_inputs, "permute"); 
	
	/* clean up */
	mxFree(url);
	mxFree(sessionkey);
	mxFree(head);
	mxFree(is);
	mxDestroyArray(permute_inputs[1]);
	
	if (result) {
		char err_str[128];
		sprintf(err_str, "Couldn't permute the pixels to get them in MATLAB orientation");
		mexErrMsgTxt(err_str);
	}
}
