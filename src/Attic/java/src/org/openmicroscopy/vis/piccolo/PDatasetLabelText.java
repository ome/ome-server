/*
 * org.openmicroscopy.vis.piccolo.PDatasetLabelText
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
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
package org.openmicroscopy.vis.piccolo;

import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.chains.events.SelectionEvent;
import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.ome.CChain;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.PLayer;
import java.util.Collection;

/** 
 * Text nodes for  dataset names.
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PDatasetLabelText extends PRemoteObjectLabelText { 
	

	private CDataset dataset;
	
	private PExecutionList executionList;
	
	public PDatasetLabelText(CDataset ds) {
		super();
		buildString(PConstants.ITEM_LABEL_SCALE,ds.getLabel());
		this.dataset = ds;
		SelectionState selectionState = SelectionState.getState();
		
		if (selectionState != null) 
			selectionState.addSelectionEventListener(this);
		setActive(false);
		setColor();
	}
	
	public CDataset getDataset() {
		return dataset;
	}
	
	
	public void selectionChanged(SelectionEvent e) {
		SelectionState selectionState = e.getSelectionState();
		Collection sets = selectionState.getActiveDatasets();
		if (selectionState.getSelectedDataset() == dataset) {
			setSelected(true);
		}
		else if (sets != null && sets.contains(dataset)) {
			setSelected(false);
		}
		else {
			setSelected(false);
		}
		setColor();
	} 
	
	public int getEventMask() {
		return	SelectionEvent.SET_SELECTED_PROJECT | 
			SelectionEvent.SET_SELECTED_DATASET;
	}
	
	public  void doSelection() {
		SelectionState selectionState = SelectionState.getState();
		System.err.println("dataset ..+ is being selected.."+dataset.getName());
		selectionState.setSelectedDataset(dataset);
	}
	
	// try to find the chain box that this is in.
	
	private PChainBox getChainBox() {
		PNode parent = getParent();
		if (parent == null) {
			System.err.println("parent is null..");
			return null;
		}
		// parent should be pdatasetLabels
		if (!(parent instanceof PDatasetLabels)) {
			System.err.println("parent is not pdatasetlabels.."+parent);
			return null;
		}
		
		PDatasetLabels labels  = (PDatasetLabels) parent;
		
		parent = labels.getParent();
		if (parent == null) {
			System.err.println("grandparent is null..");
			return null;
		}
		if (!(parent instanceof PLayer)) {
			System.err.println("parent is not a layer..."+parent);
			return null;
		}
		
		parent = parent.getParent();
		if (parent == null) 
			return null;
		if (!(parent instanceof PChainBox))
			return null;
		return (PChainBox) parent;
		
	}
	
	public PExecutionList getExecutionList() {
		if (executionList == null) {
			CDataset dataset = getDataset();
			PChainBox cb = getChainBox();
			CChain chain = cb.getChain();
			executionList = 
				new PExecutionList(dataset,chain,PConstants.ITEM_LABEL_SCALE);
		}
		return executionList;
	}
}
