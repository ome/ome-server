/*
 * org.openmicroscopy.browser.demo.AnnotationFrame
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
import java.awt.FlowLayout;
import java.awt.Font;

import javax.swing.Box;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version
 * @since
 */
public class AnnotationFrame extends JFrame
{
  public AnnotationFrame()
  {
    super("Make Annotation");
    setSize(300,175);
    
    getContentPane().setLayout(new BorderLayout());
    
    getContentPane().add(Box.createHorizontalStrut(10),BorderLayout.WEST);
    getContentPane().add(Box.createHorizontalStrut(10),BorderLayout.EAST);
    
    JPanel panel = new JPanel();
    panel.setLayout(new BorderLayout());
    
    panel.add(Box.createHorizontalStrut(5),BorderLayout.WEST);
    panel.add(Box.createVerticalStrut(10),BorderLayout.NORTH);
    panel.add(Box.createVerticalStrut(5),BorderLayout.SOUTH);
    
    JLabel label = new JLabel("Enter annotation (well D7):");
    label.setFont(new Font(label.getFont().getFontName(),
                           Font.BOLD,
                           label.getFont().getSize()));
                   
    panel.add(label,BorderLayout.CENTER);
    
    getContentPane().add(panel,BorderLayout.NORTH);
    
    JPanel buttonPanel = new JPanel();
    buttonPanel.setLayout(new FlowLayout(FlowLayout.RIGHT));
    buttonPanel.add(Box.createHorizontalGlue());
    buttonPanel.add(new JButton("Annotate"));
    buttonPanel.add(Box.createHorizontalStrut(10));
    
    getContentPane().add(buttonPanel,BorderLayout.SOUTH);
    
    JTextArea textArea = new JTextArea(4,25);
    JScrollPane pane = new JScrollPane(textArea);
    getContentPane().add(pane,BorderLayout.CENTER);
  }
}
