/*
 * org.openmicroscopy.imageviewer.ui.ScrollableImagePanel
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
package org.openmicroscopy.imageviewer.ui;

import java.awt.*;
import java.awt.image.BufferedImage;

import javax.swing.*;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class ScrollableImagePane extends JScrollPane
                                 implements ImageWidget
{
  private ImagePanel internalPanel;
  
  public ScrollableImagePane(ImagePanel panel)
  {
    super(panel);
    internalPanel = panel;
    internalPanel.setFittingContainer(this);
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ui.ImageWidget#getZoomLevel()
   */
  public double getZoomLevel()
  {
    return internalPanel.getZoomLevel();
  }
  
  public void setZoomLevel(double d)
  {
    if(d <= 0)
    {
      return;
    }
    
    double prev = internalPanel.getZoomLevel();
    double diff = d/prev;
    internalPanel.setZoomLevel(d);
    updateScrollPaneZoom(diff);
  }
  
  public void zoomToFit()
  {
    internalPanel.zoomToFit();
  }
  
  public void clearImage()
  {
    internalPanel.clearImage();
  }
  
  public void displayImage(BufferedImage image)
  {
    internalPanel.displayImage(image);
  }
  
  private void updateScrollPaneZoom(double zoomDiff)
  {
    int panelWidth = internalPanel.getPreferredSize().width;
    int panelHeight = internalPanel.getPreferredSize().height;
    int paneWidth = getViewport().getWidth();
    int paneHeight = getViewport().getHeight();
    // zoom in
    if(zoomDiff == 1)
    {
      // do nothing
      return;
    }
    double newExtentX, newExtentY;
  
    if(zoomDiff > 1)
    {
      int newX = 0;
      int newY = 0;
      // scale extentX if image still larger
      if(panelWidth > paneWidth)
      {
        int prevX = getHorizontalScrollBar().getModel().getValue();
        newX = (int)Math.round((double)prevX*zoomDiff);
        int adjustX = (int)Math.round(((zoomDiff-1)/2.0)*paneWidth);
        newX += adjustX;
      }
      if(panelHeight > paneHeight)
      {
        int prevY = getVerticalScrollBar().getModel().getValue();
        newY = (int)Math.round((double)prevY*zoomDiff);
        int adjustY = (int)Math.round(((zoomDiff-1)/2.0)*paneHeight);
        newY += adjustY;
      }
      internalPanel.scrollRectToVisible(new Rectangle(newX,newY,paneWidth,paneHeight));
    }
    if(zoomDiff < 1)
    {
      int newX = 0;
      int newY = 0;
    
      // scale extentX if image originally larger
      if(panelWidth > paneWidth)
      {
        int prevX = getHorizontalScrollBar().getModel().getValue();
        int adjustX = (int)Math.round((((1.0/zoomDiff)-1)/2.0)*paneWidth);
        newX = prevX;
        newX -= adjustX;
        newX = (int)Math.round((double)newX*zoomDiff);
        getHorizontalScrollBar().setValue(newX);
      }
      if(panelHeight > paneHeight)
      {
        int prevY = getVerticalScrollBar().getModel().getValue();
        int adjustY = (int)Math.round((((1.0/zoomDiff)-1)/2.0)*paneHeight);
        newY = prevY;
        newY -= adjustY;
        newY = (int)Math.round((double)newY*zoomDiff);
        getVerticalScrollBar().setValue(newY);
      }
      //internalPanel.scrollRectToVisible(new Rectangle(newX,newY,paneWidth,paneHeight));
    }
  }

}
