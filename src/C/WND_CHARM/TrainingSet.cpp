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

#include <string.h>
#include <stdio.h>
#include <math.h>
#include <dirent.h>

#include "TrainingSet.h"
//#include "cmatrix.h"

#ifndef WIN32
#include <stdlib.h>
#endif

//---------------------------------------------------------------------------

/* constructor of a TrainingSet object
   samples_num -long- a maximal number of samples in the training set
*/
TrainingSet::TrainingSet(long samples_num, long class_num)
{  int signature_index,sample_index;
//   samples=new sample[samples_num];
   samples=new signatures*[samples_num];
   for (sample_index=0;sample_index<samples_num;sample_index++)
     samples[sample_index]=NULL;
   /* initialize */
   for (signature_index=0;signature_index<MAX_SIGNATURE_NUM;signature_index++)
   {  SignatureNames[signature_index][0]='\0';
      SignatureWeights[signature_index]=0.0;
      SignatureMins[signature_index]=INF;
      SignatureMaxes[signature_index]=-INF;
   }
   this->class_num=class_num;
   signature_count=0;
   for (sample_index=0;sample_index<MAX_CLASS_NUM;sample_index++)
     strcpy(class_labels[sample_index],"");
   count=0;
}

/* destructor of a training set object
*/
TrainingSet::~TrainingSet()
{  int sample_index;
   for (sample_index=0;sample_index<count;sample_index++)
     if (samples[sample_index]) delete samples[sample_index];
   delete samples;
}

/* AddSample
   Add the signatures computed from one image to the training set
   new_sample -signatures- the set of signature values
   path -char *- full path to the image file (NULL if n/a)

   returned value -int- 1 if suceeded 0 if failed.
                        can fail due to bad sample class
*/
int TrainingSet::AddSample(signatures *new_sample)
{  int sig_index;

   /* check if the sample can be added */
   if (new_sample->sample_class<1 || new_sample->sample_class>class_num) return(0);

   samples[count]=new_sample;
   for (sig_index=0;sig_index<new_sample->count;sig_index++)
      if (new_sample->data[sig_index].name[0]!='\0') strcpy(SignatureNames[sig_index],new_sample->data[sig_index].name);
   signature_count=new_sample->count;
   count++;
   return(1);
}

/* SaveToFile
   filename -char *- the name of the file to save
   returned value -int- 1 is successful, 0 if failed.

   comment: saves the training set into a text file
*/
int TrainingSet::SaveToFile(char *filename)
{  int sample_index, class_index, sig_index;
   FILE *file;
   if (!(file=fopen(filename,"w"))) return(0);
   fprintf(file,"%d\n",class_num);
   fprintf(file,"%d\n",signature_count);
   fprintf(file,"%d\n",count);
   /* write the signature names */
   for (sig_index=0;sig_index<signature_count;sig_index++)
     fprintf(file,"%s\n",SignatureNames[sig_index]);
   /* write the class labels */
   for (class_index=0;class_index<=class_num;class_index++)
     fprintf(file,"%s\n",class_labels[class_index]);
   /* write the samples */
   for (sample_index=0;sample_index<count;sample_index++)
   {
      for (sig_index=0;sig_index<signature_count;sig_index++)
		if (samples[sample_index]->data[sig_index].value==(int)(samples[sample_index]->data[sig_index].value))   
        fprintf(file,"%d ",(int)(samples[sample_index]->data[sig_index].value));      /* make the file smaller */
//        else fprintf(file,"%.6f ",samples[sample_index]->data[sig_index].value);
        else fprintf(file,"%.5e ",samples[sample_index]->data[sig_index].value);
      fprintf(file,"%d\n",samples[sample_index]->sample_class);
      fprintf(file,"%s\n",samples[sample_index]->full_path);
   }
   fclose(file);
   return(1);
}


/* ReadFromFile
   filename -char *- the name of the file to open
   returned value -int- 1 is successful, 0 if failed.

   comment: reads the training set from a text file
*/
int TrainingSet::ReadFromFile(char *filename)
{  int sample_index, class_index, sample_count,sig_index;
   char buffer[50000];
   FILE *file;
   if (!(file=fopen(filename,"r"))) return(0);
   for (sample_index=0;sample_index<count;sample_index++)
     if (samples[sample_index]) delete samples[sample_index];
   delete samples;
   fgets(buffer,sizeof(buffer),file);
   class_num=atoi(buffer);
   fgets(buffer,sizeof(buffer),file);
   signature_count=atoi(buffer);
   fgets(buffer,sizeof(buffer),file);
   sample_count=atoi(buffer);
   samples=new signatures*[sample_count];
   count=0;         /* initialize the count before adding the samples to the training set */
   /* read the signature names */
   for (sig_index=0;sig_index<signature_count;sig_index++)
   {  fgets(buffer,sizeof(buffer),file);
      strcpy(SignatureNames[sig_index],buffer);
      if (strchr(SignatureNames[sig_index],'\n')) *strchr(SignatureNames[sig_index],'\n')='\0';  /* make sure there is no line break in the name */
   }
   /* read the class labels */
   for (class_index=0;class_index<=class_num;class_index++)
   {  fgets(buffer,sizeof(buffer),file);
      strcpy(class_labels[class_index],buffer);
      if (strchr(class_labels[class_index],'\n')) *strchr(class_labels[class_index],'\n')='\0';	  /* make sure there is no line break in the name */
   }
    /* read the samples */
   for (sample_index=0;sample_index<sample_count;sample_index++)
   {
      char *p_buffer;
      signatures *one_sample;
      one_sample=new signatures();
      fgets(buffer,sizeof(buffer),file);
      p_buffer=strtok(buffer," \n");
      for (sig_index=0;sig_index<signature_count;sig_index++)
      {
         one_sample->Add(SignatureNames[sig_index],atof(p_buffer));
         p_buffer=strtok(NULL," \n");
      }
      one_sample->sample_class=atoi(p_buffer);
      fgets(buffer,sizeof(buffer),file);                      /* read the image path (can also be en ampty line) */
      if (strchr(buffer,'\n')) *(strchr(buffer,'\n'))='\0';   /* remove the end of line (if there is one)        */
      strcpy(one_sample->full_path,buffer);                   /* copy the full path to the signatures object     */
      AddSample(one_sample);
   }

   fclose(file);
   return(1);
}


/*  split
    split randomly into a training set and a test set
    ratio -double- the ratio of the number of test set (e.g., 0.1 means 10% of the data are test data).
	tiles -unsigned short- indicates the number of tiles to which each image was divided into. This means that
	                       when splitting to train and test, all tiles of that one image will be either in the
						   test set or training set.
*/
void TrainingSet::split(double ratio,TrainingSet *TrainSet,TrainingSet *TestSet, unsigned short tiles)
{  long *class_samples;
   int class_index,tile_index;
   class_samples = new long[count];
   if (tiles<1) tiles=1;    /* make sure the number of tiles is valid */
   TrainSet->class_num=TestSet->class_num=class_num;
   for (class_index=1;class_index<=class_num;class_index++)
   {  int sample_index;
      int class_samples_count=0;
      for (sample_index=0;sample_index<count;sample_index++)
        if (samples[sample_index]->sample_class==class_index)
          class_samples[class_samples_count++]=sample_index;	  
      class_samples_count/=tiles;
      /* add the samples to the test set */
      for (sample_index=0;sample_index<class_samples_count*ratio;sample_index++)
      {  int rand_index;
         rand_index=rand() % class_samples_count;            /* find a random sample  */
         for (tile_index=0;tile_index<tiles;tile_index++)    /* add all the tiles of that image */
           TestSet->AddSample(samples[class_samples[rand_index*tiles+tile_index]]->duplicate());   /* add the random sample */
         /* remove the index */
//         memmove(&(class_samples[rand_index]),&(class_samples[rand_index+1]),sizeof(long)*(class_samples_count-rand_index));
         memmove(&(class_samples[rand_index*tiles]),&(class_samples[rand_index*tiles+tiles]),sizeof(long)*(tiles*(class_samples_count-rand_index)));
         class_samples_count--;
      }
      /* now add the remaining samples to the Train Set */
      for (sample_index=0;sample_index<class_samples_count*tiles;sample_index++)
        TrainSet->AddSample(samples[class_samples[sample_index]]->duplicate());
   }
   delete class_samples;
}

/* LoadImages
   load a set of image into the training set
   filename -char *- a text file with a list of full path to the images
   returned value -int- 1 is scucceeded 0 if failed
   log -int- whether to write a log file
*/
int TrainingSet::LoadImages(char *filename, int log)
{  FILE *file,*log_file;
   char buffer[1024],*p_buffer;
   int samp_class=0;
   if (!(file=fopen(filename,"r"))) return(0);
   p_buffer=fgets(buffer,1024,file);
   while (p_buffer)
   {  p_buffer[strlen(p_buffer)-1]='\0';
      if (strlen(p_buffer)>0 && p_buffer[0]!='#')
      {  if (atoi(p_buffer)) samp_class=atoi(p_buffer);
         else
         { ImageMatrix *matrix;
           signatures *ImageSignatures;
           matrix=new ImageMatrix;
           ImageSignatures=new signatures;
           if (log)  /* write to a log file */
           {  if (log_file=fopen("sigs.log","w"))
              {  fprintf(log_file,"Loading image %s",p_buffer);
                 fclose(log_file);
              }
           }
#ifdef WIN32
           matrix->LoadBMP(p_buffer,cmHSV);
#else
#endif
//matrix->Downsample(0.5,0.5);
           strcpy(ImageSignatures->full_path,p_buffer);
           ImageSignatures->compute(matrix,0);
           ImageSignatures->sample_class=samp_class;
           AddSample(ImageSignatures);
           delete matrix;
//           delete ImageSignatures;
         }
      }
      p_buffer=fgets(buffer,1024,file);
   }
   fclose(file);
   return(1);
}


/* AddAllSignatures
   load the image feature values from all files
   filename -char *- the root directory of the data set
*/

/* this function is used for sorting the files */
int comp_strings(const void *s1, const void *s2)
{  return(strcmp((char *)s1,(char *)s2));
}

int TrainingSet::AddAllSignatures(char *filename)
{  DIR *root_dir,*class_dir;
   struct dirent *ent;
   FILE *sig_file;
   char buffer[256],sig_file_name[256];
   char files_in_class[2048][64];
   int res,samp_class=1;
   if (!(root_dir=opendir(filename))) return(0);
   while (ent = readdir(root_dir))
   {  int file_index,files_in_class_count=0;
      if (strchr(ent->d_name,'.')) continue;   /* ignore the '.' and '..' entries or files     */
      strcpy(class_labels[samp_class],ent->d_name);        /* the label of the class is the directory name */
      strcpy(buffer,filename);
      strcat(buffer,"/");
      strcat(buffer,ent->d_name);
      class_dir=opendir(buffer);
      /* read the files and make sure they are sorted */
      while (ent = readdir(class_dir))
        if (strstr(ent->d_name,".sig"))  /* read only the .sig files which store image feature data */
          strcpy(files_in_class[files_in_class_count++],ent->d_name);
      closedir(class_dir);
      qsort(files_in_class,files_in_class_count,sizeof(files_in_class[0]), comp_strings);

	  /* now load and add the feature value files */
//      while (ent = readdir(class_dir))
//      {  if (strstr(ent->d_name,".sig"))
      for (file_index=0;file_index<files_in_class_count;file_index++)
         {  signatures *ImageSignatures;
            strcpy(sig_file_name,buffer);
            strcat(sig_file_name,"/");
			strcat(sig_file_name,files_in_class[file_index]);
//            strcat(sig_file_name,ent->d_name);
            ImageSignatures = new signatures;
            if (ImageSignatures->LoadFromFile(sig_file_name))
            {  ImageSignatures->sample_class=samp_class;   /* make sure the sample has the right class ID */
               AddSample(ImageSignatures);
            }
            else delete ImageSignatures;
//         }
      }
//	  closedir(class_dir);
      samp_class++;
   }
   closedir(root_dir);
}


/* LoadFromDir
   load a set of image into the training set
   filename -char *- a root directory - each class is a sub-directory.
   returned value -int- 1 is scucceeded 0 if failed
   log -int- whether to write a log file
   print_to_screen -int- print the currently processed image to the screen
   tiles -int- the number of tiles to break the image to (e.g., 4 means 4x4 = 16 tiles)
   multi_processor -int- 1 if more than one signatures process should be running
   large_set -int- whether to use the large set of image features or not
*/


int TrainingSet::LoadFromDir(char *filename, int log, int print_to_screen, int tiles, int multi_processor, int large_set, int compute_colors, int downsample)
{  DIR *root_dir,*class_dir;
   struct dirent *ent;
   FILE *log_file, *sig_file;
   char buffer[256],image_file_name[256];
   char files_in_class[2048][64];
   int res,samp_class=1;
   if (!(root_dir=opendir(filename))) return(0);
   if (tiles<1) tiles=1;    /* at least one tile */
   while (ent = readdir(root_dir))
   {  int file_index,files_in_class_count=0;
      if (strchr(ent->d_name,'.')) continue;         /* ignore the '.' and '..' entries or files     */
      strcpy(class_labels[samp_class],ent->d_name);  /* the label of the class is the directory name */
      /* constract the path of the class files */
      strcpy(buffer,filename);
      strcat(buffer,"/");
      strcat(buffer,ent->d_name);
      /* get the file names */
      class_dir=opendir(buffer);
      while (ent = readdir(class_dir))
      {  if (ent->d_name[0]=='.') continue;      /* ignore the '.' and '..' entries */
         if (strstr(ent->d_name,".bmp")==NULL && strstr(ent->d_name,".tif")==NULL && strstr(ent->d_name,".ppm")==NULL) continue;  /* process only image files */
      	   strcpy(files_in_class[files_in_class_count++],ent->d_name);
      }
      closedir(class_dir);
      qsort(files_in_class,files_in_class_count,sizeof(files_in_class[0]), comp_strings);

	  /* process the files in the directory */
      for (file_index=0;file_index<files_in_class_count;file_index++)
      {  ImageMatrix *matrix;
         signatures *ImageSignatures;
         matrix=new ImageMatrix;
         strcpy(image_file_name,buffer);
         strcat(image_file_name,"/");
         strcat(image_file_name,files_in_class[file_index]);
         if (print_to_screen) printf("Loading image %s\n",image_file_name);
         if (log)  /* write to a log file */
         {  if (log_file=fopen("sigs.log","w"))
            {  fprintf(log_file,"Loading image %s",image_file_name);
               fclose(log_file);
            }
         }
         res=0;
#ifdef WIN32
         if (strstr(image_file_name,".bmp") || strstr(image_file_name,".BMP"))
           res=matrix->LoadBMP(image_file_name,cmHSV);
#else
   if (strstr(image_file_name,".bmp")) continue;    
         if (strstr(image_file_name,".tif") || strstr(image_file_name,".TIF"))
         {  res=matrix->LoadTIFF(image_file_name);
// if (res && matrix->bits==16) matrix->to8bits();	 
         }
#endif
         if (strstr(image_file_name,".ppm") || strstr(image_file_name,".PPM"))
           res=matrix->LoadPPM(image_file_name,cmHSV);
         if (res)  /* add the image only if it was loaded properly */
         {  int tile_index_x,tile_index_y;
		    if (downsample>0 && downsample<100)
			  matrix->Downsample(((double)downsample)/100.0,((double)downsample)/100.0);   /* downsample the image */
            for (tile_index_y=0;tile_index_y<tiles;tile_index_y++)
	        for (tile_index_x=0;tile_index_x<tiles;tile_index_x++)
	        {  ImageMatrix *tile_matrix;
	           long tile_x_size=(long)(matrix->width/tiles);
	    	   long tile_y_size=(long)(matrix->height/tiles);
	           if (tiles>1) tile_matrix=new ImageMatrix(matrix,tile_index_x*tile_x_size,tile_index_y*tile_y_size,(tile_index_x+1)*tile_x_size,(tile_index_y+1)*tile_y_size);
	    	   else tile_matrix=matrix;
               /* compute the image features */
               ImageSignatures=new signatures;
               strcpy(ImageSignatures->full_path,image_file_name);
               /* check if the features for that image were processed by another process */
               if (multi_processor)
               {  if (!(sig_file=ImageSignatures->FileOpen(NULL,tile_index_x,tile_index_y)))
                  {  delete ImageSignatures;
                     if (tiles>1) delete tile_matrix;
                     continue;
                  }
               }
               /* compute the features */
               if (large_set) ImageSignatures->ComputeGroups(tile_matrix,compute_colors);
               else ImageSignatures->compute(tile_matrix,compute_colors);
               ImageSignatures->sample_class=samp_class;
               if (!multi_processor)
                 AddSample(ImageSignatures);
	           if (tiles>1) delete tile_matrix;
               if (multi_processor)
               {  ImageSignatures->SaveToFile(sig_file);
                  ImageSignatures->FileClose(sig_file);
                  delete ImageSignatures;
               }
	        }
         }
		 else if (print_to_screen) printf("Could not open image '%s' \n",image_file_name);
         delete matrix;
      }
//      closedir(class_dir);
      samp_class++;
   }
   class_num=samp_class-1;
   closedir(root_dir);

   if (multi_processor)
     AddAllSignatures(filename);
	 
   return(1);
}



/* Test
   Test the classification accuracy using two sets of signatures
   method -int- 0 - WNN,   1 - DWNN-5
   confusion_matrix -unsigned short *- an (N+1)x(N+1) pre-allocated structure for the confusion matrix. will be ignored if NULL
   confusion_matrix -unsigned short *- an (N+1)x(N+1) pre-allocated structure for the normalized similarity matrix. will be ignored if NULL
   tiles -int- number of tiles of each image. will be ignored if equal to 0 or 1.
*/
double TrainingSet::Test(TrainingSet *TestSet, int method, unsigned short *confusion_matrix, double *similarity_matrix,int tiles)
{  int test_sample_index,predicted_class,tile_index,a,b;
   signatures *test_signature;
   long accurate_prediction=0;
   double probabilities[MAX_CLASS_NUM],probabilities_sum[MAX_CLASS_NUM];
   if (tiles<1) tiles=1;   /* make sure the number of tiles is at least 1*/
   
   /*initialize the confusion and similarity matrix */
   if (confusion_matrix)
     for (a=0;a<(class_num+1)*(class_num+1);a++) confusion_matrix[a]=0;
   if (similarity_matrix)
     for (a=0;a<(class_num+1)*(class_num+1);a++) similarity_matrix[a]=0.0;	
	  
   /* test */
   tile_index=0;
   for (a=0;a<=class_num;a++) probabilities_sum[a]=0;
   /* start going over the test samples */   
   for (test_sample_index=0;test_sample_index<TestSet->count;test_sample_index++)
   {  char last_path[IMAGE_PATH_LENGTH];
      test_signature=TestSet->samples[test_sample_index]->duplicate();  //new signatures(&(TestSet->samples[test_sample_index]),TestSet->signature_count);
      if (method==0) predicted_class=WNNclassify(test_signature, probabilities);
      if (method==1) predicted_class=classify3(test_signature, probabilities);
      /* check that the tile is consistent */
      if (tile_index>0 && (strcmp(last_path,test_signature->full_path)!=0)) printf("inconsistent tile %d of image '%s' \n",tile_index,test_signature->full_path);
      else strcpy(last_path,test_signature->full_path);
      /* if the tiles are done for the image - classify the image based on the tile marginal probabilities */
      tile_index++;
      for (a=1;a<=class_num;a++) probabilities_sum[a]+=probabilities[a];
      if (tile_index==tiles)
      {  double max=0;
         for (a=1;a<=class_num;a++) if (probabilities_sum[a]>max)
      	 {  max=probabilities_sum[a];
      	    predicted_class=a;
      	 }
         if (predicted_class==test_signature->sample_class) accurate_prediction++;
         if (confusion_matrix)
         confusion_matrix[class_num*test_signature->sample_class+predicted_class]++;
         if (similarity_matrix)
      	    for (a=1;a<=class_num;a++) similarity_matrix[class_num*test_signature->sample_class+a]+=probabilities_sum[a];
         for (a=0;a<=class_num;a++) probabilities_sum[a]=0;		   /* initialize for the next image */
         tile_index=0;
      }
      delete test_signature;
   }

   /* normalize the similarity matrix */
   if (similarity_matrix)
     for (a=1;a<=class_num;a++)
     { double class_sim=similarity_matrix[class_num*a+a];
       for (b=1;b<=class_num;b++)
         similarity_matrix[class_num*a+b]/=class_sim;
     }

   return((double)accurate_prediction/(TestSet->count/tiles));
}


/* normalize
   normalize the signature in the training set to the interval [0,100]
*/


int compare_two_doubles (const void *a, const void *b)
{
  if (*((double *)a) > *((double*)b)) return(1);
  if (*((double*)a) == *((double*)b)) return(0);
  return(-1);
}

void TrainingSet::normalize()
{  int sig_index,samp_index,max_value_index;
   double *sig_data,min_value,max_value;
   sig_data=new double[count];
   for (sig_index=0;sig_index<signature_count;sig_index++)
   {  for (samp_index=0;samp_index<count;samp_index++)
       sig_data[samp_index]=samples[samp_index]->data[sig_index].value;
      qsort(sig_data,count,sizeof(double),compare_two_doubles);
      max_value_index=count;
      while (sig_data[max_value_index]==INF && max_value_index>0) max_value_index--;  /* make sure the maximum value is not SIG_INF */
      max_value=sig_data[(int)(0.975*max_value_index)];
      min_value=sig_data[(int)(0.025*count)];
      SignatureMaxes[sig_index]=max_value;   /* these values of min and max can be used for normalizing a test vector */
      SignatureMins[sig_index]=min_value;
      for (samp_index=0;samp_index<count;samp_index++)
      { if (samples[samp_index]->data[sig_index].value>=INF) samples[samp_index]->data[sig_index].value=0;
        else
        if (samples[samp_index]->data[sig_index].value<min_value) samples[samp_index]->data[sig_index].value=min_value;
        else
        if (samples[samp_index]->data[sig_index].value>max_value) samples[samp_index]->data[sig_index].value=max_value;
        else
        if (min_value>=max_value) samples[samp_index]->data[sig_index].value=0; /* prevent possible division by zero */
        else
        samples[samp_index]->data[sig_index].value=100*(samples[samp_index]->data[sig_index].value-min_value)/(max_value-min_value);
      }
   }
   delete sig_data;
}


/* SetFisherScores
   Compute the fisher score of each signature
   used_signatures -double- what fraction of the signatures should be used (a value between 0 and 1).
   sorted_feature_names -char *- a text of the names and scores of the features (NULL to ignore)
*/
void TrainingSet::SetFisherScores(double used_signatures, char *sorted_feature_names)
{  int sample_index,sig_index,class_index;
   double mean,var,class_dev_from_mean,mean_inner_class_var;
   double *class_mean,*class_var,*class_count;
   class_mean=new double[class_num+1];
   class_var=new double[class_num+1];
   class_count=new double[class_num+1];
   double signature_weight_values[MAX_SIGNATURE_NUM],threshold;

   for (sig_index=0;sig_index<signature_count;sig_index++)
   {
      /* initialize */
      for (class_index=0;class_index<=class_num;class_index++)
      {  class_mean[class_index]=0;
         class_var[class_index]=0;
         class_count[class_index]=0;
      }
      mean=0;
      var=0;
      /* find the means */
      for (sample_index=0;sample_index<count;sample_index++)
      {  class_mean[samples[sample_index]->sample_class]+=samples[sample_index]->data[sig_index].value;
         class_count[samples[sample_index]->sample_class]+=1;
      }
	  
	  for (class_index=1;class_index<=class_num;class_index++)
        if (class_count[class_index])
          class_mean[class_index]/=class_count[class_index];

      /* find the variance */
      for (sample_index=0;sample_index<count;sample_index++)
         class_var[samples[sample_index]->sample_class]+=pow(samples[sample_index]->data[sig_index].value-class_mean[samples[sample_index]->sample_class],2);

      for (class_index=1;class_index<=class_num;class_index++)
        if (class_count[class_index])
          class_var[class_index]/=class_count[class_index];

      /* compute fisher score */

      /* find the mean of all means */
      for (class_index=1;class_index<=class_num;class_index++)
        mean+=class_mean[class_index];
      mean/=class_num;
      /* find the variance of all means */
      class_dev_from_mean=0;
      for (class_index=1;class_index<=class_num;class_index++)
        class_dev_from_mean+=pow(class_mean[class_index]-mean,2);
      class_dev_from_mean/=(class_num-1);

      mean_inner_class_var=0;
      for (class_index=1;class_index<=class_num;class_index++)
        mean_inner_class_var+=class_var[class_index];
      mean_inner_class_var/=class_num;
	  if (mean_inner_class_var==0) mean_inner_class_var+=0.000001;   /* avoid division by zero - and avoid INF values */
      
	  SignatureWeights[sig_index]=class_dev_from_mean/mean_inner_class_var;
      if (SignatureWeights[sig_index]>1000) printf("%s %f\n",SignatureNames[sig_index],SignatureWeights[sig_index]);	  
   }

   /* now set to 0 all signatures that are below the threshold */
   for (sig_index=0;sig_index<signature_count;sig_index++)
     signature_weight_values[sig_index]=SignatureWeights[sig_index];
   qsort(signature_weight_values,signature_count,sizeof(double),compare_two_doubles);
   threshold=signature_weight_values[(int)((1-used_signatures)*signature_count)];
   for (sig_index=0;sig_index<signature_count;sig_index++)
     if (SignatureWeights[sig_index]<threshold) SignatureWeights[sig_index]=0.0;
   
   /* copy the feature names and scores into a string. the features will be ordered by their fisher scores */
   if (sorted_feature_names)
   {  int sig_index2;
      sorted_feature_names[0]='\0';
      for (sig_index=signature_count-1;sig_index>=(long)((1-used_signatures)*signature_count)-5;sig_index--)
	    for (sig_index2=0;sig_index2<signature_count;sig_index2++)
	      if (signature_weight_values[sig_index]==SignatureWeights[sig_index2])
		  {  char feature_string[128];
		     sprintf(feature_string,"%d. %s: %f\n",signature_count-sig_index,SignatureNames[sig_index2],SignatureWeights[sig_index2]);
		     strcat(sorted_feature_names,feature_string);
		 	 break;                                         /* no need to complete the loop */
		  }
   }

   delete class_mean;
   delete class_var;
   delete class_count;
}

/* WNNclassify
   classify a given sample using weighted nearest neioghbor
   test_sample -signature *- a given sample to classify
   dists -array of double- an array (size num_classes) of the distances from each class (ignored if NULL)
   returned value -long- the predicted class of the sample

   comment: must set weights before calling to this function
*/
long TrainingSet::WNNclassify(signatures *test_sample, double *probabilities)
{  int class_index,sample_index,sig_index;
   long most_probable_class;
   double closest_dist=INF;

   /* initialize the probabilities */
   if (probabilities)
     for (class_index=0;class_index<=class_num;class_index++)
       probabilities[class_index]=INF;

   /* normalize the test sample */
   test_sample->normalize(this);

   for (sample_index=0;sample_index<count;sample_index++)
   {  double dist=0;
      for (sig_index=0;sig_index<signature_count;sig_index++)
        dist+=SignatureWeights[sig_index]*pow(test_sample->data[sig_index].value-samples[sample_index]->data[sig_index].value,2);
      dist=sqrt(dist);
      if (dist<closest_dist)
      {  closest_dist=dist;
         most_probable_class=samples[sample_index]->sample_class;
      }
      /* set the distance from classes */
      if (probabilities)
        if (dist<probabilities[samples[sample_index]->sample_class])
          probabilities[samples[sample_index]->sample_class]=dist;
   }

   /* normalize the marginal probabilities */
   if (probabilities)
   {  double sum_dists=0;
      for (class_index=1;class_index<=class_num;class_index++)
        if (probabilities[class_index]!=0)
          sum_dists+=1/probabilities[class_index];
      for (class_index=1;class_index<=class_num;class_index++)
        if (sum_dists==0 || probabilities[class_index]==0) probabilities[class_index]=0;    /* protect from division by zero */
        else probabilities[class_index]=(1/probabilities[class_index])/sum_dists;
   }

   return(most_probable_class);
}


/* classify2
   classify a given sample
   test_sample -signature *- a given sample to classify
   probabilities -array of double- an array (size num_classes) of the distances from each class (ignored if NULL)
   returned value -long- the predicted class of the sample

   comment: must set weights before calling to this function
*/
long TrainingSet::classify2(signatures *test_sample, double *probabilities)
{  int sample_index,class_index,sig_index;
   long most_probable_class;
   double samp_sum,*class_sum,other_classes_sum,*samples_num;
   double dist,closest_dist=INF;

   /* normalize the test sample */
   test_sample->normalize(this);

   /* allocate and initialize memory */
   class_sum=new double[class_num+1];
   samples_num=new double[class_num+1];
   for (class_index=0;class_index<=class_num;class_index++)
   {  class_sum[class_index]=0;
      samples_num[class_index]=0;
   }
   other_classes_sum=0;

   for (sample_index=0;sample_index<count;sample_index++)
   {  samp_sum=0;
      for (sig_index=0;sig_index<signature_count;sig_index++)
        samp_sum+=pow(SignatureWeights[sig_index],1)*pow(test_sample->data[sig_index].value-samples[sample_index]->data[sig_index].value,2);
      other_classes_sum+=pow(samp_sum,0.5);
      class_sum[samples[sample_index]->sample_class]+=pow(samp_sum,0.5);
      samples_num[samples[sample_index]->sample_class]+=1;
   }

   for (class_index=1;class_index<=class_num;class_index++)
   {
/*
      class_sum=0;
      other_classes_sum=0;
      for (sample_index=0;sample_index<count;sample_index++)
      {  samp_sum=0;
         for (sig_index=0;sig_index<signature_count;sig_index++)
           samp_sum+=pow(SignatureWeights[sig_index],1)*pow(test_sample->data[sig_index].value-samples[sample_index].data[sig_index],2);
         if (samples[sample_index].sample_class==class_index)
           class_sum+=pow(samp_sum,2);
         else
           other_classes_sum+=pow(samp_sum,2);
      }
*/
      if (samples_num[class_index]==0) class_sum[class_index]=INF;   /* no samples for this class */
      class_sum[class_index]/=samples_num[class_index];    /* find the average distance per sample */
      dist=class_sum[class_index];    ///(other_classes_sum/count-class_sum[class_index]);
      if (dist<closest_dist)
      {  closest_dist=dist;
         most_probable_class=class_index;
      }
      if (probabilities) probabilities[class_index]=dist;
   }

   if (probabilities)
   {  double sum_dists=0;
      for (int dist_index=1;dist_index<=class_num;dist_index++)
        if (probabilities[dist_index]!=0)
           sum_dists+=1/probabilities[dist_index];
      for (int dist_index=1;dist_index<=class_num;dist_index++)
        if (sum_dists==0 || probabilities[class_index]==0) probabilities[class_index]=0;    /* protect from division by zero */
        else probabilities[dist_index]=(1/probabilities[dist_index])/sum_dists;
   }

   delete class_sum;
   delete samples_num;

   return(most_probable_class);
}

/* classify3
   test_sample -signature *- a given sample to classify
   probabilities -array of double- an array (size num_classes) of the distances from each class (ignored if NULL)
*/
long TrainingSet::classify3(signatures *test_sample, double *probabilities)
{  int dist_index,class_index,sig_index,sample_index;
   long *num_samples,min_samples=10E10;
   int max_class;
   double *min_dists;
   long *min_dists_classes;
   double *sig_probs;
   int most_probable_class;

   /* initialize the probabilities */
   for (class_index=0;class_index<=class_num;class_index++)
     probabilities[class_index]=1;

   /* find the number of samples of the smallest class */
   num_samples=new long[class_num+1];
   for (class_index=0;class_index<=class_num;class_index++)
     num_samples[class_index]=0;
   for (sample_index=0;sample_index<count;sample_index++)
     num_samples[samples[sample_index]->sample_class]+=1;
   for (class_index=1;class_index<=class_num;class_index++)
     if (num_samples[class_index]<min_samples) min_samples=num_samples[class_index];

   min_dists=new double[min_samples];
   min_dists_classes=new long[min_samples];
   for (sig_index=0;sig_index<signature_count;sig_index++)
   {  int close_index,total_num_min_dist=0;
      for (dist_index=0;dist_index<min_samples;dist_index++)
        min_dists[dist_index]=INF;
      for (sample_index=0;sample_index<count;sample_index++)
      {  double dist;
         dist=fabs(test_sample->data[sig_index].value-samples[sample_index]->data[sig_index].value);
         /* check if this dist should be in the close list */
         for (close_index=0;close_index<min_samples;close_index++)
         if (dist<min_dists[close_index])
         {  memmove(&(min_dists[close_index+1]),&(min_dists[close_index]),sizeof(double)*(min_samples-1-close_index));
            memmove(&(min_dists_classes[close_index+1]),&(min_dists_classes[close_index]),sizeof(long)*(min_samples-1-close_index));
            min_dists[close_index]=dist;
            min_dists_classes[close_index]=samples[sample_index]->sample_class;
            break;
         }
      }

      /* find the number of samples with the same minimal value */
      for (sample_index=0;sample_index<count;sample_index++)
        if (fabs(test_sample->data[sig_index].value-samples[sample_index]->data[sig_index].value)<=min_dists[min_samples-1])
          total_num_min_dist++;
/* if all other distances are in the same class then reduce total_num_min_dist */
      /* find the number of times each class appears */
      for (class_index=0;class_index<=class_num;class_index++)
        num_samples[class_index]=0;
      for (close_index=0;close_index<min_samples;close_index++)
        num_samples[min_dists_classes[close_index]]+=1;
      /* find the max class */
      max_class=0;
      for (class_index=0;class_index<=class_num;class_index++)
        if (num_samples[class_index]>max_class) max_class=num_samples[class_index];
      /* now find the probability of each class */
      if ((double)max_class/(double)min_samples>pow(1/(double)class_num,1.0/2.0))
      for (class_index=1;class_index<=class_num;class_index++)
      {  double class_prob;
         class_prob=(double)(num_samples[class_index])/(double)min_samples;
         probabilities[class_index]=probabilities[class_index]*class_prob;
      }

   }

   /* normalize the results and find the most probable class */
   if (probabilities)
   {  double sum_dists=0;
      double highest_prob=0;
      for (class_index=1;class_index<=class_num;class_index++)
        if (probabilities[class_index]>highest_prob)
        {  highest_prob=probabilities[class_index];
           most_probable_class=class_index;
        }

      for (dist_index=1;dist_index<=class_num;dist_index++)
        if (probabilities[dist_index]!=0)
           sum_dists+=1/probabilities[dist_index];
      for (dist_index=1;dist_index<=class_num;dist_index++)
        if (sum_dists==0 || probabilities[class_index]==0) probabilities[class_index]=0;    /* protect from division by zero */
        else probabilities[dist_index]=(1/probabilities[dist_index])/sum_dists;
   }

   delete num_samples;
   delete min_dists;
   delete min_dists_classes;
   return(most_probable_class);
}

/*
PrintMatrix
print the confusion or similarity matrix
confusion_matrix -unsigned short *- the confusion matrixvalues to print
                 NULL - don't print confusion matrix
similarity_matrix -double *- the similarity matrix values to print
                 NULL - don't print similarity matrix
dend_file -unsigned short- create a dendogram input file
method -unsigned short- the method of transforming the similarity values into a single distance (0 - min, 1 - average).
*/
long TrainingSet::PrintConfusion(unsigned short *confusion_matrix, double *similarity_matrix,unsigned short dend_file, unsigned short method)
{  int class_index1,class_index2;
   if (dend_file) printf("%d\n",class_num);
   else 
   {  printf("          ");
      for (class_index1=1;class_index1<=class_num;class_index1++)
        printf("%10s",class_labels[class_index1]);
      printf("\n");
   }	 
   for (class_index1=1;class_index1<=class_num;class_index1++)
   {  if (dend_file)
      {   char label[128];
	      long sum_row=0;
          for (class_index2=1;class_index2<=class_num;class_index2++) sum_row+=confusion_matrix[class_index1*class_num+class_index2];
//	      sprintf(label,"%s %d/%d",class_labels[class_index1],confusion_matrix[class_index1*class_num+class_index1],sum_row);
	      sprintf(label,"%s",class_labels[class_index1],confusion_matrix[class_index1*class_num+class_index1],sum_row);
		  if (strlen(label)>8) strcpy(label,&(label[strlen(label)-8]));  /* make sure the labels are shorter or equal to 8 characters in length */
	      printf("%s                 ",label);
	  }
      else printf("%10s",class_labels[class_index1]);
      for (class_index2=1;class_index2<=class_num;class_index2++)
	  {  if (confusion_matrix && !dend_file)
	       printf("%10d",confusion_matrix[class_index1*class_num+class_index2]);
		 if (similarity_matrix)
	     {  double dist=0;
		    if (method==0) dist=max(1-similarity_matrix[class_index1*class_num+class_index2],1-similarity_matrix[class_index2*class_num+class_index1]);
			if (method==1) dist=((1-similarity_matrix[class_index1*class_num+class_index2])+(1-similarity_matrix[class_index2*class_num+class_index1]))/2;
		    if (dend_file) printf("%1.4f       ",dist);
			else printf("   %1.5f",similarity_matrix[class_index1*class_num+class_index2]);
		 }  
	  }	
      printf("\n");
   }	 
   printf("\n");
}


long TrainingSet::report(char *data_set_name, data_split *splits, unsigned short split_num, int tiles)
{  FILE *output_file;
   output_file=stdout;
   int class_index,class_index2,sample_index,split_index,a,test_set_size,train_set_size;
   
   /* print the header */
   fprintf(output_file,"<HTML>\n<HEAD>\n<TITLE> %s </TITLE>\n </HEAD> \n <BODY> \n <br> <h1>%s</h1><hr/>\n ",data_set_name,data_set_name);
   /* print the number of samples table */
   fprintf(output_file,"<table border=\"1\" cellspacing=\"0\" cellpadding=\"3\" align=\"center\">\" \n <caption>Number of Images from Training and Testing</caption> \n <tr>");
   for (class_index=0;class_index<=class_num;class_index++)
     fprintf(output_file,"<td>%s</td>\n",class_labels[class_index]);
   fprintf(output_file,"<td>total</td>\n");
   fprintf(output_file,"</tr>\n<tr>\n");
   fprintf(output_file,"<tr>\n<td>Training</td>\n");
   train_set_size=0;
   for (class_index=1;class_index<=class_num;class_index++)
   {  int inst_num=0;
      for (sample_index=0;sample_index<count;sample_index++)
        if (samples[sample_index]->sample_class==class_index) inst_num++;
      fprintf(output_file,"<td>%d</td>\n",(int)(inst_num/(tiles*tiles)));
      train_set_size+=inst_num;
   }
   fprintf(output_file,"<td>%d</td>\n",train_set_size); /* add the total number of training samples */
   test_set_size=0;
   fprintf(output_file,"<tr>\n<td>Testing</td>\n");
   for (class_index=1;class_index<=class_num;class_index++)
   {  int inst_num=0;
      for (class_index2=1;class_index2<=class_num;class_index2++)
        inst_num+=(splits[0].confusion_matrix[class_index*class_num+class_index2]);
      fprintf(output_file,"<td>%d</td>\n",inst_num);
      test_set_size+=inst_num;
   }
   fprintf(output_file,"<td>%d</td>\n",test_set_size); /* add the total number of test samples */
   fprintf(output_file,"</tr> \n </table>\n");

   /* print the splits */
   fprintf(output_file,"<h2><center>Results</center></h2> \n <table border=\"1\" align=\"center\"><caption></caption> \n");
   for (split_index=0;split_index<split_num;split_index++)
   {  unsigned short *confusion_matrix;
      double *similarity_matrix;
      double avg_accuracy=0,class_avg,class_sum,plus_minus=0;
      
	  confusion_matrix=splits[split_index].confusion_matrix;
	  similarity_matrix=splits[split_index].similarity_matrix;	  
	  
      for (class_index=1;class_index<=class_num;class_index++)
      {  double class_avg=0,class_sum=0;
         for (class_index2=1;class_index2<=class_num;class_index2++)
		   if (class_index==class_index2) class_avg+=confusion_matrix[class_index*class_num+class_index2];
		   else class_sum+=confusion_matrix[class_index*class_num+class_index2]; 
		 avg_accuracy+=(class_avg/(class_avg+class_sum));
	  }
      avg_accuracy/=class_num;
      for (class_index=1;class_index<=class_num;class_index++)
      {  double class_avg=0.0,class_sum=0.0;
         for (class_index2=1;class_index2<=class_num;class_index2++)
		   if (class_index==class_index2) class_avg+=confusion_matrix[class_index*class_num+class_index2];
		   else class_sum+=confusion_matrix[class_index*class_num+class_index2]; 
		 if (fabs((class_avg/(class_avg+class_sum))-avg_accuracy)>plus_minus) plus_minus=fabs((class_avg/(class_avg+class_sum))-avg_accuracy);
	  }  
	  
      fprintf(output_file,"<tr> <td>Split %d</td> \n <td align=\"center\" valign=\"top\"> \n",split_index+1);
      fprintf(output_file,"<b>%.2f &plusmn; %.1f Avg per Class Correct of total</b><br> \n",avg_accuracy,plus_minus);
      fprintf(output_file,"Accuracy: <b>%.2f of total</b><br> \n",splits[split_index].accuracy);
      fprintf(output_file,"<a href=\"#split%d\">Full details</a><br> \n",split_index);
      fprintf(output_file,"<a href=\"#features%d\">Features used</a><br> </td> </tr> \n",split_index);
   }
   fprintf(output_file,"</table>\n");
   fprintf(output_file,"<br><br><br><br><br><br> \n\n\n\n\n\n\n\n");
   
   /* average similarity and confusion matrix */
   
   fprintf(output_file,"<table border=\"1\" align=\"center\"><caption>Average Confusion Matrix</caption> \n");   
   fprintf(output_file,"<tr><td></td>\n");
   for (class_index=1;class_index<=class_num;class_index++)
     fprintf(output_file,"<td>%s</td>\n",class_labels[class_index]);
   fprintf(output_file,"</tr>\n");   
   for (class_index=1;class_index<=class_num;class_index++)
   {  fprintf(output_file,"<tr><td>%s</td>\n",class_labels[class_index]);
      for (class_index2=1;class_index2<=class_num;class_index2++)
      {  double sum=0.0;
	     for (split_index=0;split_index<split_num;split_index++)
	       sum+=splits[split_index].confusion_matrix[class_index*class_num+class_index2];
   	     fprintf(output_file,"<td>%.2f</td>\n",sum/split_num);		  
	  }
	  fprintf(output_file,"</tr>\n");
   }	  
   fprintf(output_file,"</table> \n <br><br><br><br> \n");

   fprintf(output_file,"<table border=\"1\" align=\"center\"><caption>Average Similarity Matrix</caption> \n");   
   fprintf(output_file,"<tr><td></td>\n");
   for (class_index=1;class_index<=class_num;class_index++)
     fprintf(output_file,"<td>%s</td>\n",class_labels[class_index]);   
   fprintf(output_file,"</tr>\n");   	 
   for (class_index=1;class_index<=class_num;class_index++)
   {  fprintf(output_file,"<tr><td>%s</td>\n",class_labels[class_index]);
      for (class_index2=1;class_index2<=class_num;class_index2++)
      {  double sum=0.0;
	     for (split_index=0;split_index<split_num;split_index++)
	       sum+=splits[split_index].similarity_matrix[class_index*class_num+class_index2];
   	     fprintf(output_file,"<td>%.2f</td>\n",sum/split_num);		  
	  }
	  fprintf(output_file,"</tr>\n");
   } 
   fprintf(output_file,"</table> \n <br><br><br><br> \n");

   /* print the confusion/similarity matrices and feature names for the splits */
   
	 	 
   for (split_index=0;split_index<split_num;split_index++)
   {  unsigned short *confusion_matrix;
      double *similarity_matrix;
      char feature_names[60000],*p_feature_names;
	  
	  confusion_matrix=splits[split_index].confusion_matrix;
	  similarity_matrix=splits[split_index].similarity_matrix;	  

	  fprintf(output_file,"<A NAME=\"split%d\">\n",split_index);
      fprintf(output_file,"<table border=\"1\" align=\"center\"><caption>Confusion Matrix</caption> \n");   
      fprintf(output_file,"<tr><td></td>\n");
      for (class_index=1;class_index<=class_num;class_index++)
        fprintf(output_file,"<td>%s</td>\n",class_labels[class_index]);   
      fprintf(output_file,"</tr>\n");   
      for (class_index=1;class_index<=class_num;class_index++)
      {  fprintf(output_file,"<tr><td>%s</td>\n",class_labels[class_index]);
         for (class_index2=1;class_index2<=class_num;class_index2++)
		   fprintf(output_file,"<td>%d</td>\n",confusion_matrix[class_index*class_num+class_index2]);		  
   	     fprintf(output_file,"</tr>\n");
	  }
      fprintf(output_file,"</table> \n <br><br> \n");

      fprintf(output_file,"<table border=\"1\" align=\"center\"><caption>Similarity Matrix</caption> \n");   
      fprintf(output_file,"<tr><td></td>\n");
      for (class_index=1;class_index<=class_num;class_index++)
        fprintf(output_file,"<td>%s</td>\n",class_labels[class_index]);   
      fprintf(output_file,"</tr>\n");   	  
      for (class_index=1;class_index<=class_num;class_index++)
      {  fprintf(output_file,"<tr><td>%s</td>\n",class_labels[class_index]);
         for (class_index2=1;class_index2<=class_num;class_index2++)
		   fprintf(output_file,"<td>%.2f</td>\n",similarity_matrix[class_index*class_num+class_index2]);		  
   	     fprintf(output_file,"</tr>\n");
	  }
      fprintf(output_file,"</table> \n <br><br> \n");

      fprintf(output_file,"<A NAME=\"features%d\"> \n",split_index);
	  strncpy(feature_names,splits[split_index].feature_names,sizeof(feature_names));
	  feature_names[sizeof(feature_names)-1]='\0';
	  p_feature_names=strtok(feature_names,"\n");
	  a=1;
	  while (p_feature_names)
	  {  fprintf(output_file,"%s<br>\n",p_feature_names);	  	  
	     p_feature_names=strtok(NULL,"\n");
	  }
   }

   fprintf(output_file,"<br><br><br><br><br><br> \n\n\n\n\n\n\n\n");

   fprintf(output_file,"</BODY> \n </HTML>\n");
}

#pragma package(smart_init)

