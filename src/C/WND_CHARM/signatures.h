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


#ifndef signaturesH
#define signaturesH
//---------------------------------------------------------------------------

#include <stdio.h>

//#include "TrainingSet.h"
#include "cmatrix.h"

#define MAX_SIGNATURE_NUM 3000
#define SIGNATURE_NAME_LENGTH 80
#define IMAGE_PATH_LENGTH 256

//typedef struct
//{
//  double data[MAX_SIGNATURE_NUM];                   /* signature values                          */
//  unsigned short sample_class;                      /* the class of the sample                   */
//  char full_path[256];                              /* optional - full path the the image file   */
//}sample;

struct signature
{
  public:
   char name[SIGNATURE_NAME_LENGTH];
   double value;
};

class signatures
{
  private:
  public:
    signature data[MAX_SIGNATURE_NUM];
    unsigned short sample_class;                    /* the class of the sample */
    long count;
	long index;                                     /* a running index whether the feature was added or not. used to avoid computing uneeded features */
    char full_path[IMAGE_PATH_LENGTH];                            /* optional - full path the the image file   */
    signatures();
    signatures *duplicate();            /* create an identical signature vector object */
//    signatures(sample *one_sample, int sigs_count);
    void Add(char *name, double value);
    void Clear();
    void compute(ImageMatrix *matrix);
    void CompGroupA(ImageMatrix *matrix, char *transform_label);
    void CompGroupB(ImageMatrix *matrix, char *transform_label);
    void CompGroupC(ImageMatrix *matrix, char *transform_label);
    void CompGroupD(ImageMatrix *matrix, char *transform_label);
    void ComputeGroups(ImageMatrix *matrix);
    void normalize(void *TrainSet);                /* normalize the signatures based on the values of the training set */
    void ComputeFromDouble(double *data, int height, int width);  /* compute the feature values from an array of doubles */
    FILE *FileOpen(char *path, int tile_x, int tile_y);
    void FileClose(FILE *value_file);
    int SaveToFile(FILE *value_file);
    int LoadFromFile(char *filename);
};

#endif

