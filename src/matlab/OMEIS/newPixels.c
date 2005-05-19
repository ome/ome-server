#include "mex.h"
#include "matrix.h"

#include "httpOMEIS.h"
#include "httpOMEISaux.h"


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	OID ID;
	
	/* OMEIS data structures */
	omeis* is;
	pixHeader* head = (pixHeader*) mxMalloc(sizeof(head));
	
	/* MATLAB data structueres */
	mxArray *m_dx, *m_dy, *m_dz, *m_dc, *m_dt, *m_bp, *m_isSigned, *m_isFloat;
	mxArray *m_url, *m_sessionkey;
	
	char* url, *sessionkey;
	
	if (nrhs != 2)
		mexErrMsgTxt("\n [ID] = newPixels (is, ph)");
		
	if (!mxIsStruct(prhs[0]))
		mexErrMsgTxt("newPixels requires the first input to be the struct outputed"
					 " from openConnectionOMEIS\n");
					 
	if (!(m_url = mxGetField(prhs[0], 0, "url")))
		mexErrMsgTxt("newPixels requires the first input, OMEIS struct, to have field: url");
	if (!(m_sessionkey = mxGetField(prhs[0], 0, "sessionkey")))
		mexErrMsgTxt("newPixels requires the first input, OMEIS struct, to have field: sessionkey");
		
	if (!mxIsChar(m_url) || !mxIsChar(m_sessionkey))
		mexErrMsgTxt("OMEIS field aren't character array.\n");		
	
	if (!mxIsStruct(prhs[0]))
		mexErrMsgTxt("newPixels requires the first input to be the struct outputed"
					 " from openConnectionOMEIS\n");
					 
	if (!mxIsStruct(prhs[1]))
		mexErrMsgTxt("newPixels requires the second input to be a pixHeader struct.");
		
	if (!(m_dx = mxGetField(prhs[1], 0, "dx")))
		mexErrMsgTxt("newPixels requires the second input, pixHeader struct, to have field: dx");
	if (!(m_dy = mxGetField(prhs[1], 0, "dy")))
			mexErrMsgTxt("newPixels requires the second input, pixHeader struct, to have field: dy");
	if (!(m_dz = mxGetField(prhs[1], 0, "dz")))
		mexErrMsgTxt("newPixels requires the second input, pixHeader struct, to have field: dz");
	if (!(m_dc = mxGetField(prhs[1], 0, "dc")))
		mexErrMsgTxt("newPixels requires the second input, pixHeader struct, to have field: dc");
	if (!(m_dt = mxGetField(prhs[1], 0, "dt")))
		mexErrMsgTxt("newPixels requires the second input, pixHeader struct, to have field: dt");
	if (!(m_bp = mxGetField(prhs[1], 0, "bp")))
		mexErrMsgTxt("newPixels requires the second input, pixHeader struct, to have field: bp");
	if (!(m_isSigned = mxGetField(prhs[1], 0, "isSigned")))
		mexErrMsgTxt("newPixels requires the second input, pixHeader struct, to have field: isSigned");
	if (!(m_isFloat  = mxGetField(prhs[1], 0, "isFloat")))
		mexErrMsgTxt("newPixels requires the second input, pixHeader struct, to have field: isFloat");
	
	head->dx = (ome_dim) mxGetScalar(m_dx);
 	head->dy = (ome_dim) mxGetScalar(m_dy);
 	head->dz = (ome_dim) mxGetScalar(m_dz);
 	head->dc = (ome_dim) mxGetScalar(m_dc);
 	head->dt = (ome_dim) mxGetScalar(m_dt);
 	head->bp = (u_int8_t) mxGetScalar(m_bp);
 	head->isSigned = (u_int8_t) mxGetScalar(m_isSigned);
 	head->isFloat  = (u_int8_t) mxGetScalar(m_isFloat);
 	
	url = mxArrayToString(m_url);
	sessionkey = mxArrayToString(m_sessionkey);
	
	is = openConnectionOMEIS (url, sessionkey);
	if ( !(ID = newPixels (is, head)) ) {			
		mxFree(url);
		mxFree(sessionkey);
		mxFree(head);
		mxFree(is);
		mexErrMsgTxt("newPixels OMEIS method failed.\n");
	}
	
	plhs[0] = mxCreateScalarDouble((double) ID);

	mxFree(url);
	mxFree(sessionkey);
	mxFree(head);
	mxFree(is);
}