/*
 * org.openmicroscopy.semanticdemo.Overlay
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
package org.openmicroscopy.semanticdemo;

import java.awt.Color;
import java.awt.Shape;
import java.awt.geom.*;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public abstract class Overlay
{
  protected Orientation orientation;
  protected Color outlineColor;
  protected Color fillColor;
  protected Point2D absolutePoint;
  protected Shape prototype;
  protected boolean scales;
  
  public Orientation getOrientation()
  {
    return orientation;
  }
  
  public void setOrientation(Orientation orientation)
  {
    if(orientation != null)
    {
      this.orientation = orientation;
    }
  }
  
  public Color getOutlineColor()
  {
    return outlineColor;
  }
  
  public void setOutlineColor(Color color)
  {
    this.outlineColor = color;
  }
  
  public Color getFillColor()
  {
    return fillColor;
  }
  
  public void setFillColor(Color color)
  {
    this.fillColor = color;
  }
  
  public Point2D getAbsolutePoint()
  {
    return absolutePoint;
  }
  
  public void setAbsolutePoint(Point2D point)
  {
    if(point != null)
    {
      this.absolutePoint = point;
    }
  }
  
  public Shape getPrototype()
  {
    return prototype;
  }
  
  public void setPrototype(Shape shape)
  {
    if(shape != null)
    {
      this.prototype = shape;
    }
  }
  
  public boolean isScaling()
  {
    return scales;
  }
  
  public void setScaling(boolean scaling)
  {
    this.scales = scaling;
  }
  
  
}
