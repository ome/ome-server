/*/////////////////////////////////////////////////////////////////////////
//
//
//                            mb_texture.c 
//
//
//                           Michael Boland
//                            23 Nov 1998
//
//  Revisions:
//  13 Sep 2004 T. Macura:  Modified for inclusion in OME.  Generalized to compute
//     Haralick Features based on the image's co-occurrence matrix for any 
//     specified distance and angle. Limits on image's quantisation level removed.
//     Input is still limited to uint8 (i.e. 255 quantization levels).
//
/////////////////////////////////////////////////////////////////////////*/


#include "mex.h"
#include "matrix.h"
#include "CVIPtexture.h"
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>

#define row 0
#define col 1

extern TEXTURE * Extract_Texture_Features();

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	mxArray*    img;
	u_int8_t*   p_img;               /*The image from Matlab*/
	u_int8_t**  p_gray;              /*Image converted for texture calcs*/
	int         mrows;               /*Image height*/
	int         ncols;               /*Image width*/
	TEXTURE*    features ;           /*Returned struct of features*/
	int         i ;
	int         imgsize[2] ;              
	int         imgindex[2] ;
	long        offset ;                  
	int         outputsize[2] ;      /*Dimensions of TEXTURE struct*/
	int         outputindex[2] ;
	
	float*      output ;             /*Features to return*/
	int         distance, angle;     /*Parameters for texture calculations*/

	if (nrhs != 3)
		mexErrMsgTxt("\n mb_texture (im, distance, angle),\n\n"
		 "This function returns the 14 image texture statistics described by R. Haralick.\n"
		 "The statistics are calculated from the image's co-occurence matrix specified\n"
		 "for a particular distance and angle. Distance is measured in pixels and\n"
		 "the angle is measured in degrees.\n");
    
    else if (nlhs != 1)
		mexErrMsgTxt("mb_texture returns a single output.\n") ;
	
	if (!mxIsNumeric(prhs[0]))
		mexErrMsgTxt("mb_texture requires the first input to be numeric\n") ;
	
	if (!mxIsUint8(prhs[0]))
		mexCallMATLAB(1, &img, 1, prhs, "im2uint8_dynamic_range");
	else
		img = prhs[0];
	
	mrows = (int) mxGetM(img) ;
	ncols = (int) mxGetN(img) ;
	
	if (!(mrows > 1) || !(ncols > 1))
		mexErrMsgTxt("mb_texture requires an input image, not a scalar.\n") ;
	
	if ( !mxIsNumeric(prhs[1]) || (mxIsComplex(prhs[1])) )
		mexErrMsgTxt("The second argument (distance) should be numeric and not complex.");

	if ( !mxIsNumeric(prhs[2]) || (mxIsComplex(prhs[2])) )
		mexErrMsgTxt("The third argument (angle) should be numeric and not complex.");


	p_img = (u_int8_t*) mxGetData(img) ;
	distance = (double) mxGetScalar(prhs[1]) ;
	angle = (double) mxGetScalar(prhs[2]) ;
	
	imgsize[col] = ncols ;
	imgsize[row] = mrows ;
	
	p_gray = mxCalloc(mrows, sizeof(u_int8_t*)) ;
	if(p_gray) {
		for(i=0; i<mrows ; i++) {
			p_gray[i] = mxCalloc(ncols, sizeof(u_int8_t)) ;
			if(!p_gray[i])
				mexErrMsgTxt("mb_texture : error allocating p_gray[i]") ;
		}
	} else mexErrMsgTxt("mb_texture : error allocating p_gray") ;
	
	
	for(imgindex[row] = 0 ; imgindex[row] < imgsize[row] ; imgindex[row]++) 
		for(imgindex[col]=0; imgindex[col] < imgsize[col]; imgindex[col]++) {
			offset = mxCalcSingleSubscript(prhs[0], 2, imgindex) ;
			p_gray[imgindex[row]][imgindex[col]] = p_img[offset] ;
		}
	
	if (! (features=Extract_Texture_Features(distance, angle, p_gray,mrows, ncols, 255))) 
		mexErrMsgTxt("ERROR: Could not compute Haralick Features.");
		
	outputsize[row] = 14;
	outputsize[col] = 1;
	
	plhs[0] = mxCreateNumericArray(2, outputsize, mxSINGLE_CLASS, mxREAL) ;
	if (!plhs[0]) 
		mexErrMsgTxt("mb_texture: error allocating return variable.") ;
	
	output = (float*)mxGetData(plhs[0]) ;
	
	/* Copy the features into the return variable */
	outputindex[row]=0 ;
	outputindex[col]=0 ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->ASM;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->contrast;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->correlation;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->variance;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->IDM;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->sum_avg;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->sum_var;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->sum_entropy;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->entropy;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->diff_var;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->diff_entropy;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->meas_corr1;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->meas_corr2;
	
	outputindex[row]++ ;
	offset =  mxCalcSingleSubscript(plhs[0], 2, outputindex) ;
	output[offset] = features->max_corr_coef;

	/*
	    Memory clean-up.
	*/
	for (i=0; i<mrows ; i++)
		mxFree(p_gray[i]) ;
	mxFree(p_gray) ;  
	
	/* features is calloc'd inside of Extract_Texture_Features */
	free(features) ;
}
