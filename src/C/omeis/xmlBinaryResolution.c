/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */

/*------------------------------------------------------------------------------
 *
 * Written by:	Josiah Johnston <siah@nih.gov>    
 * 
 *------------------------------------------------------------------------------
 */

/******************************************************************************

	xmlBinaryResolution.c
	
	Intent: Resolve binary data, both embedded and referenced, from an ome xml file.
	
	Maintence notes:
	The interesting part of this code is three functions:
		OME_StartElement, 
		OME_Characters,
		OME_EndElement
	The parser moves sequentially through the document and calls these
	functions when it hits the beginning of an element, characters
	inside an element, and the end of an element. Sensitivity to certain
	elements and their relative positions is encoded here.
		

	Libraries: This program uses libxml2's SAX library. SAX is a stream based
	xml parser, so memory usage DOES NOT inflate when file size inflates. 
	It also uses zlib and bzip2 compression libraries.

******************************************************************************/


#include <libxml/parser.h>
#include <zlib.h>
#include <bzlib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <errno.h>
#include "xmlBinaryResolution.h"
#include "../base64.h"
#include "../b64z_lib.h"
#include "Pixels.h"
#include "digest.h"
#include "cgi.h"

/******************************************************************************
*
*	Data structures & Constants
*
******************************************************************************/
/* Names of elements this code is sensitive to */
#define BinDataLocal "BinData"
#define BinFileLocal "BinFile"
#define PixelLocal "Pixels"
#define ImageLocal "Image"

#define CompressionAttr "Compression"
#define BinNS "http://www.openmicroscopy.org/XMLschemas/BinaryFile/RC1/BinaryFile.xsd"
#define SIZEOF_FILE_OUT_BUF 1048576
const char *pixelTypes[]            = { "int8", "int16", "int32", "Uint8", "Uint16", "Uint32", "float", NULL };
const unsigned char bytesPerPixel[] = {   1,     2,       4,       1,       2,        4,        4,      0 };
const char typeIsSigned[]           = {   1,     1,       1,       0,       0,        0,        1,      0 };
const char typeIsFloat[]            = {   0,     0,       0,       0,       0,        0,        1,      0 };

/* This is a stack to keep track of
/ whether an element has content or is empty AND
/ whether the opening tag of the element is open (e.g. "<foo" is open, 
/ "<foo>" and "<foo/>" are not). It is used for every element except BinData.
*/
typedef struct _elementInfo {
	int hasContent;
	int tagOpen;
	struct _elementInfo *prev;
} StructElementInfo;

/* <BinData> stuff */
typedef struct {
/* omeis transition: fd instead of fp */
	FILE *BinDataOut;
	char *compression;
	b64z_stream *strm;
} BinDataInfo;

/* Possible states */
typedef enum {
	PARSER_START,
	IN_BINDATA,
	IN_PIXELS,
	IN_BINFILE,
	IN_BINDATA_UNDER_PIXELS,
	IN_BINDATA_UNDER_BINFILE,
} PossibleParserStates;

/* <Pixels> info */
typedef struct {
	/* dimensions of pixel array. C is channels. */
	int X,Y,Z,C,T;
	/* bytes per pixel */
	unsigned char bpp;
	char isSigned, isFloat;
	/* indexes to store current plane */
	int theZ, theC, theT;
	int bigEndian;
	char *dimOrder;
	/* pixelType is not used, but maybe it will come in handy in a later incarnation of this code */
	char *pixelType;
	int hitBinData;
	unsigned char *binDataBuf;
	unsigned int planeSize;
	PixelsRep *pixWriter;
} PixelInfo;


/* <BinFile> info */
typedef struct {
	OID FileID;
	off_t size;
	char name[65];
	int fd;
	/* sh_mmap gets memory mapped to the file on disk */
	unsigned char *sh_mmap;
} BinFileInfo;

/* Contains all the information about the parser's state */
typedef struct {
	PossibleParserStates state;
	int nOutputFiles;
	PixelInfo *pixelInfo;
	BinFileInfo BinFileInfo;
	StructElementInfo* elementInfo;
	BinDataInfo *binDataInfo;
} ParserState;

/******************************************************************************
*
*	Functions Declarations:
*
******************************************************************************/

/* SAX callbacks: */
static void OME_StartDocument(ParserState *state );
static void OME_EndDocument( ParserState *state );
static void OME_StartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs);
static void OME_EndElement(ParserState *state, const xmlChar *name);
static void OME_Characters(ParserState *state, const xmlChar *ch, int len);
static void BinDataWarning( ParserState *state, const char *msg );
static void BinDataError( ParserState *state, const char *msg );
static void BinDataFatalError( ParserState *state, const char *msg ) ;

/* Utility functions: */
void print_element(const xmlChar *name, const xmlChar **attrs);
int increment_plane_indexes( int* a, int* b, int* c, int aMax, int bMax, int cMax );



/******************************************************************************
*
*	main & global data
*
******************************************************************************/
char *dirPath = ".";
char *pixelDirPath = ".";

/******************************************************************************
*
*	Utility Functions:
*
******************************************************************************/


int parse_xml_file(const char *filename) {
    ParserState my_state;
    /* The source of xmlSAXHandler and all the function prefixes I'm using are
    / in <libxml/parser.h> Use `xml2-config --cflags` to find the location of
    / that file.
    */
	xmlSAXHandler xmlBinaryResolutionSAXParser = {
		0, /* internalSubset */
		0, /* isStandalone */
		0, /* hasInternalSubset */
		0, /* hasExternalSubset */
		0, /* resolveEntity */
		0, /* getEntity */
		0, /* entityDecl */
		0, /* notationDecl */
		0, /* attributeDecl */
		0, /* elementDecl */
		0, /* unparsedEntityDecl */
		0, /* setDocumentLocator */
		(startDocumentSAXFunc)OME_StartDocument, /* startDocument */
		(endDocumentSAXFunc)OME_EndDocument, /* endDocument */
		(startElementSAXFunc)OME_StartElement, /* startElement */
		(endElementSAXFunc)OME_EndElement, /* endElement */
		0, /* reference */
		(charactersSAXFunc)OME_Characters, /* characters */
		0, /* ignorableWhitespace */
		0, /* processingInstruction */
		0, /* comment */
		(warningSAXFunc)BinDataWarning, /* warning */
		(errorSAXFunc)BinDataError, /* error */
		(fatalErrorSAXFunc)BinDataFatalError, /* fatalError */
		0, /* getParameterEntitySAXFunc */
		0, /* cdataBlockSAXFunc */
		0, /* externalSubsetSAXFunc */
		0, /* initialized */
	};

	if (xmlSAXUserParseFile(&xmlBinaryResolutionSAXParser, &my_state, filename) < 0) {
		return -1;
	} else
		return my_state.nOutputFiles;
}

void print_element(const xmlChar *name, const xmlChar **attrs) {
	int i;
	
	fprintf( stdout, "<%s ", name );
	if( attrs != NULL ) {
		/* print the attributes. */
		for( i=0;attrs[i] != NULL;i+=2 ) {
			fprintf( stdout, "%s = \"%s\" ", attrs[i], attrs[i+1] );
		}
	}
}

int increment_plane_indexes( int* a, int* b, int* c, int aMax, int bMax, int cMax ) {
	if( *a<aMax-1 ) (*a)++;
	else {
		*a = 0;
		if(*b<bMax-1) (*b)++;
		else {
			*b = 0;
			if(*c<cMax-1) (*c)++;
			else return -1;
		}
	}
	return 0;
}

/******************************************************************************
*
*	SAX callback functions
*
******************************************************************************/

static void OME_StartDocument(ParserState *state) {

	state->state	               = PARSER_START;
	state->nOutputFiles            = 0;
	state->elementInfo             = NULL;
	state->binDataInfo             = (BinDataInfo *) malloc( sizeof( BinDataInfo ) );
	assert( state->binDataInfo != NULL);

	state->binDataInfo->BinDataOut    = NULL;
	state->binDataInfo->strm = NULL;
	
}

static void OME_EndDocument( ParserState *state ) {
	free( state->binDataInfo );
}


static void OME_StartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs) {
	char *localName;
	StructElementInfo* elementInfo;
	int i, pipeThisElementThrough;
	
	pipeThisElementThrough = 1;

	/* mark that the last open element has content, namely this element */
	if( state->elementInfo != NULL && state->state != IN_PIXELS && state->state != IN_BINDATA_UNDER_PIXELS) {
		state->elementInfo->hasContent = 1;
		if( state->elementInfo->tagOpen == 1 ) {
			fprintf( stdout, ">" );
			state->elementInfo->tagOpen = 0;
		}
	}


	/**************************************************************************
	*
	* Getting the namespace for an element is tricky. I haven't figured out 
	* how to do it yet, so I'm using the local name (BinData) to identify the
	* element.
	* I think http://cvs.gnome.org/lxr/source/gnorpm/find/search.c might have
	* some code that will do it.
	*
	* Find the local name of the element: strip the prefix if one exists.
	*/
	localName = strchr( name, ':' );
	if( localName != NULL )
		localName++;
	else
		localName = (char *) name;

	/*
	**************************************************************************/

	

	/**************************************************************************
	*
	* BinData
	* 	Change state, get compression scheme, open output file as necessary
	*/
	if( strcmp( BinDataLocal, localName ) == 0 ) {

		pipeThisElementThrough = 0;

		/* take note of compression */
		state->binDataInfo->compression = NULL;
		if( attrs != NULL ) {
			for( i=0; attrs[i] != NULL; i+=2) {
				if( strcmp( attrs[i], CompressionAttr ) == 0 ) {
					state->binDataInfo->compression = (char *) malloc( sizeof(char) * ( strlen(attrs[i+1]) + 1) );
					assert( state->binDataInfo->compression != NULL);
					strcpy( state->binDataInfo->compression, attrs[i+1] );
					break;
				}
			}
		}

		/* set up decoding stream */
		if( ! (state->binDataInfo->compression ) ) /* if the compression isn't specified, it defaults to 'none' */
			state->binDataInfo->strm = b64z_new_stream( NULL, 0,  NULL, 0, none );
		else if( strcmp(state->binDataInfo->compression, "bzip2") == 0 )
			state->binDataInfo->strm = b64z_new_stream( NULL, 0,  NULL, 0, bzip2 );
		else if( strcmp(state->binDataInfo->compression, "none") == 0 )
			state->binDataInfo->strm = b64z_new_stream( NULL, 0,  NULL, 0, none );
		else if ( strcmp(state->binDataInfo->compression, "zlib") == 0 )
			state->binDataInfo->strm = b64z_new_stream( NULL, 0,  NULL, 0, zlib );
		b64z_decode_init ( state->binDataInfo->strm );

		/* This <BinData> is under <Pixels> */
		if( state->state == IN_PIXELS ) {
			state->state = IN_BINDATA_UNDER_PIXELS;
			state->pixelInfo->hitBinData = 1;
			
			state->binDataInfo->strm->avail_out = state->pixelInfo->planeSize + 2;
			state->binDataInfo->strm->next_out  = state->pixelInfo->binDataBuf;
		} 

		/* This <BinData> is under <Pixels> */
		else if( state->state == IN_BINFILE ) {
			state->state      = IN_BINDATA_UNDER_BINFILE;
			
			state->binDataInfo->strm->avail_out = state->pixelInfo->planeSize + 2;
			state->binDataInfo->strm->next_out  = state->BinFileInfo.sh_mmap;
		}
	}
	/*
	**************************************************************************/



	/**************************************************************************
	*
	* Pixels:
	* 	The <BinData>s under Pixels are treated differently than other 
	* 	<BinData>s. If <BinData>s are used under <Pixels>, then the contents 
	* 	should be processed and coalated into the full pixel dump. We might as
	* 	well do this while it is already loaded in memory.
	*
	* 	The contents of each <BinData> section is buffered into a big chunk.
	* 	When the <BinData> closes, that chunk is converted from base 64,
	* 	uncompressed, and sent through libpix to be written to disk.
	*	
	* 	After every <BinData> under <Pixels> is processed like that, they
	* 	are replaced with a single <External>. This <External> is 
	* 	distiguishable from other <External>s by having a null value for the 
	* 	SHA1 attribute. When one of these <External>s is encountered in later
	* 	processing, the DimensionOrder attribute should be ignored. It describe
	* 	how the <BinData>s were ordered, but the pixels were reordered to
	* 	standard repository format (XYZCT) when they were sent through libpix.
	*/
	else if( strcmp( PixelLocal, localName ) == 0 ) {

		/* set state */
		state->state            = IN_PIXELS;

		/**********************************************************************
		*
		* Extract data from xml attributes.
		*
		*
		*/
		/* data extraction */
		state->pixelInfo = (PixelInfo *) malloc( sizeof( PixelInfo ) );
		assert( state->pixelInfo != NULL);
		if(attrs == NULL) {
			fprintf( stderr, "Error! Pixels element has no attributes!\n" );
			assert( attrs != NULL);
		}
		state->pixelInfo->X = 0;
		state->pixelInfo->Y = 0;
		state->pixelInfo->Z = 0;
		state->pixelInfo->C = 0;
		state->pixelInfo->T = 0;
		state->pixelInfo->bigEndian = -1;
		state->pixelInfo->dimOrder = state->pixelInfo->pixelType = NULL;
		for( i=0; attrs[i] != NULL; i+=2 ) {
			if( strcmp( attrs[i], "SizeX" ) == 0 ) {
				state->pixelInfo->X = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "SizeY" ) == 0 ) {
				state->pixelInfo->Y = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "SizeZ" ) == 0 ) {
				state->pixelInfo->Z = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "SizeC" ) == 0 ) {
				state->pixelInfo->C = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "SizeT" ) == 0 ) {
				state->pixelInfo->T = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "DimensionOrder" ) == 0 ) {
				state->pixelInfo->dimOrder = (char *) malloc( sizeof(char) * ( strlen(attrs[i+1]) + 1 ) );
				assert( state->pixelInfo->dimOrder != NULL);
				strcpy( state->pixelInfo->dimOrder, attrs[i+1] );
			} else if( strcmp( attrs[i], "PixelType" ) == 0 ) {
				state->pixelInfo->pixelType = (char *) malloc( sizeof(char) * ( strlen(attrs[i+1]) + 1 ) );
				assert( state->pixelInfo->pixelType != NULL);
				strcpy( state->pixelInfo->pixelType, attrs[i+1] );
			} else if( strcmp( attrs[i], "BigEndian" ) == 0 ) {
				if( strcmp( attrs[i+1], "true" ) == 0 || strcmp( attrs[i+1], "1" ) == 0 )
					state->pixelInfo->bigEndian = 1;
				else
					state->pixelInfo->bigEndian = 0;
			}
		}
		
		/* error check: verify we have all needed attributes */
		if( state->pixelInfo->X == 0 || state->pixelInfo->Y == 0 ||
		    state->pixelInfo->Z == 0 || state->pixelInfo->C == 0 ||
		    state->pixelInfo->T == 0 || state->pixelInfo->dimOrder == NULL ||
		    state->pixelInfo->pixelType == NULL || state->pixelInfo->bigEndian == -1 ) {
			fprintf( stderr, "Error! Pixels element does not have all required attributes!\n" );
			assert( state->pixelInfo->X != 0 && state->pixelInfo->Y != 0 &&
			        state->pixelInfo->Z != 0 && state->pixelInfo->C != 0 &&
		            state->pixelInfo->T != 0 && state->pixelInfo->dimOrder != NULL &&
		            state->pixelInfo->pixelType != NULL && state->pixelInfo->bigEndian != -1
			);
		}
		
		/* look up info for this pixel type */
		for( i=0; pixelTypes[i] != NULL; i++ ) {
			if( strcmp( state->pixelInfo->pixelType, pixelTypes[i] ) == 0 ) {
				state->pixelInfo->bpp = bytesPerPixel[i];
				state->pixelInfo->isSigned = typeIsSigned[i];
				state->pixelInfo->isFloat = typeIsFloat[i];
				break;
			}
		}
		if( pixelTypes[i] == NULL ) {
			fprintf( stderr, "Error! unknown or unsupported PixelType (%s)\n", state->pixelInfo->pixelType );
			assert( pixelTypes[i] != NULL);
		}
		
		/*
		* END "Extract data from xml attributes."
		*
		**********************************************************************/
		
		/**********************************************************************
		*
		* Initialization for <BinData> processing.
		* 	remember that we do not know if this <Pixels> contains <BinData>s
		* 	or <External>s. We will not use any of this if the <Pixels> 
		* 	contains <External>s.
		*
		*/
		/* initialize variables */
		state->pixelInfo->theZ = state->pixelInfo->theC = state->pixelInfo->theT = 0;
		state->pixelInfo->hitBinData = 0;
		
		/* initialize object to write pixels */
		state->nOutputFiles++;
		state->pixelInfo->pixWriter = NewPixels (
			state->pixelInfo->X,
			state->pixelInfo->Y,
			state->pixelInfo->Z,
			state->pixelInfo->C,
			state->pixelInfo->T,
			state->pixelInfo->bpp,
			state->pixelInfo->isSigned,
			state->pixelInfo->isFloat );
		if ( state->pixelInfo->pixWriter == NULL ) {
			fprintf( stderr, "Error! NewPixels returned NULL!\n" );
			assert ( state->pixelInfo->pixWriter != NULL );
		}
		

		state->pixelInfo->planeSize = state->pixelInfo->X * state->pixelInfo->Y * (int) state->pixelInfo->bpp;
		state->pixelInfo->binDataBuf = (unsigned char *) malloc( state->pixelInfo->planeSize + 2);
		assert( state->pixelInfo->binDataBuf != NULL);
		/*
		* END "Initialization for <BinData> processing."
		*
		**********************************************************************/

	}
	/*
	*	END "Pixels"
	*
	**************************************************************************/



	/**************************************************************************
	*
	* BinFile
	* 
	*/
	else if( strcmp( BinFileLocal, localName ) == 0 ) {
		state->state = IN_BINFILE;

		/* Extract data from xml attributes. */
		if(attrs == NULL) {
			fprintf( stderr, "Error! BinFile element has no attributes!\n" );
			assert(-1);
		}
		state->BinFileInfo.size = 0;
		*(state->BinFileInfo.name) = 0;
		for( i=0; attrs[i] != NULL; i+=2 ) {
			if( strcmp( attrs[i], "Size" ) == 0 ) {
				state->BinFileInfo.size = (off_t) atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "FileName" ) == 0 ) {
				strcpy( state->BinFileInfo.name, attrs[i+1] );
			}
		}

		/* Request new File */
/*		state->BinFileInfo.fd = NewFile (&( state->BinFileInfo.ID ),state->BinFileInfo.name,state->BinFileInfo.size);
		if (state->BinFileInfo.fd < 0) {
			fprintf( stderr, "Couldn't get a repository file.");
			assert(state->BinFileInfo.fd >= 0);
		}
		state->nOutputFiles++;
*/
		/* establish memory map to file */
/*		if ( (state->BinFileInfo.sh_mmap = (unsigned char *)mmap (NULL, state->BinFileInfo.size, PROT_READ|PROT_WRITE , MAP_SHARED, state->BinFileInfo.fd, 0)) <= 0 ) {
			close (state->BinFileInfo.fd);
			DeleteFile (state->BinFileInfo.ID);
			fprintf (stderr,"Couldn't mmap file %s (ID=%llu)\n",state->BinFileInfo.name,state->BinFileInfo.ID);
			return (-1);
		}
*/		
	}
	/*
	*	END "BinFile"
	*
	**************************************************************************/


	/* FIXME: add External resolution here using curl libraries */


	/**************************************************************************
	*
	* Pipe the element through
	*/
	if(	pipeThisElementThrough == 1 ) {
		/* Stack maintence. Necessary for closing tags properly. */
		elementInfo             = (StructElementInfo *) malloc( sizeof(StructElementInfo) );
		assert( elementInfo != NULL);
		elementInfo->hasContent = 0;
		elementInfo->prev       = state->elementInfo;
		elementInfo->tagOpen    = 1;
		state->elementInfo      = elementInfo;

		print_element( name, attrs );
		
		/* print BinFile's FileID */
		if( strcmp( BinFileLocal, localName ) == 0 ) {
			fprintf( stdout, "ID = \"%llu\" ", state->BinFileInfo.FileID );
		} else if( strcmp( PixelLocal, localName ) == 0 ) {
			fprintf( stdout, "ImageServerID = \"%llu\" ", state->pixelInfo->pixWriter->ID );
		}
	}
	/*
	**************************************************************************/


} /* END OME_StartElement */



static void OME_EndElement(ParserState *state, const xmlChar *name) {
	/* We're at the end of an element. If the element had content, then we
	/ need to print "</[elementName]>". If the element did not have 
	/ content, then we need to print "/>". I'm using a stack to keep track
	/ of element's content, so I gotta check the stack and do stack 
	/ maintence.
	/ Iff we are ending a BinData section, then we don't have to touch the
	/ stack.
	*/
	StructElementInfo *elementInfo;
	size_t nPix;
	int result;

	switch( state->state ) {
	
	
	/**************************************************************************
	*
	* Process <BinData>
	* 	write <BinData> contents to file & replace <BinData> with an
	* 	<External> that points to the file
	*/
	 case IN_BINDATA:
		state->state = PARSER_START;
		
		/* cleanup */
		b64z_decode_end ( state->binDataInfo->strm );
		free( state->binDataInfo->strm );
		state->binDataInfo->strm = NULL;
		
		if( state->binDataInfo->compression ) free( state->binDataInfo->compression );
		state->binDataInfo->compression = NULL;
		fclose( state->binDataInfo->BinDataOut );
		state->binDataInfo->BinDataOut = NULL;

/* omeis transition: replace href with file id 
		fprintf( stdout, "<External xmlns=\"%s\" href=\"%s\" SHA1=\"\"/>", BinNS, state->pixelInfo->outputPath );
*/
		break;

	/*
	* END 'Process <BinData>'
	*
	**************************************************************************/



	/**************************************************************************
	*
	* Process <BinData> inside of <Pixels>
	*
	*/
	  case IN_BINDATA_UNDER_PIXELS:
		state->state = IN_PIXELS;
		
		/* Endian check */
		if( state->pixelInfo->bigEndian != bigEndian() &&
			state->pixelInfo->bpp > 1 )
			byteSwap( state->pixelInfo->binDataBuf, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y, state->pixelInfo->bpp );
			
		/* write a buffered Pixel's plane */
		nPix = setPixelPlane(
			state->pixelInfo->pixWriter, 
			state->pixelInfo->binDataBuf, 
			state->pixelInfo->theZ, 
			state->pixelInfo->theC, 
			state->pixelInfo->theT );
		if( (unsigned int) nPix * state->pixelInfo->bpp != state->pixelInfo->planeSize ) {
			fprintf( stderr, "Error! tried to write a plane. expected to write %u bytes, actually wrote %u bytes!\n", state->pixelInfo->planeSize, (unsigned int) nPix );
			assert((unsigned int) nPix * state->pixelInfo->bpp == state->pixelInfo->planeSize);
		}

	 	/* logic to increment indexes based on dimOrder */
	 	if( strcmp( state->pixelInfo->dimOrder, "XYZCT" ) == 0 ) {
			increment_plane_indexes( 
				&( state->pixelInfo->theZ ), 
				&( state->pixelInfo->theC ), 
				&( state->pixelInfo->theT ),
				state->pixelInfo->Z, 
				state->pixelInfo->C, 
				state->pixelInfo->T 
			);
		} else if( strcmp( state->pixelInfo->dimOrder, "XYZTC" ) == 0 ) {
			increment_plane_indexes(
				&( state->pixelInfo->theZ ),
				&( state->pixelInfo->theT ),
				&( state->pixelInfo->theC ),
				state->pixelInfo->Z,
				state->pixelInfo->T,
				state->pixelInfo->C
			);
		} else if( strcmp( state->pixelInfo->dimOrder, "XYTZC" ) == 0 ) {
			increment_plane_indexes(
				&( state->pixelInfo->theT ),
				&( state->pixelInfo->theZ ),
				&( state->pixelInfo->theC ),
				state->pixelInfo->T,
				state->pixelInfo->Z,
				state->pixelInfo->C
			);
		} else if( strcmp( state->pixelInfo->dimOrder, "XYTCZ" ) == 0 ) {
			increment_plane_indexes(
				&( state->pixelInfo->theT ),
				&( state->pixelInfo->theC ),
				&( state->pixelInfo->theZ ),
				state->pixelInfo->T,
				state->pixelInfo->C,
				state->pixelInfo->Z
			);
		} else if( strcmp( state->pixelInfo->dimOrder, "XYCZT" ) == 0 ) {
			increment_plane_indexes(
				&( state->pixelInfo->theC ),
				&( state->pixelInfo->theZ ),
				&( state->pixelInfo->theT ),
				state->pixelInfo->C,
				state->pixelInfo->Z,
				state->pixelInfo->T
			);
		} else if( strcmp( state->pixelInfo->dimOrder, "XYCTZ" ) == 0 ) {
			increment_plane_indexes(
				&( state->pixelInfo->theC ),
				&( state->pixelInfo->theT ),
				&( state->pixelInfo->theZ ),
				state->pixelInfo->C,
				state->pixelInfo->T,
				state->pixelInfo->Z
			);
		}
				

		/* cleanup */
		b64z_decode_end( state->binDataInfo->strm );
		free( state->binDataInfo->strm );
		state->binDataInfo->strm = NULL;

		if( state->binDataInfo->compression ) free( state->binDataInfo->compression );
		state->binDataInfo->compression = NULL;

	 	break;
	/*
	* END 'Process <BinData> inside of <Pixels>'
	*
	**************************************************************************/


	 case IN_PIXELS:
		state->state = PARSER_START;

		/* close pixelsRep object & clean it up */
		if ( (result = FinishPixels( state->pixelInfo->pixWriter, 0 )) == 0 ) {
			fprintf(stderr, "Error calling FinishPixels: result = %d\n",result);
			if (errno) fprintf (stderr,"%s\n",strerror( errno ) );
			assert(0);
		}

		fprintf( stdout,  " FileSHA1 = \"" );
		print_md( state->pixelInfo->pixWriter->head->sha1 );
		fprintf( stdout,  "\"" );
		

	 	/* cleanup */
	 	freePixelsRep (state->pixelInfo->pixWriter);
		free( state->pixelInfo->binDataBuf );
		free( state->pixelInfo->dimOrder );
		free( state->pixelInfo->pixelType );
		free( state->pixelInfo );
		state->pixelInfo = NULL;

	 	/* DO NOT "break;" Go on to default action of stack cleanup and
	 	/ element closure.
	 	*/

	 default:
		/* Stack maintence */
		if( state->elementInfo != NULL ) {
			elementInfo = state->elementInfo;
			state->elementInfo = elementInfo->prev;
			if( elementInfo->hasContent == 0 ) {
				fprintf( stdout, "/>" );
			} else {
				fprintf( stdout, "</%s>", name );
			}
			free( elementInfo );
		}
	}
	

} /* END OME_EndElement */



static void OME_Characters(ParserState *state, const xmlChar *ch, int len) {
	unsigned char * buf;
	int rC;
	size_t outLen, writtenOut;
	
	
	/* The tag begun by OME_StartElement might be open. If so, we 
	/ need to close it so we can print the character contents of this element.
	*/
	if( state->elementInfo != NULL && state->state != IN_PIXELS && state->state != IN_BINDATA_UNDER_PIXELS) {
		state->elementInfo->hasContent = 1;
		if( state->elementInfo->tagOpen == 1 ) {
			fprintf( stdout, ">" );
			state->elementInfo->tagOpen = 0;
		}
	}

	/* The character data needs to be streamed out. 
	/ This switch directs the flow.
	*/
	switch( state->state ) {
	 case IN_PIXELS:
	 	/* only <BinData> and white space lives in <Pixels>. Neither should be printed */
	 	break;
	 case PARSER_START:
		fwrite( ch, 1, len, stdout );
		fflush( stdout );
		break;
	 case IN_BINDATA:
	 	state->binDataInfo->strm->next_in   = (unsigned char *)ch;
	 	state->binDataInfo->strm->avail_in  = len;

		buf = (unsigned char *) malloc( SIZEOF_FILE_OUT_BUF );
		assert( buf != NULL);
		
	 	state->binDataInfo->strm->next_out  = buf;
	 	state->binDataInfo->strm->avail_out = SIZEOF_FILE_OUT_BUF;
	 	
	 	do {
		 	rC = b64z_decode( state->binDataInfo->strm );
/* omeis transition: replace with file write method call */
			/* write out to file & reset output buffers */
			outLen = SIZEOF_FILE_OUT_BUF - state->binDataInfo->strm->avail_out;
			writtenOut = fwrite( buf, 1, outLen, state->binDataInfo->BinDataOut );
			if( writtenOut != outLen ) {
				fprintf( stderr, "Error! Could not write full output to file! Wrote %u, expected %u.\n", (unsigned int) writtenOut, (unsigned int) outLen );
				assert(writtenOut == outLen);
			}
	
			state->binDataInfo->strm->avail_out = SIZEOF_FILE_OUT_BUF;
			state->binDataInfo->strm->next_out  = buf;
		} while( rC != B64Z_STREAM_END );
		free( buf );
		
		break;
	 	
	 case IN_BINDATA_UNDER_PIXELS:
	 	state->binDataInfo->strm->next_in   = (unsigned char *)ch;
	 	state->binDataInfo->strm->avail_in  = len;

	 	do {
		 	rC = b64z_decode( state->binDataInfo->strm );
		 	if( state->binDataInfo->strm->avail_out == 0 && rC != B64Z_STREAM_END ) {
		 		fprintf( stderr, "Error! Uncompressed contents of a <BinData> under <Pixels> are larger than the size of a plane.\n" );
		 		assert(state->binDataInfo->strm->avail_out != 0 || rC == B64Z_STREAM_END);
		 	}
		} while( rC != B64Z_STREAM_END );
		
		break;
	  default: /* default should never get used */
		break;
	} /* switch( state->state ) */
}

/******************************************************************************
*
*	Error routines (SAX callbacks):
*
*	These are supposed to pipe the error output from SAX through to stderr.
*	They don't work completely. The last argument in the function prototype is 
*	", ...". I don't know how to access the variables passed on it through to
*	the fprintf statement. 
*	http://www.daa.com.au/~james/articles/libxml-sax/libxml-sax.html#errors
*	has an example that uses glib logging functions, but I couldn't figure out
*	how to adapt that code.
*
******************************************************************************/
static void BinDataWarning( ParserState *state, const char *msg ) {
	fprintf( stderr, "The SAX parser reports this warning message:\n%s\nParser is in state: %i\n", msg, state->state );
}
static void BinDataError( ParserState *state, const char *msg ) {
	fprintf( stderr, "Terminating program. The SAX parser reports this error message:\n%s\nParser is in state: %i\n", msg, state->state );
	assert( 0 );
}
static void BinDataFatalError( ParserState *state, const char *msg ) {
	fprintf( stderr, "Terminating program. The SAX parser reports this *FATAL* error message:\n%s\nParser is in state: %i\n", msg, state->state );
	assert( 0 );
	return;
}

