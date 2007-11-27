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

package OME::Analysis::Modules::ImageClassifier::ComputeFeatures;

use strict;
use OME;
our $VERSION = $OME::VERSION;

use IO::File;
use Log::Agent;
use Carp;
use OME::Image::Server::Pixels;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use Time::HiRes qw(gettimeofday tv_interval);


our $CACHE_DIR;
our $LIB_DIR;
our $INC_DIR;
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
		croak "OME::Analysis::Modules::ImageClassifier::ComputeFeatures was loaded without an OME installation environment!";
	}
	if (not -d $CACHE_DIR) {
		mkpath $CACHE_DIR
			or croak "Could not create cache directory for OME::Util::cURL";
	}
	if (not -d $LIB_DIR or not -d $INC_DIR) {
		croak "Both  $LIB_DIR and $INC_DIR must exist in order for OME::Analysis::Modules::ImageClassifier::ComputeFeatures to compile.";
	}
}

use Inline (Config => DIRECTORY => $CACHE_DIR);

use Inline (
	C       => 'DATA',
	CC => 'g++',
	LD => 'g++',
    INC  => "-I$INC_DIR",
    LIBS => "-ltiff -L$LIB_DIR -limfit -lfftw3",
	NAME    => 'OME::Analysis::Modules::ImageClassifier::ComputeFeatures',
#	CLEAN_AFTER_BUILD => 0,
);

Inline->init;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = $class->SUPER::new(@_);

	bless $self,$class;
	return $self;
}


sub startImage {
	my ($self,$image) = @_;
	$self->SUPER::startImage($image);
	my $mex = $self->getModuleExecution();
    my $session = OME::Session->instance();
	my $factory = $session->Factory();
	
	my $start_time = [gettimeofday()];
	$mex->read_time(tv_interval($start_time));
	$mex->execution_time(0);
	$start_time = [gettimeofday()];
	
    my $derived_pixels = $self->getCurrentInputAttributes("Pixels")->[0];
    my $pixels = OME::Image::Server::Pixels->open($derived_pixels->Parent()->ImageServerID());
	my ($x,$y,$z,$c,$t,$bytesPerPixel) = $pixels->getDimensions();
    my $x=scalar($derived_pixels->StartX());
    my $y=scalar($derived_pixels->StartY());
    my $x2=scalar($derived_pixels->EndX());
    my $y2=scalar($derived_pixels->EndY());
    my $buf = $pixels->getROI(
       $x,$y,scalar($derived_pixels->StartZ()),scalar($derived_pixels->StartC()),scalar($derived_pixels->StartT()),
       $x2,$y2,scalar($derived_pixels->EndZ()),scalar($derived_pixels->EndC()),scalar($derived_pixels->EndT()) );

	# compute features 
	my @signatures=CompFeatures($buf, ($x2-$x)+1, ($y2-$y)+1, $bytesPerPixel);
	# arrange the signatures in semantic types
	my %semantic_types=();
    while (scalar(@signatures)>0)
    {   
         my $sig_value=pop(@signatures);
         my $sig_name=pop(@signatures);
         my ($semantic_type_name,$semantic_type_element)=split(/ +/,$sig_name);         
         $semantic_types{$semantic_type_name}{$semantic_type_element}=$sig_value;
    }	
	
   # store the values in the database	
   while (my ($semantic_type_name, $semantic_type) = each(%semantic_types) )
   {
print "$semantic_type_name  \n";  
while ( my ($key2, $value2) = each(%$semantic_type) ) 
{ print "\t$key2 $value2 \n";
}

      $factory->newAttribute($semantic_type_name,$derived_pixels->feature(),$mex,$semantic_type);
   }

	$mex->write_time(tv_interval($start_time));
	$mex->storeObject();	
}





1;

__DATA__
__C__

#include <string.h>
#include <stdio.h>
#include <time.h>
#include "cmatrix.h"
#include "signatures.h"
#include "TrainingSet.h"


/* build the ImageMatrix structure */
ImageMatrix *buff2matrix(unsigned char *buffer, int width, int height, int bytes_per_pixel)
{    int x,y;
     unsigned char *p_buffer;
     ImageMatrix *matrix;
     matrix=new ImageMatrix(width,height);
     matrix->bits=8*bytes_per_pixel;
     
    p_buffer=buffer;
    for (y=0;y<height;y++)
      for (x=0;x<width;x++)
      {  long *long_pix;
          float *float_pix;
          unsigned short *short_pix;
          unsigned char *byte_pix;
          double pixel_value;             
          if (bytes_per_pixel==1)
          {    byte_pix=(unsigned char *)p_buffer;  
                pixel_value=(double )(*byte_pix);                        
          }
          if (bytes_per_pixel==2)
          {  short_pix=(unsigned short *)p_buffer;
             pixel_value=(double)(*short_pix);
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
    TrainingSet *name_sig_ts;
    
    long num_of_parameters;
    Inline_Stack_Vars;    
    matrix=buff2matrix(buffer, width, height,bytes_per_pixel);

     /* compute the image features */    
     name_sig_ts=new TrainingSet(1,2);    /* this is used for getting the feature names */
     ImageSignatures=new signatures;
     ImageSignatures->NamesTrainingSet=name_sig_ts;
     ImageSignatures->compute(matrix,0);

     Inline_Stack_Reset;
    
     /* add the signature values */
     for (int sig_index=0;sig_index<ImageSignatures->count;sig_index++)
     {  
//printf("%s: %f\n",ImageSignatures->data[a].name,ImageSignatures->data[sig_index].value);
//        Inline_Stack_Push(sv_2mortal(newSVpv(ImageSignatures->data[sig_index].name,0)));                                   
        Inline_Stack_Push(sv_2mortal(newSVpv(name_sig_ts->SignatureNames[sig_index],0)));
        Inline_Stack_Push(sv_2mortal(newSVnv(ImageSignatures->data[sig_index].value)));          
     }
     num_of_parameters=ImageSignatures->count*2;
    Inline_Stack_Done;
     
     /* free allocated class objects */
     delete matrix;   
     delete ImageSignatures;
     delete name_sig_ts;
    
     Inline_Stack_Return(num_of_parameters);
}


