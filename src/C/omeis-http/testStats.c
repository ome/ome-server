#include <stdio.h>
#include <stdlib.h>
#include "httpOMEIS.h"

int main (int argc, char**argv)
{
	omeis* is;
	OID ID;
	pixHeader* ph;
	pixStats **stackStats;
	pixStats ***planeStats;
	unsigned int theZ, theC, theT, nZ, nC, nT;
	
	if (argc < 3) {
		fprintf (stderr,"Usage:\n\t %s <OMEIS URL> <PixelsID>\n",argv[0]);
		exit (-1);
	}
	
	sscanf (argv[2],"%llu",&ID);
	if (ID == 0) {
		fprintf (stderr,"Usage:\n\t %s <OMEIS URL> <PixelsID>\n",argv[0]);
		exit (-2);
	}
	
	is = openConnectionOMEIS(argv[1], "0000");
	ph = pixelsInfo (is, ID);

	if ( ph != NULL) {
		nZ = ph->dz;
		nC = ph->dc;
		nT = ph->dt;
		printf("Dims=%d,%d,%d,%d,%d,%d\n", ph->dx, ph->dy, nZ, nC, nT, ph->bp);
		printf("Finished=%d\n", ph->isFinished);
		printf("Signed=%d\n",   ph->isSigned);
		printf("Float=%d\n",    ph->isFloat);
		printf("SHA1=%s\n",     ph->sha1);
	}
	
	while (1) {
	
	printf ("XYZ stack statistics:\n");
	stackStats = getStackStats (is, ID);
	for (theC=0; theC < nC; theC++) {
		for (theT=0; theT < nT; theT++) {
			printf ("%d\t%d\t%f\t%f\t%f\n",theC,theT,
				stackStats[theC][theT].min,
				stackStats[theC][theT].max,
				stackStats[theC][theT].mean
			);
		}
	}
	freeStackStats (stackStats);

	printf ("YZ plane statistics:\n");
	planeStats = getPlaneStats (is, ID);
	for (theZ=0; theZ < nZ; theZ++) {
		for (theC=0; theC < nC; theC++) {
			for (theT=0; theT < nT; theT++) {
				printf ("%d\t%d\t%d\t%f\t%f\t%f\n",theZ,theC,theT,
					planeStats[theZ][theC][theT].min,
					planeStats[theZ][theC][theT].max,
					planeStats[theZ][theC][theT].mean
				);
			}
		}
	}
	freePlaneStats (planeStats);

	}
	free(is);
	free(ph);
	return 1;
}
