#include <stdio.h>
#include <string.h>

#include "mex.h"
#include "matrix.h"

#include "httpOMEIS.h"
#include "httpOMEISaux.h"

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
	
	if (nrhs != 12)
		mexErrMsgTxt("\n [pixels] = getPixels (is, ID, x0, y0, z0, c0, t0, x1, y1, z1, c1, t1)");
		
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
	
	/* get ROI */
	int x0 = (int) mxGetScalar(prhs[2]);
	int y0 = (int) mxGetScalar(prhs[3]);
	int z0 = (int) mxGetScalar(prhs[4]);
	int c0 = (int) mxGetScalar(prhs[5]);
	int t0 = (int) mxGetScalar(prhs[6]);
	int x1 = (int) mxGetScalar(prhs[7]);
	int y1 = (int) mxGetScalar(prhs[8]);
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
	int dims[5];
	dims[0] = x1-x0+1;
	dims[1] = y1-y0+1;
	dims[2] = z1-z0+1;
	dims[3] = c1-c0+1;
	dims[4] = t1-t0+1;

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
