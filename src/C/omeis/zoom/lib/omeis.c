#include <simple.h>
#include <pic.h>
#include <string.h>
#include "../../composite.h"

/*
 Implementation notes:
 This is a bit of spackle to make omeis CompositeSpec objects work with the zoom program
*/

static void *
picomeis_open(const char *vp, const char *mode)
{
CompositeSpec *composite = (CompositeSpec *)vp;
	if (composite &&
		composite->thePixels &&
		composite->thePixels->head &&
		composite->theZ < composite->thePixels->head->dz &&
		composite->theT < composite->thePixels->head->dt
		) return ((void *)vp);
	else {
		fprintf(stderr, "picomeis_open(): composite paramter is not well formed.\n");
		return (NULL);
	}
}

static void *
picomeis_open_stream(FILE *stream, const char *vp,  const char *mode)
{
	fprintf(stderr, "picomeis_open_stream() is not implemented.\n");
	return NULL;
}

static void
picomeis_close(void *p)
{
/*
  open didn't allocate this.
  free(p);
*/
}

static char *
picomeis_get_name(void *p)
{
	return ("omeis-Image");
}

static void
picomeis_clear(void *vp, Pixel1 pv)
{
  /* hmm... ignore? */
}

static void
picomeis_clear_rgba(void *vp, Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a)
{
  /* hmm... ignore? */
}

static void
picomeis_set_nchan(void *vp, int nchan)
{
}

static void
picomeis_set_box(void *vp, int ox, int oy, int dx, int dy)
{
}

static void
picomeis_write_pixel(void *vp, int x, int y, Pixel1 pv)
{
	fprintf(stderr, "picomeis_write_pixel() is not implemented.\n");
}

static void
picomeis_write_pixel_rgba(void *vp, int x, int y,
			 Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a)
{
	fprintf(stderr, "picomeis_write_pixel_rgba() is not implemented.\n");
}


static void
picomeis_write_row(void *vp, int y, int x0, int nx, const Pixel1 *buf)
{
	fprintf(stderr, "picomeis_write_row() is not implemented.\n");
}

static void
picomeis_write_row_rgba(void *vp, int y, int x0, int nx, const Pixel1_rgba *buf)
{
	fprintf(stderr, "picomeis_write_row_rgba() is not implemented.\n");
}

static int
picomeis_get_nchan(void *vp)
{
CompositeSpec *theOMEisPic = (CompositeSpec *)vp;
	if (theOMEisPic->isRGB) return (3);
	else return (1);
}

static void
picomeis_get_box(void *vp, int *ox, int *oy, int *dx, int *dy)
{
CompositeSpec *theOMEisPic = (CompositeSpec *)vp;

	*ox = 0;
	*oy = 0;
	*dx = theOMEisPic->thePixels->head->dx;
	*dy = theOMEisPic->thePixels->head->dy;
}

static Pixel1
picomeis_read_pixel(void *vp, int x, int y)
{
  fprintf(stderr, "?picomeis_read_pixel\n");
  return 0;
}

static void
picomeis_read_pixel_rgba(void *vp, int x, int y, Pixel1_rgba *pv)
{
	fprintf(stderr, "picomeis_read_pixel_rgba() is not implemented.\n");
}


static void
picomeis_read_row(void *vp, int y, int x0, int nx, Pixel1 *buf)
{
CompositeSpec *theOMEisPic = (CompositeSpec *)vp;
PixelsRep *thePixels = theOMEisPic->thePixels;
int theZ = theOMEisPic->theZ;
int theT = theOMEisPic->theZ;
channelSpecType *theCh = &(theOMEisPic->RGBAGr[4]);
size_t offset;

		offset = GetOffset (thePixels, x0, y, theZ, theCh->channel, theT);
		ScalePixels (thePixels, offset, nx, buf, 1, theCh );
}

static void
picomeis_read_row_rgba(void *vp, int y, int x0, int nx, Pixel1_rgba *buf)
{
CompositeSpec *theOMEisPic = (CompositeSpec *)vp;
PixelsRep *thePixels = theOMEisPic->thePixels;
int theZ = theOMEisPic->theZ;
int theT = theOMEisPic->theZ;
channelSpecType *theChR = &(theOMEisPic->RGBAGr[0]);
channelSpecType *theChG = &(theOMEisPic->RGBAGr[1]);
channelSpecType *theChB = &(theOMEisPic->RGBAGr[2]);
size_t offset;
unsigned char *chBuf = (unsigned char *)buf;

		offset = GetOffset (thePixels, x0, y, theZ, theChR->channel, theT);
		ScalePixels (thePixels, offset, nx, chBuf,   4, theChR );

		offset = GetOffset (thePixels, x0, y, theZ, theChG->channel, theT);
		ScalePixels (thePixels, offset, nx, chBuf+1, 4, theChG );

		offset = GetOffset (thePixels, x0, y, theZ, theChB->channel, theT);
		ScalePixels (thePixels, offset, nx, chBuf+2, 4, theChB );
}


static int
picomeis_next_pic(void *vp)
{
  return 0;
}

static Pic_procs
picomeis_procs = {
  picomeis_open,
  picomeis_open_stream,
  picomeis_close,
  picomeis_get_name,
  picomeis_clear,
  picomeis_clear_rgba,
  picomeis_set_nchan,
  picomeis_set_box,
  picomeis_write_pixel,
  picomeis_write_pixel_rgba,
  picomeis_write_row,
  picomeis_write_row_rgba,
  picomeis_get_nchan,
  picomeis_get_box,
  picomeis_read_pixel,
  picomeis_read_pixel_rgba,
  picomeis_read_row,
  picomeis_read_row_rgba
};

Pic pic_omeis =
{
  "omeis", &picomeis_procs
};
