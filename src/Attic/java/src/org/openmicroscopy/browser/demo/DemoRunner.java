/*
 * org.openmicroscopy.browser.demo.DemoRunner
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

import javax.swing.JFrame;
import javax.swing.UIManager;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version
 * @since
 */
public class DemoRunner
{
  public static void main(String[] args)
  {
    try
    {
      UIManager.setLookAndFeel("com.birosoft.liquid.LiquidLookAndFeel");
    }
    catch(Exception e)
    { 
      System.out.println("Unable to load the Liquid L&F:");
      e.printStackTrace();
      System.out.println("Default L&F will be used.");
    }
    JFrame browser = new BrowserMockup();
    JFrame frame = new AttributeFrame();
    JFrame gradient = new GradientFrame();
    JFrame annotator = new AnnotationFrame();
    frame.pack();
    frame.show();
    gradient.pack();
    gradient.show();
    browser.show();
    annotator.show();
  }
}
