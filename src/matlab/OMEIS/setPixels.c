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
	
	/* MATLAB data structueres */
	mxArray *m_url, *m_sessionkey;
	
	char* url, *sessionkey;
	
	if (nrhs != 3)
		mexErrMsgTxt("\n [pix] = setPixels (is, ID, pixels)");
		
	if (!mxIsStruct(prhs[0]))
		mexErrMsgTxt("settPixels requires the first input to be the struct outputed"
					 " from openConnectionOMEIS\n");
					 
	if (!(m_url = mxGetField(prhs[0], 0, "url")))
		mexErrMsgTxt("setPixels requires the first input, OMEIS struct, to have field: url");
	if (!(m_sessionkey = mxGetField(prhs[0], 0, "sessionkey")))
		mexErrMsgTxt("setPixels requires the first input, OMEIS struct, to have field: sessionkey");
		
	if (!mxIsChar(m_url) || !mxIsChar(m_sessionkey))
		mexErrMsgTxt("OMEIS field aren't character array.\n");		
	
	if (!mxIsNumeric(prhs[1]))
		mexErrMsgTxt("setPixels requires the second input to be the PixelsID\n") ;
		
	ID = (OID) mxGetScalar(prhs[1]) ;
	
	url = mxArrayToString(m_url);
	sessionkey = mxArrayToString(m_sessionkey);

	is = openConnectionOMEIS (url, sessionkey);
	
	if (!(head = pixelsInfo (is, ID))){
		char err_str[128];
		sprintf(err_str, "PixelsID %llu or OMEIS URL '%s' is probably wrong\n", ID, is->url);		
		
		/* clean up */
		mxFree(url);
		mxFree(sessionkey);
		mxFree(is);
		
		mexErrMsgTxt(err_str);
	}
	
	/* check dimension and class check */
	const int* dims = mxGetDimensions (prhs[2]);
	switch (mxGetNumberOfDimensions (prhs[2])) {
		case 5:
			if (head->dt != dims[4])
				mexErrMsgTxt("5th Dimension of input array and Pixels doesn't match.\n");
		case 4:
			if (head->dc != dims[3])
				mexErrMsgTxt("4th Dimension of input array and Pixels doesn't match.\n");
		case 3:
			if (head->dz != dims[2])
				mexErrMsgTxt("3th Dimension of input array and Pixels doesn't match.\n");
		case 2:
			if (head->dy != dims[1])
				mexErrMsgTxt("2nd Dimension of input array and Pixels doesn't match.\n");
		case 1:
			if (head->dx != dims[0])
				mexErrMsgTxt("1st Dimension of input array and Pixels doesn't match.\n");
			break;
		default:
			mexErrMsgTxt("Input Array must be 5D or less");
		break;
	}
	
	pixHeader tmp_head;
	CtoOMEISDatatype ((char*) mxGetClassName(prhs[2]), &tmp_head);
	
	if ( (tmp_head.bp       != head->bp)       ||
		 (tmp_head.isSigned != head->isSigned) ||
		 (tmp_head.isFloat  != head->isFloat) ) {
		 
		/* clean up */
		mxFree(url);
		mxFree(sessionkey);
		mxFree(head);
		mxFree(is);
				 
		mexErrMsgTxt("Types of input array and Pixels don't match\n");
	}
	
	/* set the pixels */
	int pix = setPixels (is, ID, mxGetPr(prhs[2]));
	
	/* record number of pixels written */
	plhs[0] = mxCreateScalarDouble((double) pix);
	
	/* clean up */
	mxFree(url);
	mxFree(sessionkey);
	mxFree(head);
	mxFree(is);
}