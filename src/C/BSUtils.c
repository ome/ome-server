/* ================================================================== */
/* BSUtils.c: Byte Swap utilities                                     */
/* JTN: 9/22/00                                                       */
/* ================================================================== */
/*
#include <BSUtils.h>
*/

void BSUtilsSwap2Byte(char *cBufPtr, int iNtimes);
void BSUtilsSwapHeader(char *cTheHeader);
void BSUtilsSwap4Byte(char *cBufPtr, int iNtimes);



#if defined(__linux__)
#include <byteswap.h>
#endif


/* ------------------------------------------------------------------ */
/* BSUtilsByteSwapHeader  - Byte-swap a standard image header         */
/* Swap the header bytes from non-native to native                    */
/* This function requires an intimate knowledge of the byte layout    */
/* of the header                                                      */
/* JTN: 9/22/00                                                       */
/* ------------------------------------------------------------------ */
void BSUtilsSwapHeader(char *cTheHeader)
{
    char *ptr;
    
	/*
	 * Swap appropriate simple parts of the header in 
     * blocks of like data for speed
	 */
	ptr = &cTheHeader[0];
	BSUtilsSwap4Byte(ptr, 24);
	
	ptr = &cTheHeader[96];
	BSUtilsSwap2Byte(ptr, 2);
	
	ptr = &cTheHeader[128];
	BSUtilsSwap2Byte(ptr, 4);
	
	ptr = &cTheHeader[136];
	BSUtilsSwap4Byte(ptr, 6);
    
    ptr = &cTheHeader[160];
    BSUtilsSwap2Byte(ptr, 6);
    
    ptr = &cTheHeader[172];
    BSUtilsSwap4Byte(ptr, 2);
    
    ptr = &cTheHeader[180];
    BSUtilsSwap2Byte(ptr, 2);
    
    ptr = &cTheHeader[184];
    BSUtilsSwap4Byte(ptr, 3);
            
	/*
	 * Handle the wavelength info
	 */
	
	ptr = &cTheHeader[196];
	BSUtilsSwap2Byte(ptr, 6);
	
	
	ptr = &cTheHeader[208];
	BSUtilsSwap4Byte(ptr, 4);
}


/* ------------------------------------------------------------------ */
/* BSUtilsSwap2Byte                                                   */
/* Swap a buffer of 2 byte values.                                    */
/* JTN: 9/22/00                                                       */
/* ------------------------------------------------------------------ */
void BSUtilsSwap2Byte(char *cBufPtr, int iNtimes)
{
#ifdef __linux__
    /* Use glibc hardware-accelerated swap */
    unsigned short *uptr = (unsigned short *)cBufPtr;
    int i;
    
    for(i=0; i<iNtimes; i++, uptr++)
    {
        *uptr = bswap_16(*uptr);
    }
#else
	char holder;
	int  i;
	
	for(i=0; i<iNtimes*2; i+=2)
	{
		holder       = cBufPtr[i];
		cBufPtr[i]   = cBufPtr[i+1];
		cBufPtr[i+1] = holder;
	}
#endif
}

/* ------------------------------------------------------------------ */
/* BSUtilsSwap4Byte                                                   */
/* Swap a buffer of 4 byte values. Works for both 32-bit int          */
/* and 32-bit float on Intel Linux <-> SGI conversion                 */
/* JTN: 9/22/00                                                       */
/* ------------------------------------------------------------------ */
void BSUtilsSwap4Byte(char *cBufPtr, int iNtimes)
{
#ifdef __linux__
    /* Use glibc hardware-accelerated swap */
    unsigned long *lptr = (unsigned long *)cBufPtr;
    int i;
    
    for(i=0; i<iNtimes; i++, lptr++)
    {
        *lptr = bswap_32(*lptr);
    }
#else
	char holder;
	int  i;
	
	for(i=0; i<iNtimes*4; i+=4)
	{
		holder       = cBufPtr[i];
		cBufPtr[i]   = cBufPtr[i+3];
		cBufPtr[i+3] = holder;
		
		holder       = cBufPtr[i+1];
		cBufPtr[i+1] = cBufPtr[i+2];
		cBufPtr[i+2] = holder;
	}
#endif
}

