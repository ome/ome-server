/*
 * org.openmicroscopy.alligator.ViewEditFrame
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

//import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

public abstract class ViewEditFrame
    extends JFrame
    implements ActionListener
{
    public ViewEditFrame(String title)
    {
        super(title);
    }

    public abstract void view();
    public abstract void edit();
    public boolean validateEntries() { return true; }
    public abstract void apply();
    public void revert() {}

    public void actionPerformed(ActionEvent e)
    {
        String cmd = e.getActionCommand();

        if (cmd.equals("Edit"))
        {
            edit();
        } else if (cmd.equals("Apply")) {
            if (validateEntries())
            {
                apply();
                view();
            }
        } else if (cmd.equals("Revert")) {
            revert();
            view();
        }
    }
}
