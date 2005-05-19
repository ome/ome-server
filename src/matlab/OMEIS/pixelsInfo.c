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
	
	/* MATLAB data structueres */
	mxArray *m_url, *m_sessionkey;
	char* url, *sessionkey;
	
	if (nrhs != 2)
		mexErrMsgTxt("\n [ph] = pixelsInfo (is, ID)");
		
	if (!mxIsStruct(prhs[0]))
		mexErrMsgTxt("pixelsInfo requires the first input to be the struct outputed"
					 " from openConnectionOMEIS\n");

	if (!(m_url = mxGetField(prhs[0], 0, "url")))
		mexErrMsgTxt("newPixels requires the first input, OMEIS struct, to have field: url");
	if (!(m_sessionkey = mxGetField(prhs[0], 0, "sessionkey")))
		mexErrMsgTxt("newPixels requires the first input, OMEIS struct, to have field: sessionkey");
	
	if (!mxIsChar(m_url) || !mxIsChar(m_sessionkey))
		mexErrMsgTxt("OMEIS field aren't character array.\n");		
	
	if (!mxIsNumeric(prhs[1]))
		mexErrMsgTxt("pixelsInfo requires the second input to be the PixelsID\n") ;
		
	ID = (OID) mxGetScalar(prhs[1]) ;
	
	url = mxArrayToString(m_url);
	sessionkey = mxArrayToString(m_sessionkey);
	
	is = openConnectionOMEIS (url, sessionkey);
	if (!(head = pixelsInfo (is, ID))){
		char err_str[128];
		sprintf(err_str, "PixelsID %llu or OMEIS URL '%s' is probably wrong\n", ID, is->url);
		mexErrMsgTxt(err_str);
	}
	
	int dims[2] = {1,1};
	const char *field_names[] = {"dx", "dy", "dz", "dc", "dt", "bp", "isFloat", "isSigned", "isFinished", "sha1"};	
	plhs[0] = mxCreateStructArray (2, dims, 10, field_names);

	mxSetField(plhs[0],0, "dx", mxCreateDoubleScalar((double) head->dx));
	mxSetField(plhs[0],0, "dy", mxCreateDoubleScalar((double) head->dy));
	mxSetField(plhs[0],0, "dz", mxCreateDoubleScalar((double) head->dz));
	mxSetField(plhs[0],0, "dc", mxCreateDoubleScalar((double) head->dc));
	mxSetField(plhs[0],0, "dt", mxCreateDoubleScalar((double) head->dt));
	mxSetField(plhs[0],0, "bp", mxCreateDoubleScalar((double) head->bp));
	mxSetField(plhs[0],0, "isFloat",    mxCreateDoubleScalar((double) head->isFloat));
	mxSetField(plhs[0],0, "isSigned",   mxCreateDoubleScalar((double) head->isSigned));
	mxSetField(plhs[0],0, "isFinished", mxCreateDoubleScalar((double) head->isFinished));
	mxSetField(plhs[0],0, "sha1", mxCreateString((char*) head->sha1));
	
	mxFree(url);
	mxFree(sessionkey);
	mxFree(head);
	mxFree(is);
}