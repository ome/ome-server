/****************************************************************************/
/*                                                                          */
/*   voronoy.c                                                              */
/*                                                                          */
/*  implement Voronoy polygons.                                             */
/*                                                                          */
/*  Take a set of labeled points (x,y) in the plane.  Surround each labeled */
/*  point with walls (lines) such that every walled area around a point     */
/* (every Voronoy polygon) contains that area of the plane which is closer  */
/* to the central point than to any other point.  This divides the plane    */
/* into Voronoy polygons.                                                   */
/*                                                                          */
/*                                                                          */
/*     Author:  Christopher Grayce                                          */
/*     Copyright 2001 Christopher Grayce                                    */
/*     This file is part of OME.                                            */
/*                                                                          */ 
/*     OME is free software; you can redistribute it and/or modify          */
/*     it under the terms of the GNU General Public License as published by */
/*     the Free Software Foundation; either version 2 of the License, or    */
/*     (at your option) any later version.                                  */
/*                                                                          */
/*     OME is distributed in the hope that it will be useful,               */
/*     but WITHOUT ANY WARRANTY; without even the implied warranty of       */
/*     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        */
/*     GNU General Public License for more details.                         */
/*                                                                          */
/*     You should have received a copy of the GNU General Public License    */
/*     along with OME; if not, write to the Free Software Foundation, Inc.  */
/*        59 Temple Place, Suite 330, Boston, MA  02111-1307  USA           */
/*                                                                          */
/*                                                                          */
/****************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "voronoy.h"

#define OK     (0)
#define NO     (1)
#define YES    (2)
#define FATAL (-1)

#define VERTEX_R2_ZERO 1.0e-06
#define CHUNK 20

#define SQ(a) ((a)*(a))
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define MIN(a,b) ((a) <= (b) ? (a) : (b))

static char msgbuf[256] ;

/******************************************************************************

  Return error.

  */
static int punt(int line, const char *id, const char *msg) {

  if (msg) printf("%s [%s:%d]: %s\n",id,__FILE__,line,msg) ;
  return(FATAL) ;
}

/******************************************************************************

  Return memory error.

  */
static int memfail(int line, const char *id) {

  printf("%s [%s:%d]: can\'t allocate memory.\n",id,__FILE__,line) ;
  return(FATAL) ;
}

/******************************************************************************

  Return pointer memory error.

  */
static void *pmemfail(int line, const char *id) {

  printf("%s [%s:%d]: can\'t allocate memory.\n",id,__FILE__,line) ;
  return(0) ;
}

/************************************************************************

  Initialize a Voronoy polygon list.  We reqire:

  chunk = when we add memory for more Voronoy polygons, we do it in
          units of `chunk' polygons.

  */
void voyl_init(voyl_t *voyl, int chunk) {

  voyl->n = 0 ;
  voyl->sz = 0 ;
  voyl->chunk = chunk ;
  voyl->voy = 0 ;
}

/************************************************************************

  Free a polygon list.

  => to free polygons and the list, you need voyl_free_all.

  */
void voyl_free(voyl_t *voyl) {

  free(voyl->voy) ;
  voyl->voy = 0 ;
  voyl->n = voyl->sz = 0 ;
}

/************************************************************************

  Make sure a Voronoy polygon list has space for sz polygons.

*/
static int voyl_chksz(voyl_t *voyl, int sz) {

  int want ;
  const char *me = "voyl_chksz" ;

  if (voyl->sz < sz) {
    want = MAX(sz, voyl->sz + voyl->chunk) ;
    if (!(voyl->voy = (voy_t **)realloc(voyl->voy,want*sizeof(voy_t *))))
      return(memfail(__LINE__,me)) ;
    voyl->sz = want ;
  } ;
  return(OK) ;
}

/************************************************************************

  Add an uninitialized Voronoy polygon to a Voronoy polygon list,
  and return a pointer to it.

*/
static voy_t *voyl_next_voy(voyl_t *voyl) {

  static voy_t *voy ;
  const char *me = "voyl_next_voy" ;

  if ((voyl_chksz(voyl,voyl->n+1) != OK) ||
      !(voy = (voy_t *)malloc(sizeof(voy_t))))
    return(pmemfail(__LINE__,me)) ;
  voyl->voy[voyl->n++] = voy ;
  return(voy) ;
}

/******************************************************************************

  Initialize a Voronoy polyon.  We reqire:

  voy = must point to an uninitialized Voronoy polygon.
  ctr = the center of the polygon.
  ns  = the number of sides.
  sides = if not zero, points to an ordered list of ordered sides 
          (ordered about ctr, that is).

  */
static int voy_init(voy_t *voy, xy_t ctr, int ns, const line_t *sides) {

  const char *me = "voy_init" ;

  voy->n = ns ;
  voy->ctr = ctr ;
  if (!(voy->side = (line_t *)malloc(ns * sizeof(line_t))))
    return(memfail(__LINE__,me)) ;
  if (sides) memcpy(voy->side,sides,ns*sizeof(line_t)) ;
  return(OK) ;
}

/******************************************************************************

  Free memory allocated to a Voronoy polygon.

  */
static void voy_free(voy_t *voy) {

  free(voy->side) ;
  voy->side = 0 ;
}

/******************************************************************************

  Free all memory allocated to a Voronoy polygon list.  
  The individual polygons must have been allocated dynamically.

  */
void voyl_free_all(voyl_t *voyl) {

  int i ;

  for(i=0;i<voyl->n;i++) {
    voy_free(voyl->voy[i]) ; free(voyl->voy[i]) ;
  } ;
  free(voyl->voy) ;
  voyl->voy = 0 ;
  voyl->sz = 0 ;
  voyl->n = 0 ;
}

/******************************************************************************

  Return the line worklist.

  */
static line_t *get_wl_line(n,chunk) {

  static line_t *wl = 0 ;
  static int sz = 0 ;
  int want ;

  if (n > sz) {
    want = MAX(n,sz + chunk) ;
    if (!(wl = (line_t *)realloc(wl,want * sizeof(line_t)))) return(0) ;
    sz = want ;
  } ;
  return(wl) ;
}

/******************************************************************************

  Return the integer worklist.

  */
static int *get_wl_int(n,chunk) {

  static int *wl = 0 ;
  static int sz = 0 ;
  int want ;

  if (n > sz) {
    want = MAX(n,sz + chunk) ;
    if (!(wl = (int *)realloc(wl,want * sizeof(int)))) return(0) ;
    sz = want ;
  } ;
  return(wl) ;
}

/******************************************************************************

  Find the intersection of two lines.

  Returns YES if the lines are identical
          NO  if the lines are parallel 
          OK  if the lines intersect.
  */
static int line_intersec(xy_t *ipt, line_t li0, line_t li1) {

  double x,y ;

  if ((li0.m == li1.m) && (li0.vert == li1.vert)) {
    if ((li0.a.x == li1.a.x) && (li0.a.y == li1.a.y)) return(YES) ;
    return(NO) ;
  } ;

  if (li0.vert) {
    x = li0.a.x ;
    y = li1.a.y + li1.m * (x - li1.a.x) ;
  } else if (li1.vert) {
    x = li1.a.x ;
    y = li0.a.y + li0.m * (x - li0.a.x) ;
  } else {
    x = (li1.a.y - li0.a.y + li0.m * li0.a.x - li1.m * li1.a.x)/(li0.m - li1.m) ;
    y = li0.a.y + li0.m * (x - li0.a.x) ;
  } ;

  if (ipt) { ipt->x = x ; ipt->y = y ; } ;

  return(OK) ;
}

/******************************************************************************

  Find the line perpendicular to li0 passing through p0.

  */
static void line_perp(line_t *li1, line_t li0, xy_t p0) {

  if (li0.m == 0.0) {
    li1->m = 0.0 ; li1->vert = (li0.vert ? 0 : 1) ; 
  } else {
    li1->m = -1.0/li0.m ;    
  } ;
  li1->a = p0 ;
}

/******************************************************************************

  Find the line perpendicular to li0 passing through its midpoint

  */
static void line_perp_mid(line_t *li1, line_t li0) {

  if (li0.m == 0.0) { 
    li1->m = 0.0 ; li1->vert = (li0.vert ? 0 : 1) ; 
  } else {
    li1->m = -1.0/li0.m ;    
  } ;
  li1->a.x = (li0.b.x + li0.a.x)/2.0 ; li1->a.y = (li0.b.y + li0.a.y)/2.0 ;
}

/******************************************************************************

  Find the line segment p1 <- p0, li0->a guaranteed to be p0.

  */
static void line_seg(line_t *li0, xy_t p1, xy_t p0) {

  double dx ;

  li0->a = p0 ; li0->b = p1 ;
  if ((dx = li0->b.x - li0->a.x) == 0.0) {
    li0->m = 0.0 ; li0->vert = 1 ;
  } else {
    li0->m = (li0->b.y - li0->a.y)/dx ; li0->vert = 0 ;
  } ;
}

/******************************************************************************

  Return distance between points.

  */
static double d2_p2p(xy_t p1, xy_t p0) {

  return(SQ(p1.x-p0.x)+SQ(p1.y-p0.y)) ;
}

/******************************************************************************

  Return vertical distance from a point to a line.

  */
static double d2_p2line(line_t li0, xy_t p0) {

    line_t li1 ; xy_t p1 ;

  line_perp(&li1,li0,p0) ;
  line_intersec(&p1,li1,li0) ;
  return(d2_p2p(p1,p0)) ;
}

/******************************************************************************

  Return whether p0 on seg0 lies between end points of seg0 ;

  */
static int pt_on_seg(line_t seg0, xy_t p0) {
  
  double l2 = d2_p2p(seg0.b,seg0.a) ;

  return((d2_p2p(seg0.b,p0) < l2 + 1.0e-10) && 
	 (d2_p2p(seg0.a,p0) < l2 + 1.0e-10)) ;
}

/******************************************************************************

  Turn a line into a segment by clipping it where it exits a box.

  */
static void line_boxclip(line_t *seg, line_t li0, const line_t *box) {

  xy_t p[4] ;
  int np,i,j ;

  for(np=0,i=0;i<4;i++)
    if ((line_intersec(p+np,box[i],li0) == OK) && 
	pt_on_seg(box[i],p[np])) np += 1;
  if (np > 2) {
    /* at least one intersection is at a corner */
    for(i=0;i<np-1;i++) {
      for(j=i+1;j<np;j++) {
	if (d2_p2p(p[i],p[j]) < VERTEX_R2_ZERO) p[j] = p[(np--)-1] ;
      } ;
    } ;
  } ;
  seg->a = p[0] ;
  seg->b = p[1] ;
}

/******************************************************************************

  Return whether line p2<-p0 is counterclockwise around p0 from line p1<-p0. 

  */
static int pts_cc(xy_t p2, xy_t p1, xy_t p0) {

  double dx1,dx2,dy1,dy2 ;

  dx2 = p2.x - p0.x ; dy2 = p2.y - p0.y ;
  dx1 = p1.x - p0.x ; dy1 = p1.y - p0.y ;

  return((dx1*dy2 - dx2*dy1) > 0.0) ;
}  

/******************************************************************************

  Return whether segment seg1 is counterclockwise from segment seg0.

  */
static int seg_cc(line_t seg1, line_t seg0) {

  double dx1,dx0,dy1,dy0 ;

  dx1 = seg1.b.x - seg1.a.x ; dy1 = seg1.b.y - seg1.a.y ;
  dx0 = seg0.b.x - seg0.a.x ; dy0 = seg0.b.y - seg0.a.y ;
  return((dx0*dy1 - dx1*dy0) > 0.0) ;
}  

/******************************************************************************

  Order p2,p1 such that p2<-p1 goes around p0 counterclockwise.

  */
static void order_pts(xy_t *p2, xy_t *p1, xy_t p0) {

  xy_t p3 ;

  if (!pts_cc(*p2,*p1,p0)) { p3 = *p2 ; *p2 = *p1 ; *p1 = p3 ; }
}

/******************************************************************************

  For two segments ordered about p0, clip them if they intersect.

  Return NO  if they do not intersect.
         OK  if they do, and the earlier was clipped
         YES if they do, and the later was clipped. 1 = late, 0 = early.

  */
static int clip_sides(line_t *seg1, line_t *seg0, xy_t p0) {

  xy_t pi ;
  int rc ;

  if (line_intersec(&pi,*seg1,*seg0) != OK) return(NO) ;

  rc = NO ;
  if (pt_on_seg(*seg1,pi)) {
    seg1->a = pi ; rc = YES ;
  } ;
  if (pt_on_seg(*seg0,pi)) {
    seg0->b = pi ; rc = OK ;
  } ;
  return(rc) ;
}

/******************************************************************************

  Find max/min in a list of doubles ;

  */
static void list_maxmin(double *max, double *min, const double *list, int n) {

  double mx,mn ;
  int i ;

  mx = -1.0e+90 ; mn = 1.0e+90 ;
  for(i=0;i<n;i++) { mx = MAX(list[i],mx) ; mn = MIN(list[i],mn) ; } ;
  *max = mx ; *min = mn ;
}

/******************************************************************************

  NR Shell sort, ascending order, sort on d0, keep segl consistent.

  */
static void sort_dx_asc(int n, double *d0, line_t *segl) {

  int i,j,inc ;
  double v0 ;
  line_t seg ;

  for(inc = 1; inc <= n; inc = 3*inc+1) ;
  for(inc /= 3 ; inc > 0; inc /= 3) {
    for(i = inc; i < n; i++) {
      v0 = d0[i] ; seg = segl[i] ;
      for(j = i; (j >= inc) && (d0[j-inc] > v0) ; j -= inc) { 
	d0[j] = d0[j-inc] ; segl[j] = segl[j-inc] ;
      } ;
      d0[j] = v0 ; segl[j] = seg ;
    } ;
  } ;
}

/******************************************************************************

  Sort ordered segments into order arounx p0.


  */
static int sort_seg(line_t *segl, xy_t p0, int n) {

  static double *th = 0 ;
  static int last_n = 0 ;
  double dy,dx ;
  int i,want ;
  const char *me = "sort_seg" ;

  if (n > last_n) {
    want = MAX(n,last_n + CHUNK) ;
    if (!(th = (double *)realloc(th,want*sizeof(double))))
      return(memfail(__LINE__,me)) ;
    last_n = want ;
  } ;
  for(i=0;i<n;i++) {
    dy = segl[i].a.y - p0.y ; dx = segl[i].a.x - p0.x ;
    /* yuk */
    th[i] = atan2(dy,dx) ;
  } ;
  sort_dx_asc(n,th,segl) ;
  return(OK) ;
}

/******************************************************************************

  Make a clipping box around a collection of points.

  */
static void make_clipbox(line_t *clipbox, 
			 const double *xlist, const double *ylist,
			 const double *xbox, const double *ybox,
			 int nbox, int n) {

  xy_t p0,p1,p2,p3 ;
  double xmax,xmin,ymax,ymin,xbmax,ybmax,xbmin,ybmin,margin ;

  xbmax = ybmax = xbmin = ybmin = 0.0 ;
  list_maxmin(&xmax,&xmin,xlist,n) ;
  list_maxmin(&ymax,&ymin,ylist,n) ;
  if (xbox) list_maxmin(&xbmax,&xbmin,xbox,nbox) ;
  if (ybox) list_maxmin(&ybmax,&ybmin,ybox,nbox) ;
  
  xmax = MAX(xmax,xbmax) ; ymax = MAX(ymax,ybmax) ;
  xmin = MIN(xmin,xbmin) ; ymin = MIN(ymin,ybmin) ;

  margin = 0.01*(xmax-xmin) ;
  
  p0.x = xmin - margin ; p0.y = ymin - margin ;
  p1.x = xmax + margin ; p1.y = ymin - margin ;
  p2.x = xmax + margin ; p2.y = ymax + margin ;
  p3.x = xmin - margin ; p3.y = ymax + margin ;
  
  line_seg(clipbox+0,p1,p0) ;
  line_seg(clipbox+1,p2,p1) ;
  line_seg(clipbox+2,p3,p2) ;
  line_seg(clipbox+3,p0,p3) ;
}

/******************************************************************************

  Debug dump.

  */
static void dump_segl(const line_t *segwl, int n) {

  int i ;
  FILE *fp ;

  fp = fopen("seglist.dat","w") ;
  for(i=0;i<n;i++) fprintf(fp,"%f %f ",segwl[i].a.x,segwl[i].a.y) ;
  fprintf(fp,"\n") ;
  for(i=0;i<n;i++) fprintf(fp,"%f %f ",segwl[i].b.x,segwl[i].b.y) ;
  fprintf(fp,"\n") ;
  fclose(fp) ;
  
  fp = fopen("seglist.g","w") ;
  fprintf(fp,"plot ") ;
  for(i=0;i<n;i++) {
    fprintf(fp,"\"seglist.dat\" u %d:%d t \"%d\" w linesp",
	    1+2*i,1+2*i+1,i) ;
    if (i < n-1) fprintf(fp,",") ;
  } ;
  fprintf(fp,"\n") ;
  fclose(fp) ;
}

/******************************************************************************

  Another debug dump.

  */
void voy_dump(voyl_t *voyl) {

  int i,j ;
  voy_t *voy ;
  FILE *fp ;

  fp = fopen("voy_pts.dat","w") ;
  for(i=0;i<voyl->n;i++) {
    voy = voyl->voy[i] ;
    fprintf(fp,"%f %f\n",voy->ctr.x,voy->ctr.y) ;
  } ;
  fclose(fp) ;
  fp = fopen("voy_lines.dat","w") ;
  for(i=0;i<voyl->n;i++) {
    voy = voyl->voy[i] ;
    for(j=0;j<voy->n;j++) {
      fprintf(fp,"%f %f\n",voy->side[j].a.x,voy->side[j].a.y) ;
      fprintf(fp,"%f %f\n",voy->side[j].b.x,voy->side[j].b.y) ;
    } ;
    fprintf(fp,"\n") ;
  } ;
  fclose(fp) ;
}

/******************************************************************************

  Say whether p is within cone defined by vertex p0 and points
  on the rays p1, p2.

  */
static int inside_cone(xy_t p, xy_t p1, xy_t p2, xy_t p0) {

  xy_t plo,phi ;

  if (pts_cc(p2,p1,p0)) {
    plo = p1 ; phi = p2 ; 
  } else {
    plo = p2 ; phi = p1 ;     
  } ;
  return(pts_cc(p,plo,p0) && pts_cc(phi,p,p0)) ;
}

/******************************************************************************

  Say whether p is inside the triangle defined by p0,p1,p2.

  */
static int inside_tri(xy_t p, xy_t p0, xy_t p1, xy_t p2) {

  return(inside_cone(p,p1,p2,p0) && 
	 inside_cone(p,p0,p2,p1) && 
	 inside_cone(p,p0,p1,p2)) ;
}

/******************************************************************************

  Say whether p is inside a Voronoy polygon.

  */
int voy_p_inside(const voy_t *voy, double x, double y) {

  xy_t p0,p ;
  int i ;

  p0 = voy->ctr ;
  p.x = x ; p.y = y ;
  for(i=0;i<voy->n;i++) {
    if (inside_tri(p,p0,voy->side[i].a,voy->side[i].b)) return(1) ;
  } ;
  return(0) ;
}

/******************************************************************************

  Return 2 x,y values that define a box that contains a Voronoy polygon.

  */
void voy_box(double *x, double *y, const voy_t *voy) {

  double xmin,xmax,ymin,ymax ;
  int i ;

  xmin = ymin = +1.0e+30 ; xmax = ymax = -1.0e+30 ;
  for(i=0;i<voy->n;i++) {
    if (voy->side[i].a.x < xmin) xmin = voy->side[i].a.x ;
    if (voy->side[i].a.x > xmax) xmax = voy->side[i].a.x ;
    if (voy->side[i].a.y < ymin) ymin = voy->side[i].a.y ;
    if (voy->side[i].a.y > ymax) ymax = voy->side[i].a.y ;
    if (voy->side[i].b.x < xmin) xmin = voy->side[i].b.x ;
    if (voy->side[i].b.x > xmax) xmax = voy->side[i].b.x ;
    if (voy->side[i].b.y < ymin) ymin = voy->side[i].b.y ;
    if (voy->side[i].b.y > ymax) ymax = voy->side[i].b.y ;
  } ;
  x[0] = xmin ; y[0] = ymin ;
  x[1] = xmax ; y[1] = ymax ;
}

/******************************************************************************

  Verify a Voronoy polygon.

  */
static int voy_chk(const voy_t *voy) {

  line_t seg ;
  double r2,tol ;
  xy_t p0 ;
  int i,ns,iprev,inext,errs ;
  const char *me = "voy_chk" ;

  p0 = voy->ctr ;
  ns = voy->n ;
  tol = VERTEX_R2_ZERO ;
  errs = 0 ;
  for(i=0;i<ns;i++) {
    seg = voy->side[i] ;
    if (!pts_cc(seg.b,seg.a,p0)) {
      printf("* %s [%s:%d]: side %d is not ordered.\n",me,
	     __FILE__,__LINE__,i) ;
      errs += 1 ;
    } ;
    iprev = (i? i-1 : ns-1) ;
    if ((r2 = d2_p2p(voy->side[iprev].b,seg.a)) > SQ(tol)) {
      printf("* %s [%s:%d]: side %d and previous side %d don\'t meet.\n",
	     me,__FILE__,__LINE__,i,iprev) ;
      errs += 1 ;
    } ;
    if ((inext = i+1) == ns) inext = 0 ;
    if ((r2 = d2_p2p(seg.b,voy->side[inext].a)) > SQ(tol)) {
      printf("* %s [%s:%d]: side %d and next side %d don\'t meet.\n",
	     me,__FILE__,__LINE__,i,inext) ;
      errs += 1 ;
    } ;
  } ;
  if (errs) dump_segl(voy->side,ns) ;
  return(OK) ;
}        

/******************************************************************************

  Construct a Voronoy polygon around ptlist[i].

  */
static int voy_make(voy_t *voy, const xy_t *ptlist, const line_t *clipbox,
		    const line_t *box, int i, int nbox,int np) {

  int *nexseg ;
  line_t *segwl ;
  double d2min,d2 ;
  int nseg,nok,j,k,early,late,imin ;
  xy_t p0 ;
  const char *me = "voy_make" ;
  static line_t debug_wl[1000] ;
  FILE *fp ;

  p0 = ptlist[i] ;
  if (!(segwl = get_wl_line(nbox+SQ(np),1000))) return(memfail(__LINE__,me)) ;
  memcpy(segwl,box,nbox*sizeof(line_t)) ;
  for(j=0;j<nbox;j++) order_pts(&(segwl[j].b),&(segwl[j].a),p0) ;
  nseg = nbox ;
  for(j=0;j<np;j++) {
    if (j == i) continue ;
    line_seg(segwl+nseg,ptlist[j],p0) ;
    line_perp_mid(segwl+nseg,segwl[nseg]) ;
    line_boxclip(segwl+nseg,segwl[nseg],clipbox) ;
    order_pts(&(segwl[nseg].b),&(segwl[nseg].a),p0) ;
    nseg += 1 ;
  } ;
  if (!(nexseg = get_wl_int(nseg,1000))) return(memfail(__LINE__,me)) ;
  memset(nexseg,~0,nseg*sizeof(int)) ;
  if (sort_seg(segwl,p0,nbox) != OK) return(memfail(__LINE__,me)) ;
  for(j=0;j+1<nbox;j++) nexseg[j] = nexseg[j+1] ; nexseg[nbox-1] = 0 ;

  memcpy(debug_wl,segwl,nseg*sizeof(line_t)) ;

  for(j=0;j<nseg;j++) {
    for(k=0;k<j;k++) {
      if (seg_cc(segwl[j],segwl[k])) {
	early = k ; late = j ;
      } else {
	early = j ; late = k ;
      } ;
      if (clip_sides(segwl+late,segwl+early,p0) == OK) nexseg[early] = late ;
    } ;
  } ;
  d2min = 1.0e+30 ; imin = -1 ;
  for(i=0;i<nseg;i++)
    if ((d2 = d2_p2line(segwl[i],p0)) < d2min) { d2min = d2 ; imin = i ; } ;
  for(nok=1,i=imin; (nok < nseg) && (nexseg[i] >= 0) && (nexseg[i] < nseg) && 
	(nexseg[i] != imin); i=nexseg[i],nok++) ;
  if (nexseg[i] != imin) return(punt(__LINE__,me,"no closed chain.")) ;
  if (voy_init(voy,p0,nok,0) != OK) return(memfail(__LINE__,me)) ;
  voy->side[0] = segwl[imin] ;
  for(nok=1,i=imin; nexseg[i] != imin; i=nexseg[i],nok++)
    voy->side[nok] = segwl[nexseg[i]] ;
  if (voy_chk(voy) != OK) {
    snprintf(msgbuf,sizeof(msgbuf),"failed on polygon %d center (%f,%f)",
	     i,p0.x,p0.y) ;
    fp = fopen("last_problem.dat","w") ;
    for(i=0;i<np;i++) fprintf(fp,"%20.16e %20.16e\n",ptlist[i].x,ptlist[i].y) ;
    fclose(fp) ;
    return(punt(__LINE__,me,msgbuf)) ;
  } ;
  return(OK) ;
}      

/******************************************************************************

  Allocate and construct a complete Voronoy polygon list.  We require:

  voyl = must point to an initialized Voronoy polygon list.
  x,y  = must point to the n x,y coordinates of the polygon centers.
  xbox,ybox = must point to the nbox x,y coordinates of the corners of the
         box that encloses all the points.

  */
int voyl_voyize(voyl_t *voyl, const double *x, const double *y, 
		const double *xbox, const double *ybox, int nbox, int n) {
  
  line_t clipbox[4] ;
  line_t *box ;
  voy_t *voy ;
  xy_t p0,p1 ;
  xy_t *ptlist ;
  int i ;
  const char *me = "voyl_voyize" ;

  if (!(box = (line_t *)malloc(nbox * sizeof(line_t))) ||
      !(ptlist = (xy_t *)malloc(n * sizeof(xy_t))) )
    return(memfail(__LINE__,me)) ;

  make_clipbox(clipbox,x,y,xbox,ybox,nbox,n) ;

  p0.x = xbox[nbox-1] ; p0.y = ybox[nbox-1] ;
  p1.x = xbox[0] ; p1.y = ybox[0] ;
  line_seg(box,p1,p0) ;
  for(i=1;i<nbox;i++) {
    p0 = box[i-1].b ;
    p1.x = xbox[i] ; p1.y = ybox[i] ;
    line_seg(box+i,p1,p0) ;
  } ;
  for(i=0;i<n;i++) ptlist[i].x = x[i] ;
  for(i=0;i<n;i++) ptlist[i].y = y[i] ;

  for(i=0;i<n;i++) {
    if (!(voy = voyl_next_voy(voyl))) break ;
    if (voy_make(voy,ptlist,clipbox,box,i,nbox,n) != OK) break ;
  } ;
  free(ptlist) ; free(box) ;
  return((i == n ? OK : FATAL)) ;
}
