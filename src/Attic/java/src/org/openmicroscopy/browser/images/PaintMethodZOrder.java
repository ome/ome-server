/*
 * org.openmicroscopy.browser.images.PaintMethodZOrder
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
package org.openmicroscopy.browser.images;

import java.util.ArrayList;
import java.util.List;

/**
 * A class that specifies the active paint methods for a particular
 * browser window.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version
 * @since
 */
public class PaintMethodZOrder
{
  private List bottomToTop;
  
  /**
   * The paint method is inactive.
   */
  public static final int NOT_LISTED = -1;
  
  public PaintMethodZOrder()
  {
    bottomToTop = new ArrayList();
  }
  
  public void addMethodToBottom(PaintMethod m)
  {
    if(m == null)
    {
      return;
    }
    else
    {
      bottomToTop.add(0,m);
    }
  }
  
  public void addMethodToTop(PaintMethod m)
  {
    if(m == null)
    {
      return;
    }
    else
    {
      bottomToTop.add(m);
    }
  }
  
  public void addMethodAtIndex(int index, PaintMethod m)
  {
    if(index < 0 || index > bottomToTop.size() || m == null)
    {
      return;
    }
    else
    {
      bottomToTop.add(index,m);
    }
  }
  
  public void sendMethodBackward(PaintMethod m)
  {
    if(!bottomToTop.contains(m))
    {
      return;
    }
    else
    {
      int prev = bottomToTop.indexOf(m);
      if(prev != 0)
      {
        bottomToTop.remove(m);
        bottomToTop.add(prev-1,m);
      }
    }
  }
  
  public void sendMethodForward(PaintMethod m)
  {
    if(!bottomToTop.contains(m))
    {
      return;
    }
    else
    {
      int prev = bottomToTop.indexOf(m);
      if(prev != bottomToTop.size()-1)
      {
        bottomToTop.remove(m);
        bottomToTop.add(prev+1,m);
      }
    }
  }
  
  public void sendMethodToBack(PaintMethod m)
  {
    if(!bottomToTop.contains(m))
    {
      return;
    }
    else
    {
      bottomToTop.remove(m);
      addMethodToBottom(m);
    }
  }
  
  public void sendMethodToFront(PaintMethod m)
  {
    if(!bottomToTop.contains(m))
    {
      return;
    }
    else
    {
      bottomToTop.remove(m);
      addMethodToTop(m);
    }
  }
  
  public int getMethodIndex(PaintMethod m)
  {
    if(!bottomToTop.contains(m))
    {
      return NOT_LISTED;
    }
    else return bottomToTop.indexOf(m);
  }
  
  public void setMethodIndex(int index, PaintMethod m)
  {
    if(index < 0 || index > bottomToTop.size()-1 || m == null)
    {
      return;
    }
    else
    {
      bottomToTop.remove(m);
      bottomToTop.add(index,m);
    }
  }
}
