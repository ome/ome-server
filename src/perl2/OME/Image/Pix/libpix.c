#include <stdlib.h>
#include <stdio.h>
#include <tiffio.h>

#include "./libpix.h"





Pix *NewPix      (char* path,
	int dx, int dy, int dz, int dw, int dt, int bp)
{
	Pix *pPix;
	if (!path || strlen(path) < 1) {
		fprintf (stderr,"Pix->NewPix:  File path not set.\n");
		return (NULL);
	}
	
	if ( ! (bp == 1 || bp == 2 || bp == 4) )
	{
		fprintf (stderr,"Pix->NewPix:  Bytes per pixel must be 1,2, or 4.\n");
		return (NULL);
	}

	pPix = (Pix *) malloc(sizeof (Pix));

	strncpy (pPix->path,path,255);

	pPix->dx = dx;
	pPix->dy = dy;
	pPix->dz = dz;
	pPix->dw = dw;
	pPix->dt = dt;
	pPix->bp = bp;
	pPix->inFile.fp = NULL;
	strcpy (pPix->inFile.path,"");

	return pPix;
}

void FreePix  (Pix *pPix)
{
	convertFinish (pPix);
	free (pPix);
}


/*
* This returns a file pointer to a file ready for update.
* if the file doesn't exist, its is created.
* if the file is not large enough for the image, it will be entirely over-written with enough zeros
* to make it large enough for image.
*/
FILE *GetPixFileUpdate (Pix *pPix)
{
FILE *fp;
size_t imgSize = pPix->dx * pPix->dy * pPix->dz * pPix->dw * pPix->dt * pPix->bp;

	fp = fopen (pPix->path,"r+");
	if (!fp) {
		fp = fopen (pPix->path,"w");
		if (!fp) {
			fprintf (stderr,"Pix->GetPixFileWrite:  Could not open '%s' for update.\n",pPix->path);
			return (NULL);
		}
	}

/*
* If the file isn't long enough to accept the entire image,
* make a zero-filled file big enough for the whole thing.
*/
	if ( fseek (fp,imgSize,SEEK_SET) ) {
		fseek (fp,0,SEEK_SET);
		while (imgSize) {
			putc (0,fp);
			imgSize--;
		}
	}
	
	fseek (fp,0,SEEK_SET);
	return (fp);
}



char *GetROI (Pix *pPix,
	int x0, int y0, int z0, int w0, int t0,
	int x1, int y1, int z1, int w1, int t1
)
{
size_t nPix;
int dx = pPix->dx;
int dy = pPix->dy;
int dz = pPix->dz;
int dw = pPix->dw;
int dt = pPix->dt;
int bp = pPix->bp;
int x,y,z,w,t;
FILE *fp;
size_t nIn;
size_t thePixOff;
size_t sizeX;
char *theBuf;

	if (x0 > x1 || x1 > pPix->dx || x0 < 0 ||
		y0 > y1 || y1 > pPix->dy || y0 < 0 ||
		z0 > z1 || z1 > pPix->dz || z0 < 0 ||
		w0 > w1 || w1 > pPix->dw || w0 < 0 ||
		t0 > t1 || t1 > pPix->dt || t0 < 0 ) {
		fprintf (stderr,"Pix->GetROI:  ROI misconfigured.\n");
		return (NULL);
	}
	nPix = (x1-x0) * (y1-y0) * (z1-z0) * (w1-w0) * (t1-t0);
	theBuf = malloc (nPix * bp);
	if (!theBuf) {
		fprintf (stderr,"Pix->GetROI:  Could not allocate buffer.\n");
		return (NULL);
	}

	fp = fopen (pPix->path,"r");
	if (!fp) {
		fprintf (stderr,"Pix->GetROI:  Could not open '%s' for reading.\n",pPix->path);
		free (theBuf);
		return (NULL);
	}

	thePixOff = 0;
	sizeX = x1-x0;
	x=x0;
	for (t=t0;t < t1; t++) {
		for (w=w0;w < w1; w++) {
			for (z=z0;z < z1; z++) {
				for (y=y0;y < y1; y++) {
					if (fseek (fp, (((((t*dw) + w)*dz + z)*dy + y)*dx + x)*bp, SEEK_SET)) {
						fprintf (stderr,"Pix->GetROI:  Could not seek to (%d,%d,%d,%d,%d) in file %s.\n",
							x,y,z,w,t,pPix->path);
						fclose (fp);
						free (theBuf);
						return (NULL);
					}
					nIn = fread (theBuf+thePixOff,bp,sizeX,fp);
					thePixOff += nIn*bp;
					if (nIn < sizeX) {
						fprintf (stderr,"Pix->GetROI:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to read %d pixels, got %d\n",
							x,y,z,w,t,pPix->path,sizeX,nIn);
						fclose (fp);
						free (theBuf);
						return (NULL);
					}
				}
			}
		}
	}
	fclose (fp);

	return (theBuf);
}  



char *GetPlane (Pix *pPix, int theZ, int theW, int theT)
{
size_t nPix;
int dx = pPix->dx;
int dy = pPix->dy;
int dz = pPix->dz;
int dw = pPix->dw;
int dt = pPix->dt;
int bp = pPix->bp;
FILE *fp;
size_t nIn;
char *theBuf;

	if (theZ >= pPix->dz || theZ < 0 ||
		theW >= pPix->dw || theW < 0 ||
		theT >= pPix->dt || theT < 0 ) {
		fprintf (stderr,"Pix->GetPlane:  Plane selection out of range.\n");
		return (NULL);
	}

	nPix = dx * dy;
	theBuf = malloc (nPix * bp);
	if (!theBuf) {
		fprintf (stderr,"Pix->GetPlane:  Could not allocate buffer.\n");
		return (NULL);
	}

	fp = fopen (pPix->path,"r");
	if (!fp) {
		fprintf (stderr,"Pix->GetPlane:  Could not open '%s' for reading.\n",pPix->path);
		free (theBuf);
		return (NULL);
	}

	if (fseek (fp, (((theT*dw) + theW)*dz + theZ)*dy*dx*bp, SEEK_SET)) {
		fprintf (stderr,"Pix->GetPlane:  Could not seek to (%d,%d,%d,%d,%d) in file %s.\n",
			0,0,theZ,theW,theT,pPix->path);
		fclose (fp);
		free (theBuf);
		return (NULL);
	}
	
	nIn = fread (theBuf,bp,nPix,fp);
	if (nIn < nPix) {
		fprintf (stderr,"Pix->GetPlane:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to read %d pixels, got %d\n",
			0,0,theZ,theW,theT,pPix->path,nPix,nIn);
		fclose (fp);
		free (theBuf);
		return (NULL);
	}

	fclose (fp);
	return (theBuf);
}  


size_t Plane2TIFF (Pix *pPix, int theZ, int theW, int theT, char *path)
{
size_t nPix;
char *theBuf;

	theBuf = GetPlane (pPix,theZ,theW,theT);
	if (theBuf == NULL) {
		fprintf (stderr,"Pix->Plane2TIFF:  Could not read repository file\n");
		return (NULL);
	}
	
	nPix = Buff2Tiff (theBuf, path, pPix->dx, pPix->dy, pPix->bp*8);
	free (theBuf);
	return (nPix);
}



size_t Plane2TIFF8 (Pix *pPix, int theZ, int theW, int theT, char *path, double scale, double offset)
{
size_t nPix;
char *theBuf;
char *scaledBuf;

	theBuf = GetPlane (pPix,theZ,theW,theT);
	if (theBuf == NULL) {
		fprintf (stderr,"Pix->Plane2TIFF8:  Could not read repository file\n");
		return (NULL);
	}

	if (pPix->bp != 1) {
		scaledBuf = ScaleBuf8 (theBuf,pPix->bp,pPix->dx*pPix->dy,scale,offset);
		free (theBuf);
		if (!scaledBuf) {
			fprintf (stderr,"Pix->Plane2TIFF8:  Could not scale buffer\n");
			return (NULL);
		}
		theBuf = scaledBuf;
	}
	nPix = Buff2Tiff (theBuf, path, pPix->dx, pPix->dy, 8);
	free (theBuf);
	return (nPix);
}


char *ScaleBuf8 (char *theBuf, int bp, size_t nPix, float scale, int offset)
{
unsigned short *shortPtr = (unsigned short *)theBuf;
unsigned char *scaledBuf,*buf;
int thePix;

	scaledBuf = malloc (nPix);
	if (!scaledBuf) {
		fprintf (stderr,"Pix->ScaleBuf8:  Could not allocate memory for scaled buffer\n");
		return (NULL);
	}

	buf = scaledBuf;
	if (bp == 2) {
		for (; nPix > 0; nPix--) {
			thePix = *shortPtr++ - offset;
			if (thePix < 0) thePix = 0;
			thePix *= scale;
			if (thePix > 255) thePix=255;
			*buf++ = thePix;
		}
	}
	
	return (scaledBuf);
}


size_t Buff2Tiff (char *buf, char *path, size_t dx, size_t dy, size_t bpp)
{
size_t nPix;
TIFF* tiff;
uint32 row,nrow;
uint32 rowsperstrip = (uint32)-1;
tsize_t scanline;
tstrip_t strip;
int err;
char TiffVers[255];

	tiff = TIFFOpen(path,"w");
	if (!tiff ) {
		fprintf (stderr,"Pix->Buff2Tiff:  Could not open '%s' for writing\n",path);
		return NULL;
	}
	
	TIFFSetField(tiff, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
	TIFFSetField(tiff, TIFFTAG_BITSPERSAMPLE, bpp);
	TIFFSetField(tiff, TIFFTAG_SAMPLESPERPIXEL, 1);
/*
* FIXME:
* Apparently, this doesn't work until libtiff version 3.5.7 - Happily not returning an error here if LZW is unavailable,
* but crapping out when you call TIFFWriteEncodedStrip with LZW compression.  It does send text to stderr at this point
* if there's no LZW, but doesn't reutrn an error????!!!!  Peeeuuuuwww.
* Once again the rest of us suffer due to Unisys mouth-breaters.
	if (! TIFFSetField(tiff, TIFFTAG_COMPRESSION, COMPRESSION_LZW) )
*/
		TIFFSetField(tiff, TIFFTAG_COMPRESSION, COMPRESSION_NONE);
	TIFFSetField(tiff, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_MINISBLACK);
	

	TIFFSetField(tiff, TIFFTAG_IMAGEWIDTH, dx);
	TIFFSetField(tiff, TIFFTAG_IMAGELENGTH, dy);
	rowsperstrip = TIFFDefaultStripSize(tiff,0);
	rowsperstrip = rowsperstrip > dy ? dy : rowsperstrip;
	TIFFSetField(tiff, TIFFTAG_ROWSPERSTRIP, rowsperstrip);

	scanline = TIFFScanlineSize(tiff);

	for (row = 0; row < dy; row += rowsperstrip)
	{
		nrow = (row+rowsperstrip > dy ?
			dy-row : rowsperstrip);
		strip = TIFFComputeStrip(tiff, row, 0);
		err = TIFFWriteEncodedStrip(tiff, strip, buf, nrow*scanline);
		if (err < 0) {
			fprintf (stderr,"Pix->Buff2Tiff:  Error writing tiff file libtiff error: %d strip: %d scanline: %d rowsperstrip: %d (device full?)\n",err,strip,scanline,rowsperstrip);
			TIFFClose (tiff);
			unlink (path);
			return (NULL);
		}
		buf += (nrow * scanline);
	}
	

	TIFFClose (tiff);
	return (dx*dy);

	
	
}





char *GetStack (Pix *pPix, int theW, int theT)
{
size_t nPix;
int dx = pPix->dx;
int dy = pPix->dy;
int dz = pPix->dz;
int dw = pPix->dw;
int dt = pPix->dt;
int bp = pPix->bp;
FILE *fp;
size_t nIn;
char *theBuf;

	if (theW >= pPix->dw || theW < 0 ||
		theT >= pPix->dt || theT < 0 ) {
		fprintf (stderr,"Pix->GetStack:  Stack selection out of range.\n");
		return (NULL);
	}

	nPix = dx * dy * dz;
	theBuf = malloc (nPix * bp);
	if (!theBuf) {
		fprintf (stderr,"Pix->GetStack:  Could not allocate buffer.\n");
		return (NULL);
	}

	fp = fopen (pPix->path,"r");
	if (!fp) {
		fprintf (stderr,"Pix->GetStack:  Could not open '%s' for reading.\n",pPix->path);
		free (theBuf);
		return (NULL);
	}

	if (fseek (fp, ((theT*dw) + theW)*dz*dy*dx*bp, SEEK_SET)) {
		fprintf (stderr,"Pix->GetStack:  Could not seek to (%d,%d,%d,%d,%d) in file %s.\n",
			0,0,0,theW,theT,pPix->path);
		fclose (fp);
		free (theBuf);
		return (NULL);
	}
	nIn = fread (theBuf,bp,nPix,fp);
	if (nIn < nPix) {
		fprintf (stderr,"Pix->GetStack:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to read %d pixels, got %d\n",
			0,0,0,theW,theT,pPix->path,nPix,nIn);
		fclose (fp);
		free (theBuf);
		return (NULL);
	}

	fclose (fp);
	return (theBuf);
}  


char *GetPixels (Pix *pPix)
{
size_t size;
char *theBuf;
unsigned char *theBuf8;
unsigned short *theBuf16;
int bp = pPix->bp;
FILE *fp;
size_t nIn;

	size = pPix->dx * pPix->dy * pPix->dz * pPix->dw * pPix->dt;
	theBuf = malloc (size * bp);
	if (!theBuf) {
		fprintf (stderr,"Pix->GetPixels:  Could not allocate buffer.\n");
		return (NULL);
	}

	fp = fopen (pPix->path,"r");
	if (!fp) {
		fprintf (stderr,"Pix->GetPixels:  Could not open '%s' for reading.\n",pPix->path);
		free (theBuf);
		return (NULL);
	}

	nIn = fread (theBuf,bp,size,fp);
	fclose (fp);

	if (nIn == size)
		return (theBuf);
	else {
		fprintf (stderr,"Pix->GetPixels:  Premature end of file - expecting %d pixels, got %d.\n",size,nIn);
		fclose (fp);
		free (theBuf);
		return (NULL);
	}
}



size_t SetRow (Pix *pPix, char *thePix, int theY, int theZ, int theW, int theT)
{
size_t nPix;
int dx = pPix->dx;
int dy = pPix->dy;
int dz = pPix->dz;
int dw = pPix->dw;
int dt = pPix->dt;
int bp = pPix->bp;
FILE *fp;
size_t nOut;

	if (theY >= dy || theY < 0 ||
		theZ >= dz || theZ < 0 ||
		theW >= dw || theW < 0 ||
		theT >= dt || theT < 0 ) {
		fprintf (stderr,"Pix->SetRow:  Row selection out of range.\n");
		return (NULL);
	}

	nPix = dx;

	fp = GetPixFileUpdate (pPix);
	if (!fp) {
		fprintf (stderr,"Pix->SetRow:  Could not open '%s' for writing.\n",pPix->path);
		return (NULL);
	}

	if (fseek (fp, ((((theT*dw) + theW)*dz + theZ)*dy + theY)*dx*bp, SEEK_SET)) {
		fprintf (stderr,"Pix->SetRow:  Could not seek to (%d,%d,%d,%d,%d) in file %s.\n",
			0,theY,theZ,theW,theT,pPix->path);
		fclose (fp);
		return (NULL);
	}

	nOut = fwrite (thePix,bp,nPix,fp);
	if (nOut < nPix) {
		fprintf (stderr,"Pix->SetRow:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to write %d pixels, actually wrote %d\n",
			0,theY,theZ,theW,theT,pPix->path,nPix,nOut);
		fclose (fp);
		return (nOut);
	}

	fclose (fp);
	return (nOut);
}  



size_t SetRows (Pix *pPix, char *thePix, int nRows, int theY, int theZ, int theW, int theT)
{
size_t nPix;
int dx = pPix->dx;
int dy = pPix->dy;
int dz = pPix->dz;
int dw = pPix->dw;
int dt = pPix->dt;
int bp = pPix->bp;
FILE *fp;
size_t nOut;

	if (nRows + theY >  dy || nRows < 0 ||
		theY         >= dy || theY  < 0 ||
		theZ         >= dz || theZ  < 0 ||
		theW         >= dw || theW  < 0 ||
		theT         >= dt || theT  < 0 ) {
		fprintf (stderr,"Pix->SetRows:  Row selection out of range.\n");
		return (NULL);
	}

	nPix = dx*nRows;

	fp = GetPixFileUpdate (pPix);
	if (!fp) {
		fprintf (stderr,"Pix->SetRows:  Could not open '%s' for writing.\n",pPix->path);
		return (NULL);
	}

	if (fseek (fp, ((((theT*dw) + theW)*dz + theZ)*dy + theY)*dx*bp, SEEK_SET)) {
		fprintf (stderr,"Pix->SetRows:  Could not seek to (%d,%d,%d,%d,%d) in file %s.\n",
			0,theY,theZ,theW,theT,pPix->path);
		fclose (fp);
		return (NULL);
	}

	nOut = fwrite (thePix,bp,nPix,fp);
	if (nOut < nPix) {
		fprintf (stderr,"Pix->SetRows:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to write %d pixels, actually wrote %d\n",
			0,theY,theZ,theW,theT,pPix->path,nPix,nOut);
		fclose (fp);
		return (nOut);
	}

	fclose (fp);
	return (nOut);
}  



size_t SetPlane (Pix *pPix, char *thePix, int theZ, int theW, int theT)
{
size_t nPix;
int dx = pPix->dx;
int dy = pPix->dy;
int dz = pPix->dz;
int dw = pPix->dw;
int dt = pPix->dt;
int bp = pPix->bp;
FILE *fp;
size_t nOut;

	if (theZ >= dz || theZ < 0 ||
		theW >= dw || theW < 0 ||
		theT >= dt || theT < 0 ) {
		fprintf (stderr,"Pix->SetPlane:  Plane selection out of range.\n");
		return (NULL);
	}

	nPix = dx * dy;

	fp = GetPixFileUpdate (pPix);
	if (!fp) {
		fprintf (stderr,"Pix->SetPlane:  Could not open '%s' for writing.\n",pPix->path);
		return (NULL);
	}

	if (fseek (fp, (((theT*dw) + theW)*dz + theZ)*dy*dx*bp, SEEK_SET)) {
		fprintf (stderr,"Pix->SetPlane:  Could not seek to (%d,%d,%d,%d,%d) in file %s.\n",
			0,0,theZ,theW,theT,pPix->path);
		fclose (fp);
		return (NULL);
	}

	nOut = fwrite (thePix,bp,nPix,fp);
	if (nOut < nPix) {
		fprintf (stderr,"Pix->SetPlane:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to write %d pixels, actually wrote %d\n",
			0,0,theZ,theW,theT,pPix->path,nPix,nOut);
		fclose (fp);
		return (nOut);
	}

	fclose (fp);
	return (nOut);
}  



size_t SetStack (Pix *pPix, char *thePix, int theW, int theT)
{
size_t nPix;
int dx = pPix->dx;
int dy = pPix->dy;
int dz = pPix->dz;
int dw = pPix->dw;
int dt = pPix->dt;
int bp = pPix->bp;
FILE *fp;
size_t nOut;

	if (theW >= dw || theW < 0 ||
		theT >= dt || theT < 0 ) {
		fprintf (stderr,"Pix->SetStack:  Plane selection out of range.\n");
		return (NULL);
	}

	nPix = dx * dy * dz;

	fp = GetPixFileUpdate (pPix);
	if (!fp) {
		fprintf (stderr,"Pix->SetStack:  Could not open '%s' for writing.\n",pPix->path);
		return (NULL);
	}

	if (fseek (fp, ((theT*dw) + theW)*dz*dy*dx*bp, SEEK_SET)) {
		fprintf (stderr,"Pix->SetStack:  Could not seek to (%d,%d,%d,%d,%d) in file %s.\n",
			0,0,0,theW,theT,pPix->path);
		fclose (fp);
		return (NULL);
	}

	nOut = fwrite (thePix,bp,nPix,fp);
	if (nOut < nPix) {
		fprintf (stderr,"Pix->SetStack:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to write %d pixels, actually wrote %d\n",
			0,0,0,theW,theT,pPix->path,nPix,nOut);
		fclose (fp);
		return (nOut);
	}

	fclose (fp);
	return (nOut);
}  



size_t SetROI (Pix *pPix, char *thePix,
	int x0, int y0, int z0, int w0, int t0,
	int x1, int y1, int z1, int w1, int t1
)
{
size_t nPix;
int dx = pPix->dx;
int dy = pPix->dy;
int dz = pPix->dz;
int dw = pPix->dw;
int dt = pPix->dt;
int bp = pPix->bp;
int x,y,z,w,t;
FILE *fp;
size_t nOut;
size_t thePixOff;
size_t sizeX;

	if (x0 > x1 || x1 > pPix->dx || x0 < 0 ||
		y0 > y1 || y1 > pPix->dy || y0 < 0 ||
		z0 > z1 || z1 > pPix->dz || z0 < 0 ||
		w0 > w1 || w1 > pPix->dw || w0 < 0 ||
		t0 > t1 || t1 > pPix->dt || t0 < 0 ) {
		fprintf (stderr,"Pix->SetROI:  ROI misconfigured.\n");
		return (NULL);
	}
	nPix = (x1-x0) * (y1-y0) * (z1-z0) * (w1-w0) * (t1-t0);

	fp = GetPixFileUpdate (pPix);
	if (!fp) {
		fprintf (stderr,"Pix->SetROI:  Could not open '%s' for writing.\n",pPix->path);
		return (NULL);
	}

	thePixOff = 0;
	sizeX = x1-x0;
	x=x0;
	for (t=t0;t < t1; t++) {
		for (w=w0;w < w1; w++) {
			for (z=z0;z < z1; z++) {
				for (y=y0;y < y1; y++) {
					if (fseek (fp, (((((t*dw) + w)*dz + z)*dy + y)*dx + x)*bp, SEEK_SET)) {
						fprintf (stderr,"Pix->SetROI:  Could not seek to (%d,%d,%d,%d,%d) in file %s.\n",
							x,y,z,w,t,pPix->path);
						fclose (fp);
						return (thePixOff/bp);
					}
					nOut = fwrite (thePix+thePixOff,bp,sizeX,fp);
					thePixOff += nOut*bp;
					if (nOut < sizeX) {
						fprintf (stderr,"Pix->SetROI:  Error at (%d,%d,%d,%d,%d).  Tried to write %d pixels, wrote %d\n",
							x,y,z,w,t,sizeX,nOut);
						fclose (fp);
						return (thePixOff/bp);
					}
				}
			}
		}
	}
	fclose (fp);
	return (thePixOff/bp);
}  



size_t SetPixels (Pix *pPix, char *thePix)
{
size_t nPix = pPix->dx * pPix->dy * pPix->dz * pPix->dw * pPix->dt;
FILE *fp;
size_t nOut;

	fp = fopen (pPix->path,"w");
	if (!fp) {
		fprintf (stderr,"Pix->SetPixels:  Could not open '%s' for writing.\n",pPix->path);
		return (NULL);
	}

	nOut = fwrite (thePix,pPix->bp,nPix,fp);
	fclose (fp);
	return (nOut);
}



/*
Josiah Johnston <siah@nih.gov>
setConvertFile calls convertFinish, then re-sets internal inFile specification.
	returns true if successfull.

Variable explanation:
	pPix is pPix object in question. Can be old or new.
	inPath is path to file that will soon be converted
	bp is bytes per pixel of the file to convert
	bigEndian is a boolean. 1 if file's pixels are big endian, else 0
*/
int setConvertFile (Pix *pPix, char *inPath, int bp, int fileBigEndian)
{

	convertFinish (pPix);

	strncpy (pPix->inFile.path,inPath,255);
	pPix->inFile.fp = fopen (pPix->inFile.path,"r");
	if (!pPix->inFile.fp) {
		fprintf (stderr,"Pix->setConvertFile:  Could not open '%s' for reading.\n",pPix->inFile.path);
		return (NULL);
	}
	if ( pPix->bp > 1 && ((bigEndian() && !fileBigEndian) || (!bigEndian() && fileBigEndian)) )
		pPix->inFile.swapBytes = 1;
	else
		pPix->inFile.swapBytes = 0;

	pPix->inFile.bp = bp;

	return (1);
}



void byteSwap2 (char *theBuf, size_t length)
{
/*
use glibc hardware swap - doesn't work in new glibc.
#ifdef __linux__
    unsigned short *uptr = (unsigned short *)theBuf;
    int i;
    
    for(i=0; i<length; i++, uptr++)
    {
        *uptr = bswap_16(*uptr);
    }
#else
*/
	char holder;
	char *maxBuf = theBuf+(length*2);
	
	while (theBuf < maxBuf)
	{
		holder = *theBuf++;
		*(theBuf-1) = *theBuf;
		*theBuf++ = holder;
	}
/*
#endif
*/
}


/*
Josiah Johnston <siah@nih.gov>
* Returns true if our machine is bigEndian.
*/
int bigEndian()
{
    static int init = 1;
    static int endian_value;
    char *p;

    p = (char*)&init;
    return endian_value = p[0]?0:1;
}




/*
Josiah Johnston <siah@nih.gov>
Notes:
  convert methods check if inFile is set, seek infile to offset, 
  then read the number of bytes specified by inFile's bpp and the method parameters, 
  do any endian-flipping, and write the result to the repository file.  
*/
size_t convertRow (Pix *pPix, size_t offset, int theY, int theZ, int theW, int theT) 
{
size_t nPix = pPix->dx, nIO;
FILE *fp = pPix->inFile.fp;
char *theBuf;
int bp = pPix->bp;

	if (!fp) {
		fprintf (stderr,"Pix->convertRow:  file '%s' not open for reading.\n",pPix->inFile.path);
		return (NULL);
	}

	if (fseek (fp, offset, SEEK_SET ) ) {
		fprintf (stderr,"Pix->convertRow:  could not seek to %d in file '%s'.\n",offset, pPix->inFile.path);
		return (NULL);
	}

	theBuf = malloc (nPix * bp);
	if (!theBuf) {
		fprintf (stderr,"Pix->convertRow:  Could not allocate buffer.\n");
		return (NULL);
	}

	nIO = fread (theBuf,bp,nPix,fp);
	if (nIO != nPix) {
		fprintf (stderr,"Pix->convertRow:  Could not read enough pixels from %s.\n",pPix->inFile.path);
		free (theBuf);
		return (NULL);
	}
	
	/* flip bytes */
	if(pPix->inFile.swapBytes)
		byteSwap2( theBuf, nPix );
	
	nIO = SetRow (pPix, theBuf, theY, theZ, theW, theT);
	free (theBuf);
	if (nIO != nPix) {
		fprintf (stderr,"Pix->convertRow:  Could not write enough pixels to %s.\n",pPix->path);
		return (NULL);
	}
	
	return (nIO);
}



/*
Josiah Johnston <siah@nih.gov>
*/
size_t convertRows (Pix *pPix, size_t offset, int nRows, int theY, int theZ, int theW, int theT)
{
size_t nPix = (pPix->dx)*nRows, nIO;
FILE *fp = pPix->inFile.fp;
char *theBuf;
int bp = pPix->inFile.bp;

	if (!fp) {
		fprintf (stderr,"Pix->convertRows:  file '%s' not open for reading.\n",pPix->inFile.path);
		return (NULL);
	}
	
	if (fseek (fp, offset, SEEK_SET ) ) {
		fprintf (stderr,"Pix->convertRows:  could not seek to %d in file '%s'.\n",offset, pPix->inFile.path);
		return (NULL);
	}

	theBuf = malloc (nPix * bp);
	if (!theBuf) {
		fprintf (stderr,"Pix->convertRows:  Could not allocate buffer.\n");
		return (NULL);
	}

	nIO = fread (theBuf,bp,nPix,fp);
	if (nIO != nPix) {
		fprintf (stderr,"Pix->convertRows:  Could not read enough pixels from %s.\n",pPix->inFile.path);
		free (theBuf);
		return (NULL);
	}

	/* flip bytes */
	if(pPix->inFile.swapBytes)
		byteSwap2( theBuf, nPix );
	
	nIO = SetRows (pPix, theBuf, nRows, theY, theZ, theW, theT);
	free (theBuf);
	if (nIO != nPix) {
		fprintf (stderr,"Pix->convertRows:  Could not write enough pixels to %s.\n",pPix->path);
		return (NULL);
	}
	
	return (nIO);
}


/*
Josiah Johnston <siah@nih.gov>
*/
size_t convertPlane (Pix *pPix, size_t offset, int theZ, int theW, int theT)
{
size_t nPix = (pPix->dx)*(pPix->dy), nIO;
FILE *fp = pPix->inFile.fp;
char *theBuf;
int bp = pPix->inFile.bp;

	if (!fp) {
		fprintf (stderr,"Pix->convertPlane:  file '%s' not open for reading.\n",pPix->inFile.path);
		return (NULL);
	}
	
	if (fseek (fp, offset, SEEK_SET ) ) {
		fprintf (stderr,"Pix->convertPlane:  could not seek to %d in file '%s'.\n",offset, pPix->inFile.path);
		return (NULL);
	}

	theBuf = malloc (nPix * bp);
	if (!theBuf) {
		fprintf (stderr,"Pix->convertPlane:  Could not allocate buffer.\n");
		return (NULL);
	}

	nIO = fread (theBuf,bp,nPix,fp);
	if (nIO != nPix) {
		fprintf (stderr,"Pix->convertPlane:  Could not read enough pixels from %s.\n",pPix->inFile.path);
		free (theBuf);
		return (NULL);
	}

	/* flip bytes */
	if(pPix->inFile.swapBytes)
		byteSwap2( theBuf, nPix );
	
	nIO = SetPlane (pPix, theBuf, theZ, theW, theT);
	free (theBuf);
	if (nIO != nPix) {
		fprintf (stderr,"Pix->convertPlane:  Could not write enough pixels to %s.\n",pPix->path);
		return (NULL);
	}
	
	return (nIO);
}



/*
Josiah Johnston <siah@nih.gov>
*/
size_t convertStack (Pix *pPix, size_t offset, int theW, int theT)
{
size_t nPix = (pPix->dx)*(pPix->dy)*(pPix->dz), nIO;
FILE *fp = pPix->inFile.fp;
char *theBuf;
int bp = pPix->inFile.bp;

	if (!fp) {
		fprintf (stderr,"Pix->convertStack:  file '%s' not open for reading.\n",pPix->inFile.path);
		return (NULL);
	}
	
	if (fseek (fp, offset, SEEK_SET ) ) {
		fprintf (stderr,"Pix->convertStack:  could not seek to %d in file '%s'.\n",offset, pPix->inFile.path);
		return (NULL);
	}

	theBuf = malloc (nPix * bp);
	if (!theBuf) {
		fprintf (stderr,"Pix->convertStack:  Could not allocate buffer.\n");
		return (NULL);
	}

	nIO = fread (theBuf,bp,nPix,fp);
	if (nIO != nPix) {
		fprintf (stderr,"Pix->convertStack:  Could not read enough pixels from %s.\n",pPix->inFile.path);
		free (theBuf);
		return (NULL);
	}

	/* flip bytes */
	if(pPix->inFile.swapBytes)
		byteSwap2( theBuf, nPix );
	
	nIO = SetStack (pPix, theBuf, theW, theT);
	free (theBuf);
	if (nIO != nPix) {
		fprintf (stderr,"Pix->convertStack:  Could not write enough pixels to %s.\n",pPix->path);
		return (NULL);
	}
	
	return (nIO);
}



/*
Josiah Johnston <siah@nih.gov>
convertFinish closes inFile & sets pix->inFile to NULL.
    Behave properly if inFile is already NULL.
*/
void convertFinish (Pix *pPix)
{

	if (pPix->inFile.fp) {
		fclose (pPix->inFile.fp);
		pPix->inFile.fp = NULL;
	}
	
	strcpy (pPix->inFile.path,"");
}

