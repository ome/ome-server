/*
 * org.openmicroscopy.browser.demo.BrowserMockup
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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
package org.openmicroscopy.browser.demo;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.FlowLayout;

import javax.swing.Box;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JToolBar;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version
 * @since
 */
public class BrowserMockup extends JFrame
{
  public BrowserMockup()
  {
    super("Image Browser");
    setSize(600,600);
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    
    getContentPane().setLayout(new BorderLayout());
    getContentPane().add(Box.createHorizontalStrut(10),BorderLayout.WEST);
    getContentPane().add(Box.createHorizontalStrut(10),BorderLayout.EAST);
    getContentPane().add(Box.createVerticalStrut(10),BorderLayout.SOUTH);
    
    JPanel toolPanel = new JPanel();
    toolPanel.setLayout(new FlowLayout(FlowLayout.LEFT));
    JToolBar toolBar = new JToolBar();
    toolBar.add(new JButton("+"));
    toolBar.add(new JButton("-"));
    toolBar.add(new JButton("M"));
    
    toolPanel.add(toolBar);
    
    JPanel imagePanel = new JPanel();
    imagePanel.setBackground(new Color(192,224,255));
    
    getContentPane().add(imagePanel,BorderLayout.CENTER);
    getContentPane().add(toolPanel,BorderLayout.NORTH);
  }
}
