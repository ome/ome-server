/*
 * org.openmicroscopy.client.ClientSelect
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
import java.net.*;
import java.util.Iterator;
import java.util.HashMap;
import java.util.Vector;
import java.util.List;
import javax.swing.*;
import javax.swing.border.*;
import org.openmicroscopy.*;
import org.openmicroscopy.remote.*;

/** Handles workstation select boxes -- creates them with proper fields,
 * populates them from remote data, and gets user selections. Workstation
 * uses these select boxes for most entity population tasks.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   2.0.3
 */

public class ClientSelect extends JDialog implements ActionListener {
  protected  JDialog selectBox;
  private String Selection;
    private OMEObject selectedObject = null;
  private int    selectIndex;
    private Vector [] entLists;
  private JList itemList;
  private JComboBox jComboe, jCombog;
  private JButton button;
  private JTextField selectionFld;
  private TitledBorder titledBorder1;
  private String selectType;
  private Font f;
  private GridBagLayout gridBag = new GridBagLayout();
  private GridBagConstraints c = new GridBagConstraints();
  private String myself;
  private String mygroup;
  ClientContents ourClient;
  DataAccess  Accessor;
  HashMap selectDT;
  HashMap selectFN;


    /** Instantiates nothing visible; useful only for callers wanting
     * access to class methods such as database lookups. At some point
     * those routines should be moved over to the DataAccess class.
     *
     * @param ourClient  current instantiation of ClientContents
     */

    public ClientSelect(ClientContents ourClient) {
	setupDTMap();
	setupFNMap();
	Accessor = ourClient.ourLogin.getAccessor();
    }


    /** Instantiates a select box for a particular entity, supplied with
     * the current ClientContents context. Both environmental data, such
     * as the workstation user's experimenter name, and the set of items
     * to be the select list are retrieved from the remote server.
     *
     * @param selectEntity  the name of the selection category, such as Project
     * @param OMEclient the current ClientContents context
     */
  public ClientSelect(String selectEntity, ClientContents OMEclient) {
    ourClient = OMEclient;
    selectType = selectEntity;
    Accessor = ourClient.ourLogin.getAccessor();
    myself = ourClient.ourLogin.getExperimenter();
    mygroup = ourClient.ourLogin.getGroup();
    setupDTMap();
    setupFNMap();
    try {
	jbInit();
    }
    catch(Exception e) {
      e.printStackTrace();
    }
  }
  private void jbInit() throws Exception {
    JLabel label;
    int    arrIndex;
    String selectEntity = selectType;
    //OMELookup Finder = new OMELookup(conn);

    Selection = "";
    selectBox = new JDialog((Frame)(null), selectEntity+" Selector", true);

    //this.setBorder(BorderFactory.createLineBorder(Color.black));
    //this.setPreferredSize(new Dimension(400, 300));
    Container contentPane = selectBox.getContentPane();
    contentPane.setLayout(gridBag);
    c.fill = GridBagConstraints.HORIZONTAL;

    label = new JLabel(selectType + " select");
    f = label.getFont().deriveFont(Font.BOLD, 22f);
    label.setFont(f);
    c.gridx = 0;
    c.gridy = 0;
    c.gridwidth = 5;
    c.anchor = GridBagConstraints.CENTER;
    c.insets = new Insets(3,140,0,0);  //top padding
    gridBag.setConstraints(label, c);
    contentPane.add(label);

    label = new JLabel("Look in");
    f = label.getFont().deriveFont(Font.BOLD, 14f);
    label.setFont(f);
    c.gridx = 0;
    c.gridy = 1;
    c.gridwidth = 2;
    c.anchor = GridBagConstraints.CENTER; //bottom of space
    c.insets = new Insets(10,30,0,0);  //top padding
    gridBag.setConstraints(label, c);
    contentPane.add(label);

    entLists = getEntityList(selectType);
    itemList = new JList(entLists[0]);
    Font dsFont = new Font("Dialog", Font.BOLD, 12);
    itemList.setFont(dsFont);
    MouseListener mouseListener = new MouseAdapter() {
       public void mouseClicked(MouseEvent e) {
         Selection = (String)itemList.getSelectedValue();
         if (e.getClickCount() == 2) {
           int index = itemList.locationToIndex(e.getPoint());
	   SetSelection(index, itemList);
         }
       }
   };
   itemList.addMouseListener(mouseListener);
    JScrollPane jScroll = new JScrollPane(itemList);
    jScroll.getViewport().setBackground(Color.white);
    jScroll.setPreferredSize(new Dimension(250, 200));
    //Finder.Find(selectType);
    c.gridx = 3;
    c.gridy = 1;
    c.gridwidth = 2;
    c.gridheight = 5;
    c.insets = new Insets(10,5,10,3);  //top padding
    gridBag.setConstraints(jScroll, c);
    contentPane.add(jScroll);

    label = new JLabel("Experimenter");
    c.gridx = 0;
    c.gridy = 2;
    c.gridwidth = 2;
    c.gridheight = 1;
    c.anchor = GridBagConstraints.CENTER; //bottom of space
    c.insets = new Insets(10,5,0,0);  //top padding
    gridBag.setConstraints(label, c);
    contentPane.add(label);

    Vector experimenters = getExperimenters();
    jComboe = new JComboBox(experimenters);
    jComboe.setEditable(true);
    c.gridx = 0;
    c.gridy = 3;
    c.gridwidth = 2;
    c.insets = new Insets(5,5,0,0);  //top padding
    gridBag.setConstraints(jComboe, c);
    jComboe.insertItemAt("all",0);
    arrIndex = experimenters.indexOf(myself);
    System.err.println("Index of "+myself+" is: "+arrIndex);
    //arrIndex = exps.indexOf(myself);
    if (arrIndex++ == -1) {
	arrIndex = 0;
    }
    arrIndex = 0;
    //jComboe.setSelectedIndex(arrIndex);

    contentPane.add(jComboe);

    label = new JLabel("Group");
    c.gridx = 0;
    c.gridy = 4;
    c.gridwidth = 2;
    c.insets = new Insets(10,5,0,0);  //top padding
    gridBag.setConstraints(label, c);
    contentPane.add(label);


    Vector groups = getGroups();
    jCombog = new JComboBox(groups);
    jCombog.setEditable(true);
    c.gridx = 0;
    c.gridy = 5;
    c.gridwidth = 2;
    c.anchor = GridBagConstraints.NORTH; //top of space
    c.insets = new Insets(5,5,40,0);  //bottom padding
    gridBag.setConstraints(jCombog, c);
    jCombog.insertItemAt("all",0);
    arrIndex = experimenters.indexOf(mygroup);
    if (arrIndex == -1) {
	jCombog.setSelectedIndex(0);
    } else {
	jCombog.setSelectedIndex(arrIndex);
    }
    contentPane.add(jCombog);

    JButton buttonOK = new JButton("OK");
    buttonOK.setActionCommand("do_it");
    c.gridx = 0;
    c.gridy = 5;
    c.gridwidth = 1;
    c.anchor = GridBagConstraints.CENTER; //bottom of space
    c.insets = new Insets(45,5,0,0);  //top padding
    gridBag.setConstraints(buttonOK, c);
    contentPane.add(buttonOK);

    JButton buttonCancel = new JButton("Cancel");
    buttonCancel.setActionCommand("cancel");
    c.gridx = 1;
    c.gridy = 5;
    gridBag.setConstraints(buttonCancel, c);
    contentPane.add(buttonCancel);

    buttonOK.addActionListener(this);
    buttonCancel.addActionListener(this);

/*    label = new JLabel("Selection");
    c.gridx = 2;
    c.gridy = 6;
    c.gridwidth = 2;
    c.insets = new Insets(0,5,0,0);  //top padding
    //c.anchor = GridBagConstraints.EAST; //bottom of space
    gridBag.setConstraints(label, c);
    contentPane.add(label);

    selectionFld = new JTextField("");
    c.gridx = 4;
    c.gridy = 6;
    c.anchor = GridBagConstraints.WEST; //bottom of space
    c.ipadx = 30;
    c.insets = new Insets(0,0,0,3);  //top padding
    gridBag.setConstraints(selectionFld, c);
    contentPane.add(selectionFld);
*/
    selectBox.pack();

    Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
    Dimension frameSize = selectBox.getSize();
    if (frameSize.height > screenSize.height)
      frameSize.height = screenSize.height;
    if (frameSize.width > screenSize.width)
      frameSize.width = screenSize.width;
    selectBox.setLocation((screenSize.width - frameSize.width) / 2, (screenSize.height - frameSize.height) / 2);


  }

    /**
     * Makes the select box visible and the active window, keeps control until
     * dismissed or selection made. Returns the selection and automatically
     * terminates the selection box.
     *
     * @return OMEObject the object representing the selected item
     */
    public OMEObject getSelection () {
	selectBox.setVisible(true);
	System.err.println("\treturning selection: " + Selection +"\n");
	return selectedObject;
    }


    /** Provides the actionPerformed function required by the runtime
     *  to handle the selection box.
     *  @param e ActionEvent supplied by the runtime when an action occurs
     */
    public void actionPerformed(ActionEvent e) {
	if ("cancel".equals(e.getActionCommand())) {
	    selectBox.dispose();
	} else {
	    int index = itemList.getMaxSelectionIndex();
	    SetSelection(index, itemList);
	    selectBox.setVisible(false);
	}
    }


    /**
     * Looks up all entities (objects) of the requested type and
     * returns a list of their names, & a list of the entities themselves.
     * Internally, does a Accessor.LookupSet and then iterates over that set
     * to populate the return vectors. A supposedly equivalent method calls
     * Accessor.IterateSet to return an iterator directly. Unfortunately,
     * the remote iterator was not getting released between accesses, leading
     * to lists that could be traversed only once during an entire session.
     * @param selectType the name of the entity type (Project, Image, etc) to
     * select from
     * @return array of Vectors -- vector of object names, and vector of
     *  representations of the objects themselves.
     */
    public Vector [] getEntityList (String selectType) {
	OMEObject obj;
	Vector entities;
	Vector names = new Vector();
	HashMap criteria = new HashMap();

	String dataType = (String)selectDT.get(selectType);
	String fieldName = (String)selectFN.get(selectType);
	entities = new Vector(Accessor.LookupSet(dataType, null));
	Iterator i = entities.iterator();
	while (i.hasNext()) {
	  names.add(nameOf((OMEObject)i.next(), selectType));
	}
	return new Vector [] {names, entities};
    }


    private void SetSelection (int index, JList list) {
	selectIndex = index;
	Selection = (String)itemList.getSelectedValue();
	selectedObject = (OMEObject)entLists[1].get(index);
	System.err.println("\tSelected: "+ Selection +"from "+selectedObject+"\n");
	selectBox.setVisible(false);
    }


    // Get name of object
    private String nameOf(OMEObject obj, String type) {
	if (type.equals("Projects")) {
	    return ((org.openmicroscopy.Project)obj).getName();
	} else if (type.equals("Datasets")) {
	    return ((org.openmicroscopy.Dataset)obj).getName();
	} else if (type.equals("Images")) {
	    return ((org.openmicroscopy.Image)obj).getName();
	} else if (type.equals("Analyses")) {
	    return ((org.openmicroscopy.Chain)obj).getName();
	} else {
	    return "";
	}
    }
	

    // Set up Name to Data Type map
    private void setupDTMap() {
	selectDT = new HashMap();

	selectDT.put("Experimenters", "OME::Experimenters");
	selectDT.put("Groups", "OME::Groups");
	selectDT.put("Projects", "OME::Project");
	selectDT.put("Datasets", "OME::Dataset");
	selectDT.put("Images"  , "OME::Image");
	selectDT.put("Analyses", "OME::AnalysisChain");
    }

    // Set up Data Type to Field name
    private void setupFNMap() {
	selectFN = new HashMap();

	selectFN.put("Projects", "name");
	selectFN.put("Datasets", "name");
	selectFN.put("Images"  , "name");
	selectFN.put("Analyses", "name");
    }


    private Vector getExperimenters() throws Exception {
	Vector names = 	getAttributePair("Experimenter", "FirstName", "LastName");
	return names;
    }

    private Vector getGroups() {
	return(getAttributes("Group", "Name" ));
    }

    private Vector getAttributes(String attrType, String attrElement) {
	List attrList;
	Vector names = new Vector();
	int tries = 3;

	while (tries-- > 0) {
	    try {
		attrList = Accessor.bindings.getFactory().findAttributes(attrType, (java.util.Map)null);
	    } catch (RemoteException re) {
		continue;
	    }
	    Iterator i = attrList.iterator();
	    while (i.hasNext()) {
		names.add(((RemoteAttribute)i.next()).getStringElement(attrElement));
	    }
	    break;
	}
	if (tries == 0) {
	    System.err.println("Failed to find "+attrType+" in remote server");
	}

	return(names);
    }

    private Vector getAttributePair(String attrType, String attrElement1,
				     String attrElement2) {
	List attrList;
	Vector names = new Vector();
	attrList = Accessor.bindings.getFactory().findAttributes(attrType, (java.util.Map)null);
	Iterator i = attrList.iterator();
	while (i.hasNext()) {
	    RemoteAttribute ra = (RemoteAttribute)i.next();
	    String el1 = ra.getStringElement(attrElement1);
	    String el2 = ra.getStringElement(attrElement2);
	    String pair = new String(el1+" "+el2);
	    names.add(pair);
	}
	return(names);	
    }


    private int findInArray(String [] where, String what) {
	int i;
	int len = where.length;
	for (i = 0; i < len; i++) {
	    if (what.equals(where[i])) {
		break;
	    }
	}
	if (i == len) {
	    i = -1;
	}

	return i;
    }

}


