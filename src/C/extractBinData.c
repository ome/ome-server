/******************************************************************************
/*
/*	extractBinData.c
/*	
/*	Author: Josiah Johnston (siah@nih.gov)
/*	Originally written: May 16, 2003
/*
/*	Intent: The intent of this program is to extract the contents of <BinData>
/*	from an xml document following the OME schema, and replace the 
/*  <BinData>...</BinData> element with an <External .../> element.
/*
/*	Usage: Execute the program with no parameters to see the usage message.
/*
/*	Libraries: This program uses libxml2's SAX library. SAX is a stream based
/*	xml parser, so memory usage DOES NOT inflate when file size inflates. 
/*	YOU MUST INSTALL libxml2 BEFORE THIS WILL COMPILE.
/*	Memory usage was the same for a 100 Meg and a 1 Gig file.
/*
/*	Behavior: The modified xml document will be spewed to stdout. The extracted
/*	BinData contents will be spewed to separate files (1 per BinData) in a 
/*	directory. See Usage for more information about the directory. The path
/*	to the extracted file will be specified in the href attribute of the 
/*	<External> element that replaces the <BinData> element. The <External> tag
/*	will look like this:
/*		<External href="path/to/local/file"/>
/*	Notice it is missing the SHA1 attribute. That will distiguish these 
/*	converted BinData elements from unaltered <External> elements. The path 
/*	specified in href will be an absolute path iff this program is passed
/*	an absolute path to a scratch space. 
/*
/*	Compilation notes: Use the xml2-config utility to find the location of the
/*	libxml2 libraries. The flags --libs and --cflags cause xml2-config to 
/*	produce the proper flags to pass to the compiler. The one line compilation
/*	command is:
/*
/*		gcc `xml2-config --libs --cflags` extractBinData.c -o extractBinData
/*
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

/*****************************************************************************/


#include <libxml/parser.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/******************************************************************************
/*
/*	Data structures
/*
/*****************************************************************************/
#define BinDataLocal "BinData"
#define BinNS "http://www.openmicroscopy.org/XMLschemas/BinaryFile/RC1/BinaryFile.xsd"

// This is a stack. It stores whether an element has content or is empty. Also,
// whether the opening tag of the element is open (e.g. "<foo" is open, 
// "<foo>" and "<foo/>" are not).
typedef struct _elementInfo {
	int hasContent;
	int tagOpen;
	struct _elementInfo *prev;
} StructElementInfo;

typedef enum {
	PARSER_START,
	PARSER_IN_BINDATA,
} PossibleParserStates;

typedef struct _ParserState {
	PossibleParserStates state;
	int nBinDatas;
	StructElementInfo* elementInfo;
	FILE *BinDataOut;
} ParserState;


/******************************************************************************
/*
/*	Functions Declarations:
/*
/*****************************************************************************/

// SAX callbacks:
static void BinDataExtractStartDocument(ParserState *);
static void BinDataExtractCharacters(ParserState *, const xmlChar *, int );
static void BinDataExtractStartElement(ParserState *, const xmlChar *, const xmlChar **);
static void BinDataExtractEndElement(ParserState *, const xmlChar *);
static void BinDataWarning( ParserState *, const char * );
static void BinDataError( ParserState *, const char * );
static void BinDataFatalError( ParserState *, const char * );

// Utility functions:
int parse_xml_file(const char *);



/******************************************************************************
/*
/*	main & global data
/*
/*****************************************************************************/
char *dirPath;

int main(int ARGC, char **ARGV) {
	char *filePath;
	
	if( ARGC < 2 ) {
		fprintf( stdout, "Usage is:\n\t./preprocSAX -d=[directory path] [OME XML file]\n" );
		fprintf( stdout, "\n\n\t-d is optional. If specified, the extracted files will be written to the path indicated. That directory should already exist! If not specified, files will be written to current directory.\n" );
		return -1;
	}

	if( ARGC == 3 ) {
	// A path was specified
		dirPath = ARGV[1] + 3;
		filePath = ARGV[2];
		
		parse_xml_file(filePath);
	} else {
	// No path was specified
		dirPath = (char *) malloc( 3 );
		strcpy( dirPath, "./" );
		filePath = ARGV[1];
		
		parse_xml_file(filePath);
		
		free( dirPath );
	}
	
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
	xmlSAXHandler BinDataExtractSAXParser = {
		0, /* internalSubset */
		0, /* isStandalone */
		0, /* hasInternalSubset */
		0, /* hasExternalSubset */
		0, /* resolveEntity */
		0, /* getEntity */
		0, /* entityDecl */
		0, /* notationDecl */
		0,//(attributeDeclSAXFunc)BinDataExtractAttributeDecl, /* attributeDecl */
		0, /* elementDecl */
		0, /* unparsedEntityDecl */
		0, /* setDocumentLocator */
		(startDocumentSAXFunc)BinDataExtractStartDocument, /* startDocument */
		0, /* endDocument */
		(startElementSAXFunc)BinDataExtractStartElement, /* startElement */
		(endElementSAXFunc)BinDataExtractEndElement, /* endElement */
		0, /* reference */
		(charactersSAXFunc)BinDataExtractCharacters, /* characters */
		0, /* ignorableWhitespace */
		0, /* processingInstruction */
		0, /* comment */
		(warningSAXFunc)BinDataWarning, /* warning */
		(errorSAXFunc)BinDataError, /* error */
		(fatalErrorSAXFunc)BinDataFatalError, /* fatalError */
	};

	if (xmlSAXUserParseFile(&BinDataExtractSAXParser, &my_state, filename) < 0) {
		return NULL;
	} else
		return my_state.nBinDatas;
}



/******************************************************************************
/*
/*	SAX callback functions
/*
/*****************************************************************************/

static void BinDataExtractStartDocument(ParserState *state) {

	state->state	  = PARSER_START;
	state->nBinDatas  = 0;
	state->elementInfo = NULL;
	state->BinDataOut = NULL;
	
}



static void BinDataExtractStartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs) {
	char *localName, *binDataOutPath;
	int i, freeLocalName, pathLength;
	StructElementInfo* elementInfo;

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
	/* is this a BinData element?
	*/
	// Getting the namespace for an element is tricky. I haven't figured out 
	// how to do it yet, so I'm using the local name (BinData) to identify the
	// element.
	// I think http://cvs.gnome.org/lxr/source/gnorpm/find/search.c has some
	// code that will do it.
	// Find the local name of the element: strip the prefix if one exists.
	localName = strchr( name, ':' );
	if( localName != NULL ) {
		localName++;
		freeLocalName = 0;
	} else {
		localName = malloc( strlen(name) );
		strcpy( localName, name );
		freeLocalName = 1;
	}
	
	if( strcmp( BinDataLocal, localName ) == 0 ) {
		// Found a BinData Element!
		state->state      = PARSER_IN_BINDATA;
		state->nBinDatas++;
		
		// open the output file for the BinData contents
		binDataOutPath = (char *) malloc( 
			strlen( dirPath ) + 
			strlen( "/" ) +
			( (int) state->nBinDatas % 10 ) + 1 +
			strlen( ".out" ) +
			1 );
		sprintf( binDataOutPath, "%s/%i.out", dirPath, state->nBinDatas );
		state->BinDataOut = fopen( binDataOutPath, "w" );
		if( state->BinDataOut == NULL ) {
			fprintf( stderr, "Could not open file for output. Path is\n%s\n", binDataOutPath );
			exit -1;
		}

		// convert BinData to External
		fprintf( stdout, "<External xmlns=\"%s\" href=\"%s\"/>", BinNS, binDataOutPath );
		
		free( binDataOutPath );
	}
	/*
	/*************************************************************************/

	/**************************************************************************
	/*
	/* This isn't a BinData Element, pipe it through.
	*/
	// 
	else {
		// Stack maintence. Necessary for closing tags properly.
		elementInfo             = (StructElementInfo *) malloc( sizeof(StructElementInfo) );
		elementInfo->hasContent = 0;
		elementInfo->prev       = state->elementInfo;
		elementInfo->tagOpen    = 1;

		state->elementInfo      = elementInfo;

		// print the element.
		fprintf( stdout, "<%s ", name );
		if( attrs != NULL ) {
			// print the attributes.
			for( i=0;attrs[i] != NULL;i+=2 ) {
				fprintf( stdout, "%s = \"%s\" ", attrs[i], attrs[i+1] );
			}
		}
	}
	/*
	/*************************************************************************/

	if( freeLocalName == 1 ) 
		free( localName );

} // END BinDataExtractStartElement



static void BinDataExtractEndElement(ParserState *state, const xmlChar *name) {
	// We're at the end of an element. If the element had content, then we
	// need to print "</[elementName]>". If the element did not have 
	// content, then we need to print "/>". I'm using a stack to keep track
	// of element's content, so I gotta check the stack and do stack 
	// maintence.
	// Iff we are ending a BinData section, then we don't have to touch the
	// stack.
	char *localName;
	StructElementInfo *elementInfo;

	if( state->state == PARSER_IN_BINDATA ) {
	// BinData section
		state->state = PARSER_START;
		
		fclose( state->BinDataOut );
		state->BinDataOut = NULL;

	} else {
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
	
}



static void BinDataExtractCharacters(ParserState *state, const xmlChar *ch, int len) {
	char *buf;
	int i;
	size_t size_t_Len;
	
	// The tag begun by BinDataExtractStartElement might be open. If so, we 
	// need to close it so we can print the character contents of this element.
	if( state->elementInfo != NULL ) {
		state->elementInfo->hasContent = 1;
		if( state->elementInfo->tagOpen == 1 ) {
			fprintf( stdout, ">" );
			state->elementInfo->tagOpen = 0;
		}
	}

	// The character data needs to be streamed out. This switch directs 
	// the flow.
	size_t_Len = len;
	switch( state->state ) {
		case PARSER_START:
			fwrite( ch, size_t_Len, 1, stdout );
			fflush( stdout );
			break;
		case PARSER_IN_BINDATA:
			fwrite( ch, size_t_Len, 1, state->BinDataOut );
			fflush( state->BinDataOut );
			break;
	}
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
	exit -1;
}
static void BinDataFatalError( ParserState *state, const char *msg ) {
	fprintf( stderr, "Terminating program. The SAX parser reports this *FATAL* error message:\n%s", msg );
	exit -1;
}

