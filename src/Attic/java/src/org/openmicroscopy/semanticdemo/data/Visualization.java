/*
 * org.openmicroscopy.semanticdemo.data.Visualization
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
package org.openmicroscopy.semanticdemo.data;

import org.openmicroscopy.OMEObject;
import org.openmicroscopy.SemanticType;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class Visualization
{
  public static final class DisplayType
  {
    private int key;
    
    private DisplayType(int key)
    {
      this.key = key;
    }
    
    public static final DisplayType ANNOTATION = new DisplayType(1);
    public static final DisplayType POINT = new DisplayType(2);
    public static final DisplayType BOUNDS = new DisplayType(3);
    public static final DisplayType LINE = new DisplayType(4);
  }
  
  private int visID;
  private SemanticType semanticType;
  private String objectType;
  private DisplayType displayType;
  
  public Visualization(int ID)
  {
    this.visID = ID;
  }
  /**
   * @return
   */
  public DisplayType getDisplayType()
  {
    return displayType;
  }

  /**
   * @return
   */
  public String getObjectType()
  {
    return objectType;
  }

  /**
   * @return
   */
  public SemanticType getSemanticType()
  {
    return semanticType;
  }

  /**
   * @return
   */
  public int getID()
  {
    return visID;
  }

  /**
   * @param type
   */
  public void setDisplayType(DisplayType type)
  {
    displayType = type;
  }

  /**
   * @param object
   */
  public void setObjectType(String objectType)
  {
    this.objectType = objectType;
  }

  /**
   * @param type
   */
  public void setSemanticType(SemanticType type)
  {
    semanticType = type;
  }

  /**
   * @param i
   */
  public void setVisID(int i)
  {
    visID = i;
  }
  
  public boolean isSemantic()
  {
    return objectType == null && semanticType != null;
  }
  
  public boolean isObjective()
  {
    return semanticType == null && objectType != null;
  }

}
