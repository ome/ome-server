/*
 * org.openmicroscopy.client.ClientViewPane
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
import java.awt.geom.*;
import java.awt.font.*;
import java.awt.event.*;
import java.util.Vector;
import java.util.Iterator;
import javax.swing.border.*;
import javax.swing.JScrollPane;
import javax.swing.*;
import org.openmicroscopy.*;


/**
 *  Switches between instances of viewer panes.
 *  Extends JPanel.
 *  @see ClientViewerPane
 *
 * @author  Brian S. Hughes
 * @version 2.0
 * @since   2.0.3
 */

public class ClientViewPane  extends JPanel {
    /**
     * ClientContents instance context of this pane
     */
    ClientContents ourClient;
    /**
     * DataAccess instance to use for populating this pane
     */
    DataAccess accessor;
    /**
     * Currently active (probably visible) ClientViewerPane instance
     */
    ClientViewerPane currPane = null;


    public ClientViewPane() {

    }

    /**
     *  Contructs an instance of a view pane, ready to be filled in.
     * Give it a border and a BorderLayout.
     *
     * @param Client a ClientContents instance
     * @param Accessor a DataAccess instance (a RemoteBinding)
     * @see ClientContents
     * @see DataAccess
     */
    public ClientViewPane (ClientContents Client, DataAccess Accessor) {
      	ourClient = Client;
	accessor = Accessor;

	setBorder(BorderFactory.createEtchedBorder());
	setLayout(new BorderLayout());
	setBackground(new Color(238, 238, 238));
  }

    /**
     * Add a pane to the viewer pane
     *
     * @param pane ClientViewerPane instance to add
     */
    public void addPane (ClientViewerPane pane) {
	currPane = pane;
	JScrollPane vPane = new JScrollPane(pane);
	Dimension pdim = new Dimension();
	pdim = pane.getSize();
	vPane.setPreferredSize(pdim);
	add(vPane, BorderLayout.CENTER);
    }

    /**
     * Remove a pane from the viewer pane
     */
    public void removePane() {
	if (currPane != null) {
	    currPane = null;
	    int cnt = getComponentCount();
	    System.err.println("  has " + cnt + " components");
	    remove(cnt-1);
	}
    }
}
