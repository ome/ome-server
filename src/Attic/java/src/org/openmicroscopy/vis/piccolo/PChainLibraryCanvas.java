/*
 * org.openmicroscopy.vis.piccolo.PChainLibraryCanvas
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

import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PPaintContext;
import edu.umd.cs.piccolo.util.PNodeFilter;
import edu.umd.cs.piccolo.PCamera;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.Chains;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.dnd.ChainSelection;
import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.chains.events.SelectionEvent; 
import org.openmicroscopy.vis.chains.events.SelectionEventListener;
import java.util.Iterator;
import java.util.Collection;
import java.awt.dnd.DragSourceAdapter;
import java.awt.dnd.DragSourceEvent;
import java.awt.dnd.DragGestureListener;
import java.awt.dnd.DragSource;
import java.awt.dnd.DnDConstants;
import java.awt.dnd.DragGestureEvent;



/** 
 * A {@link PCanvas} to hold a library of analysis chains 
 *
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PChainLibraryCanvas extends PCanvas implements DragGestureListener,
  	PBufferedObject, SelectionEventListener {
	
	/***
	 * Vertical space betwen chains
	 * 
	 */
	private static float VGAP=20f;
	
	/** 
	 * Horizonal space betwen chains
	 * 
	 */
	private static float HGAP=40f;
	
	
	/**
	 * Connection to the OME Database
	 */
	private Connection connection=null;
	
	
	/**
	 * Scengraph layer for the canvas.
	 */
	private PLayer layer;
	
	/**
	 * Initial vertical position
	 */
	private float y=VGAP;
	
	/** 
	 * Initial horizontal position
	 */
	private float x=0;
	
	/**
	 * Height of the current row
	 */
	private float rowHeight =0;
	
	/**
	 * The currently selected chain
	 */
	private CChain draggingChain;
	
	
	
	/** 
	 * Listener for drag events
	 */
	private DragSourceAdapter dragListener;
	
	/**
	 * Source for drag events
	 */
	private DragSource dragSource;
	
	private PExecutionList executionList;

	public PChainLibraryCanvas(Connection c) {
		super();
		
		SelectionState.getState().addSelectionEventListener(this);
		this.connection  = c;
		setBackground(PConstants.CANVAS_BACKGROUND_COLOR);
		layer = getLayer();
		
		// make sure that rendering is always high quality
		
		setDefaultRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setInteractingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setAnimatingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		
		// install custom event handler
		
		removeInputEventListener(getZoomEventHandler());
		removeInputEventListener(getPanEventHandler());
		addInputEventListener(new PChainLibraryEventHandler(this)); 
		
		// initialize data transfer
		dragListener = new DragSourceAdapter() {
				public void dragExit(DragSourceEvent dse) {
				}
			};
		dragSource = new DragSource();
		dragSource.createDefaultDragGestureRecognizer(this,
			DnDConstants.ACTION_COPY,this);
			
		// setup tool tips.
		PCamera camera = getCamera();
		camera.addInputEventListener(new PPaletteToolTipHandler(camera));
	
		// the current chain
		CChain chain;

		// Get the chains in the database, along with an iterator
		Chains chains = connection.getChains();		
		Iterator iter = chains.iterator();
		
		int num = chains.size();
		
		// The display should be roughly square, 
		// in terms of the number of rows vs. # of columns
		int rowSize = (int) Math.floor(Math.sqrt(num));
		
		int count=0;
		// draw each of them.
		while (iter.hasNext()) {
			chain = (CChain) iter.next();
			drawChain(chain);
			count++;
			if (count == rowSize) {
				// move on to next row.
				count = 0;
				x = 0;
				y+= rowHeight;
				rowHeight = 0;
			}
		}
		
	}
	
	/**
	 * Draw a chain on the canvas. The chain is drawn at the current values
	 * of x and y.
	 * @param chain
	 */
	public  void drawChain(CChain chain) {
		
		
		float height = 0;
		
		PChainBox box = new PChainBox(connection,chain);
		layer.addChild(box);
		box.moveToBack();
		box.setOffset(x,y);

		//	setup the chain widget
		
		height = (float) box.getHeight();
 		// set the row height if this is taller than others in the row.
		if (height+VGAP>rowHeight)
			rowHeight = height;
		
		//advance the horizontal position
		x+= box.getWidth();
	}
	

	
	
	/**
	 * Animate the view to center on the  contents of this canvas.
	 *
	 */
	public void scaleToSize() {
		getCamera().animateViewToCenterBounds(getBufferedBounds(),true,0);
	}
	
	public void animateToSize() {
		getCamera().animateViewToCenterBounds(getBufferedBounds(),true,
				PConstants.ANIMATION_DELAY);
	}

	/**
	 * 
	 * @return canvas bounds with appropriate buffers for centering
	 */	
	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX()-PConstants.BORDER,
			b.getY()-PConstants.BORDER,b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER); 
	}

	
	public void setDraggingChain(CChain chain) {
		draggingChain = chain;
	}
	
	public void clearDraggingChain() {
		//System.err.println("clear chain selection");
		draggingChain = null;
	}
	
	private boolean isChainDragging() { 
		return (draggingChain != null);
	}
	
	/**
	 * Start a drag event for copying a chain to the chain canvas, 
	 * with a bit of a hack. Packaged up the ID of the chain as an integer
	 * and send it along.
	 * 
	 * @see PPaletteCanvas
	 */
	public void dragGestureRecognized(DragGestureEvent event) {
		if (isChainDragging()) {
			Integer id = new Integer(draggingChain.getID());
			ChainSelection c = new ChainSelection(id);
			dragSource.startDrag(event,DragSource.DefaultMoveDrop,c,dragListener);
		}
	}
	
	public void selectionChanged(SelectionEvent e) {
		System.err.println("canvas get selectionEvent");
		SelectionState state = e.getSelectionState();
		CChain chain = state.getSelectedChain();
		if (chain != null) {
			System.err.println("selecting chain on canvas.."+chain.getName());
			PChainBox cb = findChainBox(chain);
			if (cb != null)
				zoomToChain(cb);
		}
		else if (state.getSelectedDataset() == null) {
			// zoom to root.
			animateToSize();
		}
	}
	
	private PChainBox findChainBox(CChain chain) {
		ChainBoxFilter filter = new ChainBoxFilter(chain);
		
		// 	should only be one.
		Collection boxes = layer.getAllNodes(filter,null);
		
		Iterator iter = boxes.iterator();

		// 	should always have exactly one. but be defensive.
		if (!iter.hasNext())
				return null;
		
		// if there is one, it will be a chain box (guranteed by ChainBoxFilter)
		PChainBox cb = (PChainBox) iter.next();
		return cb;
	}
	
	private void zoomToChain(PChainBox cb) {
		System.err.println("zooming in on chain.");
		PBufferedNode cBox = (PBufferedNode) cb;				
		PBounds b = cBox.getBufferedBounds();
		PCamera camera = getCamera();
		camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
	}
	
	private class ChainBoxFilter implements PNodeFilter {
		
		private final CChain chain;
		
		ChainBoxFilter(CChain chain) {
			this.chain = chain;	
		}
		public boolean accept(PNode node) {
			if (!(node instanceof PChainBox))
				return false;
			return ((PChainBox) node).getChain() == chain;
		}
		
		public boolean acceptChildrenOf(PNode node) {
			return true;
		}
	}
	
	public void clearExecutionList() {
		if (executionList != null) {
			layer.removeChild(executionList);
			executionList = null;
		}
	}
	public void showExecutionList(PDatasetLabelText dl) {
		clearExecutionList();
		executionList = dl.getExecutionList();
		
		
		layer.addChild(executionList);
		
		PBounds b = dl.getGlobalFullBounds();
		executionList.setOffset(b.getX(),b.getY()+b.getHeight());
	}
}