/*
 * org.openmicroscopy.vis.chains.SelectionState
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
import org.openmicroscopy.vis.chains.events.SelectionEvent;
import org.openmicroscopy.vis.chains.events.SelectionEventListener;

import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.ChainExecution;
import org.openmicroscopy.Project;
import javax.swing.event.EventListenerList;
import java.util.Collection;

/** 
 * Centralized repository for state of current user selection in GUI. Tracks
 * datsets, chains, executions, and other items that might be selected by
 * users, firing off appropriate events when needed.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class SelectionState {
	
	private CDataset currentDataset = null;
	private Collection 	activeDatasets = null;
	private CChain	currentChain = null;
	private ChainExecution currentExecution = null;
	private Project currentProject = null;
	private Collection activeProjects = null;
	
	// listener lists
	private EventListenerList selectionListeners = new EventListenerList();
	
	
	// singleton
	private static SelectionState singletonState=null;
	
	public static SelectionState getState() {
		if (singletonState == null)
			singletonState = new SelectionState();
		return singletonState;
	}
	
	public SelectionState() {
		
	}
	
	// executions
	public ChainExecution getCurrentExecution() {
		return currentExecution;
	}
	
	public  void setCurrentExecution(ChainExecution exec) {
		currentExecution = exec;
		fireSelectionEvent();
	}
	
	
	// CHAIN
	
	public void setSelectedChain(CChain newChain) {
		
		if (currentChain == newChain) {
			currentDataset = null; // was "return"
		}
			
		currentChain = newChain;
		if (currentChain == null) {
			activeDatasets =null;
			currentDataset = null;
			activeProjects = null;
			currentProject = null;
		}
		else {
			System.err.println("setting chain to .."+currentChain.getName());
			activeDatasets = newChain.getDatasetsWithExecutions();
			activeProjects = null;
			if (currentDataset!= null) {
				if (!activeDatasets.contains(currentDataset))
					currentDataset = null;
			}
			if (currentDataset == null)  { // current dataset is null
				currentProject = null;
			} else { //current dataset is not null..
				if (currentProject != null &&
						!currentProject.getDatasets().contains(currentDataset)) {
					currentProject = null;
				}
			}
		}
		fireSelectionEvent();	
	}
	
	public CChain getSelectedChain() {
		return currentChain;
	}
	
	// PROJECT
	
	
	public void setSelectedProject(Project current) {
		currentProject = current;
		if (currentProject != null) {
			activeDatasets = currentProject.getDatasets(); 
			if (!activeDatasets.contains(currentDataset)) {
				currentDataset = null;
				activeProjects =null;
			}
		}
		else 
			activeDatasets=null;
		fireSelectionEvent();
	}
	

	public Collection getActiveProjects() {
		return activeProjects;
	}
	
	public Project getSelectedProject() {
		return currentProject;
	}
	
	// DATASETS
	
	public void setSelectedDataset(CDataset current) {
		doSetSelectedDataset(current);
		fireSelectionEvent();
	}
	
	private void doSetSelectedDataset(CDataset current) {
		currentDataset = current;
		if (currentDataset != null) {
			activeProjects = currentDataset.getProjects();
			if (!activeProjects.contains(currentProject))
				currentProject = null;
		}
	    else {
	    	activeProjects = null;
	    	currentChain = null;
	    	
	    }
    	if (currentProject!=null) {
    		if (currentDataset != null && 
    				!currentProject.getDatasets().contains(currentDataset)) {
    			currentProject =null;
    		}
    		else {
    			activeDatasets = currentProject.getDatasets();
    		}
    	} 	else {
    		activeDatasets =null;
    	
    	}
	   	//chains with executions are selected.
		fireSelectionEvent();
	}
	
	public void setSelected(CChain chain,CDataset dataset) {
		doSetSelectedDataset(dataset);
		currentChain = chain;
		fireSelectionEvent();
	}

	public CDataset getSelectedDataset() {
		return currentDataset;
	}

	public Collection getActiveDatasets() {
		return activeDatasets;
	}
 	
 	// 	selections
	
 	public void addSelectionEventListener(SelectionEventListener listener) {
		 selectionListeners.add(SelectionEventListener.class,
			 listener);
 	}

 	public void removeSelectionEventListener(SelectionEventListener listener) {
		 selectionListeners.remove(SelectionEventListener.class,
			 listener);
	}

 	private void fireSelectionEvent() {
		 SelectionEvent e = new SelectionEvent(this);
	 	Object[] listeners=selectionListeners.getListenerList();
	 	for (int i = listeners.length-2; i >=0; i-=2) {
			 if (listeners[i] == SelectionEventListener.class) {
				 ((SelectionEventListener) listeners[i+1]).
					selectionChanged(e);
		 	}
	 	}
 	}
}

