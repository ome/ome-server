/************************************************************************

  Deal with TIFF images.

  ==> Requires libtiff, see <http://www.libtiff.org/>

 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/fcntl.h>
#include <time.h>
#include <tiff.h>     /* header file from libtiff */
#include <tiffio.h>   /* header file from libtiff */
#include "util.h"
#include "gras.h"
#include "img_file.h"

/* modifiable output parameters -- requested values */
static int out_bits_ask = 0 ;
static int out_comp_ask = 0 ;
/* modifiable output parameters -- actual values */
static int out_bits = 0 ;
static int out_comp = 0 ;

static const char *here = __FILE__ ;

/************************************************************************

  Clean up, returning integer.

  */
static rc_t tifclean(rc_t rc, int line, 
		     const char *id, const char *msg,
		     TIFF **tifs, int ntif, 
		     char **tmps, int ntmp,
		     char **bufs, int nbuf) {
  int i ;

  if (bufs) for(i=0;i<nbuf;i++) _TIFFfree(bufs[i]) ;
  if (tifs) for(i=0;i<ntif;i++) TIFFClose(tifs[i]) ;
  if (tmps) for(i=0;i<ntmp;i++) (void)remove(tmps[i]) ;
  if (msg && (verbosity < MSG_NONE))
    printf("  %s [%s:%d]: %s\n",id,__FILE__,line,msg) ;
  return(rc) ;
}

/************************************************************************

  Request to modify output parameters.

  */
void img_set_outparm(img_file_out_parm parm, int val) {

  const char *me = "img_set_outparm" ;

  switch (parm) {
  case IMG_FILE_OUT_BITS :
    out_bits_ask = val ; break ;
  case IMG_FILE_OUT_COMP :
    out_comp_ask = val ; break ;
  default :
    if (verbosity < MSG_FATAL)
      printf("%s [%s:%d]: ignoring unknown output parameter %d\n",
	     me,__FILE__,__LINE__,parm) ;
  } ;
}

/************************************************************************

  Deal with requests to modify output parameters.

  */
static void resolve_outparm(gras_t *gr) {

  int foo ;
  const char *me = "resolve_outparm" ;
  
  out_bits = gras_depth(gr) ;
  if (out_bits_ask) {
    if (out_bits_ask % 8) {
      for(foo=out_bits_ask;foo % 8;foo++) ;
      if (verbosity < MSG_FATAL)
	printf("%s [%s:%d]: impossible %d-bit output request changed to\n"
	       "   nearest multiple of 8 bits = %d.\n",
	       me,__FILE__,__LINE__,out_bits_ask,foo) ;
      out_bits_ask = foo ;
    } ;
    if ((out_bits_ask < out_bits) && (verbosity < MSG_FATAL))
      printf("%s [%s:%d]: warning: %d-bit output requested for %d-bit\n"
	     "   image data -- image may be corrupted.\n",
	     me,__FILE__,__LINE__,out_bits_ask,out_bits) ;
    out_bits = out_bits_ask ;
  } ;
  out_comp = 1 ;
  if (out_comp_ask) out_comp = out_comp_ask ;
}

/************************************************************************

  Reset modifiable output parameters.

  */
static void reset_outparm() {

  out_bits_ask = 0 ;
  out_comp_ask = 0 ;
}

/************************************************************************

  Initialize basic TIFF tags for a grayscale image.

 */
static rc_t gtags_init(TIFF *tif, const gras_t *gras) {

  time_t now ;
  struct tm *tm = 0 ;
  char *usr ;
  int nr ;
  const char *me = "gtags_init" ;

  if (!tif) return(punt(here,__LINE__,me,"null TIFF pointer")) ;
  TIFFSetField(tif,TIFFTAG_IMAGEWIDTH ,(uint16)gras->nx) ;
  TIFFSetField(tif,TIFFTAG_IMAGELENGTH,(uint16)gras->ny) ;
  TIFFSetField(tif,TIFFTAG_BITSPERSAMPLE,(uint16)out_bits) ;
  TIFFSetField(tif,TIFFTAG_COMPRESSION,(uint16)out_comp) ;
  TIFFSetField(tif,TIFFTAG_PHOTOMETRIC,PHOTOMETRIC_MINISBLACK) ;
  TIFFSetField(tif,TIFFTAG_ORIENTATION,ORIENTATION_TOPLEFT) ;
  TIFFSetField(tif,TIFFTAG_SAMPLESPERPIXEL,1) ;
  TIFFSetField(tif,TIFFTAG_PLANARCONFIG,PLANARCONFIG_CONTIG) ;
  if ((nr = TIFFDefaultStripSize(tif,0)) > gras->ny) nr = gras->ny ;
  TIFFSetField(tif,TIFFTAG_ROWSPERSTRIP,nr) ;
  snprintf(msgbuf,sizeof(msgbuf),
	   "%s [%s:%d] of %s %s",me,__FILE__,__LINE__,__DATE__,__TIME__) ;
  TIFFSetField(tif,TIFFTAG_SOFTWARE,msgbuf) ;
  if (time(&now) && (tm = localtime(&now)) &&
      strftime(msgbuf,sizeof(msgbuf),"%Y:%m:%d %T",tm))
    TIFFSetField(tif,TIFFTAG_DATETIME,msgbuf) ;
  if ((usr = getlogin()) && snprintf(msgbuf,sizeof(msgbuf),usr) && 
      strcat(msgbuf,"@") && 
      !gethostname(msgbuf + strlen(msgbuf),sizeof(msgbuf)-strlen(msgbuf)))
    TIFFSetField(tif,TIFFTAG_HOSTCOMPUTER,msgbuf) ;    
  return(OK) ;
}

/************************************************************************

  Read a grayscale raster from a TIFF file.

 */
static rc_t tiff2gras(TIFF *tif, gras_t *gras) {
 
  char *bufs[1] ;
  int bufsz = 0 ;
  int nbuf = 0 ;
  int rps,bits,strip,iy,ix,ir,stripsz,iz ;
  int nx,ny ;
  uint16 u16 ;
  uint32 u32 ;
  const char *me = "tiff2gras" ;

  if (!tif) return(punt(here,__LINE__,me,"null TIFF handle")) ;
  if (!gras) return(punt(here,__LINE__,me,"null raster pointer")) ;
  if (!TIFFGetField(tif,TIFFTAG_PHOTOMETRIC  ,&u16) || (u16 > 1))
    return(punt(here,__LINE__,me,"not grayscale data")) ;
  if (!TIFFGetField(tif,TIFFTAG_IMAGEWIDTH   ,&u32) || !(nx   = u32) ||
      !TIFFGetField(tif,TIFFTAG_IMAGELENGTH  ,&u32) || !(ny   = u32) ||
      !TIFFGetField(tif,TIFFTAG_ROWSPERSTRIP ,&u32) || !(rps  = u32) ||
      !TIFFGetField(tif,TIFFTAG_BITSPERSAMPLE,&u16) || !(bits = u16) ||
      !(bufsz = TIFFStripSize(tif)) )
    return(punt(here,__LINE__,me,"can\'t get TIFF image size parameters")) ;
  if (!(bufs[nbuf++] = (unsigned char *)_TIFFmalloc(bufsz)))
    return(punt(here,__LINE__,me,"can\'t allocate buffer")) ;

  if (gras_chksz(gras,ny,nx) != OK)
    return(tifclean(FATAL,__LINE__,me,"can\'t initialize grayscale raster",
		   0,0,0,0,bufs,nbuf)) ;

  for(strip=iy=0;iy<ny;strip+=1,iy+=rps) {
    if ((stripsz = TIFFReadEncodedStrip(tif,strip,bufs[0],bufsz)) < 0) {
      snprintf(msgbuf,sizeof(msgbuf),
	       "TIFF I/O error while reading strip %d",strip) ;
      return(tifclean(FATAL,__LINE__,me,msgbuf,0,0,0,0,bufs,nbuf)) ;
    } ;
    for(iz=0,ir=0;ir<rps;ir++) {
      if (iy+ir >= ny) break ;
      for(ix=0;ix<nx;ix++) {
	if (iz >= stripsz) {
	  snprintf(msgbuf,sizeof(msgbuf),
		   "out of TIFF data at strip %d",strip) ;
	  return(tifclean(FATAL,__LINE__,me,msgbuf,0,0,0,0,bufs,nbuf)) ;
	} ;
	switch (bits) {
	case 8 :
	  gras->ras[iy+ir][ix] = *(uint8  *)(bufs[0] + iz) ;
	  iz += 1 ; break ;
	case 16 :
	  gras->ras[iy+ir][ix] = *(uint16 *)(bufs[0] + iz) ;
	  iz += 2 ; break ;
	default :
	  snprintf(msgbuf,sizeof(msgbuf),"can\'t handle %d bits/pixel",bits) ;	
	  return(tifclean(FATAL,__LINE__,me,msgbuf,0,0,0,0,bufs,nbuf)) ;
	} ;
      } ;
    } ;
  } ;
  return(tifclean(OK,__LINE__,0,0,0,0,0,0,bufs,nbuf)) ;
}

/************************************************************************

  Write a grayscale raster to a TIFF file.

 */
static rc_t gras2tiff(TIFF *tif, gras_t *gras) {
 
  char *bufs[1] ;
  int bufsz = 0 ;
  int nbuf = 0 ;
  int rps,bits,strip,iy,ix,ir,stripsz,iz ;
  int nx,ny ;
  uint16 u16 ;
  uint32 u32 ;
  const char *me = "gras2tiff" ;

  if (!tif) return(punt(here,__LINE__,me,"null TIFF pointer")) ;
  if (!gras) return(punt(here,__LINE__,me,"null raster pointer")) ;
  if (gtags_init(tif,gras) != OK) return(FATAL) ;
  if (!TIFFGetField(tif,TIFFTAG_IMAGELENGTH  ,&u32) || !(ny   = u32) ||
      !TIFFGetField(tif,TIFFTAG_IMAGEWIDTH   ,&u32) || !(nx   = u32) ||
      !TIFFGetField(tif,TIFFTAG_ROWSPERSTRIP ,&u32) || !(rps  = u32) ||
      !TIFFGetField(tif,TIFFTAG_BITSPERSAMPLE,&u16) || !(bits = u16) ||
      !(bufsz = TIFFStripSize(tif)) )
    return(punt(here,__LINE__,me,"can\'t get TIFF image size parameters")) ;
  if  (!(bufs[nbuf++] = (unsigned char *)_TIFFmalloc(bufsz)) )
    return(punt(here,__LINE__,me,"can\'t allocate buffer")) ;

  for(strip=iy=0;iy<ny;strip+=1,iy+=rps) {
    for(iz=0,ir=0;ir<rps;ir++) {
      if (iy+ir >= ny) break ;
      for(ix=0;ix<nx;ix++) {
	if (iz >= bufsz) {
	  snprintf(msgbuf,sizeof(msgbuf),
		   "out of TIFF data at strip %d",strip) ;
	  return(tifclean(FATAL,__LINE__,me,msgbuf,0,0,0,0,bufs,nbuf)) ;
	} ;
	switch (bits) {
	case 8 :
	  *(uint8  *)(bufs[0] + iz) = (uint8 )gras->ras[iy+ir][ix] ; 
	  iz += 1 ; break ;
	case 16 :
	  *(uint16 *)(bufs[0] + iz) = (uint16)gras->ras[iy+ir][ix] ;	
	  iz += 2 ; break ;
	default :
	  snprintf(msgbuf,sizeof(msgbuf),"can\'t handle %d bits/pixel",bits) ;	
	  return(tifclean(FATAL,__LINE__,me,msgbuf,0,0,0,0,bufs,nbuf)) ;
	} ;
      } ;
    } ;
    if ((stripsz = TIFFWriteEncodedStrip(tif,strip,bufs[0],iz)) < iz) {
      snprintf(msgbuf,sizeof(msgbuf),
	       "TIFF I/O error while writing strip %d",strip) ;
      return(tifclean(FATAL,__LINE__,me,msgbuf,0,0,0,0,bufs,nbuf)) ;
    } ;
  } ;
  return(tifclean(OK,__LINE__,0,0,0,0,0,0,bufs,nbuf)) ;
}

/************************************************************************

  Set verbosity of error and warning messages.

  */
static void tiff_set_verbosity() {

  static TIFFErrorHandler tif_wng_handler = 0 ;
  static TIFFErrorHandler tif_err_handler = 0 ;
  TIFFErrorHandler oh ;

  switch(verbosity) {

  case MSG_DEBUG :
  default :
  case MSG_WARN :
    if (tif_wng_handler) (void)TIFFSetWarningHandler(tif_wng_handler) ;
    if (tif_err_handler) (void)TIFFSetErrorHandler(tif_err_handler) ;
    break ;
  case MSG_FATAL :
    oh = TIFFSetWarningHandler(0) ;
    if (!tif_wng_handler) tif_wng_handler = oh ;
    if (tif_err_handler) (void)TIFFSetErrorHandler(tif_err_handler) ;
    break ;
  case MSG_NONE :
    oh = TIFFSetWarningHandler(0) ;
    if (!tif_wng_handler) tif_wng_handler = oh ;
    oh = TIFFSetErrorHandler(0) ;
    if (!tif_err_handler) tif_err_handler = oh ;
    break ;
  } ;
}

/************************************************************************

 Open a TIFF file and load a grayscale raster.

 */
rc_t tiff_load_gras(const char *fn, gras_t *gras) {

  TIFF *tif ;
  const char *me = "tiff_load_gras" ;

  tiff_set_verbosity() ;

  if (!(tif = TIFFOpen(fn,"r"))) {
    snprintf(msgbuf,sizeof(msgbuf),"can\'t read \"%s\"",fn) ;
    return(punt(here,__LINE__,me,msgbuf)) ;
  } ;
  if (verbosity == MSG_DEBUG) {
    printf("> %s [%s:%d]: read TIFF file \"%s\":\n",me,__FILE__,__LINE__,fn) ;
    TIFFPrintDirectory(tif,stdout,TIFFPRINT_NONE) ;
  } ;
  if (tiff2gras(tif,gras) != OK) {
    snprintf(msgbuf,sizeof(msgbuf),"can\'t load grayscale from \"%s\"",fn) ;
    return(punt(here,__LINE__,me,msgbuf)) ;
  } ;
  gras_maxmin(gras) ;
  TIFFClose(tif) ;
  return(OK) ;
}

/************************************************************************

 Open a TIFF file and dump a grayscale raster.

 */
rc_t tiff_dump_gras(const char *fn, gras_t *gras) {

  TIFF *tif ;
  const char *me = "tiff_dump_gras" ;

  gras_maxmin(gras) ;
  tiff_set_verbosity() ;
  resolve_outparm(gras) ;

  if (!(tif = TIFFOpen(fn,"w"))) {
    reset_outparm() ;
    snprintf(msgbuf,sizeof(msgbuf),"can\'t write \"%s\"",fn) ;
    return(punt(here,__LINE__,me,msgbuf)) ;
  } ;
  if (gras2tiff(tif,gras) != OK) {
    reset_outparm() ;
    snprintf(msgbuf,sizeof(msgbuf),"can\'t dump grayscale to \"%s\"",fn) ;
    return(punt(here,__LINE__,me,msgbuf)) ;
  } ;
  if (verbosity == MSG_DEBUG) {
    printf("> %s [%s:%d]: wrote TIFF file \"%s\":\n",me,__FILE__,__LINE__,fn) ;
    TIFFPrintDirectory(tif,stdout,TIFFPRINT_NONE) ;
  } ;
  reset_outparm() ;
  TIFFClose(tif) ;
  return(OK) ;
}
 
/************************************************************************

  Open a TIFF file and print first directory contents.

 */
rc_t tiff_info(const char *fn) {

  TIFF *tif ;
  const char *me = "tiff_info" ;

  if (!(tif = TIFFOpen(fn,"r"))) {
    snprintf(msgbuf,sizeof(msgbuf),"can\'t read \"%s\"",fn) ;
    return(punt(here,__LINE__,me,msgbuf)) ;
  } ;
  TIFFPrintDirectory(tif,stdout,TIFFPRINT_NONE) ;
  TIFFClose(tif) ;
  return(OK) ;
}
