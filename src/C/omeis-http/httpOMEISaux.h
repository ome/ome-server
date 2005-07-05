#ifndef HTTP_OMEIS_AUX_H
#define HTTP_OMEIS_AUX_H

#include "httpOMEIS.h"

int OMEIStoMATLABDatatype (pixHeader* head);
void CtoOMEISDatatype (const char* data_type, pixHeader* head);
void OMEIStoCDatatype (char* data_type, pixHeader* head);
void** OMEIStoCArray (void* input, pixHeader* head, char* conversion_type);
#endif