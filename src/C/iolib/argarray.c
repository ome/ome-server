/* argarray.c
 *
 * 		Functions for working arguments passed to the application
 * in various formats. CGI-POST, CGI-QUERY, or CLI. Internal representation
 * is in Name=Value pairs separated by ARGUMENT_SEPARATOR character.
*/

#include "argarray.h"
#include "failio.h"
#include <string.h>
#include <memory.h>

#define ARGUMENT_SEPARATOR	'\0'

void Argarray_Initialize (argarray_t* paa)
{
	paa->m_Allocated = 1;
	paa->m_Data = (char*) Allocate (paa->m_Allocated, "for the argarray_t NUL terminator");
	paa->m_nArgs = 0;
}

void Argarray_Destroy (argarray_t* paa)
{
	if (paa->m_Data)
		free (paa->m_Data);
}

#define APP_NAME_ENTRY_LENGTH 8
#define APP_NAME_ENTRY	"AppName="

void Argarray_ImportNameValueCLI (argarray_t* paa, int argc, char** argv)
{
	int i;
	size_t argStringSize = APP_NAME_ENTRY_LENGTH;
	char* copyPtr;
	size_t insertPoint = paa->m_Allocated - 1;

	/* First, calculate storage needs */
	for (i = 0; i < argc; ++ i)
		argStringSize += strlen (argv[i]) + 1;

	paa->m_Allocated += argStringSize;
	paa->m_Data = (char*) Reallocate (paa->m_Data, paa->m_Allocated, "for command-line argument processing");

	/* Now, concatenate with separators */
	copyPtr = paa->m_Data + insertPoint;
	/* Special case for the app name */
	memcpy (copyPtr, APP_NAME_ENTRY, APP_NAME_ENTRY_LENGTH);
	copyPtr += APP_NAME_ENTRY_LENGTH;
	/* The rest are normal */
	for (i = 0; i < argc; ++ i) {
		size_t argLen = strlen(argv[i]);
		memcpy (copyPtr, argv[i], argLen);
		copyPtr += argLen;
		*copyPtr++ = ARGUMENT_SEPARATOR;
		++ paa->m_nArgs;
	}
	*copyPtr = 0;
}

/* This is very ugly, so please convert to a better argument format, so
 * this function could be destroyed.
 */
void Argarray_ImportDashCLI (argarray_t* paa, int argc, char** argv)
{
	int i;
	size_t argStringSize = APP_NAME_ENTRY_LENGTH;
	char* copyPtr;
	size_t insertPoint = paa->m_Allocated - 1;

	/* First, calculate storage needs
	 * Three variants:
	 * 		-option			=> 'option='		i.e. empty value
	 * 		-option value	=> 'option=value'
	 * 		value			=> 'value'
	 * The last variant is the only one in which characters must be added.
	 **/
	for (i = 0; i < argc; ++ i) {
		argStringSize += strlen (argv[i]) + 1;
		if (i < argc - 1 && *argv[i] == '-' && *argv[i + 1] != '-')
			-- argStringSize;	/* option=value saves a separator over option=,value */
	}

	paa->m_Allocated += argStringSize;
	paa->m_Data = (char*) Reallocate (paa->m_Data, paa->m_Allocated, "for command-line argument processing");

	/* Now, concatenate with separators */
	copyPtr = paa->m_Data + insertPoint;
	/* Special case for the app name */
	memcpy (copyPtr, APP_NAME_ENTRY, APP_NAME_ENTRY_LENGTH);
	copyPtr += APP_NAME_ENTRY_LENGTH;
	/* The rest are normal */
	for (i = 0; i < argc; ++ i) {
		size_t argLen = strlen(argv[i]);
		memcpy (copyPtr, argv[i], argLen);
		/* -option => option= */
		if (*copyPtr == '-') {
			memmove (copyPtr, copyPtr + 1, argLen - 1);
			copyPtr[argLen - 1] = '=';
		}
		copyPtr += argLen;
		/* If the next arg is not a dash, it is this one's value;
		 * that is the only case when we omit the separator */
		if (i == argc - 1 || *argv[i] != '-' || *argv[i + 1] == '-') {
			*copyPtr++ = ARGUMENT_SEPARATOR;
			++ paa->m_nArgs;
		}
	}
	*copyPtr = 0;
}

static size_t strreplace (char* s, size_t ssize, char c1, char c2)
{
	size_t nReplaced = 0;
    while (ssize--) {
		if (*s == c1) {
			*s = c2;
			++ nReplaced;
		}
		++ s;
	}
	return (nReplaced);
}

/*
 * This assumes the following input format:
 * Name=Value\nName=Value\n...\nName=Value\n
*/
void Argarray_ImportPOST (argarray_t* paa, const char* args, size_t argslen)
{
	size_t insertPoint = paa->m_Allocated - 1;
	paa->m_Allocated += argslen;
	paa->m_Data = (char*) Reallocate (paa->m_Data, paa->m_Allocated, "for POST argument processing");
	memcpy (paa->m_Data + insertPoint, args, argslen);
	paa->m_nArgs += strreplace (paa->m_Data + insertPoint, argslen, '\n', ARGUMENT_SEPARATOR);
	paa->m_Data [paa->m_Allocated - 1] = 0;
}

/*
 * This assumes the following input format:
 * Name=Value&Name=Value&...&Name=Value
*/
void Argarray_ImportQUERY (argarray_t* paa, const char* args, size_t argslen)
{
	size_t insertPoint = paa->m_Allocated - 1;
	paa->m_Allocated += argslen + 1;
	paa->m_Data = (char*) Reallocate (paa->m_Data, paa->m_Allocated, "for POST argument processing");
	memcpy (paa->m_Data + insertPoint, args, argslen);
	paa->m_nArgs += strreplace (paa->m_Data + insertPoint, argslen, '&', ARGUMENT_SEPARATOR) + 1;
	paa->m_Data [insertPoint + argslen] = ARGUMENT_SEPARATOR;
	paa->m_Data [paa->m_Allocated - 1] = 0;
}

void Argarray_ImportPOSTFromStdin (argarray_t* paa)
{
	#define BUFFER_SIZE 4096
	char buffer [BUFFER_SIZE];
	size_t bytesRead = BUFFER_SIZE;
	size_t lastArgEnd = 0;
	while (bytesRead == BUFFER_SIZE) {
		bytesRead = fread (buffer, 1, BUFFER_SIZE, stdin);
		if (bytesRead == 0 || NULL == strchr (buffer, '\n'))
			break;
		lastArgEnd = strrchr (buffer, '\n') - buffer + 1;
		Argarray_ImportPOST (paa, buffer, lastArgEnd);
		memmove (buffer, buffer + lastArgEnd, bytesRead - lastArgEnd);
	}
}

void Argarray_DumpArgs (const argarray_t* paa)
{
	size_t i;
	const char* printPtr;
	if (!paa) {
		fprintf (stderr, "argarray_t == NULL\n");
		return;
	}
	fprintf (stderr, "argarray with %d args, %d bytes allocated\n", paa->m_nArgs, paa->m_Allocated);
	/* The arguments are NUL-separated, so need to skip over the 0s */
    printPtr = paa->m_Data;
	for (i = 0; i < paa->m_nArgs; ++ i) {
		fprintf (stderr, "%s\n", printPtr);
		printPtr += strlen(printPtr) + 1;
	}
}

int Argarray_NameExists (const argarray_t* paa, const char* argName)
{
	return (NULL != memmem (paa->m_Data, paa->m_Allocated, argName, strlen(argName)));
}

/* args is in the format of argName,description,argName,description,...,"","" */
int Argarray_VerifyRequiredArgs (const argarray_t* paa, const char** args)
{
	size_t curArg = 0;
	int nFailed = 0;
	while (*args[curArg * 2]) {
		if (!Argarray_NameExists (paa, args[curArg * 2])) {
			++ nFailed;
			fprintf (stderr, "Argument %s (%s) must be specified.\n", args[curArg * 2], args[curArg * 2 + 1]);
		}
		++ curArg;
	}
	return (nFailed == 0);
}

/*
 * This copies the value of the argument, if any, into strBuf.
 * If the argument does not exist, you'll get an empty string in strBuf.
*/
const char* Argarray_GetString (const argarray_t* paa, const char* argName)
{
	size_t argNameLen = strlen(argName);
	const char* searchPtr = paa->m_Data;
	const char* argPtr = NULL;
	while (searchPtr && searchPtr - paa->m_Data < paa->m_Allocated) {
		/* Search the string for the arg name */
		argPtr = (const char*) memmem (searchPtr, paa->m_Allocated - (searchPtr - paa->m_Data), argName, argNameLen);
		if (!argPtr)
			break;
		/* Exclude partial matches */
		if (argPtr[argNameLen] == '=' && (argPtr == paa->m_Data || argPtr[-1] == 0))
			break;
		searchPtr = argPtr + 1;
	}
	/* Value starts after the name and an '=' */
	return (argPtr ? argPtr + argNameLen + 1 : NULL);
}

long Argarray_GetInteger (const argarray_t* paa, const char* argName)
{
	const char* argString = Argarray_GetString (paa, argName);
	return (argString ? atol(argString) : 0);
}

void Argiter_Initialize (const argarray_t* paa, argiterator_t* iter, const char* seedArgName)
{
	*iter = Argarray_GetString (paa, seedArgName);
}

const char* Argiter_NextString (argiterator_t* iter)
{
	/* Move on to the next arg */
	return (*iter ? *iter += strlen (*iter) + 1 : NULL);
}

long Argiter_NextInteger (argiterator_t* iter)
{
	const char* argString = Argiter_NextString (iter);
	return (argString ? atol(argString) : 0);
}

float Argiter_NextFloat (argiterator_t* iter)
{
	const char* argString = Argiter_NextString (iter);
	return (argString ? atof(argString) : 0.0);
}

const void* memmem (const void* str, size_t strSize, const void* match,
size_t matchSize)
{
	int i;
	const char* cstr = (const char*) str;
	if (matchSize <= strSize)
		for (i = 0; i < (strSize - matchSize) + 1; ++ i)
			if (0 == memcmp (cstr + i, match, matchSize))
				return (cstr + i);
	return (NULL);
}
