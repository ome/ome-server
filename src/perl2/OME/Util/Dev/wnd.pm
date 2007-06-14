# /Library/Perl/5.8.6/OME/Analysis/Modules/ImageClassifier/ComputeFeatures.pm

#-------------------------------------------------------------------------------
#
# Copyright (C) 2003 Open Microscopy Environment
#       Massachusetts Institute of Technology,
#       National Institutes of Health,
#       University of Dundee
#
#
#
#    This library is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser General Public
#    License as published by the Free Software Foundation; either
#    version 2.1 of the License, or (at your option) any later version.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public
#    License along with this library; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#
# Written by:   Lior Shamir
#				shamirl [at@] mail [dot] nih ((.)) gov
#
#-------------------------------------------------------------------------------

package OME::Util::Dev::wnd;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use base qw(OME::Util::Commands);

use IO::File;
use Log::Agent;
use Getopt::Long;
use OME::Image::Server::Pixels;
use OME::Session;
use OME::SessionManager;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use Time::HiRes qw(gettimeofday tv_interval);


# use Inline => Config => LIBS => '-L/usr/local/mylib -lmylib';
# use Inline => Config => INC  => '-I/usr/include';

# use Inline (Config => DIRECTORY => $CACHE_DIRECTORY);
use Inline (
	C  => 'DATA',
	CC => 'g++',
        INC  => '-I/home/shamirl/sigs',
        LIBS => '-ltiff -L/home/shamirl/sigs -limfit -lfftw3',
	NAME => 'OME::Util::Dev::wnd',
);

Inline->init;


sub getCommands 
{
   return
    {
       'hello_world' => 'hello_world',
       'compile_sigs' => 'compile_sigs',
       'test' => 'test',
       'classify' => 'classify',       
      };
}

sub hello_world_help 
{
   my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This will print hello world
    
USAGE
}

sub hello_world 
{
    my ($self,$commands) = @_;
    my $script = $self->scriptName();
    my $command_name = $self->commandName($commands);
	
    print "hello world\n";
}


sub read_from_database
{  
        my ($self,$datasetStr) = @_;
        my $script = $self->scriptName();

        my $session = $self->getSession();
        my $factory = $session->Factory();

        my $datasetData =
        {  name   => $datasetStr,
           owner  => $session->User(),
        };
        my $dataset = $factory->findObject( "OME::Dataset", $datasetData);
        die "Dataset with name $datasetStr doesn't exist!" unless $dataset;

        # get a list of all semantic types
        my %semantic_types=();
        my $buf="";
        for (my $a=0;$a<400;$a++) {$buf=$buf."a";}
        my @signatures=CompFeatures($buf,20,20,1);
        while (scalar(@signatures)>0)
        {
            my $sig_value=pop(@signatures);
            my $sig_name=pop(@signatures);
            my ($semantic_type_name,$semantic_type_element)=split(/ +/,$sig_name);
            $semantic_types{$semantic_type_name}{$semantic_type_element}=$sig_value;
        }

        # read the features
        my @images = $dataset->images( __order => ['name', 'id'] );
        my $image_counter=0;
        my $total_number_of_images=scalar(@images);
        init(0,"",$total_number_of_images);
        foreach my $img (@images)
        {  $image_counter=$image_counter+1;
           print "$image_counter / $total_number_of_images \n";
           # read the image category                
           my $image_classification = $factory -> findAttribute ('Classification', image=>$img);
           my $image_category_name=$image_classification->Category()->Name();

           # get the features of the image

           my @features = $img->all_features();
           foreach my $feature (@features)
           {
             # read the feature values
             InitSigs();
             while (my ($semantic_type_name, $semantic_type_elements) = each(%semantic_types) )
             {  my $this_st = $factory -> findAttribute ($semantic_type_name, $feature);
                while (my $semantic_type_element = each (%$semantic_type_elements))
                {
                   my $value=$this_st->$semantic_type_element();
                   my $sig_name=$semantic_type_name . " " . $semantic_type_element;
#print " $sig_name: $value \n";
                   AddSig($sig_name, $value);
                }
              }
              #add the image       
              AddImage($image_category_name);
           }
        }
}


sub compile_sigs_help
{
   my ($self,$commands) = @_;
   my $script = $self->scriptName();
   my $command_name = $self->commandName($commands);
    
    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This will compute the image features for the specified dataset.
Options:

-d   dataset

-f feature file name    
    
USAGE
}



sub compile_sigs
{
        my ($self,$commands) = @_;
        my $script = $self->scriptName();
        my $command_name = $self->commandName($commands);
	
	    my ($datasetStr,$split_ratio,$filename, $threshold);
	
	    # get the parameters and initialize
	    GetOptions ('d=s' => \$datasetStr,
	            'f=s' => \$filename);

        die "filename not specified"
             unless ($filename);
 
 	    die "dataset not specified"
	         unless ($datasetStr);	
        
        read_from_database($self,$datasetStr);
 
        cleanup(1, $filename);
}


sub test_help
{
   my ($self,$commands) = @_;
   my $script = $self->scriptName();
   my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This will compute the image features for the specified dataset.
Options:

-d  dataset

-f  feature file name

-r  Train/test split ratio (0,1)

-n  No. features (0,1)    

-w use WND 5

- t tiles

USAGE
}


sub test
{
        my ($self,$commands) = @_;
        my $script = $self->scriptName();
        my $command_name = $self->commandName($commands);
#        my $environment = OME::Install::Environment->initialize();

        my ($datasetStr,$split_ratio,$filename, $threshold,$wnd5,$tiles);

        # get the parameters and initialize
        GetOptions ('d=s' => \$datasetStr,
                    'r=s' => \$split_ratio,
                    'f=s' => \$filename,
                    'w=s' => \$wnd5,
                    't=s' => \$tiles,  
                    'n=s' => \$threshold);

        die "dataset or filename not specified"
           unless ($datasetStr || $filename);
        $split_ratio=0.25
           unless ($split_ratio);
        $threshold=0.25
           unless ($threshold);
        $wnd5=0
           unless ($wnd5);
        $tiles=1
           unless ($tiles);
           
           
        if ($datasetStr)
        {  read_from_database($self,$datasetStr);
        }
        if ($filename)
        {  init(1,$filename,0);
        }
        
        my $res = TestDataset($split_ratio, $threshold,$wnd5,$tiles);
        print "accuracy: $res \n";
        cleanup(0,"");
}


sub classify_help
{
   my ($self,$commands) = @_;
   my $script = $self->scriptName();
   my $command_name = $self->commandName($commands);

    $self->printHeader();
    print <<"USAGE";
Usage:
    $script $command_name [<options>]

This will compute the image features for the specified dataset.
Options:

-d  dataset

-f  feature file name

-n  No. features (0,1)    

-w use WND 5

-i  image id

USAGE
}


sub classify
{      my ($self,$commands) = @_;
        my $script = $self->scriptName();
        my $command_name = $self->commandName($commands);
#        my $environment = OME::Install::Environment->initialize();

        my ($datasetStr,$image_id,$split_ratio,$filename, $threshold,$wnd5);

        # get the parameters and initialize
        GetOptions ('d=s' => \$datasetStr,
                    'f=s' => \$filename,
                    'w=s' => \$wnd5,
                    'i=s' => \$image_id,  
                    'n=s' => \$threshold);

        die "dataset or filename not specified"
           unless ($datasetStr || $filename);        
        die "image id not specified"
           unless ($image_id);        
        $threshold=0.25
           unless ($threshold);
        $wnd5=0
           unless ($wnd5);
                
        if ($datasetStr)
        {  read_from_database($self,$datasetStr);
        }
        if ($filename)
        {  init(1,$filename,0);
        }
        SetScores($threshold);
        
        my $session = $self->getSession();
        my $factory = $session->Factory();
        my $image =$factory->loadObject("OME::Image",$image_id);       
        my $image_pixels = $image->DefaultPixels();   	   
	    my $pixels = OME::Image::Server::Pixels->open($image_pixels->ImageServerID());
	    my ($x,$y,$z,$c,$t,$bytesPerPixel) = $pixels->getDimensions();
	    my $buf = $pixels->getPixels();
	    classify_image($buf, $x, $y, $bytesPerPixel, $wnd5);

       
}

1;

__DATA__
__C__

#include <string.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "cmatrix.h"
#include "signatures.h"
#include "TrainingSet.h"

#define MAX_CLASS_NUM 200
#define MAX_IMAGE_NUM 200000
#define CAT_NAME_LENGTH 80

unsigned short confusion_matrix[(MAX_CLASS_NUM+1)*(MAX_CLASS_NUM+1)];

char category_names[CAT_NAME_LENGTH][MAX_CLASS_NUM];	
long category_count=0;

TrainingSet *ts=NULL;
signatures *ImageSignatures=NULL;


ImageMatrix *buff2matrix(unsigned char *buffer, int width, int height, int bytes_per_pixel)
{    int x,y;
     unsigned char *p_buffer;
     ImageMatrix *matrix;
     matrix=new ImageMatrix(width,height);
     
    p_buffer=buffer;
    for (y=0;y<height;y++)
      for (x=0;x<width;x++)
      {  long *long_pix;
          float *float_pix;
          unsigned char *byte_pix;
          double pixel_value;             
          if (bytes_per_pixel==1)
          {    byte_pix=(unsigned char *)p_buffer;  
                pixel_value=(double )(*byte_pix);                        
          }
          if (bytes_per_pixel==4)
          {  float_pix=(float *)p_buffer;
              pixel_value=(double)(*float_pix);         
          }
          matrix->data[x][y].intensity=pixel_value;
          p_buffer+=bytes_per_pixel;
      } 
      
      return(matrix);     
}

void CompFeatures(unsigned char *buffer, int width, int height, int bytes_per_pixel)
{  ImageMatrix *matrix;
    signatures *ImageSignatures;
    long num_of_parameters;
     Inline_Stack_Vars;    
    matrix=buff2matrix(buffer, width, height,bytes_per_pixel);

     /* compute the image features */    
     ImageSignatures=new signatures;
     ImageSignatures->compute(matrix);

     Inline_Stack_Reset;
    
     /* add the signature values */
     for (int a=0;a<ImageSignatures->count;a++)
     {  
        Inline_Stack_Push(sv_2mortal(newSVpv(ImageSignatures->data[a].name,0)));                                   
        Inline_Stack_Push(sv_2mortal(newSVnv(ImageSignatures->data[a].value)));          
     }
     num_of_parameters=ImageSignatures->count*2;
    Inline_Stack_Done;
     
     /* free allocated class objects */
     delete matrix;   
     delete ImageSignatures;

     Inline_Stack_Return(num_of_parameters);
}

int init(int load, char *file_name, int image_num)
{  
   category_count=0;
   if (image_num==0) image_num=MAX_IMAGE_NUM;
   ts=new TrainingSet(image_num,MAX_CLASS_NUM);
   if (!ts) return(0);   
   if (load)
   {  if (ts->ReadFromFile(file_name))
       {   int a;
            for (a=1;a<=ts->class_num;a++)
               strcpy(category_names[a],ts->class_labels[a]);
            return(1);
       }
       else return(0);
   }
   return(1);
}


int cleanup(int save, char *save_to_file)
{  int a,b;
   if (ts && save)
     ts->SaveToFile(save_to_file);
   if (ts) delete ts;
}


void InitSigs()
{
   ImageSignatures=new signatures;
}

void AddSig(char *name, double value)
{
   ImageSignatures->Add(name,value);
}

int AddImage(char *category_name)
{   long category_index;
    long this_category=0;
    /* find the class category */
    for (category_index=1;category_index<=category_count;category_index++)
      if (strcmp(category_names[category_index],category_name)==0)
      {  this_category=category_index;
          break;
      }
      if (this_category==0)   /* the first image in its category */
      {   category_count++;
          ts->class_num=this_category=category_count;
      }
     strcpy(category_names[this_category],category_name);
     strcpy(ts->class_labels[this_category],category_name);

     ImageSignatures->sample_class=this_category;
     strcpy(ImageSignatures->full_path,"");   
     ts->AddSample(ImageSignatures);
     
}

void SetScores(double threshold)
{
     ts->normalize();
     ts->SetFisherScores(threshold,NULL);
}

double TestDataset(double split_ratio, double threshold, int wnd5, int tiles)
{   TrainingSet *train,*test;
     double res;
     time_t t;
     srand((unsigned) time(&t));
     train=new TrainingSet(MAX_IMAGE_NUM,MAX_CLASS_NUM);
     test=new TrainingSet(MAX_IMAGE_NUM,MAX_CLASS_NUM);
     ts->split(split_ratio,train,test,tiles);              
     train->normalize();                 
     train->SetFisherScores(threshold,NULL);     
     res=train->Test(test,0,confusion_matrix,NULL,wnd5);
     ts->PrintConfusion(confusion_matrix,NULL,0);
     delete train;
     delete test;
     return(res);
}

long classify_image(unsigned char *buffer, int width, int height, int bytes_per_pixel, int wnd5)
{  long res,class_index;
    double probabilities[MAX_CLASS_NUM];
    ImageMatrix *matrix;
    signatures *test_sample;
    
   /* compute the signatures */
   matrix=buff2matrix(buffer, width, height,bytes_per_pixel);
   test_sample=new signatures;
   test_sample->compute(matrix); 
    /* classifiy */
    if (wnd5)  res=ts->classify2(test_sample,probabilities);
    else res=ts->WNNclassify(test_sample,probabilities);
    
    printf("The class is %d - %s \n",res,category_names[res]);
    for (class_index=1;class_index<=category_count;class_index++)
       printf("probability: %d - %s: %f",class_index,category_names[class_index],probabilities[class_index]);
    printf("\n");
    
    /* clear allocated memory */
    delete matrix;    
    delete test_sample;        
    
    return(res);
}



