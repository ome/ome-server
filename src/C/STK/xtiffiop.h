/*
 * Private Extended TIFF library interface.
 *
 *  uses private LIBTIFF interface.
 *
 *  The portions of this module marked "XXX" should be
 *  modified to support your tags instead.
 *
 *  written by: Niles D. Ritter
 *  Modified by Ilya G. Goldberg to read UIC's .stk format.
 *
 */

#ifndef __xtiffiop_h
#define __xtiffiop_h

#include "tiffiop.h"
#include "xtiffio.h"

/**********************************************************************
 *               User Configuration
 **********************************************************************/

/* XXX - Define number of your extended tags here */
#define NUM_XFIELD 4
#define XFIELD_BASE (FIELD_LAST-NUM_XFIELD)

/*  XXX - Define your Tag Fields here  */
#define	FIELD_UIC1Tag     (XFIELD_BASE+0)
#define	FIELD_UIC2Tag     (XFIELD_BASE+1)
#define	FIELD_UIC3Tag     (XFIELD_BASE+2)
#define	FIELD_UIC4Tag     (XFIELD_BASE+3)


/* XXX - Define Private directory tag structure here */
struct XTIFFDirectory {
	char	 isSTK;           /* UIC2 tag found */
	uint16	 nPlanes;         /* UIC2 tag count */
	uint32   minScale;        /* UIC1 ID1 */
	uint32   maxScale;        /* UIC1 ID2 */
	float    pixSizeX;        /* UIC1 ID4->LONG0 / LONG1 */
	float    pixSizeY;        /* UIC1 ID5->LONG0 / LONG1 */
	/* these are arrays nPlanes long. */
	uint32   *dateCreated;     /* UIC2 LONG2 */
	uint32   *dateModified;    /* UIC2 LONG4 */
	uint32   *timeCreated;     /* UIC2 LONG3 */
	uint32   *timeModified;    /* UIC2 LONG5 */
	float    *wavelengths;     /* UIC3 LONG0 / LONG1 */
	float    *stageX;          /* UIC4 ID28->LONG0 / LONG1 */
	float    *stageY;          /* UIC4 ID28->LONG2 / LONG3 */
	float    *absZ;            /* UIC4 ID40->LONG0 / LONG1 */
	float    *absZvalid;       /* UIC4 ID41->LONG0 / LONG1 */
	char    **stageLabels;	   /* UIC4 ID37->LONG = N, N bytes - one string per plane*/
	float    *zDist;           /* UIC2 LONG0 / LONG1*/
};
typedef struct XTIFFDirectory XTIFFDirectory;

/**********************************************************************
 *    Nothing below this line should need to be changed by the user.
 **********************************************************************/

struct xtiff {
	TIFF 		*xtif_tif;	/* parent TIFF pointer */
	uint32		xtif_flags;
#define       XTIFFP_PRINT   0x00000001
	XTIFFDirectory	xtif_dir;	/* internal rep of current directory */
	TIFFVSetMethod	xtif_vsetfield;	/* inherited tag set routine */
	TIFFVGetMethod	xtif_vgetfield;	/* inherited tag get routine */
	TIFFPrintMethod	xtif_printdir;  /* inherited dir print method */
};
typedef struct xtiff xtiff;


#define PARENT(xt,pmember) ((xt)->xtif_ ## pmember) 
#define TIFFMEMBER(tf,pmember) ((tf)->tif_ ## pmember) 
#define XTIFFDIR(tif) ((xtiff *)TIFFMEMBER(tif,clientdir))
	
/* Extended TIFF flags */
#define XTIFF_INITIALIZED 0x80000000
	
#endif /* __xtiffiop_h */
