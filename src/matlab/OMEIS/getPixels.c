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

	if (nrhs != 2)
		mexErrMsgTxt("\n [pixels] = getPixels (is, ID)");
		
	if (!mxIsStruct(prhs[0]))
		mexErrMsgTxt("getPixels requires the first input to be the struct outputed"
					 " from openConnectionOMEIS\n");
					 
	if (!(m_url = mxGetField(prhs[0], 0, "url")))
		mexErrMsgTxt("getPixels requires the first input, OMEIS struct, to have field: url");
	if (!(m_sessionkey = mxGetField(prhs[0], 0, "sessionkey")))
		mexErrMsgTxt("getPixels requires the first input, OMEIS struct, to have field: sessionkey");
		
	if (!mxIsChar(m_url) || !mxIsChar(m_sessionkey))
		mexErrMsgTxt("OMEIS field aren't character array.\n");		
	
	if (!mxIsNumeric(prhs[1]))
		mexErrMsgTxt("getPixels requires the second input to be the PixelsID\n") ;
		
	ID = (OID) mxGetScalar(prhs[1]) ;
	
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
	
	/* figure out dimensions */
	mwSize dims[5]; dims[0] = (mwSize) head->dx; dims[1] = (mwSize) head->dy;
		dims[2] = (mwSize) head->dz; dims[3] = (mwSize) head->dc; dims[4] = (mwSize) head->dt;
		
	if (!(pixels = getPixels (is, ID))) {
		/* clean up */
		mxFree(url);
		mxFree(sessionkey);
		mxFree(head);
		mxFree(is);
		
		char err_str[128];
		sprintf(err_str, "Couldn't load pixelsID %llu\n", ID);
		mexErrMsgTxt(err_str);
	}
	
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
	
	/* If the flip failed write a message, we are doing it after cleanup */
	if (result) {
		char err_str[128];
		sprintf(err_str, "Couldn't permute the pixels to get them in MATLAB orientation");
		mexErrMsgTxt(err_str);
	}
}
