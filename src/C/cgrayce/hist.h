/************************************************************************

  Grayvalue histograms.

  Plots of number of grayvalues versus grayvalue.  

  */
#ifndef _HIST_
#define _HIST_

/* a histogram structure: */
typedef struct {
  int n ;                    /* bins */
  int nmax ;                 /* maximum number of bins */
  int binsz ;                /* binsize */
  unsigned int *x ;          /* abscissas */
  unsigned int *y ;          /* ordinates */
  unsigned int sum ;         /* integral */
} hist_t ;

/************************************************************************

  Initialize, free, check size.

  */
extern rc_t hist_init(hist_t *hs, int bins) ;
extern void hist_free(hist_t *hs) ;
extern rc_t hist_chksz(hist_t *hs, int bins) ;

/************************************************************************

  Construct a plain histogram of grayscale pixel values.

  */
extern rc_t hist_plain(hist_t *hs, const gras_t *gr, int binsz) ;

/************************************************************************

  Convert a plain histogram into a cumulative histogram.

  */
extern rc_t hist_plain2cum(hist_t *hs_cum, const hist_t *hs_plain) ;

/************************************************************************

  Construct cumulative histogram of grayscale pixel values.

  */
extern rc_t hist_cum(hist_t *hs, const gras_t *gr, int binsz) ;

/************************************************************************

  Estimate bin, x max, y max, and full width at half maximum 
  of the largest peak in a histogram.

  */
extern rc_t hist_peak(int *bin, int *xmax, int *ymax, int *fwhm, 
		      const hist_t *hs) ;

/************************************************************************

  Copy a histogram from hs_src to hs_dat, and eliminate on the way
  prefix and suffix stretches of bins containing zero grayvalues.

  */
extern rc_t hist_unpad(hist_t *hs_dst, const hist_t *hs_src) ;

/************************************************************************

  Find the region in a cumulative histogram which contains 
  between frac_lo and frac_hi of the fraction of total pixels.

  */
extern rc_t hist_cum_region(const hist_t *hs, int *lo, int *hi,
			    double frac_lo, double frac_hi) ;

/************************************************************************

  Clip a plain histogram so it contains between frac_lo and frac_hi
  fractions of the total pixels in the histogram.

  */
extern rc_t hist_plain_clip(hist_t *hs_dst, const hist_t *hs_src, 
			    double frac_lo, double frac_hi) ;

/************************************************************************

  Try fitting ng Gaussians to a histogram:

  => requires fit_nonlinear.o

  xsq = place to store fit figure of merit on return
  ap = amplitudes )
  cp = centers    ) of Gaussians - must contain initial guesses on entry.
  wp = widths     )
  hs = the histogram
  tol = tolerance on fit -- fit considered good when xsq  change/iteration 
        becomes less than tol.
  itmax = how many iterations of fitting procedure will be attempted 
          before giving up.
  ng = number of Gaussians.

  */
extern rc_t hist_fit_gauss(double *xsq, double *ap, double *cp, double *wp,
			   const hist_t *hs, double tol, int itmax, int ng) ;

/******************************************************************************

  Assign histogram ordinates from a sum of Gaussians.

  */
extern void hist_model_gauss(hist_t *hs, const double *amp, 
			     const double *ctr, const double *wid, int ng) ;

/******************************************************************************

  Dump standard raster histogram to text data file.

  */
extern rc_t hist_dump_gras(const gras_t *gr, const char *fn, 
			   const char *fn_img) ;


#endif
