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
//  13 Sep 2003 T. Macura:  Modified for inclusion in OME.  Generalized to compute
//     Haralick Features based on the image's co-occurrence matrix for any 
//     specified distance and angle. Limits on image's quantisation level removed.
//     Input is still limited to uin8 (i.e. 255 quantization levels).
//
/////////////////////////////////////////////////////////////////////////*/

#include "CVIPtexture.h"
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>

#include "httpOMEIS.h"
#include "httpOMEISaux.h"

extern TEXTURE * Extract_Texture_Features(); 

int main (int argc, char* argv[])
{
	OID ID;
	int distance, angle;
	
	u_int8_t**  p_gray;              /*Image converted for texture calcs*/
	TEXTURE*    features ;           /*Returned struct of features*/

	/* OMEIS data structures */
	omeis* is;
	pixHeader* head;
	void* pixels;

	
	if (argc != 4) {
		fprintf(stderr, "\n mb_texture (im, distance, angle),\n\n"
		 "This function returns the 14 image texture statistics described by R. Haralick.\n"
		 "The statistics are calculated from the image's co-occurence matrix specified\n"
		 "for a particular distance and angle. Distance is measured in pixels and\n"
		 "the angle is measured in degrees.\n");
		return EXIT_FAILURE;
	}
	
	sscanf(argv[1], "%llu", &ID);
	sscanf(argv[2], "%d", &distance);
	sscanf(argv[3], "%d", &angle);
	
	is = openConnectionOMEIS ("http://localhost/cgi-bin/omeis","0000");
	if (!(head = pixelsInfo (is, ID))){
		fprintf (stderr, "PixelsID %llu or OMEIS URL '%s' is probably wrong\n", ID, is->url);
		return EXIT_FAILURE;
	}
	
	if (!(pixels = getPixels (is, ID))) {
		fprintf (stderr, "Couldn't get Pixels with ID %llu\n", ID);
		return 0;
	}
	
	p_gray = (u_int8_t**) OMEIStoCArray (pixels, head, "unsigned char");
	
	if (! (features=Extract_Texture_Features(distance, angle, p_gray, head->dy, head->dx, 255))) {
		fprintf(stderr, "ERROR: Could not compute Haralick Features.\n");
		return EXIT_FAILURE;
	}
	
	printf("%f\n",features->ASM);
	printf("%f\n",features->contrast);
	printf("%f\n",features->correlation);
	printf("%f\n",features->variance);
	printf("%f\n",features->IDM);
	printf("%f\n",features->sum_avg);
	printf("%f\n",features->sum_var);
	printf("%f\n",features->sum_entropy);
	printf("%f\n",features->entropy);
	printf("%f\n",features->diff_var);
	printf("%f\n",features->diff_entropy);
	printf("%f\n",features->meas_corr1);
	printf("%f\n",features->meas_corr2);
	printf("%f\n",features->max_corr_coef);
	
	free(p_gray);
	free(pixels);
	free(features);
	return(EXIT_SUCCESS);
}
