/*
 * org.openmicroscopy.imageviewer.OMEModel
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
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.*;

import org.openmicroscopy.*;
import org.openmicroscopy.imageviewer.data.*;
import org.openmicroscopy.imageviewer.util.*;
import org.openmicroscopy.remote.*;

/**
 * A model with which a client GUI or viewer program can interface with the
 * OME system.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class OMEModel
{
  private RemoteBindings bindings;
  private Session session;
  private Factory factory;
  
  private List imageList;
  private boolean loggedIn;
  
  private ImageCache imageSlicesCache;
  private Map imagePixelsCache;
  private Map imageInfoCache;
  
  private Image loadedImage;
  private ImagePixels loadedPixels;
  private ImageInformation loadedInfo;
  
  // not cached in order to flush memory on image switch
  private RGBImageConverter converter;
  
  /**
   * Initializes the remote bindings and data structures necessary for this
   * model to function correctly.  Creates a OMEModel with its own
   * RemoteBindings.
   */
  public OMEModel()
  {
    try
    {
      bindings = new RemoteBindings();
    }
    catch(ClassNotFoundException ce)
    {
      throw new RuntimeException("WARNING: Remote Bindings not working.");
    }
    loggedIn = false;
    init();
  }
  
  public OMEModel(RemoteBindings exBindings)
  {
    if(exBindings != null)
    {
      bindings = exBindings;
    }
    // start throwing exceptions if you screw up
    session = bindings.getSession();
    factory = bindings.getFactory();
    loggedIn = true;
    init();
  }
  
  /**
   * Connects the model to the OME XML-RPC remote service.
   * 
   * @param xmlrpcURL The URL of the OME XML-RPC service.
   * @param username The username to use to login to the OME system.
   * @param password The password to use to login to the OME system.
   * @throws OMEException If a remote class cannot be found, if
   *         the username/password pair is invalid, or if the user cannot
   *         login (bad URL, wrong transport, etc.) 
   */
  public void login(String xmlrpcURL, String username, String password)
    throws OMEException
  {
    try
    {
      bindings.loginXMLRPC(xmlrpcURL, username, password);
      session = bindings.getSession();
      factory = bindings.getFactory();
      loggedIn = true;
    }
    catch(MalformedURLException me)
    {
      throw new OMEException("internal error: bad XMLRPC URL");
    }
    catch(Exception e)
    {
      throw new OMEException("Cannot log in: " + e.getMessage());
    }
  }
  
  /**
   * Disconnects the model from the OME XML-RPC service.
   * 
   * @throws OMEException If an error occurs during logout.
   */
  public void logout()
    throws OMEException
  {
    if(!loggedIn)
    {
      return;
    }
    else
    {
      try
      {
        bindings.logoutXMLRPC();
        factory = null;
        session = null;
        imageList.clear();
        imagePixelsCache.clear();
        imageInfoCache.clear();
        loadedPixels = null;
        loadedImage = null;
        loadedInfo = null;
        converter = null;
      }
      catch(Exception e)
      {
        throw new OMEException("Cannot log out: " + e.getMessage());
      }
    }
  }
  
  private void init()
  {
    imageList = new ArrayList();
    imageSlicesCache = ImageCache.getInstance();
    imagePixelsCache = new HashMap();
    imageInfoCache = new HashMap();
  }
  
  /**
   * Loads all the image records present in the database (this might not be
   * the smartest thing to do, but it's the dummy thing to do), regardless of
   * dataset or project.  Yeah, this is kinda bad.  But if I refined it, then
   * I'd be *completely* duplicating the functionality of some other projects,
   * so... it'll be dumb for now.
   *
   */
  public void loadImageRecords()
  {
    if(!loggedIn)
    {
      return;
    }
    
    imageList.clear();
    Map criteriaMap = new HashMap();
    criteriaMap.put("image_id","*");
    List imageRecords = factory.findObjects("OME::Image",null);
  
    for(Iterator iter = imageRecords.iterator(); iter.hasNext();)
    {
      RemoteImage image = (RemoteImage)iter.next();
      imageList.add(image);
    }
    Collections.sort(imageList,new ImageRecordComparator());
  }
  
  /**
   * Loads the 5D image with the specified (DB) image ID into the model.
   * All subsequent accessor calls will refer to the currently loaded image.
   * 
   * @param index The ID of the image to load.
   */
  public void loadImage(int index)
  {
    if(!loggedIn || index < 0 || index >= imageList.size())
    {
      return;
    }
    Integer intObj = new Integer(index);
    
    // check cache for remote pixels reference already, return
    if(imagePixelsCache.containsKey(intObj))
    {
      loadedImage = (Image)imageList.get(index);
      loadedPixels = (ImagePixels)imagePixelsCache.get(intObj);
      loadedInfo = (ImageInformation)imageInfoCache.get(intObj);
      converter = new RGBImageConverter(loadedPixels,loadedInfo);
      return;
    }
    
    // else, make remote call
    RemoteImage image = (RemoteImage)imageList.get(index);

    List pixelList = factory.findAttributes("Pixels",image);
    
    // no associated images
    if(pixelList == null || pixelList.size() == 0)
    {
      return;
    }
    Attribute pixelsAttribute = (Attribute)pixelList.get(0);
    Attribute repository = pixelsAttribute.getAttributeElement("Repository");
    LocalRepositoryFinder.findAndStore(repository);
    ImagePixels pixels = image.getPixels(pixelsAttribute);
    ImageInformation info = new ImageInformation(image,pixels,factory);
    
    if(pixels != null)
    {
      imagePixelsCache.put(intObj,pixels);
      imageInfoCache.put(intObj,info);
    }
    
    loadedImage = (Image)imageList.get(index);
    loadedPixels = pixels;
    loadedInfo = info;
    converter = new RGBImageConverter(loadedPixels,loadedInfo);
  }
  
  public void loadImageObject(Image image)
  {
    // check cache for remote pixels reference already, return
      //if(imagePixelsCache.containsKey(intObj))
      //{
      //loadedImage = (Image)imageList.get(index);
      //loadedPixels = (ImagePixels)imagePixelsCache.get(intObj);
      //loadedInfo = (ImageInformation)imageInfoCache.get(intObj);
      //converter = new RGBImageConverter(loadedPixels,loadedInfo);
      //return;
      // }

    // else, get pixels & image info

    List pixelList = factory.findAttributes("Pixels",image);

    // no associated images
    if(pixelList == null || pixelList.size() == 0)
    {
      return;
    }
    Attribute pixelsAttribute = (Attribute)pixelList.get(0);
    Attribute repository = pixelsAttribute.getAttributeElement("Repository");
    LocalRepositoryFinder.findAndStore(repository);
    ImagePixels pixels = image.getPixels(pixelsAttribute);
    ImageInformation info = new ImageInformation(image,pixels,factory);

    //if(pixels != null)
    //{
    //  imagePixelsCache.put(intObj,pixels);
    //  imageInfoCache.put(intObj,info);
    //}

    loadedImage = image;
    loadedPixels = pixels;
    loadedInfo = info;
    converter = new RGBImageConverter(loadedPixels,loadedInfo);
  }

  
  /**
   * Return the information (channels, z levels, timeslices) about the
   * currently loaded 5D image.
   * 
   * @return
   */
  public ImageInformation getImageInformation()
  {
    return loadedInfo;
  }
  
  /**
   * Get a 2D slice of the 5D image using the given parameters.
   * 
   * @param z The z-parameter of the slice to capture.
   * @param t The time frame of the slice to capture.
   * @param cRed Which channel to use for red flitering.
   * @param cGreen Which channel to use for green filtering.
   * @param cBlue Which channel to use for blue filtering.
   * @param rOn Whether or not to use the red filter.
   * @param gOn Whether or not to use the green filter.
   * @param bOn Whether or not to use the blue filter.
   * @return A 2D projection of the 5D image based on channels, z, and t.
   * @throws OMEException If the image cannot be read (remotely or from disk)
   */
  public BufferedImage getImageSlice(int z, int t, int cRed, int cGreen,
                                     int cBlue, boolean rOn,
                                     boolean gOn, boolean bOn)
    throws OMEException
  {
    if(converter == null)
    {
      System.err.println("null converter");
      return null;
    }
    
    // check cache status
    int imageStatus =
      imageSlicesCache.getImageStatus(loadedImage.getName(),
                                      loadedPixels.getPixelsAttribute().getID(),
                                      z, t, cRed, cGreen, cBlue,
                                      rOn, gOn, bOn);
    
    // load if in cache                                
    if(imageStatus == ImageCache.IN_MEMORY ||
       imageStatus == ImageCache.WRITTEN_TO_DISK)
    {
      try
      {
        BufferedImage cachedImage =
          imageSlicesCache.load(loadedImage.getName(),
                                loadedPixels.getPixelsAttribute().getID(),
                                z, t, cRed, cGreen, cBlue,
                                rOn, gOn, bOn);
        return cachedImage;
      }
      catch(Exception e)
      {
        throw new OMEException("Could not read image from cache.");
      }
    }
    
    // don't block until wait... just return unavailable
    else if(imageStatus == ImageCache.WRITING_TO_DISK)
    {
      System.err.println("writing cache miss");
      return null;
    }
    
    // not loaded yet; acquire RGB from converter & cache
    try
    {
      BufferedImage convertedImage = converter.getRGBImage(z,cRed,cGreen,cBlue,t,
                                      rOn,gOn,bOn);
      imageSlicesCache.store(convertedImage,
                             loadedImage.getName(),
                             loadedPixels.getPixelsAttribute().getID(),
                             z, t, cRed, cGreen, cBlue,
                             rOn, gOn, bOn);
      return convertedImage;
    }
    catch(IOException e)
    {
      throw new OMEException("Could not store image slice.");
    }
  }

  /**
   * Returns a list of 5D image data records.
   * 
   * @return See above.
   */
  public List getImageRecords()
  {
    return Collections.unmodifiableList(imageList);
  }
  
  /**
   * Returns a list of 5D image names.
   * 
   * @return See above.
   */
  public List getImageNames()
  {
    List imageNames = Filter.map(imageList, new MapOperator() {
      public Object execute(Object o)
      {
        RemoteImage image = (RemoteImage)o;
        return image.getName();
      }
    });
  
    return Collections.unmodifiableList(imageNames);
  }

  /**
   * Returns a list of (integer-valued) keys to the images, corresponding to
   * the IDs of the images.
   * 
   * This might not be the best thing, but we'll see.
   * 
   * @return A list of Integer keys.
   */
  public List getImageKeys()
  {
    List imageKeys = Filter.map(imageList, new MapOperator() {
      public Object execute(Object o)
      {
        RemoteImage image = (RemoteImage)o;
        return new Integer(image.getID());
      }
    });
    return Collections.unmodifiableList(imageKeys);
  }
}
