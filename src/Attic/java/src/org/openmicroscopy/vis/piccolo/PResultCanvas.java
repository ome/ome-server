/*
 * org.openmicroscopy.vis.piccolo.PResultCanvas
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
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PPaintContext;
import org.openmicroscopy.vis.chains.ResultFrame;
import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CChainExecution;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.dnd.ChainFlavor;
import java.awt.dnd.DropTargetListener;
import java.awt.dnd.DropTargetDragEvent;
import java.awt.dnd.DropTargetEvent;
import java.awt.dnd.DropTargetDropEvent;
import java.awt.dnd.DropTarget;
import java.awt.dnd.DnDConstants;
import java.awt.datatransfer.Transferable;
import java.awt.geom.Point2D;

/** 
 * A {@link PCanvas} for viewing chain results
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PResultCanvas extends PCanvas implements DropTargetListener {
	
	/**
	 * The initial magnification of the  canvas
	 */
	private static float INIT_SCALE=0.6f;
	
	/**
	 * Database connection 
	 */
	private Connection connection=null;
	
	
	/**
	 * The layer for the canvas. 
	 */
	private PLayer layer;
	
	/** 
	 * Under layer, we have a layer for the chain
	 * below this will be two layers, one for the chain nodes (nodeLayer)
	 * and the other for the link.
	 * 
	 * This will allow us to scale the chain only by scaling chainLayer
	 * 
	 */
	private PLayer nodeLayer = new PLayer();
	private PChainLayer chainLayer = new PChainLayer();
	
	/**
	 * The layer for the links. Links are stored in a different layer because 
	 * they must be drawn last if they are to avoid being obscured by modules. 
	 */
	private PLinkLayer linkLayer;
	
	/**
	 * A layer for the {@link PImage} instances - image thumbnails
	 * 
	 */
	private PLayer imageLayer = new PLayer();
	
	/**
	 * The event handler for this canvas
	 */
	private PResultEventHandler handler;
	
	/**
	 * DataTransfer bookkeeping
	 */
	private DropTarget dropTarget = null;
	
	/**
	 * The frame contaiing this canvas
	 */
	private ResultFrame frame;
	
	/**
	 * A pointer to the canvas with the chain library
	 */
	private PChainLibraryCanvas libraryCanvas;
	
	private CChainExecution exec;
	
	private boolean hasChain = false;
	
	private static float VGAP=10;
	
	private SelectionState selectionState;
	
	public PResultCanvas(Connection c) {
		super();
		this.connection  = c;
		layer = getLayer();
		
		layer.addChild(chainLayer);
		layer.addChild(imageLayer);
		chainLayer.addChild(nodeLayer);
		// set rendering details.
		
		setDefaultRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setInteractingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setAnimatingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setBackground(PConstants.CANVAS_BACKGROUND_COLOR);
		 
		
		//	remove handlers
		 removeInputEventListener(getZoomEventHandler());
		 removeInputEventListener(getPanEventHandler());
		 
		//	install custom event handler
		handler = new PResultEventHandler(this);
		 addInputEventListener(handler); 
			
		// set up link layer
		linkLayer = new PLinkLayer();
		//getCamera().addLayer(linkLayer);
		chainLayer.addChild(linkLayer);
		linkLayer.setPickable(false);
		
		// data transfer support
		dropTarget = new DropTarget(this,this);
		
		// set magnification
		final PCamera camera = getCamera();
			getCamera().setViewScale(INIT_SCALE);
	    
			// setup tool tips.
		camera.addInputEventListener(new PChainToolTipHandler(camera));
		
	}
	
	public void setFrame(ResultFrame frame) {
		this.frame = frame;
	}
		
	
	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX()-6*PConstants.BORDER,
			b.getY()-6*PConstants.BORDER,
			b.getWidth()+12*PConstants.BORDER,
			b.getHeight()+12*PConstants.BORDER); 
	}
	

	/**
	 * Start a DataTransfer event disable the {@link PChainEventHandler} while
	 * doing the transfer
	 */
	public void dragEnter(DropTargetDragEvent e) {
		if (hasChain == false) {
			removeInputEventListener(handler);
			e.acceptDrag (DnDConstants.ACTION_MOVE);
		}
		else 
			e.rejectDrag();
	}
	
	/**
	 * Accept a drop event. Create a chain if a chain was dropped,
	 * or a module if a module was dropped. Reinstate the event handler
	 */
	public void drop(DropTargetDropEvent e) {
		System.err.println("getting a drop...");
		try {
			Transferable transferable =  e.getTransferable();
			if (transferable.isDataFlavorSupported(ChainFlavor.chainFlavor) &&
				!hasChain) {
				e.acceptDrop(DnDConstants.ACTION_MOVE);
				Integer i = (Integer)transferable.
					getTransferData(ChainFlavor.chainFlavor); 
				e.getDropTargetContext().dropComplete(true);
				int id = i.intValue(); 
				CChain chain = connection.getChain(id); 
				System.err.println("dropped "+chain.getName()+" on result canvas");
				if (chain.hasExecutionsInSelectedDatasets(selectionState) == true) {
					System.err.println("creating dropped chains");
					Point2D loc = e.getLocation();
					createDroppedChain(chain,loc);
					addInputEventListener(handler);
					getCamera().animateViewToCenterBounds(getBufferedBounds(),
						true,PConstants.ANIMATION_DELAY);
					frame.updateExecutionChoices(chain);
					hasChain = true;
				}
				else {
					clearDrop(e);
					System.err.println("not creating dropped chain");
				}		
			} 
		}
		catch(Exception exc ) {
			exc.printStackTrace();
			clearDrop(e);
		}
	}

	
	public void clearDrop(DropTargetDropEvent e) {
		e.rejectDrop();
		addInputEventListener(handler);
	}


	public void dragExit(DropTargetEvent e) {
	}
	
	public void dragOver(DropTargetDragEvent e) {
	}
	
	public void dropActionChanged(DropTargetDragEvent e) {
	}
		
	/**
	 * Create a dropped chain
	 * @param chain
	 * @param location
	 */
	public void createDroppedChain(CChain chain,Point2D location) {
		getCamera().localToView(location);
		float x = (float) location.getX();
		float y = (float) location.getY();
		PChain p = new PChain(connection,chain,nodeLayer,linkLayer,x,y);
	}
	
	public void setLibraryCanvas(PChainLibraryCanvas libraryCanvas) {
		this.libraryCanvas = libraryCanvas;
	}
	
	public void setSelectionState(SelectionState selectionState) {
		this.selectionState = selectionState;
	}
	
	public void setExecution(CChainExecution exec) {
		this.exec=exec;
		System.err.println("setting execution to "+exec);
		gainedFocus();
		
	}
	
	public void gainedFocus() {
		if (exec != null && selectionState != null) 
			selectionState.setCurrentExecution(exec);
	}
	
	public CChainExecution getChainExecution() {
		return exec;
	}
 }