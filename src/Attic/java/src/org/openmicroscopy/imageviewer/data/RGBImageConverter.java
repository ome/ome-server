/*
 * org.openmicroscopy.imageviewer.data.RGBImageConverter
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */




/*------------------------------------------------------------------------------
 *
 * Written by:    Jeff Mellen <jeffm@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */
package org.openmicroscopy.imageviewer.data;

import java.awt.GraphicsConfiguration;
import java.awt.GraphicsDevice;
import java.awt.GraphicsEnvironment;
import java.awt.image.BufferedImage;
import java.awt.image.WritableRaster;
import java.io.IOException;

import org.openmicroscopy.*;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class RGBImageConverter
{
  protected ImagePixels pixels;
  protected ImageInformation info;
  protected GraphicsConfiguration config;
  
  public RGBImageConverter(ImagePixels pixels,
                           ImageInformation info)
    throws IllegalArgumentException
  {
    if(pixels == null || info == null)
    {
      throw new IllegalArgumentException("Null parameters passed to " +
                                         "RGBImageConverter constructor.");
    }
    this.pixels = pixels;
    this.info = info;
    
    GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
    GraphicsDevice gd = ge.getDefaultScreenDevice();
    config = gd.getDefaultConfiguration();
    System.err.println(config.toString());
    System.err.println(config.getColorModel().toString());
  }
  
  public BufferedImage runColorFilter(BufferedImage image,
                                      boolean rOn, boolean gOn, boolean bOn)
  {
    if(image == null)
    {
      return null;
    }
    int width = image.getWidth();
    int height = image.getHeight();
    
    BufferedImage newImage = new BufferedImage(width,height,
                                               BufferedImage.TYPE_INT_RGB);
    
    int[] oldPixels = image.getRGB(0,0,width,height,null,0,height);
    int[] newPixels = new int[width*height];
    System.err.println("color filter begin");
    for(int y = 0; y < height; y++)
    {
      for(int x = 0; x < width; x++)
      {
        int oRGB = oldPixels[y*height+x];
        int nAlpha = (oRGB >> 24) & 0xff;
        int nRed = rOn ? (oRGB >> 16) & 0xff : 0;
        int nGreen = gOn ? (oRGB >> 8) & 0xff : 0;
        int nBlue = bOn ? oRGB & 0xff : 0;
        int nRGB = (nAlpha << 24) | (nRed << 16) | (nGreen << 8) | nBlue;
        newPixels[y*height+x] = nRGB;
      }
    }
    System.err.println("color filter end");
    newImage.setRGB(0,0,width,height,newPixels,0,height);
    return newImage;
  }
  
  public BufferedImage getRGBImage(int z, int cRed,
                                   int cGreen, int cBlue, int t,
                                   boolean rOn, boolean gOn, boolean bOn)
    throws IOException
  {
    System.err.println("getRGBImage start");
    if(pixels == null || info == null)
    {
      return null;
    }
    if(!verifyParameters(info,z,cRed,cGreen,cBlue,t))
    {
      return null;
    }
    
    byte[] redPlane = pixels.getPlane(z,cRed,t);
    byte[] greenPlane = pixels.getPlane(z,cGreen,t);
    byte[] bluePlane = pixels.getPlane(z,cBlue,t);
    int bpp = info.getBitsPerPixel() / 8;
    
    ChannelBlackScaleData normalizer = info.getNormalizedScale(t);
    ChannelBlackScaleData.CBSChunk redChunk =
      normalizer.getCBSChunk(ChannelBlackScaleData.RED_CHUNK);
    ChannelBlackScaleData.CBSChunk greenChunk =
      normalizer.getCBSChunk(ChannelBlackScaleData.GREEN_CHUNK);
    ChannelBlackScaleData.CBSChunk blueChunk =
      normalizer.getCBSChunk(ChannelBlackScaleData.BLUE_CHUNK);
      
    int redBlack = redChunk.getBlackLevel();
    float redScale = rOn ? redChunk.getScale() : 0;
    int greenBlack = greenChunk.getBlackLevel();
    float greenScale = gOn ? greenChunk.getScale() : 0;
    int blueBlack = blueChunk.getBlackLevel();
    float blueScale = bOn ? blueChunk.getScale() : 0;
    
    int normRedScale = Math.round(256f*redScale);
    int normGreenScale = Math.round(256f*greenScale);
    int normBlueScale = Math.round(256f*blueScale);
    System.err.println("normRedScale="+normRedScale);
    System.err.println("normGreenScale="+normGreenScale);
    System.err.println("normBlueScale="+normBlueScale);
    
    int byteSize = redPlane.length;
    if(greenPlane.length != byteSize ||
       bluePlane.length != byteSize)
    {
      throw new RuntimeException("Serious Error: channel planes not same size");
    }
    
    int byteMarker = 0;
    int width = info.getDimX();
    int height = info.getDimY();
    int numPixels = width*height;
    
    BufferedImage rgbImage = new BufferedImage(width,height,
                                               BufferedImage.TYPE_INT_RGB);
    
    System.err.println("RGB image plane conversion begin");
    int[] rgbPixels = new int[numPixels*3];
    int pixelMarker = 0;
    WritableRaster raster = rgbImage.getRaster();
    if(bpp == 1)
    {
      for(int y = 0; y < height; y++)
      {
        for(int x = 0; x < width; x++)
        {
          int redVal = redPlane[byteMarker] & 0xff;
          int greenVal = greenPlane[byteMarker] & 0xff;
          int blueVal = bluePlane[byteMarker] & 0xff;
          
          redVal -= redBlack;
          if(redVal < 0) redVal = 0;
          else
          {
            redVal *= normRedScale;
            redVal = (redVal >> 8) & 0xff;
          }
          
          greenVal -= greenBlack;
          if(greenVal < 0) greenVal = 0;
          /*
          greenVal = Math.round(greenVal*greenScale);
          if(greenVal > 255) greenVal = 255;
          */
          else
          {
            greenVal *= normGreenScale;
            greenVal = (greenVal >> 8) & 0xff;
          }
          
          blueVal -= blueBlack;
          if(blueVal < 0) blueVal = 0;
          /*
          blueVal = Math.round(blueVal*blueScale);
          if(blueVal > 255) blueVal = 255;
          */
          else
          {
            blueVal *= normBlueScale;
            blueVal = (blueVal >> 8) & 0xff;
          }
          
          rgbPixels[pixelMarker++] = redVal;
          rgbPixels[pixelMarker++] = greenVal;
          rgbPixels[pixelMarker++] = blueVal;
          byteMarker++;
        }
      }
    }
    else if(bpp == 2)
    {
      for(int y = 0; y < height; y++)
      {
        for(int x = 0; x < width; x++)
        {
          int redVal = (redPlane[byteMarker] & 0xff) << 8 |
                       (redPlane[byteMarker+1] & 0xff);
          int greenVal = (greenPlane[byteMarker] & 0xff) << 8 |
                         (greenPlane[byteMarker+1] & 0xff);
          int blueVal = (bluePlane[byteMarker] & 0xff) << 8 |
                        (bluePlane[byteMarker+1] & 0xff);
          
          redVal -= redBlack;
          if(redVal < 0) redVal = 0;
          else
          {
            redVal *= normRedScale;
            // shifted criteria (1024 << 8)
            if(redVal > 65280)
            {
              redVal = 65280;
            }
            redVal = (redVal >> 8) & 0xff;
          }

          greenVal -= greenBlack;
          if(greenVal < 0) greenVal = 0;
          else
          {
            greenVal *= normGreenScale;
            // shifted criteria (255 << 8)
            if(greenVal > 65280)
            {
              greenVal = 65280;
            }
            greenVal = (greenVal >> 8) & 0xff;
          }

          blueVal -= blueBlack;
          if(blueVal < 0) blueVal = 0;
          else
          {
            blueVal *= normBlueScale;
            // shifted criteria (255 << 8)
            if(blueVal > 65280)
            {
              blueVal = 65280;
            }
            blueVal = (blueVal >> 8) & 0xff;
          }
          
          rgbPixels[pixelMarker++] = redVal;
          rgbPixels[pixelMarker++] = greenVal;
          rgbPixels[pixelMarker++] = blueVal;
          byteMarker+=2;
        }
      }
    }
    
    raster.setPixels(0,0,width,height,rgbPixels);
    return rgbImage;
  }
  
  private boolean verifyParameters(ImageInformation info,
                                   int z, int cRed, int cGreen,
                                   int cBlue, int t)
  {
    if(z < 0 || z >= info.getDimZ() ||
       cRed < 0 || cRed >= info.getDimC() ||
       cGreen < 0 || cGreen >= info.getDimC() ||
       cBlue < 0 || cBlue >= info.getDimC() ||
       t < 0 || t >= info.getDimT())
    {
      return false;
    }
    else return true;
  }
}
