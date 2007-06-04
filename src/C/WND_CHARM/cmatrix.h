//---------------------------------------------------------------------------
#ifndef cmatrixH
#define cmatrixH
//---------------------------------------------------------------------------

#ifdef WIN32
  #include <vcl.h>
#else  
  #include "colors/FuzzyCalc.h"
  #define min(a,b) (((a) < (b)) ? (a) : (b))
  #define max(a,b) (((a) < (b)) ? (b) : (a))
#endif
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                                                                               */
/* Copyright (C) 2003 Open Microscopy Environment                                */
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


#define cmRGB 1
#define cmHSV 2

#define INF 10E20

#define COLOR_NUM 19

typedef unsigned char byte;

typedef struct RGBCOLOR
{  byte red,green,blue;
}RGBcolor;

typedef struct HSVCOLOR
{  byte hue,saturation,value;
}HSVcolor;

typedef union
{  RGBcolor RGB;
   HSVcolor HSV;
}color;

//typedef struct FFT
//{  float abs;
//   float angle;
//}fft;

typedef struct PIX_DATA
{  color clr;
//   byte classified_color;  /* the color classification of clr     */
//   byte prob;       /* normailized to (0,255) interval */
   double intensity;  /* normailized to (0,255) interval */
//   byte stddev;     /* stddev of the intensity normailized to (0,255) interval */
//   byte tag;
} pix_data;


class ImageMatrix
{
  private:
  public:
   int ColorMode;                                  /* can be cmRGB or cmHSV                */
   pix_data **data;                                /* data of the colors                   */
   unsigned short bits;                            /* the number of intensity bits (8,16, etc) */
   int width,height;                               /* width and height of the picture      */
   double average;                                 /* average hue */
   double stddev;                                  /* stddev hue  */
#ifdef WIN32   
   int LoadImage(TPicture *picture,int ColorMode);
   int LoadBMP(char *filename,int ColorMode);      /* load from a bitmap file              */
#endif
   int LoadTIFF(char *filename);                   /* load from TIFF file                  */
   int LoadPPM(char *filename, int ColorMode);     /* load from a PPM file                 */
   ImageMatrix();                                  /* basic constructor                    */
   ImageMatrix(int width,int height);              /* construct a new empty matrix         */
   ImageMatrix(ImageMatrix *matrix,int x1, int y1, int x2, int y2);  /* creat a new matrix which is part of the original one */
   ~ImageMatrix();                                 /* destructor */   
   ImageMatrix *duplicate();                       /* create a new identical matrix        */
   void diff(ImageMatrix *matrix);                 /* compute the difference from another image */
   void BasicStatistics(double *mean, double *median, double *std, double *min, double *max, double *histogram, int bins);
   void normalize(double min, double max, int range);
   void Downsample(double x_ratio, double y_ratio);
   void convolve(ImageMatrix *filter);
   void GetColorStatistics(double *hue_avg, double *hue_std, double *sat_avg, double *sat_std, double *val_avg, double *val_std, double *max_color, double colors[COLOR_NUM]);
   void ColorTransform(RGBcolor rgb);
   void histogram(double *bins,unsigned short bins_num, int imhist);
   double Otsu();                                  /* Otsu grey threshold                  */
   void MultiScaleHistogram(double *out);
//   double AverageEdge();
   void EdgeTransform();
   double fft2();
   void ChebyshevTransform(int N);
   void ChebyshevFourierTransform(double *coeff);
   void Symlet5Transform();
   void GradientMagnitude(int span);
   void GradientDirection(int span);
   void PerwittMagnitude(ImageMatrix *output);
   void PerwittDirection(ImageMatrix *output);
   void ChebyshevStatistics(double *coeff, int N, int bins_num);
   int CombFirstFourMoments(double *vec);
   void EdgeStatistics(long *EdgeArea, double *MagMean, double *MagMedian, double *MagVar, double *MagHist, double *DirecMean, double *DirecMedian, double *DirecVar, double *DirecHist, double *DirecHomogeneity, double *DiffDirecHist, int num_bins);
   void RadonTransform(double *vec);
   double OtsuBinaryMaskTransform();
   int BWlabel(int level);
   void centroid(double *x_centroid, double *y_centroid);
   void FeatureStatistics(int *count, int *Euler, double *centroid_x, double *centroid_y, int *AreaMin, int *AreaMax,
                                    double *AreaMean, int *AreaMedian, double *AreaVar, int *area_histogram,double *DistMin, double *DistMax,
                                    double *DistMean, double *DistMedian, double *DistVar, int *dist_histogram, int num_bins);
   void GaborFilters(double *ratios);
   void HaarlickTexture(double distance, double *out);
   void TamuraTexture(double *vec);
   void zernike(double *zvalues, long *output_size);
};



/* global functions */
HSVcolor RGB2HSV(RGBcolor rgb);
RGBcolor HSV2RGB(HSVcolor hsv);
TColor RGB2COLOR(RGBcolor rgb);
double COLOR2GRAY(TColor color);

#endif
