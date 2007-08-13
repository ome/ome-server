/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                                                                               */
/*    Copyright (C) 2007 Open Microscopy Environment                             */
/*         Massachusetts Institue of Technology,                                 */
/*         National Institutes of Health,                                        */
/*         University of Dundee                                                  */
/*                                                                               */
/*                                                                               */
/*                                                                               */
/*    This library is free software; you can redistribusplit_numte it and/or     */
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


#include "TrainingSet.h"

#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>

#define MAX_SPLITS 100

void randomize() 
{ 
time_t t; 
srand((unsigned) time(&t)); 
} 

/* classify one image
   filenam e -char *- the full path to the image file name
*/
int classify_image(char *filename,char *image_filename, double max_features, int output_to_screen, int tiles, int method, int large_set, int compute_colors, int downsample)
{ TrainingSet *ts;
  ImageMatrix *matrix;
  signatures *image_signatures;
  double probabilities[MAX_CLASS_NUM],probabilities_sum[MAX_CLASS_NUM],max_probability=0.0;
  int res,class_index,tile_index=1,tile_index_y,tile_index_x;
  
  /* open the image file */
  if (output_to_screen) printf("opening image file '%s' \n",image_filename);  
  matrix=new ImageMatrix;
  if (strstr(image_filename,".tif") || strstr(image_filename,".TIF"))
    res=matrix->LoadTIFF(image_filename);
  else	
  if (strstr(image_filename,".ppm") || strstr(image_filename,".PPM"))
    res=matrix->LoadPPM(image_filename,cmHSV);
#ifdef WIN32
  else	
  if (strstr(image_filename,".bmp") || strstr(image_filename,".BMP"))
    res=matrix->LoadBMP(image_filename);
#endif	
  else
  {  printf("Unsupported file format \n");
     delete matrix;
     return(0);
  }
  if (res==0)   /* failed to open the image */
  {  printf("Cannot open file '%s' \n",image_filename);
     delete matrix;
     return(0);
  }
  if (downsample>0 && downsample<100)
    matrix->Downsample(((double)downsample)/100.0,((double)downsample)/100.0);
  	
  /* open the training set */
  if (output_to_screen) printf("opening training set file '%s' \n",filename);  
  ts=new TrainingSet(20000,MAX_CLASS_NUM);
  ts->ReadFromFile(filename);
  ts->normalize();
  ts->SetFisherScores(max_features,NULL);
  
  /* initialize the probabilities sum */
  for (class_index=0;class_index<ts->class_num;class_index++)
    probabilities_sum[class_index]=0.0;

  for (tile_index_y=0;tile_index_y<tiles;tile_index_y++)
	for (tile_index_x=0;tile_index_x<tiles;tile_index_x++)
	{  ImageMatrix *tile_matrix;	
       long tile_x_size=(long)(matrix->width/tiles);
  	   long tile_y_size=(long)(matrix->height/tiles);
       if (tiles>1) tile_matrix=new ImageMatrix(matrix,tile_index_x*tile_x_size,tile_index_y*tile_y_size,(tile_index_x+1)*tile_x_size,(tile_index_y+1)*tile_y_size);
   	   else tile_matrix=matrix;
	   
       /* compute the signatures */
       if (output_to_screen) printf("computing signatures tile %d of %d... \n",tile_index++,tiles*tiles);
       image_signatures=new signatures;
	   image_signatures->ScoresTrainingSet=ts;    /* so that only the needed signatures will be computed */
	   if (large_set) image_signatures->ComputeGroups(tile_matrix,compute_colors);
       else image_signatures->compute(matrix,compute_colors);
       delete tile_matrix;
	   
       /* classify */
       if (output_to_screen) printf("classifying\n");  
       if (method==1) ts->classify2(image_signatures,probabilities);
	   else ts->WNNclassify(image_signatures,probabilities);
	   
       for (class_index=0;class_index<ts->class_num;class_index++)
         probabilities_sum[class_index]+=probabilities[class_index];
	   
	}
  
  /* print results */
  for (class_index=1;class_index<ts->class_num;class_index++)
  {  
     printf("%s: %f \n",ts->class_labels[class_index],probabilities_sum[class_index]);
     if (probabilities_sum[class_index]>max_probability) 
     {  max_probability=probabilities_sum[class_index];
	    res=class_index;
	 }
  }
  printf("The resulting class is: %s (%f)\n",ts->class_labels[res],probabilities_sum[res]);
  
  if (tiles>1) delete matrix;
  delete image_signatures;
  delete ts;
  return(1);
}

int compute_features(char *root_dir, char *output_file,int class_num, int output_to_screen, int tiles,  int multi_process, int large_set, int colors, int downsample)
{    TrainingSet *ts;
     double res,per;
     ts=new TrainingSet(20000,class_num);
     ts->LoadFromDir(root_dir,0,output_to_screen,tiles,multi_process,large_set,colors,downsample);
     ts->SaveToFile(output_file);
     return(1);
}     

int split_and_test(char *filename, int class_num, int method, int tiles, double split_ratio, double max_features, long split_num, int report)
{    TrainingSet *ts,*train,*test;
     data_split splits[MAX_SPLITS];
     int split_index;
	 double res=0;
	 
     ts=new TrainingSet(20000,class_num);
     ts->ReadFromFile(filename);
	 
	 randomize();
     for (split_index=0;split_index<split_num;split_index++)
     {  unsigned short *confusion_matrix;
        double *similarity_matrix;
        char *sig_names;	 
//     unsigned short confusion_matrix[(class_num+1)*(class_num+1)];
//     double similarity_matrix[(class_num+1)*(class_num+1)];
       double accuracy;

	   confusion_matrix=new unsigned short[(class_num+1)*(class_num+1)];
       similarity_matrix=new double[(class_num+1)*(class_num+1)]; 
       sig_names=new char[64000];
       train=new TrainingSet(ts->count,class_num);
       test=new TrainingSet(ts->count,class_num);
		   
       ts->split(split_ratio,train,test,tiles*tiles);     
       train->normalize();
       train->SetFisherScores(max_features,sig_names);
       accuracy=train->Test(test,method,confusion_matrix,similarity_matrix,tiles*tiles);
	   res+=accuracy;
	   if (!report)
       {  ts->PrintConfusion(confusion_matrix,NULL,0,0);
          ts->PrintConfusion(NULL,similarity_matrix,0,0);  
//          ts->PrintConfusion(NULL,similarity_matrix,1,1);		      
       }    
       printf("\nAccuracy: %f \n",accuracy);
	   
	   splits[split_index].confusion_matrix=confusion_matrix;
	   splits[split_index].similarity_matrix=similarity_matrix;
	   splits[split_index].feature_names=sig_names;
	   splits[split_index].accuracy=accuracy;
	   
	   delete train;
	   delete test;
	 } 
	 printf("\n\n");
	 if (report)
	   ts->report(filename,splits,split_num,tiles);
	 delete ts;	 
	 for (split_index=0;split_index<split_num;split_index++)
	 {  delete splits[split_index].confusion_matrix;
        delete splits[split_index].similarity_matrix;
        delete splits[split_index].feature_names;
     }
     return(1);
}


void ShowHelp()
{
   printf("\nLaboratory of Genetics/NIA/NIH \n");
   printf("usage: wndchrm [ train [-mtslcdh] <root directory> <feature_file> ] | [ test [-trwpnfh] <feature_file>] | [ classify [-tswflcdh] <feature_file> <image_filename> ] \n");
   printf("<root directory> is a directory that has the directories of the class images as subdirectories. Images should be stored in a directory structure such that each subdirectory contains the images of one class\n");
   printf("<feature_file> is the file generated by the train command. \n");       
   printf("<image_filename> is the full path to the classified image. \n");          
   printf("m - allow running multiple instances of this program (to be used on multiple-processor machines).\n");
   printf("tN - split the image into NxN tiles. The default is 1.\n");
   printf("l - Use a large image feature set.\n");       
   printf("c - Compute color features.\n");             
   printf("dN - Downsample the images (N percents, where N is 0 to 100)\n");                
   printf("s - silent mode.\n");   
   printf("w - Classify with wnd instead of wnn. \n");
   printf("rN - the split ratio of the dataset to training/test subsets (0,1). The default is 0.25. \n");                  
   printf("fN - maximum number of features out of the dataset (0,1) . The default is 0.15. \n");   
   printf("nN - Number of repeated random splits. The default is 1.\n");               
   printf("p - Output a full report in HTML format.\n");
   printf("h - show this note.\n\n");
   printf("examples: \n \t train: \n \t wndchrm train /path/to/dataset dataset.fit \n \t test: \n \t wndchrm test -f0.1 dataset.fit \n \n");
   printf("If you have more questions about this software, please email me (lior shamir) at <shamirl [at] mail [dot] nih [dot] gov> \n\n");
   return;
}


int main(int argc, char *argv[])
{   char *root_dir, *filename, *image_filename;
    int multi_processor=0;
    int arg_index=1;
    int tiles=1;
    int output_to_screen=1;
    int method=0;
    int report=0;
	int splits_num=1;
	int large_set=0;
	int colors=0;
	int downsample=100;
    double split_ratio=0.25;
    double max_features=0.15;
    int train=0;
    int test=0;
	int classify=0;
    /* read parameters */
    if (argc<2)
    {  ShowHelp();
       return(1);
    }

    if (strcmp(argv[arg_index],"train")==0) train=1;
    if (strcmp(argv[arg_index],"test")==0) test=1;
    if (strcmp(argv[arg_index],"classify")==0) classify=1;	
    if (!train && !test && !classify)
    {  ShowHelp();
       return(1);
    }
    arg_index++;
	  
    while (argv[arg_index][0]=='-')  
    {   if (strchr(argv[arg_index],'m')) multi_processor=1;
        if (strchr(argv[arg_index],'t')) tiles=atoi(&(strchr(argv[arg_index],'t')[1]));
        if (strchr(argv[arg_index],'n')) splits_num=atoi(&(strchr(argv[arg_index],'n')[1]));		
        if (strchr(argv[arg_index],'s')) output_to_screen=0;
        if (strchr(argv[arg_index],'l')) large_set=1;
        if (strchr(argv[arg_index],'c')) colors=1;        
        if (strchr(argv[arg_index],'d')) downsample=atoi(&(strchr(argv[arg_index],'d')[1]));				
        if (strchr(argv[arg_index],'r')) split_ratio=atof(&(strchr(argv[arg_index],'r')[1]));                               
        if (strchr(argv[arg_index],'f')) max_features=atof(&(strchr(argv[arg_index],'f')[1]));                               
        if (strchr(argv[arg_index],'w')) method=1;
        if (strchr(argv[arg_index],'p')) report=1;        
        if (strchr(argv[arg_index],'h'))                                
        {  ShowHelp();
            return(1);
        }         
        arg_index++;
     } 
     if (arg_index<argc) 
     { if (train) 
       {  root_dir=argv[arg_index++];
           filename=argv[arg_index];
           compute_features(root_dir, filename,MAX_CLASS_NUM, output_to_screen, tiles, multi_processor,large_set,colors,downsample);
       }
       if (test)
       {   filename=argv[arg_index];
           split_and_test(filename, MAX_CLASS_NUM, method, tiles, split_ratio, max_features,splits_num,report);       
       }
	   if (classify)
	   {  filename=argv[arg_index++];
	      image_filename=argv[arg_index];
          classify_image(filename,image_filename, max_features, output_to_screen, tiles, method, large_set, colors, downsample);
	   }
   }  

   return(1);
}
