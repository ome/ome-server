/*
 * org.openmicroscopy.semanticdemo.OverlayTypeFactory
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

/**
 * Specifies a factory method for 
 * 
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public final class OverlayTypeFactory
{
  private Method overlayGenerator;
  
  public OverlayTypeFactory(Method method)
  {
    this.overlayGenerator = method;
  }
  
  public Overlay generateOverlay(Object dataPoint)
  {
    if(dataPoint != null)
    {
      return overlayGenerator.generateOverlay(dataPoint);
    }
    else return null;
  }
  
  public Overlay[] generateOverlays(Object[] dataPoints)
  {
    if(dataPoints == null || dataPoints.length == 0)
    {
      return null;
    }
    Overlay[] overlays = new Overlay[dataPoints.length];
    
    for(int i=0;i<overlays.length;i++)
    {
      overlays[i] = overlayGenerator.generateOverlay(dataPoints[i]);
    }
    return overlays;
  }
  
  public interface Method
  {
    public Overlay generateOverlay(Object dataPoint);
  }
}
