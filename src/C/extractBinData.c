/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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

	extractBinData.c
	
	Originally written: May 16, 2003
	
****

	Intent: The intent of this program is to extract the contents of <BinData>
	from an xml document following the OME schema AND replace the 
	<BinData>...</BinData> element with an <External .../> element.

	Usage: Execute the program with no parameters to see the usage message.

	Libraries: This program uses libxml2's SAX library. SAX is a stream based
	xml parser, so memory usage DOES NOT inflate when file size inflates. 
	YOU MUST INSTALL libxml2 BEFORE THIS WILL COMPILE.
	Memory usage on initial tests was the same for a 100 Meg and a 1 Gig file.

	Behavior: The modified xml document will be spewed to stdout. <BinData>s 
	under <Pixels> will be coalated into a repository style pixel dump and put
	in the pixels directory. All other <BinData>s will be spewed to the scratch
	directory. The extracted BinData contents will be spewed to 
	separate files (1 per BinData) in that directory. See Usage for more 
	information about the directory. The path to the extracted file will be
	specified in the href attribute of the <External> element that replaces the
	<BinData> element. The <External> tag will look like this:
		<External xmlns="BinNS" href="path/to/local/file" SHA1=""/>
	Notice it is missing the SHA1 attribute. That will distiguish these 
	converted BinData elements from normal <External> elements. The path 
	specified in href will be an absolute path iff this program is passed
	an absolute path to a scratch space. I highly recommend using an absolute
	path. The namespace, "BinNS" is a #defined constant. Look in the define 
	section below to see what it will evaluate to.
	If the Compression attribute is not specified in <BinData>, it is assumed 
	to use no compression.

	Compilation notes: Use the xml2-config utility to find the location of the
	libxml2 libraries. The flags --libs and --cflags cause xml2-config to 
	produce the proper flags to pass to the compiler. The one line compilation
	command is:

		gcc `xml2-config --libs --cflags` -I/sw/include/ -L/sw/lib/ -lz -lbz2 \
		-ltiff extractBinData.c base64.c ../perl2/OME/Image/Pix/libpix.c \
		b64z_lib.c -o extractBinData


******************************************************************************/


#include <libxml/parser.h>
#include <zlib.h>
#include <bzlib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "base64.h"
#include "b64z_lib.h"
#include "../perl2/OME/Image/Pix/libpix.h"

/******************************************************************************
*
*	Data structures & Constants
*
******************************************************************************/
#define BinDataLocal "BinData"
#define PixelLocal "Pixels"
#define ImageLocal "Image"
#define CompressionAttr "Compression"
#define BinNS "http://www.openmicroscopy.org/XMLschemas/BinaryFile/RC1/BinaryFile.xsd"
#define SIZEOF_FILE_OUT_BUF 1048576
const char *pixelTypes[] = { "bit", "int8", "int16", "int32", "Uint8", "Uint16", "Uint32", "float", "double", "complex", "double-complex", NULL };
const int bitsPerPixel[] = {  1,      8,     16,      32,      8,       16,       32,       32,      64,       64,        128            , 0 };

/* This is a stack to store information about an element. It keeps track of
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
	FILE *BinDataOut;
	char *compression;
	b64z_stream *strm;
} BinDataInfo;

/* Possible states */
typedef enum {
	PARSER_START,
	IN_BINDATA,
	IN_PIXELS,
	IN_BINDATA_UNDER_PIXELS,
} PossibleParserStates;

/* <Pixels> info */
typedef struct {
	/* dimensions of pixel array. C is channels. bpp is "bits per pixel" */
	int X,Y,Z,C,T,bpp;
	/* indexes to store current plane */
	int theZ, theC, theT;
	int bigEndian;
	char *dimOrder;
	/* pixelType is not strictly needed. maybe it will come in handy in a later incarnation of this code */
	char *pixelType;
	/* outputPath stores the path the coallated <BinData>s will reside. */
	char *outputPath;
	int hitBinData;
	unsigned char *binDataBuf;
	unsigned int planeSize;
	Pix *pixWriter;
} PixelInfo;

/* <Image> info */
typedef struct {
	/* dimensions of pixel array. This may be overridden by dimensions in <Pixels> */
	int X,Y,Z,C,T,bpp;
} ImageInfo;	

/* Contains all the information about the parser's state */
typedef struct {
	PossibleParserStates state;
	int nOutputFiles;
	PixelInfo *pixelInfo;
	ImageInfo imageInfo;
	StructElementInfo* elementInfo;
	BinDataInfo *binDataInfo;
} ParserState;

/******************************************************************************
*
*	Functions Declarations:
*
******************************************************************************/

/* SAX callbacks: */
static void extractBinDataStartDocument(ParserState *state );
static void extractBinDataEndDocument( ParserState *state );
static void extractBinDataStartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs);
static void extractBinDataEndElement(ParserState *state, const xmlChar *name);
static void extractBinDataCharacters(ParserState *state, const xmlChar *ch, int len);
static void BinDataWarning( ParserState *state, const char *msg );
static void BinDataError( ParserState *state, const char *msg );
static void BinDataFatalError( ParserState *state, const char *msg );

/* Utility functions: */
int parse_xml_file(const char *filename);
void print_element(const xmlChar *name, const xmlChar **attrs);
int increment_plane_indexes( int* a, int* b, int* c, int aMax, int bMax, int cMax );
void mem_error( char*msg );

/******************************************************************************
*
*	main & global data
*
******************************************************************************/
char *dirPath;
char *pixelDirPath;

int main(int ARGC, char **ARGV) {
	char *filePath;
	
	/* program called with improper usage. print usage message. */
	if( ARGC != 4 ) {
		fprintf( stdout, "Usage is:\n\t./extractBinData [pixel scratch directory] [scratch directory] [OME XML document to process]\n" );
		fprintf( stdout, "\n\n\t[pixel scratch directory] is an absolute path to a directory to output pixel files in repository format. For good performance, that scratch space should be on the same file system as the repository. This program will NOT clean up after itself, so clean its sandbox after use.\n\t[scratch directory]: Files extracted from <BinData>s not belonging to <Pixels> will be written here. This also needs to be an absolute path.\n" );
		return -1;
	}

	
	pixelDirPath = ARGV[1];
	dirPath      = ARGV[2];
	filePath     = ARGV[3];
	parse_xml_file(filePath);
	
	return 0;
}



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
	xmlSAXHandler extractBinDataSAXParser = {
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
		(startDocumentSAXFunc)extractBinDataStartDocument, /* startDocument */
		(endDocumentSAXFunc)extractBinDataEndDocument, /* endDocument */
		(startElementSAXFunc)extractBinDataStartElement, /* startElement */
		(endElementSAXFunc)extractBinDataEndElement, /* endElement */
		0, /* reference */
		(charactersSAXFunc)extractBinDataCharacters, /* characters */
		0, /* ignorableWhitespace */
		0, /* processingInstruction */
		0, /* comment */
		(warningSAXFunc)BinDataWarning, /* warning */
		(errorSAXFunc)BinDataError, /* error */
		(fatalErrorSAXFunc)BinDataFatalError, /* fatalError */
	};

	if (xmlSAXUserParseFile(&extractBinDataSAXParser, &my_state, filename) < 0) {
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

void mem_error( char*msg ) { 
	fprintf( stderr, "Error! unable to allocate memory in extractBinData.c\n%s", msg );
	exit(-1);
}

/******************************************************************************
*
*	SAX callback functions
*
******************************************************************************/

static void extractBinDataStartDocument(ParserState *state) {

	state->state	               = PARSER_START;
	state->nOutputFiles            = 0;
	state->elementInfo             = NULL;
	state->binDataInfo             = (BinDataInfo *) malloc( sizeof( BinDataInfo ) );
	if( !( state->binDataInfo ) ) mem_error( "" );

	state->binDataInfo->BinDataOut    = NULL;
	state->binDataInfo->strm = NULL;
	
}

static void extractBinDataEndDocument( ParserState *state ) {
	free( state->binDataInfo );
}


static void extractBinDataStartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs) {
	char *localName, *binDataOutPath;
	StructElementInfo* elementInfo;
	int i, pipeThisElementThrough;
	
	pipeThisElementThrough = 1;

	/* mark that the last open element has content, namely this element */
	if( state->elementInfo != NULL ) {
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
					state->binDataInfo->compression = (char *) malloc( strlen(attrs[i+1]) + 1);
					if( !(state->binDataInfo->compression) ) mem_error("");
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

		/* This <BinData> is not under <Pixels>
		/ 	It needs to be piped to a file & replaced with an <External>
		/ 	This data needs to be converted from base64 & possibly
		/ 	decompressed. 
		*/
		else {
			state->state      = IN_BINDATA;
			state->nOutputFiles++;
			
			/* open the output file for the BinData contents */
			binDataOutPath = (char *) malloc( 
				strlen( dirPath ) + 
				strlen( "/" ) +
				( (int) state->nOutputFiles % 10 ) + 1 +
				strlen( ".out" ) +
				1 );
			if( !binDataOutPath ) mem_error("");
			sprintf( binDataOutPath, "%s/%i.out", dirPath, state->nOutputFiles );
			state->binDataInfo->BinDataOut = fopen( binDataOutPath, "w" );
			if( state->binDataInfo->BinDataOut == NULL ) {
				fprintf( stderr, "Error! Could not open file for output. Path is\n%s\n", binDataOutPath );
				exit(-1);
			}
	
			/* convert BinData to External */
			fprintf( stdout, "<External xmlns=\"%s\" href=\"%s\" SHA1=\"\"/>", BinNS, binDataOutPath );
			
			free( binDataOutPath );
		}
	}
	/*
	**************************************************************************/


	/**************************************************************************
	*
	* Image:
	* 	nab the pixel array dimensions from Image. That is the default size 
	* 	of <Pixels>.
	*/
	else if( strcmp( ImageLocal, localName ) == 0 ) {
		state->imageInfo.X = state->imageInfo.Y = state->imageInfo.Z = state->imageInfo.C = state->imageInfo.T = 0;
		for( i=0; attrs[i] != NULL; i+=2 ) {
			if( strcmp( attrs[i], "SizeX" ) == 0 ) {
				state->imageInfo.X = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "SizeY" ) == 0 ) {
				state->imageInfo.Y = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "SizeZ" ) == 0 ) {
				state->imageInfo.Z = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "NumChannels" ) == 0 ) {
				state->imageInfo.C = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "NumTimes" ) == 0 ) {
				state->imageInfo.T = atoi( attrs[i+1] );
			}
		}
		
		/* error check: verify we have all needed attributes */
		if( state->imageInfo.X == 0 || state->imageInfo.Y == 0 ||
		    state->imageInfo.Z == 0 || state->imageInfo.C == 0 ||
		    state->imageInfo.T == 0 ) {
			fprintf( stderr, "Error! <Image> does not have all required attributes!\n" );
			exit(-1);
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
		if( !(state->pixelInfo) ) mem_error("");
		if(attrs == NULL) {
			fprintf( stderr, "Error! Pixels element has no attributes!\n" );
			exit(-1);
		}
		state->pixelInfo->X = state->imageInfo.X;
		state->pixelInfo->Y = state->imageInfo.Y;
		state->pixelInfo->Z = state->imageInfo.Z;
		state->pixelInfo->C = state->imageInfo.C;
		state->pixelInfo->T = state->imageInfo.T;
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
				state->pixelInfo->dimOrder = (char *) malloc( strlen(attrs[i+1]) + 1 );
				if( !(state->pixelInfo->dimOrder) ) mem_error("");
				strcpy( state->pixelInfo->dimOrder, attrs[i+1] );
			} else if( strcmp( attrs[i], "PixelType" ) == 0 ) {
				state->pixelInfo->pixelType = (char *) malloc( strlen(attrs[i+1]) + 1 );
				if( !(state->pixelInfo->pixelType) ) mem_error("");
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
			exit(-1);
		}
		
		/* look up bpp for this pixel type */
		state->pixelInfo->bpp = 0;
		for( i=0; pixelTypes[i] != NULL; i++ ) {
			if( strcmp( state->pixelInfo->pixelType, pixelTypes[i] ) == 0 ) {
				state->pixelInfo->bpp = bitsPerPixel[i];
				break;
			}
		}
		if( state->pixelInfo->bpp == 0 ) {
			fprintf( stderr, "Error! unknown PixelType (%s)\n", state->pixelInfo->pixelType );
		}
		
		/* I don't know how to deal with binary images for now, so I'm going
		/ to barf if the pixelType is "bit"
		*/
		if( strcmp( state->pixelInfo->pixelType, "bit" ) == 0 ) {
			fprintf( stderr, "Error! pixelType 'bit' is not supported yet!\n" );
			exit(-1);
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
		
		/* initialize libpix object - DON'T FORGET BIG ENDIAN! */
		state->nOutputFiles++;
		state->pixelInfo->outputPath = (char *) malloc( 
			strlen( pixelDirPath ) + 
			strlen( "/" ) +
			( (int) state->nOutputFiles % 10 ) + 1 +
			strlen( ".out" ) +
			1 );
		if( !(state->pixelInfo->outputPath) ) mem_error("");
		sprintf( state->pixelInfo->outputPath, "%s/%i.out", pixelDirPath, state->nOutputFiles );
		state->pixelInfo->pixWriter = NewPix(
			state->pixelInfo->outputPath,
			state->pixelInfo->X,
			state->pixelInfo->Y,
			state->pixelInfo->Z,
			state->pixelInfo->C,
			state->pixelInfo->T,
			state->pixelInfo->bpp / 8
		);

		state->pixelInfo->planeSize = state->pixelInfo->X * state->pixelInfo->Y * (int) (state->pixelInfo->bpp / 8 );
		state->pixelInfo->binDataBuf = (unsigned char *) malloc( state->pixelInfo->planeSize + 2);
		if( !(state->pixelInfo->binDataBuf) ) mem_error("");
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
	* Pipe the element through
	*/
	if(	pipeThisElementThrough == 1 ) {
		/* Stack maintence. Necessary for closing tags properly. */
		elementInfo             = (StructElementInfo *) malloc( sizeof(StructElementInfo) );
		if( !(elementInfo) ) mem_error("");
		elementInfo->hasContent = 0;
		elementInfo->prev       = state->elementInfo;
		elementInfo->tagOpen    = 1;
		state->elementInfo      = elementInfo;

		print_element( name, attrs );
	}
	/*
	**************************************************************************/


} /* END extractBinDataStartElement */



static void extractBinDataEndElement(ParserState *state, const xmlChar *name) {
	/* We're at the end of an element. If the element had content, then we
	/ need to print "</[elementName]>". If the element did not have 
	/ content, then we need to print "/>". I'm using a stack to keep track
	/ of element's content, so I gotta check the stack and do stack 
	/ maintence.
	/ Iff we are ending a BinData section, then we don't have to touch the
	/ stack.
	*/
	StructElementInfo *elementInfo;
	char *localName;

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
		if( state->pixelInfo->bigEndian != bigEndian() )
			switch( state->pixelInfo->bpp ) {
			 case 8:
				break;
			 case 16:
				byteSwap2( state->pixelInfo->binDataBuf, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y );
				break;
			 case 32:
				byteSwap4( state->pixelInfo->binDataBuf, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y );
				break;
			 case 64:
				byteSwap8( state->pixelInfo->binDataBuf, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y );
				break;
			 case 128:
				byteSwap16( state->pixelInfo->binDataBuf, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y );
				break;
			 default:
				fprintf( stderr, "Error! invalid bpp specified in <Pixels>!\n" );
				exit(-1);
				break;
			}

		/* output buffered BinData through libpix */
		SetPlane( 
			state->pixelInfo->pixWriter, 
			state->pixelInfo->binDataBuf, 
			state->pixelInfo->theZ, 
			state->pixelInfo->theC, 
			state->pixelInfo->theT );

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

	 	/* print the <External> element if we extracted <BinData>s */
		if( state->pixelInfo->hitBinData == 1 )
			fprintf( stdout, "<External xmlns=\"%s\" href=\"%s\" SHA1=\"\"/>", BinNS, state->pixelInfo->outputPath );

		/* close libpix object, clean it up */
		FreePix( state->pixelInfo->pixWriter );

	 	/* cleanup */
		free( state->pixelInfo->binDataBuf );
		free( state->pixelInfo->dimOrder );
		free( state->pixelInfo->pixelType );
		free( state->pixelInfo->outputPath );
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
	

	/**************************************************************************
	*
	* Image:
	* 	Reset indexes
	*/
	/**************************************************************************
	*
	* Getting the namespace for an element is tricky. I haven't figured out 
	* how to do it yet, so I'm using the local name (BinData) to identify the
	* element.
	* I think http://cvs.gnome.org/lxr/source/gnorpm/find/search.c might have
	* some code that will do it.
	* Find the local name of the element: strip the prefix if one exists.
	*/
	localName = strchr( name, ':' );
	if( localName != NULL )
		localName++;
	else
		localName = (char *)name;

	if( strcmp( ImageLocal, localName ) == 0 )
		state->imageInfo.X = state->imageInfo.Y = state->imageInfo.Z = state->imageInfo.C = state->imageInfo.T = 0;
	/*
	**************************************************************************/


} /* END extractBinDataEndElement */



static void extractBinDataCharacters(ParserState *state, const xmlChar *ch, int len) {
	unsigned char * buf;
	int rC;
	size_t outLen;
	
	
	/* The tag begun by extractBinDataStartElement might be open. If so, we 
	/ need to close it so we can print the character contents of this element.
	*/
	if( state->elementInfo != NULL ) {
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
	 case PARSER_START:
		fwrite( ch, 1, len, stdout );
		fflush( stdout );
		break;
	 case IN_BINDATA:
	 	state->binDataInfo->strm->next_in   = (unsigned char *)ch;
	 	state->binDataInfo->strm->avail_in  = len;

		buf = (unsigned char *) malloc( SIZEOF_FILE_OUT_BUF );
		if( !buf ) mem_error("");
		
	 	state->binDataInfo->strm->next_out  = buf;
	 	state->binDataInfo->strm->avail_out = SIZEOF_FILE_OUT_BUF;
	 	
	 	do {
		 	rC = b64z_decode( state->binDataInfo->strm );
			/* write out to file & reset output buffers */
			outLen = SIZEOF_FILE_OUT_BUF - state->binDataInfo->strm->avail_out;
			if( fwrite( buf, 1, outLen, state->binDataInfo->BinDataOut ) != outLen ) {
				fprintf( stderr, "Error! Could not write full output to file!\n" );
				exit(-1);
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
		 		exit(-1);
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
	fprintf( stderr, "The SAX parser reports this warning message:\n%s", msg );
}
static void BinDataError( ParserState *state, const char *msg ) {
	fprintf( stderr, "Terminating program. The SAX parser reports this error message:\n%s", msg );
	exit(-1);
}
static void BinDataFatalError( ParserState *state, const char *msg ) {
	fprintf( stderr, "Terminating program. The SAX parser reports this *FATAL* error message:\n%s", msg );
	exit(-1);
}

