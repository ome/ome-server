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
 * @version $Revision$ $Date$
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
  
  // singleton constructor
  private ImageCache()
  {
    diskCache = new ImageDiskCache();
    memoryCache = new ImageMemoryCache(DEFAULT_MEMORY_STRATEGY);        
  }
  
  /**
   * Returns a reference to the single image cache in the application.
   * 
   * @return
   */
  public static ImageCache getInstance()
  {
    if(cache == null)
    {
      cache = new ImageCache();
    }
    return cache;
  }
  
  /**
   * Returns the current status of the image slice with the specified attributes
   * in the cache-- that is, whether or not it is in memory or on disk,
   * or not stored at all.
   * 
   * Possible return values:
   * <ul>
   * <li><b>NOT_STORED</b>: The image is not in the cache.</li>
   * <li><b>IN_MEMORY</b>: The image resides in memory.</li>
   * <li><b>WRITING_TO_DISK</b>: The image is being flushed out of memory onto disk.</li>
   * <li><b>WRITTEN_TO_DISK</b>: The image is stored on disk.
   * </ul>
   * 
   * @param imageName The name of the image to find.
   * @param pixelsID The ID of the pixels of that image to find.
   * @param z The z-level of the image slice to find.
   * @param t The t-index of the image slice to find.
   * @param cRed The ID of the red channel of the target image slice.
   * @param cGreen The ID of the green channel of the target image slice.
   * @param cBlue The ID of the blue channel of the target image slice.
   * @param rOn Whether or not the red filter is on.
   * @param gOn Whether or not the green filter is on.
   * @param bOn Whether or not the blue filter is on.
   * @return See above return values.
   */
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
  
  /**
   * Loads an image slice with the specified parameters from the cache, if
   * it exists in the cache.  If it doesn't (this can be determined ahead of
   * time by calling <code>getImageStatus()</code>), this function will return
   * null.
   * 
   * @param imageName The name of the image to load.
   * @param pixelsID The ID of the pixels of that image (in the DB) to load.
   * @param z The z-level of the image slice to load.
   * @param t The t-index of the image slice to load.
   * @param cRed The ID of the red channel of the target image slice.
   * @param cGreen The ID of the green channel of the target image slice.
   * @param cBlue The ID of the blue channel of the target image slice.
   * @param rOn Whether or not the red filter is on.
   * @param gOn Whether or not the green filter is on.
   * @param bOn Whether or not the blue filter is on.
   * @return The image corresponding to that parameters, or null if it is not
   *         in the cache.
   * 
   * @throws IOException If the cache cannot read from disk.
   */
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
      // easy, return from memory
      return memoryCache.load(pg);
    }
    else if(diskCache.getImageStatus(pg) == ImageDiskCache.STORED)
    {
      // block-read from disk
      BufferedImage image = diskCache.load(pg);
      // store this in memory
      memoryCache.store(image,pg);
      // now return
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
          // wait until image write is done
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
  
  /**
   * Stores the 2D image with the corresponding parameters into the cache.  The
   * image will be simultaneously written to memory and onto disk, although a
   * thread will take care of the disk write (this function will exit as soon
   * as the image is stored into memory).  Exits immediately if the image is
   * null.
   * 
   * @param image The 2D image to store.
   * @param imageName The name of the image (qualified in the DB).
   * @param pixelsID The ID of the pixels of that image (in the DB).
   * @param z The z-level of the image slice.
   * @param t The t-index of the image slice.
   * @param cRed The ID of the red channel of the 2D image.
   * @param cGreen The ID of the green channel of the 2D image.
   * @param cBlue The ID of the blue channel of the 2D image.
   * @param rOn Whether or not the red filter is on.
   * @param gOn Whether or not the green filter is on.
   * @param bOn Whether or not the blue filter is on.
   * 
   * @throws IOException If the image cannot be written to disk.
   */
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
    
    memoryCache.store(image,pg); // store in memory immediately
    diskCache.store(image,pg); // write to disk immediately in case of mem error.
  }
  
  /**
   * The disk portion of the cache, which includes functions to name and
   * retrieve the images from and to disk.
   * 
   * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
   * @version $Revision$ $Date$
   */
  private class ImageDiskCache
  {
    private Set imageSliceSet;
    private Map statusMap;
    
    /**
     * Error status (IOException)
     */
    public static final int ERROR = -1;
    
    /**
     * Not stored on disk status.
     */
    public static final int NOT_STORED = 0;
    
    /**
     * Storing to disk status.
     */
    public static final int STORING = 1;
    
    /**
     * Stored on disk status.
     */
    public static final int STORED = 2;
  
    /**
     * A shortcut.
     */
    public static final String JPEG = "jpg";
    
    /**
     * Constructs a new disk cache, initializing records for the cache.
     * Package private, so ha ha ha-- too bad for you.
     *
     */
    ImageDiskCache()
    {
      imageSliceSet = new HashSet();
      statusMap = new HashMap();
      // possibly load if already on disk
    }
  
    /**
     * Gets the status of an image on disk, given a group of parameters
     * specifying which 2D slice of the the target image, and the image and
     * pixels ID of the target image.
     * 
     * Possible return values:
     * <ul>
     * <li><b>ERROR</b>: If pg is null.</li>
     * <li><b>NOT_STORED</b>: If the image is not on disk.</li>
     * <li><b>STORING</b>: If the image is being written to disk.</li>
     * <li><b>STORED</b>: If the image is stored on disk.</li>
     * </ul>
     * 
     * @param pg The ParameterGroup that corresponds to the desired 2D image.
     * @return See above return values.
     */
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
  
    /**
     * Loads a stored image corresponding to the specified ParameterGroup
     * from disk.  Will return null if pg is null or if the image is not
     * cached on disk.  If the image is being written to disk, this method
     * will not block-- it will just return null.
     * 
     * @param pg The parameter group containing all the image slice information,
     *           which will determine which 2D image slice to load.
     * @return The 2D image corresponding to the specified parameters, or null
     * @throws IOException If the image cannot be read from disk.
     */
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
  
    /**
     * Stores an image corresponding to the specified ParameterGroup
     * to disk.  Does nothing if either parameter is null.
     * @param image The image to store.
     * @param pg The parameters of the image.
     * @throws IOException If the image cannot be written to disk.
     */
    public void store(BufferedImage image, ParameterGroup pg)
      throws IOException
    {
      if(image == null || pg == null)
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
  
    // updates status.
    private void updateStatus(String fileName, int status)
    {
      statusMap.put(fileName,new Integer(status));
    }
  
    // provides a consistent mechanism to name image files on disk,
    // based on the parameters of the image.
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
   * A thread that stores images to disk (an expensive operation) in the
   * background.
   * 
   * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
   * @version $Revision$ $Date$
   */
  private class ImageCacheThread extends Thread
  {
    private ImageDiskCache callback;
    private BufferedImage imageToSave;
    private String fileType;
    private File fileTarget;

    /**
     * Constructs a thread which interacts with the disk cache (to let it
     * know that it has completed).  Stores the specified image in the runtime
     * folder with the specified file extension.  Relies on the javax.imageio
     * package to correctly write to disk in the specified format.
     * 
     * @param callback The disk cache to notify on write completion.
     * @param imageToSave The image to write to disk.
     * @param fileType The file format to save as.
     * @param fileTarget The file (handle) to write to.
     */
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
  
    /**
     * Start writing to disk, updating the disk cache.
     */
    public void start()
    {
      callback.updateStatus(fileTarget.getName(),
                            ImageDiskCache.STORING);
      super.start();
    }
    
    /**
     * Write to disk.
     * 
     * @see java.lang.Runnable#run()
     * @throws IOException If the disk write fails somehow.
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
   * @version $Revision$ $Date$
   */
  private class ImageMemoryCache
  {
    /**
     * Indicates that the image is in memory.
     */
    public static final int IN_MEMORY = 1;
    
    /**
     * Indicates that the image is not in memory.
     */
    public static final int NOT_IN_MEMORY = 0;
  
    /**
     * Indicates that the cache is using a least-recently-used cache
     * flush strategy.
     */
    public static final int STRATEGY_LRU = 0;
    
    /**
     * Indicates that the cache is using a first in-first out cache
     * flush strategy.
     */
    public static final int STRATEGY_FIFO = 1;
  
    // selected strategy
    private int strategy;
  
    // internal data structures
    private List cacheList;
    private Map cacheMap;
    
    /**
     * Constructs a memory cache that uses the specified strategy to flush
     * images when the cache is full.
     * 
     * @param strategy The strategy to use.
     * @throws IllegalArgumentException If the specified strategy is invalid.
     */
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
  
    /**
     * Returns which strategy this cache is using to flush images.
     * @return The used strategy.
     */
    public int getStrategy()
    {
      return strategy;
    }
  
    /**
     * Sets this cache's strategy to the specified strategy.  Does nothing
     * if the strategy parameter is invalid.
     * 
     * @param strategy The strategy to use.
     */
    public void setStrategy(int strategy)
    {
      if(isValidStrategy(strategy))
      {
        this.strategy = strategy;
      }
    }
  
    // simple check for validation
    private boolean isValidStrategy(int strategy)
    {
      if(strategy == STRATEGY_FIFO ||
         strategy == STRATEGY_LRU)
      {
        return true;
      }
      else return false;
    }
  
    /**
     * Returns whether or not the image corresponding to the specified
     * parameters is in memory.
     * 
     * @param pg The parameters of the image to check.
     * @return Whether the image is loaded in memory.
     */
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
  
    /**
     * Loads the image corresponding to the specified parameters from memory,
     * if it resides in memory.  Otherwise returns null.
     * 
     * @param pg The parameters of the image to load.
     * @return Null if pg is null or the desired image in the cache, otherwise
     *         the desired 2D image slice.
     */
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
     * Stores the 2D image slice with the corresponding parameters into
     * memory.  Does nothing if image or pg is null.
     * 
     * @param image The image to store.
     * @param pg The corresponding parameters of the image (key)
     */
    public void store(BufferedImage image, ParameterGroup pg)
      throws IOException
    {
      if(image == null || pg == null)
      {
        return;
      }
      
      cacheList.add(0,pg); // LRU/FIFO scheme
      // use soft references for automatic memory freeing on out-of-memory
      cacheMap.put(pg,new SoftReference(image));
    }
    
    // remove method
    private void remove(ParameterGroup pg)
    {
      cacheList.remove(pg);
      cacheMap.remove(pg);
    }
  }
  
  /**
   * A simple data structure which encapsulates all the parameters used to
   * identify images and extract 2D information from a 5D image.
   * 
   * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
   * @version $Revision$ $Date$
   */
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
     * consistency for likewise images, and speeds things up a bit.  Also
     * saves disk space for the cache.  Two parameter groups will be
     * equivalent if the image is perceived the same; that is-- cRed can be
     * 0 or 1, but if rOn is false, if all other parameters (for active
     * channels) are equivalent, the parameter groups will be equal.
     *
     * @param imageName The name of the image (reflected in the DB)
     * @param pixelsID The ID of the pixels (in the DB)
     * @param z The z index into the 5D image.
     * @param t The t inded into the 5D image.
     * @param cRed The ID of the red channel (irrelevant if rOn is false).
     * @param cGreen The ID of the green channel (irrelevant if gOn is false).
     * @param cBlue The ID of the blue channel (irrelevant if bOn is false).
     * @param rOn Whether or not the image uses the red filter.
     * @param gOn Whether or not the image uses the green filter.
     * @param bOn Whether or not the image uses the blue filter.
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
