/*
 * org.openmicroscopy.client.ClientShow
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

import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;
import java.awt.event.WindowListener;

/**
 * Brings up an OME workstation. First prompts for the username under
 * which to log in, and that user's password. If the OME server
 * verifies the login information, then create and display the main
 * workstation window.
 * @see ClientLogin
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   OME 2.0.3
 */

public class ClientShow extends JPanel {
    JFrame        clientFrame = new JFrame("OME");
    ClientLogin      ourLogin;
    Image         folderIcon;
    GridBagLayout gridBag = new GridBagLayout();

    public ClientShow() {
	/**
	 * Create the base workstation.
	 */
        clientFrame.addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent e) {
		    ourLogin.logout();
		}
	    });
	
    }

    /**
     * Instantiate a ClientLogin class to get the user logged in,
     * create the workstation window, fill it in, and display it.
     * @see ClientLogin
     */

    public void LoginAndShow(){
        ourLogin = new ClientLogin("Please enter OME name and password",
                                   "OME Login");
        if (ourLogin.isLoggedIn())
        {

	  clientFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
          JPanel clientPanel = (JPanel)clientFrame.getContentPane();
          clientPanel.setLayout(gridBag);
	  clientPanel.setOpaque(true);

          new ClientContents(clientPanel, ourLogin);

          clientFrame.pack();
          clientFrame.setSize(850, 550);
          clientFrame.setVisible(true);
        }
    }

}


