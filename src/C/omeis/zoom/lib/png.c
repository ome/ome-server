#include <stdlib.h>
#include <simple.h>
#include <pic.h>
#include <png.h>

/*------------------------------------------------------------*/
struct tagPicPng {
  char *name;
  FILE *file;
  int read_not_write;
  png_uint_32 width;
  png_uint_32 height;
  int nchan;
  png_structp png_ptr;
  png_infop info_ptr;
  int bit_depth;
  int color_type;
  int interlace_type;
  png_bytep row;
  int scanline;
};
typedef struct tagPicPng PicPng;

/*------------------------------------------------------------*/
static void *
picpng_open(const char *filename, const char *mode)
{
  PicPng *png = NULL;
  FILE *infile;

  if ('r' == mode[0] && str_eq(filename, "-.png"))
    infile = fdopen(dup(fileno(stdin)), "rb");
  else if ('w' == mode[0] && str_eq(filename, "-.png"))
    infile = fdopen(dup(fileno(stdout)), "wb");
  else
    infile = fopen(filename, mode);
  
  if (infile) {
    ALLOC(png, PicPng, 1);
    memset(png, 0, sizeof(PicPng));
    png->file = infile;
    png->name = strdup(filename);
    if ('r' == mode[0])
      png->read_not_write = 1;
    png->png_ptr = (png->read_not_write ?
                    png_create_read_struct : png_create_write_struct)
      (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    assert(png->png_ptr);
    png->info_ptr = png_create_info_struct(png->png_ptr);
    assert(png->info_ptr);
    if (setjmp(png->png_ptr->jmpbuf)) {
      if (png->read_not_write)
        png_destroy_read_struct(&png->png_ptr, &png->info_ptr, NULL);
      else
        png_destroy_write_struct(&png->png_ptr, &png->info_ptr);

      fclose(infile);
      free(png->name);
      free(png);
      return NULL;
    }
    png_init_io(png->png_ptr, png->file);
    if (png->read_not_write) {
      png_read_info(png->png_ptr, png->info_ptr);
      png_get_IHDR(png->png_ptr, png->info_ptr,
                   &png->width, &png->height, &png->bit_depth,
                   &png->color_type, &png->interlace_type, NULL, NULL);
      /* expand palette images to RGB */
      png_set_expand(png->png_ptr);
      png->row = (png_bytep)
        malloc(png_get_rowbytes(png->png_ptr, png->info_ptr));
      
      if (png->color_type & PNG_COLOR_MASK_COLOR)
        png->nchan = 3;
      else
        png->nchan = 1;
    }
  }

  return png;
}


/*------------------------------------------------------------*/
static void *
picpng_open_stream (FILE *infile, const char *filename,  const char *mode)
{
  PicPng *png = NULL;
  
  if (infile) {
    ALLOC(png, PicPng, 1);
    memset(png, 0, sizeof(PicPng));
    png->file = infile;
    ALLOC(png->name, char, strlen (filename)+1);
    strcpy (png->name,filename);
    if ('r' == mode[0])
      png->read_not_write = 1;
    png->png_ptr = (png->read_not_write ?
                    png_create_read_struct : png_create_write_struct)
      (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    assert(png->png_ptr);
    png->info_ptr = png_create_info_struct(png->png_ptr);
    assert(png->info_ptr);
    if (setjmp(png->png_ptr->jmpbuf)) {
      if (png->read_not_write)
        png_destroy_read_struct(&png->png_ptr, &png->info_ptr, NULL);
      else
        png_destroy_write_struct(&png->png_ptr, &png->info_ptr);

      fclose(infile);
      free(png->name);
      free(png);
      return NULL;
    }
    png_init_io(png->png_ptr, png->file);
    if (png->read_not_write) {
      png_read_info(png->png_ptr, png->info_ptr);
      png_get_IHDR(png->png_ptr, png->info_ptr,
                   &png->width, &png->height, &png->bit_depth,
                   &png->color_type, &png->interlace_type, NULL, NULL);
      /* expand palette images to RGB */
      png_set_expand(png->png_ptr);
      png->row = (png_bytep)
        malloc(png_get_rowbytes(png->png_ptr, png->info_ptr));
      
      if (png->color_type & PNG_COLOR_MASK_COLOR)
        png->nchan = 3;
      else
        png->nchan = 1;
    }
  }

  return png;
}

/*------------------------------------------------------------*/
static void
picpng_close(void *p)
{
  PicPng *png = (PicPng *) p;
  png_write_end(png->png_ptr, png->info_ptr);
  assert(png->name);
  free(png->name);
  assert(png->file);
  fclose(png->file);
  free(png->row);
  free(png);
}

/*------------------------------------------------------------*/
static char *
picpng_get_name(void *p)
{
  PicPng *png = (PicPng *) p;
  return png->name;
}

/*------------------------------------------------------------*/
static void
picpng_clear(void *vp, Pixel1 pv)
{
  /* hmm... ignore? */
}

/*------------------------------------------------------------*/
static void
picpng_clear_rgba(void *vp, Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a)
{
  /* hmm... ignore? */
}

/*------------------------------------------------------------*/
static void
picpng_set_nchan(void *vp, int nchan)
{
  PicPng *png = (PicPng *) vp;
  
  png->nchan = nchan;
}

/*------------------------------------------------------------*/
static void
picpng_set_box(void *vp, int ox, int oy, int dx, int dy)
{
  PicPng *png = (PicPng *) vp;
  if (! png->read_not_write) {
    png->width = ox + dx;
    png->height = oy + dy;
  }    
}

/*------------------------------------------------------------*/
static void
picpng_write_pixel(void *vp, int x, int y, Pixel1 pv)
{
  fprintf(stderr, "?picpng_write_pixel\n");
}

/*------------------------------------------------------------*/
static void
picpng_write_pixel_rgba(void *vp, int x, int y,
                     Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a)
{
  fprintf(stderr, "?picpng_write_pixel_rgba\n");
}

/*------------------------------------------------------------*/
#define WRITE_INIT(picpng_) ((picpng_)->scanline || write_init(picpng_))
static int
write_init(PicPng *png)
{
  png->bit_depth = 8;
  if (3 == png->nchan)
    png->color_type = PNG_COLOR_TYPE_RGB;
  else
    png->color_type = PNG_COLOR_TYPE_GRAY;
  png_set_IHDR(png->png_ptr, png->info_ptr, png->width, png->height,
               png->bit_depth, png->color_type, PNG_INTERLACE_NONE,
               PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
  png_write_info(png->png_ptr, png->info_ptr);
  png->row = (png_bytep)
    malloc(png_get_rowbytes(png->png_ptr, png->info_ptr));
  assert(png->row);

  return 1;
}

/*------------------------------------------------------------*/
static void
seek_row_write(PicPng *png, int y)
{
  memset(png->row, 0, png_get_rowbytes(png->png_ptr, png->info_ptr));
  while (png->scanline < y) {
    png_write_rows(png->png_ptr, &png->row, 1);
    png->scanline++;
  }
}

/*------------------------------------------------------------*/
static void
picpng_write_row(void *vp, int y, int x0, int nx, const Pixel1 *buf)
{
  PicPng *png = (PicPng *) vp;

  if (! png->read_not_write && 1 == png->nchan && WRITE_INIT(png)) {
    int i;

    seek_row_write(png, y);
    for (i = 0; i < nx; i++)
      png->row[x0+i] = buf[i];
    png_write_row(png->png_ptr, png->row);
    png->scanline++;
  }
}

/*------------------------------------------------------------*/
static void
picpng_write_row_rgba(void *vp, int y, int x0, int nx, const Pixel1_rgba *buf)
{
  PicPng *png = (PicPng *) vp;

  if (! png->read_not_write && 3 == png->nchan && WRITE_INIT(png)) {
    int i, j;

    seek_row_write(png, y);
    for (i = 0, j = x0; i < nx; i++, j += 3) {
      png->row[j+0] = buf[i].r;
      png->row[j+1] = buf[i].g;
      png->row[j+2] = buf[i].b;
    }
    png_write_row(png->png_ptr, png->row);
    png->scanline++;
  }
}

/*------------------------------------------------------------*/
static int
picpng_get_nchan(void *vp)
{
  PicPng *png = (PicPng *) vp;
  return png->nchan;
}

/*------------------------------------------------------------*/
static void
picpng_get_box(void *vp, int *ox, int *oy, int *dx, int *dy)
{
  PicPng *png = (PicPng *) vp;

  if (png->read_not_write || png->scanline) {
    *ox = 0;
    *oy = 0;
    *dx = png->width;
    *dy = png->height;
  } else {
    *ox = PIXEL_UNDEFINED;
    *oy = PIXEL_UNDEFINED;
    *dx = PIXEL_UNDEFINED;
    *dy = PIXEL_UNDEFINED;
  }
}

/*------------------------------------------------------------*/
static Pixel1
picpng_read_pixel(void *vp, int x, int y)
{
  fprintf(stderr, "?picpng_read_pixel\n");
  return 0;
}

/*------------------------------------------------------------*/
static void
picpng_read_pixel_rgba(void *vp, int x, int y, Pixel1_rgba *pv)
{
  fprintf(stderr, "?picpng_read_pixel_rgba\n");
}

/*------------------------------------------------------------*/
static void
seek_row_read(PicPng *png, int y)
{
  while (png->scanline <= y) {
    png_read_rows(png->png_ptr, &png->row, NULL, 1);
    png->scanline++;
  }
}

/*------------------------------------------------------------*/
static void
picpng_read_row(void *vp, int y, int x0, int nx, Pixel1 *buf)
{
  PicPng *png = (PicPng *) vp;
  
  if (png->read_not_write && 1 == png->nchan) {
    int i;

    seek_row_read(png, y);
    for (i = 0; i < nx; i++)
      buf[i] = png->row[x0+i];
  }
}

/*------------------------------------------------------------*/
static void
picpng_read_row_rgba(void *vp, int y, int x0, int nx, Pixel1_rgba *buf)
{
  PicPng *png = (PicPng *) vp;

  if (png->read_not_write && 3 == png->nchan) {
    int i;
    int j;

    seek_row_read(png, y);
    for (i = 0, j = x0; i < nx; i++, j += 3) {
      buf[i].r = png->row[j+0];
      buf[i].g = png->row[j+1];
      buf[i].b = png->row[j+2];
      buf[i].a = 255;
    }
  }
}

/*------------------------------------------------------------*/
static int
picpng_next_pic(void *vp)
{
  return 0;
}

/*------------------------------------------------------------*/
static Pic_procs
pic_picpng_procs = {
  picpng_open,
  picpng_open_stream,
  picpng_close,
  picpng_get_name,

  picpng_clear,
  picpng_clear_rgba,

  picpng_set_nchan,
  picpng_set_box,

  picpng_write_pixel,
  picpng_write_pixel_rgba,
  picpng_write_row,
  picpng_write_row_rgba,

  picpng_get_nchan,
  picpng_get_box,
  picpng_read_pixel,
  picpng_read_pixel_rgba,
  picpng_read_row,
  picpng_read_row_rgba
};

/*------------------------------------------------------------*/
Pic pic_png =
{
  "png", &pic_picpng_procs
};

