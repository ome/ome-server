/******************************************************************************
*
*	insertBinData.c
*	
*	Originally written: ~ May 18, 2003
*	Standard licence blurb:

 Copyright (C) 2003 Open Microscopy Environment, MIT
 Author:  Josiah Johnston <siah@nih.gov>

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

****

	Intent: The intent of this program is to process an OME xml document,
	replacing <External .../> elements with <BinData>...</BinData> elements.

	Usage: Execute the program with no parameters to see the usage message.

	Libraries: This program uses libxml2's SAX library. SAX is a stream based
	xml parser, so memory usage DOES NOT inflate when file size inflates. 
	YOU MUST INSTALL libxml2 BEFORE THIS WILL COMPILE.
	Memory usage on initial tests was the same for a 100 Meg and a 1 Gig file.

	Behavior: The modified xml document will be spewed to stdout. <External>s 
	to be replaced are flagged by an empty SHA1 attribute. To target an
	<External> under <Pixels>, place exactly ONE <External> inside <Pixels>.
	This <External> will be replaced with <BinData>s, one per plane.
	So, 
		<Pixels...>...
			<External xmlns="BinNS" href="/path/to/repository/file" SHA1=""/>
		</Pixels>
	becomes
		<Pixels...>...
			<BinData xmlns="BinNS" ...>...</BinData>
			<BinData xmlns="BinNS" ...>...</BinData>
			<BinData xmlns="BinNS" ...>...</BinData>
			...
		</Pixels>
	If the Compression attribute is specified in <External>, then that 
	Compression will be used by the <BinData>(s) that replaces it. If 
	Compression is not specified, the default behavior is to use no 
	compression.
	The namespace, "BinNS" is a #defined constant. Look in the define 
	section below to see what it will evaluate to.
	The <BinData>s that are implanted will be converted (if necessary) to the
	endian specified in <Pixels>. 

	Compilation notes: Use the xml2-config utility to find the location of the
	libxml2 libraries. The flags --libs and --cflags cause xml2-config to 
	produce the proper flags to pass to the compiler. The one line compilation
	command is:

		gcc `xml2-config --libs --cflags` -I/sw/include/ -L/sw/lib/ -lbz2 \
		-ltiff insertBinData.c base64.c ../perl2/OME/Image/Pix/libpix.c \
		b64z_lib.c -o insertBinData

*
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
*****************************************************************************/
#define ExternalLocal "External"
#define PixelLocal "Pixels"
#define CompressionAttr "Compression"
#define BinNS "http://www.openmicroscopy.org/XMLschemas/BinaryFile/RC1/BinaryFile.xsd"
#define SIZEOF_BUFS 1048576
const char *pixelTypes[] = { "bit", "int8", "int16", "int32", "Uint8", "Uint16", "Uint32", "float", "double", "complex", "double-complex", NULL };
const int bitsPerPixel[] = {  1,      8,     16,      32,      8,       16,       32,       32,      64,       64,        128            , NULL };

/* This is a stack to store information about an XML element. It keeps track of
/ whether an element has content or is empty AND
/ whether the opening tag of the element is open (e.g. "<foo" is open, 
/ "<foo>" and "<foo/>" are not). It is used for every element except BinData.
*/
typedef struct _elementInfo {
	int hasContent;
	int tagOpen;
	struct _elementInfo *prev;
} StructElementInfo;

/* Possible states */
typedef enum {
	PARSER_START,
	IN_FLAGGED_EXTERNAL,
	IN_PIXELS,
	IN_FLAGGED_EXTERNAL_UNDER_PIXELS,
} PossibleParserStates;

/* <Pixels> info */
typedef struct {
	/* dimensions of pixel array. C is channels. bpp is "bits per pixel" */
	int X,Y,Z,C,T,bpp;
	int bigEndian;
	char *dimOrder;
	/* pixelType is not strictly needed. maybe it will come in handy in a later incarnation of this code */
	char *pixelType;
} PixelInfo;

/* Contains all the information about the parser's state */
typedef struct {
	PossibleParserStates state;
	PixelInfo *pixelInfo;
	StructElementInfo* elementInfo;
} ParserState;

/******************************************************************************
*
*	Functions Declarations:
*
******************************************************************************/

/* SAX callbacks: */
static void extractBinDataStartDocument(ParserState *state);
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
	if( ARGC != 2 ) {
		fprintf( stdout, "Usage is:\n\t./insertBinData [OME XML document to process]\n" );
		return -1;
	}

	filePath     = ARGV[1];
	parse_xml_file(filePath);
	
	return 0;
}



/******************************************************************************
*
*	Utility Functions:
*
******************************************************************************/


int parse_xml_file(const char *filename) {
    ParserState state;
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

	if (xmlSAXUserParseFile(&extractBinDataSAXParser, &state, filename) < 0) {
		return -1;
	} else
		return 0;
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
	state->elementInfo             = NULL;
	
}

static void extractBinDataEndDocument( ParserState *state ) {
}


static void extractBinDataStartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs) {
	char *localName, *compression, *href;
	int i, externalFlag, rC, p, indexesRC;
	long int offset, readLength;
	StructElementInfo* elementInfo;
	b64z_stream *strm;
	/* plane indexes */
	int theZ, theC, theT;
	Pix *pixReader;
	FILE *inFile;
	unsigned char *bin, *enc;
	size_t file_read_len;
	
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
	* a good way to do it, so I'm using the local name (BinData) to identify 
	* the element.
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
	* Flagged <External>
	* 	replace w/ <BinData>(s) & change state
	*/
	/* look for flag */
	externalFlag = 0;
	if( strcmp( ExternalLocal, localName ) == 0 ) {
		externalFlag = 1;
		if( attrs != NULL ) {
			for( i=0; attrs[i] != NULL; i+=2) {
				if( strcmp( attrs[i], "SHA1" ) == 0 ) {
					if( *(attrs[i+1]) != 0 ) externalFlag = 0;
					break;
				}
			}
		}
	}
		
	if( externalFlag ) {
		/* Extract data from xml attributes. */
		compression = href = NULL;
		offset = 0;
		readLength = -1;
		if( attrs != NULL ) {
			for( i=0; attrs[i] != NULL; i+=2) {
				if( strcmp( attrs[i], CompressionAttr ) == 0 ) {
					compression = (char *) attrs[i+1];
				} else if( strcmp( attrs[i], "href" ) == 0 )
					href = (char *) attrs[i+1];
				else if( strcmp( attrs[i], "Offset" ) == 0 )
					offset = atoi( attrs[i+1] );
				else if( strcmp( attrs[i], "ReadLength" ) == 0 )
					readLength = atoi( attrs[i+1] );
			}
		}
		if( href == NULL ) {
		    fprintf( stderr, "Error! A flagged <External> is missing required attribute 'href'!\n" );
		    exit(-1);
		}

		
		/* set up encoding stream */
		if( !compression ) /* if compression isn't specified, default to none. This attribute really should be set by the perl controller that calls this program. */
			strm = b64z_new_stream( NULL, 0,  NULL, 0, none );
		else if( strcmp(compression, "bzip2") == 0 )
			strm = b64z_new_stream( NULL, 0,  NULL, 0, bzip2 );
		else if( strcmp(compression, "none") == 0 )
			strm = b64z_new_stream( NULL, 0,  NULL, 0, none );
		else if ( strcmp(compression, "zlib") == 0 )
			strm = b64z_new_stream( NULL, 0,  NULL, 0, zlib );
		else {
			strm = NULL; /* keep the compiler from spitting warning msg. */
			fprintf( stderr, "'%s' is not a supported compression library", compression);
			exit(-1);
		}

		/**********************************************************************
		*
		* Flagged <External> under Pixels
		*/
		if( state->state == IN_PIXELS ) {
			state->state = IN_FLAGGED_EXTERNAL_UNDER_PIXELS;
			
			/******************************************************************
			*
			* init
			*/
			pixReader = NewPix( 
				href, 
				state->pixelInfo->X,
				state->pixelInfo->Y,
				state->pixelInfo->Z,
				state->pixelInfo->C,
				state->pixelInfo->T,
				state->pixelInfo->bpp / 8
			);
			if( !pixReader ) mem_error("");
			theZ = theC = theT = 0;
			enc = (unsigned char *) malloc( SIZEOF_BUFS );
			if( !enc ) mem_error("");
			/*
			******************************************************************/
			
			/******************************************************************
			*
			* Encode & print out a plane at a time
			*/
			do {
				/* get plane */
				bin = (unsigned char*) GetPlane( pixReader, theZ, theC, theT );
				if( state->pixelInfo->bigEndian != bigEndian() )
					switch( state->pixelInfo->bpp ) {
					 case 8:
						break;
					 case 16:
						byteSwap2( bin, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y );
						break;
					 case 32:
						byteSwap4( bin, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y );
						break;
					 case 64:
						byteSwap8( bin, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y );
						break;
					 case 128:
						byteSwap16( bin, (size_t)state->pixelInfo->X * (size_t)state->pixelInfo->Y );
						break;
					 default:
						fprintf( stderr, "Error! That size of pixels (%i) is not supported.\n", state->pixelInfo->bpp );
						exit( -1 );
						break;
					}
					 
				
				/**************************************************************
				*
				* encode buffer & write out
				*/
				b64z_encode_init ( strm );
				strm->next_in  = bin;
				strm->avail_in = state->pixelInfo->X * state->pixelInfo->Y * ( state->pixelInfo->bpp / 8 );
				if( compression == NULL ) /* default compression */
					fprintf( stdout, "<BinData xmlns=\"%s\" Compression=\"none\">", BinNS );
				else
					fprintf( stdout, "<BinData xmlns=\"%s\" Compression=\"%s\">", BinNS, compression );
				do {
					/* encode buffer */
					strm->next_out  = enc;
					strm->avail_out = SIZEOF_BUFS;

					rC = b64z_encode( strm, B64Z_FINISH );

					/* write encoded data to stdout */
					fwrite( enc, 1, SIZEOF_BUFS - strm->avail_out, stdout );
				} while( rC != B64Z_STREAM_END );
				fprintf( stdout, "</BinData>\n" );
				b64z_encode_end( strm );
				/*
				**************************************************************/
				
				free( bin );

				/* logic to increment indexes based on dimOrder */
				if( strcmp( state->pixelInfo->dimOrder, "XYZCT" ) == 0 ) {
					indexesRC = increment_plane_indexes( 
						&( theZ ), 
						&( theC ), 
						&( theT ),
						state->pixelInfo->Z, 
						state->pixelInfo->C, 
						state->pixelInfo->T 
					);
				} else if( strcmp( state->pixelInfo->dimOrder, "XYZTC" ) == 0 ) {
					indexesRC = increment_plane_indexes( 
						&( theZ ),
						&( theT ),
						&( theC ),
						state->pixelInfo->Z,
						state->pixelInfo->T,
						state->pixelInfo->C
					);
				} else if( strcmp( state->pixelInfo->dimOrder, "XYTZC" ) == 0 ) {
					indexesRC = increment_plane_indexes( 
						&( theT ),
						&( theZ ),
						&( theC ),
						state->pixelInfo->T,
						state->pixelInfo->Z,
						state->pixelInfo->C
					);
				} else if( strcmp( state->pixelInfo->dimOrder, "XYTCZ" ) == 0 ) {
					indexesRC = increment_plane_indexes( 
						&( theT ),
						&( theC ),
						&( theZ ),
						state->pixelInfo->T,
						state->pixelInfo->C,
						state->pixelInfo->Z
					);
				} else if( strcmp( state->pixelInfo->dimOrder, "XYCZT" ) == 0 ) {
					indexesRC = increment_plane_indexes( 
						&( theC ),
						&( theZ ),
						&( theT ),
						state->pixelInfo->C,
						state->pixelInfo->Z,
						state->pixelInfo->T
					);
				} else if( strcmp( state->pixelInfo->dimOrder, "XYCTZ" ) == 0 ) {
					indexesRC = increment_plane_indexes( 
						&( theC ),
						&( theT ),
						&( theZ ),
						state->pixelInfo->C,
						state->pixelInfo->T,
						state->pixelInfo->Z
					);
				} else {
					indexesRC = 0; /* keep the compiler from spitting warning msg. */
					fprintf( stderr, "Invalid dimOrder '%s'\n", state->pixelInfo->dimOrder );
					exit(-1);
				}
			
			} while( !indexesRC );
			/*
			* END 'Encode & print out a plane at a time'
			*
			******************************************************************/
						
			/* cleanup */
			free( strm );
			free( enc );
			strm = NULL;
			enc  = NULL;
		}
		/*
		* END 'Flagged <External> under Pixels'
		*
		**********************************************************************/


		
		/**********************************************************************
		*
		* Flagged <External>
		*/
		else {
			state->state = IN_FLAGGED_EXTERNAL;

			/******************************************************************
			*
			* init
			*/
			inFile = fopen( href, "rb" );
			if( !inFile ) {
				fprintf( stderr, "Error! Could not open file (path='%s')!\n", href );
				exit(-1);
			}
			bin = (unsigned char *) malloc( SIZEOF_BUFS );
			enc = (unsigned char *) malloc( SIZEOF_BUFS );
			if( !bin || !enc ) mem_error("");
			if( fseek( inFile, offset, SEEK_SET ) ) {
				fprintf( stderr, "Error! Could not seek to location specified by offset!\n" );
				exit(-1);
			}
			b64z_encode_init( strm );
			/*
			******************************************************************/
			
			/* print <BinData> */
			if( !compression ) /* default compression */
				fprintf( stdout, "<BinData xmlns=\"%s\" Compression=\"none\" >", BinNS );
			else
				fprintf( stdout, "<BinData xmlns=\"%s\" Compression=\"%s\" >", BinNS, compression );
			
			while( readLength != 0 ) {
				/**************************************************************
				*
				* read from file into buffer
				*/
				if( readLength == -1 ) { /* read entire file */
					file_read_len = -1;
					strm->avail_in = fread( bin, 1, SIZEOF_BUFS, inFile );
				} else if( readLength > SIZEOF_BUFS ) {
					file_read_len = SIZEOF_BUFS;
					strm->avail_in = fread( bin, 1, file_read_len, inFile );
					readLength -= file_read_len;
				} else {
					file_read_len = readLength;
					strm->avail_in = fread( bin, 1, file_read_len, inFile );
					readLength -= file_read_len;
				}

				if( readLength > 0 && strm->avail_in != file_read_len ) {
					if( ferror( inFile ) ) {
						fprintf( stderr, "Error! Encountered error while reading file (path='%s').\n", href );
						exit(-1);
					} else {
						fprintf( stderr, "Error! Encountered premature end of file while reading file (path='%s').\n", href );
						exit(-1);
					}
				}
				
				if( readLength == -1 && strm->avail_in == 0 ) {
					if( ferror( inFile )) {
						fprintf( stderr, "Error! Encountered error while reading file (path='%s').\n", href );
						exit(-1);
					}
					else
						break;
				}
				/*
				**************************************************************/
				
				/**************************************************************
				*
				* encode buffer & write out
				*/
				strm->next_in = bin;
				p = B64Z_RUN;
				do {
					/* encode buffer */
					strm->next_out  = enc;
					strm->avail_out = SIZEOF_BUFS;
					if( feof( inFile ) || readLength == 0 )
						p = B64Z_FINISH;

					rC = b64z_encode( strm, p );

					/* write encoded data to stdout */
					fwrite( enc, 1, SIZEOF_BUFS - strm->avail_out, stdout );
				} while( (strm->avail_in > 0 || p == B64Z_FINISH) && rC != B64Z_STREAM_END );
				/*
				**************************************************************/
			}
			
			/* print </BinData> */
			fprintf( stdout, "</BinData>\n" );
			
			/* cleanup */
			b64z_encode_end( strm );
			fclose( inFile );
			free( bin );
			free( enc );
		}
		/*
		* END 'Flagged <External>'
		*
		**********************************************************************/

		/* cleanup */
		free( strm );
		
	}
	/*
	* END 'Flagged <External>'
	*
	**************************************************************************/



	/**************************************************************************
	*
	* Pixels
	* 	
	*/
	else if( strcmp( PixelLocal, localName ) == 0 ) {

		/* set state */
		state->state            = IN_PIXELS;

		/* Stack maintence. Necessary for closing tags properly. */
		elementInfo             = (StructElementInfo *) malloc( sizeof(StructElementInfo) );
		if( !elementInfo ) mem_error("");
		elementInfo->hasContent = 0;
		elementInfo->prev       = state->elementInfo;
		elementInfo->tagOpen    = 1;
		state->elementInfo      = elementInfo;
		
		/**********************************************************************
		*
		* Extract data from xml attributes.
		*
		*/
		state->pixelInfo = (PixelInfo *) malloc( sizeof( PixelInfo ) );
		if( !(state->pixelInfo) ) mem_error("");
		if(attrs == NULL) {
			fprintf( stderr, "Error! Pixels element has no attributes!\n" );
			exit(-1);
		}
		state->pixelInfo->X = state->pixelInfo->Y = state->pixelInfo->Z = state->pixelInfo->C = state->pixelInfo->T = 0;
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
		
		/* print out <Pixels> */
		print_element( name, attrs );
	}
	/*
	*	END "Pixels"
	*
	**************************************************************************/



	/**************************************************************************
	*
	* This isn't a flagged <External> or <Pixels>, pipe it through.
	*/
	else {
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
	/ Iff we are ending an <External>, then we don't have to touch the stack.
	*/
	StructElementInfo *elementInfo;

	switch( state->state ) {
	
	
	/* <External> : Do nothing. Everything necessary has already been done. */
	 case IN_FLAGGED_EXTERNAL_UNDER_PIXELS:
		state->state = IN_PIXELS;
		break;
	 case IN_FLAGGED_EXTERNAL:
		state->state = PARSER_START;
		break;


	 case IN_PIXELS:
		state->state = PARSER_START;

	 	/* cleanup */
		free( state->pixelInfo->dimOrder );
		free( state->pixelInfo->pixelType );
		free( state->pixelInfo );
		state->pixelInfo = NULL;
	 	/* DO NOT "break;" Go on to default action of stack cleanup and
	 	/ element closure.
	 	*/


	 case PARSER_START:
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
	
} /* END extractBinDataEndElement */



static void extractBinDataCharacters(ParserState *state, const xmlChar *ch, int len) {
	
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

	switch( state->state ) {
	 case IN_PIXELS:
	 case PARSER_START:
		fwrite( ch, 1, len, stdout );
		fflush( stdout );
		break;
	/* these next cases will never happen. they are included to prevent compiler warnings. */
	 case IN_FLAGGED_EXTERNAL:
	 case IN_FLAGGED_EXTERNAL_UNDER_PIXELS:
	 default:
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

