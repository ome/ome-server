/*
 * org.openmicroscopy.browser.images.PaintMethods
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

import java.util.HashMap;
import java.util.Map;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version
 * @since
 */
public class PaintMethods
{
  private Map methodMap;
  private static PaintMethods methods;
  
  private PaintMethods()
  {
    methodMap = new HashMap();
  }
  
  public static PaintMethods getInstance()
  {
    if(methods == null)
    {
      methods = new PaintMethods();
    }
    return methods;
  }
  
  public void put(String key, PaintMethod method)
  {
    if(key == null || method == null)
    {
      return;
    }
    methodMap.put(key,method);
  }
  
  public PaintMethod get(String key)
  {
    return (PaintMethod)methodMap.get(key);
  }
  
  public PaintMethod remove(String key)
  {
    PaintMethod method = get(key);
    methodMap.remove(key);
    return method;
  }
}
