/*
 * org.openmicroscopy.imageviewer.ImageCache
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
package org.openmicroscopy.imageviewer;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.lang.ref.SoftReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.imageio.ImageIO;

/**
 * A two-tiered caching system for images in the image viewer.  Images are
 * immediately stored to disk and then the most recent images are also stored
 * in memory, so that they may be accessed more rapidly.  The memory cache
 * uses soft references for cache management... when an OutOfMemoryError will
 * occur is not defined, but this should work *mostly* around it.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $ Revision: $ $ Date: $
 */
public class ImageCache
{
  private ImageDiskCache diskCache;
  private ImageMemoryCache memoryCache;
  
  private final int DEFAULT_MEMORY_STRATEGY = ImageMemoryCache.STRATEGY_LRU;
  
  private static ImageCache cache;
  
  /**
   * The image is in memory.
   */
  public static final int IN_MEMORY = 1;
  
  /**
   * The image is on disk.
   */
  public static final int WRITTEN_TO_DISK = 2;
  
  /**
   * The image is being written to disk (hard state to reach with UI)
   */
  public static final int WRITING_TO_DISK = 3;
  
  /**
   * The image is not yet in the cache.
   */
  public static final int NOT_STORED = 0;
  
  // change model: go with defaults, then maybe have runtime change
  // defaults: use 85% available memory, LRU strategy
  
  private ImageCache()
  {
    diskCache = new ImageDiskCache();
    memoryCache = new ImageMemoryCache(DEFAULT_MEMORY_STRATEGY);        
  }
  
  public static ImageCache getInstance()
  {
    if(cache == null)
    {
      cache = new ImageCache();
    }
    return cache;
  }
  
  public int getImageStatus(String imageName, int pixelsID, int z, int t,
                            int cRed, int cGreen, int cBlue,
                            boolean rOn, boolean gOn, boolean bOn)
  {
    ParameterGroup pg = new ParameterGroup(imageName,pixelsID,z,t,cRed,cGreen,
                                          cBlue,rOn,gOn,bOn);
                                          
    if(memoryCache.isInCache(pg))
    {
      return IN_MEMORY;
    }
    else
    {
      switch(diskCache.getImageStatus(pg))
      {
        case ImageDiskCache.STORING: return WRITING_TO_DISK;
        case ImageDiskCache.STORED: return WRITTEN_TO_DISK;
        case ImageDiskCache.NOT_STORED: return NOT_STORED;
        default: return NOT_STORED;
      }
    }
  }
  
  public BufferedImage load(String imageName, int pixelsID, int z, int t,
                            int cRed, int cGreen, int cBlue,
                            boolean rOn, boolean gOn, boolean bOn)
    throws IOException
  {
    ParameterGroup pg = new ParameterGroup(imageName, pixelsID, z, t,
                                           cRed,cGreen,cBlue,
                                           rOn,gOn,bOn);
    if(memoryCache.isInCache(pg))
    {
      return memoryCache.load(pg);
    }
    else if(diskCache.getImageStatus(pg) == ImageDiskCache.STORED)
    {
      // block-read from disk
      BufferedImage image = diskCache.load(pg);
      // store this in memory
      memoryCache.store(image,pg);
      return image;
    }
    // this would be *real* hard to reach... just calls back after it got
    // flushed... danger of race condition (storing & loading)-- wait until
    // stored, then call it back-- if it's looping on this edge, though,
    // should probably notify user the worst-case scenario is happening.
    else if(diskCache.getImageStatus(pg) == ImageDiskCache.STORING)
    {
      System.err.println("Please wait: worst-case cache scenario in progress.");
      boolean stored = false;
      BufferedImage image = null;
      while(!stored)
      {
        if(diskCache.getImageStatus(pg) == ImageDiskCache.STORED)
        {
          image = diskCache.load(pg);
          stored = true;
        }
        else
        {
          try
          {
            Thread.sleep(200);
          }
          catch(InterruptedException ie)
          {
            // I dunno
          }
        }
      }
      memoryCache.store(image,pg);
      return image;
    }
    // not in the cache, chief
    else return null;
  }
  
  public void store(BufferedImage image, String imageName, int pixelsID,
                    int z, int t, int cRed, int cGreen, int cBlue,
                    boolean rOn, boolean gOn, boolean bOn)
    throws IOException
  {
    if(image == null)
    {
      return;
    }
    ParameterGroup pg = new ParameterGroup(imageName,pixelsID,z,t,cRed,
                                           cGreen,cBlue,rOn,gOn,bOn);
    
    memoryCache.store(image,pg);
    diskCache.store(image,pg); // write to disk immediately in case of mem error.
  }
  
  /**
   * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
   * @version $ Revision: $ $ Date: $
   */
  private class ImageDiskCache
  {
    private Set imageSliceSet;
    private Map statusMap;
  
    public static final int ERROR = -1;
    public static final int NOT_STORED = 0;
    public static final int STORING = 1;
    public static final int STORED = 2;
  
    public static final String JPEG = "jpg";
  
    ImageDiskCache()
    {
      imageSliceSet = new HashSet();
      statusMap = new HashMap();
      // possibly load if already on disk
    }
  
    public int getImageStatus(ParameterGroup pg)
    {
      if(pg == null)
      {
        return ERROR;
      }
      String fileName = nameFile(pg.getImageName(),
                                 pg.getPixelsID(),
                                 pg.getZ(),
                                 pg.getT(),
                                 pg.getCRed(),
                                 pg.getCGreen(),
                                 pg.getCBlue(),JPEG);
                               
      if(!imageSliceSet.contains(fileName))
      {
        return NOT_STORED;
      }
      else
      {
        int status = ((Integer)statusMap.get(fileName)).intValue();
        return status;
      }
    }
  
    public BufferedImage load(ParameterGroup pg)
      throws IOException
    {
      if(pg == null)
      {
        return null;
      }
      String fileName = nameFile(pg.getImageName(),
                                 pg.getPixelsID(),
                                 pg.getZ(),
                                 pg.getT(),
                                 pg.getCRed(),
                                 pg.getCGreen(),
                                 pg.getCBlue(),JPEG);
                                           
      if(getImageStatus(pg) == STORED)
      {
        return ImageIO.read(new File(fileName));
      }
      else
      {
        return null;
      }
    }
  
    public void store(BufferedImage image, ParameterGroup pg)
      throws IOException
    {
      if(pg == null)
      {
        return;
      }
    
      String fileName = nameFile(pg.getImageName(),
                                 pg.getPixelsID(),
                                 pg.getZ(),
                                 pg.getT(),
                                 pg.getCRed(),
                                 pg.getCGreen(),
                                 pg.getCBlue(),JPEG);
                                 
      File file = new File(fileName);
      // destroy when program terminates
      file.deleteOnExit();
      imageSliceSet.add(fileName);
      statusMap.put(fileName,new Integer(NOT_STORED));
      new ImageCacheThread(this,image,"jpg",file).start();
    }
  
    private void updateStatus(String fileName, int status)
    {
      statusMap.put(fileName,new Integer(status));
    }
  
    private String nameFile(String imageName, int pixelsID,
                            int z, int t, int cRed, int cGreen,
                            int cBlue, String fileType)
    {
      StringBuffer buffer = new StringBuffer();
      buffer.append("omeview");
      buffer.append("-");
      buffer.append(imageName);
      buffer.append("-");
      buffer.append(pixelsID);
      buffer.append("-z");
      buffer.append(z);
      buffer.append("-t");
      buffer.append(t);
      if(cRed != ParameterGroup.CHANNEL_OFF)
      {
        buffer.append("-cr");
        buffer.append(cRed);
      }
      if(cGreen != ParameterGroup.CHANNEL_OFF)
      {
        buffer.append("-cg");
        buffer.append(cGreen);
      }
      if(cBlue != ParameterGroup.CHANNEL_OFF)
      {
        buffer.append("-cb");
        buffer.append(cBlue);
      }
      buffer.append(".");
      buffer.append(fileType);
      return buffer.toString();
    }
  }
  
  /**
   * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
   * @version $ Revision: $ $ Date: $
   */
  private class ImageCacheThread extends Thread
  {
    private ImageDiskCache callback;
    private BufferedImage imageToSave;
    private String fileType;
    private File fileTarget;

    public ImageCacheThread(ImageDiskCache callback,
                            BufferedImage imageToSave,
                            String fileType,
                            File fileTarget)
    {
      this.imageToSave = imageToSave;
      this.fileType = fileType;
      this.fileTarget = fileTarget;
      this.callback = callback;
    }
  
    public void start()
    {
      callback.updateStatus(fileTarget.getName(),
                            ImageDiskCache.STORING);
      super.start();
    }
    /* (non-Javadoc)
     * @see java.lang.Runnable#run()
     */
    public void run()
    {
      try
      {
        ImageIO.write(imageToSave,fileType,fileTarget);
        callback.updateStatus(fileTarget.getName(),
                              ImageDiskCache.STORED);
      }
      catch(IOException e)
      {
        System.err.println("critical error: could not write cache to disk");
      }

    }
  }
  
  /**
   * A simple hash to store a series of images for fast display/iteration
   * (works well for movies)  Cache management works through soft references.
   * 
   * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
   * @version $ Revision: $ $ Date: $
   */
  private class ImageMemoryCache
  {
    public static final int IN_MEMORY = 1;
    public static final int NOT_IN_MEMORY = 0;
  
    public static final int STRATEGY_LRU = 0;
    public static final int STRATEGY_FIFO = 1;
  
    public long approximateMemoryUsage = 0;
  
    private int strategy;
  
    private List cacheList;
    private Map cacheMap;
  
    ImageMemoryCache(int strategy)
      throws IllegalArgumentException
    {
      if(!isValidStrategy(strategy))
      {
        throw new IllegalArgumentException("Invalid strategy.");
      }
      this.strategy = strategy;
      this.cacheList = new ArrayList();
      this.cacheMap = new HashMap();
    }
  
    public int getStrategy()
    {
      return strategy;
    }
  
    public void setStrategy(int strategy)
    {
      if(isValidStrategy(strategy))
      {
        this.strategy = strategy;
      }
    }
  
    private boolean isValidStrategy(int strategy)
    {
      if(strategy == STRATEGY_FIFO ||
         strategy == STRATEGY_LRU)
      {
        return true;
      }
      else return false;
    }
  
    public boolean isInCache(ParameterGroup pg)
    {
      if(pg == null)
      {
        return false;
      }
      
      // now must be more sophisticated, with soft references
      if(cacheList.contains(pg))
      {
        SoftReference ref = (SoftReference)cacheMap.get(pg);
        // do cleanup if referent garbage collected
        if(ref == null || ref.get() == null)
        {
          cacheList.remove(pg);
          cacheMap.remove(pg);
          return false;
        }
        else return true;
      }
      else return false;
    }
  
    public BufferedImage load(ParameterGroup pg)
    {
      if(pg == null)
      {
        return null;
      }
      
      // inherit cleaning/soft-reference checking of isInCache
      if(!isInCache(pg))
      {
        return null;
      }
      else
      {
        // synchronization to prevent null if problematic
        // might not be necessary, but I don't think it'll deadlock
        // (famous last words)
        synchronized(cacheMap)
        {
          // LRU update
          if(this.strategy == STRATEGY_LRU)
          {
            cacheList.remove(pg);
            cacheList.add(0,pg);
          }
          SoftReference ref = (SoftReference)cacheMap.get(pg);
          return (BufferedImage)ref.get();
        }
      }
    }
  
    /**
     * Rewrite this.
     * 
     * @param image
     * @param pg
     * @return
     */
    public void store(BufferedImage image, ParameterGroup pg)
      throws IOException
    {
      if(image == null || pg == null)
      {
        return;
      }
      
      cacheList.add(0,pg); // LRU/FIFO scheme
      cacheMap.put(pg,new SoftReference(image));
    }
    
    private void remove(ParameterGroup pg)
    {
      cacheList.remove(pg);
      cacheMap.remove(pg);
    }
  }
  
  //  leaving this in for legacy purposes-- may be useful in memory cache
  private class ParameterGroup
  {
    private String imageName;
    private int pixelsID;
    private int z, t, cRed, cGreen, cBlue;
    
    // this may cause an error; but probably shouldn't (don't anticipate
    // negative channel numbers)
    public static final int CHANNEL_OFF = -2;
  
    /**
     * Invariant: cXX will be CHANNEL_OFF if xOn = false.  This maintains
     * consistency for likewise images, and speeds things up a bit.
     *
     */
    public ParameterGroup(String imageName, int pixelsID,
                          int z, int t, int cRed, int cGreen, int cBlue,
                          boolean rOn, boolean gOn, boolean bOn)
    {
      if(imageName == null)
      {
        this.imageName = "null";
      }
      else
      {
        this.imageName = imageName;
      }
      this.pixelsID = pixelsID;
      this.z = z;
      this.t = t;
      this.cRed = rOn ? cRed : CHANNEL_OFF;
      this.cGreen = gOn ? cGreen : CHANNEL_OFF;
      this.cBlue = bOn ? cBlue : CHANNEL_OFF;     
    }
 
    public String getImageName()
    {
      return imageName;
    }
  
    public int getPixelsID()
    {
      return pixelsID;
    }

    public int getCBlue()
    {
      return cBlue;
    }
  
    public int getCGreen()
    {
      return cGreen;
    }
  
    public int getCRed()
    {
      return cRed;
    }
  
    public int getT()
    {
      return t;
    }
  
    public int getZ()
    {
      return z;
    }
  
    public boolean equals(Object o)
    {
      if(o == null || !(o instanceof ParameterGroup))
      {
        return false;
      }
      ParameterGroup pg = (ParameterGroup)o;
    
      if(!this.imageName.equals(pg.getImageName()) ||
          this.pixelsID != pg.getPixelsID() ||
          this.z != pg.getZ() ||
          this.t != pg.getT() ||
          this.cRed != pg.getCRed() ||
          this.cGreen != pg.getCGreen() ||
          this.cBlue != pg.getCBlue())
      {
        return false;
      }
      else return true;
    }
     
    public int hashCode()
    {
      return imageName.hashCode() +
             (z * 10000) +
             (cRed * 1000) +
             (cGreen * 100) +
             (cBlue * 10)
             + t;
    }
  
  }
}
