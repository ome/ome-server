/*
 * org.openmicroscopy.alligator.Alligator
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




package org.openmicroscopy.alligator;

public class Alligator
{
    public static void main(String[] args)
    {
        System.out.println("OME Alligator v2.0");
        System.out.println("Copyright (c) 2003 Open Microscopy Environment");

        System.setProperty("com.apple.mrj.application.apple.menu.about.name",
                           "OME Alligator");
        System.setProperty("com.apple.mrj.application.live-resize","true");
        System.setProperty("com.apple.mrj.application.growbox.intrudes","true");
        System.setProperty("apple.laf.useScreenMenuBar","true");

        Controller controller = new Controller();

        MainFrame mainFrame = new MainFrame(controller);
        mainFrame.setSize(512,600);
        mainFrame.setVisible(true);

        controller.initialize();
    }

}
