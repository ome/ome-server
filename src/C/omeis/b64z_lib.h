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

	b64z_lib.h
	
	Originally written: June 4, 2003
	
****

	Intent: This library provides a simple mechanism to convert between binary
	and base64 format with the intermediate step of compression. It supports
	bzip2 compression and the compression used by the zlib library. The zlib 
	library uses a compression algorithm that is essentially the same as the 
	one used by gzip. The structs and interface are modelled after those of the
	libraries.

	Libraries: This relies on 2 compression libraries: bzip2 and zlib. Both are
	open source and highly portable. Those libaries can be found at:
		http://www.gzip.org/zlib/
		http://sources.redhat.com/bzip2/



******************************************************************************
******************************************************************************
*****************************************************************************/

#include <zlib.h>
#include <bzlib.h>


// return codes
#define B64Z_OK 0
#define B64Z_FINISHING 1
#define B64Z_STREAM_END 2

// action codes
#define B64Z_RUN 0
#define B64Z_FINISH 1

#define compression_type enum { bzip2, zlib, none }

typedef struct {
	bz_stream *bzip_stream;
	z_stream  *zlib_stream;

	unsigned char *buf;
	unsigned char *buf_begin;
	unsigned int buf_size;
	unsigned int buf_len;
	
	unsigned char b64_buf[5];
	
	short int compressStreamEnd;
} b64z_internal_state;

typedef struct {
	unsigned char *next_in;
	unsigned int avail_in;
	unsigned long total_in;
	
	unsigned char *next_out;
	unsigned int avail_out;
	unsigned long total_out;
	
	b64z_internal_state *state;
	
	compression_type compression;

} b64z_stream;

// creates a b64z stream
b64z_stream *b64z_new_stream( unsigned char* in, unsigned int avail_in, unsigned char* out, unsigned int avail_out, int compression );

// the following functions mimic the interface of zlib & bzip2
int b64z_decode_init( b64z_stream *strm );
int b64z_decode( b64z_stream *strm );
int b64z_decode_end( b64z_stream* strm );
int b64z_encode_init( b64z_stream *strm );
int b64z_encode( b64z_stream *strm, int action );
int b64z_encode_end( b64z_stream* strm );

// tests the library. Also the code is a working example of the library.
int test(char debug);

