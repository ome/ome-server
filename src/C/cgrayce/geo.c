/******************************************************************************

  Routines which calculate and make use of the geometric properties of objects.

  */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "util.h"
#include "obj.h"
#include "gras.h"
#include "datafile.h"
#include "geo.h"

/******************************************************************************

  Convert between names and types of properties.

  */
geo_t s2geo(const char *name) {

  if (!strcasecmp(name,"none"))   return(GEO_NONE) ;
  if (!strcasecmp(name,"area"))   return(GEO_AREA) ;
  if (!strcasecmp(name,"aspect")) return(GEO_ASPECT) ;
  if (!strcasecmp(name,"rg"))     return(GEO_RG) ;
  if (!strcasecmp(name,"rrg"))    return(GEO_RRG) ;
  /* `comp' = `compactness' is a synonym for relative Rg */
  if (!strcasecmp(name,"comp"))   return(GEO_RRG) ;
  if (!strcasecmp(name,"axis"))   return(GEO_AXIS) ;
  return(GEO_NONE) ;
}

/******************************************************************************

  Center of mass, relative to object origin.

*/
void geo_com_rel(const obj_t *ob, double *ycom, double *xcom) {

  int x,y,i ;

  for(x=y=i=0;i<ob->n;i++) { y += ob->ydata[i] ; x += ob->xdata[i] ; } ;
  if (ycom) *ycom = (double)y/(double)(ob->n) ; 
  if (xcom) *xcom = (double)x/(double)(ob->n) ;
}

/******************************************************************************

  Center of mass.

*/
void geo_com(const obj_t *ob, double *ycom, double *xcom) {

  double x,y ;

  geo_com_rel(ob,&y,&x) ;
  if (ycom) *ycom = (double)(ob->yorg) + y ;
  if (xcom) *xcom = (double)(ob->xorg) + x ;
}

/******************************************************************************

  Radius of gyration squared.

*/
double geo_rg2(const obj_t *ob) {

  double y,x,ycom,xcom,r2 ;
  int i ;

  geo_com_rel(ob,&ycom,&xcom) ;
  r2 = 0.0 ;
  for(i=0;i<ob->n;i++) { 
    y = (double)(ob->ydata[i]) ; x = (double)(ob->xdata[i]) ; 
    r2 += SQ(x - xcom) + SQ(y - ycom) ;
  } ;
  return(r2) ;
}

/******************************************************************************

  Components of the moment of inertia tensor.

*/
static void geo_moi_t(const obj_t *ob, 
		      double *ixx, double *ixy, double *iyy) {

  double y,x,ycom,xcom,dy,dx,xx,xy,yy ;
  int i ;

  geo_com_rel(ob,&ycom,&xcom) ;    
  xx = xy = yy = 0.0 ;
  for(i=0;i<ob->n;i++) { 
    y = (double)(ob->ydata[i]) ; x = (double)(ob->xdata[i]) ;
    dy = y - ycom ; dx = x - xcom ; 
    xx += SQ(dy) ;  xy += -dx*dy ; yy += SQ(dx) ;
  } ;
  if (ixx) *ixx = xx ; 
  if (ixy) *ixy = xy ; 
  if (iyy) *iyy = yy ; 
}

/******************************************************************************

  Principal moments of inertia.

*/
void geo_moi(const obj_t *ob, double *mbig, double *msmall) {

  double ixx,ixy,iyy,m0,m1,a,b,c,q ;

  geo_moi_t(ob,&ixx,&ixy,&iyy) ;
  a = 1.0 ; b = -(ixx+iyy) ; c = ixx*iyy - SQ(ixy) ;
  q = -0.5*(b + (b > 0.0 ? 1.0 : -1.0)*sqrt(fabs(SQ(b)-4.0*a*c))) ;
  m0 = q/a ; m1 = c/q ;
  if(mbig  ) *mbig   = MAX(m0,m1) ;
  if(msmall) *msmall = MIN(m0,m1) ;
}

/******************************************************************************

  Aspect ratio: 
  defined as the ratio of the smaller to the larger principal
  moment of inertia, i.e. near zero for lines, 1.0 for circles, squares,
  and other symmetric objects, between 0 and 1 for ellipses, squashed 
  circles, etc.

*/
double geo_aspect(const obj_t *ob) {
  
  double mbig,msmall ;

  geo_moi(ob,&mbig,&msmall) ;
  return(msmall/mbig) ;
}

/******************************************************************************

  Relative radius of gyration squared: 
  defined to be Rg^2 divided by Rg^2 for an ellipse of the same area and 
  aspect ratio.  A measure of the `compactness' of an object, meaning how 
  ramified and fingered it is.

*/
double geo_rrg2(const obj_t *ob) {

  double a,rg2,asp,rg2_ellipse ;

  a = (double)ob->n ;
  rg2 = geo_rg2(ob) ;
  asp = geo_aspect(ob) ;
  rg2_ellipse = SQ(a)*(1.0+asp)/(4.0*M_PI*sqrt(asp)) ;
  return(rg2/rg2_ellipse) ;
}

/******************************************************************************

  Principal axis (where the object ``points''): 
  defined to be the y and x components of the unit eigenvector of the larger 
  moment of inertia.  The x component is positive semidefinite, that is, the
  principal axis always points towards the +x axis and lies between the +y 
  and -y axes.

  For example, yax/xax = tan(t) where t is the angle from horizontal which
  the principal axis makes.
*/
void geo_axis(const obj_t *ob, double *yax, double *xax) {
  
  double ixx,ixy,iyy,mbig,msmall,yx,xx,ftmp ;

  geo_moi_t(ob,&ixx,&ixy,&iyy) ;
  geo_moi(ob,&mbig,&msmall) ;
  if (ixy == 0.0) {
    yx = 1.0 ; xx = 0.0 ;
  } else {
    ftmp = (mbig-iyy)/(mbig-ixx) ;
    yx = ftmp/(1.0 + ftmp) ;
    xx = 1.0 - yx ;
    yx = sqrt(fabs(yx)) ;
    if (ixy < 0.0) yx = -yx ;
    xx = sqrt(fabs(xx)) ;
  } ;
  if (yax) *yax = yx ;
  if (xax) *xax = xx ;
}

/******************************************************************************

  Sort objects in an object list by integer property prop.
  If plist != 0 copy into it the sorted list of the values of the property.
  
  */
static rc_t geo_sort_i(objl_t *ol, geo_t prop, int *plist) {

  int *crit ;
  int o ;
  const char *me = "geo_sort_i" ;

  if (prop == GEO_NONE) return(OK) ;

  if (!(crit = (int *)malloc(ol->n * sizeof(int))))
    return(memfail(__FILE__,__LINE__,me)) ;
  switch (prop) {
  case GEO_AREA :
    for(o=0;o<ol->n;o++) crit[o] = ol->obj[o]->n ;
    break ;
  default :
    return(punt(__FILE__,__LINE__,me,"bad property specified.")) ;
  } ;
  sort_ix_desc(ol->n,crit,(void **)ol->obj) ;
  if (plist) memcpy(plist,crit,ol->n * sizeof(int)) ;
  free(crit) ;
  return(OK) ;
}

/******************************************************************************

  Sort objects in an object list by floating point property prop.
  If plist != 0 copy into it the sorted list of the values of the property.
  
  */
static rc_t geo_sort_f(objl_t *ol, geo_t prop, double *plist) {
  
  double *crit ;
  int o ;
  const char *me = "geo_sort_f" ;

  if (prop == GEO_NONE) return(OK) ;

  if (!(crit = (double *)malloc(ol->n * sizeof(double))))
    return(memfail(__FILE__,__LINE__,me)) ;
  switch (prop) {
  case GEO_ASPECT :
    for(o=0;o<ol->n;o++) crit[o] = geo_aspect(ol->obj[o]) ;
    break ;
  case GEO_RG :
    for(o=0;o<ol->n;o++) crit[o] = geo_rg2(ol->obj[o]) ;
    break ;
  case GEO_RRG :
    for(o=0;o<ol->n;o++) crit[o] = geo_rrg2(ol->obj[o]) ;
    break ;
  default :
    return(punt(__FILE__,__LINE__,me,"bad property specified.")) ;
  } ;
  sort_dx_desc(ol->n,crit,(void **)ol->obj) ;
  if (plist && memcpy(plist,crit,ol->n * sizeof(double))) ;
  free(crit) ;
  return(OK) ;
}

/******************************************************************************

  Sort objects in an object list by property prop.
  If plist != 0 copy into it the sorted list of the values of the property.
  
  */
rc_t geo_sort(objl_t *ol, geo_t prop, void *plist) {

  const char *me = "geo_sort" ;

  if (prop == GEO_NONE) return(OK) ;

  switch(prop) {
  case GEO_AREA :
    return(geo_sort_i(ol,prop,(int *)plist)) ;
  case GEO_ASPECT :
  case GEO_RG :
  case GEO_RRG :
    return(geo_sort_f(ol,prop,(double *)plist)) ;
  default :
    return(punt(__FILE__,__LINE__,me,"bad property specified.")) ;
  } ;
  return(OK) ;
}

/******************************************************************************

  Prune objects from a list which have integer properties >min, <max.

  */
rc_t geo_prune_i(objl_t *ol, geo_t prop, int min, int max) {

  int *crit ;
  int omin,omax ;
  const char *me = "geo_prune_i" ;

  if (prop == GEO_NONE) return(OK) ;
  if (!(crit = (int *)malloc(ol->n * sizeof(int))))
    return(memfail(__FILE__,__LINE__,me)) ;
  if (geo_sort_i(ol,prop,crit) != OK) return(subfail(__FILE__,__LINE__,me)) ;
  for(omin=0;(omin<ol->n) && (crit[omin] > max);omin++) ;
  for(omax=omin;(omax<ol->n) && (crit[omax] > min);omax++) ;
  memmove(ol->obj,ol->obj+omin,(omax-omin)*sizeof(obj_t *)) ;
  ol->n = (omax-omin) ;
  free(crit) ;
  return(OK) ;
}

/******************************************************************************

  Prune objects from a list which have floating point properties >min, <max.

  */
rc_t geo_prune_f(objl_t *ol, geo_t prop, double min, double max) {

  double *crit ;
  int omin,omax ;
  const char *me = "geo_prune_f" ;

  if (prop == GEO_NONE) return(OK) ;
  if (!(crit = (double *)malloc(ol->n * sizeof(double))))
    return(memfail(__FILE__,__LINE__,me)) ;
  if (geo_sort_f(ol,prop,crit) != OK) return(subfail(__FILE__,__LINE__,me)) ;
  for(omin=0;(omin<ol->n) && (crit[omin] > max);omin++) ;
  for(omax=omin;(omax<ol->n) && (crit[omax] > min);omax++) ;
  memmove(ol->obj,ol->obj+omin,(omax-omin)*sizeof(obj_t *)) ;
  ol->n = (omax-omin) ;
  free(crit) ;
  return(OK) ;
}

/************************************************************************

  Dump a text data file 
  containing geometric properties of the objects in a list, sorted
  according to prop, if this is nonzero and != GEO_NONE.

  */
rc_t geo_dump_info(objl_t *ol, const char *fn, 
		   geo_t prop, const char *fn_img) {

  const char *fn_default = "obj-info.dat" ;
  const char *fmt = 
    "1=obj_num 2=y 3=x 4=area 5=aspect_ratio 6=axis_angle 7=compactness" ;
  datafile_reg_t dfr ;
  obj_t *ob ;
  double xcom,ycom,rrg2,yax,xax,aspect,ang ;
  int o ;
  FILE *fp ;
  const char *me = "geo_dump_info" ;

  if (!fn || !strlen(fn)) fn = fn_unique(fn_default) ;
  datafile_init(&dfr,me,__FILE__,__DATE__,__TIME__) ;
  if (!(fp = datafile_open((char *)fn,0,&dfr))) 
    return(subfail(__FILE__,__LINE__,me)) ;
  fprintf(fp,"# contents = description of objects in image file.\n") ;
  if (fn_img) fprintf(fp,"# image file = %s\n",fn_img) ;
  fprintf(fp,"# number of objects = %d\n",ol->n) ;
  fprintf(fp,"# format = %s\n",fmt) ;
  geo_sort(ol,prop,0) ;
  for(o=0;o<ol->n;o++) {
    ob = ol->obj[o] ;
    geo_com(ob,&ycom,&xcom) ;
    rrg2 = geo_rrg2(ob) ;
    aspect = geo_aspect(ob) ;
    geo_axis(ob,&yax,&xax) ;
    ang = 180.0/M_PI * atan2(yax,xax) ;
    fprintf(fp,"%d\t%f\t%f\t%d\t%f\t\t%f\t%f\n",
	    o,ycom,xcom,ob->n,aspect,ang,rrg2) ;
  } ;
  fclose(fp) ;
  if (verbosity < MSG_NONE)
    printf("%s [%s:%d]: wrote geometry of %d objs to \"%s\".\n",
	   me,__FILE__,__LINE__,o,fn) ;
  return(OK) ;
}
