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
 * Written by:	Ilya Goldberg <igg@nih.gov>    
 * 
 *------------------------------------------------------------------------------
 */

/******************************************************************************

	xmlIsOME.c
	
	Intent: determine if a file is an OME XML file.
	
	Maintence notes:
	The interesting part of this code is one function:
		OME_StartElement, 
	The parser moves sequentially through the document and calls this
	functions when it hits the beginning of an element.		

	Libraries: This program uses libxml2's SAX library.
	
******************************************************************************/


#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <libxml/parser.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "xmlIsOME.h"

/******************************************************************************
*
*	Data structures & Constants
*
******************************************************************************/
/* Names of elements this code is sensitive to */
#define OME_elem "OME"

#define OME_NS "http://www.openmicroscopy.org/XMLschemas/"


/* Contains all the information about the parser's state */
typedef struct {
	enum {
		PARSER_START,
		IN_OME,
	} state;
	char isOME;
} ParserState;

/******************************************************************************
*
*	Functions Declarations:
*
******************************************************************************/

/* SAX callbacks: */
static void OME_StartDocument(ParserState *state );
static void OME_StartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs);

int check_xml_file(const char *filename) {
    ParserState my_state;

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
		0, //(endDocumentSAXFunc)OME_EndDocument, /* endDocument */
		(startElementSAXFunc)OME_StartElement, /* startElement */
		0, /* endElement */
		0, /* reference */
		0, /* characters */
		0, /* ignorableWhitespace */
		0, /* processingInstruction */
		0, /* comment */
		0, //(warningSAXFunc)BinDataWarning, /* warning */
		0, //(errorSAXFunc)BinDataError, /* error */
		0, //(fatalErrorSAXFunc)BinDataFatalError, /* fatalError */
		0, /* getParameterEntitySAXFunc */
		0, /* cdataBlockSAXFunc */
		0, /* externalSubsetSAXFunc */
		0, /* initialized */
	};

	my_state.isOME = 0;
	if (xmlSAXUserParseFile(&xmlBinaryResolutionSAXParser, &my_state, filename) < 0) {
		return 0;
	}
	
	return ((int)my_state.isOME);
}

/******************************************************************************
*
*	SAX callback functions
*
******************************************************************************/

static void OME_StartDocument(ParserState *state) {

	state->state	               = PARSER_START;
	
}

static void OME_StartElement(ParserState *state, const xmlChar *name, const xmlChar **attrs) {
	char *localName;


	/**************************************************************************
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
	* OME
	* 	If we have a good namespace, its one of ours.
	*/
	if( strcmp( OME_elem, localName ) == 0 ) {

		state->state	               = IN_OME;
		while (*attrs != NULL && !state->isOME) {
			if (!strncmp (*attrs,"xmlns",5)) {
				if (strstr (*(attrs+1),OME_NS)) {
					state->isOME = 1;
				}
			}
			attrs+=2;
		}
	}
/* Temporary solution to recognize chains. Full solution is to merge the
Chains schema into the OME schema */
else if(strcmp( "AnalysisChain", localName ) == 0) {
	state->isOME = 1;
}
	/*
	**************************************************************************/


} /* END OME_StartElement */


