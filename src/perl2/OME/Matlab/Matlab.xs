/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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
 * Written by:   
 * 
 *------------------------------------------------------------------------------
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "matrix.h"
#include "engine.h"
typedef mxArray* OME__Matlab__Array;
typedef Engine*  OME__Matlab__Engine;

MODULE = OME::Matlab	PACKAGE = OME::Matlab

mxComplexity
__mxREAL()
        CODE:
                RETVAL = mxREAL;
        OUTPUT:
                RETVAL

mxComplexity
__mxCOMPLEX()
        CODE:
                RETVAL = mxCOMPLEX;
        OUTPUT:
                RETVAL

mxClassID
__mxUNKNOWN_CLASS()
        CODE:
                RETVAL = mxUNKNOWN_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxCELL_CLASS()
        CODE:
                RETVAL = mxCELL_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxSTRUCT_CLASS()
        CODE:
                RETVAL = mxSTRUCT_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxOBJECT_CLASS()
        CODE:
                RETVAL = mxOBJECT_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxCHAR_CLASS()
        CODE:
                RETVAL = mxCHAR_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxLOGICAL_CLASS()
        CODE:
                RETVAL = mxLOGICAL_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxDOUBLE_CLASS()
        CODE:
                RETVAL = mxDOUBLE_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxSINGLE_CLASS()
        CODE:
                RETVAL = mxSINGLE_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxINT8_CLASS()
        CODE:
                RETVAL = mxINT8_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxUINT8_CLASS()
        CODE:
                RETVAL = mxUINT8_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxINT16_CLASS()
        CODE:
                RETVAL = mxINT16_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxUINT16_CLASS()
        CODE:
                RETVAL = mxUINT16_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxINT32_CLASS()
        CODE:
                RETVAL = mxINT32_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxUINT32_CLASS()
        CODE:
                RETVAL = mxUINT32_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxINT64_CLASS()
        CODE:
                RETVAL = mxINT64_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxUINT64_CLASS()
        CODE:
                RETVAL = mxUINT64_CLASS;
        OUTPUT:
                RETVAL

mxClassID
__mxFUNCTION_CLASS()
        CODE:
                RETVAL = mxFUNCTION_CLASS;
        OUTPUT:
                RETVAL

MODULE = OME::Matlab	PACKAGE = OME::Matlab::Array

OME::Matlab::Array
newDoubleScalar(package,value)
        const char *package = NO_INIT;
        double value
        CODE:
                RETVAL = mxCreateDoubleScalar(value);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newLogicalScalar(package,value)
        const char *package = NO_INIT;
        mxLogical value
        CODE:
                RETVAL = mxCreateLogicalScalar(value);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newDoubleMatrix(package,m,n,complexity=mxREAL)
        const char *package = NO_INIT;
        int m
        int n
        mxComplexity complexity
        CODE:
                RETVAL = mxCreateDoubleMatrix(m,n,complexity);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newLogicalMatrix(package,m,n)
        const char *package = NO_INIT;
        int m
        int n
        CODE:
                RETVAL = mxCreateLogicalMatrix(m,n);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newNumericMatrix(package,m,n,classID=mxDOUBLE_CLASS,complexity=mxREAL)
        const char *package = NO_INIT;
        int m
        int n
        mxClassID classID
        mxComplexity complexity
        CODE:
                RETVAL = mxCreateNumericMatrix(m,n,classID,complexity);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newStructMatrix(package,m,n,field_names_ref)
        const char *package = NO_INIT;
        int m
        int n
        SV * field_names_ref
        INIT:
                AV      *field_names;
                int     i, numfields;
                const char  **fields;
                SV      **aval;
                STRLEN  field_len;

                if (!SvROK(field_names_ref))
                {
                    croak("newStructMatrix expects a reference for $fieldNames");
                }

                if (SvTYPE(SvRV(field_names_ref)) != SVt_PVAV)
                {
                    croak("newStructMatrix expects an array ref for $fieldNames");
                }

                field_names = (AV *) SvRV(field_names_ref);
                numfields = av_len(field_names)+1;
        CODE:
                fields = mxCalloc(numfields,sizeof(char *));
                for (i = 0; i < numfields; i++)
                {
                    aval = av_fetch(field_names,i,0);
                    if (aval != NULL)
                    {
                        fields[i] = SvPV(*aval,field_len);
                    }
                }
                RETVAL = mxCreateStructMatrix(m,n,numfields,fields);
                mxFree(fields);
        OUTPUT:
                RETVAL


OME::Matlab::Array
newLogicalArray(package,...)
        const char *package = NO_INIT;
        INIT:
                int * dims;
                int numdims, i;
        CODE:
                if (items <= 1)
                    croak("newLogicalArray expects a list of dimensions");
                numdims = items-1;
                dims = mxCalloc(numdims,sizeof(int));
                for (i = 0; i < numdims; i++)
                    dims[i] = (int) SvIV(ST(i+1));
                RETVAL = mxCreateLogicalArray(numdims,dims);
                mxFree(dims);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newNumericArray(package,classID,complexity,...)
        const char *package = NO_INIT;
        mxClassID classID
        mxComplexity complexity
        INIT:
                int * dims;
                int numdims, i;
        CODE:
                if (items <= 3)
                    croak("newNumericArray expects a list of dimensions");
                numdims = items-3;
                dims = mxCalloc(numdims,sizeof(int));
                for (i = 0; i < numdims; i++)
                    dims[i] = (int) SvIV(ST(i+3));
                RETVAL = mxCreateNumericArray(numdims,dims,classID,complexity);
                mxFree(dims);
        OUTPUT:
                RETVAL

void
DESTROY(pArray)
        OME::Matlab::Array pArray
        CODE:
                printf("OME::Matlab::Array::DESTROY\n");
                mxDestroyArray(pArray);
        OUTPUT:

mxClassID
class(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxGetClassID(pArray);
        OUTPUT:
                RETVAL

const char *
class_name(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxGetClassName(pArray);
        OUTPUT:
                RETVAL

int
order(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxGetNumberOfDimensions(pArray);
        OUTPUT:
                RETVAL

SV *
dimensions(pArray)
        OME::Matlab::Array pArray
        INIT:
                AV * dims;
                int numdims;
                const int * idims;
                int i;
        CODE:
                dims = (AV *) sv_2mortal((SV *) newAV());
                numdims = mxGetNumberOfDimensions(pArray);
                idims = mxGetDimensions(pArray);
                for (i = 0; i < numdims; i++)
                {
                    av_push(dims,newSViv(*idims++));
                }
                RETVAL = newRV((SV *) dims);
        OUTPUT:
                RETVAL

int
m(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxGetM(pArray);
        OUTPUT:
                RETVAL

int
n(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxGetN(pArray);
        OUTPUT:
                RETVAL

bool
is_cell(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsCell(pArray);
        OUTPUT:
                RETVAL

bool
is_char(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsChar(pArray);
        OUTPUT:
                RETVAL

bool
is_complex(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsComplex(pArray);
        OUTPUT:
                RETVAL

bool
is_double(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsDouble(pArray);
        OUTPUT:
                RETVAL

bool
is_empty(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsEmpty(pArray);
        OUTPUT:
                RETVAL

bool
is_int8(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsInt8(pArray);
        OUTPUT:
                RETVAL

bool
is_int16(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsInt16(pArray);
        OUTPUT:
                RETVAL

bool
is_int32(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsInt32(pArray);
        OUTPUT:
                RETVAL

bool
is_logical(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsLogical(pArray);
        OUTPUT:
                RETVAL

bool
is_numeric(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsNumeric(pArray);
        OUTPUT:
                RETVAL

bool
is_single(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsSingle(pArray);
        OUTPUT:
                RETVAL

bool
is_sparse(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsSparse(pArray);
        OUTPUT:
                RETVAL

bool
is_struct(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsStruct(pArray);
        OUTPUT:
                RETVAL

bool
is_uint8(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsUint8(pArray);
        OUTPUT:
                RETVAL

bool
is_uint16(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsUint16(pArray);
        OUTPUT:
                RETVAL

bool
is_uint32(pArray)
        OME::Matlab::Array pArray
        CODE:
                RETVAL = mxIsUint32(pArray);
        OUTPUT:
                RETVAL

double
get(pArray,...)
        OME::Matlab::Array pArray
        INIT:
                int * subs;
                int numsubs, numdims, i, cid, index;
                void * pr;
        CODE:
                if (items < 2)
                {
                    croak("get expects a list of subscripts");
                }

                /* Make sure that there are as many subscripts as
                 * there are dimensions. */
                numsubs = items-1;
                numdims = mxGetNumberOfDimensions(pArray);
                if (numsubs != numdims)
                {
                    croak("get: number of subscripts doesn't match number of dimensions");
                }

                subs = mxCalloc(numsubs,sizeof(int));
                for (i = 0; i < numsubs; i++)
                    subs[i] = (int) SvIV(ST(i+1));

                cid = mxGetClassID(pArray);
                index = mxCalcSingleSubscript(pArray,numsubs,subs);
                pr = mxGetData(pArray);
                mxFree(subs);

                switch (cid)
                {
                    case mxLOGICAL_CLASS:
                        RETVAL = ((mxLogical *) pr)[index];
                        break;
                    case mxINT8_CLASS:
                        RETVAL = ((signed char *) pr)[index];
                        break;
                    case mxUINT8_CLASS:
                        RETVAL = ((unsigned char *) pr)[index];
                        break;
                    case mxINT16_CLASS:
                        RETVAL = ((signed short int *) pr)[index];
                        break;
                    case mxUINT16_CLASS:
                        RETVAL = ((unsigned short int *) pr)[index];
                        break;
                    case mxINT32_CLASS:
                        RETVAL = ((signed int *) pr)[index];
                        break;
                    case mxUINT32_CLASS:
                        RETVAL = ((unsigned int *) pr)[index];
                        break;
                    case mxSINGLE_CLASS:
                        RETVAL = ((float *) pr)[index];
                        break;
                    case mxDOUBLE_CLASS:
                        RETVAL = ((double *) pr)[index];
                        break;
                    default:
                        croak("cannot call set on a non-numeric/non-logical array");
                        break;
                }
        OUTPUT:
                RETVAL

void
set(pArray,...)
        OME::Matlab::Array pArray
        INIT:
                int * subs;
                int numsubs, numdims, i, cid, index;
                double value;
                void * pr;

                if (items < 3)
                {
                    croak("set expects a list of subscripts");
                }

                /* Make sure that there are as many subscripts as
                 * there are dimensions. */
                numsubs = items-2;
                numdims = mxGetNumberOfDimensions(pArray);
                if (numsubs != numdims)
                {
                    croak("set: number of subscripts doesn't match number of dimensions");
                }
        CODE:
                subs = mxCalloc(numsubs,sizeof(int));
                for (i = 0; i < numsubs; i++)
                    subs[i] = (int) SvIV(ST(i+1));

                value = (double) SvNV(ST(items-1));

                cid = mxGetClassID(pArray);
                index = mxCalcSingleSubscript(pArray,numsubs,subs);
                pr = mxGetData(pArray);
                mxFree(subs);

                switch (cid)
                {
                    case mxLOGICAL_CLASS:
                        ((mxLogical *) pr)[index] = (mxLogical) value;
                    case mxINT8_CLASS:
                        ((signed char *) pr)[index] = (signed char) value;
                        break;
                    case mxUINT8_CLASS:
                        ((unsigned char *) pr)[index] = (unsigned char) value;
                        break;
                    case mxINT16_CLASS:
                        ((signed short int *) pr)[index] = (signed short int) value;
                        break;
                    case mxUINT16_CLASS:
                        ((unsigned short int *) pr)[index] = (unsigned short int) value;
                        break;
                    case mxINT32_CLASS:
                        ((signed int *) pr)[index] = (signed int) value;
                        break;
                    case mxUINT32_CLASS:
                        ((unsigned int *) pr)[index] = (unsigned int) value;
                        break;
                    case mxSINGLE_CLASS:
                        ((float *) pr)[index] = (float) value;
                        break;
                    case mxDOUBLE_CLASS:
                        ((double *) pr)[index] = (double) value;
                        break;
                    default:
                        croak("cannot call set on a non-numeric/non-logical array");
                        break;
                }
        OUTPUT:

SV *
getAll(pArray)
        OME::Matlab::Array pArray
        INIT:
                AV * values;
                int n, i, esize, cid;
                void * pr;
        CODE:
                cid = mxGetClassID(pArray);
                values = (AV *) sv_2mortal((SV *) newAV());
                n = mxGetNumberOfElements(pArray);
                av_extend(values,n);
                pr = mxGetData(pArray);
                esize = mxGetElementSize(pArray);

                for (i = 0; i < n; i++)
                {
                    switch (cid)
                    {
                        case mxLOGICAL_CLASS:
                            av_push(values,newSViv(*((mxLogical *) pr)++));
                            break;
                        case mxINT8_CLASS:
                            av_push(values,newSViv(*((signed char *) pr)++));
                            break;
                        case mxUINT8_CLASS:
                            av_push(values,newSViv(*((unsigned char *) pr)++));
                            break;
                        case mxINT16_CLASS:
                            av_push(values,newSViv(*((signed short int *) pr)++));
                            break;
                        case mxUINT16_CLASS:
                            av_push(values,newSViv(*((unsigned short int *) pr)++));
                            break;
                        case mxINT32_CLASS:
                            av_push(values,newSViv(*((signed int *) pr)++));
                            break;
                        case mxUINT32_CLASS:
                            av_push(values,newSViv(*((unsigned int *) pr)++));
                            break;
                        case mxSINGLE_CLASS:
                            av_push(values,newSVnv(*((float *) pr)++));
                            break;
                        case mxDOUBLE_CLASS:
                            av_push(values,newSVnv(*((double *) pr)++));
                            break;
                        default:
                            croak("cannot call getAll on a non-numeric/non-logical array");
                            break;
                    }
                }
                RETVAL = newRV((SV *) values);
        OUTPUT:
                RETVAL

void
setAll(pArray,valueref)
        OME::Matlab::Array pArray
        SV * valueref
        INIT:
                AV * values;
                I32  numvals;
                int  i, n, cid;

                n = mxGetNumberOfElements(pArray);

                if (!SvROK(valueref))
                {
                    printf("Not a reference\n");
                    XSRETURN_UNDEF;
                }

                if (SvTYPE(SvRV(valueref)) != SVt_PVAV)
                {
                    printf("Not an array reference\n");
                    XSRETURN_UNDEF;
                }

                values = (AV *) SvRV(valueref);

                if ((numvals = av_len(values)+1) != n)
                {
                    printf("Incorrect length %d %d\n",numvals,n);
                    XSRETURN_UNDEF;
                }
        CODE:
                cid = mxGetClassID(pArray);
                switch (cid)
                {
                    case mxLOGICAL_CLASS:
                    {
                        mxLogical * pr;
                        SV** aval;

                        pr = (mxLogical *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (mxLogical) SvTRUE(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    case mxINT8_CLASS:
                    {
                        signed char * pr;
                        SV** aval;

                        pr = (signed char *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (signed char) SvIV(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    case mxUINT8_CLASS:
                    {
                        unsigned char * pr;
                        SV** aval;

                        pr = (unsigned char *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (unsigned char) SvIV(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    case mxINT16_CLASS:
                    {
                        signed short int * pr;
                        SV** aval;

                        pr = (signed short int *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (signed short int) SvIV(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    case mxUINT16_CLASS:
                    {
                        unsigned short int * pr;
                        SV** aval;

                        pr = (unsigned short int *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (unsigned short int) SvIV(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    case mxINT32_CLASS:
                    {
                        signed int * pr;
                        SV** aval;

                        pr = (signed int *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (signed int) SvIV(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    case mxUINT32_CLASS:
                    {
                        unsigned int * pr;
                        SV** aval;

                        pr = (unsigned int *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (unsigned int) SvIV(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    case mxSINGLE_CLASS:
                    {
                        float * pr;
                        SV** aval;

                        pr = (float *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (float) SvNV(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    case mxDOUBLE_CLASS:
                    {
                        double * pr;
                        SV** aval;

                        pr = (double *) mxGetData(pArray);
                        for (i = 0; i < n; i++)
                        {
                            aval = av_fetch(values,i,0);
                            if (aval != NULL)
                            {
                                *pr = (double) SvIV(*aval);
                            }
                            pr++;
                        }

                        break;
                    }
                    default:
                        croak("cannot call setAll on a non-numeric/non-logical array");
                        break;
                }
        OUTPUT:

MODULE = OME::Matlab	PACKAGE = OME::Matlab::Engine

OME::Matlab::Engine
open(package,startcmd=NULL)
        const char *package = NO_INIT;
        const char *startcmd
        CODE:
            RETVAL = engOpen(startcmd);
            engOutputBuffer(RETVAL,NULL,0);
        OUTPUT:
            RETVAL

int
close(pEngine)
        OME::Matlab::Engine pEngine;
        CODE:
            RETVAL = engClose(pEngine);
        OUTPUT:
            RETVAL

OME::Matlab::Array
getVariable(pEngine,varname)
        OME::Matlab::Engine pEngine;
        const char *varname;
        CODE:
            RETVAL = engGetVariable(pEngine,varname);
        OUTPUT:
            RETVAL

int
putVariable(pEngine,varname,pArray)
        OME::Matlab::Engine pEngine;
        const char *varname;
        OME::Matlab::Array pArray;
        CODE:
            RETVAL = engPutVariable(pEngine,varname,pArray);
        OUTPUT:
            RETVAL

int
eval(pEngine,matlab_code)
        OME::Matlab::Engine pEngine;
        const char *matlab_code;
        CODE:
            RETVAL = engEvalString(pEngine,matlab_code);
        OUTPUT:
            RETVAL
