/******************************************************************************
/*
/*	extractBinData.c
/*	
/*	Originally written: May 16, 2003
/*	Standard licence blurb:

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

/****

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

	Compilation notes: Use the xml2-config utility to find the location of the
	libxml2 libraries. The flags --libs and --cflags cause xml2-config to 
	produce the proper flags to pass to the compiler. The one line compilation
	command is:

		gcc `xml2-config --libs --cflags` -I/sw/include/ -L/sw/lib/ -lbz2 -ltiff extractBinData.c base64.c ../perl2/OME/Image/Pix/libpix.c scratch/b64z_lib.c -o extractBinData

/****

2do
Buffering/Memory issues:
*...memory requirement of two times the size of the <BinData> contents...*
<BinData> content is optionally compressed and is mandatorily converted to base64. It's loaded into memory when it is extracted, so we should do the base64 decoding and decompression before it is written to disk.
base64 decoding acts on a buffer, but I can convert it to stream processing without getting crazy. decompression schemes are gzip and bzip2. bzip2 supports stream decompression to memory or disk. gzip does not support stream decompression to memory, but does support stream compression to disk.
<BinData>s in <OTF> will either be written directly to disk or treated the same way as <Pixels>.
<BinData>s in <Pixels> need to be reordered before being written to disk. I am going to use libpix methods to do this ordering. libpix currently supports buffered writes. it can accept buffers that hold rows or planes or stacks. There are some complications in writing a pixels dump to disk using random access, so it's good to keep that functionality centralized in libpix.

The ways I can handle <Pixels>' <BinData> (that I can think of):
	a crufty but servicable solution is to buffer the <BinData> contents, run decoding and decompression on the buffer, then pass the buffer to libpix to be written. drawbacks to this solution are: the entire <BinData> is loaded in RAM. Due to the way the <BinData> contents are received, the buffering has a memory requirement of two times the size of the contents and must be copied twice. The limiting factor is that gzip does not support stream decompression to memory and libpix needs a memory chunk.
	the Real solution is to refactor the pixel writing methods in libpix to separate the file seek functionality from the pixel writing functionality. i would use the libpix file seek functionality to position the file pointer, then do stream decompression straight to disk.

the Real solution is more involved and will take longer. right now i am trying to get this working without taking two more weeks, so i'm leaving the crufty solution. i HIGHLY recommend that someone (probably me) implement the real solution. the crufty solution could be optimized for non-<Pixels> <BinData>. That can actually be an intermediate step in moving towards the Real solution

/*
/*****************************************************************************/


#include <libxml/parser.h>
#include <zlib.h>
#include <bzlib.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "base64.h"
#include "scratch/stringBuf.h"
#include "scratch/b64z_lib.h"
#include "../perl2/OME/Image/Pix/libpix.h"

/******************************************************************************
/*
/*	Data structures & Constants
/*
/*****************************************************************************/
#define BinDataLocal "BinData"
#define PixelLocal "Pixels"
#define CompressionAttr "Compression"
#define BinNS "http://www.openmicroscopy.org/XMLschemas/BinaryFile/RC1/BinaryFile.xsd"
// specifies memory usage of bzip. see ftp://sources.redhat.com/pub/bzip2/docs/manual_3.html#SEC19 for more info
#define SIZEOF_FILE_OUT_BUF 10//00000
const char *pixelTypes[] = { "bit", "int8", "int16", "int32", "Uint8", "Uint16", "Uint32", "float", "double", "complex", "double-complex", NULL };
const int bitsPerPixel[] = {  1,      8,     16,      32,      8,       16,       32,       32,      64,       64,        128            , NULL };

// This is a stack to store information about an element. It keeps track of
// whether an element has content or is empty AND
// whether the opening tag of the element is open (e.g. "<foo" is open, 
// "<foo>" and "<foo/>" are not). It is used for every element except BinData.
typedef struct _elementInfo {
	int hasContent;
	int tagOpen;
	struct _elementInfo *prev;
} StructElementInfo;

// <BinData> storage & info
typedef struct {
	FILE *BinDataOut;
	// binDataBuf buffers the content of a <BinData>
	StringBuf *binDataBuf;
	char *compression;
	b64z_stream *strm;
} BinDataInfo;

// Possible states
typedef enum {
	PARSER_START,
	IN_BINDATA,
	IN_PIXELS,
	IN_BINDATA_UNDER_PIXELS,
} PossibleParserStates;

// <Pixels> info
typedef struct {
	// dimensions of pixel array. C is channels. bpp is "bits per pixel"
	int X,Y,Z,C,T,bpp;
	// indexes to store current plane
	int theZ, theC, theT;
	char *dimOrder;
	// pixelType is not strictly needed. maybe it will come in handy in a later incarnation of this code
	char *pixelType;
	// outputPath stores the path the coallated <BinData>s will reside.
	char *outputPath;
	int hitBinData;
	Pix *pixWriter;
} PixelInfo;

// Contains all the information about the parser's state
typedef struct {
	PossibleParserStates state;
	int nOutputFiles;
	PixelInfo *pixelInfo;
	StructElementInfo* elementInfo;
	BinDataInfo *binDataInfo;
} ParserState;

/******************************************************************************
/*
/*	Functions Declarations:
/*
/*****************************************************************************/

// SAX callbacks:
static void extractBinDataStartDocument(ParserState *);
static void extractBinDataEndDocument( ParserState * );
static void extractBinDataCharacters(ParserState *, const xmlChar *, int );
static void extractBinDataStartElement(ParserState *, const xmlChar *, const xmlChar **);
static void extractBinDataEndElement(ParserState *, const xmlChar *);
static void BinDataWarning( ParserState *, const char * );
static void BinDataError( ParserState *, const char * );
static void BinDataFatalError( ParserState *, const char * );

// Utility functions:
int parse_xml_file(const char *);
void print_element(const xmlChar *, const xmlChar **);
int increment_plane_indexes( int *, int *, int *, int, int, int);
void mem_error( char*msg );

/******************************************************************************
/*
/*	main & global data
/*
/*****************************************************************************/
char *dirPath;
char *pixelDirPath;

int main(int ARGC, char **ARGV) {
	char *filePath;
	
	// program called with improper usage. print usage message.
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
/*
/*	Utility Functions:
/*
/*****************************************************************************/


int parse_xml_file(const char *filename) {
    ParserState my_state;
    // The source of xmlSAXHandler and all the function prefixes I'm using are
    // in <libxml/parser.h> Use `xml2-config --cflags` to find the location of
    // that file.
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
		return NULL;
	} else
		return my_state.nOutputFiles;
}

void print_element(const xmlChar *name, const xmlChar **attrs) {
	int i;
	
	fprintf( stdout, "<%s ", name );
	if( attrs != NULL ) {
		// print the attributes.
		for( i=0;attrs[i] != NULL;i+=2 ) {
			fprintf( stdout, "%s = \"%s\" ", attrs[i], attrs[i+1] );
		}
	}
}

int increment_plane_indexes( int* a, int* b, int* c, int aMax, int bMax, int cMax ) {
	
	if( *a<aMax ) (*a)++;
	else {
		*a = 0;
		if(*b<bMax) (*b)++;
		else {
			*b = 0;
			if(*c<cMax) (*c)++;
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
/*
/*	SAX callback functions
/*
/*****************************************************************************/

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
	int i, freeLocalName, pathLength;
	StructElementInfo* elementInfo;
	size_t bufferSize;

	// mark that the last open element has content, namely this element
	if( state->elementInfo != NULL ) {
		state->elementInfo->hasContent = 1;
		if( state->elementInfo->tagOpen == 1 ) {
			fprintf( stdout, ">" );
			state->elementInfo->tagOpen = 0;
		}
	}


	/**************************************************************************
	/*
	/* Getting the namespace for an element is tricky. I haven't figured out 
	/* how to do it yet, so I'm using the local name (BinData) to identify the
	/* element.
	/* I think http://cvs.gnome.org/lxr/source/gnorpm/find/search.c might have
	/* some code that will do it.
	/* Find the local name of the element: strip the prefix if one exists.
	*/
	localName = strchr( name, ':' );
	if( localName != NULL ) {
		localName++;
		freeLocalName = 0;
	} else {
		localName = malloc( strlen(name) );
		strcpy( localName, name );
		freeLocalName = 1;
	}
	/*
	/*************************************************************************/

	

	/**************************************************************************
	/*
	/* BinData
	/* 	Change state, get compression scheme, open output file as necessary
	*/
	if( strcmp( BinDataLocal, localName ) == 0 ) {

		// take note of compression
		state->binDataInfo->compression = NULL;
		if( attrs != NULL ) {
			for( i=0; attrs[i] != NULL; i+=2) {
				if( strcmp( attrs[i], CompressionAttr ) == 0 ) {
					state->binDataInfo->compression = (char *) malloc( strlen(attrs[i+1]) + 1);
					strcpy( state->binDataInfo->compression, attrs[i+1] );
					break;
				}
			}
		}

		// set up decoding stream
		state->binDataInfo->binDataBuf = makeStringBuf();
		if( ! (state->binDataInfo->compression ) ) /* no compression */
			state->binDataInfo->strm = b64z_new_stream( NULL, 0,  NULL, 0, none );
		else if( strcmp(state->binDataInfo->compression, "bzip2") == 0 )
			state->binDataInfo->strm = b64z_new_stream( NULL, 0,  NULL, 0, bzip2 );
		else if ( strcmp(state->binDataInfo->compression, "zlib") == 0 )
			state->binDataInfo->strm = b64z_new_stream( NULL, 0,  NULL, 0, zlib );
		b64z_decode_init ( state->binDataInfo->strm );

		// This <BinData> is under <Pixels>
		if( state->state == IN_PIXELS ) {
			state->state = IN_BINDATA_UNDER_PIXELS;
			state->pixelInfo->hitBinData = 1;
		} 

		// This <BinData> is not under <Pixels>
		// 	It needs to be piped to a file & replaced with an <External>
		// 	This data needs to be converted from base64 & possibly
		// 	decompressed. 
		else {
			state->state      = IN_BINDATA;
			state->nOutputFiles++;
			
			// open the output file for the BinData contents
			binDataOutPath = (char *) malloc( 
				strlen( dirPath ) + 
				strlen( "/" ) +
				( (int) state->nOutputFiles % 10 ) + 1 +
				strlen( ".out" ) +
				1 );
			sprintf( binDataOutPath, "%s/%i.out", dirPath, state->nOutputFiles );
			state->binDataInfo->BinDataOut = fopen( binDataOutPath, "w" );
			if( state->binDataInfo->BinDataOut == NULL ) {
				fprintf( stderr, "Error! Could not open file for output. Path is\n%s\n", binDataOutPath );
				exit(-1);
			}
	
			// convert BinData to External
			fprintf( stdout, "<External xmlns=\"%s\" href=\"%s\" SHA1=\"\"/>", BinNS, binDataOutPath );
			
			free( binDataOutPath );
		}
	}
	/*
	/*************************************************************************/



	/**************************************************************************
	/*
	/* Pixels:
	/* 	The <BinData>s under Pixels are treated differently than other 
	/* 	<BinData>s. If <BinData>s are used under <Pixels>, then the contents 
	/* 	should be processed and coalated into the full pixel dump. We might as
	/* 	well do this while it is already loaded in memory.
	/*
	/* 	The contents of each <BinData> section is buffered into a big chunk.
	/* 	When the <BinData> closes, that chunk is converted from base 64,
	/* 	uncompressed, and sent through libpix to be written to disk.
	/*
	/* 	After every <BinData> under <Pixels> is processed like that, they
	/* 	are replaced with a single <External>. This <External> is 
	/* 	distiguishable from other <External>s by having a null value for the 
	/* 	SHA1 attribute. When one of these <External>s is encountered in later
	/* 	processing, the DimensionOrder attribute should be ignored. It describe
	/* 	how the <BinData>s were ordered, but the pixels were reordered to
	/* 	standard repository format (XYZCT) when they were sent through libpix.
	*/
	else if( strcmp( PixelLocal, localName ) == 0 ) {

		// set state
		state->state            = IN_PIXELS;

		// Stack maintence. Necessary for closing tags properly.
		elementInfo             = (StructElementInfo *) malloc( sizeof(StructElementInfo) );
		elementInfo->hasContent = 0;
		elementInfo->prev       = state->elementInfo;
		elementInfo->tagOpen    = 1;
		state->elementInfo      = elementInfo;
		
		/**********************************************************************
		/*
		/* Extract data from xml attributes.
		/*
		/*
		*/
		// data extraction
		state->pixelInfo = (PixelInfo *) malloc( sizeof( PixelInfo ) );
		if(attrs == NULL) {
			fprintf( stderr, "Error! Pixels element has no attributes!\n" );
			exit(-1);
		}
		state->pixelInfo->X = state->pixelInfo->Y = state->pixelInfo->Z = state->pixelInfo->C = state->pixelInfo->T = 0;
		state->pixelInfo->dimOrder = state->pixelInfo->pixelType = NULL;
		for( i=0; attrs[i] != NULL; i+=2 ) {
			if( strcmp( attrs[i], "SizeX" ) == 0 ) {
				state->pixelInfo->X = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "SizeY" ) == 0 ) {
				state->pixelInfo->Y = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "SizeZ" ) == 0 ) {
				state->pixelInfo->Z = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "NumChannels" ) == 0 ) {
				state->pixelInfo->C = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "NumTimes" ) == 0 ) {
				state->pixelInfo->T = atoi( attrs[i+1] );
			} else if( strcmp( attrs[i], "DimensionOrder" ) == 0 ) {
				state->pixelInfo->dimOrder = (char *) malloc( strlen(attrs[i+1]) + 1 );
				strcpy( state->pixelInfo->dimOrder, attrs[i+1] );
			} else if( strcmp( attrs[i], "PixelType" ) == 0 ) {
				state->pixelInfo->pixelType = (char *) malloc( strlen(attrs[i+1]) + 1 );
				strcpy( state->pixelInfo->pixelType, attrs[i+1] );
			}
		}
		
		// error check: verify we have all needed attributes
		if( state->pixelInfo->X == 0 || state->pixelInfo->Y == 0 ||
		    state->pixelInfo->Z == 0 || state->pixelInfo->C == 0 ||
		    state->pixelInfo->T == 0 || state->pixelInfo->dimOrder == NULL ||
		    state->pixelInfo->pixelType == NULL ) {
			fprintf( stderr, "Error! Pixels element does not have all required attributes!\n" );
			exit(-1);
		}
		
		// look up bpp for this pixel type
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
		
		// I don't know how to deal with binary images for now, so I'm going
		// to barf if the pixelType is "bit"
		if( strcmp( state->pixelInfo->pixelType, "bit" ) == 0 ) {
			fprintf( stderr, "Error! pixelType 'bit' is not supported yet!\n" );
			exit(-1);
		}

		/*
		/* END "Extract data from xml attributes."
		/*
		/*********************************************************************/
		
		/**********************************************************************
		/*
		/* Initialization for <BinData> processing.
		/* 	remember that we do not know if this <Pixels> contains <BinData>s
		/* 	or <External>s. We will not use any of this if the <Pixels> 
		/* 	contains <External>s.
		/*
		*/
		// initialize variables
		state->pixelInfo->theZ = state->pixelInfo->theC = state->pixelInfo->theT = 0;
		state->pixelInfo->hitBinData = 0;
		
		// 2do
		// initialize libpix object - DON'T FORGET BIG ENDIAN!
		state->nOutputFiles++;
		state->pixelInfo->outputPath = (char *) malloc( 
			strlen( pixelDirPath ) + 
			strlen( "/" ) +
			( (int) state->nOutputFiles % 10 ) + 1 +
			strlen( ".out" ) +
			1 );
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

		/*
		/* END "Initialization for <BinData> processing."
		/*
		/*********************************************************************/

		// print out <Pixels>
		print_element( name, attrs );
	}
	/*
	/*	END "Pixels"
	/*
	/*************************************************************************/



	/**************************************************************************
	/*
	/* This isn't a <BinData> or <Pixels>, pipe it through.
	*/
	else {
		// Stack maintence. Necessary for closing tags properly.
		elementInfo             = (StructElementInfo *) malloc( sizeof(StructElementInfo) );
		elementInfo->hasContent = 0;
		elementInfo->prev       = state->elementInfo;
		elementInfo->tagOpen    = 1;
		state->elementInfo      = elementInfo;

		print_element( name, attrs );
	}
	/*
	/*************************************************************************/

	if( freeLocalName == 1 ) 
		free( localName );

} // END extractBinDataStartElement



static void extractBinDataEndElement(ParserState *state, const xmlChar *name) {
	// We're at the end of an element. If the element had content, then we
	// need to print "</[elementName]>". If the element did not have 
	// content, then we need to print "/>". I'm using a stack to keep track
	// of element's content, so I gotta check the stack and do stack 
	// maintence.
	// Iff we are ending a BinData section, then we don't have to touch the
	// stack.
	char *localName;
	unsigned char *base64buf, *decodedBase64buf, *uncompressedBuf;
	int base64Len, noBase64Len, returnCode;
	size_t outLen;
	unsigned int bufLen;
	unsigned long zlibBufLen;
	StructElementInfo *elementInfo;
	bz_stream bzip_stream;
	z_stream zlib_stream;

	switch( state->state ) {
	
	
	/**************************************************************************
	/*
	/* Process <BinData>
	/* 	write <BinData> contents to file & replace <BinData> with an
	/* 	<External> that points to the file
	*/
	 case IN_BINDATA:
		state->state = PARSER_START;
		
		//cleanup
		b64z_decode_end ( state->binDataInfo->strm );
		free( state->binDataInfo->strm );
		state->binDataInfo->strm = NULL;
		
		if( state->binDataInfo->compression ) free( state->binDataInfo->compression );
		state->binDataInfo->compression = NULL;
		fclose( state->binDataInfo->BinDataOut );
		state->binDataInfo->BinDataOut = NULL;

		break;

		// get full buffer of binData & clean up
		base64Len = state->binDataInfo->binDataBuf->len;
		base64buf = (unsigned char *) malloc( base64Len );
		if( !base64buf ) mem_error("");
		getFullString( state->binDataInfo->binDataBuf, base64buf );
		destroyStringBuf( state->binDataInfo->binDataBuf );
		state->binDataInfo->binDataBuf = NULL;

	 	// decode base64
	 	noBase64Len = base64Len / 4 * 3;
	 	decodedBase64buf = (unsigned char *) malloc( noBase64Len );
	 	noBase64Len = base64_decode( decodedBase64buf, base64buf, base64Len );
		free( base64buf );
	 	
	 	// no compression - just write to file
 		if( state->binDataInfo->compression == NULL ) {
			outLen = noBase64Len;
			returnCode = fwrite( decodedBase64buf, 1, outLen, state->binDataInfo->BinDataOut );
			if( returnCode != outLen ) {
				fprintf( stderr, "Error! Could not write entire buffer to output file! wrote %i/%i bytes.\n", returnCode, outLen );
				exit(-1);
			}
 		}


 		/**********************************************************************
 		/*
 		/* bzip2
 		/* 	decompress data & write to file
 		/*
 		*/
	 	else if( strcmp( state->binDataInfo->compression, "bzip2" ) == 0 ) {
	 		// initialize bzip2 decompression stream
			bzip_stream.bzalloc = NULL;
			bzip_stream.bzfree  = NULL;
			bzip_stream.opaque  = NULL;
			if( BZ2_bzDecompressInit( &bzip_stream, 0, 0 ) != BZ_OK ) { fprintf( stderr, "Error! Could not initialize bzip2 decompression!\n" ); exit(-1); }

			// initialize stream parameters
			bzip_stream.next_in   = (char *) decodedBase64buf;  // *hopefully* this is a safe cast
			bzip_stream.avail_in  = noBase64Len;
			uncompressedBuf       = (unsigned char *) malloc( SIZEOF_FILE_OUT_BUF );
			bzip_stream.avail_out = SIZEOF_FILE_OUT_BUF;
			bzip_stream.next_out  = (char *) uncompressedBuf;  // *hopefully* this is a safe cast
			
			// decompress & write to file
			do {
				returnCode = BZ2_bzDecompress( &bzip_stream );
				switch( returnCode ) {
					case BZ_STREAM_END:
					case BZ_OK:
						outLen = SIZEOF_FILE_OUT_BUF - bzip_stream.avail_out;
						if( fwrite( uncompressedBuf, 1, outLen, state->binDataInfo->BinDataOut ) != outLen ) {
							fprintf( stderr, "Error! Could not write full output to file!\n" );
							exit(-1);
						}
						bzip_stream.avail_out = SIZEOF_FILE_OUT_BUF;
						bzip_stream.next_out  = (char *) uncompressedBuf;  // *hopefully* this is a safe cast
						break;
					default:
						fprintf( stderr, "Error! bzip2 decompression returned an error!\n" );
						exit(-1);
						// for more error messages, see ftp://sources.redhat.com/pub/bzip2/docs/manual_3.html#SEC23
				}
			} while( returnCode != BZ_STREAM_END );
			
			// cleanup
			if( BZ2_bzDecompressEnd( &bzip_stream ) != BZ_OK ) {
				fprintf( stderr, "Error! bzip2 returned an error message when calling BZ2_bzDecompressEnd\n" );
				exit(-1);
			}
			free( uncompressedBuf );
	 	}
	 	/*
	 	/*	END 'bzip2'
	 	/*
	 	/*********************************************************************/
	 	
	 	
 		/**********************************************************************
 		/*
 		/* zlib
 		/* 	decompress data & write to file
 		/*
 		*/
	 	else if( strcmp( state->binDataInfo->compression, "zlib" ) == 0 ) {
			// initialize the zlib stream
			zlib_stream.zalloc   = Z_NULL;
			zlib_stream.zfree    = Z_NULL;
			zlib_stream.opaque   = Z_NULL;
			zlib_stream.next_in  = decodedBase64buf;
			zlib_stream.avail_in = noBase64Len;
			returnCode = inflateInit( &zlib_stream );
			switch( returnCode ) {
				case Z_OK:
					break;
				case Z_MEM_ERROR:
					fprintf( stderr, "Error! zlib could not allocate memory to initialize.\nzlib reports:%s\n", zlib_stream.msg );
					exit(-1);
				case Z_VERSION_ERROR:
					fprintf( stderr, "Error! data was compressed with an incompatible version of zlib!\nzlib reports:%s\n", zlib_stream.msg );
					exit(-1);
				default:
					fprintf( stderr, "Error! zlib reported the following error on initialization:\n%s", zlib_stream.msg );
					exit(-1);
			}
			
			// initialize stream parameters
			uncompressedBuf       = (unsigned char *) malloc( SIZEOF_FILE_OUT_BUF );
			zlib_stream.avail_out = SIZEOF_FILE_OUT_BUF;
			zlib_stream.next_out  = (char *) uncompressedBuf;  // *hopefully* this is a safe cast

			// decompress & write to file
			do {
				returnCode = inflate( &zlib_stream, Z_SYNC_FLUSH );
				switch( returnCode ) {
					case Z_STREAM_END:
					case Z_OK:
						outLen = SIZEOF_FILE_OUT_BUF - zlib_stream.avail_out;
						if( fwrite( uncompressedBuf, 1, outLen, state->binDataInfo->BinDataOut ) != outLen ) {
							fprintf( stderr, "Error! Could not write full output to file!\n" );
							exit(-1);
						}
						zlib_stream.avail_out = SIZEOF_FILE_OUT_BUF;
						zlib_stream.next_out  = uncompressedBuf;
						break;
					default:
						fprintf( stderr, "Error! zlib decompression returned an error!\nmessage is:\n%s\nend of message\n", zlib_stream.msg );
						exit(-1);
						// for more error messages, see http://www.gzip.org/zlib/manual.html#inflate
				}
			} while( returnCode != Z_STREAM_END );

			// cleanup
			if( inflateEnd( &zlib_stream ) != Z_OK ) {
				fprintf( stderr, "Error! zlib gave an error message when calling inflateEnd\nmessage is:\n%s\nend of message\n", zlib_stream.msg );
				exit(-1);
			}
			free( uncompressedBuf );
		}
	 	/*
	 	/*	END 'zlib'
	 	/*
	 	/*********************************************************************/

		// cleanup
		free( decodedBase64buf );
		if( state->binDataInfo->compression ) free( state->binDataInfo->compression );
		state->binDataInfo->compression = NULL;
		fclose( state->binDataInfo->BinDataOut );
		state->binDataInfo->BinDataOut = NULL;

		break;
	/*
	/* END 'Process <BinData>'
	/*
	/*************************************************************************/



	/**************************************************************************
	/*
	/* Process <BinData> inside of <Pixels>
	/*
	*/
	 case IN_BINDATA_UNDER_PIXELS:
		state->state = IN_PIXELS;
		
		// get full buffer of binData & clean up
		base64Len = state->binDataInfo->binDataBuf->len;
		base64buf = (unsigned char *) malloc( base64Len );
		if( !base64buf ) mem_error("");
		getFullString( state->binDataInfo->binDataBuf, base64buf );
		destroyStringBuf( state->binDataInfo->binDataBuf );
		state->binDataInfo->binDataBuf = NULL;

	 	// decode base64
	 	noBase64Len = base64Len / 4 * 3;
	 	decodedBase64buf = (unsigned char *) malloc( noBase64Len );
		if( !decodedBase64buf ) mem_error("");
	 	noBase64Len = base64_decode( decodedBase64buf, base64buf, base64Len );
		free( base64buf );

	 	// pixels aren't compressed
 		if( state->binDataInfo->compression == NULL ) {
		 	uncompressedBuf = decodedBase64buf;
			bufLen = noBase64Len;
 		}


		/**********************************************************************
		/*
	 	/* bzip2
	 	/* 	decompress
	 	*/
	 	else if( strcmp( state->binDataInfo->compression, "bzip2" ) == 0 ) {

		 	bufLen = state->pixelInfo->X * state->pixelInfo->Y * (int) (state->pixelInfo->bpp / 8 );
		 	uncompressedBuf = (unsigned char *) malloc( bufLen + 1 );
		 	if( uncompressedBuf == NULL ) mem_error("");
		 	uncompressedBuf[bufLen] = '\0';


			returnCode = BZ2_bzBuffToBuffDecompress( uncompressedBuf, &bufLen, decodedBase64buf, noBase64Len, 0, 0 );
			switch( returnCode ) {
			  case BZ_OK:
				break;
			  case BZ_MEM_ERROR:
				mem_error("Error generated by a call to bzip2's BZ2_bzBuffToBuffDecompress");
				break;
			  case BZ_OUTBUFF_FULL:
			  	fprintf( stderr, "Error! bzip2 reports not enough room in output buffer." );
			  	exit(-1);
				break;
			  case BZ_DATA_ERROR:
			  	fprintf( stderr, "Error! bzip2 reports data integrity error in input data." );
			  	exit(-1);
				break;
			// other error messages at ftp://sources.redhat.com/pub/bzip2/docs/manual_3.html#SEC37
	 		} 
	 		
	 		free(decodedBase64buf);
	 		decodedBase64buf = NULL;
	 	
	 	}
	 	/*
	 	/* END 'bzip2'
	 	/*
	 	/*********************************************************************/



		/**********************************************************************
		/*
	 	/* zlib
	 	/* 	decompress
	 	*/
	 	else if( strcmp( state->binDataInfo->compression, "zlib" ) == 0 ) {

		 	zlibBufLen = state->pixelInfo->X * state->pixelInfo->Y * (int) (state->pixelInfo->bpp / 8 );
		 	uncompressedBuf = (unsigned char *) malloc( zlibBufLen + 1 );
		 	if( uncompressedBuf == NULL ) mem_error("");
		 	uncompressedBuf[zlibBufLen] = '\0';

			returnCode = uncompress( uncompressedBuf, &zlibBufLen, decodedBase64buf, noBase64Len );
			switch( returnCode ) {
			  case Z_OK:
				break;
			  case Z_MEM_ERROR:
				mem_error("Error generated by a call to zlib's uncompress\n");
				break;
			  case Z_BUF_ERROR:
			  	fprintf( stderr, "Error! zlib's uncompress reports not enough room in output buffer.\n" );
			  	exit(-1);
				break;
			  case Z_DATA_ERROR:
			  	fprintf( stderr, "Error! zlib's uncompress reports input data was corrupted.\n" );
			  	exit(-1);
				break;
			  default:
			  	fprintf( stderr, "Error! zlib's uncompress reports an error.\n" );
			  	exit(-1);
	 		} 
	 		
	 		bufLen = zlibBufLen;
	 		free(decodedBase64buf);
	 		decodedBase64buf = NULL;
	 	}
	 	/*
	 	/* END 'zlib'
	 	/*
	 	/*********************************************************************/
	 	

	 	// output buffered BinData through libpix
	 	SetPlane( 
	 		state->pixelInfo->pixWriter, 
	 		uncompressedBuf, 
	 		state->pixelInfo->theZ, 
	 		state->pixelInfo->theC, 
	 		state->pixelInfo->theT );

	 	// logic to increment indexes based on dimOrder
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
				

		// cleanup
		free( uncompressedBuf );
		if( state->binDataInfo->compression ) free( state->binDataInfo->compression );
		state->binDataInfo->compression = NULL;

	 	break;
	/*
	/* END 'Process <BinData> inside of <Pixels>'
	/*
	/*************************************************************************/


	 case IN_PIXELS:
		state->state = PARSER_START;

	 	// print the <External> element if we extracted <BinData>s
		if( state->pixelInfo->hitBinData == 1 )
			fprintf( stdout, "<External xmlns=\"%s\" href=\"%s\" SHA1=\"\"/>", BinNS, state->pixelInfo->outputPath );
	 
	 	// cleanup
		free( state->pixelInfo->dimOrder );
		free( state->pixelInfo->pixelType );
		free( state->pixelInfo->outputPath );
		// 2do
		// close libpix object, clean it up
		FreePix( state->pixelInfo->pixWriter );

	 	// DO NOT "break;" Go on to default action of stack cleanup and
	 	// element closure.



	 default:
		// Stack maintence
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
	
} // END extractBinDataEndElement



static void extractBinDataCharacters(ParserState *state, const xmlChar *ch, int len) {
	unsigned char * buf;
	int rC;
	size_t outLen;
	
	
	// The tag begun by extractBinDataStartElement might be open. If so, we 
	// need to close it so we can print the character contents of this element.
	if( state->elementInfo != NULL ) {
		state->elementInfo->hasContent = 1;
		if( state->elementInfo->tagOpen == 1 ) {
			fprintf( stdout, ">" );
			state->elementInfo->tagOpen = 0;
		}
	}

	// The character data needs to be streamed out. 
	// This switch directs the flow.
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
			//write out to file & reset output buffers
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
	 	// copy stream to BinData buffer
	 	// this recast is safe. xmlChar is a typedef for unsigned char.
	 	// without this recast the compiler spits a warning
	 	copyStringToBuf( state->binDataInfo->binDataBuf, (unsigned char *)ch, len );
	 	break;
	} // switch( state->state )
}

/******************************************************************************
/*
/*	Error routines (SAX callbacks):
/*
/*	These are supposed to pipe the error output from SAX through to stderr.
/*	They don't work completely. The last argument in the function prototype is 
/*	", ...". I don't know how to access the variables passed on it through to
/*	the fprintf statement. 
/*	http://www.daa.com.au/~james/articles/libxml-sax/libxml-sax.html#errors
/*	has an example that uses glib logging functions, but I couldn't figure out
/*	how to adapt that code.
/*
/*****************************************************************************/
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

