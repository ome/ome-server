/*
 * org.openmicroscopy.imageviewer.ImagePanel
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
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.awt.image.BufferedImageOp;

import javax.swing.*;


/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $ Revision: $ $ Date: $
 */
public class ImagePanel extends JPanel
                        implements ImageWidget
{
  private BufferedImage displayImage;
  private BufferedImage zoomedImage;
  private ImageController controller;
  private BufferedImageOp zoomOp;
  
  private AffineTransform zoomTransform;
  
  public ImagePanel()
  {
    setSize(600,600);
    setPreferredSize(new Dimension(600,600));
    controller = ImageController.getInstance();
    controller.setImageWidget(this);
    zoomTransform = AffineTransform.getScaleInstance(1,1);
    zoomOp = new AffineTransformOp(zoomTransform,
                                   AffineTransformOp.TYPE_BILINEAR);
  }
  
  public void paintComponent(Graphics g)
  {
    g.setColor(Color.white);
    super.paintComponent(g);
    Graphics2D g2 = (Graphics2D)g;
    
    if(zoomedImage != null)
    {
      g2.drawImage(zoomedImage,null,0,0);
    }
    else
    {
      g2.setColor(Color.black);
      g2.drawString("No image loaded",10,10);
    }
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ImageWidget#displayImage(java.awt.image.BufferedImage)
   */
  public void displayImage(BufferedImage image)
  {
    this.displayImage = image;
    if(Math.abs(zoomTransform.getScaleX() - 1) > 0.01)
    {
      System.err.println("transforming");
      this.zoomedImage = new BufferedImage((int)Math.round(image.getWidth()*
                                           zoomTransform.getScaleX()),
                                           (int)Math.round(image.getHeight()*
                                           zoomTransform.getScaleY()),
                                           BufferedImage.TYPE_INT_ARGB);
      zoomOp.filter(displayImage,zoomedImage);
    }
    else
    {
      zoomedImage = displayImage;
    }
    setPreferredSize(new Dimension(zoomedImage.getWidth(),zoomedImage.getHeight()));
    revalidate();
    repaint();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ImageWidget#clearImage()
   */
  public void clearImage()
  {
    this.displayImage = null;
    repaint();
  }
  
  public void setZoomLevel(double factor)
  {
    zoomTransform = AffineTransform.getScaleInstance(factor,factor);
    zoomOp = new AffineTransformOp(zoomTransform,
                                   AffineTransformOp.TYPE_BILINEAR);
    // cheap hack to reset-- might break eventually
    displayImage(displayImage);
  }


}