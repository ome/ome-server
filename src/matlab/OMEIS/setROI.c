#include <stdio.h>
#include <string.h>

#include "mex.h"
#include "matrix.h"
#include "ome-Matlab.h" /* backwards compatiblity to mwSize/mwIndex */

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
	mxArray *permute_inputs[2];
	mxArray *copy_input_array; /* we need a local copy so we can transpose it */
	
	char* url, *sessionkey;
	
	if (nrhs != 13)
		mexErrMsgTxt("\n [pix] = setROI (is, ID, row0 (OME:y0), column0 (OME:x0), z0, c0, t0, row1 (OME:y1), column1 (OME:x1), z1, c1, t1, pixels)");
		
	if (!mxIsStruct(prhs[0]))
		mexErrMsgTxt("setROI requires the first input to be the struct outputed"
					 " from openConnectionOMEIS\n");
					 
	if (!(m_url = mxGetField(prhs[0], 0, "url")))
		mexErrMsgTxt("setROI requires the first input, OMEIS struct, to have field: url");
	if (!(m_sessionkey = mxGetField(prhs[0], 0, "sessionkey")))
		mexErrMsgTxt("setROI requires the first input, OMEIS struct, to have field: sessionkey");
		
	if (!mxIsChar(m_url) || !mxIsChar(m_sessionkey))
		mexErrMsgTxt("OMEIS field aren't character array.\n");		
	
	if (!mxIsNumeric(prhs[1]))
		mexErrMsgTxt("setROI requires the second input to be the PixelsID\n") ;
		
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
	
	if (!(head = pixelsInfo (is, ID))){
		char err_str[128];
		sprintf(err_str, "PixelsID %llu or OMEIS URL '%s' is probably wrong\n", ID, is->url);		
		
		/* clean up */
		mxFree(url);
		mxFree(sessionkey);
		mxFree(is);
		
		mexErrMsgTxt(err_str);
	}
	
	/*
		In OMEIS Size_X corresponds to columns and Size_Y corresponds to rows.
		This is diametrically opposite to MATLAB's assumptions.
		hence we do
		"$matlab_var_name = permute($matlab_var_name, [2 1 3 4 5]);" 
		the hard way (groan)
	*/
	
	permute_inputs[0] = prhs[12]; /* permute_input isn't being modified so
									discarding the const qualifier is okay */
	permute_inputs[1] = mxCreateDoubleMatrix(1, 5, mxREAL);
 	mxGetPr(permute_inputs[1])[0] = 2;
 	mxGetPr(permute_inputs[1])[1] = 1;
 	mxGetPr(permute_inputs[1])[2] = 3;
 	mxGetPr(permute_inputs[1])[3] = 4;
 	mxGetPr(permute_inputs[1])[4] = 5;
 	
	/* mexCallMATLAB allocates memory for copy_input_array */
 	if (mexCallMATLAB(1, &copy_input_array, 2, permute_inputs, "permute")) {
		/* clean up */
		mxFree(url);
		mxFree(sessionkey);
		mxFree(head);
		mxFree(is);
		
 		char err_str[128];
		sprintf(err_str, "Couldn't permute the pixels to get them in MATLAB orientation");
		mexErrMsgTxt(err_str);
 	}
 	
	/* check dimension and class check */
	const mwSize* dims = mxGetDimensions (copy_input_array);
	switch (mxGetNumberOfDimensions (copy_input_array)) {
		char err_str[128];
		case 5:
			if ((t1-t0+1) != dims[4]) {
				sprintf (err_str, "5th Dimension (%d) of input array and Pixels doesn't match specified ROI extents (%d to %d).\n", dims[4], t0, t1);
				mexErrMsgTxt (err_str);
			}
		case 4:
			if ((c1-c0+1) != dims[3]) {
				sprintf (err_str, "4th Dimension (%d) of input array and Pixels doesn't match specified ROI extents (%d to %d).\n", dims[3], c0, c1);
				mexErrMsgTxt (err_str);
			}
		case 3:
			if ((z1-z0+1) != dims[2]) {
				sprintf (err_str, "3th Dimension (%d) of input array and Pixels doesn't match specified ROI extents (%d to %d).\n", dims[2], z0, z1);
				mexErrMsgTxt (err_str);
			}
		case 2:
			if ((y1-y0+1) != dims[1]) {
				sprintf (err_str, "Height (%d) of input array and Pixels doesn't match specified ROI extents (%d to %d).\n", dims[1], y0, y1);
				mexErrMsgTxt (err_str);
			}
		case 1:
			if ((x1-x0+1) != dims[0]) {
				sprintf (err_str, "Width (%d) of input array and Pixels doesn't match specified ROI extents (%d to %d.\n", dims[0], x0, x1);
				mexErrMsgTxt (err_str);
			}
			break;
		default:
			/* clean up */
			mxFree(url);
			mxFree(sessionkey);
			mxFree(head);
			mxFree(is);
			mxDestroyArray(copy_input_array);
					
			mexErrMsgTxt("Input Array must be 5D or less");
			break;
	}
	
	pixHeader tmp_head;
	CtoOMEISDatatype ((char*) mxGetClassName(copy_input_array), &tmp_head);
	
	if ( !samePixelType(&tmp_head, head)) {
		/* clean up */
		mxFree(url);
		mxFree(sessionkey);
		mxFree(head);
		mxFree(is);
		mxDestroyArray(copy_input_array);

		mexErrMsgTxt("Types of input array and Pixels don't match\n");
	}
	
	/* set the pixels */
	int pix = setROI (is, ID, x0, y0, z0, c0, t0, x1, y1, z1, c1, t1, mxGetPr(copy_input_array));
	
	/* record number of pixels written */
	plhs[0] = mxCreateScalarDouble((double) pix);
	
	/* clean up */
	mxFree(url);
	mxFree(sessionkey);
	mxFree(head);
	mxFree(is);
	mxDestroyArray(copy_input_array);
}
