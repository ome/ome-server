/* filt.h: definitions for filter data types and routines */

#ifndef FILT_HDR
#define FILT_HDR

/* $Header$ */

typedef struct {		/* A 1-D FILTER */
    char *name;			/* name of filter */
    double (*func)(double x, char *d);		/* filter function */
    double supp;		/* radius of nonzero portion */
    double blur;		/* blur factor (1=normal) */
    char windowme;		/* should filter be windowed? */
    char cardinal;		/* is this filter cardinal?
				   ie, does func(x) = (x==0) for integer x? */
    char unitrange;		/* does filter stay within the range [0..1] */
    void (*initproc)(void);		/* initialize client data, if any N.B.: void parameters is a guess (IGG 1/23/04)*/
    void (*printproc)(char *clientdata);	/* print client data, if any */
    char *clientdata;		/* client info to be passed to func */
} Filt;

#define filt_func(f, x) (*(f)->func)((x), (f)->clientdata)
#define filt_print_client(f) (*(f)->printproc)((f)->clientdata)

Filt *filt_find(char *name);
Filt *filt_window(Filt *f, char *windowname);
void filt_print(Filt *f);
void filt_catalog(void);


/* the filter collection: */

double filt_box (double x, char *d);		/* box, pulse, Fourier window, */
double filt_triangle (double x, char *d);		/* triangle, Bartlett window, */
double filt_quadratic (double x, char *d);	/* 3rd order (quadratic) b-spline */
double filt_cubic (double x, char *d);		/* 4th order (cubic) b-spline */
double filt_catrom (double x, char *d);		/* Catmull-Rom spline, Overhauser spline */
double filt_mitchell (double x, char *d);		/* Mitchell & Netravali's two-param cubic */
double filt_gaussian (double x, char *d);		/* Gaussian (infinite) */
double filt_sinc (double x, char *d);		/* Sinc, perfect lowpass filter (infinite) */
double filt_bessel (double x, char *d);		/* Bessel (for circularly symm. 2-d filt, inf)*/

double filt_hanning (double x, char *d);		/* Hanning window */
double filt_hamming (double x, char *d);		/* Hamming window */
double filt_blackman (double x, char *d);		/* Blackman window */
double filt_kaiser (double x, char *d);		/* parameterized Kaiser window */

double filt_normal (double x, char *d);		/* normal distribution (infinite) */


/* support routines */
double bessel_i0 (double x);

#endif
