/*
 * org.openmicroscopy.vis.chains.Toolbar
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
 * Written by:    Harry Hochheiser <hsh@nih.gov>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.vis.chains;

import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.chains.Controller;
import org.openmicroscopy.Project;
import org.openmicroscopy.Dataset;
import java.util.List;
import javax.swing.JFrame;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JComboBox;
import javax.swing.DefaultComboBoxModel;
import javax.swing.SwingConstants;
import javax.swing.ListCellRenderer;
import javax.swing.JList;
import java.awt.GridLayout;
import java.awt.BorderLayout;
import java.awt.FlowLayout;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.Component;

/** 
 * A Control panel for the chain builder visualization
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ControlPanel extends JFrame implements ActionListener {
	
	protected JLabel statusLabel;
	protected JPanel panel;
	
	protected JButton newChainButton;
	
	protected JButton viewResultsButton;
	
	protected JComboBox projList;
	protected JComboBox datasetList;
	
	
	protected Project curProject;
	protected CDataset curDataset;
	
	private Connection connection;
	
	private Controller controller;
	/**
	 * 
	 * @param cmd The hash table linking strings to actions
	 */
	public ControlPanel(Controller controller,Connection connection) {
		super("OME Chains: Menu Bar");
		this.connection=connection;
		this.controller = controller;
		
		Container content = getContentPane();
		content.setLayout(new BorderLayout());
		
		JPanel topPanel = new JPanel();
		
		topPanel.setLayout(new GridLayout(0,2,10,10));
		
		JLabel userLabel = new JLabel("OME User:");
		topPanel.add(userLabel);
		
		statusLabel = new JLabel();
		statusLabel.setHorizontalAlignment(SwingConstants.LEFT);
		statusLabel.setMinimumSize(new Dimension(150,30));
		statusLabel.setPreferredSize(new Dimension(150,30));
		topPanel.add(statusLabel);
		
		// projects
		JLabel projectLabel = new JLabel("Projects");
		topPanel.add(projectLabel); 
		Object[] projects = getProjects();
		projList = new JComboBox(projects);
		projList.setRenderer(new ProjectRenderer());
		projList.addActionListener(this);
		projList.setMaximumSize(projList.getMinimumSize());
		projList.setEditable(false);
		topPanel.add(projList);
		
		//dataset
		JLabel datasetLabel = new JLabel("Datasets");
		topPanel.add(datasetLabel);
		datasetList = new JComboBox();
		datasetList.setRenderer(new DatasetRenderer());
		datasetList.setEditable(false);
		datasetList.setMaximumSize(datasetList.getMinimumSize());
		topPanel.add(datasetList);
		datasetList.addActionListener(this);
		updateProjectChoice(curProject);
		
		
		// control butons
		newChainButton = new JButton("New Chain");
		newChainButton.addActionListener(
			controller.getCmdTable().lookupActionListener("new chain"));
		newChainButton.setEnabled(false);
		topPanel.add(newChainButton);
		
		
		
		viewResultsButton = new JButton("View Results");
		viewResultsButton.
			addActionListener(
				controller.getCmdTable().lookupActionListener("view results"));
		viewResultsButton.setEnabled(false);
		topPanel.add(viewResultsButton);
		
		content.add(topPanel,BorderLayout.NORTH);
		//Logout
		
		JPanel logoutPanel = new JPanel();
		logoutPanel.setLayout(new FlowLayout(FlowLayout.RIGHT,0,5));
		JButton logout = new JButton("Logout");
		logoutPanel.add(logout);
		logout.addActionListener(controller.getCmdTable().lookupActionListener("logout"));
		content.add(logoutPanel,BorderLayout.SOUTH);
		
		pack();
		show();
	
		setResizable(false);
		
	}
	
	/**
	 * set the status to be logged in
	 */
	public void setLoggedIn(String s) {
		statusLabel.setText(s);
	}
	
	/**
	 * Set the state of the New chain button
	 * @param v true if button should be enabled. else false.
	 */
	public void setEnabled(boolean v) {
		newChainButton.setEnabled(v);
		viewResultsButton.setEnabled(v);
	}
	
	public Object[] getProjects() {
		Object[] a = new Object[0];
		
		List projects  = connection.getProjectsForUser();
		a = projects.toArray(a);
		curProject = (Project) a[0];
		return a;
	}
	
	public void actionPerformed(ActionEvent e) {
		
		Object obj = e.getSource();
		if (!(obj instanceof JComboBox)) 
			return;
		JComboBox cb = (JComboBox) obj;
		Object item = cb.getSelectedItem();
		if (cb == projList)
			updateProjectChoice(item);
		else if (cb == datasetList) 
			updateDatasetChoice(item);
	}
		
	public void  updateProjectChoice(Object item) {
		curProject = (Project) item;
		List datasets = curProject.getDatasets();
		Object[] a = new Object[0];
		a = datasets.toArray(a);
		DefaultComboBoxModel model = new DefaultComboBoxModel(a);
		datasetList.setModel(model);
		curDataset = (CDataset) a[0];
		curDataset.loadImages(connection);
		updateDatasetChoice(curDataset);
	}
	
	public void updateDatasetChoice(Object item) {
		
		System.err.println("getting execution list");
		curDataset = (CDataset) item;
		// update the list of executions
		connection.setDataset(curDataset);	
	}
}

class ProjectRenderer  extends JLabel implements ListCellRenderer {
	
	public ProjectRenderer() {
		setOpaque(true);
		setHorizontalAlignment(SwingConstants.LEFT);
		setVerticalAlignment(SwingConstants.CENTER);
	}
	
	public Component getListCellRendererComponent(JList list,
			Object value,int index,boolean isSelected,
				boolean cellHasFocus) {
			Project p = (Project) value;
			
			if (isSelected) {
				setBackground(list.getSelectionBackground());
				setForeground(list.getSelectionForeground());
			} else {
				setBackground(list.getBackground());
				setForeground(list.getForeground());
			}
			setText(p.getName()); 
			return this;
	}
}

class DatasetRenderer  extends JLabel implements ListCellRenderer {
	
	public DatasetRenderer() {
		setOpaque(true);
		setHorizontalAlignment(SwingConstants.LEFT);
		setVerticalAlignment(SwingConstants.CENTER);
	}
	
	public Component getListCellRendererComponent(JList list,
			Object value,int index,boolean isSelected,
				boolean cellHasFocus) {
			if (value instanceof Dataset) {
				Dataset d = (Dataset) value;
				setText(d.getName());
			}
			else 
				setText("None");
			if (isSelected) {
				setBackground(list.getSelectionBackground());
				setForeground(list.getSelectionForeground());
			} else {
				setBackground(list.getBackground());
				setForeground(list.getForeground());
			}
			 
			return this;
	}
}