/*
 * org.openmicroscopy.imageviewer.data.ChannelBlackScaleData
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


/**
 * A class which encapsulates the OME image adjustment parameters necessary
 * to transform the raw OME image information to a conventional RGB or
 * grayscale image.  This class is made up of four "chunks": the red channel
 * chunk, green channel chunk, blue channel chunk, and monochrome channel
 * chunk.  Each chunk contains three values: channel number, black level
 * baseline, and channel brightness scaling factor.  The grayscale value in
 * each pixel of the OME image will be reduced by the blacklevel baseline and
 * then multiplied by the brightness scaling factor for each channel to
 * generate appropriate red, green, blue or grayscale values: this is done by
 * the RGBImageConverter.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 * @see org.openmicroscopy.imageviewer.data.RGBImageConverter
 */
public class ChannelBlackScaleData
{
  private CBSChunk[] scaleInfo;
  
  /**
   * The index of the red CBS chunk.
   */
  public static final int RED_CHUNK = 0;
  
  /**
   * The index of the green CBS chunk.
   */
  public static final int GREEN_CHUNK = 1;
  
  /**
   * The index of the blue CBS chunk.
   */
  public static final int BLUE_CHUNK = 2;
  
  /**
   * The index of the gray CBS chunk.
   */
  public static final int GRAY_CHUNK = 3;
  
  // default CBS blacklevel parameter
  private static final int DEFAULT_BLACKLEVEL = 0;
  
  // default CBS scaling parameter
  private static final int DEFAULT_SCALE = 4;
  
  /**
   * Creates an empty four-channel CBS data type.
   */
  public ChannelBlackScaleData()
  {
    scaleInfo = new CBSChunk[4];
    for(int i = 0; i < 4; i++)
    {
      scaleInfo[i] = new CBSChunk();
    }
  }
  
  /**
   * Creates a specified mono- or multi-channel CBS data object.
   * One, three, or four chunks can be passed into this constructor.  If one
   * chunk is passed, this indicates this data represents image adjustment
   * information for a monochrome image; so CBS values for all channels will
   * be identical.  If three chunks are passed, this indicates that this data
   * represents image adjustment information for an RGB image; so CBS value for
   * red, green and blue channels will be distinct.  Same goes for four chunks.
   * 
   * @param cbsInfo
   * @throws IllegalArgumentException
   */
  public ChannelBlackScaleData(CBSChunk[] cbsInfo)
    throws IllegalArgumentException
  {
    if(cbsInfo.length == 3 || cbsInfo.length == 4)
    {
      for(int i=0;i<cbsInfo.length;i++)
      {
        CBSChunk chunk = cbsInfo[i];
        scaleInfo[i] = new CBSChunk(chunk.getChannel(),
                                    chunk.getBlackLevel(),
                                    chunk.getScale());
      }
    }
    
    // single grayscale value
    else if(cbsInfo.length == 1)
    {
      CBSChunk chunk = cbsInfo[0];
      scaleInfo[GRAY_CHUNK] = new CBSChunk(chunk.getChannel(),
                                           chunk.getBlackLevel(),
                                           chunk.getScale());
      // by reference (should be OK)
      scaleInfo[RED_CHUNK] = scaleInfo[GRAY_CHUNK];
      scaleInfo[GREEN_CHUNK] = scaleInfo[GRAY_CHUNK];
      scaleInfo[BLUE_CHUNK] = scaleInfo[GRAY_CHUNK];
    }
    else
    {
      throw new IllegalArgumentException("Incorrect number of CBS values");
    }
  }
  
  // analogous to makeWBS() in OMEimage.js (SVG viewer)
  /**
   * Gets the default adjustment parameters for CCD image data, given a set
   * of wavelengths.  This was ported from the makeWBS() function in the
   * OMEimage.js image viewer... but it seems to work.
   * 
   * @param waves The different wavelengths (corresponding to either the same
   *              or different channels) used to capture an image.
   * @return The default black-level adjustment parameters for a CCD image.
   *         Returns null if waves is null or if the length of the wavelength
   *         array is zero.
   */
  public static ChannelBlackScaleData getDefaultChannelScale(Wavelength[] waves)
  {
    if(waves == null || waves.length < 1)
    {
      return null;
    }
    int len = waves.length;
    ChannelBlackScaleData data = new ChannelBlackScaleData();
    
    // not quite sure if this is doing the right thing... looks weird
    // (but again, analogous to makeWBS())
    data.setCBSChunk(RED_CHUNK,
                     new CBSChunk(waves[0].getChannelNumber(),
                                  DEFAULT_BLACKLEVEL,
                                  DEFAULT_SCALE));
                                   
    
    data.setCBSChunk(GREEN_CHUNK,
                     new CBSChunk(waves[len/2].getChannelNumber(),
                                  DEFAULT_BLACKLEVEL,
                                  DEFAULT_SCALE));
                                  
    data.setCBSChunk(BLUE_CHUNK,
                     new CBSChunk(waves[len-1].getChannelNumber(),
                                  DEFAULT_BLACKLEVEL,
                                  DEFAULT_SCALE));
    
    data.setCBSChunk(GRAY_CHUNK,
                     new CBSChunk(waves[0].getChannelNumber(),
                                  DEFAULT_BLACKLEVEL,
                                  DEFAULT_SCALE));                        
    
    return data;
  }
  
  /**
   * Returns the channel-blacklevel-scaling factor data chunk corresponding to
   * a particular color filter.  The parameter must be either RED_CHUNK,
   * GREEN_CHUNK, BLUE_CHUNK or GRAY_CHUNK, or an exception will be thrown.
   * 
   * @param whichChunk Which chunk to get.
   * @return The chunk containing channel-blacklevel-scaling for a certain channel.
   * @throws IllegalArgumentException If whichChunk is invalid.
   */
  public CBSChunk getCBSChunk(int whichChunk)
    throws IllegalArgumentException
  {
    if(!isValidChunkIndex(whichChunk))
    {
      throw new IllegalArgumentException("Invalid data chunk type");
    }
    CBSChunk chunk = scaleInfo[whichChunk];
    return new CBSChunk(chunk.getChannel(),chunk.getBlackLevel(),chunk.getScale());
  }
  
  /**
   * Sets the channel-blacklevel-scaling parameters for a particular color
   * channel.  The parameter must be either RED_CHUNK, GREEN_CHUNK, BLUE_CHUNK
   * or GRAY_CHUNK, or an exception will be thrown.
   * 
   * @param whichChunk Which chunk to set.
   * @param chunk The channel-blacklevel-scaling factor for the specified channel.
   * @throws IllegalArgumentException If whichChunk is invalid or chunk is null.
   */
  public void setCBSChunk(int whichChunk, CBSChunk chunk)
    throws IllegalArgumentException
  {
    if(!isValidChunkIndex(whichChunk) || chunk == null)
    {
      throw new IllegalArgumentException("Invalid chunk parameters");
    }
    scaleInfo[whichChunk] = new CBSChunk(chunk.getChannel(),
                                         chunk.getBlackLevel(),
                                         chunk.getScale());
  }
  
  private boolean isValidChunkIndex(int index)
  {
    return (index > -1 && index < 4);
  }
  
  /**
   * An object representation of the channel-blacklevel-scaling adjustment
   * parameters.  This data is used to transformed the values contained in a 
   * 10- or 12-bit grayscale image to RGB.  These values are usually dependent
   * on plane statistics culled from the OME database, so setting these to
   * arbitrary, non-precomputed values will likely generate unsatisfactory
   * results.
   * 
   * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
   * @version $Revision$ $Date$
   */
  static class CBSChunk
  {
    private int channel;
    private int blackLevel;
    private float scale;
    
    /**
     * Dummy constructor.
     *
     */
    public CBSChunk()
    {
    }
    
    /**
     * Parameterized constructor.
     * @param channel The channel number of the scaling data.
     * @param blackLevel The base blacklevel of this channel.
     * @param scale The brightness scaling factor for this channel.
     */
    public CBSChunk(int channel, int blackLevel, float scale)
    {
      this.channel = channel;
      this.blackLevel = blackLevel;
      this.scale = scale;
    }
    
    
    /**
     * @return The base blacklevel.
     */
    public int getBlackLevel()
    {
      return blackLevel;
    }

    /**
     * @return The channel.
     */
    public int getChannel()
    {
      return channel;
    }

    /**
     * @return The scaling factor.
     */
    public float getScale()
    {
      return scale;
    }

    /**
     * @param i The base black level.
     */
    public void setBlackLevel(int i)
    {
      blackLevel = i;
    }

    /**
     * @param i The channel.
     */
    public void setChannel(int i)
    {
      channel = i;
    }

    /**
     * @param f The scaling factor.
     */
    public void setScale(float f)
    {
      scale = f;
    }

  }
}
