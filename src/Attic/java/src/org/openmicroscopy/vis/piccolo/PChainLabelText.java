/*
 * org.openmicroscopy.vis.piccolo.PChainLabelText
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
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.ome.CDataset;
import edu.umd.cs.piccolo.PNode;



/** 
 * Text nodes for  dataset names.
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PChainLabelText extends PRemoteObjectLabelText {
	
	public static final double LABEL_SCALE=.25;
	
	
	private boolean active = false;
	private boolean selected = false;
	private CChain chain;
	
	private PExecutionList executionList;
	
	public PChainLabelText(CChain c) {
		super();
		buildString(LABEL_SCALE,c.getName());
		this.chain  = c;
		SelectionState selectionState = SelectionState.getState();
		if (selectionState != null) 
			selectionState.addSelectionEventListener(this);
		setColor();
	}
	
	
	public CChain getChain() {
		return chain;
	}
		
	public void selectionChanged(SelectionEvent e) {
		
		SelectionState selectionState = e.getSelectionState();
		
		if (selectionState.getSelectedChain() == chain) {
			setActive(false);
			setSelected(true);
		}
		else {
			setActive(false);
			setSelected(false);
		}
		setColor();
	} 
	
	public int getEventMask() {
		return SelectionEvent.SET_SELECTED_CHAIN;
	}
	
	/* used to be called when this is clicked on. now questionable */
	public  void doSelection() {
		SelectionState selectionState = SelectionState.getState();
		System.err.println("dataset ..+ is being selected.."+chain.getName());
		CDataset dataset = getDataset();
		//selectionState.setSelected(chain,dataset);
	}
	
	private CDataset getDataset() {
		PNode parent = getParent();
		if (parent == null || !(parent instanceof PChainLabels))
			return null;
		PChainLabels cl = (PChainLabels) parent;
		parent = cl.getParent();
		if (parent == null || !(parent instanceof PDataset))
			return null;
		return ((PDataset) parent).getDataset();
		
	}
	public PExecutionList getExecutionList() {
		if (executionList == null) {
			CDataset dataset = getDataset();
			executionList = new PExecutionList(dataset,chain,LABEL_SCALE);
		}
		return executionList;
	}
}
