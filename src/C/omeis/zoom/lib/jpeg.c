#include <simple.h>
#include <pic.h>
#include <string.h>
#include <jpeglib.h>

struct tagJpeg {
  struct jpeg_error_mgr jerr;
  char *name;
  FILE *file;
  int read_not_write;
  struct jpeg_decompress_struct in;
  struct jpeg_compress_struct out;
  int format;
  int scanline;
  int row_stride;
  JSAMPARRAY row;
};
typedef struct tagJpeg Jpeg;

static void *
jpeg_open(const char *filename, const char *mode)
{
  Jpeg *jpeg = NULL;
  FILE *try;

  if ('r' == mode[0] && str_eq(filename, "-.jpeg"))
    try = fdopen(dup(fileno(stdin)), "rb");
  else if ('w' == mode[0] && str_eq(filename, "-.jpeg"))
    try = fdopen(dup(fileno(stdout)), "wb");
  else
    try = fopen(filename, mode);
  
  if (try) {
    ALLOC(jpeg, Jpeg, 1);
    memset(jpeg, 0, sizeof(Jpeg));
    jpeg->file = try;
    ALLOC(jpeg->name, char, strlen (filename)+1);
    strcpy (jpeg->name,filename);
    if ('r' == mode[0]) {
      jpeg->read_not_write = 1;
      jpeg->in.err = jpeg_std_error(&jpeg->jerr);
      jpeg_create_decompress(&jpeg->in);
      jpeg_stdio_src(&jpeg->in, jpeg->file);
      jpeg_read_header(&jpeg->in, TRUE);
      jpeg_start_decompress(&jpeg->in);
      jpeg->row_stride = jpeg->in.output_width * jpeg->in.output_components;
      jpeg->row = (*jpeg->in.mem->alloc_sarray)((j_common_ptr) &jpeg->in,
					      JPOOL_IMAGE, jpeg->row_stride, 1);
    } else {
      jpeg->read_not_write = 0;
      jpeg->out.err = jpeg_std_error(&jpeg->jerr);
      jpeg_create_compress(&jpeg->out);
      jpeg_stdio_dest(&jpeg->out, jpeg->file);
      jpeg->out.in_color_space = JCS_RGB;
    }
  }

  return jpeg;
}

static void *
jpeg_open_stream (FILE *stream, const char *filename,  const char *mode)
{
  Jpeg *jpeg = NULL;

  if (stream) {
    ALLOC(jpeg, Jpeg, 1);
    memset(jpeg, 0, sizeof(Jpeg));
    jpeg->file = stream;
    ALLOC(jpeg->name, char, strlen (filename)+1);
    strcpy (jpeg->name,filename);
    if ('r' == mode[0]) {
      jpeg->read_not_write = 1;
      jpeg->in.err = jpeg_std_error(&jpeg->jerr);
      jpeg_create_decompress(&jpeg->in);
      jpeg_stdio_src(&jpeg->in, jpeg->file);
      jpeg_read_header(&jpeg->in, TRUE);
      jpeg_start_decompress(&jpeg->in);
      jpeg->row_stride = jpeg->in.output_width * jpeg->in.output_components;
      jpeg->row = (*jpeg->in.mem->alloc_sarray)((j_common_ptr) &jpeg->in,
					      JPOOL_IMAGE, jpeg->row_stride, 1);
    } else {
      jpeg->read_not_write = 0;
      jpeg->out.err = jpeg_std_error(&jpeg->jerr);
      jpeg_create_compress(&jpeg->out);
      jpeg_stdio_dest(&jpeg->out, jpeg->file);
      jpeg->out.in_color_space = JCS_RGB;
    }
  }

  return jpeg;
}

static void
jpeg_close(void *p)
{
  Jpeg *jpeg = (Jpeg *) p;

  if (jpeg->read_not_write) {
    jpeg_finish_decompress(&jpeg->in);
    jpeg_destroy_decompress(&jpeg->in);
  } else {
    jpeg_finish_compress(&jpeg->out);
    jpeg_destroy_compress(&jpeg->out);
  }

  assert(jpeg->name);
  free(jpeg->name);
  assert(jpeg->file);
  fclose(jpeg->file);
  free(jpeg);
}

static char *
jpeg_get_name(void *p)
{
  Jpeg *jpeg = (Jpeg *) p;
  return jpeg->name;
}

static void
jpeg_clear(void *vp, Pixel1 pv)
{
  /* hmm... ignore? */
}

static void
jpeg_clear_rgba(void *vp, Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a)
{
  /* hmm... ignore? */
}

static void
jpeg_set_nchan(void *vp, int nchan)
{
  Jpeg *jpeg = (Jpeg *) vp;
  
  if (! jpeg->read_not_write) {
    jpeg->out.input_components = nchan;
  	if (nchan == 1)
        jpeg->out.in_color_space = JCS_GRAYSCALE;
  	else
        jpeg->out.in_color_space = JCS_RGB;
  }
}

static void
jpeg_set_box(void *vp, int ox, int oy, int dx, int dy)
{
  Jpeg *jpeg = (Jpeg *) vp;
  if (! jpeg->read_not_write) {
    jpeg->out.image_width = ox + dx;
    jpeg->out.image_height = oy + dy;
  }    
}

static void
jpeg_write_pixel(void *vp, int x, int y, Pixel1 pv)
{
  fprintf(stderr, "?jpeg_write_pixel\n");
  /* output scanlines until we reach scanline y */
  /* set pixel x of scanline to pv */
}

static void
jpeg_write_pixel_rgba(void *vp, int x, int y,
		     Pixel1 r, Pixel1 g, Pixel1 b, Pixel1 a)
{
  fprintf(stderr, "?jpeg_write_pixel_rgba\n");
}

#define WRITE_INIT(jpeg_) ((jpeg_)->scanline || write_init(jpeg_))
static int
write_init(Jpeg *jpeg)
{
  jpeg->row_stride = jpeg->out.input_components * jpeg->out.image_width;
  jpeg_set_defaults(&jpeg->out);
  jpeg->row = (*jpeg->out.mem->alloc_sarray)((j_common_ptr) &jpeg->out,
					   JPOOL_IMAGE, jpeg->row_stride, 1);
  jpeg_start_compress(&jpeg->out, TRUE);

  return 1;
}

static void
seek_row_write(Jpeg *jpeg, int y)
{
  while (jpeg->scanline < y) {
    jpeg_write_scanlines(&jpeg->out, jpeg->row, 1);
    jpeg->scanline++;
  }
}

static void
jpeg_write_row(void *vp, int y, int x0, int nx, const Pixel1 *buf)
{
  Jpeg *jpeg = (Jpeg *) vp;

  if (! jpeg->read_not_write &&
      1 == jpeg->out.input_components &&
      WRITE_INIT(jpeg)) {
    int i;

    seek_row_write(jpeg, y);
    memset(jpeg->row[0], 0, jpeg->row_stride);
    for (i = 0; i < nx; i++)
      jpeg->row[0][x0+i] = buf[i];
    jpeg_write_scanlines(&jpeg->out, jpeg->row, 1);
    jpeg->scanline++;
  }
}

static void
jpeg_write_row_rgba(void *vp, int y, int x0, int nx, const Pixel1_rgba *buf)
{
  Jpeg *jpeg = (Jpeg *) vp;

  if (! jpeg->read_not_write &&
      3 == jpeg->out.input_components &&
      WRITE_INIT(jpeg)) {
    int i, j;

    seek_row_write(jpeg, y);
    memset(jpeg->row[0], 0, jpeg->row_stride);
    for (i = 0, j = x0; i < nx; i++, j += 3) {
      jpeg->row[0][j+0] = buf[i].r;
      jpeg->row[0][j+1] = buf[i].g;
      jpeg->row[0][j+2] = buf[i].b;
    }
    jpeg_write_scanlines(&jpeg->out, jpeg->row, 1);
    jpeg->scanline++;
  }
}

static int
jpeg_get_nchan(void *vp)
{
  Jpeg *jpeg = (Jpeg *) vp;
  return jpeg->read_not_write ?
    jpeg->in.output_components : jpeg->out.input_components;
}

static void
jpeg_get_box(void *vp, int *ox, int *oy, int *dx, int *dy)
{
  Jpeg *jpeg = (Jpeg *) vp;

  if (jpeg->read_not_write) {
    *ox = 0;
    *oy = 0;
    *dx = jpeg->in.image_width;
    *dy = jpeg->in.image_height;
  } else if (jpeg->scanline) {
    *ox = 0;
    *oy = 0;
    *dx = jpeg->out.image_width;
    *dy = jpeg->out.image_height;
  } else {
    *ox = PIXEL_UNDEFINED;
    *oy = PIXEL_UNDEFINED;
    *dx = PIXEL_UNDEFINED;
    *dy = PIXEL_UNDEFINED;
  }
}

static Pixel1
jpeg_read_pixel(void *vp, int x, int y)
{
  fprintf(stderr, "?jpeg_read_pixel\n");
  return 0;
}

static void
jpeg_read_pixel_rgba(void *vp, int x, int y, Pixel1_rgba *pv)
{
  fprintf(stderr, "?jpeg_read_pixel_rgba\n");
}

static void
seek_row_read(Jpeg *jpeg, int y)
{
  while (jpeg->scanline <= y) {
    jpeg_read_scanlines(&jpeg->in, jpeg->row, 1);
    jpeg->scanline++;
  }
}

static void
jpeg_read_row(void *vp, int y, int x0, int nx, Pixel1 *buf)
{
  Jpeg *jpeg = (Jpeg *) vp;
  
  if (jpeg->read_not_write && 1 == jpeg->in.output_components) {
    int i;

    seek_row_read(jpeg, y);
    for (i = 0; i < nx; i++)
      buf[i] = jpeg->row[0][x0+i];
  }
}

static void
jpeg_read_row_rgba(void *vp, int y, int x0, int nx, Pixel1_rgba *buf)
{
  Jpeg *jpeg = (Jpeg *) vp;

  if (jpeg->read_not_write && 3 == jpeg->in.output_components) {
    int i;

    seek_row_read(jpeg, y);
    if (1 == jpeg->in.output_components)
      for (i = 0; i < nx; i++) {
	const int luminance = jpeg->row[0][x0+i];
	buf[i].r = luminance;
	buf[i].g = luminance;
	buf[i].b = luminance;
      }
    else
      for (i = 0; i < nx; i++) {
	buf[i].r = jpeg->row[0][(x0+i)*3+0];
	buf[i].g = jpeg->row[0][(x0+i)*3+1];
	buf[i].b = jpeg->row[0][(x0+i)*3+2];
      }
  }
}

static int
jpeg_next_pic(void *vp)
{
  return 0;
}

static Pic_procs
pic_jpeg_procs = {
  jpeg_open,
  jpeg_open_stream,
  jpeg_close,
  jpeg_get_name,

  jpeg_clear,
  jpeg_clear_rgba,

  jpeg_set_nchan,
  jpeg_set_box,

  jpeg_write_pixel,
  jpeg_write_pixel_rgba,
  jpeg_write_row,
  jpeg_write_row_rgba,

  jpeg_get_nchan,
  jpeg_get_box,
  jpeg_read_pixel,
  jpeg_read_pixel_rgba,
  jpeg_read_row,
  jpeg_read_row_rgba,
  jpeg_next_pic
};

Pic pic_jpeg =
{
  "jpeg", &pic_jpeg_procs
};
