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
use OME::Tasks::ImageManager;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use Time::HiRes qw(gettimeofday tv_interval);


our $CACHE_DIR;
our $LIB_DIR;
our $INC_DIR;
our $PACKAGE_NAME = 'OME::Util::Dev::wnd';
BEGIN {
	my $environment = initialize OME::Install::Environment;
	if ($environment and $environment->base_dir()) {
		$CACHE_DIR = $environment->base_dir().'/Inline';
		$LIB_DIR = $environment->base_dir().'/lib';
		$INC_DIR = $environment->base_dir().'/include';
	} else {
# Uncomment the following lines and comment out the line after that if the intent really is to
# be able to run this without an OME install environment bootstrap.
#		$CACHE_DIR = '/var/tmp/Inline';
#		$LIB_DIR = '/usr/local/lib';
#		$INC_DIR = '/usr/local/include';
		croak "$PACKAGE_NAME was loaded without an OME installation environment!";
	}
	if (not -d $CACHE_DIR) {
		mkpath $CACHE_DIR
			or croak "Could not create cache directory for $PACKAGE_NAME";
	}
	if (not -d $LIB_DIR or not -d $INC_DIR) {
		croak "Both  $LIB_DIR and $INC_DIR must exist in order for $PACKAGE_NAME to compile.";
	}
}

use Inline (Config => DIRECTORY => $CACHE_DIR);

use Inline (
	C  => 'DATA',
	CC => 'g++',
	LD => 'g++',
    INC  => "-I$INC_DIR",
    LIBS => "-ltiff -L$LIB_DIR -limfit -lfftw3",
	NAME => $PACKAGE_NAME,
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
           my $image_path= OME::Tasks::ImageManager->getImageOriginalFiles($img)->Path();
print "$image_path \n";
#		print "hello ".$img->name()."\n";
                
           # get the features of the image

           my @features = $img->all_features();
           my $do_once=0;
           foreach my $feature (@features)
           {
             # check if that feature has signature values
             my $this_st = $factory -> findAttribute ('GaborTextures',$feature);
 if (($this_st=="") || ($do_once==1))  { next;}
             
             # read the feature values
# print "before initsigs \n";                
             InitSigs();
# print "after initsigs \n";                             
             while (my ($semantic_type_name, $semantic_type_elements) = each(%semantic_types) )
             {  my $this_st = $factory -> findAttribute ($semantic_type_name, $feature);
                while (my $semantic_type_element = each (%$semantic_type_elements))
                {
                   my $value=$this_st->$semantic_type_element();
                   my $sig_name=$semantic_type_name . " " . $semantic_type_element;
# print " $sig_name: $value \n";
                   AddSig($sig_name, $value);
# print "after add value \n";                   
                }
              }
              #add the image    
print "before add image \n";              
              AddImage($image_category_name,$image_path);
              $do_once=1;
print "after add image \n";                            
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
TrainingSet *name_sig_ts=NULL;
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
     ImageSignatures->NamesTrainingSet=name_sig_ts;    /* this is used for getting the feature names */
     ImageSignatures->compute(matrix,0);

     Inline_Stack_Reset;
    
     /* add the signature values */
     for (int sig_index=0;sig_index<ImageSignatures->count;sig_index++)
     {  
//        Inline_Stack_Push(sv_2mortal(newSVpv(ImageSignatures->data[sig_index].name,0)));                                   
        Inline_Stack_Push(sv_2mortal(newSVpv(name_sig_ts->SignatureNames[sig_index],0)));
        Inline_Stack_Push(sv_2mortal(newSVnv(ImageSignatures->data[sig_index].value)));          
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
   name_sig_ts=new TrainingSet(1,2);
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
   if (name_sig_ts) delete name_sig_ts;
}


void InitSigs()
{
   ImageSignatures=new signatures;
}

void FreeSigs()
{
   if (ImageSignatures) delete ImageSignatures;
   ImageSignatures=NULL;
}

void AddSig(char *name, double value)
{
   ImageSignatures->Add(name,value);
}

int AddImage(char *category_name, char *image_path)
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
     strcpy(ImageSignatures->full_path,image_path);   
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
     ts->split(split_ratio,train,test,tiles,0,0,0);              
     train->normalize();                 
     train->SetFisherScores(threshold,NULL);     
     res=train->Test(test,wnd5,confusion_matrix,NULL,1,0,NULL);
     ts->PrintConfusion(stdout,confusion_matrix,NULL,0,0);
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
   test_sample->compute(matrix,0); 
    /* classifiy */
    if (wnd5)  res=ts->classify2(test_sample,probabilities,NULL);
    else res=ts->WNNclassify(test_sample,probabilities,NULL,NULL);
    
    printf("The class is %d - %s \n",res,category_names[res]);
    for (class_index=1;class_index<=category_count;class_index++)
       printf("probability: %d - %s: %f",class_index,category_names[class_index],probabilities[class_index]);
    printf("\n");
    
    /* clear allocated memory */
    delete matrix;    
    delete test_sample;        
    
    return(res);
}



