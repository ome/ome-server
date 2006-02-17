#include <stdio.h>
#include <string.h>

#include "mex.h"
#include "matrix.h"

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
	int dims[5]; dims[0] = head->dx; dims[1] = head->dy;
		dims[2] = head->dz; dims[3] = head->dc; dims[4] = head->dt;
		
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
	int tmp_dims[2] = {1,1};
	plhs[0] = mxCreateNumericArray (2, tmp_dims, OMEIStoMATLABDatatype(head), mxREAL);
	
	mxSetData (plhs[0], pixels);
	mxSetDimensions (plhs[0], dims, 5);
	
	/* clean up */
	mxFree(url);
	mxFree(sessionkey);
	mxFree(head);
	mxFree(is);
}
