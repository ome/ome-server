/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                                                                               */
/*    Copyright (C) 2003 Open Microscopy Environment                             */
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


#ifndef TrainingSetH
#define TrainingSetH
//---------------------------------------------------------------------------

#include "signatures.h"

#define MAX_CLASS_NUM 200
#define MAX_CLASS_NAME_LENGTH 50
 
class TrainingSet
{
public:
/* properties */
   signatures **samples;                                           /* samples data                              */
   char SignatureNames[MAX_SIGNATURE_NUM][SIGNATURE_NAME_LENGTH];  /* names of the signatures (e.g. "MultiScale Histogram bin 3) */
   double SignatureWeights[MAX_SIGNATURE_NUM];                     /* weights of the samples                    */
   double SignatureMins[MAX_SIGNATURE_NUM];                        /* minimum value of each signature           */
   double SignatureMaxes[MAX_SIGNATURE_NUM];                       /* maximum value of each signature           */
   long class_num;                                                 /* number of classes                         */
   char class_labels[MAX_CLASS_NUM][MAX_CLASS_NAME_LENGTH];        /* labels of the classes                     */
   long count;                                                     /* the number of samples in the training set */
   long signature_count;                                           /* the number of signatures (< MAX_SIGNATURE_NUM) */
/* methods */
   TrainingSet(long samples_num, long class_num);                  /* constructor                               */
   ~TrainingSet();                                                 /* destructor                                */
   int LoadImages(char *filename, int log);                        /* load a set of images (paths are in the text file) */
   int AddAllSignatures(char *filename);                           /* load the image feature values from all files */
   int LoadFromDir(char *filename, int log, int print_to_screen, int tiles, int multi_processor);  /* load images from a root directory         */
   double Test(TrainingSet *TestSet, int method, unsigned short *confusion_matrix, double *similarity_matrix,int tiles);     /* test                                      */
   int SaveToFile(char *filename);                                 /* save the training set values to a file    */
   int ReadFromFile(char *filename);                               /* read the training set values from a file  */
   void split(double ratio,TrainingSet *TrainSet,TrainingSet *TestSet, unsigned short tiles); /* random split to train and test */
   int AddSample(signatures *new_sample);                          /* add signatures computed from one image */
   void normalize();                                               /* normalize the values of the signatures to [0,100] */
   void SetFisherScores(double used_signatures, char *sorted_feature_names);   /* compute the fisher scores for the signatures */
   long WNNclassify(signatures *test_sample, double *probabilities);/* classify a sample using weighted nearest neighbor */
   long classify2(signatures *test_sample, double *probabilities); /* classify using -5                          */
   long PrintConfusion(unsigned short *confusion_matrix, double *similarity_matrix, unsigned short dend_file);  /* print a confusion or similarity matrix */
};


#endif
