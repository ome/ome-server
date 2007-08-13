/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                                                                               */
/* Copyright (C) 2007 Open Microscopy Environment                                */
/*       Massachusetts Institue of Technology,                                   */
/*       National Institutes of Health,                                          */
/*       University of Dundee                                                    */
/*                                                                               */
/*                                                                               */
/*                                                                               */
/*    This library is free software; you can redistribute it and/or              */
/*    modify it under the terms of the GNU Lesser General Public                 */
/*    License as published by the Free Software Foundation; either               */
/*    version 2.1 of the License, or (at your option) any later version.         */
/*                                                                               */
/*    This library is distributed in the hope that it will be useful,            */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of             */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU          */
/*    Lesser General Public License for more details.                            */
/*                                                                               */
/*    You should have received a copy of the GNU Lesser General Public           */
/*    License along with this library; if not, write to the Free Software        */
/*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  */
/*                                                                               */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                                                                               */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/* Written by:  Lior Shamir <shamirl [at] mail [dot] nih [dot] gov>              */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/



#pragma hdrstop

#include <math.h>
#include <stdio.h>
#include "cmatrix.h"
#include "colors/FuzzyCalc.h"
#include "transforms/fft/bcb_fftw3/fftw3.h"
#include "transforms/chevishev.h"
#include "transforms/ChebishevFourier.h"
#include "transforms/wavelet/Symlet5.h"
#include "transforms/wavelet/DataGrid2D.h"
#include "transforms/radon.h"
#include "statistics/CombFirst4Moments.h"
#include "statistics/FeatureStatistics.h"
#include "textures/gabor.h"
#include "textures/tamura.h"
#include "textures/haarlick/haarlick.h"
#include "textures/zernike/zernike.h"

#ifndef WIN32
#include <stdlib.h>
#include <string.h>
#include <tiffio.h>
#endif

#define MIN(a,b) (a<b?a:b)
#define MAX(a,b) (a>b?a:b)

RGBcolor HSV2RGB(HSVcolor hsv)
{   RGBcolor rgb;
    float R, G, B;
    float H, S, V;
    float i, f, p, q, t;

    H=hsv.hue;
    S=(float)(hsv.saturation)/240;
    V=(float)(hsv.value)/240;
    if(S==0 && H==0) {R=G=B=V;}  /*if S=0 and H is undefined*/
    H=H*(360.0/240.0);
    if(H==360) {H=0;}
    H=H/60;
    i=floor(H);
    f=H-i;
    p=V*(1-S);
    q=V*(1-(S*f));
    t=V*(1-(S*(1-f)));

    if(i==0) {R=V;  G=t;  B=p;}
    if(i==1) {R=q;  G=V;  B=p;}
    if(i==2) {R=p;  G=V;  B=t;}
    if(i==3) {R=p;  G=q;  B=V;}
    if(i==4) {R=t;  G=p;  B=V;}
    if(i==5) {R=V;  G=p;  B=q;}

    rgb.red=(byte)(R*255);
    rgb.green=(byte)(G*255);
    rgb.blue=(byte)(B*255);
    return rgb;
}
//-----------------------------------------------------------------------
HSVcolor RGB2HSV(RGBcolor rgb)
{
  float r,g,b,h,max,min,delta;
  HSVcolor hsv;

  r=(float)(rgb.red) / 255;
  g=(float)(rgb.green) / 255;
  b=(float)(rgb.blue) / 255;

  max = MAX (r, MAX (g, b)), min = MIN (r, MIN (g, b));
  delta = max - min;

  hsv.value = (byte)(max*240.0);
  if (max != 0.0)
    hsv.saturation = (byte)((delta / max)*240.0);
  else
    hsv.saturation = 0;
  if (hsv.saturation == 0) hsv.hue = 0; //-1;
  else {
    if (r == max)
      h = (g - b) / delta;
    else if (g == max)
      h = 2 + (b - r) / delta;
    else if (b == max)
      h = 4 + (r - g) / delta;
    h *= 60.0;
    if (h < 0.0) h += 360.0;
    hsv.hue = (byte)(h *(240.0/360.0));
  }
  return(hsv);
}


//--------------------------------------------------------------------------
TColor RGB2COLOR(RGBcolor rgb)
{  return((TColor)(rgb.blue*65536+rgb.green*256+rgb.red));
}

double COLOR2GRAY(TColor color1)
{  double r,g,b;

   r=(byte)(color1 & 0xFF);
   g=(byte)((color1 & 0xFF00)>>8);
   b=(byte)((color1 & 0xFF0000)>>16);

   return((0.3*r+0.59*g+0.11*b));
}


#ifdef WIN32

//--------------------------------------------------------------------------
int ImageMatrix::LoadImage(TPicture *picture,int ColorMode)
{  int a,b,x,y;
   width=picture->Width;
   height=picture->Height;
   bits=8;
   this->ColorMode=ColorMode;
   /* allocate memory for the image's pixels */
   data=new pix_data *[width];
   if (!data) return(0); /* memory allocation failed */
   for (a=0;a<width;a++)
   {  data[a]=new pix_data[height];
      if (!data[a]) return (0);   /* memory allocation failed */
   }
   /* load the picture */
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
     {
        data[x][y].clr.RGB.red=(byte)(picture->Bitmap->Canvas->Pixels[x][y] & 0xFF);               /* red value */
        data[x][y].clr.RGB.green=(byte)((picture->Bitmap->Canvas->Pixels[x][y] & 0xFF00) >> 8);    /* green value */
        data[x][y].clr.RGB.blue=(byte)((picture->Bitmap->Canvas->Pixels[x][y] & 0xFF0000) >> 16);  /* blue value */
        if (ColorMode==cmHSV) data[x][y].clr.HSV=RGB2HSV(data[x][y].clr.RGB);
        data[x][y].intensity=COLOR2GRAY(picture->Bitmap->Canvas->Pixels[x][y]);
     }
   return(1);
}

int ImageMatrix::LoadBMP(char *filename,int ColorMode)
{  TPicture *picture;
   int ret_val;
   picture = new TPicture;
   picture->LoadFromFile(filename);
   ret_val=LoadImage(picture,ColorMode);
   delete picture;
   return(ret_val);
}

#endif



/* LoadTIFF
   filename -char *- full path to the image file
*/
int ImageMatrix::LoadTIFF(char *filename)
{
#ifndef WIN32
   unsigned long h,w,x,y;
   unsigned short int spp,bps;
   TIFF *tif = NULL;
   //tdata_t buf;
   unsigned char *buf8;
   unsigned short *buf16;
   double max_val;
   
   if (tif = TIFFOpen(filename, "r"))
   {
     TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &w);
     width = w;
     TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &h);
     height = h;
     TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, &bps);
     bits=bps;
     TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL, &spp);

     /* allocate the data */
     data=new pix_data *[width];
     if (!data) return(0); /* memory allocation failed */
     for (x=0;x<width;x++)
     {  data[x]=new pix_data[height];
        if (!data[x]) return (0);   /* memory allocation failed */
     }

     max_val=pow(2,bits)-1;
     /* read TIFF header and determine image size */
     buf8 = (unsigned char *)_TIFFmalloc(TIFFScanlineSize(tif)*spp);
     buf16 = (unsigned short *)_TIFFmalloc(TIFFScanlineSize(tif)*sizeof(unsigned short)*spp);
 	 for (y = 0; y < height; y++)
	 {   int col;
	     if (bits==8) TIFFReadScanline(tif, buf8, y);
		 else TIFFReadScanline(tif, buf16, y);
	     x=0;col=0;
	 	 while (x<width)
		 { unsigned char byte_data;
		   unsigned short short_data;
		   double val;
		   int sample_index;	
		   for (sample_index=0;sample_index<spp;sample_index++)
		   {  byte_data=buf8[col+sample_index];
              short_data=buf16[col+sample_index];
 		      if (bits==8) val=(double)byte_data;
		      else val=(double)(short_data);
			  if (spp==3)  /* RGB image */
			  {  if (sample_index==0) data[x][y].clr.RGB.red=(unsigned char)(255*(val/max_val));
			     if (sample_index==1) data[x][y].clr.RGB.green=(unsigned char)(255*(val/max_val));
				 if (sample_index==2) data[x][y].clr.RGB.blue=(unsigned char)(255*(val/max_val));
			  }
		   }
		   if (spp==3) data[x][y].intensity=COLOR2GRAY(RGB2COLOR(data[x][y].clr.RGB));
		   if (spp==1)	  
           {  data[x][y].clr.RGB.red=(unsigned char)(255*(val/max_val));
              data[x][y].clr.RGB.green=(unsigned char)(255*(val/max_val));
              data[x][y].clr.RGB.blue=(unsigned char)(255*(val/max_val));
		      data[x][y].intensity=val;
		   }	  
		   x++;
		   col+=spp;
		 }
	 }
	 _TIFFfree(buf8);
	 _TIFFfree(buf16);
	 TIFFClose(tif);
   }
   else return(0);
#endif
   return(1);
}

/*  SaveTiff
    Save a matrix in TIFF format (16 bits per pixel)
*/
int ImageMatrix::SaveTiff(char *filename)
{
#ifndef WIN32
   int x,y;
   TIFF* tif = TIFFOpen(filename, "w");
   unsigned short *BufImage16 = new unsigned short[width*height];
   unsigned char *BufImage8 = new unsigned char[width*height];

   if (!tif) return(0);

   for (y = 0; y < height; y++)
     for (x = 0; x < width ; x++)
     {  if (bits==16) BufImage16[x + (y * width)] = (unsigned short)(data[x][y].intensity);
        else BufImage8[x + (y * width)] = (unsigned char)(data[x][y].intensity);
     }

   TIFFSetField(tif,TIFFTAG_IMAGEWIDTH, width);
   TIFFSetField(tif,TIFFTAG_IMAGELENGTH, height);
   TIFFSetField(tif, TIFFTAG_PLANARCONFIG,1);
   TIFFSetField(tif, TIFFTAG_PHOTOMETRIC, 1);
   TIFFSetField(tif, TIFFTAG_BITSPERSAMPLE, bits);
   TIFFSetField(tif, TIFFTAG_COMPRESSION, 1);

   for (y = 0; y < height; y ++)
   {  if (bits==16) TIFFWriteScanline (tif, &(BufImage16[y*width]), y,0 );
      else TIFFWriteScanline (tif, &(BufImage8[y*width]), y,0 );
   }

   TIFFClose(tif);
   delete BufImage8;
   delete BufImage16;
#endif
   return(1);
}

/* LoadPPM
   filename -char *- full path to the image file
*/

int ImageMatrix::LoadPPM(char *filename, int ColorMode)
{  FILE *fi;

   char ty[256],line[256],*p;
   byte *buffer;
   int x, y, m=-1;
   int w, h;

   fi=fopen(filename,"r");  /* open the file */
   if (!fi) return(0);
   /* PPM header */
   fgets(line,sizeof(line),fi);
   while (line[0]=='#') fgets(line,sizeof(line),fi);
   sscanf(line, "%s %d %d %d", ty, &w, &h, &m);
   if (m>255 || m<=0)
   {  fgets(line,sizeof(line),fi);
      while (line[0]=='#') fgets(line,sizeof(line),fi);
      sscanf(line, "%d %d %d", &w, &h, &m);
      if (m>255 || m<=0)
      {  fgets(line,sizeof(line),fi);
         while (line[0]=='#') fgets(line,sizeof(line),fi);
         sscanf(line, "%d", &m);
      }
   }

   /* allocate memory */
   bits=(unsigned short)ceil(log(m+1)/log(2));
   width=w;
   height=h;
   data=new pix_data *[width];
   if (!data) return(0); /* memory allocation failed */
   for (x=0;x<width;x++)
   {  data[x]=new pix_data[height];
      if (!data[x]) return (0);   /* memory allocation failed */
   }

   /* read the pixel data */
   int res,length,index=0;
   length=width*height;
   if (strcmp(ty, "P6") == 0) length=3*length;
   buffer=new byte[length];
   res=fread(buffer,sizeof(byte),length,fi);
   if (res==0) return(0);
   /* color image */
   if (strcmp(ty, "P6") == 0)
   {  for (y = 0; y < height; y++)
        for (x = 0; x < width; x++)
        {  data[x][y].clr.RGB.red=buffer[index++];
           data[x][y].clr.RGB.green=buffer[index++];
           data[x][y].clr.RGB.blue=buffer[index++];
           data[x][y].intensity=COLOR2GRAY(RGB2COLOR(data[x][y].clr.RGB));
           if (ColorMode==cmHSV) data[x][y].clr.HSV=RGB2HSV(data[x][y].clr.RGB);
        }
   }
   else
   /* greyscale image */
   if (strcmp(ty, "P5") == 0)
   {  for (y = 0; y < height; y++)
        for (x = 0; x < width; x++)
        {  data[x][y].clr.RGB.red=buffer[index];
           data[x][y].clr.RGB.green=buffer[index];
           data[x][y].clr.RGB.blue=buffer[index++];
           data[x][y].intensity=COLOR2GRAY(RGB2COLOR(data[x][y].clr.RGB));
           if (ColorMode==cmHSV) data[x][y].clr.HSV=RGB2HSV(data[x][y].clr.RGB);
        }
   }
   delete buffer;
   fclose(fi);
   return(1);
}

/* simple constructors */

ImageMatrix::ImageMatrix()
{
   data=NULL;
   width=0;
   height=0;
}

ImageMatrix::ImageMatrix(int width, int height)
{  int a,b;
   bits=8; /* set some default value */
   this->width=width;
   this->height=height;
   data=new pix_data *[width];
   for (a=0;a<width;a++)
   {  data[a]=new pix_data[height];
      for (b=0;b<height;b++)
        data[a][b].intensity=0;  /* initialize */
   }
}

/* create an image which is part of the image
   (x1,y1) - top left
   (x2,y2) - bottom right
*/
ImageMatrix::ImageMatrix(ImageMatrix *matrix,int x1, int y1, int x2, int y2)
{  int x,y;
   bits=matrix->bits;
   ColorMode=matrix->ColorMode;
   /* verify that the image size is OK */
   if (x1<0) x1=0;
   if (y1<0) y1=0;
   if (x2>=matrix->width) x2=matrix->width-1;
   if (y2>=matrix->height) y2=matrix->height-1;

   width=x2-x1;
   height=y2-y1;
   data=new pix_data *[width];
   for (x=0;x<width;x++)
     data[x]=new pix_data[height];
   for (y=y1;y<y1+height;y++)
     for (x=x1;x<x1+width;x++)
       data[x-x1][y-y1]=matrix->data[x][y];
}

/* free the memory allocated in "ImageMatrix::LoadImage" */
ImageMatrix::~ImageMatrix()
{  int a;
   if (data)
   {  for (a=0;a<width;a++)
        delete data[a];
      delete data;
   }
   data=NULL;
}

/* compute the difference from another image */
void ImageMatrix::diff(ImageMatrix *matrix)
{  int x,y;
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
     {  data[x][y].intensity=fabs(data[x][y].intensity-matrix->data[x][y].intensity);
        data[x][y].clr.RGB.red=abs(data[x][y].clr.RGB.red-matrix->data[x][y].clr.RGB.red);
        data[x][y].clr.RGB.green=abs(data[x][y].clr.RGB.green-matrix->data[x][y].clr.RGB.green);
        data[x][y].clr.RGB.blue=abs(data[x][y].clr.RGB.blue-matrix->data[x][y].clr.RGB.blue);
     }
}


/* duplicate
   create another matrix the same as the first
*/
ImageMatrix *ImageMatrix::duplicate()
{  ImageMatrix *new_matrix;
   int a,x,y;
   new_matrix=new ImageMatrix;
   new_matrix->data=new pix_data *[width];
   if (!(new_matrix->data)) return(NULL); /* memory allocation failed */
   for (a=0;a<width;a++)
   {  new_matrix->data[a]=new pix_data[height];
      if (!(new_matrix->data[a])) return (NULL);   /* memory allocation failed */
   }
   new_matrix->width=width;
   new_matrix->height=height;
   new_matrix->bits=bits;
   new_matrix->ColorMode=ColorMode;

   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
       new_matrix->data[x][y]=data[x][y];
  return(new_matrix);
}

/* to8bits
   convert a 16 bit matrix to 8 bits
*/
void ImageMatrix::to8bits()
{  int x,y;
   double max_val;
   if (bits==8) return;
   max_val=pow(2,bits)-1;
   bits=8;
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
       data[x][y].intensity=255*(data[x][y].intensity/max_val);
}

/* flip
   flip an image horizontaly
*/
void ImageMatrix::flip()
{  int x,y;
   pix_data temp;
   for (y=0;y<height;y++)
     for (x=0;x<width/2;x++)
	 { temp=data[x][y];
	   data[x][y]=data[width-x-1][y];
	   data[width-x-1][y]=temp;	   
	 }
}

/* Downsample
   down sample an image
   x_ratio, y_ratio -double- (0 to 1) the size of the new image comparing to the old one
*/
void ImageMatrix::Downsample(double x_ratio, double y_ratio)
{  double x,y,dx,dy,frac;
   int new_x,new_y,a;
   if (x_ratio>1) x_ratio=1;
   if (y_ratio>1) y_ratio=1;
   dx=1/x_ratio;
   dy=1/y_ratio;

   if (dx==1 && dy==1) return;   /* nothing to scale */

   /* first downsample x */
   for (new_y=0;new_y<height;new_y++)
   { x=0;
     new_x=0;
     while (x<width)
     {  double sum_i=0;
        double sum_r=0;
        double sum_g=0;
        double sum_b=0;

        /* the leftmost fraction of pixel */
        a=(int)(floor(x));
        frac=ceil(x)-x;
        if (frac>0 && a<width)
        {  sum_i+=data[a][new_y].intensity*frac;
           sum_r+=data[a][new_y].clr.RGB.red*frac;
           sum_g+=data[a][new_y].clr.RGB.green*frac;
           sum_b+=data[a][new_y].clr.RGB.blue*frac;
        }
        /* the middle full pixels */
        for (a=(int)(ceil(x));a<floor(x+dx);a=a+1)
        if (a<width)
        {  sum_i+=data[a][new_y].intensity;
           sum_r+=data[a][new_y].clr.RGB.red;
           sum_g+=data[a][new_y].clr.RGB.green;
           sum_b+=data[a][new_y].clr.RGB.blue;
        }
        /* the right fraction of pixel */
        frac=x+dx-floor(x+dx);
        if (frac>0 && a<width)
        {  sum_i+=data[a][new_y].intensity*frac;
           sum_r+=data[a][new_y].clr.RGB.red*frac;
           sum_g+=data[a][new_y].clr.RGB.green*frac;
           sum_b+=data[a][new_y].clr.RGB.blue*frac;
        }

        data[new_x][new_y].intensity=sum_i/(dx);
        data[new_x][new_y].clr.RGB.red=(byte)(sum_r/(dx));
        data[new_x][new_y].clr.RGB.green=(byte)(sum_g/(dx));
        data[new_x][new_y].clr.RGB.blue=(byte)(sum_b/(dx));

        x+=dx;
        new_x++;
     }
   }

   /* free the unedded memory to prevent a memory lick */
   for (a=(int)(width*x_ratio);a<width;a++)
     delete data[a];
   width=(int)(x_ratio*width);

   /* downsample y */
   for (new_x=0;new_x<width;new_x++)
   { y=0;
     new_y=0;
     while (y<height)
     {  double sum_i=0;
        double sum_r=0;
        double sum_g=0;
        double sum_b=0;

        a=(int)(floor(y));
        frac=ceil(y)-y;
        if (frac>0 && a<height)   /* take also the part of the leftmost pixel (if needed) */
        {  sum_i+=data[new_x][a].intensity*frac;
           sum_r+=data[new_x][a].clr.RGB.red*frac;
           sum_g+=data[new_x][a].clr.RGB.green*frac;
           sum_b+=data[new_x][a].clr.RGB.blue*frac;
        }
        for (a=(int)(ceil(y));a<floor(y+dy);a=a+1)
        if (a<height)
        {  sum_i+=data[new_x][a].intensity;
           sum_r+=data[new_x][a].clr.RGB.red;
           sum_g+=data[new_x][a].clr.RGB.green;
           sum_b+=data[new_x][a].clr.RGB.blue;
        }
        frac=y+dy-floor(y+dy);
        if (frac>0 && a<height)
        {  sum_i+=data[new_x][a].intensity*frac;
           sum_r+=data[new_x][a].clr.RGB.red*frac;
           sum_g+=data[new_x][a].clr.RGB.green*frac;
           sum_b+=data[new_x][a].clr.RGB.blue*frac;
        }

        data[new_x][new_y].intensity=sum_i/(dy);
        data[new_x][new_y].clr.RGB.red=(byte)(sum_r/(dy));
        data[new_x][new_y].clr.RGB.green=(byte)(sum_g/(dy));
        data[new_x][new_y].clr.RGB.blue=(byte)(sum_b/(dy));

        y+=dy;
        new_y++;
     }
   }
   height=(int)(y_ratio*height);
}


/* find basic intensity statistics */

int compare_doubles (const void *a, const void *b)
{
  if (*((double *)a) > *((double*)b)) return(1);
  if (*((double*)a) == *((double*)b)) return(0);
  return(-1);
}

/* BasicStatistics
   get basic statistical properties of the intensity of the image
   mean -double *- pre-allocated one double for the mean intensity of the image
   median -double *- pre-allocated one double for the median intensity of the image
   std -double *- pre-allocated one double for the standard deviation of the intensity of the image
   min -double *- pre-allocated one double for the minimum intensity of the image
   max -double *- pre-allocated one double for the maximal intensity of the image
   histogram -double *- a pre-allocated vector for the histogram. If NULL then histogram is not calculated
   nbins -int- the number of bins for the histogram
   
   if one of the pointers is NULL, the corresponding value is not computed.
*/
void ImageMatrix::BasicStatistics(double *mean, double *median, double *std, double *min, double *max, double *hist, int bins)
{  int x,y,pixel_index,num_pixels;
   double *pixels;
   double min1=INF,max1=-INF,mean_sum=0;
   
   num_pixels=height*width;
   pixels=new double[num_pixels];

   /* calculate the average, min and max */
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
     {  mean_sum+=data[x][y].intensity;
        if (data[x][y].intensity>max1)
          max1=data[x][y].intensity;
        if (data[x][y].intensity<min1)
          min1=data[x][y].intensity;
        pixels[y*width+x]=data[x][y].intensity;
     }
   if (max) *max=max1;	 
   if (min) *min=min1;
   if (mean) *mean=mean_sum/num_pixels;

   /* calculate the standard deviation */
   if (std)
   {  *std=0;
      for (pixel_index=0;pixel_index<num_pixels;pixel_index++)
        *std=*std+pow(pixels[pixel_index]-*mean,2);
      *std=sqrt(*std/(num_pixels-1));
   }
   
   if (hist)  /* do the histogram only if needed */
     histogram(hist,bins,0);

   /* find the median */
   if (median)
   {  qsort(pixels,num_pixels,sizeof(double),compare_doubles);
      *median=pixels[num_pixels/2];
   }

   delete pixels;
}

/* normalize the pixel values into a given range */
void ImageMatrix::normalize(double min, double max, int range)
{  int x,y;
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
     {  if (data[x][y].intensity<min) data[x][y].intensity=0;
	    else if (data[x][y].intensity>max) data[x][y].intensity=range;
	    else data[x][y].intensity=((data[x][y].intensity-min)/(max-min))*range;
	 }
}

/* concolve
*/
void ImageMatrix::convolve(ImageMatrix *filter)
{ int x,y,j;
  ImageMatrix *copy;
  int height2=filter->height/2;
  int width2=filter->width/2;
  double tmp;

  copy=duplicate();

    for(x=0;x<width;++x)
    {  for(y=0;y<height;++y)
       {
         tmp=0.0;
         for(int i=-width2;i<=width2;++i)
         {  int xx=x+i;
            if(xx<width && xx >= 0) {
            for(j=-height2;j<=height2;++j) {
              int yy=y+j;
              if(int(yy)>=0 && yy < height) {
                tmp+=filter->data[i+width2][j+height2].intensity*copy->data[xx][yy].intensity;
              }
            }
          }
        }
        data[x][y].intensity=tmp;
      }
    }
  delete copy;
}

/* find the basic color statistics
   hue_avg -double *- average hue
   hue_std -double *- standard deviation of the hue
   sat_avg -double *- average saturation
   sat_std -double *- standard deviation of the saturation
   val_avg -double *- average value
   val_std -double *- standard deviation of the value
   max_color -double *- the most popular color
   colors -double *- a histogram of colors
   if values are NULL - the value is not computed
*/

void ImageMatrix::GetColorStatistics(double *hue_avg, double *hue_std, double *sat_avg, double *sat_std, double *val_avg, double *val_std, double *max_color, double *colors)
{  int x,y,a,color_index;
   color hsv;
   double max,pixel_num;
   float certainties[COLORS_NUM];

   pixel_num=height*width;

   /* calculate the average hue, saturation, value */
   if (hue_avg) *hue_avg=0;
   if (sat_avg) *sat_avg=0;
   if (val_avg) *val_avg=0;
   if (colors)
     for (a=0;a<COLORS_NUM;a++)
       colors[a]=0;

   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
     {  hsv=data[x][y].clr;
        if (hue_avg) *hue_avg+=hsv.HSV.hue;
        if (sat_avg) *sat_avg+=hsv.HSV.saturation;
        if (val_avg) *val_avg+=hsv.HSV.value;
         color_index=FindColor(hsv.HSV.hue,hsv.HSV.saturation,hsv.HSV.value,certainties);
//         data[x][y].classified_color=(byte)color_index;
         colors[color_index]+=1;
     }
   *hue_avg=*hue_avg/pixel_num;
   *sat_avg=*sat_avg/pixel_num;
   *val_avg=*val_avg/pixel_num;

   /* max color (the most common color in the image) */
   if (max_color)
   {  *max_color=0;
      max=0.0;
      for (a=0;a<COLORS_NUM;a++)
        if (colors[a]>max)
        {  max=colors[a];
           *max_color=a;
        }
   }
   /* colors */
   if (colors)
     for (a=0;a<COLORS_NUM;a++)
       colors[a]=colors[a]/pixel_num;

   /* standard deviation of hue, saturation and value */
   if (hue_std) *hue_std=0;
   if (sat_std) *sat_std=0;
   if (val_std) *val_std=0;
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
     {  hsv=data[x][y].clr;
        if (hue_std && hue_avg) *hue_std+=pow(hsv.HSV.hue-*hue_avg,2);
        if (sat_std && sat_avg) *sat_std+=pow(hsv.HSV.saturation-*sat_avg,2);
        if (val_std && val_avg) *val_std+=pow(hsv.HSV.value-*val_avg,2);
     }
   if (hue_std && hue_avg) *hue_std=sqrt(*hue_std/pixel_num);
   if (sat_std && sat_avg) *sat_std=sqrt(*sat_std/pixel_num);
   if (val_std && val_avg) *val_std=sqrt(*val_std/pixel_num);
}

/* ColorTransform
   Finds the closest color to the given RGB triple
   and transforms all the pixels that have a different
   color to black.
*/
void ImageMatrix::ColorTransform(RGBcolor rgb)
{  int x,y,base_color;
   HSVcolor hsv;
   color hsv_pixel;
   float certainties[COLORS_NUM];
   hsv=RGB2HSV(rgb);
   base_color=FindColor(hsv.hue,hsv.saturation,hsv.value,certainties);
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
     {  int color_index;
        hsv_pixel=data[x][y].clr;
        color_index=FindColor(hsv_pixel.HSV.hue,hsv_pixel.HSV.saturation,hsv_pixel.HSV.value,certainties);
        if (color_index!=base_color)
        {  data[x][y].clr.HSV.hue=0;
           data[x][y].clr.HSV.saturation=0;
           data[x][y].clr.HSV.value=0;
           data[x][y].intensity=0;
        }
     }
}

/* get image histogram */
void ImageMatrix::histogram(double *bins,unsigned short bins_num, int imhist)
{  int x,y;
   double min=INF,max=-INF;

   /* find the minimum and maximum */
   if (imhist==1)
   {  min=0;
      max=pow(2,bits)-1;
   }
   else
   {  for (y=0;y<height;y++)
       for (x=0;x<width;x++)
       {  if (data[x][y].intensity>max)
            max=data[x][y].intensity;
          if (data[x][y].intensity<min)
            min=data[x][y].intensity;
       }
   }

   /* initialize the bins */
   for (x=0;x<bins_num;x++)
     bins[x]=0;

   /* build the histogram */
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
     { if (data[x][y].intensity==max) bins[bins_num-1]+=1;
       else bins[(int)(((data[x][y].intensity-min)/(max-min))*bins_num)]+=1;
     }

}

/* fft 2 dimensional transform */
// http://www.fftw.org/doc/
double ImageMatrix::fft2()
{  fftw_complex *out;
   double *in;
   fftw_plan p;
   int x,y,half_height;

   in = (double*) fftw_malloc(sizeof(double) * width*height);
   out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * width*height);


   p=fftw_plan_dft_r2c_2d(width,height,in,out, FFTW_MEASURE /* FFTW_ESTIMATE */);

   for (x=0;x<width;x++)
     for (y=0;y<height;y++)
       in[height*x+y]=data[x][y].intensity;

   fftw_execute(p); /* execute the transformation (repeat as needed) */

   half_height=height/2+1;   /* (to 56 including 56 ) */
   /* find the abs and angle */
   for (x=0;x<width;x++)
     for (y=0;y<half_height;y++)
        data[x][y].intensity=sqrt(pow(out[half_height*x+y][0],2)+pow(out[half_height*x+y][1],2));    /* sqrt(real(X).^2 + imag(X).^2) */

   /* complete the first column */
   for (y=half_height;y<height;y++)
     data[0][y].intensity=data[0][height-y].intensity;

   /* complete the rows */
   for (y=half_height;y<height;y++)
     for (x=1;x<width;x++)   /* 1 because the first column is already completed */
       data[x][y].intensity=data[width-x][height-y].intensity;

   fftw_destroy_plan(p);
   fftw_free(in);
   fftw_free(out);

   /* calculate the magnitude and angle */

   return(0);
}

/* chebyshev transform */
void ImageMatrix::ChebyshevTransform(int N)
{  double *out;
   int x,y,old_width;

   if (N<2) N=min(width,height);
   out=new double[height*N];
   Chebyshev(this, out,N);

   old_width=width;  /* keep the old width to free the memory */
   width=N;
   height=min(height,N);   /* prevent error */

   for(y=0;y<height;y++)
     for(x=0;x<width;x++)
       data[x][y].intensity=out[y*width+x];
   delete out;

   /* free the unneeded memory (to prevent memory lick) */
   for (x=width;x<old_width;x++)
     delete data[x];
}

/* chebyshev transform
   coeff -array of double- a pre-allocated array of 32 doubles
*/
void ImageMatrix::ChebyshevFourierTransform(double *coeff)
{
   ChebyshevFourier(this, 0, coeff,32);
}


/* Symlet5 transform */
void ImageMatrix::Symlet5Transform()
{  int x,y;
   DataGrid2D *grid;
   Symlet5 *Sym5;

   grid = new DataGrid2D(width,height,-1);
   for (y=0;y<height;y++)
     for(x=0;x<width;x++)
       grid->setData(x,y,-1,data[x][y].intensity);
   Sym5=new Symlet5(0,1);
   Sym5->transform2D(grid);

   /* free the old memory of the matrix */
   for (x=0;x<width;x++)
     delete data[x];
   delete data;
   /* allocate new memory (new dimensions) and copy the values */
   width=grid->getX();
   height=grid->getY();
   data=new pix_data*[width];
   for (x=0;x<width;x++)
   {  data[x]=new pix_data[height];
      for (y=0;y<height;y++)
        data[x][y].intensity=grid->getData(x,y,-1);  /* initialize */
   }

   delete Sym5;
   delete grid;
}

/* chebyshev statistics
   coeff -array of double- pre-allocated memory of 20 doubles
   nibs_num - (32 is normal)
*/
void ImageMatrix::ChebyshevStatistics(double *coeff, int N, int bins_num)
{
   if (N<2) N=20;
   ChebyshevTransform(N);
   histogram(coeff,bins_num,0);
}

/* CombFirstFourMoments
   vec should be pre-alocated array of 48 doubles
*/
int ImageMatrix::CombFirstFourMoments(double *vec)
{  int count;
   ImageMatrix *matrix;
   if (bits==16) 
   {  matrix=this->duplicate();
      matrix->to8bits();
   }
   else matrix=this;
   count=CombFirst4Moments(matrix, vec);   
   vd_Comb4Moments(vec);   
   if (bits==16) delete matrix;
   return(count);
}

/* Edge Transform */
void ImageMatrix::EdgeTransform()
{  int x,y;
   ImageMatrix *TempMatrix;
   TempMatrix=duplicate();
   for (y=0;y<TempMatrix->height;y++)
     for (x=0;x<TempMatrix->width;x++)
     {  double max_x=0,max_y=0;
        if (y>0 && y<height-1) max_y=max(fabs(TempMatrix->data[x][y].intensity-TempMatrix->data[x][y-1].intensity),fabs(TempMatrix->data[x][y].intensity-TempMatrix->data[x][y+1].intensity));
        if (x>0 && x<width-1) max_x=max(fabs(TempMatrix->data[x][y].intensity-TempMatrix->data[x-1][y].intensity),fabs(TempMatrix->data[x][y].intensity-TempMatrix->data[x+1][y].intensity));
        data[x][y].intensity=max(max_x,max_y);
     }

   /* use otsu global threshold to set edges to 0 or 1 */
   double OtsuGlobalThreshold,max_val;
   max_val=pow(2,bits)-1;
   OtsuGlobalThreshold=Otsu();
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
       if (data[x][y].intensity>OtsuGlobalThreshold*max_val) data[x][y].intensity=max_val;
       else data[x][y].intensity=0;

   delete TempMatrix;
}

/* transform by gradient magnitude */
void ImageMatrix::GradientMagnitude(int span)
{  int x,y,i,j;
   double sumx,sumy;
   if (span==0) span=2;  /* make sure 0 is not a default */
   for (x=0;x<width-span;x++)
     for (y=0;y<height-span;y++)
       data[x][y].intensity=sqrt(pow(data[x+span][y].intensity-data[x][y].intensity,2)+pow(data[x][y+span].intensity-data[x][y].intensity,2));
}

/* transform by gradient direction */
void ImageMatrix::GradientDirection(int span)
{  int x,y;
   if (span==0) span=2;  /* make sure 0 is not a default */
   for (x=0;x<width-span;x++)
     for (y=0;y<height-span;y++)
     {  if (data[x][y+span].intensity-data[x][y].intensity==0)
          data[x][y].intensity=0;
        else
          data[x][y].intensity=atan2(data[x+span][y].intensity-data[x][y].intensity,data[x][y+span].intensity-data[x][y].intensity);
     }
}

/* Perwitt gradient magnitude
   output - a pre-allocated matrix that will hold the output (the input matrix is not changed)
            output should be of the same size as the input matrix
*/
void ImageMatrix::PerwittMagnitude(ImageMatrix *output)
{  int x,y,i,j;
   double sumx,sumy;
   for (x=0;x<width;x++)
     for (y=0;y<height;y++)
     {  sumx=0;
        sumy=0;
        for (j=y-1;j<=y+1;j++)
          if (j>=0 && j<height && x-1>=0)
             sumx+=data[x-1][j].intensity*1;//0.3333;
        for (j=y-1;j<=y+1;j++)
          if (j>=0 && j<height && x+1<width)
            sumx+=data[x+1][j].intensity*-1;//-0.3333;
        for (i=x-1;i<=x+1;i++)
          if (i>=0 && i<width && y-1>=0)
            sumy+=data[i][y-1].intensity*1;//-0.3333;
        for (i=x-1;i<=x+1;i++)
          if (i>=0 && i<width && y+1<height)
            sumy+=data[i][y+1].intensity*-1;//0.3333;
        output->data[x][y].intensity=sqrt(sumx*sumx+sumy*sumy);
     }
}

/* Perwitt gradient direction
   output - a pre-allocated matrix that will hold the output (the input matrix is not changed)
            output should be of the same size as the input matrix
*/
void ImageMatrix::PerwittDirection(ImageMatrix *output)
{  int x,y,i,j;
   double sumx,sumy;
   for (x=0;x<width;x++)
     for (y=0;y<height;y++)
     {  sumx=0;
        sumy=0;
        for (j=y-1;j<=y+1;j++)
          if (j>=0 && j<height && x-1>=0)
             sumx+=data[x-1][j].intensity*1;//0.3333;
        for (j=y-1;j<=y+1;j++)
          if (j>=0 && j<height && x+1<width)
            sumx+=data[x+1][j].intensity*-1;//-0.3333;
        for (i=x-1;i<=x+1;i++)
          if (i>=0 && i<width && y-1>=0)
            sumy+=data[i][y-1].intensity*1;//-0.3333;
        for (i=x-1;i<=x+1;i++)
          if (i>=0 && i<width && y+1<height)
            sumy+=data[i][y+1].intensity*-1;//0.3333;
        if (sumy==0 || fabs(sumy)<1/INF) output->data[x][y].intensity=3.1415926*(sumx<0);
        else output->data[x][y].intensity=atan2(sumy,sumx);
     }
}


/* edge statistics */
//#define NUM_BINS 8
//#define NUM_BINS_HALF 4
/* EdgeArea -long- number of edge pixels
   MagMean -double- mean of the gradient magnitude
   MagMedian -double- median of the gradient magnitude
   MagVar -double- variance of the gradient magnitude
   MagHist -array of double- histogram of the gradient magnitude. array of size "num_bins" should be allocated before calling the function
   DirecMean -double- mean of the gradient direction
   DirecMedian -double- median of the gradient direction
   DirecVar -double- variance of the gradient direction
   DirecHist -array of double- histogram of the gradient direction. array of size "num_bins" should be allocated before calling the function
   DirecHomogeneity -double-
   DiffDirecHist -array of double- array of size num_bins/2 should be allocated
*/

void ImageMatrix::EdgeStatistics(long *EdgeArea, double *MagMean, double *MagMedian, double *MagVar, double *MagHist, double *DirecMean, double *DirecMedian, double *DirecVar, double *DirecHist, double *DirecHomogeneity, double *DiffDirecHist, int num_bins)
{  ImageMatrix *GradientMagnitude,*GradientDirection;
   int x,y,bin_index;
   double min,max,sum,max_intensity;
   
   max_intensity=pow(bits,2)-1;
   
   GradientMagnitude=duplicate();
   PerwittMagnitude(GradientMagnitude);
   GradientDirection=duplicate();
   PerwittDirection(GradientDirection);

   /* find gradient statistics */
   GradientMagnitude->BasicStatistics(MagMean, MagMedian, MagVar, &min, &max, MagHist, num_bins);
   *MagVar=pow(*MagVar,2);

   /* find the edge area (number of edge pixels) */
   *EdgeArea=0;
//   level=min+(max-min)/2;   // level=duplicate->OtsuBinaryMaskTransform()   // level=MagMean

   for (y=0;y<GradientMagnitude->height;y++)
     for (x=0;x<GradientMagnitude->width;x++)
        if (GradientMagnitude->data[x][y].intensity>max_intensity*0.5) (*EdgeArea)+=1; /* find the edge area */
//   GradientMagnitude->OtsuBinaryMaskTransform();

   /* find direction statistics */
   GradientDirection->BasicStatistics(DirecMean, DirecMedian, DirecVar, &min, &max, DirecHist, num_bins);
   *DirecVar=pow(*DirecVar,2);

   /* Calculate statistics about edge difference direction
      Histogram created by computing differences amongst histogram bins at angle and angle+pi */
   for (bin_index=0;bin_index<(int)(num_bins/2);bin_index++)
      DiffDirecHist[bin_index]=fabs(DirecHist[bin_index]-DirecHist[bin_index+(int)(num_bins/2)]);
   sum=0;
   for (bin_index=0;bin_index<(int)(num_bins/2);bin_index++)
   {  DiffDirecHist[bin_index]=DiffDirecHist[bin_index]/(DirecHist[bin_index]+DirecHist[bin_index+(int)(num_bins/2)]);
      sum+=(DirecHist[bin_index]+DirecHist[bin_index+(int)(num_bins/2)]);
   }

   /* The fraction of edge pixels that are in the first two bins of the histogram measure edge homogeneity */
   *DirecHomogeneity = (DirecHist[0]+DirecHist[1])/sum;

   delete GradientMagnitude;
   delete GradientDirection;
}

/* radon transform
   vec -array of double- output column. a pre-allocated vector of the size 3*4=12
*/
void ImageMatrix::RadonTransform(double *vec)
{   int x,y,val_index,output_size,vec_index,bin_index;
    double *pixels,*ptr,bins[3];
    int angle,num_angles=4;
    double theta[4]={0,45,90,135};
    double min,max;
    int rLast,rFirst;
    rLast = (int) ceil(sqrt(pow(width-1-(width-1)/2,2)+pow(height-1-(height-1)/2,2))) + 1;
    rFirst = -rLast;
    output_size=rLast-rFirst+1;

    ptr=new double[output_size*num_angles];
    for (val_index=0;val_index<output_size*num_angles;val_index++)
      ptr[val_index]=0;  /* initialize the output vector */

    pixels=new double[width*height];
    vec_index=0;

    for (x=0;x<width;x++)
      for (y=0;y<height;y++)
        pixels[y+height*x]=data[x][y].intensity;

    radon(ptr,pixels, theta, height, width, (width-1)/2, (height-1)/2, num_angles, rFirst, output_size);

    for (angle=0;angle<num_angles;angle++)
    {  //radon(ptr,pixels, &theta, height, width, (width-1)/2, (height-1)/2, 1, rFirst, output_size);
       /* create histogram */
       double min=INF,max=-INF;
       /* find the minimum and maximum values */
       for (val_index=angle*output_size;val_index<(angle+1)*output_size;val_index++)
       {  if (ptr[val_index]>max) max=ptr[val_index];
          if (ptr[val_index]<min) min=ptr[val_index];
       }

       for (val_index=0;val_index<3;val_index++)   /* initialize the bins */
         bins[val_index]=0;
       for (val_index=angle*output_size;val_index<(angle+1)*output_size;val_index++)
         if (ptr[val_index]==max) bins[2]+=1;
         else bins[(int)(((ptr[val_index]-min)/(max-min))*3)]+=1;

       for (bin_index=0;bin_index<3;bin_index++)
         vec[vec_index++]=bins[bin_index];
    }
    vd_RadonTextures(vec);
    delete pixels;
    delete ptr;
}

//-----------------------------------------------------------------------------------
/* Otsu
   Find otsu threshold
*/
double ImageMatrix::Otsu()
{  int a,x,y;
   double hist[256],omega[256],mu[256],sigma_b2[256],maxval=-INF,sum,count;
   double max=pow(2,bits)-1;
   histogram(hist,256,1);
   omega[0]=hist[0]/(width*height);
   mu[0]=1*hist[0]/(width*height);
   for (a=1;a<256;a++)
   {  omega[a]=omega[a-1]+hist[a]/(width*height);
      mu[a]=mu[a-1]+(a+1)*hist[a]/(width*height);
   }
   for (a=0;a<256;a++)
   {  if (omega[a]==0 || 1-omega[a]==0)
         sigma_b2[a]=0;
      else sigma_b2[a]=pow(mu[255]*omega[a]-mu[a],2)/(omega[a]*(1-omega[a]));
      if (sigma_b2[a]>maxval) maxval=sigma_b2[a];
   }
   sum=0.0;
   count=0.0;
   for (a=0;a<256;a++)
     if (sigma_b2[a]==maxval)
     {  sum+=a;
        count++;
     }
   return((pow(2,bits)/256.0)*((sum/count)/max));
}

//-----------------------------------------------------------------------------------
/*
  OtsuBinaryMaskTransform
  Transforms an image to a binary image such that the threshold is otsu global threshold
*/
double ImageMatrix::OtsuBinaryMaskTransform()
{  int x,y;
   double OtsuGlobalThreshold;
   double max=pow(2,bits)-1;

   OtsuGlobalThreshold=Otsu();

   /* classify the pixels by the threshold */
   for (y=0;y<height;y++)
     for (x=0;x<width;x++)
       if (data[x][y].intensity>OtsuGlobalThreshold*max)   // (data[x][y].intensity-min)/(max-min)
         data[x][y].intensity=1;
       else data[x][y].intensity=0;

//   delete pixels;
   return(OtsuGlobalThreshold);
}

/*  BWlabel
    label groups of connected pixel (4 or 8 connected dependes on the value of the parameter "level").
    This is an implementation of the Matlab function bwlabel
    returned value -int- the number of objects found
*/
//--------------------------------------------------------
int ImageMatrix::BWlabel(int level)
{
   return(bwlabel(this,level));
}

//--------------------------------------------------------

void ImageMatrix::centroid(double *x_centroid, double *y_centroid)
{
   GlobalCentroid(this,x_centroid,y_centroid);
}

//--------------------------------------------------------

/*
  FeatureStatistics
  Find feature statistics. Before calling this function the image should be transformed into a binary
  image using "OtsuBinaryMaskTransform".

  count -int *- the number of objects detected in the binary image
  Euler -int *- the euler number (number of objects - number of holes
  centroid_x -int *- the x coordinate of the centroid of the binary image
  centroid_y -int *- the y coordinate of the centroid of the binary image
  AreaMin -int *- the smallest area
  AreaMax -int *- the largest area
  AreaMean -int *- the mean of the areas
  AreaMedian -int *- the median of the areas
  AreaVar -int *- the variance of the areas
  DistMin -int *- the smallest distance
  DistMax -int *- the largest distance
  DistMean -int *- the mean of the distance
  DistMedian -int *- the median of the distances
  DistVar -int *- the variance of the distances

*/

int compare_ints (const void *a, const void *b)
{
  if (*((int *)a) > *((int *)b)) return(1);
  if (*((int *)a) == *((int *)b)) return(0);
  return(-1);
}

void ImageMatrix::FeatureStatistics(int *count, int *Euler, double *centroid_x, double *centroid_y, int *AreaMin, int *AreaMax,
                                    double *AreaMean, int *AreaMedian, double *AreaVar, int *area_histogram,double *DistMin, double *DistMax,
                                    double *DistMean, double *DistMedian, double *DistVar, int *dist_histogram, int num_bins)
{  int object_index;
   double sum_areas,sum_dists;
   ImageMatrix *BWImage;
   int *object_areas;
   double *centroid_dists,sum_dist;

   BWImage=duplicate();
   BWImage->OtsuBinaryMaskTransform();
   BWImage->centroid(centroid_x,centroid_y);
   *count=BWImage->BWlabel(8);
   *Euler=EulerNumber(BWImage,*count)+1;

   /* calculate the areas */
   sum_areas=0;
   sum_dists=0;
   object_areas=new int[*count];
   centroid_dists=new double[*count];
   for (object_index=1;object_index<=*count;object_index++)
   {  double x_centroid,y_centroid;
      object_areas[object_index-1]=FeatureCentroid(BWImage, object_index, &x_centroid, &y_centroid);
      centroid_dists[object_index-1]=sqrt(pow(x_centroid-(*centroid_x),2)+pow(y_centroid-(*centroid_y),2));
      sum_areas+=object_areas[object_index-1];
      sum_dists+=centroid_dists[object_index-1];
   }
   /* compute area statistics */
   qsort(object_areas,*count,sizeof(int),compare_ints);
   *AreaMin=object_areas[0];
   *AreaMax=object_areas[*count-1];
   if (count>0) *AreaMean=sum_areas/(*count);
   else *AreaMean=0;
   *AreaMedian=object_areas[(*count)/2];
   for (object_index=0;object_index<num_bins;object_index++)
     area_histogram[object_index]=0;
   /* compute the variance and the histogram */
   sum_areas=0;
   for (object_index=1;object_index<=*count;object_index++)
   {  sum_areas+=pow(object_areas[object_index-1]-*AreaMean,2);
      if (object_areas[object_index-1]==*AreaMax) area_histogram[num_bins-1]+=1;
      else area_histogram[((object_areas[object_index-1]-*AreaMin)/(*AreaMax-*AreaMin))*num_bins]+=1;
   }
   if (*count>1) *AreaVar=sum_areas/((*count)-1);
   else *AreaVar=sum_areas;

   /* compute distance statistics */
   qsort(centroid_dists,*count,sizeof(double),compare_doubles);
   *DistMin=centroid_dists[0];
   *DistMax=centroid_dists[*count-1];
   if (count>0) *DistMean=sum_dists/(*count);
   else *DistMean=0;
   *DistMedian=centroid_dists[(*count)/2];
   for (object_index=0;object_index<num_bins;object_index++)
     dist_histogram[object_index]=0;

   /* compute the variance and the histogram */
   sum_dist=0;
   for (object_index=1;object_index<=*count;object_index++)
   {  sum_dist+=pow(centroid_dists[object_index-1]-*DistMean,2);
      if (centroid_dists[object_index-1]==*DistMax) dist_histogram[num_bins-1]+=1;
      else dist_histogram[(int)(((centroid_dists[object_index-1]-*DistMin)/(*DistMax-*DistMin))*num_bins)]+=1;
   }
   if (*count>1) *DistVar=sum_dist/((*count)-1);
   else *DistVar=sum_dist;

   delete BWImage;
   delete object_areas;
   delete centroid_dists;
}

/* GaborFilters */
/* ratios -array of double- a pre-allocated array of double[7]
*/
void ImageMatrix::GaborFilters(double *ratios)
{  GaborTextureFilters(this, ratios);
}


/* haarlick
   output -array of double- a pre-allocated array of 28 doubles
*/
void ImageMatrix::HaarlickTexture(double distance, double *out)
{  if (distance<=0) distance=1;
   haarlick(this,distance,out);
}

/* MultiScaleHistogram
   histograms into 3,5,7,9 bins
   Function computes signatures based on "multiscale histograms" idea.
   Idea of multiscale histogram came from the belief of a unique representativity of an
   image through infinite series of histograms with sequentially increasing number of bins.
   Here we used 4 histograms with number of bins being 3,5,7,9.
   out -array of double- a pre-allocated array of 24 bins
*/
void ImageMatrix::MultiScaleHistogram(double *out)
{  int a;
   double max=0;
   histogram(out,3,0);
   histogram(&(out[3]),5,0);
   histogram(&(out[8]),7,0);
   histogram(&(out[15]),9,0);
   for (a=0;a<24;a++)
     if (out[a]>max) max=out[a];
   for (a=0;a<24;a++)
     out[a]=out[a]/max;
}

/* TamuraTexture
   Tamura texture signatures: coarseness, directionality, contrast
   vec -array of double- a pre-allocated array of 6 doubles
*/
void ImageMatrix::TamuraTexture(double *vec)
{
  Tamura3Sigs(this,vec);
}

/* zernike
   zvalue -array of double- a pre-allocated array of double of a suficient size
                            (the actual size is returned by "output_size))
   output_size -* long- the number of enteries in the array "zvalues" (normally 72)
*/
void ImageMatrix::zernike(double *zvalues, long *output_size)
{  mb_zernike(this, 0, 0, zvalues, output_size);
}

/*
double radon(ImageMatrix *image, double p, double tau)
//function radon,image,p,tau,all_rays=all_rays,raylen = raylen
{ int a,xl,yl;
  double *x,*y;
//if  n_params() lt 1 then return,-1
//sz = size(image)
//if sz(0) ne 2 then return,-1
//xl = sz(1)
//yl = sz(2)
  xl=width;
  yl=height;
//x = findgen(xl)-xl/2
//y = findgen(yl)
  x=new double[xl];
  y-new double[yl];
  max_abs_x=-100000000;
  x_min=10000000;
  for (a=0;a<xl;a++)
  {  x[a]=(double)a-xl/2;
     if (x[a]>max_abs_x) max_abs_x=x[a];
     if (x[a]<x_min) x_min=x[a];
  }
  y_min=100000000;
  for (a=0;a<y1;a++)
  {  y[a]=(double)a;
     if (Y[a]<y_min) y_min=Y[a];
  }

  kl=xl;
  hl=yl;
  ml=xl;
  nl=yl;
  delta_x = delta_y=1;
// p = (findgen(kl)/(kl-1)*kl-(kl)/2)*delta_y/max(abs(x))
  for (a=0;a<kl;a++)
    p[a]=(a/(kl-1)*kl-kl/2)*delta_y/max_abs_x;


tau = findgen(hl)*delta_y
alpha = p * delta_x/delta_y

g_radon  =  fltarr(kl,hl)
raylen   =  fltarr(kl,hl)
all_rays =  fltarr(kl,hl,xl > yl)

for k = 0,kl-1 do begin
 for h = 0,hl-1 do begin
  beta = (p(k)*x_min+tau(h) - y_min)/delta_y
  if alpha(k) gt 0 then begin
    m_min = 0 > ceil((-beta)/alpha(k))
    m_max = ml - 1 < floor((nl-1-beta)/alpha(k))
  endif else begin
    m_min = 0 > ceil((nl-1-beta)/alpha(k))
    m_max = ml - 1 < floor((-beta)/alpha(k))
  endelse
  sum=0
  mv = findgen(m_max-m_min+1)+m_min
  nfloatv = (alpha(k)*mv+beta)
  wneg = where(nfloatv lt 0.0,wnegcount)
  wre = where(abs(nfloatv) lt 0.01,wrecount)
  if wrecount gt 0 then nfloatv(wre) = 0
  nv = floor(nfloatv)
  wv = nfloatv-nv
  sum = 0
  if max(nfloatv) gt nl-1 then stop ;this is an error in indexing
  wno = where(wv eq 0,wnocount)
  inray = fltarr(n_elements(mv))
  if wnocount gt 0 then begin
   inray(wno) = image(mv(wno),nv(wno))
   wint = where(wv ne 0,wintcount)
   if wintcount gt 0 then begin

inray(wint)=image(mv(wint),nv(wint))*(1-wv)+image(mv(wint),nv(wint)+1)*wv
   endif
  endif else inray = image(mv,nv)*(1-wv)+image(mv,nv)*wv
  g_radon(k,h) = delta_x*(mean(inray))
  raylen(k,h) =n_elements(inray)
  all_rays(k,h,0:raylen(k,h)-1) = inray
 endfor
endfor


return,g_radon

  delete x,y;
}

;__________________________________________________
;__________________________________________________
; test code here


xl=(yl=100)
image = fltarr(xl,yl)

;slope=-0.8
;offset = 0
slope= (randomu(seed,1))(0)*2-1
offset = (randomu(seed,1))(0)*xl

line = 10
for i = 0,yl-1 do begin
  yind = slope*(i-xl/2)+offset
  if yind ge 0 and yind lt yl then $
   image(i,yind) = image(i,yind) + line
endfor

image=smooth(image,5)
image = image+randomn(seed,xl,yl)

g_radon = radon(image,p,tau,all_rays=all_rays,raylen=raylen)

wm = wheremax(g_radon)
print
print,'Actual Values for slope and y offset:......... P=',slope,  '    Tau =
: ',offset
print,'Measured slope and offset from radon transform: P=',p(wm(0)),'    Tau
= : ',tau(wm(1))
print,'value at peak of radon transform= ',g_radon(wm(0),wm(1))


!P.multi=[0,1,3]
!P.charsize=2
fill=1
contour,image,fill=fill,tit='Image (line + noise)',xtit='X',ytit='Y'
axis,xl/2,/data,yaxis=1
contour,g_radon,p,tau,tit='Radon
Transform',fill=fill,nlevels=21,xtit='Slope',ytit='Y Offset'
surface,g_radon,p,tau,tit='Radon Transform',xtit='Slope',ytit='Y Offset'


end

*/

#pragma package(smart_init)




