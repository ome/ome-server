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
import org.openmicroscopy.vis.ome.CProject;
import org.openmicroscopy.ChainExecution;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;

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
	private CDataset rolloverDataset = null;
	private Collection 	activeDatasets = null;
	private CChain	currentChain = null;
	private ChainExecution currentExecution = null;
	private CProject currentProject = null;
	private CProject rolloverProject = null;
	
	// listener lists
	private ArrayList selectionListeners = new ArrayList();
	
	
	// singleton
	private static SelectionState singletonState=null;
	
	public static SelectionState getState() {
		if (singletonState == null)
			singletonState = new SelectionState();
		return singletonState;
	}
	
	private SelectionState() {
		
	}
	
	// executions
	public ChainExecution getSelectedExecution() {
		return currentExecution;
	}
	
	public  void setSelectedExecution(ChainExecution exec) {
		currentExecution = exec;
		fireSelectionEvent(
			new SelectionEvent(this,SelectionEvent.SET_SELECTED_EXECUTION));
	}
	
	
	// CHAIN
	
	public void setSelectedChain(CChain newChain) {
		
		if (currentChain == newChain) {
			currentDataset = null; // was "return"
		}
			
		currentChain = newChain;
		// if we clear chain, clear everything.
		
		if (currentChain == null) {
			activeDatasets =null;
			currentDataset = null;
			currentProject = null;
		}
		else {
			// select datasets for this chain
			activeDatasets = newChain.getDatasetsWithExecutions();

			// current dataset null if not contained.
			if (currentDataset!= null) {
				if (!activeDatasets.contains(currentDataset))
					currentDataset = null;
			}
			
		    // update projects.
			if (currentDataset == null)  { // no project if no dataset
				currentProject = null;
			} 
		}

		fireSelectionEvent(
			new SelectionEvent(this,SelectionEvent.SET_CHAIN));	
	}
	
	public CChain getSelectedChain() {
		return currentChain;
	}
	
	// PROJECT
	
	
	public synchronized void setSelectedProject(CProject current) {
		
		currentProject = current;
		
		if (currentProject == null)
			// no datasets active if no project is selected.
			activeDatasets=null; // however, we don't have to clear 
											//selected dataset & chain.
		else {
			// set active projects
			activeDatasets = currentProject.getDatasets(); 
			if (!activeDatasets.contains(currentDataset)) {
				//only one project is active if the active datasets 
				// don't contain the current dataset.
				currentDataset = null;
			}
		}
		fireSelectionEvent(
			new SelectionEvent(this,SelectionEvent.SET_PROJECT));
	}
	

	
	
	public CProject getSelectedProject() {
		return currentProject;
	}

	public void setRolloverProject(CProject p) {
		
		// we don't change the rollover if there is a selected project
		//if (currentProject != null) {
			rolloverProject =p;
			fireSelectionEvent(
				new SelectionEvent(this,SelectionEvent.SET_ROLLOVER_PROJECT));
		//}
	}
	
	public CProject getRolloverProject() {
		return rolloverProject;
	}
	
	// DATASETS
	
	public void setSelectedDataset(CDataset current) {	
		doSetSelectedDataset(current);
		fireSelectionEvent(
			new SelectionEvent(this,SelectionEvent.SET_PROJECT));
	}
	
	private void doSetSelectedDataset(CDataset current) {
		currentDataset = current;
		
		if (currentDataset == null) {
	    	currentChain = null;
		}
		else  {
			if (!currentDataset.hasProject(currentProject))
				currentProject = null;
		}
	     
    	if (currentProject!=null) {
    		if (currentDataset != null && 
    				!currentProject.hasDataset(currentDataset)) {
    			currentProject =null;
    		}
    		else {
    			activeDatasets = currentProject.getDatasets();
    		}
    	} 	else {
    		activeDatasets =null;
    	
    	}
	   	
	}
	
	public void setSelected(CChain chain,CDataset dataset) {
		doSetSelectedDataset(dataset);
		currentChain = chain;
		fireSelectionEvent(
			new SelectionEvent(this,SelectionEvent.SET_CHAIN));
	}

	public CDataset getSelectedDataset() {
		return currentDataset;
	}

	public Collection getActiveDatasets() {
		return activeDatasets;
	}
	
	public void setRolloverDataset(CDataset d) {
		if (currentDataset == null) {
			rolloverDataset =d;
			fireSelectionEvent(
				new SelectionEvent(this,SelectionEvent.SET_ROLLOVER_DATASET));
		}
	}

	public CDataset getRolloverDataset() {
		return rolloverDataset;
	}
 	
 	// 	selections
	
 	public synchronized void addSelectionEventListener(SelectionEventListener listener) {
		 selectionListeners.add(listener);
 	}

 	public synchronized void removeSelectionEventListener(SelectionEventListener listener) {
		 selectionListeners.remove(listener);
	}

 	private synchronized void fireSelectionEvent(SelectionEvent e) {
 		Iterator iter = selectionListeners.iterator();
 		while (iter.hasNext()) {
			SelectionEventListener listener = (SelectionEventListener)
				iter.next();
			int mask = listener.getEventMask() & e.getMask();
			// only send the event if it contains something that the
			// listener is interested in (overlap != 0) 
			if ((mask & e.getMask()) !=0 ) {
				listener.selectionChanged(e);
			}
		}
 	}
}

