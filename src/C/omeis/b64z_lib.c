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
*
*	b64z_lib.c
*	
*	Originally written: June 4, 2003
****

	Notes: #define NO_VERBIAGE if you want to avoid all use of I/O
	int test(int verbosity) prints messages to stdout if verbosity is 1-3
	fatal errors generate messages to stderr before exiting with -1
	currently, all errors are fatal
	To COMPLETELY silence output, you must also define something else for
	bzip2, but I can't remember what it is.


*******************************************************************************
*******************************************************************************
******************************************************************************/

/* #define NO_VERBIAGE */

#ifndef NO_VERBIAGE
#include <stdio.h>
#endif

#include <stdlib.h>
#include <zlib.h>
#include <bzlib.h>
#include <string.h>
#include "base64.h"
#include "b64z_lib.h"

#define SIZEOF_BUF 1032 /* needs to be multiple of 3 && 4 */
#define BLOCK_SIZE_100K 9

/*	enum { none, bzip2, zlib }*/

/*****************************************************************************/
/**************                                                ***************/
/**************             Internal utilities                 ***************/
/**************                                                ***************/
/*****************************************************************************/



/******************************************************************************
*
*	b64z_mem_error - die with memory allocation error
*
*/
void b64z_mem_error (void) {
#ifndef NO_VERBIAGE
	fprintf( stderr, "Error! something in b64z_lib could not allocate memory!\n" );
#endif
	exit(-1);
}
/*
*	END 'b64z_mem_error'
*
******************************************************************************/


/******************************************************************************
*
*	decode base64 - specialized for base 64/zip decoder
*		returns the length of the decoded buffer
*/
/* decodes base64 data from 'strm->next_in' to 'to' & updates strm variables
/ len is the length of 'to'
*/
unsigned int _b64z_b64decode(  b64z_stream *strm, unsigned char* to, unsigned int len ) {
	unsigned int extracted = 0;
	int t; /* size needed to complete a buffered partial block */
	int r; /* partial block remainder */
	long rc; /* return code */
	unsigned char tmp_buf[4];
	
	/* deal with buffered input of partial blocks. 
	 *   strm->state->b64_buf will either be empty or contain a partial block
	 *   a partial block is an incomplete portion of a 4 byte base 64 block */
	if( strm->state->b64_buf[0] != 0 ) {
		t = 4 - strlen( strm->state->b64_buf );  /* size needed to complete block */
		if( strm->avail_in >= t ) {
			memcpy( strm->state->b64_buf + strlen( strm->state->b64_buf ), strm->next_in, t );
			strm->next_in  += t;
			strm->total_in += t;
			strm->avail_in -= t;
			
			if( len >= 3 ) {
				rc = base64_decode( to, strm->state->b64_buf, 4 );
				if( rc < 0 ) {
#ifndef NO_VERBIAGE
					fprintf( stderr, "Error! could not decode the base64 string!\n" );
#endif
					exit(-1);
				}
				extracted = (unsigned int) rc;
				to  += extracted;
				len -= extracted;
				strm->state->b64_buf[0] = 0;
			} 
			/* less than 3 bytes are available in 'to'.
			 *   determine if the decoded string can fit into 'to'. */
			else if (strm->state->b64_buf[3] == '=') { 
				extracted = base64_decode( tmp_buf, strm->state->b64_buf, 4 );
				if( extracted <= len ) {
					memcpy( to, tmp_buf, extracted );
					strm->state->b64_buf[0] = 0;
					return extracted;
				}
				return 0;
			} else {
				return 0;
			}
		} else {
			t = strm->avail_in;
			strncpy( strm->state->b64_buf + strlen( strm->state->b64_buf ), strm->next_in, t );
			strm->next_in  += t;
			strm->total_in += t;
			strm->avail_in -= t;
			return 0;
		}
	}

	/* Decode the largest whole block buffer amount possible. */
	if( len > strm->avail_in / 4 * 3 )
		len = strm->avail_in / 4 * 3;
	r = len % 3;
	len -= r;
	rc = base64_decode( to, strm->next_in, len * 4 / 3);
	if( rc < 0 ) {
#ifndef NO_VERBIAGE
		fprintf( stderr, "Error! could not decode the base64 string!\n" );
#endif
		exit(-1);
	}
	extracted += (unsigned int) rc;
	to += rc;
	strm->next_in  += rc * 4 / 3;
	strm->avail_in -= rc * 4 / 3;
	strm->total_in += rc * 4 / 3;

	/* If there is one block left in the input stream that ends with padding 
	 *   AND there is some room left in the output stream, 
	 *   THEN see if the decoded string will fit */
	if( strm->avail_in == 4 && strm->next_in[3] == '=' && r > 0 ) {
		rc = base64_decode( tmp_buf, strm->next_in, 4 );
		if( rc < 0 ) {
#ifndef NO_VERBIAGE
			fprintf( stderr, "Error! could not decode the base64 string!\n" );
#endif
			exit(-1);
		} else if( rc <= r ) {
			memcpy( to, tmp_buf, rc );
			strm->next_in  += rc * 4 / 3;
			strm->avail_in -= rc * 4 / 3;
			strm->total_in += rc * 4 / 3;
			extracted += rc;
			return extracted;
		}
	}
	else 
	/* if there is a partial block of input sitting around, suck it up */
	if( strm->avail_in < 4 && strm->avail_in > 0 ) { 
		strncpy( strm->state->b64_buf, strm->next_in, strm->avail_in );
		strm->state->b64_buf[strm->avail_in] = 0;
		strm->next_in  += strm->avail_in;
		strm->total_in += strm->avail_in;
		strm->avail_in  = 0;
	}


	return extracted;
}
/*
*	END 'decode base64'
*
******************************************************************************/


/******************************************************************************
*
*	encode base64 - specialized for base 64/zip decoder
*		returns the length of the encoded buffer
*/
/* encodes base64 data from 'from' to 'strm->next_out' & updates strm variables
/ len is the length of 'from'
*/
unsigned int _b64z_b64encode(  b64z_stream *strm, unsigned char* from, unsigned int *len, int action ) {
	unsigned int extracted;

	if( action != B64Z_FINISH ) 
		*len -= *len % 3;
	if( (*len + 2) / 3 * 4 > strm->avail_out )
		*len = strm->avail_out / 4 * 3;
	extracted = base64_encode( strm->next_out, from, *len );
	strm->next_out  += extracted;
	strm->avail_out -= extracted;
	strm->total_out += extracted;
	return extracted;
}
/*
*	END 'decode base64'
*
******************************************************************************/


/*****************************************************************************/
/**************                                                ***************/
/**************             Interface functions                ***************/
/**************                                                ***************/
/*****************************************************************************/



/******************************************************************************
*
*	b64z_new_stream
*		handy dandy utility to create and set up a new stream. You still need
*		to call b64z_decode_init to initialize the stream. This utility just 
*		saves a little bit of typing.
*/
b64z_stream *b64z_new_stream( unsigned char* next_in, unsigned int avail_in, unsigned char* next_out, unsigned int avail_out, int compression ) {
	b64z_stream *strm;
	
	strm = ( b64z_stream * ) malloc( sizeof( b64z_stream ) );
	if( !strm ) b64z_mem_error();
	
	strm->next_in   = next_in;
	strm->avail_in  = avail_in;
	strm->next_out  = next_out;
	strm->avail_out = avail_out;
	
	strm->compression = compression;
	
	return strm;	
}
/*
*	END 'b64z_new_stream'
*
*****************************************************************************/




/******************************************************************************
*******************************************************************************
*******************************************************************************
*
*	Stream initialization for DECODING
*		currently return value is pretty meaningless. it will always be B64Z_OK
*		If an error is encountered, a message is printed to stderr and the 
*		program exits with -1. This function has a return value to make 
*		altering error behavior easier.
*
*/
int b64z_decode_init( b64z_stream *strm ) {
	bz_stream *bzip_stream;
	z_stream  *zlib_stream;
	int rC;

	if( !strm ) {
#ifndef NO_VERBIAGE
		fprintf( stderr, "Error! b64z_decode_init was passed a NULL pointer!\n" );
#endif
		exit(-1);
	};
	
	strm->state = (b64z_internal_state *) malloc( sizeof( b64z_internal_state ) );
	if( !(strm->state) ) b64z_mem_error();
	strm->state->bzip_stream = NULL;
	strm->state->zlib_stream = NULL;

	strm->total_in  = 0;
	strm->total_out = 0;

	/* initialize compression streams */
	switch( strm->compression ) {
	
	/**************************************************************************
	*
	*	bzip2
	*
	*/
	  case bzip2:
		bzip_stream = (bz_stream *) malloc( sizeof( bz_stream ) );
		if( !bzip_stream ) b64z_mem_error();

		bzip_stream->bzalloc = NULL;
		bzip_stream->bzfree  = NULL;
		bzip_stream->opaque  = NULL;
		rC = BZ2_bzDecompressInit( bzip_stream, 0, 0 );
		if( rC != BZ_OK ) {
#ifndef NO_VERBIAGE
			fprintf( stderr, "Error! Could not initialize bzip2 decompression!\n" );
#endif
			exit(-1);
		}

		/* initialize stream parameters */
		bzip_stream->next_in   = (char *) strm->next_in;   /* *hopefully* this is a safe cast */
		bzip_stream->avail_in  = strm->avail_in;
		bzip_stream->next_out  = (char *) strm->next_out;  /* *hopefully* this is a safe cast */
		bzip_stream->avail_out = strm->avail_out;

		strm->state->bzip_stream = bzip_stream;
		break;
	/*
	*
	**************************************************************************/


	/**************************************************************************
	*
	*	zlib
	*
	*/
	  case zlib:
		zlib_stream = (z_stream *) malloc( sizeof( z_stream ));
		if( !zlib_stream ) b64z_mem_error();
		
		zlib_stream->zalloc   = NULL;
		zlib_stream->zfree    = NULL;
		zlib_stream->opaque   = NULL;
		zlib_stream->next_in  = (char *) strm->next_in;
		zlib_stream->avail_in = strm->avail_in;
		rC = inflateInit( zlib_stream );
		switch( rC ) {
			case Z_OK:
				break;
			case Z_MEM_ERROR:
#ifndef NO_VERBIAGE
				fprintf( stderr, "Error! zlib could not allocate memory to initialize.\nzlib reports:%s\n", zlib_stream->msg );
#endif
				exit(-1);
			case Z_VERSION_ERROR:
#ifndef NO_VERBIAGE
				fprintf( stderr, "Error! data was compressed with an incompatible version of zlib!\nzlib reports:%s\n", zlib_stream->msg );
#endif
				exit(-1);
			default:
#ifndef NO_VERBIAGE
				fprintf( stderr, "Error! zlib reported the following error on initialization:\n%s", zlib_stream->msg );
#endif
				exit(-1);
		}
		zlib_stream->next_out  = (char *) strm->next_out;  /* *hopefully* this is a safe cast */
		zlib_stream->avail_out = strm->avail_out;

		strm->state->zlib_stream = zlib_stream;
		break;
	/*
	*
	**************************************************************************/


	  case none:
	  default:
		break;
	} /* switch */

	/* initialize internal variables */
	strm->state->b64_buf[0] = strm->state->b64_buf[4] = 0;
	strm->state->buf_len    = 0;
	if( strm->compression == none ) {
		strm->state->buf = strm->state->buf_begin = NULL;
	} else {
		strm->state->buf_size = SIZEOF_BUF; /* default buffer size */
		strm->state->buf = (unsigned char *) malloc( strm->state->buf_size );
		if( ! (strm->state->buf) ) b64z_mem_error();
		strm->state->buf_begin = strm->state->buf;
	}
	
	return B64Z_OK;
}
/*
*	END 'Stream initialization for DECODING'
*
*******************************************************************************
*******************************************************************************
******************************************************************************/



/******************************************************************************
*******************************************************************************
*******************************************************************************
*
*	Decode a base64 compressed string.
*		This function will return B64Z_STREAM_END if the stream has ended.
*		The stream ends when the input is exhausted and intermediate buffers 
*		are flushed.
*
*	avail_in DOES NOT INDICATE THAT THE STREAM HAS ENDED! IF THIS FUNCTION HAS
*	NOT RETURNED B64Z_STREAM_END THEN THERE IS STILL DATA IN AN INTERMEDIATE 
*	BUFFER.
*
*/
int b64z_decode( b64z_stream *strm ) {
	/* pL is process Length - length of data to process */
	unsigned int pL;
	unsigned char *begin, *buf;
	unsigned int size, len;
	/* rL is return Length */
	unsigned int rL;
	/* rC is return Code */
	int rC;
	
	bz_stream *bzstr;
	z_stream *zstr;
	if( strm->avail_in  == 0 && strm->state->buf_len == 0 ) return B64Z_STREAM_END;
	if( strm->avail_out == 0 ) return B64Z_OK;

	/**************************************************************************
	*
	*	Convert uncompressed data.
	*/
	if( strm->compression == none ) {
		pL = strm->avail_out;
		
		rL = _b64z_b64decode( strm, strm->next_out, pL );
		strm->next_out  += rL;
		strm->avail_out -= rL;
		
		strm->total_out += rL;
	}
	/*
	**************************************************************************/


	/**************************************************************************
	*
	*	Convert compressed data. A buffer will hold the intermediate results.
	*
	*/
	else {
		begin = strm->state->buf_begin;
		buf   = strm->state->buf;
		len   = strm->state->buf_len;
		size  = strm->state->buf_size;
		while( (strm->avail_in > 0 || len > 0) && strm->avail_out > 0 ) {
		/* while there exists data to decompress and there is room to decompress it */

			/* decode base 64 */
			if( begin + len < buf + size &&
			    strm->avail_in > 0 ) {
				pL = ( buf + size - begin - len );
				rL = _b64z_b64decode( strm, begin + len, pL );
				len += rL;
			}

			/* decompress */
			switch( strm->compression ) {
			/******************************************************************
			*
			*	bzip2
			*
			*/
			  case bzip2:
				bzstr = strm->state->bzip_stream;
				bzstr->next_in   = begin;
				bzstr->avail_in  = len;
				bzstr->next_out  = strm->next_out;
				bzstr->avail_out = strm->avail_out;
				
				rC = BZ2_bzDecompress( bzstr );
				switch( rC ) {
				  case BZ_STREAM_END:
				  case BZ_OK:
					if( bzstr->avail_in == 0 ) {
						begin = buf;
						len   = 0;
					} else {
						begin = begin + len - bzstr->avail_in;
						len   = bzstr->avail_in;
					}
					strm->next_out  = bzstr->next_out;
					strm->avail_out = bzstr->avail_out;
					strm->total_out = bzstr->total_out_lo32;
					break;
				  default:
#ifndef NO_VERBIAGE
					fprintf( stderr, "Error! bzip2 decompression returned an error (%i)!\n", rC );
#endif
					exit(-1);
					/* for more error messages, see ftp://sources.redhat.com/pub/bzip2/docs/manual_3.html#SEC23 */
				}
				break;
			/*
			*
			******************************************************************/
		
		
			/******************************************************************
			*
			*	zlib
			*
			*/
			  case zlib:
				zstr = strm->state->zlib_stream;

				zstr->next_in   = begin;
				zstr->avail_in  = len;
				zstr->next_out  = strm->next_out;
				zstr->avail_out = strm->avail_out;

				rC = inflate( zstr, Z_SYNC_FLUSH );

				switch( rC ) {
				  case Z_STREAM_END:
				  case Z_OK:
					if( zstr->avail_in == 0 ) {
						begin = buf;
						len   = 0;
					} else {
						begin = begin + len - zstr->avail_in;
						len   = zstr->avail_in;
					}
					strm->next_out  = zstr->next_out;
					strm->avail_out = zstr->avail_out;
					strm->total_out = zstr->total_out;
					break;
				  default:
#ifndef NO_VERBIAGE
					fprintf( stderr, "Error! zlib decompression returned an error (%i)!\nmessage is:\n%s\nend of message\n", rC, zstr->msg );
#endif
					exit(-1);
					/* for more error messages, see http://www.gzip.org/zlib/manual.html#inflate */
				}
				break;
			/*
			*
			******************************************************************/

			  case none: /* this case will NEVER be hit. it may avoid a compiler warning though */
			  	break;
			  default:
#ifndef NO_VERBIAGE
				fprintf ( stderr, "Error! unable to discern the compression type!");
#endif
			} /* switch */
		} /* while */
		strm->state->buf_begin = begin;
		strm->state->buf_len   = len;
	} /* else */
	/*
	*	END 'Convert compressed data'
	*
	**************************************************************************/

	if( strm->avail_in == 0 && strm->state->buf_len == 0 ) return B64Z_STREAM_END;
	return B64Z_OK;
}
/*
*	END 'Decode a base64 compressed string.'
*
*******************************************************************************
*******************************************************************************
******************************************************************************/




/******************************************************************************
*******************************************************************************
*******************************************************************************
*
*	Stream closure for DECODING
*
*/
int b64z_decode_end( b64z_stream* strm ) {
	/* close compression streams */
	switch( strm->compression ) {
	
	/**************************************************************************
	*
	*	bzip2
	*
	*/
	  case bzip2:
		if( BZ2_bzDecompressEnd( strm->state->bzip_stream ) != BZ_OK ) {
#ifndef NO_VERBIAGE
			fprintf( stderr, "Error! bzip2 returned an error message when calling BZ2_bzDecompressEnd\n" );
#endif
			exit(-1);
		}
		free( strm->state->bzip_stream );
		strm->state->bzip_stream = NULL;
		return B64Z_OK;
	/*
	*
	**************************************************************************/


	/**************************************************************************
	*
	*	zlib
	*
	*/
	  case zlib:
		if( inflateEnd( strm->state->zlib_stream ) != Z_OK ) {
#ifndef NO_VERBIAGE
			fprintf( stderr, "Error! zlib gave an error message when calling inflateEnd\nmessage is:\n%s\nend of message\n", strm->state->zlib_stream->msg );
#endif
			exit(-1);
		}
		free( strm->state->zlib_stream );
		strm->state->zlib_stream = NULL;
		return B64Z_OK;
	/*
	*
	**************************************************************************/


	  case none:
	  default:
		break;
	} /* end "close compression streams" */
	
	
	/* cleanup internal variables */
	if( strm->state->buf ) free( strm->state->buf );
	free( strm->state );
	strm->state = NULL;
	
	return B64Z_OK;
}
/*
*	END 'Stream closure for DECODING'
*
*******************************************************************************
*******************************************************************************
******************************************************************************/



/******************************************************************************
*******************************************************************************
*******************************************************************************
*
*	Stream initialization for ENCODING
*		currently return value is pretty useless. it will always be B64Z_OK
*		If an error is encountered, a message is printed to stderr and the 
*		program exits with -1. This function has a return value to make 
*		altering error behavior easier.
*
*/
int b64z_encode_init( b64z_stream *strm ) {
	bz_stream *bzip_stream;
	z_stream  *zlib_stream;
	int rC;

	if( !strm ) {
#ifndef NO_VERBIAGE
		fprintf( stderr, "Error! b64z_encode_init was passed a NULL pointer!\n" );
#endif
		exit(-1);
	};
	
	strm->state = (b64z_internal_state *) malloc( sizeof( b64z_internal_state ) );
	if( !(strm->state) ) b64z_mem_error();
	strm->state->bzip_stream = NULL;
	strm->state->zlib_stream = NULL;

	strm->total_in  = 0;
	strm->total_out = 0;
	strm->state->compressStreamEnd = 0;

	/* initialize compression streams */
	switch( strm->compression ) {
	
	/**************************************************************************
	*
	*	bzip2
	*
	*/
	  case bzip2:
		bzip_stream = (bz_stream *) malloc( sizeof( bz_stream ) );
		if( !bzip_stream ) b64z_mem_error();

		bzip_stream->bzalloc = NULL;
		bzip_stream->bzfree  = NULL;
		bzip_stream->opaque  = NULL;
		rC = BZ2_bzCompressInit( bzip_stream, BLOCK_SIZE_100K, 0, 30 );
		if( rC != BZ_OK ) {
#ifndef NO_VERBIAGE
			fprintf( stderr, "Error! Could not initialize bzip2 compression! return code was %i\n", rC );
#endif
			exit(-1);
			/* for more error messages: ftp://sources.redhat.com/pub/bzip2/docs/manual_3.html#SEC19 */
		}

		/* initialize stream parameters */
		bzip_stream->next_in   = (char *) strm->next_in;   /* *hopefully* this is a safe cast */
		bzip_stream->avail_in  = strm->avail_in;
		bzip_stream->next_out  = (char *) strm->next_out;  /* *hopefully* this is a safe cast */
		bzip_stream->avail_out = strm->avail_out;

		strm->state->bzip_stream = bzip_stream;
		break;
	/*
	*
	**************************************************************************/


	/**************************************************************************
	*
	*	zlib
	*
	*/
	  case zlib:
		zlib_stream = (z_stream *) malloc( sizeof( z_stream ));
		if( !zlib_stream ) b64z_mem_error();
		
		zlib_stream->zalloc   = NULL;
		zlib_stream->zfree    = NULL;
		zlib_stream->opaque   = NULL;
		rC = deflateInit( zlib_stream, Z_DEFAULT_COMPRESSION );
		switch( rC ) {
			case Z_OK:
				break;
			case Z_MEM_ERROR:
#ifndef NO_VERBIAGE
				fprintf( stderr, "Error! zlib could not allocate memory to initialize.\nzlib reports:%s\n", zlib_stream->msg );
#endif
				exit(-1);
			case Z_VERSION_ERROR:
#ifndef NO_VERBIAGE
				fprintf( stderr, "Error! data was compressed with an incompatible version of zlib!\nzlib reports:%s\n", zlib_stream->msg );
#endif
				exit(-1);
			default:
#ifndef NO_VERBIAGE
				fprintf( stderr, "Error! zlib reported the following error (%i) on initialization:\n%s", rC, zlib_stream->msg );
#endif
				exit(-1);
				/* for more error messages: http://www.gzip.org/zlib/manual.html#deflateInit */
		}
		zlib_stream->next_in  = (char *) strm->next_in;    /* *hopefully* this is a safe cast */
		zlib_stream->avail_in = strm->avail_in;
		zlib_stream->next_out  = (char *) strm->next_out;  /* *hopefully* this is a safe cast */
		zlib_stream->avail_out = strm->avail_out;

		strm->state->zlib_stream = zlib_stream;
		break;
	/*
	*
	**************************************************************************/


	  case none:
	  default:
		break;
	}

	/* initialize internal variables */
	strm->state->buf_len    = 0;
	if( strm->compression == none ) {
		strm->state->buf = malloc( 3 );
		strm->state->buf_begin = NULL;
	} else {
		strm->state->buf_size = SIZEOF_BUF;
		strm->state->buf = (unsigned char *) malloc( strm->state->buf_size );
		if( ! (strm->state->buf) ) b64z_mem_error();
		strm->state->buf_begin = strm->state->buf;
	}
	
	return B64Z_OK;
}
/*
*	END 'Stream initialization for ENCODING'
*
*******************************************************************************
*******************************************************************************
******************************************************************************/



/******************************************************************************
*******************************************************************************
*******************************************************************************
*
*	Encode a binary string.
*		This function will return B64Z_STREAM_END if the stream has ended.
*		The stream ends when the input is exhausted and intermediate buffers 
*		are flushed.
*
*	avail_in DOES NOT INDICATE THAT THE STREAM HAS ENDED! IF THIS FUNCTION HAS
*	NOT RETURNED B64Z_STREAM_END THEN THERE IS STILL DATA IN AN INTERMEDIATE 
*	BUFFER.
*
*/
int b64z_encode( b64z_stream *strm, int action ) {
	/* pL is process Length - length of data to process */
	unsigned int pL;
	unsigned char *begin, *buf;
	unsigned int size, len;
	/* rC is return Code - it stores the return value of various functions */
	int rC;
	/* Unused variables
	int compStreamEnd;
	*/
	
	bz_stream *bzstr;
	z_stream *zstr;
	
	if( strm->avail_in == 0 && strm->state->buf_len == 0 && strm->state->compressStreamEnd == 1) return B64Z_STREAM_END;
	if( strm->avail_out == 0 ) return B64Z_OK;

	/**************************************************************************
	*
	*	Convert data without compressing.
	*/
	if( strm->compression == none ) {
		pL = strm->avail_in;
		
		_b64z_b64encode( strm, strm->next_in, &pL, action );
		strm->next_in  += pL;
		strm->avail_in -= pL;
		
		strm->total_in  += pL;
		
		if(strm->avail_in == 0 && action == B64Z_FINISH)
			strm->state->compressStreamEnd = 1;
		else
			strm->state->compressStreamEnd = 0;
	}
	/*
	**************************************************************************/


	/**************************************************************************
	*
	*	Convert data using compression.
	*		The pipeline consists of three buffers and two operations.
	*		strm->next_in feeds into compression which outputs to strm->buf
	*		strm->buf feeds into base64 encoding which outputs to strm->next_out
	*
	*		The places data may pool are inside the compression library and
	*		strm->buf. 
	*
	*/
	else {
		begin = strm->state->buf_begin;
		buf   = strm->state->buf;
		len   = strm->state->buf_len;
		size  = strm->state->buf_size;
		do {
		/* do while data exists to process and there is room to process the data */

			if( ( strm->avail_in > 0  || action == B64Z_FINISH ) && 
			    ( buf + size - begin - len) > 0 &&
			    strm->state->compressStreamEnd != 1 ) {
			/* if (there is input or action is finishing) and there is room for output
			/ if action is finishing and there is no input, there might still be a need to flush buffers
			/ if the stream has finished then do not run
			*/
			
			switch( strm->compression ) {
			/******************************************************************
			*
			*	bzip2 - compress
			*
			*/
			  case bzip2:
				bzstr = strm->state->bzip_stream;
				
				bzstr->next_in   = strm->next_in;
				bzstr->avail_in  = strm->avail_in;
				bzstr->next_out  = begin + len;
				bzstr->avail_out = buf + size - begin - len;

				if( action == B64Z_RUN )
					rC = BZ2_bzCompress( bzstr, BZ_RUN );
				else if( action == B64Z_FINISH )
					rC = BZ2_bzCompress( bzstr, BZ_FINISH );
				else {
#ifndef NO_VERBIAGE
					fprintf( stderr, "Error! Bad parameter (action => %i) passed to b64z_encode.\n", action );
#endif
					exit(-1);
				}
				
				switch( rC ) {
				  case BZ_STREAM_END:
					strm->state->compressStreamEnd = 1;
				  case BZ_FINISH_OK:
				  case BZ_OK:
				  case BZ_RUN_OK:
					strm->next_in   = bzstr->next_in;
					strm->avail_in  = bzstr->avail_in;
					len            += (buf + size - begin - len) - bzstr->avail_out;
					strm->total_in  = bzstr->total_in_lo32;
					break;
				  default:
#ifndef NO_VERBIAGE
					fprintf( stderr, "Error! bzip2 compression returned an error (%i)!\n", rC );
#endif
					exit(-1);
					/* for explanation of error messages, see ftp://sources.redhat.com/pub/bzip2/docs/manual_3.html#SEC23 */
				}
				break;
			/*
			*
			******************************************************************/
		
		
			/******************************************************************
			*
			*	zlib - compress
			*
			*/
			  case zlib:
				zstr = strm->state->zlib_stream;
				
				zstr->next_in   = strm->next_in;
				zstr->avail_in  = strm->avail_in;
				zstr->next_out  = begin + len;
				zstr->avail_out = buf + size - begin - len;
				if( action == B64Z_RUN )
					rC = deflate( zstr, Z_NO_FLUSH );
				else if( action == B64Z_FINISH )
					rC = deflate( zstr, Z_FINISH );
				else {
#ifndef NO_VERBIAGE
					fprintf( stderr, "Error! Bad parameter (action => %i) passed to b64z_encode.\n", action );
#endif
					exit(-1);
				}
				
				switch( rC ) {
				  case Z_STREAM_END:
					strm->state->compressStreamEnd = 1;
				  case Z_OK:
					strm->next_in   = zstr->next_in;
					strm->avail_in  = zstr->avail_in;
					len            += (buf + size - begin - len) - zstr->avail_out;
					strm->total_in  = zstr->total_in;
					break;
				  default:
#ifndef NO_VERBIAGE
					fprintf( stderr, "Error! zlib decompression returned an error (%i)!\nmessage is:\n%s\nend of message\n", rC, zstr->msg );
#endif
					exit(-1);
					/* for explanation of error messages, see http://www.gzip.org/zlib/manual.html#deflate */
				}
				break;
			/*
			*
			******************************************************************/
		
			  case none: /* this case will NEVER be hit, but it may avoid compiler warnings */
				break;
		
#ifndef NO_VERBIAGE
			  default:
				fprintf (stderr, "Error! Unable to discern the compression type!");
#endif

			} /* switch( compression ) */
			} /* if */

			/* encode base 64 */
			if(len > 3 || (len > 0 && action == B64Z_FINISH)) { /* don't bother trying to encode if there is nothing to encode */
				pL = len;
				if( strm->state->compressStreamEnd == 1 && action == B64Z_FINISH ) 
					rC = _b64z_b64encode( strm, begin, &pL, action );
				else
					rC = _b64z_b64encode( strm, begin, &pL, B64Z_RUN );
				begin += pL;
				len   -= pL;
				if( len == 0 ) begin = buf;
			}

		} while( (strm->avail_in > 0 || (len > 3 || (len > 0 && action == B64Z_FINISH))) && strm->avail_out >= 4 );
		/* 'len > 3' uses '3' because 3 is the smallest block possible to encode with base64 unless you are at the end of a stream
		/ 'strm->avail_out >= 4' uses '4' because 4 is the smallest base64 block
		/ if the output space available is less than that, we can't do anything.
		*/
		
		strm->state->buf_begin = begin;
		strm->state->buf_len   = len;
		
	} /* else */
	/*
	*	END 'Convert data...'
	*
	**************************************************************************/

	if( strm->avail_in == 0 && strm->state->buf_len == 0 && strm->state->compressStreamEnd == 1) return B64Z_STREAM_END;
	return B64Z_OK;
}
/*
*	END 'Encode a binary string.'
*
*******************************************************************************
*******************************************************************************
******************************************************************************/




/******************************************************************************
*******************************************************************************
*******************************************************************************
*
*	Stream closure for ENCODING
*
*/
int b64z_encode_end( b64z_stream* strm ) {
	/* close compression streams */
	switch( strm->compression ) {
	
	/**************************************************************************
	*
	*	bzip2
	*
	*/
	  case bzip2:
		if( BZ2_bzCompressEnd( strm->state->bzip_stream ) != BZ_OK ) {
#ifndef NO_VERBIAGE
			fprintf( stderr, "Error! bzip2 returned an error message when calling BZ2_bzDecompressEnd\n" );
#endif
			exit(-1);
		}
		free( strm->state->bzip_stream );
		strm->state->bzip_stream = NULL;
		return B64Z_OK;
	/*
	*
	**************************************************************************/


	/**************************************************************************
	*
	*	zlib
	*
	*/
	  case zlib:
		if( deflateEnd( strm->state->zlib_stream ) != Z_OK ) {
#ifndef NO_VERBIAGE
			fprintf( stderr, "Error! zlib gave an error message when calling inflateEnd\nmessage is:\n%s\nend of message\n", strm->state->zlib_stream->msg );
#endif
			exit(-1);
		}
		free( strm->state->zlib_stream );
		strm->state->zlib_stream = NULL;
		return B64Z_OK;
	/*
	*
	**************************************************************************/


	  case none:
	  default:
		break;
	} /* end "close compression streams" */
	
	
	/* cleanup internal variables */
	if( strm->state->buf ) free( strm->state->buf );
	free( strm->state );
	strm->state = NULL;
	
	return B64Z_OK;
}
/*
*	END 'Stream closure for ENCODING'
*
******************************************************************************/


/******************************************************************************
*
* test
* 	tests this library & provides example usage of the library's code
* 	It returns the number of tests failed.
* 	this WILL WRITE TO stdout if verbosity is non zero.
* 	Allowed values of verbosity are 0-2, with 0 being silent, 1 being succinct, and 2 being verbose
*
*/
int test(char debug) {
	b64z_stream *strm;
	int rC;	/* return Code */
	int action_code, n_failures = 0, n_tests;
	unsigned int len_of_remaining_input;
	
	const int resultBufSize = 512;
	const int len_strm_input = 7;
	const int len_strm_output = 7;

	unsigned char *testString = "\"The state can't give you free speech, and the state can't take it away. You're born with it, like your eyes, like your ears. Freedom is something you assume, then you wait for someone to try to take it away. The degree to which you resist is the degree to which you are free...\"\n---Utah Phillips";
	unsigned char *dec, *enc;
	compression_type comps[] = { none, bzip2, zlib };
	char *comp_labels[] = {"none", "bzip2", "zlib" };

	for(n_tests=0;n_tests<3;n_tests++) {
		enc = (unsigned char *) malloc( resultBufSize );
		dec = (unsigned char *) malloc( resultBufSize );
		if( enc == NULL || dec == NULL ) {
#ifndef NO_VERBIAGE
			fprintf( stderr, "out of memory!\n" );
#endif
			exit(-1);
		}
			
#ifndef NO_VERBIAGE
		if( debug ) fprintf( stdout, "Testing conversion using compression '%s'\n", comp_labels[n_tests] );
		if( debug == 2 ) fprintf( stdout, "\toriginal: %s\n", testString );
#endif

		strm = b64z_new_stream( NULL, 0, NULL, 0, comps[n_tests] );
		/* b64z_new_stream(next_in, avail_in, next_out, avail_out, compression); */
		b64z_encode_init( strm );
	
		len_of_remaining_input = strlen( testString );
		strm->next_in  = testString;
		strm->avail_in = 0;
		action_code = B64Z_RUN;
		do {
			if( len_of_remaining_input > len_strm_input ) {
				strm->avail_in += len_strm_input;
				len_of_remaining_input -= len_strm_input;
			}
			else {
				strm->avail_in += len_of_remaining_input;
				len_of_remaining_input = 0;
				action_code = B64Z_FINISH;
			}
			
			strm->next_out = enc + strm->total_out;
			strm->avail_out = len_strm_output;

			rC = b64z_encode( strm, action_code );
			/* Remember, when using b64z_encode, you must request for the 
			/ stream to end.
			/ The stream WILL NOT END until you request it. Also, it may 
			/ require more than one call to flush the internal buffers. Also,
			/ bzip2 will barf if you supply more input after you request the
			/ stream to end. I haven't tested what the other compression 
			/ schemes do in that situation, but I would advise NOT TO DO IT.
			*/			
		} while(rC != B64Z_STREAM_END);

		b64z_encode_end( strm );
		enc[strm->total_out] = 0;

#ifndef NO_VERBIAGE
		if( debug == 2 ) fprintf( stdout, "\tencoded : %s\n", enc );
#endif
		len_of_remaining_input = strm->total_out;
	
	/* DECODE */
		b64z_decode_init( strm );

		strm->next_in  = enc;
		strm->avail_in = 0;
		do {
			if( len_of_remaining_input > len_strm_input ) {
				strm->avail_in += len_strm_input;
				len_of_remaining_input -= len_strm_input;
			}
			else {
				strm->avail_in += len_of_remaining_input;
				len_of_remaining_input ^= len_of_remaining_input;  /* equiv to 'len_of_remaining_input = 0;' */
			}
			
			strm->next_out = dec + strm->total_out;
			strm->avail_out = len_strm_output;

			rC = b64z_decode( strm );
		} while(! (len_of_remaining_input == 0 && rC == B64Z_STREAM_END));
		/* b64z_decode will return B64Z_STREAM_END any time the input buffer
		/ and internal buffers are empty. This behavior is very distinct from 
		/ the behavior of b64z_encode.
		*/
		
		b64z_decode_end( strm );

		dec[strm->total_out] = 0;
#ifndef NO_VERBIAGE
		if( debug == 2 ) fprintf( stdout, "\tdecoded : %s\n", dec );
		if( debug ) {
			if( strcmp( testString, dec ) != 0 ) {
				n_failures++;
				fprintf( stdout, "\tError! Test failed. The original string and the final string differ!\n" );
			}
			else
				fprintf( stdout, "\tTest passed.\n" );
		}
#endif
	
		free( strm );
		free( enc );
		free( dec );
	}
#ifndef NO_VERBIAGE
	if( debug ) {
		if( n_failures == 0 ) fprintf( stdout, "Passed all %i tests\n", n_tests );
		else fprintf( stdout, "Failed %i out of %i tests\n", n_failures, n_tests );
	}
#endif
		
	return n_failures;
}
/*
* END 'test'
*
******************************************************************************/
