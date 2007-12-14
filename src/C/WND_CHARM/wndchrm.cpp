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
#define MAX_SAMPLES 190000

extern int print_to_screen;

int isdigit(char c)
{  return(c>='0' && c<='9');
}

void randomize() 
{ 
  time_t t; 
  srand((unsigned) time(&t)); 
} 

/* displays an error message and stops the program */
int show_error(char *error_message, int stop)
{  printf("Oy Vey: %s!\n",error_message);
   if (stop) exit(0);
   return(0);
}

/* classify one image
   filenam e -char *- the full path to the image file name
*/
int classify_image(char *filename,char *image_filename, double max_features, int tiles, int method, int large_set, int compute_colors, int downsample)
{ TrainingSet *ts;
  ImageMatrix *matrix;
  signatures *image_signatures;
  double probabilities[MAX_CLASS_NUM],probabilities_sum[MAX_CLASS_NUM],max_probability=0.0;
  int res,class_index,tile_index=1,tile_index_y,tile_index_x;
  
  /* open the image file */
  if (print_to_screen) printf("opening image file '%s' \n",image_filename);  
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
  else show_error("Unsupported file format \n",1);
  if (res==0)   /* failed to open the image */
  {  char error_message[256];
     delete matrix;
     sprintf(error_message,"Cannot open file '%s' \n",image_filename);
	 show_error(error_message,0);
     return(0);
  }
  if (downsample>0 && downsample<100)
    matrix->Downsample(((double)downsample)/100.0,((double)downsample)/100.0);
  	
  /* open the training set */
  if (print_to_screen) printf("opening training set file '%s' \n",filename);  
  ts=new TrainingSet(MAX_SAMPLES,MAX_CLASS_NUM);
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
       if (print_to_screen) printf("computing signatures tile %d of %d... \n",tile_index++,tiles*tiles);
       image_signatures=new signatures;
       image_signatures->ScoresTrainingSet=ts;    /* so that only the needed signatures will be computed */
       if (large_set) image_signatures->ComputeGroups(tile_matrix,compute_colors);
       else image_signatures->compute(matrix,compute_colors);
       delete tile_matrix;
	   
       /* classify */
       if (print_to_screen) printf("classifying\n");  
       if (method==WND) ts->classify2(image_signatures,probabilities,NULL);
       else ts->WNNclassify(image_signatures,probabilities,NULL,NULL);
	   
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

int compute_features(char *root_dir, char *output_file,int class_num, int tiles,  int multi_process, int large_set, int colors, int downsample)
{  TrainingSet *ts;
   double res,per;
   ts=new TrainingSet(MAX_SAMPLES,class_num);
   ts->LoadFromDir(root_dir,tiles,multi_process,large_set,colors,downsample);
   ts->SaveToFile(output_file);
   return(1);
}     

int split_and_test(char *filename, char *report_file_name, int class_num, int method, int tiles, double split_ratio, double max_features, long split_num, 
				int report,int max_training_images, int exact_training_images, int max_test_images, char *phylib_path,int phylip_algorithm,int export_tsv, 
				long first_n, char *weight_file_buffer, char weight_vector_action, int N, char *test_set_path)
{    TrainingSet *ts,*train,*test;
     data_split splits[MAX_SPLITS];
     char dataset_name[128];
	 FILE *output_file;
     int split_index;
     double res=0;
     char error_message[256];
	 
     ts=new TrainingSet(MAX_SAMPLES,class_num);
     if (!ts->ReadFromFile(filename))
     {  sprintf(error_message,"Cannot open file '%s'\n",filename);
		return(show_error(error_message,0));
     }
     if (ts->count<=0) 
	   return(show_error("File does not contain samples\n",0));
	    
	 if (N>0)
	   while (ts->class_num>N)
	     ts->RemoveClass(ts->class_num);
	 
     randomize();
     for (split_index=0;split_index<split_num;split_index++)
     { unsigned short *confusion_matrix;
       double *similarity_matrix;
       char *sig_names,*individual_images;
//     unsigned short confusion_matrix[(class_num+1)*(class_num+1)];
//     double similarity_matrix[(class_num+1)*(class_num+1)];
       double accuracy;

       train=new TrainingSet(ts->count,class_num);
       test=new TrainingSet(ts->count,class_num);
       confusion_matrix=new unsigned short[(class_num+1)*(class_num+1)];
       similarity_matrix=new double[(class_num+1)*(class_num+1)];	   
       sig_names=new char[ts->signature_count*80];	   
       
	   ts->split(split_ratio*(test_set_path==NULL),train,test,tiles*tiles,max_training_images,max_test_images,exact_training_images);
	   if (test_set_path) 
	     if (!test->ReadFromFile(test_set_path)) 
	        return(show_error("Cannot open test set file",0));
       train->normalize();
       train->SetFisherScores(max_features,sig_names);
	   if (weight_vector_action=='w') 
	     if(!train->SaveWeightVector(weight_file_buffer))
		   show_error("Could not write weight vector",1);
	   if (weight_vector_action=='r' || weight_vector_action=='+' || weight_vector_action=='-') 
	     if(train->LoadWeightVector(weight_file_buffer,(weight_vector_action=='+')-(weight_vector_action=='-'))<1)
		   show_error("Could not load weight vector",1);	   
	   if (report) individual_images=new char[(int)((test->count/(tiles*tiles))*(class_num*15))];
	   else individual_images=NULL;
       accuracy=train->Test(test,method,confusion_matrix,similarity_matrix,tiles*tiles,first_n,individual_images);
       res+=accuracy;
       if (!report)
       {  ts->PrintConfusion(stdout,confusion_matrix,NULL,0,0);
          ts->PrintConfusion(stdout,NULL,similarity_matrix,0,0);
          ts->PrintConfusion(stdout,confusion_matrix,similarity_matrix,1,1);
          printf("\nAccuracy: %f \n",accuracy);
       }

       splits[split_index].confusion_matrix=confusion_matrix;
       splits[split_index].similarity_matrix=similarity_matrix;
       splits[split_index].feature_names=sig_names;
       splits[split_index].accuracy=accuracy;
       splits[split_index].individual_images=individual_images;
       splits[split_index].method=method;
	   splits[split_index].pearson_coefficient=test->pearson();

	 delete train;
	 delete test;
    } 
    printf("\n\n");
    strcpy(dataset_name,filename);
    if (strrchr(dataset_name,'.')) *strrchr(dataset_name,'.')='\0';
    if (strrchr(dataset_name,'/'))   /* extract the file name */
	{  char buffer[128];
	   strcpy(buffer,&(strrchr(dataset_name,'/')[1]));
	   strcpy(dataset_name,buffer);
	}
    if (report)
    {  if (report_file_name)
	   {  if (!strchr(report_file_name,'.')) strcat(report_file_name,".html");
	      output_file=fopen(report_file_name,"w");
	      if (!output_file) 
		  {  char error_message[256];
		     sprintf(error_message,"Could not open file for writing '%s'\n",report_file_name);
			 show_error(error_message,0);
		     exit(0);
		  }
	   }
	   else output_file=stdout;  
	   ts->report(output_file,dataset_name,splits,split_num,tiles,max_training_images,phylib_path,phylip_algorithm,export_tsv,test_set_path);
	   if (output_file!=stdout) fclose(output_file);
	   /* copy the .ps and .jpg of the dendrogram to the output path of the report */
	   if (phylib_path && (strchr(phylib_path,'/'))) 
	   {  char command_line[512],ps_file_path[512];
	      strcpy(ps_file_path,report_file_name);
          (strrchr(ps_file_path,'/'))[1]='\0';
          sprintf(command_line,"mv ./%s.ps %s",dataset_name,ps_file_path);
          system(command_line);
          sprintf(command_line,"mv ./%s.jpg %s",dataset_name,ps_file_path);
          system(command_line);
		  if (export_tsv)
          {  sprintf(command_line,"cp -r ./tsv %s",ps_file_path);
             system(command_line);		  
             sprintf(command_line,"rm -r ./tsv");
             system(command_line);
          }
	   }
	}
    delete ts;
    for (split_index=0;split_index<split_num;split_index++)
    {  delete splits[split_index].confusion_matrix;
       delete splits[split_index].similarity_matrix;
       if (splits[split_index].feature_names) delete splits[split_index].feature_names;
       if (splits[split_index].individual_images) delete splits[split_index].individual_images;
    }
    return(1);
}


void ShowHelp()
{
   printf("\nLaboratory of Genetics/NIA/NIH \n");
   printf("usage: wndchrm [ train [-mtslcdh] <root directory> <feature_file> ] | [ test [-tsrwpijnfqvh] <feature_file> [<test_set_feature_file>] [<report_file>] ] | [ classify [-tswflcdh] <feature_file> <image_filename> ] \n");
   printf("<root directory> is a directory that has the directories of the class images as subdirectories. Images should be stored in a directory structure such that each subdirectory contains the images of one class. Currently supported file formats: TIFF, PPM. \n");
   printf("<feature_file> is the file generated by the train command. \n");       
   printf("<test_set_feature_file> optional file to a test feature file (also generated by train mode).\n");
   printf("<image_filename> is the full path to the classified image. \n");          
   printf("m - allow running multiple instances of this program (to be used on multiple-processor machines).\n");
   printf("tN - split the image into NxN tiles. The default is 1.\n");
   printf("l - Use a large image feature set.\n");
   printf("c - Compute color features.\n");
   printf("dN - Downsample the images (N percents, where N is 1 to 100)\n");
   printf("s - silent mode.\n");
   printf("w - Classify with wnd instead of wnn. \n");
   printf("fN - maximum number of features out of the dataset (0,1) . The default is 0.15. \n");
   printf("rN - the split ratio of the dataset to training/test subsets (0,1). The default is 0.25. \n");
   printf("i[#]N - Set a maximal number of training images (for each class). If the '!' is specified then the class is ignored if it doesn't have at least N samples.\n");
   printf("jN - Set a maximal number of test images (for each class). \n");
   printf("nN - Number of repeated random splits. The default is 1.\n");
   printf("p[+][k][path] - Output a full report in HTML format. 'path' is an optional path to phylib3.65 root dir for generating dendrograms. The optinal '+' creates a directory and exports the data into tsv files. 'k' is an optional digit (1..3) of the specific phylip algorithm to be used. \n");
   printf("qN - the number of first closest classes among which the presence of the right class is considered a match.\n");
   printf("v[r|w|+|-][path] - read/write the feature weights into a file.\n");   
   printf("Nx - set the maximum number of classes (use only the first x classes).\n");
   printf("h - show this note.\n\n");
   printf("examples: \n \t train: \n \t wndchrm train /path/to/dataset dataset.fit \n \t wndchrm train -mcl /path/to/dataset dataset.fit \n \t test: \n \t wndchrm test -f0.1 dataset.fit \n \t wndchrm test -f0.2 -i50 -j20 -n5 -p/path/to/phylip3.65 dataset.fit report.html \n");
   printf("\t classify: \n \t wndchrm classify /path/to/image.tif dataset.fit \n \t wndchrm classify -f0.2 -cl /path/to/image.tif dataset.fit \n");
   printf("\nIf you have more questions about this software, please email me (lior shamir) at <shamirl [at] mail [dot] nih [dot] gov> \n\n");
   return;
}


int main(int argc, char *argv[])
{   char *root_dir, *filename, *image_filename;
    int multi_processor=0;
    int arg_index=1;
    int tiles=1;
    int method=0;
    int report=0;
    int splits_num=1;
    int large_set=0;
    int colors=0;
    int downsample=100;
    double split_ratio=0.25;
    double max_features=0.15;
    int max_training_images=0;
    int max_test_images=0;
    int train=0;
    int test=0;
    int classify=0;
    char phylib_path_buffer[256];
    char *phylib_path=NULL;
    char report_file_buffer[256];
    char *report_file=NULL;
    int export_tsv=0;
    int phylip_algorithm=0;
    int exact_training_images=0;
    long first_n=1;
	char weight_file_buffer[256];
    char weight_vector_action='\0';
	char *test_set_path=NULL;
	int N=0;
	
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

	/* read the switches */
    while (argv[arg_index][0]=='-')
    {   if (argv[arg_index][1]=='p')
        {  report=1;
		   if ((strchr(argv[arg_index],'p')[1])=='+') export_tsv=1;
		   if (isdigit(strchr(argv[arg_index],'p')[1+export_tsv])) phylip_algorithm=(strchr(argv[arg_index],'p')[1+export_tsv])-'0';
           if ((strchr(argv[arg_index],'p')[1+export_tsv+(phylip_algorithm>0)])=='/' || (strchr(argv[arg_index],'p')[1+export_tsv+(phylip_algorithm>0)])=='.')
		   {   strcpy(phylib_path_buffer,&(strchr(argv[arg_index],'p')[1+export_tsv+(phylip_algorithm>0)]));
               phylib_path=phylib_path_buffer;
		   }
		   if (phylip_algorithm<=0) phylip_algorithm=1;   /* set the default */
		   arg_index++;
		   continue;	/* so that the path will not trigger other switches */
        }
		if (argv[arg_index][1]=='v' && strlen(argv[arg_index])>3)
		{  weight_vector_action=argv[arg_index][2];
		   if (weight_vector_action!='r' && weight_vector_action!='w' && weight_vector_action!='+' && weight_vector_action!='-')
		     show_error("Unspecified weight vector action (-v switch)",1);
		   strcpy(weight_file_buffer,&(strchr(argv[arg_index],'v')[2]));
		   arg_index++;
		   continue;   /* so that the path will not trigger other switches */
		}
	    if (strchr(argv[arg_index],'m')) multi_processor=1;
        if (strchr(argv[arg_index],'t')) tiles=atoi(&(strchr(argv[arg_index],'t')[1]));
        if (strchr(argv[arg_index],'n')) splits_num=atoi(&(strchr(argv[arg_index],'n')[1]));
        if (strchr(argv[arg_index],'s')) print_to_screen=0;
        if (strchr(argv[arg_index],'l')) large_set=1;
        if (strchr(argv[arg_index],'c')) colors=1;
        if (strchr(argv[arg_index],'d')) downsample=atoi(&(strchr(argv[arg_index],'d')[1]));
        if (strchr(argv[arg_index],'f')) max_features=atof(&(strchr(argv[arg_index],'f')[1]));
        if (strchr(argv[arg_index],'r')) split_ratio=atof(&(strchr(argv[arg_index],'r')[1]));
        if (strchr(argv[arg_index],'q')) first_n=atoi(&(strchr(argv[arg_index],'q')[1]));
        if (strchr(argv[arg_index],'N')) N=atoi(&(strchr(argv[arg_index],'N')[1]));
        if (strchr(argv[arg_index],'i'))
        {  exact_training_images=(strchr(argv[arg_index],'i')[1]=='#');
           max_training_images=atoi(&(strchr(argv[arg_index],'i')[1+exact_training_images]));
        }
        if (strchr(argv[arg_index],'j')) max_test_images=atoi(&(strchr(argv[arg_index],'j')[1]));
        if (strchr(argv[arg_index],'w')) method=1;
        if (strchr(argv[arg_index],'h'))
        {  ShowHelp();
           return(1);
        }
        arg_index++;
     }

	 /* check that the values in the switches are correct */
	 if (test && splits_num<=0) show_error("splits number (n) must be an integer greater than 0",1);
	 if (test && max_training_images<0) show_error("Maximal number of training images (i) must be an integer greater than 0",1);
	 if (test && max_test_images<0) show_error("maximal number of test images (j) must be an integer greater than 0",1);
	 if (test && report && arg_index==argc-1) show_error("a report html file must be specified",1);
	 if (tiles<=0) show_error("number of tiles (t) must be an integer greater than 0",1);
	 if (downsample<1 || downsample>100) show_error("downsample size (d) must be an integer between 1 to 100",1);
	 if (split_ratio<0 || split_ratio>1) show_error("split ratio (r) must be between 0 to 1",1);
	 if (splits_num<1 || splits_num>MAX_SPLITS) show_error("splits num out of range",1);
     if (weight_vector_action!='\0' && weight_vector_action!='r' && weight_vector_action!='w' && weight_vector_action!='-' && weight_vector_action!='+') show_error("-v must be followed with either 'w' (write) or 'r' (read) ",1);
	 
	 /* run */
     if (arg_index<argc)
     { if (train)
       {  root_dir=argv[arg_index++];
          filename=argv[arg_index];
          compute_features(root_dir, filename,MAX_CLASS_NUM, tiles, multi_processor,large_set,colors,downsample);
       }
       if (test)
       {   filename=argv[arg_index++];
	       /* check if there is a test set feature file */
	       if (arg_index<argc && strstr(argv[arg_index],".htm")==NULL)  
	          test_set_path=argv[arg_index++];
	       /* check if there is a report file name */
	       if (arg_index<argc)  
		   {  strcpy(report_file_buffer,argv[arg_index]);
		      report_file=report_file_buffer;
			  report=1;   /* assume that the user wanted a report if a report file was specified */
		   }
           split_and_test(filename, report_file, MAX_CLASS_NUM, method, tiles, split_ratio, max_features,splits_num,report,max_training_images,
		                  exact_training_images,max_test_images,phylib_path,phylip_algorithm,export_tsv,first_n,weight_file_buffer,weight_vector_action,N,
						  test_set_path);
       }
	   if (classify)
	   {  filename=argv[arg_index++];
	      image_filename=argv[arg_index];
          classify_image(filename,image_filename, max_features, tiles, method, large_set, colors, downsample);
	   }
     }
     else ShowHelp();

     return(1);
}
