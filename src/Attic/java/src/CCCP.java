/*

	CCCP Correlation Coefficient of Cellular Position
	Brian S. DeDecker
	version 0.6

*/


import javax.media.jai.*;
import javax.media.jai.iterator.*;
import com.sun.media.jai.codec.*;
import java.io.*;
import java.awt.image.renderable.ParameterBlock;


public class CCCP  {


static double average1 = 0;
static double average2 = 0;
static double cccp = 0;
static RectIter iter1 = null;
static RectIter iter2 = null;
static RectIter iter3 = null;
static String line = null;





public static void readImageList ( LineNumberReader bufferedImageList,
                                    int lineNumber) {

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

        image1 = line.substring(0,index1);

        if (index2 != -1) {

        image2 = line.substring(index1 + 1,index2);

        image3 = line.substring(index2 + 1);}


        if (index2 == -1) {

        image2 = line.substring(index1 + 1);

        }


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
                                                  }


  if (line == null) {

              iter1 = null;
              iter2 = null;
              iter3 = null;

                              }

                }



// method for calculating r between two images (iter1 and iter2)
// the third binary image (iter 3)
// defines the total area of the cell to be included in the calculation of r



public static void correlationMasked ( RectIter iter1, RectIter iter2,
                                        RectIter iter3)      {

        long pixelCount = 0;
    	long pixelSum12 = 0;
    	long pixelSum1 = 0;
        long pixelSum2 = 0;
    	long pixelSum11 = 0;
    	long pixelSum22 = 0;
    	long dn1, dn2;
        long dn3 = 1;
    	long corrNum;
    	double corrDenom;
    	double corr;

		iter1.startLines();
		iter2.startLines();
  		if (iter3 != null) {iter3.startLines();}

 		do {
 				iter1.startPixels();
 				iter2.startPixels();
      				if (iter3 != null) {iter3.startPixels();}

 				do {

                    dn1 = iter1.getSample();
                    dn2 = iter2.getSample();
                    if (iter3 != null) {dn3 = iter3.getSample();}

                    if ( dn3 != 0 ) {

                  	        pixelSum12 += dn1 * dn2;
        			pixelSum1 += dn1;
        			pixelSum2 += dn2;
        			pixelSum11 += dn1 * dn1;
        			pixelSum22 += dn2 * dn2;
          			pixelCount++;

          					}

          			} while ((! iter1.nextPixelDone()) &&
                                          (! iter2.nextPixelDone()) );

          	} while ((! iter1.nextLineDone()) &&
                        (! iter2.nextLineDone()) );


         average1 = (double)pixelSum1 / (double)pixelCount;

         average2 =  (double)pixelSum2 / (double)pixelCount;

         corrNum = ((pixelCount * pixelSum12) - (pixelSum1 * pixelSum2));

         corrDenom = Math.sqrt ((((double)pixelCount * (double)pixelSum11) -
         			((double)pixelSum1 * (double)pixelSum1)) *
        			(((double)pixelCount * (double)pixelSum22) -
        			((double)pixelSum2 * (double)pixelSum2)));

         cccp = (double)corrNum / corrDenom;


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

                correlationMasked(iter1, iter2, iter3);

                System.out.println(cccp);

                              }

        lineNumber++;
                                  }

          while (line != null);

                                    }

                                 }



