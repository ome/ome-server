/* omextract.c
#
#	This program implements extraction of a region from an OME repository
# data file. The repository format is simply a 5-dimensional matrix of 16-bit
# values (color_t defined below).
#
# Usage:
# omextract InputFile=<path>	    - source repository
#	    OutputFile=<path>	    - destination repository
#	    Dims=x,y[,z,w,t]	    - dimensions of the source repository
#	    Start=x,y[,z,w,t]
#	    End=x,y[,z,w,t]	    - vectors to two bounding points in 5-space.
#
*/

#include <stdio.h>
#ifdef linux
    #include <unistd.h>
#else
    #include <io.h>
    #include <stdlib.h>
    #ifndef PATH_MAX	/* PATH_MAX is the Linux constant name */
	#define PATH_MAX _MAX_PATH
    #endif
#endif
#include <fcntl.h>
#include <malloc.h>
#include <errno.h>
#include <string.h>
#include <limits.h>
#include <ctype.h>

/*----------------------------------------------------------------------*/

#define MAX_COPY_BUFFER_SIZE	USHRT_MAX
#define CGI_ARGUMENT_SEPARATOR	'&'

#ifndef min
    #define min(a,b)	((a) < (b) ? (a) : (b))
#endif

typedef unsigned short	    color_t;	/* Single-pixel value in the repository */

typedef unsigned long int   coord_t;
typedef struct {
    coord_t	x;
    coord_t	y;
    coord_t	z;
    coord_t	w;
    coord_t	t;
} SPoint5D;

/*----------------------------------------------------------------------*/

void* Allocate (size_t nBytes, const char* purpose);
char* ConvertCLIArgsToCGI (int argc, char** argv);
void ExtractArgString (const char* cgiArgs, const char* argName, char* strBuf, size_t strBufSize);
void ExtractArg5DPoint (const char* cgiArgs, const char* argName, SPoint5D* pt);
void ExtractArguments (const char* cgiArgs, char* strInputFile, char* strOutputFile, SPoint5D* srcDim, SPoint5D* rgnStart, SPoint5D* rgnEnd);
FILE* OpenFile (const char* filename, const char* mode);
void Read (FILE* fp, void* buffer, size_t bufferSize);
void Write (FILE* fp, const void* buffer, size_t bufferSize);
void Seek (FILE* fp, long offset);
void FlushBuffer (FILE* ofp, void* buffer, size_t* pos);
void BufferedCopy (FILE* ifp, FILE* ofp, void* buffer, size_t* pos, size_t bytesToCopy);

/*----------------------------------------------------------------------*/

/* Wrapper for malloc that quits on failure */
void* Allocate (size_t nBytes, const char* purpose)
{
    void* p = malloc (nBytes);
    if (!p) {
	fprintf (stderr, "Error: failed to allocate %d %s\n");
	exit (1);
    }
    return (p);
}

/* Converts C argv array to a CGI-style argument string
 * like arg1=value1&arg2=value2&arg3=value3
*/
char* ConvertCLIArgsToCGI (int argc, char** argv)
{
    int i;
    size_t argStringSize = 1;	/* for \0 */
    char* unifiedArg;
    char* copyPtr;

    /* First, calculate storage needs */
    for (i = 1; i < argc; ++ i)
	argStringSize += strlen (argv[i]) + 1;

    unifiedArg = (char*) Allocate (argStringSize * sizeof(char), "for command-line argument processing");

    /* Now, concatenate with '&' separators */
    copyPtr = unifiedArg;
    for (i = 1; i < argc; ++ i) {
	strcpy (copyPtr, argv[i]);
	copyPtr += strlen (argv[i]);
	if (i < argc - 1)
	    *copyPtr++ = CGI_ARGUMENT_SEPARATOR;
    }
    *copyPtr = '\0';

    return (unifiedArg);
}

/* Extracts the string value for a named argument from a CGI argument string */
void ExtractArgString (const char* cgiArgs, const char* argName, char* strBuf, size_t strBufSize)
{
    const char* argPtr;
    const char* argValuePtr;
    const char* argValueEnd;
    size_t argValueSize;

    /* Search the string for the arg name */
    argPtr = strstr (cgiArgs, argName);
    if (!argPtr) {
	fprintf (stderr, "Error: argument '%s' must be specified.\n", argName);
	exit (1);
    }
    /* Value starts after the name and an '=' */
    argValuePtr = argPtr + strlen(argName) + 1;
    /* And copy data after '=' but before the next value */
    argValueEnd = strchr (argValuePtr, CGI_ARGUMENT_SEPARATOR);
    if (!argValueEnd)	/* Last value on the line will not have a terminator */
	argValueEnd = argValuePtr + strlen(argValuePtr);
    argValueSize = argValueEnd - argValuePtr;
    if (argValueSize > strBufSize)
	argValueSize = strBufSize - 1;
    strncpy (strBuf, argValuePtr, argValueSize);
    strBuf[argValueSize] = '\0';
}

/* Extracts a 5D point value ("pt=x,y,z,w,t") for a named argument
 * from a CGI argument string
*/
void ExtractArg5DPoint (const char* cgiArgs, const char* argName, SPoint5D* pt)
{
    int i;
    char buffer [32];
    const char* convPtr = buffer;

    ExtractArgString (cgiArgs, argName, buffer, 32);
    /* Convert non-numeric data to nuls */
    for (i = 0; i < 32; ++ i)
	if (!isdigit (buffer[i]))
	    buffer[i] = 0;
    pt->x = atol (convPtr); convPtr += strlen(convPtr) + 1;
    pt->y = atol (convPtr); convPtr += strlen(convPtr) + 1;
    pt->z = atol (convPtr); convPtr += strlen(convPtr) + 1;
    pt->w = atol (convPtr); convPtr += strlen(convPtr) + 1;
    pt->t = atol (convPtr);
}

/* Gets work parameters from the passed in CGI argument string */
void ExtractArguments (const char* cgiArgs, char* strInputFile, char* strOutputFile, SPoint5D* srcDim, SPoint5D* rgnStart, SPoint5D* rgnEnd)
{
    ExtractArgString (cgiArgs, "InputFile", strInputFile, PATH_MAX);
    ExtractArgString (cgiArgs, "OutputFile", strOutputFile, PATH_MAX);
    ExtractArg5DPoint (cgiArgs, "Dims", srcDim);
    ExtractArg5DPoint (cgiArgs, "Start", rgnStart);
    ExtractArg5DPoint (cgiArgs, "End", rgnEnd);
}

/*---------------------------------------------------------------------
 * The following block of functions wraps C I/O to quit on failure
*/
FILE* OpenFile (const char* filename, const char* mode)
{
    FILE* fp = fopen (filename, mode);
    if (!fp) {
	fprintf (stderr, "Error %d (%s) while opening file %s\n", errno, strerror(errno), filename);
	exit (1);
    }
    return (fp);
}

void Read (FILE* fp, void* buffer, size_t bufferSize)
{
    size_t br = fread (buffer, 1, bufferSize, fp);
    if (br != bufferSize) {
	fprintf (stderr, "Error %d (%s) while reading input file\n", errno, strerror(errno));
	exit (1);
    }
}

void Write (FILE* fp, const void* buffer, size_t bufferSize)
{
    size_t bw = fwrite (buffer, 1, bufferSize, fp);
    if (bw != bufferSize) {
	fprintf (stderr, "Error %d (%s) while writing output file\n", errno, strerror(errno));
	exit (1);
    }
}

void Seek (FILE* fp, long offset)
{
    int ec = fseek (fp, offset, SEEK_SET);
    if (ec) {
	fprintf (stderr, "Error: the specified region is larger than the input file.\n");
	exit (1);
    }
}

/* The two following functions implement a write-through buffer. Copy data is
 * read into the buffer and written to disk as the buffer gets full. Caller
 * should call FlushBuffer upon completion of all operations.
*/
void FlushBuffer (FILE* ofp, void* buffer, size_t* pos)
{
    Write (ofp, buffer, *pos);
    *pos = 0;
}

void BufferedCopy (FILE* ifp, FILE* ofp, void* buffer, size_t* pos, size_t bytesToCopy)
{
    size_t bytesRead = 0;
    char* pcBuffer;

    while (bytesToCopy) {
	pcBuffer = (char*) buffer + *pos;
	bytesRead = min (bytesToCopy, MAX_COPY_BUFFER_SIZE - *pos);
	Read (ifp, pcBuffer, bytesRead);
	*pos += bytesRead;
	if (*pos == MAX_COPY_BUFFER_SIZE)   /* Buffer full, flush */
	    FlushBuffer (ofp, buffer, pos);
	bytesToCopy -= bytesRead;
    }
}

/*-----------------------------------------------------------------------*/

int main (int argc, char** argv)
{
    char strInputFile [PATH_MAX], strOutputFile [PATH_MAX];
    SPoint5D srcDim, rgnStart, rgnEnd;
    SPoint5D srcElementSize;
    SPoint5D destElementSize;
    FILE *ifp = NULL, *ofp = NULL;
    void* copyBuffer = NULL;
    size_t copyBufferPos = 0;
    size_t t, w, z, y;
    char* cgiArgs = NULL;

    if (argc != 6) {
	fprintf (stderr, "Usage: %s InputFile=<path> OutputFile=<path> Dims=x,y[,z,w,t] Start=x,y[,z,w,t] End=x,y[,z,w,t]\n", argv[0]);
	exit (0);
    }

    cgiArgs = ConvertCLIArgsToCGI (argc, argv);
    ExtractArguments (cgiArgs, strInputFile, strOutputFile, &srcDim, &rgnStart, &rgnEnd);
    free (cgiArgs);

    ifp = OpenFile (strInputFile, "rb");
    ofp = OpenFile (strOutputFile, "wb");

    copyBuffer = Allocate (MAX_COPY_BUFFER_SIZE, "for copy buffer");

    srcElementSize.x = sizeof(color_t);
    srcElementSize.y = srcDim.x * srcElementSize.x;
    srcElementSize.z = srcDim.y * srcElementSize.y;
    srcElementSize.w = srcDim.z * srcElementSize.z;
    srcElementSize.t = srcDim.w * srcElementSize.w;

    destElementSize.x = sizeof(color_t);
    destElementSize.y = (rgnEnd.x - rgnStart.x + 1) * destElementSize.x;
    destElementSize.z = (rgnEnd.y - rgnStart.y + 1) * destElementSize.y;
    destElementSize.w = (rgnEnd.z - rgnStart.z + 1) * destElementSize.z;
    destElementSize.t = (rgnEnd.w - rgnStart.w + 1) * destElementSize.w;

    for (t = rgnStart.t; t <= rgnEnd.t; ++ t) {
	for (w = rgnStart.w; w <= rgnEnd.w; ++ w) {
	    for (z = rgnStart.z; z <= rgnEnd.z; ++ z) {
		for (y = rgnStart.y; y <= rgnEnd.y; ++ y) {
		    size_t offset = t * srcElementSize.t + w * srcElementSize.w +
			    z * srcElementSize.z + y * srcElementSize.y + rgnStart.x * srcElementSize.x;
		    Seek (ifp, offset);
		    BufferedCopy (ifp, ofp, copyBuffer, &copyBufferPos, destElementSize.y);
		}
	    }
	}
    }

    FlushBuffer (ofp, copyBuffer, &copyBufferPos);
    free (copyBuffer);

    fclose (ofp);
    fclose (ifp);
    return (0);
}

