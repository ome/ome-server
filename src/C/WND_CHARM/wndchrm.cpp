/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                                                                               */
/*    Copyright (C) 2007 Open Microscopy Environment                             */
/*         Massachusetts Institue of Technology,                                 */
/*         National Institutes of Health,                                        */
/*         University of Dundee                                                  */
/*                                                                               */
/*                                                                               */
/*                                                                               */
/*    This library is free software; you can redistribusplit_numte it and/or              */
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

int compute_features(char *root_dir, char *output_file,int class_num, int output_to_screen, int tiles,  int multi_process, int large_set)
{   TrainingSet *ts;
     double res,per;
     ts=new TrainingSet(20000,class_num);
     ts->LoadFromDir(root_dir,0,output_to_screen,tiles,multi_process,large_set);
     ts->SaveToFile(output_file);
     return(1);
}     

int split_and_test(char *filename, int class_num, int method, int tiles, double split_ratio, double max_features, long split_num)
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
       sig_names=new char[50000];
       train=new TrainingSet(ts->count,class_num);
       test=new TrainingSet(ts->count,class_num);
		   
       ts->split(split_ratio,train,test,tiles*tiles);     
       train->normalize();
       train->SetFisherScores(max_features,sig_names);
       accuracy=train->Test(test,method,confusion_matrix,similarity_matrix,tiles*tiles);
	   res+=accuracy;
     ts->PrintConfusion(confusion_matrix,NULL,0,0);
     ts->PrintConfusion(NULL,similarity_matrix,0,0);     
       printf("\nAccuracy: %f \n",accuracy);
	   
	   splits[split_index].confusion_matrix=confusion_matrix;
	   splits[split_index].similarity_matrix=similarity_matrix;
	   splits[split_index].feature_names=sig_names;
	   
	   delete train;
	   delete test;
	 } 
	 printf("\n\n");
	 ts->report(filename,splits,split_num);	 
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
   printf("usage: wndchrm [ train [-mtsh] <root directory> <output_file> ] | [ test [-trwnfh] <input_file>] \n");
   printf("<root directory> is a directory that has the directories of the class images as subdirectories. Images should be stored in a directory structure such that each subdirectory contains the images of one class\n");
   printf("<input_file> is the file generated by the train command. \n");       
   printf("m - allow running multiple instances of this program (to be used on multiple-processor machines).\n");
   printf("tN - split the image into NxN tiles. The default is 1.\n");
   printf("w - use wnd-charm instead of wnn. \n");
   printf("s - silent mode.\n");   
   printf("rN - the split ratio of the dataset to training/test subsets (0,1). The default is 0.25. \n");                  
   printf("fN - maximum number of features out of the dataset (0,1) . The default is 0.15. \n");   
   printf("nN - Number of repeated random splits. The default is 1.\n");               
   printf("l - Use a large image feature set.\n");                  
   printf("h - show this note.\n\n");
   printf("examples: \n \t train: \n \t wndchrm train /path/to/dataset dataset.fit \n \t test: \n \t wndchrm test -f0.1 dataset.fit \n \n");
   printf("If you have more questions, please email me (lior shamir) at <shamirl [at] mail [dot] nih [dot] gov> \n\n");
   return;
}


int main(int argc, char *argv[])
{   char *root_dir, *filename;
    int multi_processor=0;
    int arg_index=1;
    int tiles=1;
    int output_to_screen=1;
    int method=0;
	int splits_num=1;
	int large_set=0;
    double split_ratio=0.25;
    double max_features=0.15;
    int train=0;
    int test=0;
    /* read parameters */
    if (argc<2)
    {  ShowHelp();
       return(1);
    }

    if (strcmp(argv[arg_index],"train")==0) train=1;
    if (strcmp(argv[arg_index],"test")==0) test=1;
    if (train==0 && test==0)
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
        if (strchr(argv[arg_index],'r')) split_ratio=atof(&(strchr(argv[arg_index],'r')[1]));                               
        if (strchr(argv[arg_index],'f')) max_features=atof(&(strchr(argv[arg_index],'f')[1]));                               
        if (strchr(argv[arg_index],'w')) method=1;
        if (strchr(argv[arg_index],'h'))                                
        {  ShowHelp();
            return(1);
        }         
        arg_index++;
     } 
     if (arg_index<argc) 
     {  if (train) 
        {  root_dir=argv[arg_index++];
            filename=argv[arg_index];
            compute_features(root_dir, filename,100, output_to_screen, tiles, multi_processor,large_set);
        }
        if (test)
       {   filename=argv[arg_index];
           split_and_test(filename, 100, method, tiles, split_ratio, max_features,splits_num);       
       }
   }  

   return(1);
}
