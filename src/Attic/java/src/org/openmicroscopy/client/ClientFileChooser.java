/*
 * org.openmicroscopy.client.ClientFileChooser
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
 * Written by:    Brian S. Hughes <bshughes@mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.client;

import java.io.*;
import java.io.File;
import java.awt.*;
import java.awt.event.*;
import java.util.Vector;
import javax.swing.*;
import javax.swing.filechooser.*;

// open.gif found in C:\j2sdk1.4.2_01\demo\jfc\Notepad\resources


public class ClientFileChooser {
    private JFileChooser fc = new JFileChooser();
    private Vector files = new Vector();
    private static String motifClassName = "com.sun.java.swing.plaf.motif.MotifLookAndFeel";
    
    public ClientFileChooser() {

	fc.setDialogType(JFileChooser.OPEN_DIALOG);
	fc.setAcceptAllFileFilterUsed(true);
	fc.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
	fc.setMultiSelectionEnabled(false);
    }
    
    public Vector getFiles(String prompt) {
	fc.setDialogTitle(prompt);
	int retval = fc.showOpenDialog(null);
	if (retval == JFileChooser.APPROVE_OPTION) {
	    if (fc.isMultiSelectionEnabled()) {
		files.add(fc.getSelectedFiles());
	    } else {
		files.add(fc.getSelectedFile());
	    }
	} else if (retval == JFileChooser.ERROR_OPTION) {
	    JOptionPane.showMessageDialog(null, "No file chosen due to error conditions");

	}

	return files;
    }
}
