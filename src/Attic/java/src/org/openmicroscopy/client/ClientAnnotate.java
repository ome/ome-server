/*
 * org.openmicroscopy.simple.client
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
 * Handles creating and editing the annotation (description) field of
 * a semantic type.
 * Creates a filled in dialog box in which to edit a semantic type's
 * annotation. It contains both the (pretty useless) default constructor
 * and a constructor that takes in two strings that are displayed
 * as identification to the user.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   2.0.3
 */

public class ClientAnnotate extends JDialog implements ActionListener {


    private JDialog annotateBox;
    private String entityName = "";
    private String entityDescription = "";
    private Container contentPane;
    private String experimenter;
    private String group;
    private String annotateType;
    private String nameEntity;
    private JTextField nameField;
    private JTextArea  descField;
    private JFrame annotateParent;
    private GridBagLayout gridBag = new GridBagLayout();
    private GridBagConstraints c = new GridBagConstraints();
    private JComboBox jComboBox1 = new JComboBox();
    private DataAccess accessor;

    public ClientAnnotate() {
    }

    public ClientAnnotate(String annotateEntity, String name) {
	/**
	 * Contructs an annotation editing window.
	 * @param annotateEntity    semantic type of instance being edited
	 * @param name              name of the instance being edited
	 */
	annotateType = annotateEntity;
	nameEntity = name;
	try {
	    jbInit();
	}
	catch(Exception e) {
	    e.printStackTrace();
	}
    }


    /**
     *  Handles user pressing "OK" or "Cancel".
     * @param ActionEvent e
     */

    public void actionPerformed(ActionEvent e) {
	if ("cancel".equals(e.getActionCommand())) {
	    annotateBox.dispose();
	} else {
	    // Promote user's selection back to main frame
	    annotateBox.setVisible(false);
	}
    }

    
    /**
     *  Handles the implementation details for the constructor.
     */
    private void jbInit() throws Exception {
	JLabel label;
	Font f;

	annotateBox = new JDialog((Frame)null, annotateType+" Creator", true);

	contentPane = annotateBox.getContentPane();
	contentPane.setLayout(gridBag);
	c.fill = GridBagConstraints.NONE;

	// Box's title
	label = new JLabel(annotateType + " annotate");
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

	// Display entity owner's Group
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

    // Display entity owner
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

    // Display entity's name
	label = new JLabel(annotateType + " name");
	f = label.getFont().deriveFont(Font.BOLD, 14f);
	label.setFont(f);
	c.gridx = 0;
	c.gridy = 3;
	c.gridwidth = 1;
	c.anchor = GridBagConstraints.WEST;
	c.insets = new Insets(5,10,0,0);
	gridBag.setConstraints(label, c);
	contentPane.add(label);

	nameField = new JTextField(nameEntity);
	c.gridx = 2;
	c.gridy = 3;
	c.gridwidth = 2;
	c.insets = new Insets(5, 6, 0, 5);
	gridBag.setConstraints(nameField, c);
	contentPane.add(nameField);

	// Display entity's current annotation (description field)
	label = new JLabel(annotateType + " description");
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




}
