/*

	Track movement of cellular position
	Peter Kosa
	version 0.6

*/


import javax.media.jai.*;
import javax.media.jai.iterator.*;
import com.sun.media.jai.codec.*;
import java.io.*;
import java.awt.image.renderable.ParameterBlock;

public class TMCP  {

static int refThreshhold=0;
static int testThreshhold=0;
static int maskThreshhold=0;
static double cccp = 0;
static RectIter iter1 = null;
static RectIter iter2 = null;
static RectIter iter3 = null;
static String line = null;
static int imageThreshhold, blank;

public static void readImageList ( LineNumberReader bufferedImageList,
                                    int lineNumber) {
imageThreshhold = 0;
iter1 = null;
iter2 = null;
iter3 = null;

String image1 = null;
String image2 = null;
String image3 = null;



                try {


            bufferedImageList.setLineNumber(lineNumber);

            line = bufferedImageList.readLine();

		}	catch (Exception e) {

                System.err.println("image list not found");
                                                }





        if (line != null) {



        int index1 = line.indexOf("\t");
        int index2 = line.indexOf("\t",index1 + 1);
        int index3 = line.indexOf("\t",index2 + 1);


        image1 = line.substring(0,index1);

        image2 = line.substring(index1 + 1,index2);

        if (index3 == -1) {imageThreshhold = Integer.parseInt(line.substring(index2+1));};

        if (index3 != -1) {

        imageThreshhold = Integer.parseInt(line.substring(index2 + 1,index3));
        image3 = line.substring(index3 + 1);}

        try {

        iter1 = iterImage(image1);

		}	catch (Exception e) {

                iter1 = null;

                System.err.println("first image not found");
                                                }

	try {

        iter2 = iterImage(image2);

		}	catch (Exception e) {

                iter2 = null;


                System.err.println("second image not found");

						 }

        if (image3 != null) {	try {

        iter3 = iterImage(image3);

		}	catch (Exception e) {

                iter3 = null;

                System.err.println("a third image not used as mask");}

                                                  }
System.out.print("    Average distance for image "+image1+" ");                                          }


  if (line == null) {

              iter1 = null;
              iter2 = null;
              iter3 = null;

                              }

                }



// method for calculating r between two images (iter1 and iter2)
// the third binary image (iter 3)
// defines the total area of the cell to be included in the calculation of r



public static void distanceMoved ( RectIter iter1, RectIter iter2,
                                        RectIter iter3)      {

        int maxx, maxy, deltax, deltay, distanceInt;
        int count, x1, x2, x3, y1, y2, y3;
        int y=0;
        int x;
        int refpixel[][] = new int [1000][1000];
    	int dn1, dn2;
        int dn3 = maskThreshhold+1;
    	long signalSum=0;
    	double weightedDistance=0;
        double averageDistance=0;

//
// Read the reference image and build the x,y array
//
		iter1.startLines();
     		if (iter3 != null) {iter3.startLines();}
		blank=1;
 		do {            x=0;
 				iter1.startPixels();
      				if (iter3 != null) {iter3.startPixels();}

 				do {

                    dn1 = iter1.getSample();
                    refpixel[x][y] =0;
		    
                    if (iter3 != null) {dn3 = iter3.getSample();
                                        iter3.nextPixelDone();}
                    if (( dn3 > maskThreshhold ) && (dn1 > refThreshhold))
                         { refpixel [x][y] = 1;
			   blank=0;}
                    if (dn3 <= maskThreshhold) { refpixel[x][y] = -1;}
                                x++;

        			} while (! iter1.nextPixelDone() );
                          y++;
                          if (iter3 != null) {iter3.nextLineDone();}
          	} while (! iter1.nextLineDone());

               maxx=x;  // set the boundaries of the image
               maxy=y;
                x=0;
                y=0;
		iter2.startLines();

 		do {
 				iter2.startPixels();

 				do {

                    dn2 = (iter2.getSample() - imageThreshhold);
                    if (dn2<0) {dn2=0;}

                    if (( refpixel[x][y] != -1 ) && ( dn2 > testThreshhold ))
			
                    {

//***********************  try square counting methond *************************
int shortestDistance = 2000000000; // something big to start with
int i;
count = 1;
distanceInt = shortestDistance;

if (refpixel[x][y]==1) {shortestDistance=0;}
if (blank==1) {shortestDistance=0;}
do {
        i=0;
        do{

          x1= x-count+i;
          x2 = x-count;
          x3= x+count;
          y1= y-count +i;
          y2= y-count;
          y3 = y+count;


// ******************************* can't check outside of image *************
          if (y1<0) {y1=0;};
          if (y2<0) {y2=0;};
          if (y3<0) {y3=0;};
          if (x1<0) {x1=0;};
          if (x2<0) {x2=0;};
          if (x3<0) {x3=0;};

          if (y1>maxy) {y1=maxy;};
          if (y2>maxy) {y2=maxy;};
          if (y3>maxy) {y3=maxy;};
          if (x1>maxx) {x1=maxx;};
          if (x2>maxx) {x2=maxx;};
          if (x3>maxx) {x3=maxx;};



 //           ************ check top and bottom of search box*************

        if (refpixel[x1][y2]!=0)  {
                        deltax = x-x1;
                        deltay = y-y2;
                        distanceInt = (deltax*deltax) + (deltay*deltay);

          if (distanceInt < shortestDistance) { shortestDistance = distanceInt;}
                                  }

        if (refpixel[x1][y3]!=0) {
                        deltax = x-x1;
                        deltay = y-y3;
                        distanceInt = (deltax*deltax) + (deltay*deltay);
                        if (distanceInt < shortestDistance) { shortestDistance = distanceInt;}
                        }

  //            ******************* check sides of search box ************


        if ((refpixel[x2][y1] >0)) {
                        deltax = x-x2;
                        deltay = y-y1;
                        distanceInt = (deltax*deltax) + (deltay*deltay);
                        if (distanceInt < shortestDistance) { shortestDistance = distanceInt;}
                        }

        if (refpixel[x3][y1]>0) {
                        deltax = x-x3;
                        deltay = y-y1;
                        distanceInt = (deltax*deltax) + (deltay*deltay);
                        if (distanceInt < shortestDistance) { shortestDistance = distanceInt;}
                        }


        if (distanceInt < shortestDistance) { shortestDistance = distanceInt;}

           i++;
          } while ( (i<=(2*count)));

//    count is neccessary because the routine searches
//     in boxes rather than circles
//

            count++;
	    
	    //System.out.print(" x,y,count,iti,dn2 "+x+","+y+","+count+","+imageThreshhold
	    //+","+dn2);
           } while ( (shortestDistance == 2000000000)
           || ((count*count)<=shortestDistance ) );
// ----------------------------------------------------------------------------
          signalSum =signalSum + dn2;
          weightedDistance=weightedDistance + (Math.sqrt(shortestDistance))*dn2;

          }
                                  x++;
          			} while ((! iter2.nextPixelDone()));
                  y++;
                  x=0;
          	}

                while ((! iter2.nextLineDone()) );
		
                averageDistance=weightedDistance/signalSum;
                if (blank!=1) {System.out.println(averageDistance);}
		if (blank==1) {System.out.println("NaN");}

                        }

// method for reading the image into iterative form
public static RectIter iterImage(String file) {


// Read image into standard jai buffer

        PlanarImage loadImage = JAI.create("fileload", file);


 // Formate image from buffer into iterative form
 // (used for grabbing single pixel values)

        RectIter iter = RectIterFactory.create(loadImage, null);

 		return iter;
 				}



 /* Main starting method.
 	Comand line interface
 */

   public static void main(String[] args) throws IOException{

        String imageList = args[0];

        int lineNumber = 1;


        FileReader imageListRead = null;
        LineNumberReader bufferedImageList = null;

        imageListRead =  new FileReader(imageList);
        bufferedImageList = new LineNumberReader(imageListRead);


        do {



        readImageList(bufferedImageList, lineNumber);


        if (iter1 != null && iter2 != null){

                distanceMoved(iter1, iter2, iter3);


                              }

        lineNumber++;
                                  }

          while (line != null);

                                    }

                                 }



