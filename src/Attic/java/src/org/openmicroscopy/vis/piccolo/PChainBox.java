/*
 * org.openmicroscopy.vis.piccolo.PChainBox
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

package org.openmicroscopy.vis.piccolo;

import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.chains.events.SelectionEvent;
import org.openmicroscopy.vis.chains.events.SelectionEventListener;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.util.PBounds;
import java.util.Collection;


/** 
 * A subclass of {@link PCategoryBox} that is used to provide a colored 
 * background for {@link PChain} widgets in the {@link PChainLibraryCannvas}
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PChainBox extends PGenericBox implements  SelectionEventListener {
	

	/**
	 * The size of an orthogonal side of the lock icon
	 */
	public static final int SIZE_LENGTH=50;
	
	public static final double MAX_NAME_SCALE=6;
	

	/**
	 * 
	 * The ID of the chain being stored
	 */
	private int chainID=0;
	
	private CChain chain;
	
	
	private static final float VGAP=10;
	private static final float HGAP=20;
	private static final float FUDGE=3;
	
	private PText name;
	
	private float height;
	private float width;
	float x =0;
	float y = 0;
	
	private PLayer chainLayer;
	private PLinkLayer PLinkLayer;
	
	
	public PChainBox(Connection connection,CChain chain) {
		super();
		this.chain = chain;
		chainID = chain.getID();
		SelectionState selectionState = SelectionState.getState();
		selectionState.addSelectionEventListener(this);
		
		
		chainLayer = new PLayer();
		addChild(chainLayer);
		
	
		// add name
		name = new PText(chain.getName());
		name.setFont(PConstants.LABEL_FONT);
		name.setPickable(false);
		name.setScale(MAX_NAME_SCALE);
		chainLayer.addChild(name);
		name.setOffset(HGAP,VGAP*3);
		
		double width = name.getGlobalFullBounds().getWidth();
		//		 one VGAP below + 3 above
		y = (float) (name.getGlobalFullBounds().getHeight()+VGAP*3); 
		
		
		// add ower name
		PText owner = new PText(connection.getOwnerName(chain));
		owner.setFont(PConstants.LABEL_FONT);
		owner.setPickable(false);
	
		
		chainLayer.addChild(owner);
		owner.setOffset(x+HGAP,y+VGAP);
		y += owner.getHeight()+VGAP;
		
		// build the chain..
		PChain p = new PChain(connection,chain,false);
		
		chainLayer.addChild(p);
		p.setOffset(HGAP*2,y);
		y += p.getHeight()+VGAP; 

		//		 find width. use it in layout of datasets/executions..
		if (p.getWidth() > width)
			width = p.getWidth();
		
		
		
		// if executions, add them here...
		Collection datasets = chain.getDatasetsWithExecutions();
		if (datasets.size() > 0) {
			// add indication of datasets
			PText datasetLabel = new PText("Datasets: ");
			datasetLabel.setFont(PConstants.LABEL_FONT);
			datasetLabel.setOffset(x+HGAP,y);
			datasetLabel.setPickable(false);
			datasetLabel.setScale(PConstants.FIELD_LABEL_SCALE);
			chainLayer.addChild(datasetLabel);
			PBounds dlbounds = datasetLabel.getGlobalFullBounds();
			//y+=dlbounds.getHeight()+VGAP;
			double datasetsWidth = width - (dlbounds.getWidth()+2*HGAP);
			
			// add individual datasets
			PDatasetLabels datasetLabels = new 
				PDatasetLabels(datasets,datasetsWidth);
			
			// adjust size
			chainLayer.addChild(datasetLabels);
			double ratio = PConstants.ITEM_LABEL_SCALE/
				PConstants.FIELD_LABEL_SCALE;
			y += (1-ratio)*dlbounds.getHeight()-VGAP-FUDGE;
			datasetLabels.setOffset(x+dlbounds.getWidth()+2*HGAP,y);
			PBounds b2 = datasetLabels.getGlobalFullBounds();
			double datasetHeight = dlbounds.getHeight();
			if (b2.getHeight() > datasetHeight)
				datasetHeight = b2.getHeight();
			y+= datasetHeight+VGAP;
			// add indications of executions
			
			
			/// add the individual labels;
		}
		
		setExtent(width+HGAP*2,y);
	}
	
	/**
	 * 
	 * @return the ID of the chain stored in the box
	 */
	public int getChainID() {
		return chain.getID();
	}
	
	/**
	 * @return the chain stored in the box
	 * 
	 */
	public CChain getChain() {
		return chain;
	}
	
	public void setExtent(double width,double height) {
		super.setExtent(width,height);
		// add a triangle in the corner.
		if (chain.getLocked()) {
			addLockedIndicator();
			//PBounds b = getFullBoundsReference();
			
		}
	}
	
	private void addLockedIndicator() {
		PBounds b = getFullBoundsReference();
		PText locked = new PText("Locked");
		locked.setFont(PConstants.LABEL_FONT);
		locked.setPaint(PConstants.LOCKED_COLOR);
		locked.setScale(2);
		chainLayer.addChild(locked);
		PBounds lockedBounds = locked.getGlobalFullBounds();
		float x = (float) (b.getX()+b.getWidth()-lockedBounds.getWidth()-HGAP);
		locked.setOffset(x,b.getY()+VGAP);
	}
			
	
	public void setSelected(boolean v) {
		if (v == true)
			setPaint(PConstants.EXECUTED_COLOR);
		else
			setPaint(null);
		repaint();
	}
	
	public void selectionChanged(SelectionEvent e) {
		SelectionState selectionState = e.getSelectionState();
		if (e.isEventOfType(SelectionEvent.SET_ROLLOVER_CHAIN)) {
			System.err.println("chain box got rollover chain event");
			boolean selected = selectionState.getRolloverChain() == chain; 
			setHighlighted(selected);
			
		}
		else {
			Collection activeDatasets = selectionState.getActiveDatasets();
			boolean selected = 
				chain.hasExecutionsInSelectedDatasets(activeDatasets);
			setSelected(selected);
		}
	}
	
	public int getEventMask() {
		return SelectionEvent.SET_SELECTED_DATASET |
			SelectionEvent.SET_SELECTED_PROJECT |
			SelectionEvent.SET_ROLLOVER_CHAIN;
	}
}