/*
 * org.openmicroscopy.vis.piccolo.PChainCanvas
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
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PNodeFilter;
import edu.umd.cs.piccolo.util.PPaintContext;
import org.openmicroscopy.Chain.Node;
import org.openmicroscopy.managers.ChainManager;
import org.openmicroscopy.vis.chains.ChainFrame;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CNode;
import org.openmicroscopy.vis.ome.CModule;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.Module.FormalInput;
import org.openmicroscopy.Module.FormalOutput;
import org.openmicroscopy.vis.dnd.ModuleFlavor;
import org.openmicroscopy.vis.dnd.ChainFlavor;
import java.awt.dnd.DropTargetListener;
import java.awt.dnd.DropTargetDragEvent;
import java.awt.dnd.DropTargetEvent;
import java.awt.dnd.DropTargetDropEvent;
import java.awt.dnd.DropTarget;
import java.awt.dnd.DnDConstants;
import java.awt.datatransfer.Transferable;
import java.awt.geom.Point2D;
import java.util.List;
import java.util.Iterator;
import java.util.Collection;

/** 
 * A {@link PCanvas} for building chains
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PChainCanvas extends PCanvas implements DropTargetListener {
	
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
	private ChainFrame frame;
	
	/**
	 * A pointer to the canvas with the chain library
	 */
	private PChainLibraryCanvas libraryCanvas;
	
	public PChainCanvas(Connection c) {
		super();
		this.connection  = c;
		layer = getLayer();
		
		// set rendering details.
		
		setDefaultRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setInteractingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setAnimatingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setBackground(PConstants.CANVAS_BACKGROUND_COLOR);
		
		// remove handlers
		removeInputEventListener(getZoomEventHandler());
		removeInputEventListener(getPanEventHandler());
		// set up link layer
		linkLayer = new PLinkLayer();
		getCamera().addLayer(linkLayer);
		linkLayer.moveToFront();
		
		// event handler
		handler = new PChainEventHandler(this,linkLayer);
		addInputEventListener(handler);
		
		// data transfer support
		dropTarget = new DropTarget(this,this);
		
		// set magnification
		final PCamera camera = getCamera();
	    getCamera().setViewScale(INIT_SCALE);
	    
	    // setup tool tips.
		camera.addInputEventListener(new PChainToolTipHandler(camera));
		
		
	}
	
	public void setFrame(ChainFrame frame) {
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
	//	System.err.println("getting a drop...");
		try {
			Transferable transferable =  e.getTransferable();
			if (transferable.isDataFlavorSupported(ModuleFlavor.moduleFlavor)) { 
				e.acceptDrop(DnDConstants.ACTION_MOVE);
				String i = (String)transferable.getTransferData(
						ModuleFlavor.moduleFlavor); 
				e.getDropTargetContext().dropComplete(true);
				int id = Integer.parseInt(i);
				CModule mod = connection.getModule(id); 
				Point2D loc = e.getLocation();
				createDroppedModule(mod,loc);
				addInputEventListener(handler);
			}
			else if (transferable.
					isDataFlavorSupported(ChainFlavor.chainFlavor)) {
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
		setSaveEnabled(true);
	}
	
	/**
	 * Create a dropped chain
	 * @param chain
	 * @param location
	 */
	public void createDroppedChain(CChain chain,Point2D location) {
		getCamera().localToGlobal(location);
		float x = (float) location.getX();
		float y = (float) location.getY();
		PChain p = new PChain(connection,chain,false);
		layer.addChild(p);
		p.setOffset(x,y);
		PBounds b = layer.getFullBounds();
		PBounds newb = new PBounds(b.getX()-PConstants.BORDER,	
			b.getY()-PConstants.BORDER,
			b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER);
		getCamera().animateViewToCenterBounds(newb,true,
			PConstants.ANIMATION_DELAY);
		setSaveEnabled(true);
	}
	
	/**
	 * Logout of OME
	 *
	 */
	public void logout() {
		List children = layer.getChildrenReference();
		Object childObjects[] = children.toArray();
		
		PModule mod;
		for (int i =0; i < childObjects.length; i++) {
			mod = (PModule) childObjects[i];
			mod.remove();
		}
	}
	
	
	private void setSaveEnabled(boolean v) {
		if (frame != null)
			frame.setSaveEnabled(v);
	}
	
	/**
	 * The save status is ture (enabled) if there are any {@link PModule}
	 * objects on the {@link PChainCanvas}
	 *
	 */
	public void updateSaveStatus() {
		boolean res  = false;
		
		Collection modules = findModules();
		if (modules.size() > 0)
			res = true;
		setSaveEnabled(res);
	}	
	
	/**
	 * To save a chain, ask the manager to create it,
	 * add the nodes and links, commit the transaction, and 
	 * updaet the library. 
	 * @param name
	 * @param desc
	 */
	public void save(String name,String desc) {	
		ChainManager manager = connection.getChainManager();
		CChain chain  =  (CChain)manager.createChain(name,desc);
		
		//populate chains
		addNodes(manager,chain);
		
		// links
		addLinks(manager,chain);
		// commit chain
		
		connection.commitTransaction();
		
		// for now, layout this chain. eventually, save layout in database
		chain.layout(); 
		
		connection.addChain(chain);
		
		// add this to the library
		libraryCanvas.drawChain(chain);
		libraryCanvas.scaleToSize();
	}
	
	private Collection findModules() {
		PNodeFilter filter = new PNodeFilter() {
			public boolean accept(PNode node) {
				return (node instanceof PModule);
			}
			public boolean acceptChildrenOf(PNode node) {
				return  true;
			}
		};
		return  layer.getAllNodes(filter,null);
		
	}
	/**
	 * Add the modules currently on the canvas to the chain being created.
	 * @param manager
	 * @param chain
	 */
	private void addNodes(ChainManager manager,CChain chain) {
		PNode node;
		PModule mod;
		CNode chainNode;
				
		
		Collection modNodes = findModules();
		
		Iterator iter = modNodes.iterator();
		while (iter.hasNext()) {
			
			node = (PNode) iter.next();
			if (node instanceof PModule) {
				mod = (PModule) node;
				chainNode =  (CNode) manager.addNode(chain,mod.getModule());
			 	mod.setNode(chainNode);
			}
		}
	}
	
	/**
	 * Add the links to the chain by iterating over the links in the {@link 
	 * linkLayer}
	 * @param manager
	 * @param chain
	 */
	private void addLinks(ChainManager manager,CChain chain) {
		PNode node;
		PParamLink link;

		PNodeFilter filter = new PNodeFilter() {
			public boolean accept(PNode node) {
				return (node instanceof PParamLink);
			}
			public boolean acceptChildrenOf(PNode node) {
				return  true;
			}
		};
		Collection linkNodes = layer.getAllNodes(filter,null);
		// plus add in whatever is in linkLayer;
		linkNodes.addAll(linkLayer.links());
		Iterator iter = linkNodes.iterator();
		while (iter.hasNext()) {
			node = (PNode) iter.next();
			if (node instanceof PParamLink) {
				link = (PParamLink) node; // add it somehow.
				// get from output
				PFormalOutput output = link.getOutput();
				FormalOutput fromOutput = (FormalOutput) output.getParameter();
				
				// to input
				PFormalInput input = link.getInput();
				FormalInput toInput = (FormalInput) input.getParameter();
				
				// from node
				Node fromNode = output.getPModule().getNode();
				//to node
				Node toNode = input.getPModule().getNode();
				// add it.
				manager.addLink(chain,fromNode,fromOutput,toNode,toInput);
			}
		}
	}
	
	public void setLibraryCanvas(PChainLibraryCanvas libraryCanvas) {
		this.libraryCanvas = libraryCanvas;
	}
 }