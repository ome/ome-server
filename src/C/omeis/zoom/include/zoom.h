/* $Header$ */

typedef struct {	/* SOURCE TO DEST COORDINATE MAPPING */
    double sx, sy;	/* x and y scales */
    double tx, ty;	/* x and y translations */
    double ux, uy;	/* x and y offset used by MAP, private fields */
} Mapping;
/* see explanation in zoom.c */

void zoom(Pic *apic, Window_box *a, Pic *bpic, Window_box *b, Filt *xfilt, Filt *yfilt);
void zoom_opt(Pic *apic, Window_box *a, Pic *bpic, Window_box *b,
	Filt *xfilt, Filt *yfilt, int square, int intscale);
void zoom_continuous (Pic *apic, Window_box *awin, Pic *bpic, Window_box *bwin,
	Mapping *m, Filt *xfilt, Filt *yfilt);


extern int zoom_debug;
extern int zoom_coerce;	/* simplify filters if possible? */
extern int zoom_xy;	/* filter x before y (1) or vice versa (0)? */
extern int zoom_trimzeros;	/* trim zeros from filter weight table? */
