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
import org.openmicroscopy.vis.ome.CProject;
import org.openmicroscopy.vis.ome.events.DatasetSelectionEvent;
import org.openmicroscopy.vis.ome.events.DatasetSelectionEventListener;
import org.openmicroscopy.vis.piccolo.PBrowserCanvas;
import java.util.List;
import java.util.Vector;
import javax.swing.JFrame;
import javax.swing.JButton;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.ListCellRenderer;
import javax.swing.JList;
import javax.swing.JToolBar;
import javax.swing.BoxLayout;
import javax.swing.ListSelectionModel;
import javax.swing.JScrollPane;
import javax.swing.Box;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;
import javax.swing.event.EventListenerList;
import java.awt.Container;
import java.awt.Dimension;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;
import java.awt.Component;
import java.awt.Font;
import java.util.Iterator;
import java.util.HashSet;

/** 
 * A Control panel for the chain builder visualization
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ControlPanel extends JFrame implements ListSelectionListener, 
	MouseListener {
	
	protected JLabel statusLabel;
	protected JPanel panel;
	
	protected JButton newChainButton;
	
	protected JButton viewResultsButton;
	
	protected final JList projList;
	protected final JList datasetList;
	
	
	protected CProject curProject;
	protected CDataset curDataset;
	
	private Controller controller;
	private Connection connection;
	
	private PBrowserCanvas browser;
	
	private Vector projects;
	private Vector datasets;
	
	boolean reentrant = false;
	
	private EventListenerList datasetListeners  =
		new EventListenerList();
		
	private HashSet selectedDatasets = new HashSet();
	private HashSet deselectedDatasets;
	private HashSet newSelectedDatasets;
		
	/**
	 * 
	 * @param cmd The hash table linking strings to actions
	 */
	public ControlPanel(Controller controller,Connection connection) {
		super("OME Chains: Menu Bar");
		this.controller = controller;
		this.connection = connection;
		Container content = getContentPane();
		content.setLayout(new BoxLayout(content,BoxLayout.Y_AXIS));
		
		JToolBar toolBar = buildToolBar();
		
		content.add(toolBar);
		
		JPanel topPanel = new JPanel();
		
		topPanel.setLayout(new BoxLayout(topPanel,BoxLayout.X_AXIS));
	
		
		
		// projects
		JPanel projectPanel = new JPanel();
		
		projectPanel.setLayout(new BoxLayout(projectPanel,BoxLayout.Y_AXIS));
		JLabel projectLabel = new JLabel("Projects");
		projectLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
		projectPanel.add(projectLabel);
		
		projectPanel.add(Box.createRigidArea(new Dimension(0,3)));
		
 		getProjects(connection);
		projList = new JList(projects);
		projList.setAlignmentX(Component.LEFT_ALIGNMENT);
		projList.setSelectionMode(ListSelectionModel.SINGLE_INTERVAL_SELECTION);
		projList.setVisibleRowCount(-1);
		projList.setLayoutOrientation(JList.VERTICAL);
		
		projList.setCellRenderer(new ProjectRenderer());
		projList.addListSelectionListener(this);
		JScrollPane projScroller = new JScrollPane(projList);
		projScroller.setMinimumSize(new Dimension(100,200));
		projScroller.setAlignmentX(Component.LEFT_ALIGNMENT);
		projectPanel.add(projScroller);

		
		topPanel.add(projectPanel);
		topPanel.add(Box.createRigidArea(new Dimension(5,0)));
		
		//dataset
		getDatasets(connection);
		JPanel datasetPanel = new JPanel();
		datasetPanel.setLayout(new BoxLayout(datasetPanel,BoxLayout.Y_AXIS));
		JLabel datasetLabel = new JLabel("Datasets");
		datasetLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
		datasetPanel.add(datasetLabel);
		datasetPanel.add(Box.createRigidArea(new Dimension(0,3)));
		datasetList = new JList(datasets);
		datasetList.setAlignmentX(Component.LEFT_ALIGNMENT);
		datasetList.setSelectionMode(ListSelectionModel.SINGLE_INTERVAL_SELECTION);
		datasetList.setVisibleRowCount(-1);
		datasetList.setLayoutOrientation(JList.VERTICAL);
		datasetList.addListSelectionListener(this);
		datasetList.addMouseListener(this);
		datasetList.setCellRenderer(new DatasetRenderer());
		JScrollPane datasetScroll = new JScrollPane(datasetList);
		datasetScroll.setMinimumSize(new Dimension(100,200));
		datasetScroll.setAlignmentX(Component.LEFT_ALIGNMENT);
		datasetPanel.add(datasetScroll);
		//datasetList.addListSelectionListener(this);
		
		
		topPanel.add(datasetPanel);
			
		topPanel.add(Box.createRigidArea(new Dimension(5,0)));
		
		JPanel imagePanel = new JPanel();
		imagePanel.setLayout(new BoxLayout(imagePanel,BoxLayout.Y_AXIS));
		JLabel browserLabel = new JLabel("Representative Thumbnails...");
		browserLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
		imagePanel.add(browserLabel);
		imagePanel.add(Box.createRigidArea(new Dimension(0,3)));
		browser = new PBrowserCanvas(connection);
		browser.setPreferredSize(new Dimension(400,400));
		imagePanel.add(browser);
		topPanel.add(imagePanel);
		content.add(topPanel);
		pack();
		show();
	
		setResizable(false);
		addDatasetSelectionEventListener(browser);
		addDatasetSelectionEventListener(connection);
	}
	
	private JToolBar buildToolBar() {
		JToolBar tool = new JToolBar();
		tool.setFloatable(false);
		tool.setLayout(new BoxLayout(tool,BoxLayout.X_AXIS));
		
		//	control butons
		newChainButton = new JButton("New Chain");
		newChainButton.addActionListener(
		 controller.getCmdTable().lookupActionListener("new chain"));
		newChainButton.setEnabled(false);
		tool.add(newChainButton);
		
		tool.add(Box.createRigidArea(new Dimension(10,0)));		
		viewResultsButton = new JButton("View Results");
		viewResultsButton.addActionListener(
			 controller.getCmdTable().lookupActionListener("view results"));
		viewResultsButton.setEnabled(false);
		tool.add(viewResultsButton);
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
		tool.add(statusLabel);
	
		
		return tool;
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
	
	public void getProjects(Connection connection) {
		
		List p  = connection.getProjectsForUser();
		curProject =(CProject) p.get(0);
		projects = new Vector(p);
	}
	
	public void getDatasets(Connection connection) {
		List d = connection.getDatasetsForUser();
		//curDataset = (CDataset) d.get(0);
		datasets = new Vector(d);
	}
	
	
	
	public void valueChanged(ListSelectionEvent e) {
		
		if (reentrant == true) 
			return;
		Object obj = e.getSource();
		if (!(obj instanceof JList)) 
			return;
		JList list = (JList) obj;
		
		Object item = list.getSelectedValue();
		
		if (list == projList)
			updateProjectChoice(item);
		else if (list == datasetList) 
			updateDatasetChoice(item);
		
	} 
		
	public void  updateProjectChoice(Object item) {
		deselectedDatasets = new HashSet();
		newSelectedDatasets = new HashSet();
		setCurProjectDatasetsActive(false);
		
		curProject = (CProject) item;
		if (curDataset ==null)
			clearProjectActiveFlags();
		
		setCurProjectDatasetsActive(true);
			
		int pos = projects.indexOf(curProject);
		
		reentrant =true;
		projList.setSelectedIndex(pos);
		if (curDataset!= null && !curDataset.isInCurrentProject()) {
			datasetList.clearSelection();
			clearProjectActiveFlags();
			clearCurDataset();
		}
		reentrant =false;
		datasetList.repaint();
		projList.repaint();
		browser.displayDatasets();
		connection.clearDatasets();
		fireEvents();
		selectedDatasets.addAll(newSelectedDatasets);
	}
	
	public void updateDatasetChoice(Object item) {
		deselectedDatasets = new HashSet();
		newSelectedDatasets = new HashSet();
		int pos = -1;
	
		if (curDataset != null)
			curDataset.setProjectsActive(false);
			
		clearCurDataset();
		
		if (item != null)
			setCurDataset((CDataset) item);
		
		if (curDataset != null) {
			curDataset.setProjectsActive(true);
			pos = datasets.indexOf(curDataset);
			System.err.println("selecting dataset "+curDataset.getName());
		}
		
		reentrant =true;
		datasetList.setSelectedIndex(pos);
		if (curProject != null && curProject.isInCurrentDataset()==false) {
			projList.clearSelection();
			System.err.println("setting current project to nulll..");
			curProject = null;
			clearDatasetActiveFlags();
		}
		reentrant =false;
		
		//	update the list of executions
		//connection.setDataset(curDataset);	
		
		datasetList.repaint();
		projList.repaint();
		connection.clearDatasets();
		fireEvents();
		selectedDatasets.addAll(newSelectedDatasets);
		browser.displayDatasets();
	}
	
	private void clearDatasetActiveFlags() {
		Iterator iter = datasets.iterator();
		CDataset d;
		while (iter.hasNext()) {
			d = (CDataset) iter.next();
			d.setInCurrentProject(false);
		}
	}
	
	private void clearProjectActiveFlags() {
		Iterator iter = projects.iterator();
		CProject p;
		while (iter.hasNext()) {
			p = (CProject) iter.next();
			p.setInCurrentDataset(false);
		}
	}
	
	private void setCurProjectDatasetsActive(boolean b) {
		if (curProject == null) 
			return;
		List d = curProject.getDatasets();
		Iterator i = d.iterator();
		while (i.hasNext()) {
			CDataset ds = (CDataset) i.next();
			ds.setInCurrentProject(b);
			addToSelectedDatasets(ds,b);
		}
	}
	
	private void addToSelectedDatasets(CDataset ds,boolean b) {
		if (ds == null) return;
		
		if (b ==true) {// add to new selection
			if (selectedDatasets.contains(ds))
				return; // don't need to add it if we already have it in the list
			if (deselectedDatasets.contains(ds))
				deselectedDatasets.remove(ds);
			newSelectedDatasets.add(ds);
		}
		else {// it's begin deselected
			if (selectedDatasets.contains(ds))
				selectedDatasets.remove(ds);
			if (newSelectedDatasets.contains(ds))
				newSelectedDatasets.remove(ds);
			deselectedDatasets.add(ds);
		}		
	}
		
	// mouse listener so we can handle double-click to deselect from list. 
	// this isn't terribly efficient, as the current dataset will get deselected 
	// and reselected, but anything else is too complicated. 
	public void mouseClicked(MouseEvent e) {
		if (e.getClickCount() == 2) {
			int index =datasetList.locationToIndex(e.getPoint());
			if (index == datasetList.getSelectedIndex()) {
				//deselect dataset 
				CProject tmp = curProject;
				reentrant = true;
				datasetList.clearSelection();
				reentrant = false;
				updateProjectChoice(tmp);
			}
		}
	}
	public void mouseEntered(MouseEvent e) {
	}
	
	public void mouseExited(MouseEvent e) {
	}
	
	public void mousePressed(MouseEvent e) {
	}
	
	public void mouseReleased(MouseEvent e) {
	}
	
	public void addDatasetSelectionEventListener(DatasetSelectionEventListener
		listener) {
			datasetListeners.add(DatasetSelectionEventListener.class,
				listener);
	}
	
	public void removeDatasetSelectionEventListener(DatasetSelectionEventListener
		listener) {
			datasetListeners.remove(DatasetSelectionEventListener.class,
				listener);
	}
	
	public void fireDatasetSelectionEvent(DatasetSelectionEvent e) {
		Object[] listeners=datasetListeners.getListenerList();
		for (int i = listeners.length-2; i >=0; i-=2) {
			if (listeners[i] == DatasetSelectionEventListener.class) {
				((DatasetSelectionEventListener) listeners[i+1]).
					datasetSelectionChanged(e);
			}
		}
	}
	
	private void clearCurDataset() {

		if (curDataset!=null) { 
			addToSelectedDatasets(curDataset,false);
		}
		curDataset=null;
	}
	
	private void setCurDataset(CDataset c) {
		if (curProject != null)
			setCurProjectDatasetsActive(false);
		curDataset=c;
		if (curDataset != null) {
			addToSelectedDatasets(curDataset,true);
		}	
	}
	
	private void fireEvents() {
		fireEvents(deselectedDatasets,false);
		fireEvents(newSelectedDatasets,true);
	}
	
	private void fireEvents(HashSet set,boolean b) {
		Iterator iter = set.iterator();
		while (iter.hasNext()) {
			CDataset d = (CDataset) iter.next();
			DatasetSelectionEvent e  = new DatasetSelectionEvent(d,b);
			fireDatasetSelectionEvent(e);
		}			
	}
	
}

class ProjectRenderer  extends JLabel implements ListCellRenderer {
	
	private Font plainFont = new Font(null,Font.PLAIN,10);
	private Font activeFont = new Font(null,Font.BOLD,12);
	
	public ProjectRenderer() {
		setOpaque(true);
		setHorizontalAlignment(SwingConstants.LEFT);
		setVerticalAlignment(SwingConstants.CENTER);
	}
	
	public Component getListCellRendererComponent(JList list,
			Object value,int index,boolean isSelected,
				boolean cellHasFocus) {
			CProject p = (CProject) value;
			
			if (p.isInCurrentDataset())
				setFont(activeFont);
			else
				setFont(plainFont);
			if (isSelected) {
				setBackground(list.getSelectionBackground());
				setForeground(list.getSelectionForeground());
				setFont(activeFont);
			} else {
				setBackground(list.getBackground());
				setForeground(list.getForeground());
			}
			setText(p.getName()); 
			return this;
	}
}

class DatasetRenderer  extends JLabel implements ListCellRenderer {
	
	private Font plainFont = new Font(null,Font.PLAIN,10);
	private Font activeFont = new Font(null,Font.BOLD,12);
	
	public DatasetRenderer() {
		setOpaque(true);
		setHorizontalAlignment(SwingConstants.LEFT);
		setVerticalAlignment(SwingConstants.CENTER);
	}
	
	public Component getListCellRendererComponent(JList list,
			Object value,int index,boolean isSelected,
				boolean cellHasFocus) {
			setFont(plainFont);
			if (value instanceof CDataset) {
				CDataset d = (CDataset) value;
				setText(d.getName());
				if (d.isInCurrentProject()) {
					setFont(activeFont);
				}
			}
			else 
				setText("None");
			if (isSelected) {
				setBackground(list.getSelectionBackground());
				setForeground(list.getSelectionForeground());
				setFont(activeFont);
			} else {
				setBackground(list.getBackground());
				setForeground(list.getForeground());
			}
						 
			return this;
	}
}