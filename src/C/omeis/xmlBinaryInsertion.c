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

	xmlBinaryInsertion.c

	Intent: Graze an OME document, inserting Binary Pixel Data under <Pixels>.

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
	xml parser, so memory usage does not inflate when file size inflates. 

*
******************************************************************************/


#include <libxml/parser.h>
#include <zlib.h>
#include <bzlib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <errno.h>

#include "xmlBinaryInsertion.h"
#include "base64.h"
#include "b64z_lib.h"
#include "Pixels.h"
#include "OMEIS_Error.h"

/******************************************************************************
*
*	Data structures & Constants
*
*****************************************************************************/
#define PixelLocal "Pixels"
#define BinNS "http://www.openmicroscopy.org/XMLschemas/BinaryFile/RC1/BinaryFile.xsd"
#define SIZEOF_BUFS 1048576

/* This is a stack to store information about each XML element. It keeps track of
/ whether an element has content or is empty AND
/ whether the opening tag of the element is open (e.g. "<foo" is open, 
/ "<foo>" and "<foo/>" are not).
*/
typedef struct _elementInfo {
	int hasContent;
	int tagOpen;
	struct _elementInfo *prev;
} StructElementInfo;

/* Contains all the information about the parser's state */
typedef struct {
	StructElementInfo* elementInfo;
	char bigEndian;
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
int xmlInsertBinaryData(const char *filename, char bigEndian);
void _print_element(const xmlChar *name, const xmlChar **attrs);

/******************************************************************************
*
*	Utility Functions:
*
******************************************************************************/


int xmlInsertBinaryData(const char *filename, char bigEndian) {
    ParserState state;    
    /* The source of xmlSAXHandler and all the function prefixes I'm using are
      in <libxml/parser.h> Use `xml2-config --cflags` to find the location of
      that file.
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

    state.bigEndian = bigEndian;

	return xmlSAXUserParseFile(&extractBinDataSAXParser, &state, filename);
}

void _print_element(const xmlChar *name, const xmlChar **attrs) {
	int i;
	
	fprintf( stdout, "<%s ", name );
	if( attrs != NULL ) {
		/* print the attributes. */
		for( i=0;attrs[i] != NULL;i+=2 ) {
			fprintf( stdout, "%s = \"%s\" ", attrs[i], attrs[i+1] );
		}
	}
}


/******************************************************************************
*
*	SAX callback functions
*
******************************************************************************/

static void extractBinDataStartDocument(ParserState *state) {
	state->elementInfo             = NULL;	
}

static void extractBinDataEndDocument( ParserState *state ) {
}


static void extractBinDataStartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs) {
	char *localName, *compression, *href;
	int i, rC;
	StructElementInfo* elementInfo;
	PixelsRep *thePixels;
	OID PixelsID;
	b64z_stream *strm;
	/* plane indexes */
	int theZ, theC, theT;
	unsigned char *bin, *enc;
	unsigned int planeSize;
	
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
	* Pixels
	* 	
	*/
	if( strcmp( PixelLocal, localName ) == 0 ) {

		/* Stack maintence. Necessary for closing tags properly. */
		elementInfo             = (StructElementInfo *) malloc( sizeof(StructElementInfo) );
		assert( elementInfo != NULL);
		elementInfo->hasContent = 1;
		elementInfo->prev       = state->elementInfo;
		elementInfo->tagOpen    = 1;
		state->elementInfo      = elementInfo;
		
		/* Extract data from xml attributes. */
		PixelsID = 0;
		for( i=0; attrs[i] != NULL; i+=2 )
			if( !strcmp( attrs[i], "ImageServerID" ) )
				PixelsID = atol( attrs[i+1] );
		assert( PixelsID != 0 );
				
		/* print <Pixels> */
		fprintf( stdout, "<%s ", name );
		for( i=0;attrs[i] != NULL;i+=2 ) {
			if( strcmp( attrs[i], "ImageServerID" ) && strcmp( attrs[i], "Repository" ) &&
			    strcmp( attrs[i], "FileSHA1" ) ) {
			fprintf( stdout, "%s = \"%s\" ", attrs[i], attrs[i+1] );
		} }
		
		/* load Pixels Rep */
		if (! (thePixels = GetPixelsRep (PixelsID,'r',state->bigEndian)) ) {
			OMEIS_ReportError ("xmlBinaryInsertion", "PixelsID",PixelsID,"GetPixelsRep failed");
			assert( thePixels != NULL);
		}
		fprintf( stdout, "DimensionOrder=\"XYZCT\" BigEndian=\"%c\">\n", ( state->bigEndian ? 't' : 'f') );

		/* setup compression/base 64 stream */
		strm = b64z_new_stream( NULL, 0,  NULL, 0, zlib );
		theZ = theC = theT = 0;
		planeSize = thePixels->head->dx * thePixels->head->dy * thePixels->head->bp;
		enc = (unsigned char *) malloc( SIZEOF_BUFS );
		assert( enc != NULL );
		bin = (unsigned char *) malloc( planeSize );
		assert( bin != NULL );

		/******************************************************************
		*
		* Encode & print out a plane at a time
		*/
		do {
			/* get plane */
			if( !getPixelPlane( thePixels, (void *) bin, theZ, theC, theT ) ) {
				OMEIS_ReportError ("xmlBinaryInsertion", "PixelsID",thePixels->ID,"getPixelPlane returned NULL.");
				exit(-1);
			}				 
			
			/* encode buffer & write out */
			b64z_encode_init ( strm );
			strm->next_in  = bin;
			strm->avail_in = planeSize;
			fprintf( stdout, "<BinData xmlns=\"%s\" Compression=\"zlib\">", BinNS );

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
			
			/* increment indexes */
			if( theZ < thePixels->head->dz - 1 ) theZ++;
			else {
				theZ = 0;
				if( theC < thePixels->head->dc - 1) theC++;
				else {
					theC = 0;
					theT++;
				}
			}
		} while( theT < thePixels->head->dt ); 
		/*
		* END 'Encode & print out a plane at a time'
		*
		******************************************************************/
					
		/* cleanup */
		free( strm );
		free( enc );
		free( bin );
		freePixelsRep (thePixels);
	}
	/*
	*	END "Pixels"
	*
	**************************************************************************/



	/**************************************************************************
	*
	* This isn't a <Pixels>, pipe it through.
	*/
	else {
		/* Stack maintence. Necessary for closing tags properly. */
		elementInfo             = (StructElementInfo *) malloc( sizeof(StructElementInfo) );
		assert( elementInfo != NULL );
		elementInfo->hasContent = 0;
		elementInfo->prev       = state->elementInfo;
		elementInfo->tagOpen    = 1;
		state->elementInfo      = elementInfo;

		_print_element( name, attrs );
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

	fwrite( ch, 1, len, stdout );
	fflush( stdout );
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

/* Compiler attribute prototype */
void BinDataError( ParserState *state, const char *msg ) __attribute__ ((noreturn));
void BinDataError( ParserState *state, const char *msg ) {
	fprintf( stderr, "Terminating program. The SAX parser reports this error message:\n%s", msg );
	exit(-1);
}

/* Compiler Attribute prototype */
void BinDataFatalError( ParserState *state, const char *msg ) __attribute__ ((noreturn));
void BinDataFatalError( ParserState *state, const char *msg ) {
	fprintf( stderr, "Terminating program. The SAX parser reports this *FATAL* error message:\n%s", msg );
	exit(-1);
}

