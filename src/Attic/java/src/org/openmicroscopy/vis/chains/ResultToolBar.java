/*
 * org.openmicroscopy.vis.chains.ResultToolbar
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
import org.openmicroscopy.Project;
import org.openmicroscopy.Dataset;
import javax.swing.Box;
import javax.swing.JToolBar;
import javax.swing.JLabel;
import javax.swing.JComboBox;
import javax.swing.JList;
import javax.swing.ListCellRenderer;
import javax.swing.SwingConstants;
import javax.swing.DefaultComboBoxModel;
import java.awt.Dimension;
import java.awt.Component;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.List;

/** 
 * Toolbar for a {@link ChainFrame}. This toolbar contains a "save" button
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ResultToolBar extends JToolBar implements ActionListener{
	
	protected Connection connection;
	
	protected CmdTable cmd;
	
	protected JComboBox projList;
	protected JComboBox datasetList;
	protected JComboBox execList;
	
	protected JLabel chainName;
	
	protected Project curProject;
	protected Dataset curDataset;
	/**
	 * 
	 * @param cmd The hash table linking strings to actions
	 */
	public ResultToolBar(CmdTable cmd,Connection connection) {
		super();
		this.cmd=cmd;
		this.connection = connection;
		
		Dimension dim = new Dimension(5,0);
		
		add(Box.createRigidArea(dim));
	
		JLabel projectLabel = new JLabel("Projects");
		add(projectLabel);
		
		add(Box.createRigidArea(dim));
		String[] data = {"NONE"};
		
		Object[] projects = getProjects();
	
		projList = new JComboBox(projects);
		projList.setRenderer(new ProjectRenderer());
		projList.
			addActionListener(this);
		projList.setMaximumSize(projList.getMinimumSize());
		projList.setEditable(false);
		add(projList);
		add(Box.createRigidArea(dim));
		
		JLabel datasetLabel = new JLabel("Datasets");
		add(datasetLabel);
		add(Box.createRigidArea(dim));
		datasetList = new JComboBox();
		datasetList.setRenderer(new DatasetRenderer());
		datasetList.setEditable(false);
		datasetList.setMaximumSize(datasetList.getMinimumSize());
		updateProjectChoice(curProject);
		add(datasetList);
		datasetList.addActionListener(this);
		
		
		add(Box.createRigidArea(dim));
		add(Box.createHorizontalGlue());
		JLabel chains = new JLabel("Chain: ");
		add(chains);

		chainName = new JLabel("None");
		
		add(chainName);
		add(Box.createRigidArea(dim));
		JLabel exes = new JLabel("Executions");
		add(exes);
			
		execList = new JComboBox(data);
		execList.addActionListener(this);
		execList.setEditable(false);
		execList.setMaximumSize(execList.getMinimumSize());
		add(execList);
		add(Box.createRigidArea(dim));	
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
		else if (cb == execList) 
			updateExecutionChoice(item);
		
	}
	
	public void  updateProjectChoice(Object item) {
		curProject = (Project) item;
		List datasets = curProject.getDatasets();
		Object[] a = new Object[0];
		a = datasets.toArray(a);
		DefaultComboBoxModel model = new DefaultComboBoxModel(a);
		datasetList.setModel(model);
	}
	
	public void updateDatasetChoice(Object item) {
	}
	
	public void updateExecutionChoice(Object item) {
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