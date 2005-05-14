#include <stdio.h>
#include <stdlib.h>
#include "httpOMEIS.h"
#include "httpOMEISaux.h"

int main (void)
{
	omeis* is;
	pixHeader* ph = malloc(sizeof(pixHeader));
	
	is = openConnectionOMEIS("http://localhost/cgi-bin/omeis", "0000");
	ph->dx = 3;
	ph->dy = 3;
	ph->dz = 1;
	ph->dc = 1;
	ph->dt = 1;
	CtoOMEISDatatype ("unsigned char", ph);
	unsigned char array[] = {1,2,3,4,5,6,7,8,9};
	
	OID ID = newPixels (is, ph);
	int pix = setPixels (is, ID, (void*) array);
	fprintf (stderr, "pix = %d\n", pix);
	ID = finishPixels (is, ID);
	char* path = getLocalPath (is, ID);
	char* sha1 = pixelsSHA1 (is, ID);

	free(ph);
	ph = pixelsInfo (is, ID);

	printf("SHA1 = `%s`\n", sha1);
	printf("path = `%s`\n", path);

	if ( ph != NULL) {
		printf("Dims=%d,%d,%d,%d,%d,%d\n", ph->dx, ph->dy, ph->dz, ph->dc, ph->dt, ph->bp);
		printf("Finished=%d\n", ph->isFinished);
		printf("Signed=%d\n",   ph->isSigned);
		printf("Float=%d\n",    ph->isFloat);
		printf("SHA1=%s\n",     ph->sha1);
	}
	
	void* pixels = getPixels (is,  135);
	int**  int_pixels = (int**) OMEIStoCArray (pixels, ph, "int");
	
	int i,j;
	for (i=0; i<3; i++) {
		for (j=0; j<3; j++)
			printf ("%d ", int_pixels[i][j]);
		printf ("\n");
	}

	free(is);
	free(ph);
	free(sha1);
	free(path);
	return 1;
}