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
import org.openmicroscopy.vis.chains.ControlPanel;
import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.chains.events.DatasetSelectionEvent;
import org.openmicroscopy.vis.chains.events.DatasetSelectionEventListener;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;

import java.awt.Color;
import java.awt.BasicStroke;
import java.awt.Font;


/** 
 * A subclass of {@link PCategoryBox} that is used to provide a colored 
 * background for {@link PChain} widgets in the {@link PChainLibraryCannvas}
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PChainBox extends PGenericBox implements 
	DatasetSelectionEventListener{
	
	/**
	 * The color for display of the lock icon
	 */
	private static final Color LOCK_ICON_COLOR= new Color(255,0,0,100);
	
	/**
	 * The size of an orthogonal side of the lock icon
	 */
	public static final int SIZE_LENGTH=50;
	
	/**
	 * The ID of the chain being stored
	 */
	private int chainID=0;
	
	private CChain chain;
	
	private static final BasicStroke VIEWABLE_STROKE = new BasicStroke(5);
	private static final Color EXECUTED_COLOR = new Color(204,204,255,200);
	
	private static final Font LOCKED_FONT = new Font(null,Font.BOLD,18);
	
	private static final float VGAP=10;
	private static final float HGAP=20;
	
	
	public PChainBox(ControlPanel controlPanel,CChain chain, float x, float y) {
		super(x,y);
		this.chain = chain;
		chainID = chain.getID();
		SelectionState selectionState = controlPanel.getSelectionState();
		selectionState.addDatasetSelectionEventListener(this);
		
		boolean selected = chain.hasExecutionsInSelectedDatasets(selectionState);
		setSelected(selected);
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
		locked.setFont(LOCKED_FONT);
		locked.setPaint(Color.RED);
		locked.setScale(2);
		addChild(locked);
		PBounds lockedBounds = locked.getGlobalFullBounds();
		float x = (float) (b.getX()+b.getWidth()-lockedBounds.getWidth()-HGAP);
		locked.setOffset(x,b.getY()+VGAP);
	}
			
	
	public void datasetSelectionChanged(DatasetSelectionEvent e) {
		repaint();
		SelectionState selectionState = e.getSelectionState();
		boolean selected = 
			chain.hasExecutionsInSelectedDatasets(selectionState);
		setSelected(selected);
	} 
	
	public void setSelected(boolean v) {
		if (v == true)
			setPaint(EXECUTED_COLOR);
		else
			setPaint(PGenericBox.CATEGORY_COLOR);
		repaint();
	}
	 
}