/* argarray.h
 *
 * 		Functions for working arguments passed to the application
 * in various formats. CGI-POST, CGI-QUERY, or CLI.
*/

#ifndef ARGARRAY_H
#define ARGARRAY_H

#include <stdlib.h>	/* for size_t */

typedef struct {
	char*	m_Data;
	size_t	m_Allocated;
	size_t	m_nArgs;
} argarray_t;

typedef const char* argiterator_t;

void Argarray_Initialize (argarray_t* paa);
void Argarray_Destroy (argarray_t* paa);
void Argarray_ImportNameValueCLI (argarray_t* paa, int argc, char** argv);
void Argarray_ImportDashCLI (argarray_t* paa, int argc, char** argv);
void Argarray_ImportPOST (argarray_t* paa, const char* args, size_t argslen);
void Argarray_ImportQUERY (argarray_t* paa, const char* agrs, size_t argslen);
void Argarray_ImportPOSTFromStdin (argarray_t* paa);
void Argarray_DumpArgs (const argarray_t* paa);
int  Argarray_NameExists (const argarray_t* paa, const char* argName);
int  Argarray_VerifyRequiredArgs (const argarray_t* paa, const char** args);
const char* Argarray_GetString (const argarray_t* paa, const char* argName);
long Argarray_GetInteger (const argarray_t* paa, const char* argName);
long Argarray_GetIntegerArray (const argarray_t* paa, const char* argName, long* dest);
void Argiter_Initialize (const argarray_t* paa, argiterator_t* iter, const char* seedArgName);
const char* Argiter_NextString (argiterator_t* iter);
long Argiter_NextInteger (argiterator_t* iter);
float Argiter_NextFloat (argiterator_t* iter);
const void* memmem (const void* str, size_t strSize, const void* match, size_t matchSize);

#endif

