/*
 * org.openmicroscopy.imageviewer.ui.ImagePanel
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
import java.awt.event.*;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.awt.image.BufferedImageOp;
import java.text.NumberFormat;

import javax.swing.*;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class ImagePanel extends JPanel
                        implements ImageWidget
{
  private ImagePanelInternal internalPanel;
  private ImageController controller;
  private JScrollPane scrollPane;
  
  private JButton zoomInButton;
  private JButton zoomOutButton;
  private JButton zoom100Button;
  private JButton zoomFitButton;
  private JLabel zoomAmountLabel;
  
  public ImagePanel()
  {
    setSize(600,600);
    setPreferredSize(new Dimension(600,600));
    controller = ImageController.getInstance();
    controller.setImageWidget(this);
    
    setLayout(new BorderLayout(0,0));
    internalPanel = new ImagePanelInternal(this);
    scrollPane = new JScrollPane(internalPanel);
    add(scrollPane,BorderLayout.CENTER);
    
    JPanel zoomPanel = new JPanel();
    
    zoomInButton = new JButton("Zoom in");
    zoomOutButton = new JButton("Zoom out");
    zoomFitButton = new JButton("Zoom to fit");
    zoom100Button = new JButton("Zoom 100%");
    zoomAmountLabel = new JLabel("Zoom: 100%");
    
    zoomPanel.add(zoomInButton);
    zoomPanel.add(zoomOutButton);
    zoomPanel.add(zoomFitButton);
    zoomPanel.add(zoom100Button);
    zoomPanel.add(Box.createHorizontalStrut(5));
    zoomPanel.add(zoomAmountLabel);
    
    zoomInButton.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae)
      {
        double currentFactor = internalPanel.getZoomLevel();
        // max zoom = 800%
        if(currentFactor <= 4.0025)
        {
          internalPanel.setZoomLevel(currentFactor*2);
          updateLabel(currentFactor*2);
          updateScrollPane(2);
        }
      }
    });
    
    zoomOutButton.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae)
      {
        double currentFactor = internalPanel.getZoomLevel();
        // max zoom out = 10%
        if(currentFactor > 0.19)
        {
          internalPanel.setZoomLevel(currentFactor/2.0);
          updateLabel(currentFactor/2.0);
          updateScrollPane(0.5);
        }
      }
    });
    
    zoom100Button.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae)
      {
        double oldLevel = internalPanel.getZoomLevel();
        internalPanel.setZoomLevel(1);
        updateScrollPane(1/oldLevel);
        updateLabel(1);
      }
    });
    
    zoomFitButton.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae)
      {
        internalPanel.zoomToFit();
        updateLabel(internalPanel.getZoomLevel());
;      }
    });
    
    add(zoomPanel,BorderLayout.SOUTH);
  }
  
  private void updateScrollPane(double diff)
  {
    int panelWidth = internalPanel.getPreferredSize().width;
    int panelHeight = internalPanel.getPreferredSize().height;
    int paneWidth = scrollPane.getViewport().getWidth();
    int paneHeight = scrollPane.getViewport().getHeight();
    // zoom in
    if(diff == 1)
    {
      // do nothing
      return;
    }
    double newExtentX, newExtentY;
    System.err.println("panelWidth="+panelWidth+", panelHeight="+panelHeight);
    System.err.println("paneWidth="+paneWidth+", paneHeight="+paneHeight);
    
    if(diff > 1)
    {
      int newX = 0;
      int newY = 0;
      // scale extentX if image still larger
      if(panelWidth > paneWidth)
      {
        int prevX = scrollPane.getHorizontalScrollBar().getModel().getValue();
        newX = (int)Math.round((double)prevX*diff);
        int adjustX = (int)Math.round(((diff-1)/2.0)*paneWidth);
        newX += adjustX;
        System.err.println("prevX="+prevX+",newX="+newX);
      }
      if(panelHeight > paneHeight)
      {
        int prevY = scrollPane.getVerticalScrollBar().getModel().getValue();
        newY = (int)Math.round((double)prevY*diff);
        int adjustY = (int)Math.round(((diff-1)/2.0)*paneHeight);
        newY += adjustY;
        System.err.println("prevY="+prevY+",newY="+newY);
      }
      internalPanel.scrollRectToVisible(new Rectangle(newX,newY,paneWidth,paneHeight));
    }
    if(diff < 1)
    {
      int newX = 0;
      int newY = 0;
      
      // scale extentX if image originally larger
      if(panelWidth > paneWidth)
      {
        int prevX = scrollPane.getHorizontalScrollBar().getModel().getValue();
        int adjustX = (int)Math.round((((1.0/diff)-1)/2.0)*paneWidth);
        newX = prevX;
        newX -= adjustX;
        newX = (int)Math.round((double)newX*diff);
        System.err.println("prevX="+prevX+", newX="+newX);
        scrollPane.getHorizontalScrollBar().setValue(newX);
      }
      if(panelHeight > paneHeight)
      {
        int prevY = scrollPane.getVerticalScrollBar().getModel().getValue();
        int adjustY = (int)Math.round((((1.0/diff)-1)/2.0)*paneHeight);
        newY = prevY;
        newY -= adjustY;
        newY = (int)Math.round((double)newY*diff);
        System.err.println("prevY="+prevY+", newY="+newY);
        scrollPane.getVerticalScrollBar().setValue(newY);
      }
      //internalPanel.scrollRectToVisible(new Rectangle(newX,newY,paneWidth,paneHeight));
    }
  }
  
  void updateLabel(double zoomFactor)
  {
    NumberFormat format = NumberFormat.getPercentInstance();
    format.setMaximumFractionDigits(0);
    zoomAmountLabel.setText("Zoom: " +format.format(zoomFactor));
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ui.ImageWidget#clearImage()
   */
  public void clearImage()
  {
    internalPanel.clearImage();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ui.ImageWidget#displayImage(java.awt.image.BufferedImage)
   */
  public void displayImage(BufferedImage image)
  {
    internalPanel.displayImage(image);
  }
  
  /**
   * Gets the current zoom level.
   */
  public double getZoomLevel()
  {
    return internalPanel.getZoomLevel();
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ui.ImageWidget#setZoomLevel(double)
   */
  public void setZoomLevel(double zoomLevel)
  {
    internalPanel.setZoomLevel(zoomLevel);
  }
  
  /**
   * This is hackalicious.
   * @return A reference to the scroll pane in the ImagePanel.
   */
  public JScrollPane getImagePane()
  {
    return scrollPane;
  }
}

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
class ImagePanelInternal extends JPanel
{
  private BufferedImage displayImage;
  private BufferedImage zoomedImage;
  private ImageController controller;
  private BufferedImageOp zoomOp;
  private ImagePanel container;
  
  private AffineTransform zoomTransform;
  private double zoomLevel = 1.0;
  
  private boolean zoomToFit = false;
  
  public ImagePanelInternal(ImagePanel container)
  {
    this.container = container;
    setSize(600,600);
    setPreferredSize(new Dimension(600,600));
    zoomTransform = AffineTransform.getScaleInstance(zoomLevel,zoomLevel);
    zoomOp = new AffineTransformOp(zoomTransform,
                                   AffineTransformOp.TYPE_BILINEAR);
                                   
    this.addComponentListener(new ComponentAdapter()
    {
      public void componentResized(ComponentEvent ce)
      {
        if(zoomToFit)
        {
          zoomToFit();
        }
      }
    });
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
    System.err.println(getPreferredSize().getWidth()+","+getPreferredSize().getHeight());
  }
  
  /* (non-Javadoc)
   * @see org.openmicroscopy.imageviewer.ImageWidget#clearImage()
   */
  public void clearImage()
  {
    this.displayImage = null;
    repaint();
  }
  
  public double getZoomLevel()
  {
    return zoomLevel;
  }
  
  public void setZoomLevel(double factor)
  {
    zoomToFit = false;
    zoomLevel = factor;
    zoomTransform = AffineTransform.getScaleInstance(zoomLevel,zoomLevel);
    zoomOp = new AffineTransformOp(zoomTransform,
                                   AffineTransformOp.TYPE_BILINEAR);
    // cheap hack to reset-- might break eventually
    displayImage(displayImage);
  }
  
  public void zoomToFit()
  {
    JScrollPane pane = container.getImagePane();
    int width = pane.getWidth()-5;
    int height = pane.getHeight()-5;
    
    int imageWidth = displayImage.getWidth();
    int imageHeight = displayImage.getHeight();
    
    double scaleX = ((double)width/(double)imageWidth);
    double scaleY = ((double)height/(double)imageHeight);
    
    setZoomLevel(Math.min(scaleX,scaleY));
    zoomToFit = true;
    container.updateLabel(Math.min(scaleX,scaleY));
  }


}