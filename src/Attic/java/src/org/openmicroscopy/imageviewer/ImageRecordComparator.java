/*
 * org.openmicroscopy.imageviewer.ImageRecordComparator
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

import org.openmicroscopy.Image;
import java.util.Comparator;

/**
 * Sorts images by ID.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class ImageRecordComparator implements Comparator
{
  /**
   * Sorts images by image ID.  Will place null objects at the end of the list.
   * If either one of the objects is not an Image, will return 0, implying
   * equality (but this is not really the case-- equals() will return false)
   * 
   * @param o1 The first Image.
   * @param o2 The second Image.
   * @see java.util.Comparator#compare(java.lang.Object, java.lang.Object)
   */
  public int compare(Object o1, Object o2)
  {
    // move nulls to end
    if(o1 == null)
    {
      if(o2 == null)
      {
        return 0;
      }
      else return 1;
    }
    else if(o2 == null)
    {
      if(o1 == null)
      {
        return 0;
      }
      else return -1;
    }
    
    if(o1 instanceof Image && o2 instanceof Image)
    {
      Image image1 = (Image)o1;
      Image image2 = (Image)o2;
      if(image1.getID() == image2.getID())
      {
        return 0;
      }
      else
      {
        return image1.getID() < image2.getID() ? -1 : 1;
      }
    }
    
    // uh, I dunno
    return 0;
  }
}
