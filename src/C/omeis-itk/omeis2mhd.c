#include <stdio.h>
#include <stdlib.h>

#include "httpOMEIS.h"
#include "itkOMEIS.h"

int main (int argc, char* argv[])
{
	omeis* is;
	pixHeader* ph;
	OID ID;
	char* omeis_url = NULL;
	char* output_basename = NULL;
	
	/* interpret the function inputs */	
	if (argc == 2)
		sscanf(argv[1], "%llu", &ID);
	else if (argc == 3) {
		sscanf(argv[1], "%llu", &ID);
		output_basename = argv[2];		
	} else if (argc == 4) {
		sscanf(argv[1], "%llu", &ID);
		output_basename = argv[2];		
		omeis_url = argv[3];		
	} else {
		printf("USAGE: %s <PixelsID> [<OUTPUT_BASENAME>] [<OMEIS_URL>] e.g. \n", argv[0]);
		printf("       %s 1 \n", argv[0]);
		printf("       %s 1 itk-out http://localhost/cgi-bin/omeis \n", argv[0]);
		return EXIT_FAILURE;
	}
	
	/* open connection to OMEIS */
	if (omeis_url != NULL)
		is = openConnectionOMEIS(omeis_url, "OOOO");
	else
		is = openConnectionOMEIS("http://localhost/cgi-bin/omeis/", "OOOO");
	
	/* get image header information and pixels */
	if (!(ph = pixelsInfo(is, ID))) {
		fprintf(stderr, "PixelsID %llu is invalid.\n", ID);
		return EXIT_FAILURE;
	}
	void* pixels = getPixels (is, ID);

	/* open MetaImage header and raw-pixels files for writing */
	FILE* mhd_FILE;
	FILE* raw_FILE;
	char mhd_filename[25]; /* PixelsID has a maximum of 21 characters */
	char raw_filename[25];
	
	if (output_basename == NULL) {
		sprintf(mhd_filename, "%llu.mhd", ID);
		sprintf(raw_filename, "%llu.raw", ID);
	} else {
		sprintf(mhd_filename, "%s.mhd", output_basename);
		sprintf(raw_filename, "%s.raw", output_basename);
	}
	
	if ( !(mhd_FILE = fopen(mhd_filename, "w")) ) {
		fprintf(stderr, "Couldn't open output MetaImage header file.\n");
		return EXIT_FAILURE;
	}
	
	if ( !(raw_FILE = fopen(raw_filename, "w")) ) {
		fprintf(stderr, "Couldn't open output MetaImage raw-pixels file.\n");
		fclose(mhd_FILE);
		return EXIT_FAILURE;
	}
	
	/* write raw-pixels file */
	if ( fwrite(pixels, sizeof(char)*ph->bp, ph->dx*ph->dy*ph->dz*ph->dc*ph->dt, raw_FILE)
			!= ph->dx*ph->dy*ph->dz*ph->dc*ph->dt ) {
		fprintf(stderr, "Couldn't write all pixels to output MetaImage raw-pixels file.\n");
		fclose(mhd_FILE);
		fclose(raw_FILE);
		return EXIT_FAILURE;
	}
	fclose(raw_FILE);
	
	/* write header file */
	int NDims = nDims (ph);
	fprintf(mhd_FILE, "NDims = %d\n", NDims);
	
	fprintf(mhd_FILE, "DimSize =");
	if (NDims >= 1) fprintf(mhd_FILE, " %d", ph->dx);
	if (NDims >= 2) fprintf(mhd_FILE, " %d", ph->dy);
	if (NDims >= 3) fprintf(mhd_FILE, " %d", ph->dz);
	if (NDims >= 4) fprintf(mhd_FILE, " %d", ph->dc);
	if (NDims == 5) fprintf(mhd_FILE, " %d", ph->dt);
	fprintf(mhd_FILE, "\n");

	char* ElementType = OMEIStoMETDatatype(ph);
	fprintf(mhd_FILE, "ElementType = %s\n", ElementType);
	free(ElementType);
	
	/* set the endianness of the file to the endianness of the local machine */
	if (bigEndian() )
		fprintf(mhd_FILE, "ElementByteOrderMSB = True\n");
	else
		fprintf(mhd_FILE, "ElementByteOrderMSB = False\n");
		
	fprintf(mhd_FILE, "ElementDataFile = %s\n", raw_filename);
	fclose(mhd_FILE);
	
	free(is);
	free(ph);
	return (EXIT_SUCCESS);
}