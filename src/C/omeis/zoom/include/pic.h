/*
 * pic.h: definitions for device-independent picture package
 *
 * Paul Heckbert, ph@cs.cmu.edu	Sept 1988
 *
 * Copyright (c) 1989  Paul S. Heckbert
 * This source may be used for peaceful, nonprofit purposes only, unless
 * under licence from the author. This notice should remain in the source.
 */

#ifndef PIC_HDR
#define PIC_HDR

/* $Header$ */
#include <pixel.h>
#include <window.h>
#include <stdio.h>

typedef struct {		/* PICTURE PROCEDURE POINTERS */
    void *(*open)(const char *filename, const char *mode);
    void *(*open_stream)(FILE *stream, const char *filename,  const char *mode);
    void (*close)(void *p);

    char *(*get_name)(void *p);
    void (*clear)(void *vp, Pixel1 pv);
    void (*clear_rgba)(void *vp, Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a);

    void (*set_nchan)(void *vp, int nchan);
    void (*set_box)(void *vp, int ox, int oy, int dx, int dy);
    void (*write_pixel)(void *vp, int x, int y, Pixel1 pv);
    void (*write_pixel_rgba)(void *vp, int x, int y,Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a);
    void (*write_row)(void *vp, int y, int x0, int nx, const Pixel1 *buf);
    void (*write_row_rgba)(void *vp, int y, int x0, int nx, const Pixel1_rgba *buf);

    int (*get_nchan)(void *vp);
    void (*get_box)(void *vp, int *ox, int *oy, int *dx, int *dy);
    Pixel1 (*read_pixel)(void *vp, int x, int y);
    void (*read_pixel_rgba)(void *vp, int x, int y, Pixel1_rgba *pv);
    void (*read_row)(void *vp, int y, int x0, int nx, Pixel1 *buf);
    void (*read_row_rgba)(void *vp, int y, int x0, int nx, Pixel1_rgba *buf);
} Pic_procs;

typedef struct {	/* PICTURE INFO */
    char *dev;		/* device/filetype name */
    Pic_procs *procs;	/* structure of generic procedure pointers */
    char *data;		/* device-dependent data (usually ptr to structure) */
} Pic;

#define PIC_LISTMAX 20
extern Pic *pic_list[PIC_LISTMAX];	/* list of known picture devices */
extern int pic_npic;			/* #pics in pic_list, set by pic_init */

#define PIC_UNDEFINED PIXEL_UNDEFINED	/* used for unknown nchan */

Pic *pic_open(char *file, char *mode);
Pic *pic_open_dev(char *dev, char *name, char *mode);
Pic *pic_open_stream (char *dev, FILE *stream, char *name, char *mode);
void pic_close(Pic *p);

#define     pic_get_name(p) \
    (*(p)->procs->get_name)((p)->data)
#define     pic_clear(p, pv) \
    (*(p)->procs->clear)((p)->data, pv)
#define     pic_clear_rgba(p, r, g, b, a) \
    (*(p)->procs->clear_rgba)((p)->data, r, g, b, a)

#define     pic_set_nchan(p, nchan) \
    (*(p)->procs->set_nchan)((p)->data, nchan)
#define     pic_set_box(p, ox, oy, dx, dy) \
    (*(p)->procs->set_box)((p)->data, ox, oy, dx, dy)

#define     pic_write_pixel(p, x, y, pv) \
    (*(p)->procs->write_pixel)((p)->data, x, y, pv)
#define     pic_write_pixel_rgba(p, x, y, r, g, b, a) \
    (*(p)->procs->write_pixel_rgba)((p)->data, x, y, r, g, b, a)
#define     pic_write_row(p, y, x0, nx, buf) \
    (*(p)->procs->write_row)((p)->data, y, x0, nx, buf)
#define     pic_write_row_rgba(p, y, x0, nx, buf) \
    (*(p)->procs->write_row_rgba)((p)->data, y, x0, nx, buf)

#define     pic_get_nchan(p) \
    (*(p)->procs->get_nchan)((p)->data)
#define     pic_get_box(p, ox, oy, dx, dy) \
    (*(p)->procs->get_box)((p)->data, ox, oy, dx, dy)

#define     pic_read_pixel(p, x, y) \
    (*(p)->procs->read_pixel)((p)->data, x, y)
#define     pic_read_pixel_rgba(p, x, y, pv) \
    (*(p)->procs->read_pixel_rgba)((p)->data, x, y, pv)
#define     pic_read_row(p, y, x0, nx, buf) \
    (*(p)->procs->read_row)((p)->data, y, x0, nx, buf)
#define     pic_read_row_rgba(p, y, x0, nx, buf) \
    (*(p)->procs->read_row_rgba)((p)->data, y, x0, nx, buf)


void	pic_init(void);
void	pic_catalog(void);
#define pic_get_dev(p) (p)->dev
Pic *pic_load(char *name1, char *name2);
void pic_save(Pic *p, char *name);
void pic_copy(register Pic *p, register Pic *q);
void pic_set_window(Pic *p, Window *win);
void pic_write_block(Pic *p, int x0, int y0, int nx, int ny, Pixel1 *buf);
void pic_write_block_rgba(Pic *p, int x0, int y0, int nx, int ny, Pixel1_rgba *buf);
Window *pic_get_window(Pic *p, Window *win);
void pic_read_block(Pic *p, int x0, int y0, int nx, int ny, Pixel1 *buf);
void pic_read_block_rgba(Pic *p, int x0, int y0, int nx, int ny, Pixel1_rgba *buf);

char *pic_file_dev(char *file);

#endif
