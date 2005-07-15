#include <string.h>
#include <stdlib.h>
#include "httpOMEIS.h"
#include "httpOMEISaux.h"

#ifdef MATLAB
#include "matrix.h"

/*
	checks to see if pixels are of the same types by comparing the
	bits per pixel, isSigned, and isFloat variables
*/

int samePixelType (pixHeader* lhs, pixHeader* rhs)
{
	/* if isFloat=1 isSigned might be 0 or might be 1.
	   Hence we have this special check */
	   
	if ((lhs->isFloat == 1) && (rhs->isFloat == 1))
		return 1;
		
	if ( (lhs->bp != rhs->bp) ||
		 (lhs->isSigned != rhs->isSigned) ||
		 (lhs->isFloat  != lhs->isFloat) ){
		 return 0;
	} else {
		return 1;
	}
}

int OMEIStoMATLABDatatype (pixHeader* head)
{
	if (head->bp == 1 && head->isSigned == 1) {
		return mxINT8_CLASS;
	} else if (head->bp == 1 && head->isSigned == 0) {
		return mxUINT8_CLASS;
	} else if (head->bp == 2 && head->isSigned == 1) {
		return mxINT16_CLASS;
	} else if (head->bp == 2 && head->isSigned == 0) {
		return mxUINT16_CLASS;	
	} else if (head->bp == 4 && head->isSigned == 1 && head->isFloat == 0) {
		return mxINT32_CLASS;
	} else if (head->bp == 4 && head->isSigned == 0 && head->isFloat == 0) {
		return mxUINT32_CLASS;
	} else if (head->isFloat == 1) {
		return mxSINGLE_CLASS;
	}
	
	return 0;
}
#endif

void CtoOMEISDatatype (const char* data_type, pixHeader* head)
{
	if (!strcmp (data_type, "char") || !strcmp(data_type, "int8")) {
		head->bp       = 1;
		head->isSigned = 1;
		head->isFloat  = 0;
	} else if (!strcmp (data_type, "unsigned char") || !strcmp(data_type, "uint8")) {
		head->bp       = 1;
		head->isSigned = 0;
		head->isFloat  = 0;
	} else if (!strcmp (data_type, "short") || !strcmp(data_type, "int16")) {
		head->bp       = 2;
		head->isSigned = 1;
		head->isFloat  = 0;
	} else if (!strcmp (data_type, "unsigned short") || !strcmp(data_type, "uint16")) {
		head->bp       = 2;
		head->isSigned = 0;
		head->isFloat  = 0;
	} else if (!strcmp (data_type, "long") || !strcmp (data_type, "int") || !strcmp (data_type, "int32")) {
		head->bp       = 4;
		head->isSigned = 1;
		head->isFloat  = 0;
	} else if (!strcmp (data_type, "unsigned long") || !strcmp (data_type, "uint32")) {
		head->bp       = 4;
		head->isSigned = 0;
		head->isFloat  = 0;
	} else if (strcmp (data_type, "float") || !strcmp (data_type, "single")) {
		head->bp       = 4;
		head->isSigned = 1;
		head->isFloat  = 1;
	} else {
		fprintf (stderr, "%s is not a type supported by OMEIS\n", data_type);
	}
}

void OMEIStoCDatatype (char* data_type, pixHeader* head)
{
	if (head->bp == 1 && head->isSigned == 1) {
		strcpy (data_type, "char");
	} else if (head->bp == 1 && head->isSigned == 0) {
		strcpy (data_type, "unsigned char");
	} else if (head->bp == 2 && head->isSigned == 1) {
		strcpy (data_type, "short") ;
	} else if (head->bp == 2 && head->isSigned == 0) {
		strcpy (data_type, "unsigned short") ;
	} else if (head->bp == 4 && head->isSigned == 1 && head->isFloat == 0) {
		strcpy (data_type, "int");
	} else if (head->bp == 4 && head->isSigned == 0 && head->isFloat == 0) {
		strcpy (data_type, "unsigned long");
	} else if (head->isFloat == 1) {
		strcpy (data_type, "float");
	} else {
		fprintf (stderr, "%s is not a type supported by OMEIS\n", data_type);
	}
}

void** OMEIStoCArray (void* input, pixHeader* head, char* conversion_type)
{
	char initial_type[32];
	int i,j;
	
	OMEIStoCDatatype(initial_type, head);
	
	/***************************************************************************
	** CHAR
	***************************************************************************/
	if (!strcmp (initial_type, "char")) {
		if (!strcmp (conversion_type, "char")) {
			char** output_t;
			output_t = (char**) malloc(sizeof(char*)*head->dy);
			for (i=0; i<head->dy; i++)
				output_t[i] = input + (i*head->dy*head->bp);
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned char")) {
			char* input_t = (char*) input;
			unsigned char** output_t = (unsigned char**)malloc(sizeof(unsigned char**)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned char*) malloc(sizeof(unsigned char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "short")) {
			char* input_t = (char*) input;
			short** output_t = (short**) malloc(sizeof(short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (short *) malloc(sizeof(short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned short")) {
			char*  input_t = (char*) input;
			unsigned short** output_t = (unsigned short**) malloc(sizeof(unsigned short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned short*) malloc(sizeof(unsigned short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "long") || !strcmp (conversion_type, "int")) {
			char*  input_t = (char*) input;
			long** output_t = (long **) malloc(sizeof(long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (long *) malloc(sizeof(long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned long")) {
			char*  input_t = (char*) input;
			unsigned long** output_t = (unsigned long **)malloc(sizeof(unsigned long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned long*)malloc(sizeof(unsigned long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "float")) {
			char*  input_t = (char*) input;
			float** output_t = (float **) malloc(sizeof(float*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (float *) malloc(sizeof(float)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else {
			fprintf (stderr, "%s is not a type supported by OMEIS\n", initial_type);
			return NULL;
		}
	/***************************************************************************
	** UNSIGNED CHAR
	***************************************************************************/
	} else if (!strcmp (initial_type, "unsigned char")) {
		if (!strcmp (conversion_type, "char")) {
			unsigned char*  input_t = (unsigned char*) input;
			char** output_t = (char **) malloc(sizeof(char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (char *) malloc(sizeof(char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned char")) {
			unsigned char** output_t;
			output_t = (unsigned char**) malloc(sizeof(unsigned char*)*head->dy);
			for (i=0; i<head->dy; i++)
				output_t[i] = input + (i*head->dy*head->bp);
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "short")) {
			unsigned char*  input_t = (unsigned char*) input;
			short** output_t = (short **) malloc(sizeof(short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (short *) malloc(sizeof(short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned short")) {
			unsigned char*  input_t = (unsigned char*) input;
			unsigned short** output_t = (unsigned short**) malloc(sizeof(unsigned short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned short*) malloc(sizeof(unsigned short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "long") || !strcmp (conversion_type, "int")) {
			unsigned char*  input_t = (unsigned char*) input;
			long** output_t = (long **) malloc(sizeof(long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (long *) malloc(sizeof(long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned long")) {
			unsigned char*  input_t = (unsigned char*) input;
			unsigned long** output_t = (unsigned long **) malloc(sizeof(unsigned long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned long *) malloc(sizeof(unsigned long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "float")) {
			unsigned char*  input_t = (unsigned char*) input;
			float** output_t = (float **) malloc(sizeof(float*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (float *) malloc(sizeof(float)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else {
			fprintf (stderr, "%s is not a type supported by OMEIS\n", initial_type);
			return NULL;
		}
	/***************************************************************************
	** SHORT
	***************************************************************************/
	} else if (!strcmp (initial_type, "short")) {
		if (!strcmp (conversion_type, "char")) {
			short*  input_t = (short*) input;
			char** output_t = (char **) malloc(sizeof(char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (char *) malloc(sizeof(char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned char")) {
			short*  input_t = (short*) input;
			unsigned char** output_t = (unsigned char **) malloc(sizeof(unsigned char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned char *) malloc(sizeof(unsigned char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "short")) {
			short** output_t = (short**) malloc(sizeof(short*)*head->dy);
			for (i=0; i<head->dy; i++)
				output_t[i] = input + (i*head->dy*head->bp);
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned short")) {
			short*  input_t = (short*) input;
			unsigned short** output_t = (unsigned short**) malloc(sizeof(unsigned short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned short*) malloc(sizeof(unsigned short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "long") || !strcmp (conversion_type, "int")) {
			short*  input_t = (short*) input;
			long** output_t = (long **) malloc(sizeof(long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (long *) malloc(sizeof(long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned long")) {
			short*  input_t = (short*) input;
			unsigned long** output_t = (unsigned long**) malloc(sizeof(unsigned long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned long*) malloc(sizeof(unsigned long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "float")) {
			short*  input_t = (short*) input;
			float** output_t = (float **) malloc(sizeof(float*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (float *) malloc(sizeof(float)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else {
			fprintf (stderr, "%s is not a type supported by OMEIS\n", initial_type);
			return NULL;
		}
	/***************************************************************************
	** UNSIGNED SHORT
	***************************************************************************/
	} else if (!strcmp (initial_type, "unsigned short")) {
		if (!strcmp (conversion_type, "char")) {
			unsigned short*  input_t = (unsigned short*) input;
			char** output_t = (char **) malloc(sizeof(char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (char *) malloc(sizeof(char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned char")) {
			unsigned short*  input_t = (unsigned short*) input;
			unsigned char** output_t = (unsigned char**) malloc(sizeof(unsigned char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned char*) malloc(sizeof(unsigned char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;		
		} else if (!strcmp (conversion_type, "short")) {
			unsigned short*  input_t = (unsigned short*) input;
			short** output_t = (short **) malloc(sizeof(short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (short *) malloc(sizeof(short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned short")) {
			unsigned short** output_t = (unsigned short**) malloc(sizeof(unsigned short*)*head->dy);
			for (i=0; i<head->dy; i++)
				output_t[i] = input + (i*head->dy*head->bp);
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "long") || !strcmp (conversion_type, "int")) {
			unsigned short*  input_t = (unsigned short*) input;
			long** output_t = (long **) malloc(sizeof(long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (long *) malloc(sizeof(long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned long")) {
			unsigned short*  input_t = (unsigned short*) input;
			unsigned long** output_t = (unsigned long**) malloc(sizeof(unsigned long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned long *) malloc(sizeof(unsigned long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "float")) {
			unsigned short*  input_t = (unsigned short*) input;
			float** output_t = (float **) malloc(sizeof(float*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (float *) malloc(sizeof(float)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else {
			fprintf (stderr, "%s is not a type supported by OMEIS\n", initial_type);
			return NULL;
		}
	/***************************************************************************
	** LONG
	***************************************************************************/
	} else if (!strcmp (initial_type, "long") || !strcmp (initial_type, "int")) {
		if (!strcmp (conversion_type, "char")) {
			long*  input_t = (long*) input;
			char** output_t = (char **) malloc(sizeof(char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (char *) malloc(sizeof(char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned char")) {
			long*  input_t = (long*) input;
			unsigned char** output_t = (unsigned char**) malloc(sizeof(unsigned char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned char*) malloc(sizeof(unsigned char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "short")) {
			long*  input_t = (long*) input;
			short** output_t = (short **) malloc(sizeof(short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (short *) malloc(sizeof(short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned short")) {
			long*  input_t = (long*) input;
			unsigned short** output_t = (unsigned short**) malloc(sizeof(unsigned short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned short*) malloc(sizeof(unsigned short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "long") || !strcmp (conversion_type, "int")) {
			long** output_t = (long**) malloc (sizeof(long*)*head->dy);
			for (i=0; i<head->dy; i++)
				output_t[i] = input + (i*head->dy*head->bp);
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned long")) {
			long*  input_t = (long*) input;
			unsigned long** output_t = (unsigned long**) malloc(sizeof(unsigned long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned long*) malloc(sizeof(unsigned long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "float")) {
			long*  input_t = (long*) input;
			float** output_t = (float **) malloc(sizeof(float*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (float *) malloc(sizeof(float)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else {
			fprintf (stderr, "%s is not a type supported by OMEIS\n", initial_type);
			return NULL;
		}
	/***************************************************************************
	** UNSIGNED LONG
	***************************************************************************/
	} else if (!strcmp (initial_type, "unsigned long")) {
		if (!strcmp (conversion_type, "char")) {
			unsigned long*  input_t = (unsigned long*) input;
			char** output_t = (char **) malloc(sizeof(char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (char *) malloc(sizeof(char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned char")) {
			unsigned long*  input_t = (unsigned long*) input;
			unsigned char** output_t = (unsigned char**) malloc(sizeof(unsigned char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned char*) malloc(sizeof(unsigned char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "short")) {
			unsigned long*  input_t = (unsigned long*) input;
			short** output_t = (short **) malloc(sizeof(short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (short *) malloc(sizeof(short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned short")) {
			unsigned long*  input_t = (unsigned long*) input;
			unsigned short** output_t = (unsigned short**) malloc(sizeof(unsigned short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned short*) malloc(sizeof(unsigned short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "long") || !strcmp (conversion_type, "int")) {
			unsigned long*  input_t = (unsigned long*) input;
			long** output_t = (long **) malloc(sizeof(long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (long *) malloc(sizeof(long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned long")) {
			unsigned long** output_t = (unsigned long**) malloc (sizeof(unsigned long*)*head->dy);
			for (i=0; i<head->dy; i++)
				output_t[i] = input + (i*head->dy*head->bp);
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "float")) {
			unsigned long*  input_t = (unsigned long*) input;
			float** output_t = (float **) malloc(sizeof(float*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (float *) malloc(sizeof(float)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else {
			fprintf (stderr, "%s is not a type supported by OMEIS\n", initial_type);
			return NULL;
		}
	/***************************************************************************
	** FLOAT
	***************************************************************************/
	} else if (!strcmp (initial_type, "float")) {
		if (!strcmp (conversion_type, "char")) {
			float*  input_t = (float*) input;
			char** output_t = (char **) malloc(sizeof(char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (char *) malloc(sizeof(char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned char")) {
			float*  input_t = (float*) input;
			unsigned char** output_t = (unsigned char**) malloc(sizeof(unsigned char*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned char*) malloc(sizeof(unsigned char)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "short")) {
			float*  input_t = (float*) input;
			short** output_t = (short **) malloc(sizeof(short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (short *) malloc(sizeof(short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned short")) {
			float*  input_t = (float*) input;
			unsigned short** output_t = (unsigned short**) malloc(sizeof(unsigned short*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned short*) malloc(sizeof(unsigned short)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "long") || !strcmp (conversion_type, "int")) {
			float*  input_t = (float*) input;
			long** output_t = (long **) malloc(sizeof(long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (long *) malloc(sizeof(long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "unsigned long")) {
			float*  input_t = (float*) input;
			unsigned long** output_t = (unsigned long **) malloc(sizeof(unsigned long*)*head->dy);
			for (i=0; i<head->dy; i++) {
				output_t[i] = (unsigned long *) malloc(sizeof(unsigned long)*head->dx);
				for (j=0; j<head->dx; j++)
					output_t[i][j] = input_t[i*head->dy+j];
			}
			return (void**) output_t;
		} else if (!strcmp (conversion_type, "float")) {
			float** output_t;
			output_t = (float**) malloc (sizeof(float*)*head->dy);
			for (i=0; i<head->dy; i++)
				output_t[i] = input + (i*head->dy*head->bp);
			return (void**) output_t;
		} else {
			fprintf (stderr, "%s is not a type supported by OMEIS\n", initial_type);
			return NULL;
		}
	}
	fprintf (stderr, "%s is not a type supported by OMEIS\n", initial_type);
	return NULL;
}
