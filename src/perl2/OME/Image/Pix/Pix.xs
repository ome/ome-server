#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "libpix.h"
typedef Pix *OME__Image__Pix;


MODULE = OME::Image::Pix                PACKAGE = OME::Image::Pix

PROTOTYPES: ENABLE




OME::Image::Pix
new(package,path,dx,dy,dz,dw,dt,bp)
		char *package = NO_INIT;
		char *path
		int dx
		int dy
		int dz
		int dw
		int dt
		int bp
		CODE:
		RETVAL = new(path,dx,dy,dz,dw,dt,bp);
		OUTPUT:
		RETVAL


void
DESTROY(pPix)
		OME::Image::Pix pPix



char*
GetPix (pPix)
	OME::Image::Pix pPix
	PREINIT:
	size_t size;
	CODE:
		size = pPix->dx * pPix->dy * pPix->dz * pPix->dw * pPix->dt * pPix->bp;
		RETVAL = (char *) GetPix(pPix);
		if (RETVAL) {
			ST(0) = sv_newmortal();
		/*
		* This nifty call prevents copying of the pixels,
		* and sets the returned value up to be garbage collected by Perl.
		* Basically, it sets the SV's memory buffer to something that was malloc'd externally.
		* We are not to touch this buffer ever again after giving it up to Perl with this call.
		*/
			sv_usepvn (ST(0), RETVAL, size);
		} else {
			ST(0) = &PL_sv_undef;
		}


char*
GetPixPlane (pPix,theZ,theW,theT)
	OME::Image::Pix pPix
	int theZ
	int theW
	int theT
	PREINIT:
	size_t size;
	CODE:
		size = pPix->dx * pPix->dy * pPix->bp;
		RETVAL = (char *) GetPixPlane(pPix,theZ,theW,theT);
		if (RETVAL) {
			ST(0) = sv_newmortal();
		/*
		* This nifty call prevents copying of the pixels,
		* and sets the returned value up to be garbage collected by Perl.
		* Basically, it sets the SV's memory buffer to something that was malloc'd externally.
		* We are not to touch this buffer ever again after giving it up to Perl with this call.
		*/
			sv_usepvn (ST(0), RETVAL, size);
		} else {
			ST(0) = &PL_sv_undef;
		}

char*
GetPixStack (pPix,theW,theT)
	OME::Image::Pix pPix
	int theW
	int theT
	PREINIT:
	size_t size;
	CODE:
		size = pPix->dx * pPix->dy * pPix->dz * pPix->bp;
		RETVAL = (char *) GetPixStack(pPix,theW,theT);
		if (RETVAL) {
			ST(0) = sv_newmortal();
		/*
		* This nifty call prevents copying of the pixels,
		* and sets the returned value up to be garbage collected by Perl.
		* Basically, it sets the SV's memory buffer to something that was malloc'd externally.
		* We are not to touch this buffer ever again after giving it up to Perl with this call.
		*/
			sv_usepvn (ST(0), RETVAL, size);
		} else {
			ST(0) = &PL_sv_undef;
		}

char*
GetPixROI (pPix,x0,y0,z0,w0,t0,x1,y1,z1,w1,t1)
	OME::Image::Pix pPix
	int x0
	int y0
	int z0
	int w0
	int t0
	int x1
	int y1
	int z1
	int w1
	int t1
	PREINIT:
	size_t size;
	CODE:
		size = (x1-x0) * (y1-y0) * (z1-z0) * (w1-w0) * (t1-t0) * pPix->bp;
		RETVAL = (char *) GetPixROI(pPix,x0,y0,z0,w0,t0,x1,y1,z1,w1,t1);
		if (RETVAL) {
			ST(0) = sv_newmortal();
		/*
		* This nifty call prevents copying of the pixels,
		* and sets the returned value up to be garbage collected by Perl.
		* Basically, it sets the SV's memory buffer to something that was malloc'd externally.
		* We are not to touch this buffer ever again after giving it up to Perl with this call.
		*/
			sv_usepvn (ST(0), RETVAL, size);
		} else {
			ST(0) = &PL_sv_undef;
		}

size_t
SetPix (pPix,thePix)
	OME::Image::Pix pPix
	char *thePix

size_t
SetPixPlane (pPix,thePix,theZ,theW,theT)
	OME::Image::Pix pPix
	char *thePix
	int theZ
	int theW
	int theT

size_t
SetPixStack (pPix,thePix,theW,theT)
	OME::Image::Pix pPix
	char *thePix
	int theW
	int theT


size_t
SetPixROI (pPix,thePix,x0,y0,z0,w0,t0,x1,y1,z1,w1,t1)
	OME::Image::Pix pPix
	char *thePix
	int x0
	int y0
	int z0
	int w0
	int t0
	int x1
	int y1
	int z1
	int w1
	int t1
