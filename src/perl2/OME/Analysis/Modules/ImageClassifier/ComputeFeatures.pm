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
use OME::Image::Server::Pixels;

use base qw(OME::Analysis::Handlers::DefaultLoopHandler);
use Time::HiRes qw(gettimeofday tv_interval);


# use Inline => Config => LIBS => '-L/usr/local/mylib -lmylib';
# use Inline => Config => INC  => '-I/usr/include';

# use Inline (Config => DIRECTORY => $CACHE_DIRECTORY);
use Inline (
	C       => 'DATA',
	CC => 'g++',
#	LIBS    => ['-lcurl'],
    INC  => '-I/Volumes/Windows/projects/sigs',
    LIBS => '-ltiff -L/Volumes/Windows/projects/sigs -limfit -lfftw3',
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


/* build the ImageMatrix structure */
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
//printf("%s: %f\n",ImageSignatures->data[a].name,ImageSignatures->data[a].value);
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


