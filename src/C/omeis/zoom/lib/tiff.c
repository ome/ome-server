#include <stdlib.h>
#include <errno.h>
#include <simple.h>
#include <pic.h>
#include <string.h>
#include <tiffio.h>

struct tagPicTiff {
  char name[256];
  FILE *stream;
  int read_not_write;
  int format;
  int scanline;
  int width;
  int height;
  int num_channels;
  tsize_t row_stride;
  int rows_per_strip;
  unsigned char *row;
  void *tiffBuf;
  char buf_mode;
  tsize_t buf_size;
  toff_t buf_off;
  TIFF *tiff;
};
typedef struct tagPicTiff PicTiff;


static void *pictiff_open(const char *filename, const char *mode);
static void *pictiff_open_stream (FILE *stream, const char *filename,  const char *mode);
static void pictiff_close(void *p);
static char *pictiff_get_name(void *p);
static void pictiff_clear(void *vp, Pixel1 pv);
static void pictiff_clear_rgba(void *vp, Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a);
static void pictiff_set_nchan(void *vp, int nchan);
static void pictiff_set_box(void *vp, int ox, int oy, int dx, int dy);
static void pictiff_write_pixel(void *vp, int x, int y, Pixel1 pv);
static void pictiff_write_pixel_rgba(void *vp, int x, int y,Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a);
static void pictiff_write_row(void *vp, int y, int x0, int nx, const Pixel1 *buf);
static void pictiff_write_row_rgba(void *vp, int y, int x0, int nx, const Pixel1_rgba *buf);
static int pictiff_get_nchan(void *vp);
static void pictiff_get_box(void *vp, int *ox, int *oy, int *dx, int *dy);
static Pixel1 pictiff_read_pixel(void *vp, int x, int y);
static void pictiff_read_pixel_rgba(void *vp, int x, int y, Pixel1_rgba *pv);
static void pictiff_read_row(void *vp, int y, int x0, int nx, Pixel1 *buf);
static void pictiff_read_row_rgba(void *vp, int y, int x0, int nx, Pixel1_rgba *buf);

static toff_t mfs_lseek (thandle_t h, toff_t offset, int whence);
static tsize_t mfs_read  (thandle_t h, tdata_t buf, tsize_t size);
static tsize_t  mfs_write (thandle_t h, tdata_t buf, tsize_t size);
static toff_t mfs_size  (thandle_t h);
static int mfs_map   (thandle_t h, tdata_t *addr, toff_t *len);
static void mfs_unmap (thandle_t h, tdata_t data, toff_t size);
static int mfs_close (thandle_t h);

static int extend_mem_file (thandle_t h, tsize_t size);



static void *
pictiff_open(const char *filename, const char *mode)
{
  PicTiff *tiff = NULL;
  TIFF *try = NULL;

  /* TIFF doesn't support streaming I/O */
  if (('r' == mode[0] && str_eq(filename, "-.tiff")) ||
      ('w' == mode[0] && str_eq(filename, "-.tiff")))
    try = NULL;
  else
    try = TIFFOpen(filename, mode);
  
  if (try) {
    tiff = (PicTiff *) malloc (sizeof(PicTiff));
    if (!tiff) return (NULL);
    memset(tiff, 0, sizeof(PicTiff));
    tiff->tiff = try;
    strncpy (tiff->name,filename,255);
    if ('r' == mode[0]) {
      uint32 width = 0;
      uint32 height = 0;
      uint16 chans = 0;

      tiff->read_not_write = 1;
      /* read TIF header and determine image size */
      tiff->row_stride = TIFFScanlineSize(tiff->tiff);
      tiff->row = (unsigned char *) _TIFFmalloc(tiff->row_stride);

      TIFFGetField(tiff->tiff, TIFFTAG_IMAGEWIDTH, &width);
      tiff->width = width;
      TIFFGetField(tiff->tiff, TIFFTAG_IMAGELENGTH, &height);
      tiff->height = height;
      TIFFGetField(tiff->tiff, TIFFTAG_SAMPLESPERPIXEL, &chans);
      tiff->num_channels = chans;
    } else {
      tiff->read_not_write = 0;
      /* initialize header for writing */
    }
  }

  return tiff;
}


static void *
pictiff_open_stream (FILE *stream, const char *filename,  const char *mode)
{
	PicTiff *tiff = NULL;
	TIFF *try = NULL;
	char buf_mode;
	
	if (!stream) return (NULL);
	if (mode[0] == 'r') {
		fprintf (stderr,"TIFF streams are supported for writing only\n");
		return (NULL);
	}
	else if (mode[0] == 'w') buf_mode = 'w';
	else if (mode[0] == 'a') buf_mode = 'a';
	else return (NULL);
	tiff = (PicTiff *) malloc (sizeof(PicTiff));
	if (!tiff) return (NULL);
	memset(tiff, 0, sizeof(PicTiff));
	tiff->tiffBuf = malloc(0);
	tiff->buf_size = 0;
	tiff->buf_off = 0;
	tiff->buf_mode = buf_mode;
	tiff->stream=stream;

	try = TIFFClientOpen(filename, mode, (thandle_t) tiff,
		mfs_read, mfs_write, mfs_lseek, mfs_close, mfs_size, mfs_map, mfs_unmap);

  
	if (try) {
		tiff->tiff = try;
		strncpy (tiff->name,filename,255);
		
		if ('r' == mode[0]) {
			uint32 width = 0;
			uint32 height = 0;
			uint16 chans = 0;
			
			tiff->read_not_write = 1;
			/* read TIF header and determine image size */
			tiff->row_stride = TIFFScanlineSize(tiff->tiff);
			tiff->row = (unsigned char *) _TIFFmalloc(tiff->row_stride);
			
			TIFFGetField(tiff->tiff, TIFFTAG_IMAGEWIDTH, &width);
			tiff->width = width;
			TIFFGetField(tiff->tiff, TIFFTAG_IMAGELENGTH, &height);
			tiff->height = height;
			TIFFGetField(tiff->tiff, TIFFTAG_SAMPLESPERPIXEL, &chans);
			tiff->num_channels = chans;
		} else {
			tiff->read_not_write = 0;
			/* initialize header for writing */
		}
	} else {
		free (tiff->tiffBuf);
		free (tiff);
		tiff = NULL;
	}

  return tiff;
}

static void
pictiff_close(void *p)
{
  PicTiff *tiff = (PicTiff *) p;

  TIFFClose(tiff->tiff);
  free(tiff);
}

static char *
pictiff_get_name(void *p)
{
  PicTiff *tiff = (PicTiff *) p;
  return tiff->name;
}

static void
pictiff_clear(void *vp, Pixel1 pv)
{
  /* hmm... ignore? */
}

static void
pictiff_clear_rgba(void *vp, Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a)
{
  /* hmm... ignore? */
}

static void
pictiff_set_nchan(void *vp, int nchan)
{
  PicTiff *tiff = (PicTiff *) vp;
  
  if (! tiff->read_not_write) {
    tiff->num_channels = nchan;
  }
}

static void
pictiff_set_box(void *vp, int ox, int oy, int dx, int dy)
{
  PicTiff *tiff = (PicTiff *) vp;
  if (! tiff->read_not_write) {
    tiff->width = ox + dx;
    tiff->height = oy + dy;
  }    
}

static void
pictiff_write_pixel(void *vp, int x, int y, Pixel1 pv)
{
  fprintf(stderr, "?pictiff_write_pixel\n");
  /* output scanlines until we reach scanline y */
  /* set pixel x of scanline to pv */
}

static void
pictiff_write_pixel_rgba(void *vp, int x, int y,
		     Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a)
{
  fprintf(stderr, "?pictiff_write_pixel_rgba\n");
}

#define WRITE_INIT(tiff_) ((tiff_)->scanline || write_init(tiff_))
static int
write_init(PicTiff *tiff)
{
  /* prepare TIF header for writing */
  TIFFSetField(tiff->tiff, TIFFTAG_IMAGEWIDTH, tiff->width);
  TIFFSetField(tiff->tiff, TIFFTAG_IMAGELENGTH, tiff->height);
  if (tiff->num_channels == 1)
    TIFFSetField(tiff->tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK );
  else
    TIFFSetField(tiff->tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_RGB);
  TIFFSetField(tiff->tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
  TIFFSetField(tiff->tiff, TIFFTAG_SAMPLESPERPIXEL, tiff->num_channels);
  TIFFSetField(tiff->tiff, TIFFTAG_BITSPERSAMPLE, 8);
  TIFFSetField(tiff->tiff, TIFFTAG_ROWSPERSTRIP,
	       TIFFDefaultStripSize(tiff->tiff, 0));
#ifdef USE_TIFF_LZW
  if (! TIFFSetField(tiff->tiff, TIFFTAG_COMPRESSION, COMPRESSION_LZW) )
#endif
    TIFFSetField(tiff->tiff, TIFFTAG_COMPRESSION, COMPRESSION_NONE);
  TIFFSetField(tiff->tiff, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);

  tiff->row_stride = TIFFScanlineSize(tiff->tiff);
  tiff->row = (unsigned char *) _TIFFmalloc(tiff->row_stride);

  return 1;
}

static void
pictiff_write_scanline(PicTiff *tiff)
{
  TIFFWriteScanline(tiff->tiff, tiff->row, tiff->scanline, 0);
}

static void
pictiff_read_scanline(PicTiff *tiff)
{
  TIFFReadScanline(tiff->tiff, tiff->row, tiff->scanline, 0);
}

static void
seek_row_write(PicTiff *tiff, int y)
{
  while (tiff->scanline < y) {
    pictiff_write_scanline(tiff);
    tiff->scanline++;
  }
}

static void
pictiff_write_row(void *vp, int y, int x0, int nx, const Pixel1 *buf)
{
  PicTiff *tiff = (PicTiff *) vp;

  if (! tiff->read_not_write &&
      1 == tiff->num_channels &&
      WRITE_INIT(tiff)) {
    int i;

    seek_row_write(tiff, y);
    memset(tiff->row, 0, tiff->row_stride);
    for (i = 0; i < nx; i++)
      tiff->row[x0+i] = buf[i];
    pictiff_write_scanline(tiff);
    tiff->scanline++;
  }
}

static void
pictiff_write_row_rgba(void *vp, int y, int x0, int nx, const Pixel1_rgba *buf)
{
  PicTiff *tiff = (PicTiff *) vp;

  if (! tiff->read_not_write &&
      3 == tiff->num_channels &&
      WRITE_INIT(tiff)) {
    int i, j;

    seek_row_write(tiff, y);
    memset(tiff->row, 0, tiff->row_stride);
    for (i = 0, j = x0; i < nx; i++, j += 3) {
      tiff->row[j+0] = buf[i].r;
      tiff->row[j+1] = buf[i].g;
      tiff->row[j+2] = buf[i].b;
    }
    pictiff_write_scanline(tiff);
    tiff->scanline++;
  }
}

static int
pictiff_get_nchan(void *vp)
{
  PicTiff *tiff = (PicTiff *) vp;

  return tiff->num_channels;
}

static void
pictiff_get_box(void *vp, int *ox, int *oy, int *dx, int *dy)
{
  PicTiff *tiff = (PicTiff *) vp;

  if (tiff->read_not_write || tiff->row) {
    *ox = 0;
    *oy = 0;
    *dx = tiff->width;
    *dy = tiff->height;
  } else {
    *ox = PIXEL_UNDEFINED;
    *oy = PIXEL_UNDEFINED;
    *dx = PIXEL_UNDEFINED;
    *dy = PIXEL_UNDEFINED;
  }    
}

static Pixel1
pictiff_read_pixel(void *vp, int x, int y)
{
  fprintf(stderr, "?pictiff_read_pixel\n");
  return 0;
}

static void
pictiff_read_pixel_rgba(void *vp, int x, int y, Pixel1_rgba *pv)
{
  fprintf(stderr, "?pictiff_read_pixel_rgba\n");
}

static void
seek_row_read(PicTiff *tiff, int y)
{
  while (tiff->scanline <= y) {
    pictiff_read_scanline(tiff);
    tiff->scanline++;
  }
}

static void
pictiff_read_row(void *vp, int y, int x0, int nx, Pixel1 *buf)
{
  PicTiff *tiff = (PicTiff *) vp;
  
  if (tiff->read_not_write && 1 == tiff->num_channels) {
    int i;

    seek_row_read(tiff, y);
    for (i = 0; i < nx; i++)
      buf[i] = tiff->row[x0+i];
  }
}

static void
pictiff_read_row_rgba(void *vp, int y, int x0, int nx, Pixel1_rgba *buf)
{
  PicTiff *tiff = (PicTiff *) vp;

  if (tiff->read_not_write && 3 == tiff->num_channels) {
    int i;

    seek_row_read(tiff, y);
    for (i = 0; i < nx; i++) {
      buf[i].r = tiff->row[(x0+i)*3+0];
      buf[i].g = tiff->row[(x0+i)*3+1];
      buf[i].b = tiff->row[(x0+i)*3+2];
    }
  }
}

static Pic_procs
pictiff_procs = {
	pictiff_open,
	pictiff_open_stream,
	pictiff_close,
	pictiff_get_name,
	
	pictiff_clear,
	pictiff_clear_rgba,
	
	pictiff_set_nchan,
	pictiff_set_box,
	
	pictiff_write_pixel,
	pictiff_write_pixel_rgba,
	pictiff_write_row,
	pictiff_write_row_rgba,
	
	pictiff_get_nchan,
	pictiff_get_box,
	pictiff_read_pixel,
	pictiff_read_pixel_rgba,
	pictiff_read_row,
	pictiff_read_row_rgba,
};

Pic pic_tiff =
{
  "tiff", &pictiff_procs
};






/*
--------------------------------------------------------------------------------
-	Module		:	mem_file.c
-	Description	:	A general purpose library for manipulating a memory area
-                   as if it were a file.
-                   mfs_ stands for memory file system.
-	Author		:	Mike Johnson - Banctec AB 03/07/96
-					
--------------------------------------------------------------------------------
*/

/* 

Copyright (c) 1996 Mike Johnson
Copyright (c) 1996 BancTec AB

Permission to use, copy, modify, distribute, and sell this software
for any purpose is hereby granted without fee, provided
that (i) the above copyright notices and this permission notice appear in
all copies of the software and related documentation, and (ii) the names of
Mike Johnson and BancTec may not be used in any advertising or
publicity relating to the software.

THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, 
EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY 
WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  

IN NO EVENT SHALL MIKE JOHNSON OR BANCTEC BE LIABLE FOR
ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF 
LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE 
OF THIS SOFTWARE.

*/

/*
--------------------------------------------------------------------------------
-	Function	:	mfs_lseek ()
-
-	Arguments	:	File descriptor, offset, whence
-
-	Returns		:	as per man lseek (2)
-
-	Description	:	Does the same as lseek (2) except on a memory based file.
-					Note: the memory area will be extended if the caller
-					attempts to seek past the current end of file (memory).
-					
--------------------------------------------------------------------------------
*/

static toff_t mfs_lseek (thandle_t h, toff_t offset, int whence)
{
	PicTiff *tiff = (PicTiff *) h;
	toff_t ret;
	toff_t test_off;


	if (! tiff->tiffBuf)	/* Not open */
	{
		ret = -1;
		errno = EBADF;
	}
	else if (offset < 0 && whence == SEEK_SET)
	{
		ret = -1;
		errno = EINVAL;
	}
	else
	{
		switch (whence)
		{
			case SEEK_SET:
				if (offset > tiff->buf_size)
					extend_mem_file (h, offset);
				tiff->buf_off = offset;
				ret = offset;
				break;

			case SEEK_CUR:
				test_off = tiff->buf_off + offset;

				if (test_off < 0)
				{
					ret = -1;
					errno = EINVAL;
				}
				else
				{
					if (test_off > tiff->buf_size)
						extend_mem_file (h, test_off);
					tiff->buf_off = test_off;
					ret = test_off;
				}
				break;

			case SEEK_END:
				test_off = tiff->buf_size + offset;
				if (test_off < 0)
				{
					ret = -1;
					errno = EINVAL;
				}
				else
				{
					if (test_off > tiff->buf_size)
						extend_mem_file (h, test_off);
					tiff->buf_off = test_off;
					ret = test_off;
				}
				break;

			default:
				errno = EINVAL;
				ret = -1;
				break;
		}
	}

	return (ret);
}	


/*
--------------------------------------------------------------------------------
-	Function	:	mfs_read ()
-
-	Arguments	:	File descriptor, buffer, size
-
-	Returns		:	as per man read (2)
-
-	Description	:	Does the same as read (2) except on a memory based file.
-					Note: An attempt to read past the end of memory currently
-					allocated to the file will return 0 (End Of File)
-					
--------------------------------------------------------------------------------
*/

static tsize_t mfs_read  (thandle_t h, tdata_t buf, tsize_t size)
{
	PicTiff *tiff = (PicTiff *) h;
	tsize_t ret;

	if (!tiff->tiffBuf || ! tiff->buf_mode != 'r')
	{
		/* File is either not open, or not opened for read */

		ret = -1;
		errno = EBADF;
	}
	else if (tiff->buf_off + size > tiff->buf_size)
	{
		ret = 0;		/* EOF */
	}
	else
	{
		memcpy ((void *)buf, (void *) (tiff->tiffBuf + tiff->buf_off), size);
		tiff->buf_off = tiff->buf_off + size;
		ret = size;
	}

	return (ret);
}

/*
--------------------------------------------------------------------------------
-	Function	:	mfs_write ()
-
-	Arguments	:	File descriptor, buffer, size
-
-	Returns		:	as per man write (2)
-
-	Description	:	Does the same as write (2) except on a memory based file.
-					Note: the memory area will be extended if the caller
-					attempts to write past the current end of file (memory).
-					
--------------------------------------------------------------------------------
*/

static tsize_t mfs_write (thandle_t h, tdata_t buf, tsize_t size)
{
	PicTiff *tiff = (PicTiff *) h;
	tsize_t ret;
	if (!tiff->tiffBuf || ! tiff->buf_mode == 'r')
	{
		/* Either the file is not open or it is opened for reading only */

		ret = -1;
		errno = EBADF;
	}
	else if (tiff->buf_mode == 'w')
	{
		/* Write */

		if (tiff->buf_off + size > tiff->buf_size)
		{    	
			extend_mem_file (h, tiff->buf_off + size);
		}

		memcpy (tiff->tiffBuf + tiff->buf_off, (void *)buf, (size_t)size);
		tiff->buf_off = tiff->buf_off + size;

		ret = size;
	}
	else
	{
		/* Append */

		if (tiff->buf_off != tiff->buf_size)
			tiff->buf_off = tiff->buf_size;

		extend_mem_file (h, tiff->buf_off + size);

		memcpy (tiff->tiffBuf + tiff->buf_off, (void *)buf, (size_t)size);
		tiff->buf_off = tiff->buf_off + size;

		ret = size;
	}

	return (ret);
}

/*
--------------------------------------------------------------------------------
-	Function	:	mfs_size ()
-
-	Arguments	:	File descriptor
-
-	Returns		:	integer file size
-
-	Description	:	This function returns the current size of the file in bytes.
-					
--------------------------------------------------------------------------------
*/

static toff_t mfs_size  (thandle_t h)
{
	PicTiff *tiff = (PicTiff *) h;
	toff_t ret;

	if (! tiff->tiffBuf)	/* Not open */
	{
		ret = -1;
		errno = EBADF;
	}
	else
		ret = tiff->buf_size;

	return (ret);
}

/*
--------------------------------------------------------------------------------
-	Function	:	mfs_map ()
-
-	Arguments	:	File descriptor, ptr to address, ptr to length
-
-	Returns		:	Map status (succeeded or otherwise)
-
-	Description	:	This function tells the client where the file is mapped
-					in memory and what size the mapped area is. It is provided
-					to satisfy the MapProc function in libtiff. It pretends
-					that the file has been mmap (2)ped.
-					
--------------------------------------------------------------------------------
*/

static int mfs_map   (thandle_t h, tdata_t *addr, toff_t *len)
{
	PicTiff *tiff = (PicTiff *) h;
	int ret;

	if (! tiff->tiffBuf)	/* Not open */
	{
		ret = -1;
		errno = EBADF;
	}
	else
	{
		*addr = tiff->tiffBuf;
		*len = tiff->buf_size;
		ret = 0;
	}

	return (ret);
}

/*
--------------------------------------------------------------------------------
-	Function	:	mfs_unmap ()
-
-	Arguments	:	File descriptor
-
-	Returns		:	UnMap status (succeeded or otherwise)
-
-	Description	:	This function does nothing as the file is always
-                   in memory.
-					
--------------------------------------------------------------------------------
*/

static void mfs_unmap (thandle_t h, tdata_t data, toff_t size)
{
	return;
}

/*
--------------------------------------------------------------------------------
-	Function	:	mfs_close ()
-
-	Arguments	:	File descriptor
-
-	Returns		:	close status (succeeded or otherwise)
-
-	Description	:	Close the open memory file. (Make fd available again.)
-					
--------------------------------------------------------------------------------
*/

static int mfs_close (thandle_t h)
{
	PicTiff *tiff = (PicTiff *) h;
	int ret;

	if (! tiff->tiffBuf)	/* Not open */
	{
		ret = -1;
		errno = EBADF;
	}
	else
	{
		fwrite (tiff->tiffBuf,tiff->buf_size,1,tiff->stream);
		fflush (tiff->stream);
		free (tiff->tiffBuf);
		tiff->tiffBuf = NULL;
		ret = 0;
	}

	return (ret);
}

/*
--------------------------------------------------------------------------------
-	Function	:	extend_mem_file ()
-
-	Arguments	:	File descriptor, length to extend to.
-
-	Returns		:	0 - All OK, -1 - realloc () failed.
-
-	Description	:	Increase the amount of memory allocated to a file.
-					
--------------------------------------------------------------------------------
*/

static int extend_mem_file (thandle_t h, tsize_t size)
{
	PicTiff *tiff = (PicTiff *) h;

	void *new_mem;
	int ret;

	if ((new_mem = (void *)realloc (tiff->tiffBuf, (size_t)size)) == NULL) {
		ret = -1;
	} else {
		tiff->tiffBuf = new_mem;
		tiff->buf_size = size;
		ret = 0;
	}

	return (ret);
}
