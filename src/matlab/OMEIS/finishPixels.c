#include "mex.h"
#include "matrix.h"

#include "httpOMEIS.h"
#include "httpOMEISaux.h"


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	OID ID;
	/* OMEIS data structures */
	omeis* is;
	
	/* MATLAB data structueres */
	mxArray *m_url, *m_sessionkey;
	char* url, *sessionkey;
	
	if (nrhs != 2)
		mexErrMsgTxt("\n [newID] = finishPixels (is, ID)");
		
	if (!mxIsStruct(prhs[0]))
		mexErrMsgTxt("finishPixels requires the first input to be the struct outputed"
					 " from openConnectionOMEIS\n");

	if (!(m_url = mxGetField(prhs[0], 0, "url")))
		mexErrMsgTxt("finishPixels requires the first input, OMEIS struct, to have field: url");
	if (!(m_sessionkey = mxGetField(prhs[0], 0, "sessionkey")))
		mexErrMsgTxt("finishPixels requires the first input, OMEIS struct, to have field: sessionkey");
	
	if (!mxIsChar(m_url) || !mxIsChar(m_sessionkey))
		mexErrMsgTxt("OMEIS field aren't character array.\n");		
	
	if (!mxIsNumeric(prhs[1]))
		mexErrMsgTxt("finishPixels requires the second input to be the PixelsID\n") ;
		
	ID = (OID) mxGetScalar(prhs[1]) ;
	
	url = mxArrayToString(m_url);
	sessionkey = mxArrayToString(m_sessionkey);
	
	is = openConnectionOMEIS (url, sessionkey);
	
	if (!(ID = finishPixels (is, ID))) {
		mexErrMsgTxt("finishPixels OMEIS method failed.\n");
	}
	
	plhs[0] = mxCreateScalarDouble((double) ID);
	
	mxFree(url);
	mxFree(sessionkey);
	mxFree(is);
}