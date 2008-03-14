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
#include <sys/stat.h>
#include <sys/types.h>
#include <ctype.h>

#include "TrainingSet.h"
//#include "cmatrix.h"

#ifndef WIN32
#include <stdlib.h>
#endif


/* global variable */
int print_to_screen=1;

/* compare_two_doubles
   function used for qsort
*/
int compare_two_doubles (const void *a, const void *b)
{
  if (*((double *)a) > *((double*)b)) return(1);
  if (*((double*)a) == *((double*)b)) return(0);
  return(-1);
}

int comp_strings(const void *s1, const void *s2)
{  return(strcmp((char *)s1,(char *)s2));
}

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
//   for (sig_index=0;sig_index<new_sample->count;sig_index++)
//      if (new_sample->data[sig_index].name[0]!='\0') strcpy(SignatureNames[sig_index],new_sample->data[sig_index].name);
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

/* RemoveClass
   remove a class from the training set
   class_index -long- the index of the class to be removed
*/
void TrainingSet::RemoveClass(long class_index)
{  long index,deleted_count=0;
   /* remove the class label */
   for (index=class_index;index<class_num;index++)
     strcpy(class_labels[index],class_labels[index+1]);
   /* remove the samples of that class */
   for (index=0;index<count;index++)
   { if (samples[index]->sample_class==class_index)
     {  delete samples[index];
        deleted_count++;
     }
     else samples[index-deleted_count]=samples[index];
   }
   count=count-deleted_count;   /* set the new number of samples */   
   /* change the indices of the samples */
   for (index=0;index<count;index++)
     if (samples[index]->sample_class>class_index)
	   samples[index]->sample_class=samples[index]->sample_class-1;
   /* change the number of classes and training samples */	   
   class_num--;
   return;
}

/* SaveWeightVector
   save the weights of the features into a file 
   filename -char *- the name of the file into which the weight values should be written
*/
int TrainingSet::SaveWeightVector(char *filename)
{  FILE *sig_file;
   int sig_index;
   if (!(sig_file=fopen(filename,"w"))) return(0);
   if (print_to_screen) printf("Saving weight vector to file '%s'...\n",filename);   
   for (sig_index=0;sig_index<signature_count;sig_index++)
     fprintf(sig_file,"%f %s\n",SignatureWeights[sig_index],SignatureNames[sig_index]);
   fclose(sig_file);
   return(1);
}

/* LoadWeightVector
   load the weights of the features from a file and assign them to the features of the training set
   filename -char *- the name of the file into which the weight values should be read from
   factor -double- multiple the loaded feature vector and add to the existing vecotr (-1 is subtracting). 0 replaces the existing vector with the loaded vector.
   returned value -double- the square difference between the original weight vector and the imported weight vector
*/
double TrainingSet::LoadWeightVector(char *filename, double factor)
{  FILE *sig_file;
   int sig_index=0;
   char line[128],*p_line;
   double feature_weight_distance=0.0;
   if (!(sig_file=fopen(filename,"r"))) return(0);
   if (print_to_screen) printf("Loading weight vector from file '%s'...\n",filename);
   p_line=fgets(line,sizeof(line),sig_file);
   while (p_line)
   {  if (strlen(p_line)>0)
      {  if (strchr(p_line,' ')) (*strchr(p_line,' '))='\0';
         feature_weight_distance+=pow(SignatureWeights[sig_index]-atof(p_line),2);
         if (factor==0) SignatureWeights[sig_index++]=atof(p_line);
	     else SignatureWeights[sig_index++]+=factor*atof(p_line);
         if (SignatureWeights[sig_index-1]<0) SignatureWeights[sig_index-1]=0;		  
	  }
      p_line=fgets(line,sizeof(line),sig_file);   
   }
   fclose(sig_file);
   if (sig_index!=signature_count) return(-1.0);
   return(sqrt(feature_weight_distance));
}

/*  split
    split randomly into a training set and a test set
    ratio -double- the ratio of the number of test set (e.g., 0.1 means 10% of the data are test data).
	tiles -unsigned short- indicates the number of tiles to which each image was divided into. This means that
	                       when splitting to train and test, all tiles of that one image will be either in the
		     	       test set or training set.
    max_train_samples -int- the maximum number of samples to use for training (0 to ignore and use the proportional part of the set)
	max_test_samples -int- the maximum namber of samples for the test set (0 to ignore and use the proportional part of the set)
	exact_max_train -int- if 1 then the class is removed if its number of samples does not reach the "max_train_samples". (ignored if 0)
*/
void TrainingSet::split(double ratio,TrainingSet *TrainSet,TrainingSet *TestSet, unsigned short tiles, int max_train_samples, int max_test_samples, int exact_max_train)
{  long *class_samples;
   int class_index,sig_index,tile_index;
   int number_of_test_samples;
   long class_counts[MAX_CLASS_NUM];
   class_samples = new long[count];

   /* copy the class labels to the train and test */
   for (class_index=0;class_index<=class_num;class_index++)
   {  strcpy(TrainSet->class_labels[class_index],class_labels[class_index]);
      strcpy(TestSet->class_labels[class_index],class_labels[class_index]);
   }
   
   /* copy the signature names to the training and test set */
   for (sig_index=0;sig_index<signature_count;sig_index++)
   {  strcpy(TrainSet->SignatureNames[sig_index],SignatureNames[sig_index]);
      strcpy(TestSet->SignatureNames[sig_index],SignatureNames[sig_index]);	  
   }
      
   if (tiles<1) tiles=1;    /* make sure the number of tiles is valid */
//class_num=250; /* FERET */   
   TrainSet->class_num=TestSet->class_num=class_num;   
   for (class_index=1;class_index<=class_num;class_index++)
   {  int sample_index,sample_count=0;
      int class_samples_count=0;
      for (sample_index=0;sample_index<count;sample_index++)
        if (samples[sample_index]->sample_class==class_index)
//if (strstr(samples[sample_index]->full_path,"_fa") || strstr(samples[sample_index]->full_path,"_fb") || strstr(samples[sample_index]->full_path,"_rc") || strstr(samples[sample_index]->full_path,"_rb") || strstr(samples[sample_index]->full_path,"_ql") || strstr(samples[sample_index]->full_path,"_qr"))	  	/* FERET */
          class_samples[class_samples_count++]=sample_index;	  
      class_samples_count/=tiles;
	  class_counts[class_index]=class_samples_count;
      /* add the samples to the test set */
      number_of_test_samples=(int)(class_samples_count*ratio);
	  if (max_train_samples>0) number_of_test_samples=max(0,class_samples_count-max_train_samples);	  
      if (max_test_samples>0 && number_of_test_samples>max_test_samples) number_of_test_samples=max_test_samples;
      for (sample_index=0;sample_index<number_of_test_samples;sample_index++)
      {  int rand_index;
         rand_index=rand() % class_samples_count;            /* find a random sample  */

//int b=0;   /* FERET */
//for (int a=0;a<class_samples_count;a++)
//if (strstr(samples[class_samples[a*tiles]]->full_path,"_fb"))
//{ rand_index=a;
//  b=1;
//  break;
//}
//if (b==0) break;

         for (tile_index=0;tile_index<tiles;tile_index++)    /* add all the tiles of that image */
           TestSet->AddSample(samples[class_samples[rand_index*tiles+tile_index]]->duplicate());   /* add the random sample */		   
         /* remove the index */
         memmove(&(class_samples[rand_index*tiles]),&(class_samples[rand_index*tiles+tiles]),sizeof(long)*(tiles*(class_samples_count-rand_index)));
         class_samples_count--;
      }
	  
      /* now add the remaining samples to the Train Set */	  	  
      for (sample_index=0;sample_index<class_samples_count*tiles && (sample_count<max_train_samples*tiles || max_train_samples<=0);sample_index++)
//if (strstr(samples[class_samples[sample_index]]->full_path,"_fa") || strstr(samples[class_samples[sample_index]]->full_path,"_fb") || strstr(samples[class_samples[sample_index]]->full_path,"_hr") || strstr(samples[class_samples[sample_index]]->full_path,"_hl") || strstr(samples[class_samples[sample_index]]->full_path,"_pr"))	  	/* FERET */
//if (strstr(samples[class_samples[sample_index]]->full_path,"_fa")) /* FERET */
//if (strstr(samples[class_samples[sample_index]]->full_path,"_fa") || strstr(samples[class_samples[sample_index]]->full_path,"_fb") || strstr(samples[class_samples[sample_index]]->full_path,"_rc") || strstr(samples[class_samples[sample_index]]->full_path,"_rb") || strstr(samples[class_samples[sample_index]]->full_path,"_ql") || strstr(samples[class_samples[sample_index]]->full_path,"_qr"))	  	/* FERET */
      {  TrainSet->AddSample(samples[class_samples[sample_index]]->duplicate());
         sample_count++;
      }
   }

   /* remove the class if it doesn't have enough samples */
   class_index=class_num;
   if (exact_max_train)
   while (class_index>0)
   {  if (class_counts[class_index]<=max_train_samples-max_test_samples)
      {  TrainSet->RemoveClass(class_index);
	     TestSet->RemoveClass(class_index);
	     RemoveClass(class_index);
	  }
	  class_index--;
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
		   ImageSignatures->NamesTrainingSet=this;
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

int TrainingSet::AddAllSignatures(char *filename)
{  DIR *root_dir,*class_dir;
   struct dirent *ent;
   FILE *sig_file;
   char buffer[512],sig_file_name[512];
   char files_in_class[4096][64];
   int res,samp_class=1;
//   if (!(root_dir=opendir(filename))) return(0);   
//   while (ent = readdir(root_dir))
   while (samp_class<=class_num)
   {  int file_index,files_in_class_count=0;
//      if (strchr(ent->d_name,'.')) continue;   /* ignore the '.' and '..' entries or files     */
//      strcpy(class_labels[samp_class],ent->d_name);        /* the label of the class is the directory name */
      sprintf(buffer,"%s/%s",filename,class_labels[samp_class]);
//	  strcpy(buffer,filename);
//      strcat(buffer,"/");
//      strcat(buffer,ent->d_name);
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
//         strcpy(sig_file_name,buffer);
//         strcat(sig_file_name,"/");
//         strcat(sig_file_name,files_in_class[file_index]);
         sprintf(sig_file_name,"%s/%s",buffer,files_in_class[file_index]);
         ImageSignatures = new signatures;
         ImageSignatures->NamesTrainingSet=this;		 
         if (ImageSignatures->LoadFromFile(sig_file_name))
         {  ImageSignatures->sample_class=samp_class;   /* make sure the sample has the right class ID */
            AddSample(ImageSignatures);
         }
         else delete ImageSignatures;
//         }
      }
//      closedir(class_dir);
      samp_class++;
   }
//   closedir(root_dir);
}


/* LoadFromDir
   load a set of image into the training set
   filename -char *- a root directory - each class is a sub-directory.
   returned value -int- 1 is succeeded 0 if failed
   tiles -int- the number of tiles to break the image to (e.g., 4 means 4x4 = 16 tiles)
   multi_processor -int- 1 if more than one signatures process should be running
   large_set -int- whether to use the large set of image features or not
*/


int TrainingSet::LoadFromDir(char *filename, int tiles, int multi_processor, int large_set, int compute_colors, int downsample)
{  DIR *root_dir,*class_dir;
   struct dirent *ent;
   FILE *sig_file;
   char buffer[256],image_file_name[256];
   char files_in_class[4096][64];
   char dirs_in_root[MAX_CLASS_NUM][64];
   int dirs_count=0;
   int res,samp_class=1;

   if (filename[strlen(filename)-1]=='/') filename[strlen(filename)-1]='\0';  /* remove a last '/' is there is one       */
   if (!(root_dir=opendir(filename))) return(0);
   if (tiles<1) tiles=1;    /* at least one tile */
   while (ent = readdir(root_dir))
   {  if (strchr(ent->d_name,'.') || strcmp(ent->d_name,"tsv")==0) continue;   /* ignore the '.' and '..' entries or files, and the automatically generated tsv directory */
      strcpy(class_labels[samp_class],ent->d_name);                            /* the label of the class is the directory name */
      samp_class++;
   }
   closedir(root_dir);
   class_num=samp_class-1;   
   qsort(&(class_labels[1]),class_num,sizeof(class_labels[1]),comp_strings);

   samp_class=1;
   while (samp_class<=class_num)
   {  int file_index,files_in_class_count=0;
      /* constract the path of the class files */
      strcpy(buffer,filename);
      strcat(buffer,"/");
      strcat(buffer,class_labels[samp_class]);
      /* get the file names */
      class_dir=opendir(buffer);
      while (ent = readdir(class_dir))
      {  if (ent->d_name[0]=='.') continue;          /* ignore the '.' and '..' entries */
         if (strstr(ent->d_name,".bmp")==NULL && strstr(ent->d_name,".tif")==NULL && strstr(ent->d_name,".ppm")==NULL) continue;  /* process only image files */
      	   strcpy(files_in_class[files_in_class_count++],ent->d_name);
      }
      closedir(class_dir);
      qsort(files_in_class,files_in_class_count,sizeof(files_in_class[0]), comp_strings);

	  /* process the files in the directory */
      for (file_index=0;file_index<files_in_class_count;file_index++)
      {  ImageMatrix *matrix;
         signatures *ImageSignatures;
//ImageMatrix *TempMatrix;		 
         matrix=new ImageMatrix;
         strcpy(image_file_name,buffer);
         strcat(image_file_name,"/");
         strcat(image_file_name,files_in_class[file_index]);
         if (print_to_screen) printf("Loading image %s\n",image_file_name);
         res=0;
#ifdef WIN32
         if (strstr(image_file_name,".bmp") || strstr(image_file_name,".BMP"))
           res=matrix->LoadBMP(image_file_name,cmHSV);
#else
//         if (strstr(image_file_name,".bmp")) continue;
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
//matrix->flip();
//printf("flipping image '%s'\n",image_file_name);			  
//TempMatrix=new ImageMatrix(matrix,0,0,42,80);
//delete matrix;
//matrix=TempMatrix;
//double min,max;
//matrix->BasicStatistics(NULL, NULL, NULL, &min, &max, NULL, 0);
//matrix->normalize(min,max,(int)(pow(2,16)));
            for (tile_index_y=0;tile_index_y<tiles;tile_index_y++)
              for (tile_index_x=0;tile_index_x<tiles;tile_index_x++)
              {  ImageMatrix *tile_matrix;
                 long tile_x_size=(long)(matrix->width/tiles);
                 long tile_y_size=(long)(matrix->height/tiles);
                 if (tiles>1) tile_matrix=new ImageMatrix(matrix,tile_index_x*tile_x_size,tile_index_y*tile_y_size,(tile_index_x+1)*tile_x_size,(tile_index_y+1)*tile_y_size);
                 else tile_matrix=matrix;
                 /* compute the image features */
                 ImageSignatures=new signatures;
                 ImageSignatures->NamesTrainingSet=this;
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
               {  ImageSignatures->SaveToFile(sig_file,1);
                  ImageSignatures->FileClose(sig_file);
                  delete ImageSignatures;
               }
            }
         }
         else if (print_to_screen) printf("Could not open '%s' \n",image_file_name);
         delete matrix;
      }
      samp_class++;
    }

    if (multi_processor)
      AddAllSignatures(filename);

    return(1);
}



/* Test
   Test the classification accuracy using two sets of signatures
   method -int- 0 - WNN,   1 - DWNN-5
   confusion_matrix -unsigned short *- an (N+1)x(N+1) pre-allocated structure for the confusion matrix. will be ignored if NULL
   confusion_matrix -unsigned short *- an (N+1)x(N+1) pre-allocated structure for the normalized similarity matrix. will be ignored if NULL
   tiles -int- number of tiles of each image.
   rank -long- the number of first closest classes among which a presence of the right class is considered a match
   report_string -char *- the outpust string for showing the classification of each image (ignored if NULL)
*/
double TrainingSet::Test(TrainingSet *TestSet, int method, unsigned short *confusion_matrix, double *similarity_matrix,int tiles, long rank, char *report_string)
{  int test_sample_index,predicted_class,tile_index,class_index,b;
   signatures *test_signature;
   long accurate_prediction=0,interpolate=1;
   double probabilities[MAX_CLASS_NUM],probabilities_sum[MAX_CLASS_NUM],normalization_factor;
   char interpolated_value[128];
   if (tiles<1) tiles=1;       /* make sure the number of tiles is at least 1 */
   if (rank<=0) rank=1;  /* set a valid value to rank                */
   if (report_string) strcpy(report_string,"");    /* make sure the string is initially empty */
   
   /* interpolate only if all class labels are values */
   for (class_index=1;class_index<class_num;class_index++)
     interpolate*=(atof(class_labels[class_index])!=0.0 || class_labels[class_index][0]=='0');
        
   /*initialize the confusion and similarity matrix */
   if (confusion_matrix)
     for (class_index=0;class_index<(class_num+1)*(class_num+1);class_index++) confusion_matrix[class_index]=0;
   if (similarity_matrix)
     for (class_index=0;class_index<(class_num+1)*(class_num+1);class_index++) similarity_matrix[class_index]=0.0;

   /* test */
   tile_index=0;
   for (class_index=0;class_index<=class_num;class_index++) probabilities_sum[class_index]=0;
   /* start going over the test samples */
//TestSet->count=250*tiles;   /* FERET */
   for (test_sample_index=0;test_sample_index<TestSet->count;test_sample_index++)
   {  char last_path[IMAGE_PATH_LENGTH];
      signatures *closest_sample;
	  if (print_to_screen) printf("Testing image %s (%d/%d)...\n",TestSet->samples[test_sample_index]->full_path,test_sample_index/tiles,TestSet->count/tiles);	  
      test_signature=TestSet->samples[test_sample_index]->duplicate();  //new signatures(&(TestSet->samples[test_sample_index]),TestSet->signature_count);
      if (method==WNN) predicted_class=WNNclassify(test_signature, probabilities,&normalization_factor,&closest_sample);
      if (method==WND) predicted_class=classify2(test_signature, probabilities,&normalization_factor);
//if (method==WND) predicted_class=classify3(test_signature, probabilities, &normalization_factor);

      /* check that the tile is consistent */
      if (tile_index>0 && (strcmp(last_path,test_signature->full_path)!=0)) printf("inconsistent tile %d of image '%s' \n",tile_index,test_signature->full_path);
      else strcpy(last_path,test_signature->full_path);
      /* if the tiles are done for the image - classify the image based on the tile marginal probabilities */
      tile_index++;
      for (class_index=1;class_index<=class_num;class_index++) probabilities_sum[class_index]+=(probabilities[class_index]/(double)tiles);
      if (tile_index==tiles)
      {  int cand;
         for (class_index=1;class_index<=class_num;class_index++) probabilities[class_index]=0.0;  /* initialize the array */
         for (cand=0;cand<rank;cand++)
         {
            double max=0;
            for (class_index=1;class_index<=class_num;class_index++)
              if (probabilities_sum[class_index]>max && probabilities[class_index]==0.0)
              {  max=probabilities_sum[class_index];
                 predicted_class=class_index;
              }
            probabilities[predicted_class]=1.0;
            if (predicted_class==test_signature->sample_class) break;  /* class was found among the n closest */
         }
         /* update confusion and similarity matrices */
         if (predicted_class==test_signature->sample_class) accurate_prediction++;
         if (print_to_screen) printf("Actual class ID: %d     Predicted class ID: %d      Ac: %f   (%d/%d)\n",test_signature->sample_class,predicted_class,(double)(accurate_prediction*tiles)/(double)(test_sample_index+1),accurate_prediction,(test_sample_index+1)/tiles);
         if (confusion_matrix)  /* update the confusion matrix */
           confusion_matrix[class_num*test_signature->sample_class+predicted_class]++;
         if (similarity_matrix) /* update the similarity matrix */
         for (class_index=1;class_index<=class_num;class_index++) similarity_matrix[class_num*test_signature->sample_class+class_index]+=probabilities_sum[class_index];

         /* print the report to a string */
         if (report_string)
         {  char buffer[512],closest_image[512],color[128],one_image_string[MAX_CLASS_NUM*15];
            sprintf(one_image_string,"<tr><td>%d</td> <td>%.3f</td>",(int)(test_sample_index/tiles)+1,normalization_factor);  /* image index and the normlization factor */
            for (class_index=1;class_index<=class_num;class_index++)
            {  if (class_index==test_signature->sample_class) sprintf(buffer,"<td><b>%.3f</b></td>",probabilities_sum[class_index]);  /* put the actual class in bold */
               else sprintf(buffer,"<td>%.3f</td>",probabilities_sum[class_index]);
               strcat(one_image_string,buffer);
            }
            if (predicted_class==test_signature->sample_class) sprintf(color,"<font color=\"#00FF00\">Correct</font>");
            else sprintf(color,"<font color=\"#FF0000\">Incorrect</font>");
			
			/* add the interpolated value of the two top classes */
			if (interpolate)  
            {  double second_highest_prob=-1.0;
			   int second_highest_class;
               for (class_index=1;class_index<=class_num;class_index++)
			     if (probabilities_sum[class_index]>second_highest_prob && class_index!=predicted_class) 
				 {  second_highest_prob=probabilities_sum[class_index];
				    second_highest_class=class_index;
				 }
               TestSet->samples[test_sample_index]->interpolated_value=(second_highest_prob*atof(class_labels[second_highest_class])+probabilities_sum[predicted_class]*atof(class_labels[predicted_class]))/(second_highest_prob+probabilities_sum[predicted_class]);
               sprintf(interpolated_value,"<td>%.3f</td>",TestSet->samples[test_sample_index]->interpolated_value);
		    }
			else strcpy(interpolated_value,"");
			
            if (method==WNN && tiles==1) sprintf(closest_image,"<td><A HREF=\"%s\"><IMG WIDTH=40 HEIGHT=40 SRC=\"%s__1\"></A></td>",closest_sample->full_path,closest_sample->full_path);
            else strcpy(closest_image,"");
            sprintf(buffer,"<td></td><td>%s</td><td>%s</td><td>%s</td>%s<td><A HREF=\"%s\"><IMG WIDTH=40 HEIGHT=40 SRC=\"%s__1\"></A></td>%s</tr>\n",class_labels[test_signature->sample_class],class_labels[predicted_class],color,interpolated_value,test_signature->full_path,test_signature->full_path,closest_image);
            strcat(one_image_string,buffer);
            strcat(report_string,one_image_string);   /* add the image to the string */
         }

         /* initialize for the next image */
         for (class_index=0;class_index<=class_num;class_index++) probabilities_sum[class_index]=0;
         tile_index=0;
      }
      delete test_signature;
   }

   /* normalize the similarity matrix */
   if (similarity_matrix)
     for (class_index=1;class_index<=class_num;class_index++)
     { double class_sim=similarity_matrix[class_num*class_index+class_index];
       for (b=1;b<=class_num;b++)
         similarity_matrix[class_num*class_index+b]/=class_sim;
     }
   
   return((double)accurate_prediction/(TestSet->count/tiles));
}


/* normalize
   normalize the signature in the training set to the interval [0,100]
*/

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
   double signature_weight_values[MAX_SIGNATURE_NUM],threshold;   
   class_mean=new double[class_num+1];
   class_var=new double[class_num+1];
   class_count=new double[class_num+1];

   for (sig_index=0;sig_index<signature_count;sig_index++)
   {
      /* initialize */
      for (class_index=0;class_index<=class_num;class_index++)
      {  class_mean[class_index]=0.0;
         class_var[class_index]=0.0;
         class_count[class_index]=0.0;
      }
      mean=0.0;
      var=0.0;
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
      if (class_num>1) class_dev_from_mean/=(class_num-1);
	  else class_dev_from_mean=0;

      mean_inner_class_var=0;
      for (class_index=1;class_index<=class_num;class_index++)
        mean_inner_class_var+=class_var[class_index];
      mean_inner_class_var/=class_num;
      if (mean_inner_class_var==0) mean_inner_class_var+=0.000001;   /* avoid division by zero - and avoid INF values */

      SignatureWeights[sig_index]=class_dev_from_mean/mean_inner_class_var;
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
   probabilities -array of double- an array (size num_classes) marginal probabilities of the given sample from each class. (ignored if NULL).
   normalization_factor -double *- the normalization factor used to compute the marginal probabilities from the distances normalization_factor=1/(sum_dist*marginal_prob). ignored if NULL.
   closest_sample -signatures **- a pointer to the closest sample found. (ignored if NULL).
   returned value -long- the predicted class of the sample

   comment: must set weights before calling to this function
*/
long TrainingSet::WNNclassify(signatures *test_sample, double *probabilities, double *normalization_factor,signatures **closest_sample)
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
      if (dist<closest_dist && dist>1.0/INF)
      {  closest_dist=dist;
         most_probable_class=samples[sample_index]->sample_class;
         if (closest_sample) *closest_sample=samples[sample_index];		 
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
        if (sum_dists==0) probabilities[class_index]=0;    /* protect from division by zero */
        else
          if (probabilities[class_index]==0) probabilities[class_index]=1.0; /* exact match */
          else probabilities[class_index]=(1/probabilities[class_index])/sum_dists;
      if (normalization_factor) *normalization_factor=sum_dists;
   }

   return(most_probable_class);
}


/* classify2
   classify a given sample
   test_sample -signature *- a given sample to classify
   probabilities -array of double- an array (size num_classes) marginal probabilities of the given sample from each class. (ignored if NULL).
   normalization_factor -double *- the normalization factor used to compute the marginal probabilities from the distances normalization_factor=1/(dist*marginal_prob). Ignored if NULL.   
   returned value -long- the predicted class of the sample

   comment: must set weights before calling to this function
*/
long TrainingSet::classify2(signatures *test_sample, double *probabilities, double *normalization_factor)
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
      other_classes_sum+=pow(samp_sum,2);
      class_sum[samples[sample_index]->sample_class]+=pow(samp_sum,2);
      samples_num[samples[sample_index]->sample_class]+=1;
   }

   for (class_index=1;class_index<=class_num;class_index++)
     class_sum[class_index]=pow(class_sum[class_index],-10);
   other_classes_sum=pow(other_classes_sum,-10);
	 
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
     if (normalization_factor) *normalization_factor=sum_dists;				
   }

   delete class_sum;
   delete samples_num;

   return(most_probable_class);
}

/* classify3
   test_sample -signature *- a given sample to classify
   probabilities -array of double- an array (size num_classes) marginal probabilities of the given sample from each class. (ignored if NULL).
   normalization_factor -double *- the normalization factor used to compute the marginal probabilities from the distances normalization_factor=1/(dist*marginal_prob). Ignored if NULL.
*/
long TrainingSet::classify3(signatures *test_sample, double *probabilities,double *normalization_factor)
{  int dist_index,class_index,sig_index,sample_index;
   long *num_samples,*close_samples,min_samples=10000000;
   int max_class;
   double *min_dists;
   long *min_dists_classes;
   double *sig_probs;
   int most_probable_class;
   long double probs[MAX_CLASS_NUM];
   double dist;
   long size_of_class;

   /* initialize the probabilities */
   for (class_index=0;class_index<=class_num;class_index++)
     probs[class_index]=1;

   /* find the number of samples of the smallest class */
   num_samples=new long[class_num+1];
   close_samples=new long[class_num+1];
   for (class_index=0;class_index<=class_num;class_index++)
     num_samples[class_index]=0;
   for (sample_index=0;sample_index<count;sample_index++)
     num_samples[samples[sample_index]->sample_class]+=1;
   for (class_index=1;class_index<=class_num;class_index++)
     if (num_samples[class_index]<min_samples) min_samples=num_samples[class_index];

   min_dists=new double[count];
   min_dists_classes=new long[count];
   for (sig_index=0;sig_index<signature_count;sig_index++)
   {  int close_index,total_num_min_dist;
      for (dist_index=0;dist_index<min_samples;dist_index++)
        min_dists[dist_index]=INF;
      for (sample_index=0;sample_index<count;sample_index++)
      {
         dist=fabs(test_sample->data[sig_index].value-samples[sample_index]->data[sig_index].value);
         /* check if this dist should be in the close list */
         for (close_index=0;close_index<count;close_index++)
         if (dist<min_dists[close_index])
         {  memmove(&(min_dists[close_index+1]),&(min_dists[close_index]),sizeof(double)*(count-1-close_index));
            memmove(&(min_dists_classes[close_index+1]),&(min_dists_classes[close_index]),sizeof(long)*(count-1-close_index));
            min_dists[close_index]=dist;
            min_dists_classes[close_index]=samples[sample_index]->sample_class;
            break;
         }
      }

      /* find the actual range of the closest sample */
      sample_index=min_samples-1;
      dist=min_dists[sample_index];
      while (sample_index<count && min_dists[sample_index]==dist)
        sample_index++;
      size_of_class=sample_index;
      if (size_of_class>=count) continue; /* no point in continuing if they all equally close */
      /* find the number of samples with the same minimal value */
//      total_num_min_dist=0;
//      for (sample_index=0;sample_index<count;sample_index++)
//        if (fabs(test_sample->data[sig_index].value-samples[sample_index]->data[sig_index].value)<=min_dists[0])
//          total_num_min_dist++;
      /* if all other distances are in the same class then reduce total_num_min_dist */
//      if (total_num_min_dist>count/2) continue;

      /* find the number of times each class appears */
      for (class_index=1;class_index<=class_num;class_index++)
        close_samples[class_index]=0;
      for (close_index=0;close_index<size_of_class;close_index++)
        close_samples[min_dists_classes[close_index]]+=1;
      /* find the max class */
      max_class=0;
      for (class_index=1;class_index<=class_num;class_index++)
        if (close_samples[class_index]>max_class) max_class=close_samples[class_index];
      /* now find the probability of each class */
      if ((double)max_class/(double)min_samples>pow(1/(double)class_num,1.0/2.0))
      for (class_index=1;class_index<=class_num;class_index++)
      {  long double class_prob;
         class_prob=((double)size_of_class/(double)(num_samples[class_index]))*(double)(close_samples[class_index])/(double)size_of_class;
//if (class_prob<1.0/(double)class_num) class_prob=1.0/(double)class_num;
         probs[class_index]=probs[class_index]*class_prob;
      }

   }

   /* normalize the results and find the most probable class */
   if (probabilities)
   {  long double sum_dists=0.0;
      long double highest_prob=0.0;
      most_probable_class=0;
      for (class_index=1;class_index<=class_num;class_index++)
        if (probs[class_index]>highest_prob)
        {  highest_prob=probs[class_index];
           most_probable_class=class_index;
        }

      for (dist_index=1;dist_index<=class_num;dist_index++)
        if (probs[dist_index]!=0)
           sum_dists+=probs[dist_index];
      for (dist_index=1;dist_index<=class_num;dist_index++)
        if (sum_dists==0 || probs[dist_index]==0) probabilities[dist_index]=0;    /* protect from division by zero */
        else probabilities[dist_index]=(probs[dist_index])/sum_dists;
     if (normalization_factor) *normalization_factor=sum_dists;				
   }

   delete num_samples;
   delete min_dists;
   delete min_dists_classes;
   delete close_samples;
   return(most_probable_class);
}

/*  Pearson
    compute pearson correlation
	This function is used by wndchrm.cpp if all class labels are numerical.
	The class labels are used as the values of one variable, and the interpolated values are used as the other
*/
double TrainingSet::pearson()
{  double mean=0,stddev=0,mean_ground=0,stddev_ground=0,z_score_sum=0;
   int test_sample_index,class_index;
   /* check if the data can be interpolated (all class labels are numbers) */
   for (class_index=1;class_index<=class_num;class_index++)
     if (atof(class_labels[class_index])==0.0 && class_labels[class_index][0]!='0') return(0);
   /* compute the mean */
   for (test_sample_index=0;test_sample_index<count;test_sample_index++)
   {  mean+=samples[test_sample_index]->interpolated_value;
      mean_ground+=atof(class_labels[samples[test_sample_index]->sample_class]);
   }
   mean/=count;
   mean_ground/=count;
   /* compute the stddev */
   for (test_sample_index=0;test_sample_index<count;test_sample_index++)
   {  stddev+=pow(samples[test_sample_index]->interpolated_value-mean,2);
      stddev_ground+=pow(atof(class_labels[samples[test_sample_index]->sample_class])-mean_ground,2);
   }
   stddev=sqrt(stddev/(count-1));
   stddev_ground=sqrt(stddev_ground/(count-1));
   /* now compute the pearson correlation */
   for (test_sample_index=0;test_sample_index<count;test_sample_index++)
     z_score_sum+=((samples[test_sample_index]->interpolated_value-mean)/stddev)*((atof(class_labels[samples[test_sample_index]->sample_class])-mean_ground)/stddev_ground);
   return(z_score_sum/(count-1));
}

/*
PrintMatrix
print the confusion or similarity matrix
output_file -FILE *- the file to print into (can be stdout to print to screen)
confusion_matrix -unsigned short *- the confusion matrixvalues to print
                 NULL - don't print confusion matrix
similarity_matrix -double *- the similarity matrix values to print
                 NULL - don't print similarity matrix
dend_file -unsigned short- create a dendogram input file
method -unsigned short- the method of transforming the similarity values into a single distance (0 - min, 1 - average. 2 - top triangle, 3 - bottom triangle).

returned values -long- 1 if successful, 0 if failed
*/
long TrainingSet::PrintConfusion(FILE *output_file,unsigned short *confusion_matrix, double *similarity_matrix,unsigned short dend_file, unsigned short method)
{  int class_index1,class_index2;
   if (dend_file) fprintf(output_file,"%d\n",class_num);
   else
   {  fprintf(output_file,"          ");
      for (class_index1=1;class_index1<=class_num;class_index1++)
        fprintf(output_file,"%10s",class_labels[class_index1]);
      fprintf(output_file,"\n");
   }
   for (class_index1=1;class_index1<=class_num;class_index1++)
   {  if (dend_file)
      {   char label[128];
//          long sum_row=0;
//          for (class_index2=1;class_index2<=class_num;class_index2++) sum_row+=confusion_matrix[class_index1*class_num+class_index2];
//          sprintf(label,"%s",class_labels[class_index1],confusion_matrix[class_index1*class_num+class_index1],sum_row);
          strcpy(label,class_labels[class_index1]);
          if (strlen(label)>8) strcpy(label,&(label[strlen(label)-8]));  /* make sure the labels are shorter or equal to 8 characters in length */
          if (!isalnum(label[strlen(label)-1])) label[strlen(label)-1]='\0';
          fprintf(output_file,"%s                 ",label);
      }
      else fprintf(output_file,"%10s",class_labels[class_index1]);
      for (class_index2=1;class_index2<=class_num;class_index2++)
      {  if (confusion_matrix && !dend_file)
           fprintf(output_file,"%10d",confusion_matrix[class_index1*class_num+class_index2]);
         if (similarity_matrix)
         {  double dist=0;
            if (method==0) dist=max(1-similarity_matrix[class_index1*class_num+class_index2],1-similarity_matrix[class_index2*class_num+class_index1]);
            if (method==1) dist=((1-similarity_matrix[class_index1*class_num+class_index2])+(1-similarity_matrix[class_index2*class_num+class_index1]))/2;
            if (method==2) dist=(1-similarity_matrix[class_index1*class_num+class_index2])*(class_index2>=class_index1)+(1-similarity_matrix[class_index2*class_num+class_index1])*(class_index2<class_index1);  /* top triangle    */
            if (method==3) dist=(1-similarity_matrix[class_index1*class_num+class_index2])*(class_index2<=class_index1)+(1-similarity_matrix[class_index2*class_num+class_index1])*(class_index2>class_index1);  /* bottom triangle */
#ifndef WIN32
            if (dist==NAN) dist=0;
#endif
            if (dend_file) fprintf(output_file,"%1.4f       ",fabs(dist*(dist>=0)));
            else fprintf(output_file,"   %1.5f",similarity_matrix[class_index1*class_num+class_index2]);
         }
      }
      fprintf(output_file,"\n");
   }
   fprintf(output_file,"\n");
   return(1);
}


long TrainingSet::report(FILE *output_file, char *data_set_name, data_split *splits, unsigned short split_num, int tiles, int max_train_images, char *phylib_path, int phylip_algorithm, int export_tsv, char *path_to_test_set)
{  int class_index,class_index2,sample_index,split_index,a,test_set_size,train_set_size;
   int test_images[MAX_CLASS_NUM];
   double *avg_similarity_matrix;
   double splits_accuracy,splits_class_accuracy,avg_pearson=0;
   FILE *tsvfile;
   char tsv_filename[512];
   
   /* create a directory for the files */
#ifndef WIN32
   if (export_tsv) mkdir("tsv",0755);
#else
   if (export_tsv) mkdir("tsv");
#endif

   /* print the header */
   fprintf(output_file,"<HTML>\n<HEAD>\n<TITLE> %s </TITLE>\n </HEAD> \n <BODY> \n <br> <h1>%s</h1><br>\n ",data_set_name,data_set_name);
   if (path_to_test_set)  fprintf(output_file,"Testing with data file: %s<br>",path_to_test_set);
   fprintf(output_file,"<hr/><CENTER>\n");
   
   /* print the number of samples table */
   fprintf(output_file,"<table border=\"1\" cellspacing=\"0\" cellpadding=\"3\" align=\"center\">\" \n <caption>Number of Images from Training and Testing (tiles per image=%d)</caption> \n <tr>",tiles*tiles);
   for (class_index=0;class_index<=class_num;class_index++)
     fprintf(output_file,"<td>%s</td>\n",class_labels[class_index]);
   fprintf(output_file,"<td>total</td></tr>\n");
   test_set_size=0;
   fprintf(output_file,"<tr><td>Testing</td>\n");
   for (class_index=1;class_index<=class_num;class_index++)
   {  int inst_num=0;
      for (class_index2=1;class_index2<=class_num;class_index2++)
        inst_num+=(splits[0].confusion_matrix[class_index*class_num+class_index2]);
      fprintf(output_file,"<td>%d</td>\n",inst_num);
      test_images[class_index]=inst_num;
      test_set_size+=inst_num;
   }
   fprintf(output_file,"<td>%d</td></tr>\n",test_set_size); /* add the total number of test samples */
   train_set_size=0;
   fprintf(output_file,"<tr>\n<td>Training</td>\n");
   for (class_index=1;class_index<=class_num;class_index++)
   {  int inst_num=0;
      for (sample_index=0;sample_index<count;sample_index++)
        if (samples[sample_index]->sample_class==class_index) inst_num++;
      inst_num=(int)(inst_num/(tiles*tiles))-test_images[class_index]*(path_to_test_set==NULL);
      if (max_train_images>0 && inst_num>max_train_images) inst_num=max_train_images;
      fprintf(output_file,"<td>%d</td>\n",inst_num);
      train_set_size+=inst_num;
   }
   fprintf(output_file,"<td>%d</td>\n",train_set_size); /* add the total number of training samples */
   fprintf(output_file,"</tr> \n </table>\n");          /* close the number of samples table */

   /* print the splits */
   splits_accuracy=0.0;
   splits_class_accuracy=0.0;
   fprintf(output_file,"<h2>Results</h2> \n <table border=\"1\" align=\"center\"><caption></caption> \n");
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
      fprintf(output_file,"Accuracy: <b>%.2f of total</b><br> \n",splits[split_index].accuracy);	  
      fprintf(output_file,"<b>%.2f &plusmn; %.1f Avg per Class Correct of total</b><br> \n",avg_accuracy,plus_minus);
	  if (splits[split_index].pearson_coefficient!=0) 
	    fprintf(output_file,"Peasron correlation coefficient: %.2f<br>\n",splits[split_index].pearson_coefficient);
      avg_pearson+=splits[split_index].pearson_coefficient;
      if (splits[split_index].feature_weight_distance>=0)
	    fprintf(output_file,"Feature weight distance: %.2f<br>\n",splits[split_index].feature_weight_distance);	  	  
      fprintf(output_file,"<a href=\"#split%d\">Full details</a><br> \n",split_index);
//      fprintf(output_file,"<a href=\"#features%d\">Features used</a><br> </td> </tr> \n",split_index);
      splits_accuracy+=splits[split_index].accuracy;
	  splits_class_accuracy+=avg_accuracy;
   }
   /* average of all splits */
   fprintf(output_file,"<tr> <td>Total</td> \n <td align=\"center\" valign=\"top\"> \n");
   fprintf(output_file,"<b>%.2f Avg per Class Correct of total</b><br> \n",splits_class_accuracy/split_num);
   fprintf(output_file,"Accuracy: <b>%.2f of total</b><br> \n",splits_accuracy/split_num);
   if (avg_pearson!=0) 
     fprintf(output_file,"Peasron correlation coefficient: %.2f<br>\n",avg_pearson/split_num);
   
   fprintf(output_file,"</table>\n");   /* close the splits table */
   fprintf(output_file,"<br><br><br><br><br><br> \n\n\n\n\n\n\n\n");

   /* average (sum) confusion matrix */
   sprintf(tsv_filename,"tsv/avg_confusion.tsv");                /* determine the tsv file name           */
   tsvfile=NULL;                                                 /* keep it null if the file doesn't open */
   if (export_tsv) tsvfile=fopen(tsv_filename,"w");              /* open the file for tsv                 */
   fprintf(output_file,"<table border=\"1\" align=\"center\"><caption>Confusion Matrix (sum of all splits)</caption> \n");
   fprintf(output_file,"<tr><td></td> ");      /* space */
   if (tsvfile) fprintf(tsvfile,"\t");         /* space (in the tsv file) */
   for (class_index=1;class_index<=class_num;class_index++)
   {  fprintf(output_file,"<td><b>%s</b></td> ",class_labels[class_index]);   /* print to the html file  */
      if (tsvfile) fprintf(tsvfile,"%s\t",class_labels[class_index]);         /* print into the tsv file */
   }
   fprintf(output_file,"</tr>\n");         /* end of the classes names */
   if (tsvfile) fprintf(tsvfile,"\n");     /* end of the classes names in the tsv file */
   for (class_index=1;class_index<=class_num;class_index++)
   {  fprintf(output_file,"<tr><td><b>%s</b></td> ",class_labels[class_index]);  /* print the class name                   */
      if (tsvfile) fprintf(tsvfile,"%s\t",class_labels[class_index]);            /* print the class name into the tsv file */   
      for (class_index2=1;class_index2<=class_num;class_index2++)
      {  double sum=0.0;
	     char bgcolor[64];
         for (split_index=0;split_index<split_num;split_index++)
           sum+=splits[split_index].confusion_matrix[class_index*class_num+class_index2];
		 if (class_index==class_index2) strcpy(bgcolor," bgcolor=#D5D5D5");
		 else strcpy(bgcolor,"");  
         if ((double)((long)(sum/split_num))==sum/split_num) fprintf(output_file,"<td%s>%d</td>\n",bgcolor,(long)(sum/*/split_num*/));
         else fprintf(output_file,"<td%s>%.0f</td> ",bgcolor,sum/*/split_num*/);
         if (tsvfile) fprintf(tsvfile,"%.0f\t",sum/*/split_num*/);     /* print the values to the tsv file (for the tsv machine readable file a %.2f for all values should be ok) */		 
      }
      fprintf(output_file,"</tr>\n");         /* end of the line in the html report */
      if (tsvfile) fprintf(tsvfile,"\n");     /* end of the line in the tsv file    */	  
   }
   fprintf(output_file,"</table> \n <br><br><br><br> \n");  /* end of average confusion matrix */
   if (tsvfile) fclose(tsvfile);

   /* average similarity matrix */
   sprintf(tsv_filename,"tsv/avg_similarity.tsv");                 /* determine the tsv file name               */
   tsvfile=NULL;                                                   /* keep it null if the file doesn't open     */
   if (export_tsv) tsvfile=fopen(tsv_filename,"w");                /* open the file for tsv                     */   
   avg_similarity_matrix=new double[(class_num+1)*(class_num+1)];  /* this is used for creating the dendrograms */
   fprintf(output_file,"<table border=\"1\" align=\"center\"><caption>Average Similarity Matrix</caption> \n");
   fprintf(output_file,"<tr><td></td> ");      /* space */
   if (tsvfile) fprintf(tsvfile,"\t");         /* space */   
   for (class_index=1;class_index<=class_num;class_index++)
   {  fprintf(output_file,"<td><b>%s</b></td> ",class_labels[class_index]);   /* print to the html file  */
      if (tsvfile) fprintf(tsvfile,"%s\t",class_labels[class_index]);         /* print into the tsv file */
   }
   fprintf(output_file,"</tr>\n");         /* end of the classes names */
   if (tsvfile) fprintf(tsvfile,"\n");     /* end of the classes names in the tsv file */
   for (class_index=1;class_index<=class_num;class_index++)
   {  fprintf(output_file,"<tr><td><b>%s</b></td> ",class_labels[class_index]);
      if (tsvfile) fprintf(tsvfile,"%s\t",class_labels[class_index]);         /* print the class name into the tsv file */
      for (class_index2=1;class_index2<=class_num;class_index2++)
      {  double sum=0.0;
         for (split_index=0;split_index<split_num;split_index++)
           sum+=splits[split_index].similarity_matrix[class_index*class_num+class_index2];
         avg_similarity_matrix[class_index*class_num+class_index2]=sum/split_num;    /* remember this value for the dendrogram file */
         fprintf(output_file,"<td>%.2f</td> ",sum/split_num);
         if (tsvfile) fprintf(tsvfile,"%.2f\t");             /* print the values to the tsv file (for the tsv machine readable file a %.2f for all values should be ok) */		 		 
      }
      fprintf(output_file,"</tr>\n");                        /* end of the line in the html report */
      if (tsvfile) fprintf(tsvfile,"\n");                    /* end of the line in the tsv file    */	  
   }
   fprintf(output_file,"</table> \n <br><br><br><br> \n");   /* end of average similarity matrix */
   if (tsvfile) fclose(tsvfile);

   /* *** generate a dendrogram *** */
   if (phylib_path)  /* generate a dendrogram only if phlyb path was specified */
   {  FILE *dend_file;
      char file_path[256],alg[16];
	  int algorithm_index;	  
      /* write "dend_file.txt" */
      sprintf(file_path,"%s/dend_file.txt",phylib_path);
      dend_file=fopen(file_path,"w");
      if (dend_file)
	  {  PrintConfusion(dend_file, splits[0].confusion_matrix,avg_similarity_matrix,1,1);  /* print the dendrogram to a the "dend_file.txt" file */
         fclose(dend_file);
		 if (export_tsv)   /* write the phylip file to the tsv directory */
		 {  sprintf(file_path,"tsv/dend_file.txt");
		    dend_file=fopen(file_path,"w");
			PrintConfusion(dend_file, splits[0].confusion_matrix,avg_similarity_matrix,1,1);  /* print the dendrogram to a "dend_file.txt" file */
			fclose(dend_file);
		 }
         sprintf(file_path,"%s/fitch.infile",phylib_path);
         dend_file=fopen(file_path,"w");
         if (dend_file)
         {  /* create fith.infile */
            fprintf(dend_file,"%s/dend_file.txt\nJ\n97\n10\nY\n",phylib_path);
            fclose(dend_file);
            /* create drawtree.infile */			
            sprintf(file_path,"%s/drawtree.infile",phylib_path);
            dend_file=fopen(file_path,"w");
			alg[0]='\0';
			for (algorithm_index=0;algorithm_index<phylip_algorithm;algorithm_index++)
			  strcat(alg,"I\n");
            fprintf(dend_file,"outtree\n%s/src/font1\n%sV\nN\nY\n",phylib_path,alg);     //D\n
            fclose(dend_file);
			/* create the dendrogram */
			system("rm plotfile");
            sprintf(file_path,"%s/src/fitch < %s/fitch.infile",phylib_path,phylib_path);
            system(file_path);
            sprintf(file_path,"%s/src/drawtree < %s/drawtree.infile",phylib_path,phylib_path);
            system(file_path);
            sprintf(file_path,"mv plotfile ./%s.ps",data_set_name);
            system(file_path);			
//            system("mv plotfile plotfile.ps");		
            sprintf(file_path,"convert ./%s.ps ./%s.jpg",data_set_name,data_set_name);
            system(file_path);
            system("rm outfile outtree");  /* delete files from last run */			
            fprintf(output_file,"<A HREF=\"%s.ps\"><IMG SRC=\"%s.jpg\"></A><br>",data_set_name,data_set_name);
            fprintf(output_file,"<A HREF=\"%s.ps\">%s.ps</A><br>",data_set_name,data_set_name);			
         }
	}		   
   }
   delete avg_similarity_matrix;  /* free the memory allocated for the dendrogram similarity matrix */

   /* *** print the confusion/similarity matrices, feature names and individual images for the splits *** */
   for (split_index=0;split_index<split_num;split_index++)
   {  unsigned short *confusion_matrix;
      double *similarity_matrix;
      char feature_names[60000],*p_feature_names;
      unsigned short features_num=0,class_index;

      confusion_matrix=splits[split_index].confusion_matrix;
      similarity_matrix=splits[split_index].similarity_matrix;

      fprintf(output_file,"<HR><BR><A NAME=\"split%d\">\n",split_index);   /* for the link to the split */
      fprintf(output_file,"<B>Split %d</B><br><br>\n",split_index+1);

	  /* print the confusion matrix */
      fprintf(output_file,"<table border=\"1\" align=\"center\"><caption>Confusion Matrix</caption> \n");
      fprintf(output_file,"<tr><td></td>\n");
      for (class_index=1;class_index<=class_num;class_index++)
        fprintf(output_file,"<td><b>%s</b></td>\n",class_labels[class_index]);
      fprintf(output_file,"</tr>\n");
      for (class_index=1;class_index<=class_num;class_index++)
      {  fprintf(output_file,"<tr><td><b>%s</b></td>\n",class_labels[class_index]);
         for (class_index2=1;class_index2<=class_num;class_index2++)
           fprintf(output_file,"<td>%d</td>\n",confusion_matrix[class_index*class_num+class_index2]);
         fprintf(output_file,"</tr>\n");
      }
      fprintf(output_file,"</table> \n <br><br> \n");
      
	  /* print the similarity matrix */
      fprintf(output_file,"<table border=\"1\" align=\"center\"><caption>Similarity Matrix</caption> \n");   
      fprintf(output_file,"<tr><td></td>\n");
      for (class_index=1;class_index<=class_num;class_index++)
        fprintf(output_file,"<td><b>%s</b></td>\n",class_labels[class_index]);   
      fprintf(output_file,"</tr>\n");
      for (class_index=1;class_index<=class_num;class_index++)
      {  fprintf(output_file,"<tr><td><b>%s</b></td>\n",class_labels[class_index]);
         for (class_index2=1;class_index2<=class_num;class_index2++)
           fprintf(output_file,"<td>%.2f</td>\n",similarity_matrix[class_index*class_num+class_index2]);
         fprintf(output_file,"</tr>\n");
      }
      fprintf(output_file,"</table> \n <br><br> \n");

      /* count the number of features */
      strncpy(feature_names,splits[split_index].feature_names,sizeof(feature_names));
      feature_names[sizeof(feature_names)-1]='\0';  /* make sure the string is null-terminated */
      a=0;
      while (feature_names[a]!='\0')
        features_num+=(feature_names[a++]=='\n');
//      fprintf(output_file,"<A NAME=\"features%d\"> \n",split_index);
      fprintf(output_file,"%d features selected (out of %d features computed).<br>  <a href=\"#\" onClick=\"sigs_used=document.getElementById('FeaturesUsed_split%d'); if (sigs_used.style.display=='none'){ sigs_used.style.display='inline'; } else { sigs_used.style.display='none'; }\">Toggle feature names</a><br><br>\n",features_num,signature_count,split_index);
      fprintf(output_file,"<TABLE ID=\"FeaturesUsed_split%d\" border=\"1\" style=\"display: none;\">\n",split_index);
      p_feature_names=strtok(feature_names,"\n");
      a=1;
      while (p_feature_names)
      {  fprintf(output_file,"<tr><td>%s</td></tr>\n",p_feature_names);
         p_feature_names=strtok(NULL,"\n");
      }
      fprintf(output_file,"</table><br>\n");

      /* individual image predictions */
      if (splits[split_index].individual_images)
      {  char closest_image[256],interpolated_value[256];
	     int interpolate=1;
         
         /* add the most similar image if WNN and no tiling */
         if (splits[split_index].method==WNN && tiles==1) strcpy(closest_image,"<td><b>Most similar image</b></td>");
         else strcpy(closest_image,"");
		 
         fprintf(output_file,"<a href=\"#\" onClick=\"sigs_used=document.getElementById('IndividualImages_split%d'); if (sigs_used.style.display=='none'){ sigs_used.style.display='inline'; } else { sigs_used.style.display='none'; }\">Individual image predictions</a><br>\n",split_index);
         fprintf(output_file,"<TABLE ID=\"IndividualImages_split%d\" border=\"1\" style=\"display: none;\">\n       <tr><td><b>Image No.</b></td><td><b>Normalization<br>Factor</b></td>",split_index);
         for (class_index=1;class_index<=class_num;class_index++)
         {  fprintf(output_file,"<td><b>%s</b></td>",class_labels[class_index]);
            interpolate*=(atof(class_labels[class_index])!=0.0 || class_labels[class_index][0]=='0');		 /* interpolate only if all class labels are values */ 
		 }
   	     if (interpolate) strcpy(interpolated_value,"<td><b>Interpolated<br>Value</b></td>");
         else strcpy(interpolated_value,"");		 
         fprintf(output_file,"<td>&nbsp</td><td><b>Actual<br>Class</b></td><td><b>Predicted<br>Class</b></td><td><b>Classification<br>Correctness</b></td>%s<td><b>Image</b></td>%s</tr>\n",interpolated_value,closest_image);		 
         fprintf(output_file,splits[split_index].individual_images);
         fprintf(output_file,"</table><br><br>\n");
      }
   }

   fprintf(output_file,"<br><br><br><br><br><br> \n\n\n\n\n\n\n\n");

   fprintf(output_file,"</CENTER> \n </BODY> \n </HTML>\n");
}

#pragma package(smart_init)

