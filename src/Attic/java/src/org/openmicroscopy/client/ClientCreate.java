/*
 * org.openmicroscopy.client.ClientCreate
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
import java.util.HashMap;
import javax.swing.*;
import javax.swing.border.*;
import org.openmicroscopy.*;


/**
 * Makes and handles Create dialog boxes to create various entities.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   2.0.3
 */

public class ClientCreate extends JDialog implements ActionListener {
    protected JDialog createBox;
    protected String entityName = "";
    protected String entityDescription = "";
    protected Container contentPane;
    private String experimenter;
    private String group;
    private String createType;
    protected JTextField nameField;
    protected JTextArea  descField;
    private JFrame createParent;
    protected GridBagLayout gridBag = new GridBagLayout();
    private GridBagConstraints c = new GridBagConstraints();
    private JComboBox jComboBox1 = new JComboBox();
    protected DataAccess accessor;


    public ClientCreate() {
	
    }

    /**
     *  Instantiates a ClientCreate class for a particular entity type,
     * owned by a particular user and group.
     */
    
    public ClientCreate(String createEntity,
                   String experimenter, String group) {
	createType = createEntity;
	//createParent = parent;
	this.experimenter = experimenter;
	this.group = group;
	try {
	    jbInit();
	}
	catch(Exception e) {
	    e.printStackTrace();
	}
    }

    /**
     * Handles actions in the Create box. Only the runtime should
     * call this method, since only it knows when an action happened.
     * @param e the ActionEvent that occurred in the box.
     */
    public void actionPerformed(ActionEvent e) {
	if ("cancel".equals(e.getActionCommand())) {
	    createBox.dispose();
	} else {
	    createBox.setVisible(false);
	    // Promote user's selection back to main frame
	}
    }

    private void jbInit() throws Exception {
	JLabel label;
	Font f;

	createBox = new JDialog((Frame)null, createType+" Creator", true);

	contentPane = createBox.getContentPane();
	contentPane.setLayout(gridBag);
	c.fill = GridBagConstraints.NONE;


	label = new JLabel(createType + " create");
	f = label.getFont().deriveFont(Font.BOLD, 22f);
	label.setFont(f);
	c.gridx = 0;
	c.gridy = 0;
	c.gridwidth = 3;
	c.gridheight = 1;
	c.anchor = GridBagConstraints.CENTER;
	c.insets = new Insets(3,100,10,0);
	gridBag.setConstraints(label, c);
	contentPane.add(label);

	label = new JLabel("Group");
	f = label.getFont().deriveFont(Font.BOLD, 14f);
	label.setFont(f);
	c.gridx = 0;
	c.gridy = 1;
	c.gridwidth = 1;
	c.anchor = GridBagConstraints.WEST;
	c.insets = new Insets(5,10,0,0);
	gridBag.setConstraints(label, c);
	contentPane.add(label);

	label = new JLabel(this.group);
	f = label.getFont().deriveFont(Font.BOLD, 14f);
	label.setFont(f);
	c.gridx = 2;
	c.gridy = 1;
	c.gridwidth = 1;
	c.anchor = GridBagConstraints.WEST;
	c.insets = new Insets(5,10,0,0);
	gridBag.setConstraints(label, c);
	contentPane.add(label);

	label = new JLabel("Experimenter");
	f = label.getFont().deriveFont(Font.BOLD, 14f);
	label.setFont(f);
	c.gridx = 0;
	c.gridy = 2;
	c.gridwidth = 1;
	c.anchor = GridBagConstraints.WEST;
	c.insets = new Insets(5,10,0,0);
	gridBag.setConstraints(label, c);
	contentPane.add(label);

	label = new JLabel(this.experimenter);
	f = label.getFont().deriveFont(Font.BOLD, 14f);
	label.setFont(f);
	c.gridx = 2;
	c.gridy = 2;
	c.gridwidth = 1;
	c.anchor = GridBagConstraints.WEST;
	c.insets = new Insets(5,10,0,0);
	gridBag.setConstraints(label, c);
	contentPane.add(label);

	label = new JLabel(createType + " name");
	f = label.getFont().deriveFont(Font.BOLD, 14f);
	label.setFont(f);
	c.gridx = 0;
	c.gridy = 3;
	c.gridwidth = 1;
	c.anchor = GridBagConstraints.WEST;
	c.insets = new Insets(5,10,0,0);
	gridBag.setConstraints(label, c);
	contentPane.add(label);

	nameField = new JTextField(20);
	c.gridx = 2;
	c.gridy = 3;
	c.gridwidth = 2;
	c.insets = new Insets(5, 6, 0, 5);
	gridBag.setConstraints(nameField, c);
	contentPane.add(nameField);

	label = new JLabel(createType + " description");
	label.setFont(f);
	c.gridx = 0;
	c.gridy = 4;
	c.gridwidth = 1;
	c.anchor = GridBagConstraints.WEST; //bottom of space
	c.insets = new Insets(4,10,0,0);
	gridBag.setConstraints(label, c);
	contentPane.add(label);

	descField = new JTextArea(3, 20);
	c.gridx = 2;
	c.gridy = 4;
	c.gridwidth = 2;
	c.insets = new Insets(4, 6, 0, 5);
	descField.setBorder(new EtchedBorder());
	descField.setLineWrap(true);
	gridBag.setConstraints(descField, c);
	contentPane.add(descField);

    }

    /**
     * Gathers the user's inputs, and makes the requested entity, recording
     * it in the remote server's database.
     *
     * @param Accessor the remote DataAccess (RemoteBinding) to the server
     */

    public OMEObject getSelection (DataAccess Accessor) {

	accessor = Accessor;
	// OK & Cancel
	JPanel okPanel = new JPanel();
	JButton buttonOK = new JButton("OK");
	buttonOK.setActionCommand("do_it");
	JButton buttonCancel = new JButton("Cancel");
	buttonCancel.setActionCommand("cancel");
	okPanel.add(buttonOK);
	okPanel.add(buttonCancel);
	c.gridx = 0;
	c.gridy = 6;
	c.gridwidth = 4;
	c.anchor = GridBagConstraints.CENTER; //bottom of space
	gridBag.setConstraints(okPanel, c);
	contentPane.add(okPanel);
	buttonOK.addActionListener(this);
	buttonCancel.addActionListener(this);

	createBox.pack();
	Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
	Dimension frameSize = createBox.getSize();
	if (frameSize.height > screenSize.height)
	    frameSize.height = screenSize.height;
	if (frameSize.width > screenSize.width)
	    frameSize.width = screenSize.width;
	createBox.setLocation((screenSize.width - frameSize.width) / 2, (screenSize.height - frameSize.height) / 2);
	createBox.setVisible(true);

	entityName = nameField.getText();
	entityDescription = descField.getText();
	return (makeObject(entityName, entityDescription));
    }



    private OMEObject makeObject (String name, String description) {
	if (createType.equals("Project")) {
	    return makeProject(name, description);
	} else if (createType.equals("Dataset")) {
	    return makeDataset(name, description);
	} else {
	    return null;
	}
    }

    private OMEObject makeObject(String type, HashMap map, String name, String description) {
	HashMap fldMap = map;
	OMEObject obj = null;

	fldMap.put("name", name);
	fldMap.put("description", description);
	// !!! Kludge !!! //
	fldMap.put("owner_id", "1");
	try {
	    obj = accessor.bindings.getFactory().newObject(type, fldMap);
	    System.err.println("Factory made object");
	    obj.writeObject();
	    System.err.println("wrote object");
	}
	catch (Exception e) {
	    System.err.println("Exception in makeObject: " + e.toString());
	    obj = null;
	}

	return obj;
    }

    private Project makeProject (String name, String description) {
	Project newP = null;
	HashMap fldMap = new HashMap();

	newP = (Project)makeObject("OME::Project", fldMap, name, description);
	return newP;
    }

    private Dataset makeDataset (String name, String description) {
	Dataset newD = null;
	HashMap fldMap = new HashMap();

	fldMap.put("locked", "false");
	newD = (Dataset)makeObject("OME::Dataset", fldMap, name, description);
	return newD;
    }


}
