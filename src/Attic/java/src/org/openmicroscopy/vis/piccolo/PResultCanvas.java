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
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CModule;
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
	 * The layer for the canvas 
	 */
	private PLayer layer;
	
	
	/**
	 * The layer for the links. Links are stored in a different layer because 
	 * they must be drawn last if they are to avoid being obscured by modules. 
	 */
	private PLinkLayer linkLayer;
	
	/**
	 * The event handler for this canvas
	 */
	private PChainEventHandler handler;
	
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
	
	public PResultCanvas(Connection c) {
		super();
		this.connection  = c;
		layer = getLayer();
		
		// set rendering details.
		
		setDefaultRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setInteractingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setAnimatingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setBackground(PConstants.CANVAS_BACKGROUND_COLOR);
		 
		
		//	remove handlers
		 removeInputEventListener(getZoomEventHandler());
		 removeInputEventListener(getPanEventHandler());
		 
		//	install custom event handler
		 addInputEventListener(new PResultEventHandler(this)); 
			
		// set up link layer
		linkLayer = new PLinkLayer();
		getCamera().addLayer(linkLayer);
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
		return new PBounds(b.getX(),b.getY(),b.getWidth()+2*PConstants.BORDER,
		b.getHeight()+2*PConstants.BORDER); 
	}
	

	/**
	 * Start a DataTransfer event disable the {@link PChainEventHandler} while
	 * doing the transfer
	 */
	public void dragEnter(DropTargetDragEvent e) {
		removeInputEventListener(handler);
		e.acceptDrag (DnDConstants.ACTION_MOVE);
	
	}
	
	/**
	 * Accept a drop event. Create a chain if a chain was dropped,
	 * or a module if a module was dropped. Reinstate the event handler
	 */
	public void drop(DropTargetDropEvent e) {
		System.err.println("getting a drop...");
		try {
			Transferable transferable =  e.getTransferable();
			if (transferable.isDataFlavorSupported(ChainFlavor.chainFlavor)) {
				e.acceptDrop(DnDConstants.ACTION_MOVE);
				Integer i = (Integer)transferable.
					getTransferData(ChainFlavor.chainFlavor); 
				e.getDropTargetContext().dropComplete(true);
				int id = i.intValue(); 
				Point2D loc = e.getLocation();
				CChain chain = connection.getChain(id); 
				createDroppedChain(chain,loc);
				addInputEventListener(handler);			
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
	 * Create a dropped module
	 * @param mod the module to create
	 * @param location the poitn of drop.
	 */
	private void createDroppedModule(CModule mod,Point2D location) {
		
		// determine the corect point
		getCamera().localToView(location);
		
		//create the layer
		PModule mNode = new PModule(connection,mod,
			(float) location.getX(), (float) location.getY());
		mod.addModuleWidget(mNode);
		
		// add it to layer.
		layer.addChild(mNode);
		
		// put the module info back into the connection
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
		PChain p = new PChain(connection,chain,layer,linkLayer,x,y);
	}
	
	public void setLibraryCanvas(PChainLibraryCanvas libraryCanvas) {
		this.libraryCanvas = libraryCanvas;
	}
 }