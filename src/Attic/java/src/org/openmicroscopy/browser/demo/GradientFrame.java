/*
 * org.openmicroscopy.browser.demo.GradientFrame
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
import java.awt.Dimension;
import java.awt.Font;
import java.awt.GradientPaint;
import java.awt.Graphics;
import java.awt.Graphics2D;

import javax.swing.JFrame;
import javax.swing.JPanel;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version
 * @since
 */
public class GradientFrame extends JFrame
{
  public GradientFrame()
  {
    super("");
    setSize(125,375);
    getContentPane().setLayout(new BorderLayout());
    
    getContentPane().add(new GradientPanel("MAX_BRIGHT",37,255));
  }
}

class GradientPanel extends JPanel
{
  private String feature;
  private int min;
  private int max;
  
  public GradientPanel(String feature, int min, int max)
  {
    this.feature = feature;
    this.min = min;
    this.max = max;
    setPreferredSize(new Dimension(150,350));
  }
  
  public void paintComponent(Graphics g)
  {
    super.paintComponent(g);
    Graphics2D g2 = (Graphics2D)g;
    
    g2.setPaint(new GradientPaint(75f,50f,Color.BLUE,75f,350f,Color.RED));
    g2.drawRect(5,25,75,300);
    g2.setColor(Color.BLACK);
    g2.drawString(String.valueOf(max),90,35);
    g2.drawString(String.valueOf(min),90,315);

    g2.setFont(new Font(null,Font.BOLD,12));
    g2.drawString(feature,25,15);
  }
}