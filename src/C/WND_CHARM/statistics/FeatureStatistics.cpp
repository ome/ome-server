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




#pragma hdrstop

#ifndef WIN32
#include <string.h>
#endif

#include "FeatureStatistics.h"

typedef struct POINT1
{  long x,y;
}point;

//---------------------------------------------------------------------------
/*  BWlabel
    label groups of 4-connected pixels.
    This is an implementation of the Matlab function bwlabel
*/
int bwlabel(ImageMatrix *Im, int level)
{  int x,y,base_x,base_y,group_counter=1;
   int stack_count;
   point *stack=new point[Im->width*Im->height];

   for (y=0;y<Im->height;y++)
     for (x=0;x<Im->width;x++)
     {
        if (Im->data[x][y].intensity==1)
        {
           /* start a new group */
           group_counter++;
           Im->data[x][y].intensity=group_counter;
           stack[0].x=x;
           stack[0].y=y;
           stack_count=1;
           while (stack_count>0)
           {  base_x=stack[0].x;
              base_y=stack[0].y;

              if (base_x>0 && Im->data[base_x-1][base_y].intensity==1)
              {  Im->data[base_x-1][base_y].intensity=group_counter;
                 stack[stack_count].x=base_x-1;
                 stack[stack_count].y=base_y;
                 stack_count++;
              }

              if (base_x<Im->width-1 && Im->data[base_x+1][base_y].intensity==1)
              {  Im->data[base_x+1][base_y].intensity=group_counter;
                 stack[stack_count].x=base_x+1;
                 stack[stack_count].y=base_y;
                 stack_count++;
              }

              if (base_y>0 && Im->data[base_x][base_y-1].intensity==1)
              {  Im->data[base_x][base_y-1].intensity=group_counter;
                 stack[stack_count].x=base_x;
                 stack[stack_count].y=base_y-1;
                 stack_count++;
              }

              if (base_y<Im->height-1 && Im->data[base_x][base_y+1].intensity==1)
              {  Im->data[base_x][base_y+1].intensity=group_counter;
                 stack[stack_count].x=base_x;
                 stack[stack_count].y=base_y+1;
                 stack_count++;
              }

              /* look for 8 connected pixels */
              if (level==8)
              {  if (base_x>0 && base_y>0 && Im->data[base_x-1][base_y-1].intensity==1)
                 {  Im->data[base_x-1][base_y-1].intensity=group_counter;
                    stack[stack_count].x=base_x-1;
                    stack[stack_count].y=base_y-1;
                    stack_count++;
                 }

                if (base_x<Im->width-1 && base_y>0 && Im->data[base_x+1][base_y-1].intensity==1)
                {  Im->data[base_x+1][base_y-1].intensity=group_counter;
                   stack[stack_count].x=base_x+1;
                   stack[stack_count].y=base_y-1;
                   stack_count++;
                }

                if (base_x>0 && base_y<Im->height-1 && Im->data[base_x-1][base_y+1].intensity==1)
                {  Im->data[base_x-1][base_y+1].intensity=group_counter;
                   stack[stack_count].x=base_x-1;
                   stack[stack_count].y=base_y+1;
                   stack_count++;
                }

                if (base_x<Im->width-1 && base_y<Im->height-1 && Im->data[base_x+1][base_y+1].intensity==1)
                {  Im->data[base_x+1][base_y+1].intensity=group_counter;
                   stack[stack_count].x=base_x+1;
                   stack[stack_count].y=base_y+1;
                   stack_count++;
                }
              }
              stack_count-=1;
              memcpy(stack,&(stack[1]),sizeof(point)*stack_count);
           }
        }
     }

   /* now decrease every non-zero pixel by one because the first group was "2" */
   for (y=0;y<Im->height;y++)
     for (x=0;x<Im->width;x++)
        if (Im->data[x][y].intensity!=0)
          Im->data[x][y].intensity-=1;

   delete stack;
   return(group_counter-1);
}

/* the input should be a binary image */
void GlobalCentroid(ImageMatrix *Im, double *x_centroid, double *y_centroid)
{  int x,y;
   double x_mass=0,y_mass=0,mass=0;

   for (y=0;y<Im->height;y++)
     for (x=0;x<Im->width;x++)
       if (Im->data[x][y].intensity>0)
       {  x_mass=x_mass+x+1;    /* the "+1" is only for compatability with matlab code (where index starts from 1) */
          y_mass=y_mass+y+1;    /* the "+1" is only for compatability with matlab code (where index starts from 1) */
          mass++;
       }
   *x_centroid=x_mass/mass;
   *y_centroid=y_mass/mass;

//   for (y=0;y<Im->height;y++)
//     for (x=0;x<Im->width;x++)
//       if (Im->data[x][y].intensity>0) mass++;

   /* find the x coordinate of the centroid */
//   for (x=0;x<Im->width;x++)
//   {  for (y=0;y<Im->height;y++)
//        x_mass=x_mass+Im->data[x][y].intensity;
//      if (x_mass>=mass/2)
//      {  *x_centroid=x;
//         break;
//      }
//   }

   /* find the y coordinate of the centroid */
//   for (y=0;y<Im->height;y++)
//   {  for (x=0;x<Im->width;x++)
//        y_mass=y_mass+Im->data[x][y].intensity;
//      if (y_mass>=mass/2)
//      {  *y_centroid=y;
//         break;
//      }
//   }
}

/* find the centroid of a certain feature
   the input image should be a bwlabel transform of a binary image
   the retruned value is the area of the feature
*/
int FeatureCentroid(ImageMatrix *Im, double object_index,double *x_centroid, double *y_centroid)
{  int x,y;
   double x_mass=0,y_mass=0,mass=0;


   for (y=0;y<Im->height;y++)
     for (x=0;x<Im->width;x++)
       if (Im->data[x][y].intensity==object_index)
       {  x_mass=x_mass+x+1;      /* the "+1" is only for compatability with matlab code (where index starts from 1) */
          y_mass=y_mass+y+1;      /* the "+1" is only for compatability with matlab code (where index starts from 1) */
          mass++;
       }
   *x_centroid=x_mass/mass;
   *y_centroid=y_mass/mass;
   return(mass);



//   for (y=0;y<Im->height;y++)
//     for (x=0;x<Im->width;x++)
//       if (Im->data[x][y].intensity==object_index) mass++;

   /* find the x coordinate of the centroid */
//   for (x=0;x<Im->width;x++)
//   {  for (y=0;y<Im->height;y++)
//        if (Im->data[x][y].intensity==object_index)
//          x_mass++;
//        if (x_mass>=mass/2)
//        {  *x_centroid=x;
//            break;
//        }
//   }

   /* find the y coordinate of the centroid */
//   for (y=0;y<Im->height;y++)
//   {  for (x=0;x<Im->width;x++)
//        if (Im->data[x][y].intensity==object_index)
//          y_mass++;
//        if (y_mass>=mass/2)
//        {  *y_centroid=y;
//           break;
//        }
//   }
//   return(mass);
}

/* the number of pixels that are above the threshold
   the input image is a binary image
*/
int area(ImageMatrix *Im)
{  int x,y,sum=0;
   for (y=0;y<Im->height;y++)
     for (x=0;x<Im->width;x++)
       sum=sum+(Im->data[x][y].intensity>0);
   return(sum);
}

/* EulerNumber
   The input image should be a binary image
*/
int EulerNumber(ImageMatrix *Im, int FeatureNumber)
{  int x,y,HolesNumber;
   ImageMatrix *cp;
   cp=Im->duplicate();

   /* inverse the image */
   for (y=0;y<cp->height;y++)
     for (x=0;x<cp->width;x++)
       if (cp->data[x][y].intensity>0)
         cp->data[x][y].intensity=0;
       else cp->data[x][y].intensity=1;
   HolesNumber=cp->BWlabel(8);

   delete cp;
   return(FeatureNumber-HolesNumber-1);
}

#pragma package(smart_init)
