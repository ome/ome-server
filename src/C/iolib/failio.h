/* failio.h
 *
 * 		Wrappers for the C I/O library that exit on any error
 * with a (hopefully) descriptive message.
*/

#ifndef FAILIO_H
#define FAILIO_H

#include <stdio.h>

void* Allocate (size_t nBytes, const char* purpose);
void* Reallocate (void* pOld, size_t nBytes, const char* purpose);
FILE* OpenFile (const char* filename, const char* mode);
void Read (FILE* fp, void* buffer, size_t bufferSize);
void Write (FILE* fp, const void* buffer, size_t bufferSize);
void Seek (FILE* fp, long offset);
void CloseFile (FILE* fp);

#endif

