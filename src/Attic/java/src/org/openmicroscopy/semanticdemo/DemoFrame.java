/*
 * org.openmicroscopy.semanticdemo.DemoFrame
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

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;

import org.openmicroscopy.imageviewer.ui.*;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public class DemoFrame extends JFrame
{
  private DataController controller;
  
  public DemoFrame()
  {
    setSize(800,600);
    setTitle("Semantic Visualization Demo");
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    
    Container container = getContentPane();
    container.setLayout(new BorderLayout());
    
    JPanel imageTopPanel = new JPanel();
    OverlayImagePanel panel = new OverlayImagePanel(imageTopPanel);
    imageTopPanel.add(new ScrollableImagePane(panel));
    container.add(imageTopPanel,BorderLayout.CENTER);
    controller = new DataController(panel);
    
    final JList theList = new JList(controller.getOverlayNames());
    
    theList.addListSelectionListener(new ListSelectionListener()
    {
      /* (non-Javadoc)
       * @see javax.swing.event.ListSelectionListener#valueChanged(javax.swing.event.ListSelectionEvent)
       */
      public void valueChanged(ListSelectionEvent e)
      {
        String type = (String)theList.getSelectedValue();
        controller.loadOverlays(type);
      }
    });
    
    JPanel listPanel = new JPanel();
    listPanel.setLayout(new FlowLayout(FlowLayout.LEFT,5,5));
    theList.setBorder(BorderFactory.createTitledBorder("Display types"));
    container.add(theList,BorderLayout.EAST);
  }
}
