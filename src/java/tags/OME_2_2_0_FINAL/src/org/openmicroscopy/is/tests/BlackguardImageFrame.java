/*
 * org.openmicroscopy.is.tests.BlackguardControlFrame
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.is.tests;

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;

public class BlackguardImageFrame
    extends JFrame
{
    private Image image = null;

    private class ImageComponent
        extends JComponent
    {
        private ImageComponent() { super(); }

        public void paint(Graphics g)
        {
            if (image != null)
                g.drawImage(image,0,0,null);
        }

        public Dimension getPreferredSize()
        {
            if (image != null)
                return new Dimension(image.getWidth(null),
                                     image.getHeight(null));
            else
                return new Dimension(0,0);
        }
    }

    private ImageComponent ic;

    public BlackguardImageFrame()
    {
        super("Image");

        Container cp = getContentPane();
        cp.setLayout(new BorderLayout());

        ic = new ImageComponent();
        JScrollPane scroll = new JScrollPane
            (ic,
             JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
             JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS);
        cp.add(scroll,BorderLayout.CENTER);

        setDefaultCloseOperation(EXIT_ON_CLOSE);
    }

    public void setImage(Image image)
    {
        this.image = image;
        ic.revalidate();
        ic.repaint();
    }
}