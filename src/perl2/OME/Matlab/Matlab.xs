#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "matrix.h"
typedef mxArray* OME__Matlab__Array;

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

MODULE = OME::Matlab	PACKAGE = OME::Matlab::Array

OME::Matlab::Array
newDoubleScalar(package,value)
        char *package = NO_INIT;
        double value
        CODE:
                RETVAL = mxCreateDoubleScalar(value);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newLogicalScalar(package,value)
        char *package = NO_INIT;
        mxLogical value
        CODE:
                RETVAL = mxCreateLogicalScalar(value);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newDoubleMatrix(package,m,n,complexity=mxREAL)
        char *package = NO_INIT;
        int m
        int n
        mxComplexity complexity
        CODE:
                RETVAL = mxCreateDoubleMatrix(m,n,complexity);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newLogicalMatrix(package,m,n)
        char *package = NO_INIT;
        int m
        int n
        CODE:
                RETVAL = mxCreateLogicalMatrix(m,n);
        OUTPUT:
                RETVAL

OME::Matlab::Array
newLogicalArray(package,...)
        char *package = NO_INIT;
        INIT:
                int * dims;
                int numdims, i;
        CODE:
                if (items <= 1)
                    XSRETURN_UNDEF;
                numdims = items-1;
                dims = mxCalloc(numdims,sizeof(int));
                for (i = 0; i < numdims; i++)
                    dims[i] = (int) SvIV(ST(i+1));
                RETVAL = mxCreateLogicalArray(numdims,dims);
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
                    printf("not enough params\n");
                    XSRETURN_UNDEF;
                }

                /* Make sure that there are as many subscripts as
                 * there are dimensions. */
                numsubs = items-1;
                numdims = mxGetNumberOfDimensions(pArray);
                if (numsubs != numdims)
                {
                    printf("numsubs != numdims\n");
                    XSRETURN_UNDEF;
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
                        printf("unknown class\n");
                        XSRETURN_UNDEF;
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
                    printf("not enough params\n");
                    XSRETURN_UNDEF;
                }

                /* Make sure that there are as many subscripts as
                 * there are dimensions. */
                numsubs = items-2;
                numdims = mxGetNumberOfDimensions(pArray);
                if (numsubs != numdims)
                {
                    printf("numsubs != numdims\n");
                    XSRETURN_UNDEF;
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
                        printf("unknown class\n");
                        XSRETURN_UNDEF;
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
                            printf("unknown class\n");
                            XSRETURN_UNDEF;
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
                        printf("unknown class\n");
                        XSRETURN_UNDEF;
                        break;
                }
        OUTPUT: