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

#ifndef xmlBinaryResolution_h
#define xmlBinaryResolution_h

#include <libxml/parser.h>
#include <zlib.h>
#include <bzlib.h>
#include "../base64.h"
#include "../b64z_lib.h"
#include "Pixels.h"

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


/* Returns -1 on error, number of extracted files on success. */
int parse_xml_file(const char *filename);

#endif
