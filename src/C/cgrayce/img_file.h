/************************************************************************

  Load/dump image files, so far only in TIFF format.

  ==> Requires libtiff, see <http://www.libtiff.org/>

*/
#ifndef _IMG_FILE_
#define _IMG_FILE_

#include "util.h"
#include "gras.h"

/* the user-modifiable output parameters */
typedef enum { 
  IMG_FILE_OUT_BITS ,          /* bits per pixel */
  IMG_FILE_OUT_COMP            /* compression scheme */
} img_file_out_parm ;

/************************************************************************

  Request to modify output parameters.

  */
extern void img_set_outparm(img_file_out_parm parm, int val) ;

/************************************************************************

 Open a TIFF file and load a grayscale raster.  
 
 */
extern rc_t tiff_load_gras(const char *fn, gras_t *gras) ;

/************************************************************************

 Open a TIFF file and dump a grayscale raster.

 */
extern rc_t tiff_dump_gras(const char *fn, gras_t *gras) ;
 
/************************************************************************

  Open a TIFF file and print first directory contents.

 */
extern rc_t tiff_info(const char *fn) ;

#endif
