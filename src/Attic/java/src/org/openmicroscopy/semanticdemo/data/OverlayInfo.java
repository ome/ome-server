/*
 * org.openmicroscopy.semanticdemo.data.OverlayInfo
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

import org.openmicroscopy.semanticdemo.Orientation;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class OverlayInfo
{
  private String textSource;
  private String[] xSources;
  private String[] ySources;
  private boolean scales;
  private Orientation orientation;
  private int displayOnZ;
  private int displayOnC;
  private int displayOnT;
  
  public OverlayInfo()
  {
  }
  
  
  /**
   * @return
   */
  public Orientation getOrientation()
  {
    return orientation;
  }

  /**
   * @return
   */
  public boolean isScales()
  {
    return scales;
  }

  /**
   * @return
   */
  public String getTextSource()
  {
    return textSource;
  }

  /**
   * @return
   */
  public String[] getXSources()
  {
    return xSources;
  }

  /**
   * @return
   */
  public String[] getYSources()
  {
    return ySources;
  }

  /**
   * @param orientation
   */
  public void setOrientation(Orientation orientation)
  {
    this.orientation = orientation;
  }

  /**
   * @param b
   */
  public void setScales(boolean b)
  {
    scales = b;
  }

  /**
   * @param string
   */
  public void setTextSource(String string)
  {
    textSource = string;
  }

  /**
   * @param strings
   */
  public void setXSources(String[] strings)
  {
    // deep copy
    xSources = new String[strings.length];
    for(int i=0;i<strings.length;i++)
    {
      xSources[i] = strings[i];
    }
  }

  /**
   * @param strings
   */
  public void setYSources(String[] strings)
  {
    // deep copy
    ySources = new String[strings.length];
    for(int i=0;i<strings.length;i++)
    {
      ySources[i] = strings[i];
    }
  }

  /**
   * @return
   */
  public int getDisplayOnC()
  {
    return displayOnC;
  }

  /**
   * @return
   */
  public int getDisplayOnT()
  {
    return displayOnT;
  }

  /**
   * @return
   */
  public int getDisplayOnZ()
  {
    return displayOnZ;
  }

  /**
   * @param i
   */
  public void setDisplayOnC(int i)
  {
    displayOnC = i;
  }

  /**
   * @param i
   */
  public void setDisplayOnT(int i)
  {
    displayOnT = i;
  }

  /**
   * @param i
   */
  public void setDisplayOnZ(int i)
  {
    displayOnZ = i;
  }

}
