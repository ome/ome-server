/*
 * org.openmicroscopy.client.ClientCreateDS
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
import java.awt.font.*;
import javax.swing.*;
import javax.swing.border.*;
import org.openmicroscopy.*;


/**
 * Creates a ClientCreate box to guide the user through creating a dataset.
 * Extends ClientCreate.
 * @see ClientCreate
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   2.0.3
 */
public class ClientCreateDS extends ClientCreate implements ActionListener {
  private Container contentPane;
  private GridBagLayout gridBag;
  private GridBagConstraints c = new GridBagConstraints();
  protected ClientCreate createBox;


    /** Constructs a ClientCreateDS initialized with values.
     * Blindly catches all exceptions, and dumps a stack trace in response.
     * @param createEntity the type of entity to create 
     * @param experimenter the new dataset's owner's name
     * @param group the name of the owner's group
     */
  public ClientCreateDS(String createEntity,
                     String experimenter, String group) {
    try {
      createBox = new ClientCreate(createEntity, experimenter, group);
      contentPane = createBox.contentPane;
      gridBag = createBox.gridBag;
      jbInit();
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }

    /**
     * Displays the dataset creation box, and causes the dataset
     * to be created if the user actually creates one.
     * @param Accessor active DataAccess (RemoteBinding)
     * @see ClientCreate
     */
  public OMEObject getSelection (DataAccess Accessor) {
    return (createBox.getSelection(Accessor));

  }

  private void jbInit() throws Exception {

    c.fill = GridBagConstraints.NONE;
    JButton importButton = new JButton("Import");
    importButton.setToolTipText("Import images into this new dataset");
    c.gridx = 0;
    c.gridy = 6;
    c.gridwidth = 1;
    c.gridheight = 1;
    c.anchor = GridBagConstraints.WEST;
    c.insets = new Insets(7,30,0,0);
    gridBag.setConstraints(importButton, c);
    contentPane.add(importButton);

  }
}

