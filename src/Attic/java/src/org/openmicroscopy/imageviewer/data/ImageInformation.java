/*
 * org.openmicroscopy.imageviewer.data.ImageInformation
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

import java.util.*;

import org.openmicroscopy.*;
import org.openmicroscopy.imageviewer.util.*;
import org.openmicroscopy.remote.*;

/**
 * Contains basic information about a 5D image, including number of Z levels,
 * number of timeframes, channels, bits per pixel, and color normalization
 * statistics.  (May rely too much on the OME::Remote factory methods, though.)
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class ImageInformation
{
  protected Image imageSource;
  protected ImagePixels pixels;
  protected Attribute pixelsAttribute;
  protected Factory dataSource;
  
  protected int sizeX;
  protected int sizeY;
  protected int sizeZ;
  protected int sizeC;
  protected int sizeT;
  protected int bitsPerPixel;
  
  protected StackStatistics[][] stackStats;
  protected Wavelength[] channelInfo;
  
  protected ChannelBlackScaleData CBS;
  
  protected Map cbsMap;
  
  /**
   * Constructs an image information class based on the 5D image source, and the
   * individual set of pixels desired in that image.  Needs Factory to query
   * the database about statistics.  (this might not be a good thing)
   * 
   * @param imageSource The image to store information about.
   * @param pixels The pixel source of the image.
   * @param dataSource The factory used to access the OME database.  Is there
   *                   a better way to do this?
   */
  public ImageInformation(Image imageSource,
                          ImagePixels pixels,
                          Factory dataSource)
  {
    this.imageSource = imageSource;
    this.pixels = pixels;
    this.pixelsAttribute = pixels.getPixelsAttribute();
    this.dataSource = dataSource;
    
    Map imageSourceMap = new HashMap();
    imageSourceMap.put("target",imageSource);
    
    // extract the channel/wavelength information for this image.
    List channelComponents = dataSource.findAttributes("PixelChannelComponent",
                                                       imageSourceMap);
                                                       
    final int pixelsID = pixelsAttribute.getID();
    
    // this taken straight out of the SVG viewer code
    // might be a faster/better/less OME-call-intensive way to do it
    channelComponents = Filter.grep(channelComponents,new GrepOperator() {
      public boolean eval(Object o)
      {
        Attribute attribute = (Attribute)o;
        Attribute pixels = attribute.getAttributeElement("Pixels");
        return pixels.getID() == pixelsID;
      }
    });
    
    channelInfo = new Wavelength[channelComponents.size()];
    for(int i = 0; i < channelComponents.size(); i++)
    {
      Attribute channel = (Attribute)channelComponents.get(i);
      channelInfo[i] = new Wavelength(channel.getIntElement("Index"));
    }
    
    CBS = ChannelBlackScaleData.getDefaultChannelScale(channelInfo);
    cbsMap = new HashMap();
    
    // hopefully this doesn't break right here
    
    
    // extract the proper stack statistics for this image,
    // this might be done the hard way (I dunno)
    
    Map moduleConstraints = new HashMap();
    moduleConstraints.put("name","Stack statistics");
    
    Module stackModule = (Module)dataSource.findObject("OME::Module",
                                                       moduleConstraints);
    
    Map formalInputConstraints = new HashMap();
    formalInputConstraints.put("module_id",new Integer(stackModule.getID()));
    formalInputConstraints.put("name","Pixels");
    
    Module.FormalInput formalInput =
      (Module.FormalInput)dataSource.findObject("OME::Module::FormalInput",
                                                formalInputConstraints);
                                                
    RemoteModuleExecution moduleExecution =
      (RemoteModuleExecution)pixelsAttribute.getModuleExecution();
    
    Map actualInputConstraints = new HashMap();
    actualInputConstraints.put("formal_input_id",new Integer(formalInput.getID()));
    actualInputConstraints.put("input_module_execution_id",
                               new Integer(moduleExecution.getID()));
                               
    ModuleExecution.ActualInput actualInput =
      (ModuleExecution.ActualInput)dataSource.findObject("OME::ModuleExecution::ActualInput",
                                                         actualInputConstraints);
                            
    final int stackAnalysisID = actualInput.getModuleExecution().getID();
    
    // retrieve statistics
    List stackMins = dataSource.findAttributes("StackMinimum",imageSourceMap);
    List stackMaxes = dataSource.findAttributes("StackMaximum",imageSourceMap);
    List stackMeans = dataSource.findAttributes("StackMean",imageSourceMap);
    List stackSigmas = dataSource.findAttributes("StackSigma",imageSourceMap);
    List stackGeomeans = dataSource.findAttributes("StackGeometricMean",imageSourceMap);
    List stackGeosigmas = dataSource.findAttributes("StackGeometricSigma",imageSourceMap);
    
    GrepOperator stackIDOperator = new GrepOperator() {
      public boolean eval(Object o)
      {
        Attribute attribute = (Attribute)o;
        RemoteModuleExecution execution =
          (RemoteModuleExecution)attribute.getModuleExecution();
        if(execution.getID() == stackAnalysisID)
        {
          return true;
        }
        else return false;
      }
    };
    
    List usableMins = Filter.grep(stackMins,stackIDOperator);
    List usableMaxes = Filter.grep(stackMaxes,stackIDOperator);
    List usableMeans = Filter.grep(stackMeans,stackIDOperator);
    List usableSigmas = Filter.grep(stackSigmas,stackIDOperator);
    List usableGeomeans = Filter.grep(stackGeomeans,stackIDOperator);
    List usableGeosigmas = Filter.grep(stackGeosigmas,stackIDOperator);
    
    sizeX = pixelsAttribute.getIntElement("SizeX");
    sizeY = pixelsAttribute.getIntElement("SizeY");
    sizeZ = pixelsAttribute.getIntElement("SizeZ");
    sizeC = pixelsAttribute.getIntElement("SizeC");
    sizeT = pixelsAttribute.getIntElement("SizeT");
    bitsPerPixel = pixelsAttribute.getIntElement("BitsPerPixel");
    
    stackStats = new StackStatistics[sizeC][sizeT];
    
    // initialize array
    for(int i=0;i<sizeC;i++)
    {
      for(int j=0;j<sizeT;j++)
      {
        stackStats[i][j] = new StackStatistics();
      }
    }
    
    // populate internal data structures
    for(Iterator iter = usableMins.iterator(); iter.hasNext();)
    {
      Attribute stackMin = (Attribute)iter.next();
      int theC = stackMin.getIntElement("TheC");
      int theT = stackMin.getIntElement("TheT");
      stackStats[theC][theT].setMin(stackMin.getIntElement("Minimum"));
    }
    
    for(Iterator iter = usableMaxes.iterator(); iter.hasNext();)
    {
      Attribute stackMax = (Attribute)iter.next();
      int theC = stackMax.getIntElement("TheC");
      int theT = stackMax.getIntElement("TheT");
      stackStats[theC][theT].setMax(stackMax.getIntElement("Maximum"));
    }
    
    for(Iterator iter = usableMeans.iterator(); iter.hasNext();)
    {
      Attribute stackMean = (Attribute)iter.next();
      int theC = stackMean.getIntElement("TheC");
      int theT = stackMean.getIntElement("TheT");
      stackStats[theC][theT].setMean(stackMean.getFloatElement("Mean"));
    }
    
    for(Iterator iter = usableSigmas.iterator(); iter.hasNext();)
    {
      Attribute stackSigma = (Attribute)iter.next();
      int theC = stackSigma.getIntElement("TheC");
      int theT = stackSigma.getIntElement("TheT");
      stackStats[theC][theT].setSigma(stackSigma.getFloatElement("Sigma"));
    }
    
    for(Iterator iter = usableGeomeans.iterator(); iter.hasNext();)
    {
      Attribute stackMean = (Attribute)iter.next();
      int theC = stackMean.getIntElement("TheC");
      int theT = stackMean.getIntElement("TheT");
      stackStats[theC][theT].setGeoMean(stackMean.getFloatElement("GeometricMean"));
    }
    
    for(Iterator iter = usableGeosigmas.iterator(); iter.hasNext();)
    {
      Attribute stackSigma = (Attribute)iter.next();
      int theC = stackSigma.getIntElement("TheC");
      int theT = stackSigma.getIntElement("TheT");
      stackStats[theC][theT].setGeoSigma(stackSigma.getFloatElement("GeometricSigma"));
    }
  }
  
  /**
   * Get the width (extent) of the image in pixels.
   * 
   * @return The image width.
   */
  public int getDimX()
  {
    return sizeX;
  }
  
  /**
   * Get the height of the image in pixels.
   * @return The image height.
   */
  public int getDimY()
  {
    return sizeY;
  }
  
  /**
   * Get the depth of the image in levels.
   * @return The image depth.
   */
  public int getDimZ()
  {
    return sizeZ;
  }
  
  /**
   * Get the number of channels encapsulated in the image.
   * @return The number of channels
   */
  public int getDimC()
  {
    return sizeC;
  }
  
  /**
   * Get the number of time frames in the image.
   * @return The number of frames.
   */
  public int getDimT()
  {
    return sizeT;
  }
  
  /**
   * Get the number of bits per pixel (grayscale, unchanged by conversion)
   * @return The number of bits per pixel.
   */
  public int getBitsPerPixel()
  {
    return bitsPerPixel;
  }
  
  /**
   * Gets the stack minimum value of the specified XYZ slice.
   * 
   * @param c The desired channel.
   * @param t The desired timeframe.
   * @return The stack minimum.
   */
  public int getStackMin(int c, int t)
  {
    return stackStats[c][t].getMin();
  }
  
  /**
   * Gets the stack maximum value of the specified XYZ slice.
   * 
   * @param c The desired channel.
   * @param t The desired timeframe.
   * @return The stack maximum.
   */
  public int getStackMax(int c, int t)
  {
    return stackStats[c][t].getMax();
  }
  
  /**
   * Gets the stack arithmetic mean brightness value of the specified XYZ slice.
   * 
   * @param c The desired channel.
   * @param t The desired timeframe.
   * @return The stack mean.
   */
  public float getStackMean(int c, int t)
  {
    return stackStats[c][t].getMean();
  }
  
  /**
   * Gets the stack arithmetic brightness sigma value of the specified XYZ slice.
   * 
   * @param c The desired channel.
   * @param t The desired timeframe.
   * @return The stack sigma.
   */
  public float getStackSigma(int c, int t)
  {
    return stackStats[c][t].getSigma(); 
  }
  
  /**
   * Gets the stack geometric mean brightness value of the specified XYZ slice.
   * 
   * @param c The desired channel.
   * @param t The desired timeframe.
   * @return The stack geomean.
   */
  public float getStackGeoMean(int c, int t)
  {
    return stackStats[c][t].getGeoMean();
  }
  
  /**
   * Gets the stack geometric brightness sigma of the specified XYZ slice.
   * 
   * @param c The desired channel.
   * @param t The desired timeframe.
   * @return The stack geometric sigma.
   */
  public float getStackGeoSigma(int c, int t)
  {
    return stackStats[c][t].getGeoSigma();
  }
  
  /**
   * Gets the number of logical channels.
   * @return The number of channels.
   */
  public int numChannels()
  {
    return channelInfo.length;
  }
  
  /**
   * Gets the wavelength information associated with the specified channel.
   * @param i The channel to analyze.
   * @return Wavelength information for that channel.
   */
  public Wavelength getChannelInfo(int i)
  {
    return channelInfo[i];
  }
  
  // analogous to getConvertedWBS4OME_JPEG in OMEimage.js
  // and boundary conditions modifier in updatePic in OMEimage.js
  public ChannelBlackScaleData getNormalizedScale(int t)
  {
    if(t < 0 || t >= getDimT())
    {
      return null;
    }
    
    Integer tObj = new Integer(t);
    if(cbsMap.containsKey(tObj))
    {
      return (ChannelBlackScaleData)cbsMap.get(tObj);
    }
    
    ChannelBlackScaleData convertedData = new ChannelBlackScaleData();
    
    ChannelBlackScaleData.CBSChunk[] dataChunks =
      {CBS.getCBSChunk(ChannelBlackScaleData.RED_CHUNK),
       CBS.getCBSChunk(ChannelBlackScaleData.GREEN_CHUNK),
       CBS.getCBSChunk(ChannelBlackScaleData.BLUE_CHUNK),
       CBS.getCBSChunk(ChannelBlackScaleData.GRAY_CHUNK)};
       
    ChannelBlackScaleData.CBSChunk[] newChunks =
      new ChannelBlackScaleData.CBSChunk[dataChunks.length];
    
    for(int i=0;i<dataChunks.length;i++)
    {
      ChannelBlackScaleData.CBSChunk chunk = dataChunks[i];
      int channel = chunk.getChannel();
      int blackLevel = chunk.getBlackLevel();
      float scale = chunk.getScale();
      
      float newBlack = getStackGeoMean(channel,t) +
                       getStackGeoSigma(channel,t) * blackLevel;
      
      float scaleMod = scale == 0f ? 0.00001f : scale;
      float newScale = 255f / (getStackGeoSigma(channel,t) * scaleMod);
      
      int newB = Math.round(newBlack);
      float newS = Math.round(newScale*100000f)/100000f;
      
      // black-level overcorrection adjustment
      if(newB < getStackMin(channel,t))
      {
        newB = Math.round((float)Math.ceil(getStackMin(channel,t)));
      }
      
      if(newB > getStackMax(channel,t))
      {
        newB = Math.round((float)Math.floor(getStackMax(channel,t)));
      }
      // end black-level overcorrection adjustment
      
      // white-level overcorrection adjustment
      float whiteLevel = getStackGeoMean(channel,t)
                       + dataChunks[i].getScale() * getStackGeoSigma(channel,t);
      boolean recalculate = false;
      
      if(whiteLevel < getStackMin(channel,t))
      {
        whiteLevel = getStackMin(channel,t);
        recalculate = true;
      }
      if(whiteLevel > getStackMax(channel,t))
      {
        whiteLevel = getStackMax(channel,t);
        recalculate = true;
      }
      
      if(recalculate)
      {
        if(whiteLevel - getStackGeoMean(channel,t) == 0f)
        {
          whiteLevel += 0.00001f;
        }
        newS = 255f / (whiteLevel - getStackGeoMean(channel,t));
      }
      // end white-level correction adjustment
      
      newChunks[i] = new ChannelBlackScaleData.CBSChunk(channel,newB,newS);
    }
    
    convertedData.setCBSChunk(ChannelBlackScaleData.RED_CHUNK,
                              newChunks[0]);
    convertedData.setCBSChunk(ChannelBlackScaleData.GREEN_CHUNK,
                              newChunks[1]);
    convertedData.setCBSChunk(ChannelBlackScaleData.BLUE_CHUNK,
                              newChunks[2]);
    convertedData.setCBSChunk(ChannelBlackScaleData.RED_CHUNK,
                              newChunks[3]);
    
    cbsMap.put(tObj,convertedData);  
    return convertedData;
  }
}
