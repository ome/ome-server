/*
 * org.openmicroscopy.semanticdemo.OverlayImagePanel
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

import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Shape;
import java.awt.geom.AffineTransform;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

import javax.swing.*;

import org.openmicroscopy.imageviewer.ui.ImagePanel;


/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class OverlayImagePanel extends ImagePanel
                               implements OverlayReceiver
{
  // quick hack...
  private Set overlays;
  
  public OverlayImagePanel(JComponent parentContainer)
  {
    super(parentContainer);
    overlays = new HashSet();
  }
  
  public void paintComponent(Graphics g)
  {
    super.paintComponent(g);
    
    Graphics2D g2 = (Graphics2D)g;
    for(Iterator iter = overlays.iterator(); iter.hasNext();)
    {
      Overlay overlay = (Overlay)iter.next();
      g2.setColor(overlay.getOutlineColor());
      g2.setPaint(overlay.getFillColor());
      
      // ignore orientation/scaling for now
      Shape s = overlay.getPrototype();
      AffineTransform at =
        AffineTransform.getTranslateInstance(overlay.getAbsolutePoint().getX(),
                                             overlay.getAbsolutePoint().getY());
      g2.fill(at.createTransformedShape(s));
      g2.draw(at.createTransformedShape(s));
    }
    
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.semanticdemo.OverlayReceiver#addOverlay(org.openmicroscopy.semanticdemo.Overlay)
   */
  public void addOverlay(Overlay overlay)
  {
    // TODO Auto-generated method stub
    if(overlay != null)
    {
      overlays.add(overlay);
      repaint();
    }
  }
  
  public void addOverlays(Overlay[] overlays)
  {
    if(overlays == null)
    {
      return;
    }
    
    for(int i=0;i<overlays.length;i++)
    {
      this.overlays.add(overlays[i]);
    }
    repaint();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.semanticdemo.OverlayReceiver#setOverlays(org.openmicroscopy.semanticdemo.Overlay[])
   */
  public void setOverlays(Overlay[] overlays)
  {
    if(overlays == null || overlays.length == 0)
    {
      this.overlays.clear();
      repaint();
      return;
    }
    // TODO Auto-generated method stub
    this.overlays.clear();
    for(int i=0;i<overlays.length;i++)
    {
      this.overlays.add(overlays[i]);
    }
    repaint();
  }


}
