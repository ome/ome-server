#include <stdlib.h>
#include <stdio.h>
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

	return pPix;
}

void FreePix  (Pix *pPix)
{
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

	if (theZ >= pPix->dz || theZ < 0 ||
		theW >= pPix->dw || theW < 0 ||
		theT >= pPix->dt || theT < 0 ) {
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
		fprintf (stderr,"Pix->SetPlane:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to read %d pixels, got %d\n",
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

	if (theW >= pPix->dw || theW < 0 ||
		theT >= pPix->dt || theT < 0 ) {
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
		fprintf (stderr,"Pix->SetStack:  Error at (%d,%d,%d,%d,%d) in file %s.  Tried to read %d pixels, got %d\n",
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
