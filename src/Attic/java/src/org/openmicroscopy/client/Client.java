/*
 * org.openmicroscopy.client.Client
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

/**
 * Creates and displays an OME client workstation. Instantiates a
 * member of the OMEClientShow class, and immediately passes off
 *
 * all further responsiblities to that instance.
 * @see org.openmicroscopy.client.ClientShow
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   OME 2.0.3
 */


public class Client extends JPanel {

    public static void main(String[] args) {
	ClientShow ourClient = new ClientShow();
	ourClient.LoginAndShow();
    }

  public Client() {

  }
}

