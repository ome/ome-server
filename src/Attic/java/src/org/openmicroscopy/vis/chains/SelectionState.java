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
import org.openmicroscopy.vis.chains.events.ChainSelectionEvent;
import org.openmicroscopy.vis.chains.events.ChainSelectionEventListener;
import org.openmicroscopy.vis.chains.events.DatasetSelectionEvent;
import org.openmicroscopy.vis.chains.events.DatasetSelectionEventListener;
import org.openmicroscopy.vis.chains.events.ProjectSelectionEvent;
import org.openmicroscopy.vis.chains.events.ProjectSelectionEventListener;
import org.openmicroscopy.vis.chains.events.ExecutionSelectionEvent;
import org.openmicroscopy.vis.chains.events.ExecutionSelectionEventListener;

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
	private EventListenerList chainListeners = new EventListenerList();
	private EventListenerList datasetListeners = new EventListenerList();
	private EventListenerList projectListeners = new EventListenerList();
	private EventListenerList executionListeners = new EventListenerList();
	
	public SelectionState() {
		
	}
	
	// executions
	public ChainExecution getCurrentExecution() {
		return currentExecution;
	}
	
	public  void setCurrentExecution(ChainExecution exec) {
		currentExecution = exec;
		fireExecutionSelectionEvent();
	}
	
	
	// CHAIN
	
	public void setCurrentChain(CChain newChain) {
		CChain eventChain = null;
		int status;
		if (newChain == null) {
			eventChain = currentChain;
			if (eventChain == null) // if old chain was null and so is new 
				return; // no need for an event.
			status = ChainSelectionEvent.DESELECTED;
		}
		else  {// not a null chain
			eventChain = newChain;
			status = ChainSelectionEvent.SELECTED;
		}
		fireChainSelectionChanged(eventChain,status);	
	}
	
	public CChain getCurrentChain() {
		return currentChain;
	}
	
	// PROJECT
	
	public void setProjectSelections(Collection active,Project current) {
		activeProjects = active;
		currentProject  = current;
		fireProjectSelectionEvent();			
	}
	
	public Collection getActiveProjects() {
		return activeProjects;
	}
	
	public Project getCurrentProject() {
		return currentProject;
	}
	
	// DATASETS
	
	public void setDatasetSelections(Collection active,CDataset current) {
		activeDatasets = active;
		currentDataset  = current;
		fireDatasetSelectionEvent();
	}

	public CDataset getCurrentDataset() {
		return currentDataset;
	}

	public Collection getActiveDatasets() {
		return activeDatasets;
	}

	// list management
	
	public void addChainSelectionEventListener(ChainSelectionEventListener
			listener) {
		chainListeners.add(ChainSelectionEventListener.class,
				listener);
	}
	
	public void removeChainSelectionEventListener(ChainSelectionEventListener
		listener) {
			chainListeners.remove(ChainSelectionEventListener.class,
				listener);
	}
	
	private void fireChainSelectionChanged(CChain chain,int status) {
		ChainSelectionEvent e = new ChainSelectionEvent(this,chain,status);
		Object[] listeners=chainListeners.getListenerList();
		for (int i = listeners.length-2; i >=0; i-=2) {
			if (listeners[i] == ChainSelectionEventListener.class) {
				((ChainSelectionEventListener) listeners[i+1]).
					chainSelectionChanged(e);
			}
		}
	}
	
	//datasets
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

	public void fireDatasetSelectionEvent() {
		DatasetSelectionEvent e = 
			new DatasetSelectionEvent(this,activeDatasets,currentDataset);
		Object[] listeners=datasetListeners.getListenerList();
		for (int i = listeners.length-2; i >=0; i-=2) {
			if (listeners[i] == DatasetSelectionEventListener.class) {
				((DatasetSelectionEventListener) listeners[i+1]).
					datasetSelectionChanged(e);
			}
		}
	} 
	
	// projects7
	
	public void addProjectSelectionEventListener(ProjectSelectionEventListener
				listener) {
		projectListeners.add(ProjectSelectionEventListener.class,
			listener);
	}

	public void removeProjectSelectionEventListener(ProjectSelectionEventListener
		listener) {
			projectListeners.remove(ProjectSelectionEventListener.class,
				listener);
	}

	private void fireProjectSelectionEvent() {
		ProjectSelectionEvent e = 
			new ProjectSelectionEvent(this,activeProjects,currentProject);
		Object[] listeners=projectListeners.getListenerList();
		for (int i = listeners.length-2; i >=0; i-=2) {
			if (listeners[i] == ProjectSelectionEventListener.class) {
				((ProjectSelectionEventListener) listeners[i+1]).
					projectSelectionChanged(e);
			}
		}
	}
	
	//executions
	
 	public void addExecutionSelectionEventListener(
 			ExecutionSelectionEventListener listener) {
		 executionListeners.add(ExecutionSelectionEventListener.class,
			 listener);
 	}

 	public void removeExecutionSelectionEventListener(
 			ExecutionSelectionEventListener listener) {
		 executionListeners.remove(ExecutionSelectionEventListener.class,
			 listener);
	}

 	private void fireExecutionSelectionEvent() {
		 ExecutionSelectionEvent e = 
			 new ExecutionSelectionEvent(this,currentExecution);
	 	Object[] listeners=executionListeners.getListenerList();
	 	for (int i = listeners.length-2; i >=0; i-=2) {
			 if (listeners[i] == ExecutionSelectionEventListener.class) {
				 ((ExecutionSelectionEventListener) listeners[i+1]).
					executionSelectionChanged(e);
		 	}
	 	}
 	}
}

