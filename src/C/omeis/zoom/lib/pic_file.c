static char rcsid[] = "$Header$";

#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <simple.h>
#include "pic.h"

typedef enum {PIC_DUNNO, PIC_SHORT, PIC_LONG} Magic_type;
typedef enum {PIC_NA, PIC_LITTLE_ENDIAN, PIC_BIG_ENDIAN} Magic_byteorder;

#ifdef vax
#   define MACHINE_BYTEORDER LITTLE_ENDIAN
#else
#   define MACHINE_BYTEORDER BIG_ENDIAN
#endif

typedef struct {
    char *dev;			/* device name */
    char *suffix;		/* file suffix */
    long magic;			/* magic number */
    Magic_type type;		/* type of magic number (DUNNO|SHORT|LONG) */
    Magic_byteorder byteorder;	/* NA, LITTLE_ENDIAN, or BIG_ENDIAN */
    int (*recogproc)();		/* procedure to recognize, if needed */
} Dev_info;

static Dev_info dev[] = {
 /*  DEV      SUFFIX	MAGIC#		TYPE	BYTEORDER	RECOGPROC */

    "jpeg",    "jpg",   0,          PIC_DUNNO,  PIC_NA,              0,
    "jpeg",    "jpeg",  0,          PIC_DUNNO,  PIC_NA,              0,
    "jpeg",    "pjpg",  0,          PIC_DUNNO,  PIC_NA,              0,
    "jpeg",    "pjpeg", 0,          PIC_DUNNO,  PIC_NA,              0,
    "png",     "png",   0,          PIC_DUNNO,  PIC_NA,              0,
    "tiff",    "tif",   0,          PIC_DUNNO,  PIC_NA,              0,
    "tiff",    "tiff",  0,          PIC_DUNNO,  PIC_NA,              0,
    "omeis",   "",      0,          PIC_DUNNO,  PIC_NA,              0,
};
#define NDEV (sizeof dev / sizeof dev[0])

/*
 * pic_file_dev: given file name, try to determine its device type.
 * First examine the file (if it exists);
 * then try special type-specific recognizers,
 * if those fail look at file suffix.
 * Returns 0 if unrecognized.
 */

char *pic_file_dev(char *file)
{
    char *suffix;
    union {
	unsigned short s;
	long l;
    } u, v;
    Dev_info *d;
    FILE *fp;
    struct stat sb;

    /* first try examining the file */
    if ((fp = fopen(file, "r")) != NULL && fstat(fileno(fp), &sb) == 0 &&
	(sb.st_mode&S_IFMT) == S_IFREG) {
	    if (fread(&u, sizeof u, 1, fp) != 1)
		u.l = 0;			/* no magic number */
	    fclose(fp);
	    for (d=dev; d<dev+NDEV; d++) {
		if (d->byteorder != PIC_NA) {	/* check file's magic number */
		    if (d->type == PIC_SHORT) {	/* short magic number */
			v.s = u.s;
			/* if file byte order diff. from machine's then swap: */
			if (d->byteorder != MACHINE_BYTEORDER)
			    swap_short(&v.s);
			if (v.s==d->magic) return d->dev;
		    }
		    else {			/* long magic number */
			v.l = u.l;
			/* if file byte order diff. from machine's then swap: */
			if (d->byteorder != MACHINE_BYTEORDER)
			    swap_long(&v.l);
			if (v.l==d->magic) return d->dev;
		    }
		}
	    }
    }
    
    /* if magic number didn't identify, try type-specific recognizers: */
    for (d=dev; d<dev+NDEV; d++)
	if (d->recogproc)		/* call device's recognition proc */
	    if ((*d->recogproc)(file, d)) return d->dev;

    /* if we couldn't recognize by file contents, try file name */
    suffix = strrchr(file, '.');
    if (suffix) suffix++;
    else {
	suffix = strrchr(file, '/');
	suffix = suffix ? suffix+1 : file;
    }
    for (d=dev; d<dev+NDEV; d++)
	if (str_eq(d->suffix, suffix)) return d->dev;

    /* else failure */
    return 0;
}
