/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                                                                               */
/*    Copyright (C) 2007 Open Microscopy Environment                             */
/*         Massachusetts Institue of Technology,                                 */
/*         National Institutes of Health,                                        */
/*         University of Dundee                                                  */
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

#include <stdio.h>
#include <string.h>

#include "signatures.h"
#include "cmatrix.h"
#include "TrainingSet.h"
#include "colors/FuzzyCalc.h"

#ifndef WIN32
#include <stdlib.h>
#endif

//---------------------------------------------------------------------------
/*  signatures (constructor)
*/
signatures::signatures()
{  int sig_index;
   for (sig_index=0;sig_index<MAX_SIGNATURE_NUM;sig_index++)
   {  data[sig_index].name[0]='\0';
      data[sig_index].value=0;
   }
   count=0;
   sample_class=0;
   full_path[0]='\0';
}
//---------------------------------------------------------------------------

/* duplicate
*/
signatures *signatures::duplicate()
{  int sig_index;
   signatures *new_samp;
   new_samp=new signatures();
   new_samp->sample_class=sample_class;
   new_samp->count=count;
   strcpy(new_samp->full_path,full_path);
   for (sig_index=0;sig_index<count;sig_index++)
   {  new_samp->data[sig_index].value=data[sig_index].value;
      strcpy(new_samp->data[sig_index].name,data[sig_index].name);
   }
   return(new_samp);
}

/* Add
   add a signature
   name -char *- the name of the signature (e.g. Multiscale Histogram bin 3)
   value -double- the value to add
*/
void signatures::Add(char *name,double value)
{
//printf("%s %f\n",name,value);
   if (strchr(name,'\n')) *(strchr(name,'\n'))='\0';  /* prevent end of lines inside the features names */
   if (name) strcpy(data[count].name,name);   
if (value>INF) value=INF;        /* prevent error */
if (value<1/INF && value>-1/INF) value=0;  /* prevent a numerical error */
   data[count].value=value;
   count++;
}

/* Clear
   clear all signature values
*/
void signatures::Clear()
{  count=0;
}


/* compute
   compute signature set of a given image and add the
   resulting values to the "data" attribute of this class
   input - an image matrix structure.
*/

void signatures::compute(ImageMatrix *matrix)
{  char buffer[80];
   double vec[72];
   int a,b,c;
   double mean, median, std, min, max, histogram[10], norm_avg, norm_std;
   ImageMatrix *TempMatrix;
   ImageMatrix *FourierTransform,*ChebyshevTransform,*ChebyshevFourierTransform,*WaveletSelector,*WaveletFourierSelector;
   FourierTransform=matrix->duplicate();
   FourierTransform->fft2();
   ChebyshevTransform=matrix->duplicate();     
   ChebyshevTransform->ChebyshevTransform(0);     
   ChebyshevFourierTransform=FourierTransform->duplicate();
   ChebyshevFourierTransform->ChebyshevTransform(0);    
   WaveletSelector=matrix->duplicate();
   WaveletSelector->Symlet5Transform();    
   WaveletFourierSelector=FourierTransform->duplicate();
   WaveletFourierSelector->Symlet5Transform();
#ifndef WIN32
   printf("start computing features\n");
#endif
   count=0;      /* start counting signatures from 0 */
   /* chebichev fourier transform (signatures 0 - 63) */
   for (a=0;a<32;a++) vec[a]=0;
   matrix->ChebyshevFourierTransform(vec);   
   for (a=0;a<32;a++)
   {  sprintf(buffer,"ChebyshevFourierCoefficientHistogram Bin%02d",a);
      Add(buffer,vec[a]);
   }
   FourierTransform->ChebyshevFourierTransform(vec);
   for (a=0;a<32;a++)
   {  sprintf(buffer,"ChebyshevFourierCoefficientHistogram_FFT Bin%02d",a);
      Add(buffer,vec[a]);
   }
   /* Chebyshev Statistics (signatures 64 - 127) */
   TempMatrix=matrix->duplicate();
   TempMatrix->ChebyshevStatistics(vec,0,32);
   for (a=0;a<32;a++)
   {  sprintf(buffer,"ChebyshevCoefficientHistogram Bin%02d",a);
      Add(buffer,vec[a]);
   } 
   delete TempMatrix;
   TempMatrix=FourierTransform->duplicate();
   TempMatrix->ChebyshevStatistics(vec,0,32);
   for (a=0;a<32;a++)
   {  sprintf(buffer,"ChebyshevCoefficientHistogram_FFT Bin%02d",a);
      Add(buffer,vec[a]);
   }
   delete TempMatrix;
   
   /* Comb4Moments (signatures 128 - 415) */
   char four_moments_names[80][80]={"Minus45_Mean_HistBin00","Minus45_Mean_HistBin01","Minus45_Mean_HistBin02","Minus45_Std_HistBin00","Minus45_Std_HistBin01","Minus45_Std_HistBin02",
           "Minus45_Skew_HistBin00","Minus45_Skew_HistBin01","Minus45_Skew_HistBin02","Minus45_Kurt_HistBin00","Minus45_Kurt_HistBin01","Minus45_Kurt_HistBin02",
		   "Plus45_Mean_HistBin00","Plus45_Mean_HistBin01","Plus45_Mean_HistBin02","Plus45_Std_HistBin00","Plus45_Std_HistBin01","Plus45_Std_HistBin02",
		   "Plus45_Skew_HistBin00","Plus45_Skew_HistBin01","Plus45_Skew_HistBin02","Plus45_Kurt_HistBin00","Plus45_Kurt_HistBin01","Plus45_Kurt_HistBin02","90_Mean_HistBin00",
		   "90_Mean_HistBin01","90_Mean_HistBin02","90_Std_HistBin00","90_Std_HistBin01","90_Std_HistBin02","90_Skew_HistBin00","90_Skew_HistBin01","90_Skew_HistBin02",
		   "90_Kurt_HistBin00","90_Kurt_HistBin01","90_Kurt_HistBin02","0_Mean_HistBin00","0_Mean_HistBin01","0_Mean_HistBin02","0_Std_HistBin00","0_Std_HistBin01","0_Std_HistBin02",
		   "0_Skew_HistBin00","0_Skew_HistBin01","0_Skew_HistBin02","0_Kurt_HistBin00","0_Kurt_HistBin01","0_Kurt_HistBin02"};
   
   matrix->CombFirstFourMoments(vec);
   for (a=0;a<48;a++)
   {  sprintf(buffer,"Comb4Orient4MomentsHistogram %s",four_moments_names[a]);
      Add(buffer,vec[a]);
   }
   ChebyshevTransform->CombFirstFourMoments(vec);
   for (a=0;a<48;a++)
   {  sprintf(buffer,"Comb4Orient4MomentsHistogram_Chebyshev %s",four_moments_names[a]);
      Add(buffer,vec[a]);
   }
   ChebyshevFourierTransform->CombFirstFourMoments(vec);
   for (a=0;a<48;a++)
   {  sprintf(buffer,"Comb4Orient4MomentsHistogram_ChebyshevFFT %s",four_moments_names[a]);
      Add(buffer,vec[a]);
   }   
   FourierTransform->CombFirstFourMoments(vec);  
   for (a=0;a<48;a++)
   {  sprintf(buffer,"Comb4Orient4MomentsHistogram_FFT %s",four_moments_names[a]);
      Add(buffer,vec[a]);
   }  
   WaveletSelector->CombFirstFourMoments(vec);
   for (a=0;a<48;a++)
   {  sprintf(buffer,"Comb4Orient4MomentsHistogram_Wavelet %s",four_moments_names[a]);
      Add(buffer,vec[a]);
   }       
   WaveletFourierSelector->CombFirstFourMoments(vec);
   for (a=0;a<48;a++)
   {  sprintf(buffer,"Comb4Orient4MomentsHistogram_WaveletFFT %s",four_moments_names[a]);
      Add(buffer,vec[a]);
   }
    
   /* edge statistics (signatures 416 - 443) */
   {  long EdgeArea;
      double MagMean, MagMedian, MagVar, MagHist[8], DirecMean, DirecMedian, DirecVar, DirecHist[8], DirecHomogeneity, DiffDirecHist[4];
      matrix->EdgeStatistics(&EdgeArea, &MagMean, &MagMedian, &MagVar, MagHist, &DirecMean, &DirecMedian, &DirecVar, DirecHist, &DirecHomogeneity, DiffDirecHist, 8);
      Add("EdgeArea EdgeArea",EdgeArea);
      for (a=0;a<4;a++)
      {  sprintf(buffer,"EdgeDiffDirecHist Bin%d",a);
         Add(buffer,DiffDirecHist[a]);
      }
      for (a=0;a<8;a++)
      {  sprintf(buffer,"EdgeDirecHist Bin%d",a);
         Add(buffer,DirecHist[a]);
      }
      Add("EdgeDirecHomo DirecHomo",DirecHomogeneity);
      Add("EdgeDirecMean DirecMean",DirecMean);
      Add("EdgeDirecMedian DirecMedian",DirecMedian);
      Add("EdgeDirecVar DirecVar",DirecVar);
      for (a=0;a<8;a++)
      {  sprintf(buffer,"EdgeMagHist Bin%d",a);
         Add(buffer,MagHist[a]);
      }
      Add("EdgeMagMean MagMean",MagMean);
      Add("EdgeMagMedian MagMedian",MagMedian);
      Add("EdgeMagVar MagVar",MagVar);
   }
 
   /*feature statistics (signatures 444 - 477) */
   {  int count, Euler, AreaMin, AreaMax, AreaMedian, area_histogram[10], dist_histogram[10];
      double centroid_x, centroid_y, AreaMean, AreaVar, DistMin, DistMax, DistMean, DistMedian, DistVar;

      matrix->FeatureStatistics(&count, &Euler, &centroid_x, &centroid_y, &AreaMin, &AreaMax, &AreaMean, &AreaMedian, &AreaVar, area_histogram, &DistMin, &DistMax,
                        &DistMean, &DistMedian, &DistVar, dist_histogram, 10);

      for (a=0;a<10;a++)  /* area histogram */
      {  sprintf(buffer,"FeatureAreaHist Bin%d",a);
         Add(buffer,area_histogram[a]);
      }
      Add("FeatureAreaMax FeatureAreaMax",AreaMax);
      Add("FeatureAreaMean FeatureAreaMean",AreaMean);
      Add("FeatureAreaMedian FeatureAreaMedian",AreaMedian);
      Add("FeatureAreaMin FeatureAreaMin",AreaMin);
      Add("FeatureAreaVar FeatureAreaVar",AreaVar);
      Add("FeatureCentroid X",centroid_x);
      Add("FeatureCentroid Y",centroid_y);
      Add("FeatureCount FeatureCount",count);
      for (a=0;a<10;a++)
      {  sprintf(buffer,"FeatureDistHist Bin%d",a);
         Add(buffer,dist_histogram[a]);
      }
      Add("FeatureDistMax FeatureDistMax",DistMax);
      Add("FeatureDistMean FeatureDistMean",DistMean);
      Add("FeatureDistMedian FeatureDistMedian",DistMedian);
      Add("FeatureDistMin FeatureDistMin",DistMin);
      Add("FeatureDistVar FeatureDistVar",DistVar);
      Add("FeatureEuler FeatureEuler",Euler);
   }  
   /* gabor filters (signatures 478 - 484) */
   matrix->GaborFilters(vec);
   for (a=0;a<7;a++)
   {  sprintf(buffer,"GaborTextures Gabor%02d",a+1);
      Add(buffer,vec[a]);
   }

   /* haarlick textures (signatures 485 - 652) */
   char haarlick_names[80][80]={"CoOcMat_AngularSecondMoment","ASM","CoOcMat_Contrast","Contrast","CoOcMat_Correlation","Correlation","CoOcMat_Variance","Variance","CoOcMat_InverseDifferenceMoment","IDM","CoOcMat_SumAverage" ,"SumAvg",
           "CoOcMat_SumVariance","SumVar","CoOcMat_SumEntropy", "SumEntropy","CoOcMat_Entropy" ,"Entropy","CoOcMat_DifferenceEntropy","DiffEntropy","CoOcMat_DifferenceVariance","DiffVar","CoOcMat_FirstMeasureOfCorrelation","MeasCorr1",
		   "CoOcMat_SecondMeasureOfCorrelation","MeasCorr2","CoOcMat_MaximalCorrelationCoefficient" ,"MaxCorrCoef","CoOcMat_AngularSecondMomentDif", "ASM","CoOcMat_ContrastDif" ,"Contrast","CoOcMat_CorrelationDif","Correlation","CoOcMat_VarianceDif","Variance",
		   "CoOcMat_InverseDifferenceMomentDif","IDM","CoOcMat_SumAverageDif","SumAvg","CoOcMat_SumVarianceDif","SumVar","CoOcMat_SumEntropyDif" ,"SumEntropy","CoOcMat_EntropyDif","Entropy","CoOcMat_DifferenceEntropyDif","DiffEntropy","CoOcMat_DifferenceVarianceDif","DiffVar",
		   "CoOcMat_FirstMeasureOfCorrelationDif","MeasCorr1","CoOcMat_SecondMeasureOfCorrelationDif","MeasCorr2","CoOcMat_MaximalCorrelationCoefficientDif","MaxCorrCoef"};

   matrix->HaarlickTexture(0,vec);
   for (a=0;a<28;a++)
   {  sprintf(buffer,"%s %s",haarlick_names[a*2],haarlick_names[a*2+1]);
      Add(buffer,vec[a]);
   }
   ChebyshevTransform->HaarlickTexture(0,vec);
   for (a=0;a<28;a++)
   {  sprintf(buffer,"%s_Chebyshev %s",haarlick_names[a*2],haarlick_names[a*2+1]);
      Add(buffer,vec[a]);
   }    
   ChebyshevFourierTransform->HaarlickTexture(0,vec);
   for (a=0;a<28;a++)
   {  sprintf(buffer,"%s_ChebyshevFFT %s",haarlick_names[a*2],haarlick_names[a*2+1]);
      Add(buffer,vec[a]);
   }
   FourierTransform->HaarlickTexture(0,vec);
   for (a=0;a<28;a++)
   {  sprintf(buffer,"%s_FFT %s",haarlick_names[a*2],haarlick_names[a*2+1]);
      Add(buffer,vec[a]);
   }
   WaveletSelector->HaarlickTexture(0,vec);
   for (a=0;a<28;a++)
   {  sprintf(buffer,"%s_Wavelet %s",haarlick_names[a*2],haarlick_names[a*2+1]);
      Add(buffer,vec[a]);
   }
   WaveletFourierSelector->HaarlickTexture(0,vec);
   for (a=0;a<28;a++)
   {  sprintf(buffer,"%s_WaveletFFT %s",haarlick_names[a*2],haarlick_names[a*2+1]);
      Add(buffer,vec[a]);
   }  

   /* multiple histogram (signatures 653 - 796) */
   /* ***************************************** */
   /* multiple histogram of the original image (signatures 653 - 676) */
   matrix->MultiScaleHistogram(vec);
   b=3;c=3;
   for (a=0;a<24;a++)
   {  if (a==b) b+=(c=c+2);
      sprintf(buffer,"MultipleScaleHistograms TBins%d_Bin%02d",c,a+c-b);
      Add(buffer,vec[a]);
   }
   /* multiple histogram of the chebyshev transform (signatures 677 - 700) */
   ChebyshevTransform->MultiScaleHistogram(vec);
   b=3;c=3;   
   for (a=0;a<24;a++)
   {  if (a==b) b+=(c=c+2);
      sprintf(buffer,"MultipleScaleHistograms_Chebyshev TBins%d_Bin%02d",c,a+c-b);
      Add(buffer,vec[a]);
   }
   /* multiple histogram of the Chebushev Fourier transform (signatures 701 - 724) */
   ChebyshevFourierTransform->MultiScaleHistogram(vec);
   b=3;c=3;   
   for (a=0;a<24;a++)
   {  if (a==b) b+=(c=c+2);
      sprintf(buffer,"MultipleScaleHistograms_ChebyshevFFT TBins%d_Bin%02d",c,a+c-b);
      Add(buffer,vec[a]);
   }
   /* multiple histogram of the Fourier transform (signatures 725 - 748) */
   FourierTransform->MultiScaleHistogram(vec);
   b=3;c=3;   
   for (a=0;a<24;a++)
   {  if (a==b) b+=(c=c+2);
      sprintf(buffer,"MultipleScaleHistograms_FFT TBins%d_Bin%02d",c,a+c-b);
      Add(buffer,vec[a]);
   }
   /* multiple histogram of the wavelet transform (signatures 749 - 772) */
   WaveletSelector->MultiScaleHistogram(vec);
   b=3;c=3;   
   for (a=0;a<24;a++)
   {  if (a==b) b+=(c=c+2);
      sprintf(buffer,"MultipleScaleHistograms_Wavelet TBins%d_Bin%02d",c,a+c-b);
      Add(buffer,vec[a]);
   }
   /* multiple histogram of the wavelet Fourier transform (signatures 773 - 796) */
   WaveletFourierSelector->MultiScaleHistogram(vec);
   b=3;c=3;   
   for (a=0;a<24;a++)
   {  if (a==b) b+=(c=c+2);
      sprintf(buffer,"MultipleScaleHistograms_WaveletFFT TBins%d_Bin%02d",c,a+c-b);
      Add(buffer,vec[a]);
   }

   /* radon transform (signatures 797 - 844) */
   matrix->RadonTransform(vec);
   for (a=0;a<12;a++)
   {  sprintf(buffer,"RadonTransformStatistics Orient%d_Bin_%02d",45*(int)(a/3),a % 3);
      Add(buffer,vec[a]);
   }
   ChebyshevTransform->RadonTransform(vec);
   for (a=0;a<12;a++)
   {  sprintf(buffer,"RadonTransformStatistics_Chebyshev Orient%d_Bin_%02d",45*(int)(a/3),a % 3);
      Add(buffer,vec[a]);
   }
   ChebyshevFourierTransform->RadonTransform(vec);
   for (a=0;a<12;a++)
   {  sprintf(buffer,"RadonTransformStatistics_ChebyshevFFT Orient%d_Bin_%02d",45*(int)(a/3),a % 3);
      Add(buffer,vec[a]);
   }
   FourierTransform->RadonTransform(vec);
   for (a=0;a<12;a++)
   {  sprintf(buffer,"RadonTransformStatistics_FFT Orient%d_Bin_%02d",45*(int)(a/3),a % 3);
      Add(buffer,vec[a]);
   }
 
   char tamura_names[80][80]={"Total_Coarseness","Coarseness_Hist_Bin_00","Coarseness_Hist_Bin_01","Coarseness_Hist_Bin_02","Directionality","Contrast"};
   /* tamura texture (signatures 845 - 880) */
   matrix->TamuraTexture(vec);
   for (a=0;a<6;a++)
   {  sprintf(buffer,"TamuraTextures %s",tamura_names[a]);
      Add(buffer,vec[a]);
   }
   ChebyshevTransform->TamuraTexture(vec);
   for (a=0;a<6;a++)
   {  sprintf(buffer,"TamuraTextures_Chebyshev %s",tamura_names[a]);
      Add(buffer,vec[a]);
   }
   ChebyshevFourierTransform->TamuraTexture(vec);
   for (a=0;a<6;a++)
   {  sprintf(buffer,"TamuraTextures_ChebyshevFFT %s",tamura_names[a]);
      Add(buffer,vec[a]);
   }
   FourierTransform->TamuraTexture(vec);
   for (a=0;a<6;a++)
   {  sprintf(buffer,"TamuraTextures_FFT %s",tamura_names[a]);
      Add(buffer,vec[a]);
   }
   WaveletSelector->TamuraTexture(vec);
   for (a=0;a<6;a++)
   {  sprintf(buffer,"TamuraTextures_Wavelet %s",tamura_names[a]);
      Add(buffer,vec[a]);
   }
   WaveletFourierSelector->TamuraTexture(vec);
   for (a=0;a<6;a++)
   {  sprintf(buffer,"TamuraTextures_WaveletFFT %s",tamura_names[a]);
      Add(buffer,vec[a]);
   }

   /* zernike (signatures 881 - 1024) */
   { long x,y,output_size;   /* output size is normally 72 */
     matrix->zernike(vec,&output_size);
	 x=0;y=0;
     for (a=0;a<output_size;a++)
     {  sprintf(buffer,"ZernikeMoments Z_%02d_%02d",y,x);
        Add(buffer,vec[a]);
		if (x>=y) x=1-(y++ % 2);
		else x+=2;
	}
	x=0;y=0;	 
    FourierTransform->zernike(vec,&output_size);
    for (a=0;a<output_size;a++)
    {  sprintf(buffer,"ZernikeMoments_FFT Z_%02d_%02d",y,x);
       Add(buffer,vec[a]);
	   if (x>=y) x=1-(y++ % 2);
	   else x+=2;		
     }
   }

   return;
   /* basic statistics (signatures 1025 - 1049) */

   /* basic image statistics */
   matrix->BasicStatistics(&mean, &median, &std, &min, &max, NULL, 10);
   Add("mean",mean);
   Add("median",median);
   Add("stddev",std);
   Add("min",min);
   Add("max",max);

   /* basic chebyshev statistics */
   ChebyshevTransform->BasicStatistics(&mean, &median, &std, &min, &max, NULL, 10);
   Add("Chebyshev mean",mean);
   Add("Chebyshev median",median);
   Add("Chebyshev stddev",std);
   Add("Chebyshev min",min);
   Add("Chebyshev max",max);

   /* basic Fourier statistics */
   FourierTransform->BasicStatistics(&mean, &median, &std, &min, &max, NULL, 10);
   Add("Fourier mean",mean);
   Add("Fourier median",median);
   Add("Fourier stddev",std);
   Add("Fourier min",min);
   Add("Fourier max",max);

   /* basic Wavelet statistics */
   WaveletSelector->BasicStatistics(&mean, &median, &std, &min, &max, NULL, 10);
   Add("Wavelet mean",mean);
   Add("Wavelet median",median);
   Add("Wavelet stddev",std);
   Add("Wavelet min",min);
   Add("Wavelet max",max);

   /* basic Wavelet Fourier statistics */
   WaveletFourierSelector->BasicStatistics(&mean, &median, &std, &min, &max, NULL, 10);
   Add("Wavelet Fourier mean",mean);
   Add("Wavelet Fourier median",median);
   Add("Wavelet Fourier stddev",std);
   Add("Wavelet Fourier min",min);
   Add("Wavelet Fourier max",max);

   delete FourierTransform;
   delete ChebyshevTransform;
   delete ChebyshevFourierTransform;
   delete WaveletSelector;
   delete WaveletFourierSelector;



   return;



/* consider adding also the global centroid (by calling the centroid method) also centroid of Fourier   x and y of max */
   {
      TempMatrix=matrix->duplicate();
      TempMatrix->normalize(min,max,255);
      TempMatrix->BasicStatistics(&mean, &median, &std, &min, &max, histogram, 0);
      Add("normalized mean",mean);
      Add("normalized median",median);
      Add("normalized stddev",std);
      delete TempMatrix;

   }

   /* general color image statistics */
   {  double hue_avg, hue_std, sat_avg, sat_std, val_avg, val_std, max_color, colors[COLORS_NUM];
      matrix->GetColorStatistics(&hue_avg, &hue_std, &sat_avg, &sat_std, &val_avg, &val_std, &max_color, colors);
      Add("hue average",hue_avg);
      Add("hue stddev",hue_std);
      Add("saturation average",sat_avg);
      Add("saturation stddev",sat_std);
      Add("value average",val_avg);
      Add("value stddev",val_std);
      Add("most common color",max_color);
      for (a=0;a<COLORS_NUM;a++)
      {  sprintf(buffer,"color %d",a);
         Add(buffer,colors[a]);
      }
   }

   /* basic edges */
   TempMatrix=matrix->duplicate();
   TempMatrix->EdgeTransform();
   TempMatrix->BasicStatistics(&mean, &median, &std, &min, &max, histogram, 8);
   Add("mean edge",mean);
   Add("median edge",median);
   for (a=0;a<8;a++)
   {  sprintf(buffer,"edge bin %d/8",a);
      Add(buffer,histogram[a]);
   }
   delete TempMatrix;

   /* edge statistics */

   /* peaks of fourier on each axis */

}


/* CompGroupA
   compute group A of image feature (high contrast features)
   the features in this group are edge statistics, object statistics and Gabor textures
   input - an image matrix structure.
         - transform_label - the image transform short description (e.g., wavelet-fourier)
*/
void signatures::CompGroupA(ImageMatrix *matrix, char *transform_label)
{  int a;
   char buffer[80];
   double vec[32];
   /* edge statistics */
   {  long EdgeArea;
      double MagMean, MagMedian, MagVar, MagHist[8], DirecMean, DirecMedian, DirecVar, DirecHist[8], DirecHomogeneity, DiffDirecHist[4];
      matrix->EdgeStatistics(&EdgeArea, &MagMean, &MagMedian, &MagVar, MagHist, &DirecMean, &DirecMedian, &DirecVar, DirecHist, &DirecHomogeneity, DiffDirecHist, 8);
      Add("Edge Area",EdgeArea);
      for (a=0;a<4;a++)
      {  sprintf(buffer,"DiffDirecHist bin %d",a);
         Add(buffer,DiffDirecHist[a]);
      }
      for (a=0;a<8;a++)
      {  sprintf(buffer,"Direction Histogram bin %d",a);
         Add(buffer,DirecHist[a]);
      }
      Add("Direction Homogeneity",DirecHomogeneity);
      Add("Direction Mean",DirecMean);
      Add("Direction Median",DirecMedian);
      Add("Direction Variance",DirecVar);
      for (a=0;a<8;a++)
      {  sprintf(buffer,"Magnitude Histogram bin %d",a);
         Add(buffer,MagHist[a]);
      }
      Add("Magnitude Mean",MagMean);
      Add("Magnitude Median",MagMedian);
      Add("Magnitude Variance",MagVar);
   }

   /* object statistics */
   {  int count, Euler, AreaMin, AreaMax, AreaMedian, area_histogram[10], dist_histogram[10];
      double centroid_x, centroid_y, AreaMean, AreaVar, DistMin, DistMax, DistMean, DistMedian, DistVar;

      matrix->FeatureStatistics(&count, &Euler, &centroid_x, &centroid_y, &AreaMin, &AreaMax, &AreaMean, &AreaMedian, &AreaVar, area_histogram, &DistMin, &DistMax,
                        &DistMean, &DistMedian, &DistVar, dist_histogram, 10);

      for (a=0;a<10;a++)  /* area histogram */
      {  sprintf(buffer,"Feature area histogram bin %d",a);
         Add(buffer,area_histogram[a]);
      }
      Add("Feature AreaMax",AreaMax);
      Add("Feature AreaMean",AreaMean);
      Add("Feature AreaMedian",AreaMedian);
      Add("Feature AreaMin",AreaMin);
      Add("Feature AreaVar",AreaVar);
      Add("Feature X Centroid",centroid_x);
      Add("Feature Y Centroid",centroid_y);
      Add("Feature Count",count);
      for (a=0;a<10;a++)
      {  sprintf(buffer,"Feature dist histogram bin %d",a);
         Add("Feature DistHist",dist_histogram[a]);
      }
      Add("Feature DistMax",DistMax);
      Add("Feature DistMean",DistMean);
      Add("Feature DistMedian",DistMedian);
      Add("Feature DistMin",DistMin);
      Add("Feature DistVar",DistVar);
      Add("Feature Euler",Euler);
   }

   /* gabor filters */
   matrix->GaborFilters(vec);
   for (a=0;a<7;a++)
   {  sprintf(buffer,"Gabor Filters bin %d",a);
      Add(buffer,vec[a]);
   }
}

/* CompGroupB
   compute group B of image feature (Polynomial Decompositions)
   the features in this group are Chebyshev-Fourier Statistics, Chebyshev Statistics, Zernike Polynomials
   input - an image matrix structure.
         - transform_label - the image transform short description (e.g., wavelet-fourier)
*/
void signatures::CompGroupB(ImageMatrix *matrix, char *transform_label)
{  int a;
   double vec[72];
   char buffer[80];
   ImageMatrix *TempMatrix;

   /* chebichev fourier transform (signatures 0 - 63) */
   for (a=0;a<32;a++) vec[a]=0;
   matrix->ChebyshevFourierTransform(vec);
   for (a=0;a<32;a++)
   {  sprintf(buffer,"Chebishev Fourier Transform bin %d (%s)",a,transform_label);
      Add(buffer,vec[a]);
   }

   /* Chebyshev Statistics (signatures 64 - 127) */
   TempMatrix=matrix->duplicate();
   TempMatrix->ChebyshevStatistics(vec,0,32);
   for (a=0;a<32;a++)
   {  sprintf(buffer,"Chebishev Statistics bin %d (%s)",a,transform_label);
      Add(buffer,vec[a]);
   }
   delete TempMatrix;

   /* zernike (signatures 881 - 1024) */
   long output_size;   /* output size is normally 72 */
   matrix->zernike(vec,&output_size);
   for (a=0;a<output_size;a++)
   {  sprintf(buffer,"Zernike %d (%s)",a,transform_label);
      Add(buffer,vec[a]);
   }
}

/* CompGroupC
   compute group C of image feature (Statistics and Textures)
   the features in this group are First Four Moments, Haralick Textures, Multiscale Histogram, Tamura Textures, Radon Transform Statistics
   input - an image matrix structure.
         - transform_label - the image transform short description (e.g., wavelet-fourier)
*/
void signatures::CompGroupC(ImageMatrix *matrix, char *transform_label)
{  int a;
   double vec[72];
   char buffer[80];
   double mean, median, std, min, max;
   
   /* Comb4Moments */
   matrix->CombFirstFourMoments(vec);
   for (a=0;a<48;a++)
   {  sprintf(buffer,"CombFirstFourMoments %d (%s)",a,transform_label);
      Add(buffer,vec[a]);
   }

   /* haarlick textures */
   matrix->HaarlickTexture(0,vec);
   for (a=0;a<28;a++)
   {  sprintf(buffer,"Haarlick Texture %d (%s)",a,transform_label);
      Add(buffer,vec[a]);
   }

   /* multiple histogram of the original image */
   matrix->MultiScaleHistogram(vec);
   for (a=0;a<24;a++)
   {  sprintf(buffer,"MultiScale Histogram bin %d (%s)",a,transform_label);
      Add(buffer,vec[a]);
   }

   /* tamura texture */
   matrix->TamuraTexture(vec);
   for (a=0;a<6;a++)
   {  sprintf(buffer,"Tamura Texture %d (%s)",a,transform_label);
      Add(buffer,vec[a]);
   }

   /* radon transform */
   matrix->RadonTransform(vec);
   for (a=0;a<12;a++)
   {  sprintf(buffer,"Radon bin %d (%s)",a,transform_label);
      Add(buffer,vec[a]);
   }
   
   /* basic statistics */
   matrix->BasicStatistics(&mean, &median, &std, &min, &max, NULL, 10);
   sprintf(buffer,"mean (%s)",transform_label);
   Add(buffer,mean);
   sprintf(buffer,"median (%s)",transform_label);   
   Add(buffer,median);
   sprintf(buffer,"stddev (%s)",transform_label);      
   Add(buffer,std);
   sprintf(buffer,"min (%s)",transform_label);         
   Add(buffer,min);
   sprintf(buffer,"max (%s)",transform_label);            
   Add(buffer,max);   
}

/* CompGroupD
   compute group D of image feature (color features)
   the features in this group are HSV statistics, color histogram
   input - an image matrix structure.
         - transform_label - the image transform short description (e.g., wavelet-fourier)
*/
void signatures::CompGroupD(ImageMatrix *matrix, char *transform_label)
{  int a;
   double vec[72];
   char buffer[80];

   /* general color image statistics */
   {  double hue_avg, hue_std, sat_avg, sat_std, val_avg, val_std, max_color, colors[COLORS_NUM];
      matrix->GetColorStatistics(&hue_avg, &hue_std, &sat_avg, &sat_std, &val_avg, &val_std, &max_color, colors);
      Add("hue average",hue_avg);
      Add("hue stddev",hue_std);
      Add("saturation average",sat_avg);
      Add("saturation stddev",sat_std);
      Add("value average",val_avg);
      Add("value stddev",val_std);
      Add("most popular color",max_color);
      for (a=1;a<COLORS_NUM;a++)
      {  sprintf(buffer,"color %d (%s)",a,transform_label);
         Add(buffer,colors[a]);
      }
   }

}

/* ComputeGroups
   compute the image features
   input - an image matrix structure.
*/
void signatures::ComputeGroups(ImageMatrix *matrix)
{
  ImageMatrix *TempMatrix;
  ImageMatrix *FourierTransform,*ChebyshevTransform,*ChebyshevFourierTransform,*WaveletSelector,*FourierWaveletSelector;
  ImageMatrix *FourierChebyshev,*WaveletFourier,*ChebyshevWavelet, *EdgeTransform, *EdgeFourier, *EdgeWavelet;

  count=0;      /* start counting signatures from 0 */

  FourierTransform=matrix->duplicate();
  FourierTransform->fft2();
  ChebyshevTransform=matrix->duplicate();
  ChebyshevTransform->ChebyshevTransform(0);
  ChebyshevFourierTransform=FourierTransform->duplicate();
  ChebyshevFourierTransform->ChebyshevTransform(0);
  WaveletSelector=matrix->duplicate();
  WaveletSelector->Symlet5Transform();
  FourierWaveletSelector=FourierTransform->duplicate();
  FourierWaveletSelector->Symlet5Transform();

  FourierChebyshev=ChebyshevTransform->duplicate();
  FourierChebyshev->fft2();
  WaveletFourier=WaveletSelector->duplicate();
  WaveletFourier->Symlet5Transform();
  ChebyshevWavelet=WaveletSelector->duplicate();
  ChebyshevWavelet->ChebyshevTransform(0);
  EdgeTransform=matrix->duplicate();
  EdgeTransform->EdgeTransform();
  EdgeFourier=EdgeTransform->duplicate();
  EdgeFourier->fft2();
  EdgeWavelet=EdgeTransform->duplicate();
  EdgeWavelet->Symlet5Transform();

  CompGroupA(matrix,"");
  CompGroupB(matrix,"");
  CompGroupC(matrix,"");
//  CompGroupD(matrix,"");

  CompGroupB(FourierTransform,"Fourier");
  CompGroupC(FourierTransform,"Fourier");

  CompGroupB(WaveletSelector,"Wavelet");
  CompGroupC(WaveletSelector,"Wavelet");

  CompGroupB(ChebyshevTransform,"Chebyshev");
  CompGroupC(ChebyshevTransform,"Chebyshev");

  CompGroupC(ChebyshevFourierTransform,"Chebyshev Fourier");
  CompGroupC(FourierWaveletSelector,"Wavelet Fourier");
/**/
  CompGroupB(WaveletFourier,"Fourier Wavelet");
  CompGroupC(WaveletFourier,"Fourier Wavelet");

  CompGroupC(FourierChebyshev,"Fourier Chebyshev");
  CompGroupC(ChebyshevWavelet,"Chebyshev Wavelet");

  CompGroupB(EdgeTransform,"Edge Transform");
  CompGroupC(EdgeTransform,"Edge Transform");

  CompGroupB(EdgeFourier,"Edge Fourier Transform");
  CompGroupC(EdgeFourier,"Edge Fourier Transform");

  CompGroupB(EdgeWavelet,"Edge Wavelet Transform");
  CompGroupC(EdgeWavelet,"Edge Wavelet Transform");
  
  delete FourierTransform;
  delete WaveletSelector;
  delete ChebyshevTransform;
  delete ChebyshevFourierTransform;
  delete FourierWaveletSelector;
  delete WaveletFourier;
  delete ChebyshevWavelet;
  delete EdgeTransform;
  delete EdgeFourier;
  delete EdgeWavelet;
  delete FourierChebyshev;
}


/* normalize
   normalize the signature values using the maximum and minimum values of the training set
   ts -TrainingSet *- the training set according which the signature values should be normalized
*/
void signatures::normalize(void *TrainSet)
{  int sig_index;
   TrainingSet *ts;
   ts=(TrainingSet *)TrainSet;
   for (sig_index=0;sig_index<count;sig_index++)
   { if (data[sig_index].value>=INF) data[sig_index].value=0;
     else
     if (data[sig_index].value<ts->SignatureMins[sig_index]) data[sig_index].value=ts->SignatureMins[sig_index];
     else
     if (data[sig_index].value>ts->SignatureMaxes[sig_index]) data[sig_index].value=ts->SignatureMaxes[sig_index];
     else
     if (ts->SignatureMins[sig_index]>=ts->SignatureMaxes[sig_index]) data[sig_index].value=0; /* prevent possible division by zero */
     else
     data[sig_index].value=100*(data[sig_index].value-ts->SignatureMins[sig_index])/(ts->SignatureMaxes[sig_index]-ts->SignatureMins[sig_index]);
   }
}


/* ComputeFromDouble
   compute signature set of a given image and add the
   resulting values to the "data" attribute of this class.
   This function is the same as "compute" but accepts doubles as input
   instead of ImageMatrix

   input - data -double *- the pixel values.
                the data is organized such that the first data are the first row
                (y moves faster, x moves slower)
           height - the image height
           width - the image width
*/
void signatures::ComputeFromDouble(double *data, int height, int width)
{  ImageMatrix *matrix;
   int x,y;
   matrix=new ImageMatrix(width,height);
   for (x=0;x<width;x++)
     for (y=0;y<height;y++)
       matrix->data[x][y].intensity=data[x*height+y];
   compute(matrix);
   delete matrix;
}


/* FileOpen
   Creates and opens a files before writing feature value content
   path -char *- path to the file to be opened. If NULL then open path is the original file name with ".sig" extention.
*/
FILE *signatures::FileOpen(char *path, int tile_x, int tile_y)
{  char filename[512],buffer[512];
   FILE *ret;
   if (path) strcpy(filename,path);
   else
   {  char *p_point;
      strcpy(filename,full_path);
      p_point=strrchr(filename,'.');
      if (p_point) *p_point='\0';
      if (tile_x!=-1) sprintf(buffer,"%s_%d_%d",filename,tile_x,tile_y);
      strcat(buffer,".sig");
      strcpy(filename,buffer);
   }
   if (ret=fopen(filename,"r"))
   {  fclose(ret);
      return(NULL);   /* file already exists */
   }
   else return(fopen(filename,"w"));
}

/* FileClose
   Closes a value file.
*/
void signatures::FileClose(FILE *value_file)
{
   fclose(value_file);
}

int signatures::SaveToFile(FILE *value_file)
{  int sig_index;

   fprintf(value_file,"%d\n",sample_class);
   fprintf(value_file,"%s\n",full_path);
   for (sig_index=0;sig_index<count;sig_index++)
     fprintf(value_file,"%f %s\n",data[sig_index].value,data[sig_index].name);
//     fprintf(value_file,"%e %s\n",data[sig_index].value,data[sig_index].name);	 
   return(1);
}

int signatures::LoadFromFile(char *filename)
{  char buffer[256],*p_buffer;
   FILE *value_file;

   if (!(value_file=fopen(filename,"r")))
     return(0);
   /* read the class */
   fgets(buffer,sizeof(buffer),value_file);
//   if (strchr(buffer,'\n')) *(strchr(buffer,'\n'))='\0';
   sample_class=atoi(buffer);

   /* read the path */
   fgets(buffer,sizeof(buffer),value_file);
   if (strchr(buffer,'\n')) *(strchr(buffer,'\n'))='\0';
   strcpy(full_path,buffer);

   /* read the feature values */
   p_buffer=fgets(buffer,sizeof(buffer),value_file);
   while (p_buffer)
   {  char *p_name;
      p_name=strchr(buffer,' ');
      *p_name='\0';
      p_name++;
      Add(p_name,atof(buffer));
      p_buffer=fgets(buffer,sizeof(buffer),value_file);
   }
   fclose(value_file);
   return(1);
}

#pragma package(smart_init)

