/*
 * org.openmicroscopy.browser.layout.CoordinateLayoutMethod
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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
package org.openmicroscopy.browser.layout;

import java.awt.geom.Point2D;
import java.util.HashMap;
import java.util.Map;

import org.openmicroscopy.browser.images.Thumbnail;

/**
 * Specifies a layout method to arbitarily layout images by a set of
 * coordinates.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version 2.2
 * @since 2.2
 */
public class CoordinateLayoutMethod implements LayoutMethod
{
  private Map positionMap;
  
  public CoordinateLayoutMethod()
  {
    positionMap = new HashMap();
  }
  
  /**
   * Returns the assigned/saved coordinate of the specified thumbnail.  Returns
   * nothing if the thumbnail does not have a specified coordinate.
   * 
   * @see org.openmicroscopy.browser.layout.LayoutMethod#getAnchorPoint(org.openmicroscopy.browser.images.Thumbnail)
   */
  public Point2D getAnchorPoint(Thumbnail t)
  {
    if(!positionMap.containsKey(t))
    {
      return null;
    }
    else
    {
      return (Point2D)positionMap.get(t);
    }
  }
  
  /**
   * Sets the anchor (upper-left) coordinate of the specified thumbnail.
   * 
   * @param t The thumbnail to anchor.
   * @param point The desired anchor (upper-left) point of the thumbnail.
   */
  public void setAnchorPoint(Thumbnail t, Point2D point)
  {
    if(t != null && point != null)
    {
      positionMap.put(t,point);
    }
  }
  
  /**
   * Removes the thumbnail from the method and unloads its coordinate.
   * @param t The thumbnail to remove.
   */
  public void removeThumbnail(Thumbnail t)
  {
    if(t != null)
    {
      positionMap.remove(t);
    }
  }
  
  // TODO: save/load methods?  or have separate class take care of that?
  // store as semantic type?
}
