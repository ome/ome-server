/*
 * org.openmicroscopy.imageviewer.ui.ZoomImagePanel
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
import java.text.NumberFormat;

import javax.swing.*;

/**
 * Encapsulates an ImagePanel within a scrolling and zoom control.
 * Use the zooming mechanism
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class ZoomImagePanel extends JPanel
{
  private ScrollableImagePane internalPanel;
  private ImageController controller;
  private JScrollPane scrollPane;
  
  private JButton zoomInButton;
  private JButton zoomOutButton;
  private JButton zoom100Button;
  private JButton zoomFitButton;
  private JLabel zoomAmountLabel;
  
  public ZoomImagePanel()
  {
    setSize(600,600);
    setPreferredSize(new Dimension(600,600));
    
    setLayout(new BorderLayout(0,0));
    ImagePanel panel = new ImagePanel(this);
    internalPanel = new ScrollableImagePane(panel);
    add(internalPanel,BorderLayout.CENTER);
    controller = ImageController.getInstance();
    controller.setImageWidget(internalPanel);
    
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
        }
      }
    });
    
    zoom100Button.addActionListener(new ActionListener() {
      public void actionPerformed(ActionEvent ae)
      {
        double oldLevel = internalPanel.getZoomLevel();
        internalPanel.setZoomLevel(1);
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
    
    internalPanel.addComponentListener(new ComponentAdapter()
    {
      public void componentResized(ComponentEvent ce)
      {
        updateLabel(internalPanel.getZoomLevel());
      }
    });
    
    add(zoomPanel,BorderLayout.SOUTH);
  }
  
  void updateLabel(double zoomFactor)
  {
    NumberFormat format = NumberFormat.getPercentInstance();
    format.setMaximumFractionDigits(0);
    zoomAmountLabel.setText("Zoom: " +format.format(zoomFactor));
  }
}