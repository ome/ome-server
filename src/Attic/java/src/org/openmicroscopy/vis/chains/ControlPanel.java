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
//import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.chains.events.SelectionEvent;
import org.openmicroscopy.vis.chains.events.SelectionEventListener;
import org.openmicroscopy.vis.piccolo.PBrowserCanvas;
import org.openmicroscopy.Project;
//import org.openmicroscopy.ChainExecution;
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
import java.awt.Container;
import java.awt.Dimension;
import java.awt.event.MouseListener;
import java.awt.event.MouseEvent;
import java.awt.Component;
import java.awt.Font;
import java.util.Collection;


/** 
 * A Control panel for the chain builder visualization
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class ControlPanel extends JFrame implements ListSelectionListener, 
	MouseListener, SelectionEventListener {
	
	protected JLabel statusLabel;
	protected JPanel panel;
	
	protected JButton newChainButton;
	
	//protected JButton viewResultsButton;
	
	protected JList projList=null;
	protected JList datasetList;
	
	
	
	private Controller controller;
	
	private PBrowserCanvas browser;
	
	private Vector projects;
	private Vector datasets;
	
	private boolean reentrant = false;
	
	/// in theory, we don't need to keep state around of 
	// current project and current dataset.
	// as it's all in the SelectionState.
	// In practice, it makes the coding a bit easier.
	// This does present a risk of inconsistency, but it seems to work ok.
	
	private Project curProject;
	private CDataset curDataset=null;
		
	
	private SelectionState selectionState;
	/**
	 * 
	 * @param cmd The hash table linking strings to actions
	 */
	public ControlPanel(Controller controller,Connection connection) {
		super("OME Chains: Menu Bar");
		this.controller = controller;
		Container content = getContentPane();
		content.setLayout(new BoxLayout(content,BoxLayout.Y_AXIS));
		
		selectionState = new SelectionState();
		
		JToolBar toolBar = buildToolBar();
		
		content.add(toolBar);
		
		JPanel topPanel = new JPanel();
		
		topPanel.setLayout(new BoxLayout(topPanel,BoxLayout.X_AXIS));
	
		
		
		// projects
		getProjects(connection);
		if (projects.size() > 0) {
			JPanel projectPanel = new JPanel();
		
			projectPanel.setLayout(new BoxLayout(projectPanel,BoxLayout.Y_AXIS));
			JLabel projectLabel = new JLabel("Projects");
			projectLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
			projectPanel.add(projectLabel);
		
			projectPanel.add(Box.createRigidArea(new Dimension(0,3)));
		
 	
			projList = new JList(projects);
			projList.setAlignmentX(Component.LEFT_ALIGNMENT);
			projList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
			projList.setVisibleRowCount(-1);
			projList.setLayoutOrientation(JList.VERTICAL);
			
			projList.setCellRenderer(new ProjectRenderer(selectionState));
			projList.addListSelectionListener(this);
			projList.addMouseListener(this);
			JScrollPane projScroller = new JScrollPane(projList);
			projScroller.setMinimumSize(new Dimension(100,200));
			projScroller.setAlignmentX(Component.LEFT_ALIGNMENT);
			projectPanel.add(projScroller);
	
			
			topPanel.add(projectPanel);
		}
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
		datasetList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
		datasetList.setVisibleRowCount(-1);
		datasetList.setLayoutOrientation(JList.VERTICAL);
		datasetList.addListSelectionListener(this);
		datasetList.addMouseListener(this);
		datasetList.setCellRenderer(new DatasetRenderer(selectionState));
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

		browser.displayAllDatasets();	

		selectionState.addSelectionEventListener(this);		
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
		/*viewResultsButton = new JButton("View Results");
		viewResultsButton.addActionListener(
			 controller.getCmdTable().lookupActionListener("view results"));
		viewResultsButton.setEnabled(true);
		tool.add(viewResultsButton);*/
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
	
	
		
	private void getProjects(Connection connection) {
		
		List p  = connection.getProjectsForUser();
		if (p != null && p.size() > 0) {
			curProject =(Project) p.get(0);
		}
		projects = new Vector(p);
	}
	
	private void getDatasets(Connection connection) {
		List d = connection.getDatasetsForUser();
		datasets = new Vector(d);
	}
	
	
	
	public void valueChanged(ListSelectionEvent e) {
		
		System.err.println("got an event with value changed..");
		System.err.println("reentrant is "+ reentrant);
		System.err.println("value adjusting is "+e.getValueIsAdjusting()); 
		if ( e.getValueIsAdjusting() == true) // or reentrant == true 
			return;
		Object obj = e.getSource();
		System.err.println("value changed source is "+obj);
		if (!(obj instanceof JList)) 
			return;
		JList list = (JList) obj;
		
		Object item = list.getSelectedValue();
		System.err.println("selected item is "+item);
		System.err.println("selected index is "+list.getSelectedIndex());
		

		if (list == projList)
			selectionState.setSelectedProject((Project) item);
		else 
			selectionState.setSelectedDataset((CDataset) item);
	} 	

	public SelectionState getSelectionState() {
		return selectionState;
	}
		
	
	// mouse listener so we can handle double-click to deselect from list. 
	// this isn't terribly efficient, as the current dataset will get deselected 
	// and reselected, but anything else is too complicated. 
	public void mouseClicked(MouseEvent e) {
		if (e.getClickCount() == 2) {
			if (e.getSource() == datasetList)
				doDatasetDoubleClick(e);
			else if (e.getSource() == projList)
				doProjectDoubleClick(e);
		}
	}
	
	private void doDatasetDoubleClick(MouseEvent e) {
		int index =datasetList.locationToIndex(e.getPoint());
		if (index == datasetList.getSelectedIndex()) {
			selectionState.setSelectedDataset(null);
		}
	}

	private void doProjectDoubleClick(MouseEvent e) {
		int index = projList.locationToIndex(e.getPoint());	
		if (index == projList.getSelectedIndex()) {
			selectionState.setSelectedProject(null);
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
	
	/*// we're going to set the datasets to be those that are
	// associated with the current chain.
	public void chainSelectionChanged(ChainSelectionEvent e) {
		
		CChain chain = e.getChain();
		System.err.println("changing to chain.."+chain.getName());
				
		if (e.getStatus() == ChainSelectionEvent.SELECTED) {
			//change active datasets
			reentrant = true;
			datasetList.clearSelection();
			if (projList !=null)
				projList.clearSelection();
			curDataset = null;
			if (projList != null)
				projList.clearSelection();
			reentrant = false;
			activeProjects =null;
			activeDatasets=new HashSet(chain.getDatasetsWithExecutions());
			System.err.println("active datasets"+activeDatasets.size());
			if (activeDatasets.size() ==1) {
				Object objs[] = activeDatasets.toArray();
				curDataset = (CDataset) objs[0];
			//	updateDatasetChoice(curDataset); 
			}
			else { 
				//				 multiple active.
				
				fireEvents();	
				datasetList.repaint();
				if (projList != null)
					projList.repaint();
			}
		}
		datasetList.repaint();
		if (projList != null)
			projList.repaint();
	}
	
	public void executionSelectionChanged(ExecutionSelectionEvent e) {
		ChainExecution exec = e.getSelectedExecution();
		System.err.println("control panel has new selected execution...");
		System.err.println("exec. is "+exec.getID());
		System.err.println("dataset is "+exec.getDataset().getName());
	//updateDatasetChoice(exec.getDataset());
	}*/
	
	
	
	public void selectionChanged(SelectionEvent e) {

		System.err.println("selection changed...");
		selectionState.removeSelectionEventListener(this);
		int pos = datasets.indexOf(selectionState.getSelectedDataset());
		System.err.println("dataset pos is "+pos);
		if (pos >=0)
			datasetList.setSelectedIndex(pos);
		else
			datasetList.clearSelection();
		pos= projects.indexOf(selectionState.getSelectedProject());
		System.err.println("project pos is "+pos);
		if (pos >=0)
			projList.setSelectedIndex(pos);
		else
			projList.clearSelection();
		projList.repaint();
		datasetList.repaint();
		selectionState.addSelectionEventListener(this);
	}
}

class ProjectRenderer  extends JLabel implements ListCellRenderer {
	
	private Font plainFont = new Font(null,Font.PLAIN,12);
	private Font activeFont = new Font(null,Font.BOLD,12);
	private SelectionState state;
	
	public ProjectRenderer(SelectionState state) {
		setOpaque(true);
		this.state = state;
		setHorizontalAlignment(SwingConstants.LEFT);
		setVerticalAlignment(SwingConstants.CENTER);
	}
	
	public Component getListCellRendererComponent(JList list,
			Object value,int index,boolean isSelected,
				boolean cellHasFocus) {
			Project p = (Project) value;
			
			setFont(plainFont);
			if (state != null) {
				Collection active = state.getActiveProjects();
				if (active != null && active.contains(p))
					setFont(activeFont);
			}
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
	
	private Font plainFont = new Font(null,Font.PLAIN,12);
	private Font activeFont = new Font(null,Font.BOLD,12);
	private SelectionState state;	
	
	public DatasetRenderer(SelectionState state) {
		setOpaque(true);
		this.state = state;
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
				if (state !=null) {
					Collection active = state.getActiveDatasets();
					if (active != null && active.contains(d))
						setFont(activeFont);
				}
			}
			else 
				setText("None");
			if (isSelected) {
				//System.err.println("in selected dataset");
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
