/*
 * zoom_main: main program for image zooming
 *
 * see comments in zoom.c
 *
 * note: DEFAULT_FILE must be set in Makefile
 */

#include <math.h>

#include <simple.h>
#include <pic.h>
#include "filt.h"
#include "zoom.h"

#define UNDEF PIC_UNDEFINED
#define FILTER_DEFAULT "triangle"
#define WINDOW_DEFAULT "blackman"

double atof_check();

static char usage[] = "\
Usage: zoom [options]\n\
-src %s		source filename\n\
-dst %s		dest filename\n\
-s %d%d%d%d	source box (x0 y0 xsize ysize)\n\
-d %d%d%d%d	dest box\n\
-sw %d%d%d%d	window (x0 y0 x1 y1)\n\
-dw %d%d%d%d	dest window\n\
-map %f%f%f%f	scale and translate: sx sy tx ty (src to dst by default)\n\
-square		use square mapping (don't stretch pixels)\n\
-intscale	use integer scale factors\n\
-filt %s[%s	filter name in x and y (default=triangle)\n\
			\"-filt '?'\" prints a filter catalog\n\
-supp %f[%f	filter support radius\n\
-blur %f[%f	blur factor: >1 is blurry, <1 is sharp\n\
-window %s[%s	window an IIR filter (default=blackman)\n\
-mono		monochrome mode (1 channel)\n\
-debug %d	print filter coefficients\n\
-xy		filter x before y\n\
-yx		filter y before x\n\
-plain		disable filter coercion\n\
-keep0		keep zeros in xfilter\n\
-dev		print list of known picture devices/file formats\n\
Where %d denotes integer, %f denotes float, %s denotes string,\n\
and '[' marks optional following args\n\
";

main(ac, av)
int ac;
char **av;
{
    char *xfiltname = FILTER_DEFAULT, *yfiltname = 0;
    char *xwindowname = 0, *ywindowname = 0;
    char *srcfile = DEFAULT_FILE;
    char *dstfile = DEFAULT_FILE;
    int xyflag, yxflag, mono, nocoerce, nchan, square, intscale, keepzeros, i;
    double xsupp = -1., ysupp = -1.;
    double xblur = -1., yblur = -1.;
    Pic *apic, *bpic;
    Window_box a;		/* src window */
    Window_box b;		/* dst window */
    Mapping m;
    Filt *xfilt, *yfilt, xf, yf;

    a.x0 = b.x0 = UNDEF;
    a.x1 = b.x1 = UNDEF;
    m.sx = 0.;
    square = 0;
    intscale = 0;
    mono = 0;
    xyflag = 0;
    yxflag = 0;
    nocoerce = 0;
    keepzeros = 0;

    for (i=1; i<ac; i++)
	if (av[i][0]=='-')
	    if (str_eq(av[i], "-src") && ok(i+1<ac, "-src"))
		srcfile = av[++i];
	    else if (str_eq(av[i], "-dst") && ok(i+1<ac, "-dst"))
		dstfile = av[++i];
	    else if (str_eq(av[i], "-s") && ok(i+4<ac, "-s")) {
		a.x0 = atof_check(av[++i]);
		a.y0 = atof_check(av[++i]);
		a.nx = atof_check(av[++i]);
		a.ny = atof_check(av[++i]);
	    }
	    else if (str_eq(av[i], "-d") && ok(i+4<ac, "-d")) {
		b.x0 = atof_check(av[++i]);
		b.y0 = atof_check(av[++i]);
		b.nx = atof_check(av[++i]);
		b.ny = atof_check(av[++i]);
	    }
	    else if (str_eq(av[i], "-sw") && ok(i+4<ac, "-sw")) {
		a.x0 = atof_check(av[++i]);
		a.y0 = atof_check(av[++i]);
		a.x1 = atof_check(av[++i]);
		a.y1 = atof_check(av[++i]);
	    }
	    else if (str_eq(av[i], "-dw") && ok(i+4<ac, "-dw")) {
		b.x0 = atof_check(av[++i]);
		b.y0 = atof_check(av[++i]);
		b.x1 = atof_check(av[++i]);
		b.y1 = atof_check(av[++i]);
	    }
	    else if (str_eq(av[i], "-map") && ok(i+4<ac, "-map")) {
		m.sx = atof_check(av[++i]);
		m.sy = atof_check(av[++i]);
		m.tx = atof_check(av[++i]);
		m.ty = atof_check(av[++i]);
	    }
	    else if (str_eq(av[i], "-square"))
		square = 1;
	    else if (str_eq(av[i], "-intscale"))
		intscale = 1;
	    else if (str_eq(av[i], "-filt") && ok(i+1<ac, "-filt")) {
		xfiltname = av[++i];
		if (i+1<ac && av[i+1][0]!='-') yfiltname = av[++i];
	    }
	    else if (str_eq(av[i], "-supp") && ok(i+1<ac, "-supp")) {
		xsupp = atof_check(av[++i]);
		if (i+1<ac && av[i+1][0]!='-') ysupp = atof_check(av[++i]);
	    }
	    else if (str_eq(av[i], "-blur") && ok(i+1<ac, "-blur")) {
		xblur = atof_check(av[++i]);
		if (i+1<ac && av[i+1][0]!='-') yblur = atof_check(av[++i]);
	    }
	    else if (str_eq(av[i], "-window") && ok(i+1<ac, "-window")) {
		xwindowname = av[++i];
		if (i+1<ac && av[i+1][0]!='-') ywindowname = av[++i];
	    }
	    else if (str_eq(av[i], "-mono"))
		mono = 1;
	    else if (str_eq(av[i], "-debug") && ok(i+1<ac, "-debug"))
		zoom_debug = atof_check(av[++i]);
	    else if (str_eq(av[i], "-xy"))
		xyflag = 1;
	    else if (str_eq(av[i], "-yx"))
		yxflag = 1;
	    else if (str_eq(av[i], "-plain"))
		nocoerce = 1;
	    else if (str_eq(av[i], "-keep0"))
		keepzeros = 1;
	    else if (str_eq(av[i], "-dev")) {
		pic_catalog();
		exit(0);
	    }
	    else {
		if (!str_eq(av[i], "-"))
		    fprintf(stderr, "unrecognized argument: %s\n", av[i]);
		fputs(usage, stderr);
		exit(1);
	    }

    if (str_eq(xfiltname, "?")) {
	filt_catalog();
	exit(0);
    }
    if (xyflag) zoom_xy = 1;
    if (yxflag) zoom_xy = 0;
    zoom_coerce = !nocoerce;
    zoom_trimzeros = !keepzeros;

    bpic = pic_open(dstfile, "w");
    if (!bpic) {
	fprintf(stderr, "can't get %s\n", dstfile);
	exit(1);
    }
    apic = str_eq(srcfile, dstfile) ? bpic : pic_open(srcfile, "r");
    if (!apic) {
	fprintf(stderr, "can't get %s\n", srcfile);
	exit(1);
    }

    /* how many channels are src and dst?  maybe src knows... */
    nchan = pic_get_nchan(apic);
    if (nchan==UNDEF) {
	nchan = mono ? 1 : 3;
	pic_set_nchan(apic, nchan);
    }
    pic_set_nchan(bpic, nchan);

    /*
     * set source and dest subwindows a and b of apic and bpic
     * note: pic_get_window doesn't set nx, ny fields of Window_box struct
     */
    if (a.x0==UNDEF) pic_get_window(apic, (Window_box *)&a);
    if (a.x1==UNDEF) window_box_set_max(&a);
    if (b.x0==UNDEF) pic_get_window(bpic, (Window_box *)&b);
    if (b.x1==UNDEF) window_box_set_max(&b);
    /*
     * nx and ny uninitialized at this point
     * pic_get_window might return x0=UNDEF for bpic
     */

    if (!yfiltname) yfiltname = xfiltname;
    xfilt = filt_find(xfiltname);
    yfilt = filt_find(yfiltname);
    if (!xfilt || !yfilt) {
	fprintf(stderr, "can't find filters %s and %s\n",
	    xfiltname, yfiltname);
	exit(1);
    }
    /* copy the filters before modifying them */
    xf = *xfilt; xfilt = &xf;
    yf = *yfilt; yfilt = &yf;
    if (xsupp>=0.) xfilt->supp = xsupp;
    if (xsupp>=0. && ysupp<0.) ysupp = xsupp;
    if (ysupp>=0.) yfilt->supp = ysupp;
    if (xblur>=0.) xfilt->blur = xblur;
    if (xblur>=0. && yblur<0.) yblur = xblur;
    if (yblur>=0.) yfilt->blur = yblur;

    if (!ywindowname) ywindowname = xwindowname;
    if (xwindowname || xfilt->windowme) {
	if (!xwindowname) xwindowname = WINDOW_DEFAULT;
	xfilt = filt_window(xfilt, xwindowname);
    }
    if (ywindowname || yfilt->windowme) {
	if (!ywindowname) ywindowname = WINDOW_DEFAULT;
	yfilt = filt_window(yfilt, ywindowname);
    }

    if (xfilt->printproc) {
	printf("xfilt: ");
	filt_print_client(xfilt);
    }
    if (yfilt->printproc) {
	printf("yfilt: ");
	filt_print_client(yfilt);
    }

    if (m.sx==0.) zoom_opt(apic, &a, bpic, &b, xfilt, yfilt, square, intscale);
    else   zoom_continuous(apic, &a, bpic, &b, &m, xfilt, yfilt);

    pic_close(apic);
    if (bpic!=apic) pic_close(bpic);
}

ok(enough, option)
int enough;
char *option;
{
    if (!enough) {
	fprintf(stderr, "insufficient args to %s\n", option);
	exit(1);
    }
    return 1;
}

/* atof_check: ascii to float conversion with checking */

double atof_check(str)
char *str;
{
    char *s;

    for (s=str; *s; s++)
	if (strchr("0123456789.+-eE", *s) == NULL) {
	    fprintf(stderr, "expected numeric argument, not %s\n", str);
	    exit(1);
	}
    return atof(str);
}
