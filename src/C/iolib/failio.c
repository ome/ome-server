/* failio.c
 *
 * 		Wrappers for the C I/O library that exit on any error
 * with a (hopefully) descriptive message.
*/

#include "failio.h"
#include <errno.h>
#include <stdlib.h>
#include <string.h>

void* Allocate (size_t nBytes, const char* purpose)
{
	void* p = malloc (nBytes);
	if (!p) {
		fprintf (stderr, "Error: failed to allocate %d bytes %s\n", nBytes, purpose);
		exit (1);
	}
	return (p);
}

void* Reallocate (void* pOld, size_t nBytes, const char* purpose)
{
	void* p = realloc (pOld, nBytes);
	if (!p) {
		fprintf (stderr, "Error: failed to reallocate %d bytes %s\n", nBytes, purpose);
		exit (1);
	}
	return (p);
}

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
		fprintf (stderr, "Error %d (%s) while reading input file at offset %d.\n", errno, strerror(errno), br);
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

void CloseFile (FILE* fp)
{
	int ec = fclose (fp);
	if (ec != 0) {
		fprintf (stderr, "Error: %d (%s) while closing file.\n", errno, strerror(errno));
		exit (1);
	}

}

