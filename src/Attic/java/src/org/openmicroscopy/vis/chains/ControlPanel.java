/*
 * org.openmicroscopy.vis.chains.ControlPanel
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee¶
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
 * Written by:    Harry Hochheiser <hsh@nih.gov>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.vis.chains;

import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.piccolo.PBrowserCanvas;
import org.openmicroscopy.vis.piccolo.PProjectSelectionCanvas;
import java.util.List;
import java.util.Vector;
import javax.swing.JFrame;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.JToolBar;
import javax.swing.BoxLayout;
import javax.swing.Box;
import javax.swing.JSplitPane;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.Component;


/** 
 * A Control panel for the chain builder visualization
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ControlPanel extends JFrame  {
	
	private static final int BROWSER_SIDE=400;
	protected JLabel statusLabel;
	
	protected JPanel panel;
	
	protected JButton newChainButton;
	
	//protected JButton viewResultsButton;
	
	
	
	
	private Controller controller;
	
	private PBrowserCanvas browser;
	
	private Vector projects;
	
	private PProjectSelectionCanvas projCanvas = null;
	
	private JSplitPane split = null;
	/**
	 * 
	 * @param cmd The hash table linking strings to actions
	 */
	public ControlPanel(Controller controller,Connection connection) {
		super("OME Chains: Menu Bar");
		this.controller = controller;
		Container content = getContentPane();
		content.setLayout(new BoxLayout(content,BoxLayout.Y_AXIS));
		
		
		JToolBar toolBar = buildToolBar();
		
		content.add(toolBar);
		
		// projects
		getProjects(connection);
		if (projects.size() > 0) {
			//add project list right here.
			projCanvas =  new PProjectSelectionCanvas(this,projects);
			//content.add(projCanvas);
		}
		System.err.println("tool bar width is "+toolBar.getWidth());
		browser = new PBrowserCanvas(connection);
		browser.setPreferredSize(new Dimension(BROWSER_SIDE,BROWSER_SIDE));
		//content.add(browser);
		
		if (projCanvas == null)
			content.add(browser);
		else {
			split = new JSplitPane(JSplitPane.VERTICAL_SPLIT,
				projCanvas,browser);
				
			split.setOneTouchExpandable(true);
			split.setResizeWeight(0.33);
			split.setAlignmentX(Component.CENTER_ALIGNMENT);
			content.add(split);
		}
		pack();
		show();
	
		if (projCanvas != null) 
			projCanvas.layoutLabels();// projlist, dataset list
	}



	public void completeInitialization() {
		browser.displayAllDatasets();	
		SelectionState selectionState = SelectionState.getState();
		selectionState.addSelectionEventListener(browser);
	}
	
	private JToolBar buildToolBar() {
		JToolBar tool = new JToolBar();
		tool.setFloatable(false);
		tool.setLayout(new BoxLayout(tool,BoxLayout.X_AXIS));
		
		//	control butons
		newChainButton = new JButton("New Chain");
		newChainButton.addActionListener(
		 controller.getCmdTable().lookupActionListener("new chain"));
		newChainButton.setEnabled(true);
		tool.add(newChainButton);
		
		tool.add(Box.createRigidArea(new Dimension(10,0)));		
		tool.add(Box.createRigidArea(new Dimension(10,0)));
		//Logout
		
		JButton logout = new JButton("Logout");
		tool.add(logout);
		logout.addActionListener(
			controller.getCmdTable().lookupActionListener("logout"));
		
		tool.add(Box.createRigidArea(new Dimension(30,0)));	
		statusLabel = new JLabel();
		statusLabel.setHorizontalAlignment(SwingConstants.LEFT);
		statusLabel.setMinimumSize(new Dimension(150,30));
		statusLabel.setPreferredSize(new Dimension(150,30));
		tool.add(Box.createHorizontalGlue());
		tool.add(statusLabel);
	
		
		return tool;
	}
	
	public void setDividerLocation(int h) {
		if (split != null)
			split.setDividerLocation(h);
	}
	
	
	
	/**
	 * set the status to be logged in
	 */
	public void setLoggedIn(String s) {
		statusLabel.setText(s);
	}
	
		
	private void getProjects(Connection connection) {
		
		List p  = connection.getProjectsForUser();
		projects = new Vector(p);
	}	
}
