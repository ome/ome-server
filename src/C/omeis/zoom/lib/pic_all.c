static char rcsid[] = "$Header$";
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif  /* HAVE_CONFIG_H */

#include <pic.h>

extern Pic
    pic_tiff, pic_jpeg, pic_png, pic_omeis;

/*
 * A pic_list for those programs that want everything.
 * If the application doesn't define space for pic_list then the
 * linker will grab this.
 */

Pic *pic_list[PIC_LISTMAX] = {
    &pic_tiff, &pic_jpeg, &pic_png, &pic_omeis, 
0};
