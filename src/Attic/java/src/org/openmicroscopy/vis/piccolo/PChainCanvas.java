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
import org.openmicroscopy.Chain;
import org.openmicroscopy.Chain.Node;
import org.openmicroscopy.managers.ChainManager;
import org.openmicroscopy.vis.chains.ChainFrame;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.ModuleInfo;
import org.openmicroscopy.vis.ome.CNode;
import org.openmicroscopy.Module;
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

/** 
 * Extends PCanvas to provide functionality necessary for a piccolo canvas.<p> 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PChainCanvas extends PCanvas implements DropTargetListener {
	
	private static float INIT_SCALE=0.6f;
	private Connection connection=null;
	private int modCount;
	private PLayer layer;
	
	private float x,y;
	
	private PLinkLayer linkLayer;
	private PChainEventHandler handler;
	private DropTarget dropTarget = null;
	
	private ChainFrame frame;
	
	private PChainLibraryCanvas libraryCanvas;
	
	public PChainCanvas(Connection c) {
		super();
		this.connection  = c;
		layer = getLayer();
		
	
		removeInputEventListener(getZoomEventHandler());
		linkLayer = new PLinkLayer();
		getCamera().addLayer(linkLayer);
		linkLayer.moveToFront();
		handler = new PChainEventHandler(this,linkLayer);
		addInputEventListener(handler);
		dropTarget = new DropTarget(this,this);
		

		final PCamera camera = getCamera();
	    getCamera().setViewScale(INIT_SCALE);
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
	

	
	public void dragEnter(DropTargetDragEvent e) {
		System.err.println("drag enter canvas");
		removeInputEventListener(handler);
		e.acceptDrag (DnDConstants.ACTION_MOVE);
	
	}
	
	public void drop(DropTargetDropEvent e) {
		try {
			Transferable transferable =  e.getTransferable();
			System.err.println("got a drop on canvavs "+transferable);
			if (transferable.isDataFlavorSupported(ModuleFlavor.moduleFlavor)) { 
				e.acceptDrop(DnDConstants.ACTION_MOVE);
				String i = (String)transferable.getTransferData(
						ModuleFlavor.moduleFlavor);
				System.err.println("just dropped module "+i+" onto chain canvas.");
				e.getDropTargetContext().dropComplete(true);
				int id = Integer.parseInt(i);
				ModuleInfo mInfo = connection.getModuleInfo(id);
				System.err.println("module is "+mInfo.getModule().getName());
				Point2D loc = e.getLocation();
				createDroppedModule(mInfo,loc);
				addInputEventListener(handler);
			}
			else if (transferable.isDataFlavorSupported(ChainFlavor.chainFlavor)) {
				e.acceptDrop(DnDConstants.ACTION_MOVE);
				Integer i = (Integer)transferable.
					getTransferData(ChainFlavor.chainFlavor);
				e.getDropTargetContext().dropComplete(true);
				int id = i.intValue();
				System.err.println("dropping chain id "+id);
				Point2D loc = e.getLocation();
				Chain chain = connection.getChain(id);
				createDroppedChain(chain,loc);
				addInputEventListener(handler);
				
			} 
		}
		catch(Exception exc ) {
			System.err.println("drop failed");
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
	
	
	private void createDroppedModule(ModuleInfo info,Point2D location) {
		// create the PModule
		
		System.err.println("creating new dropped module at "+
			location.getX()+","+ location.getY());
		getCamera().localToView(location);
		System.err.println("view coords are "+location.getX()+","+
			location.getY());
		PModule mNode = new PModule(connection,info,
			(float) location.getX(), (float) location.getY());
		info.addModuleWidget(mNode);
		
		// add it to layer.
		layer.addChild(mNode);
		
		// put the module info back into the connection
		Module module = info.getModule();
		connection.setModuleInfo(module.getID(),info);
		setSaveEnabled(true);
	}
	
	public void createDroppedChain(Chain chain,Point2D location) {
		getCamera().localToView(location);
		float x = (float) location.getX();
		float y = (float) location.getY();
		PChain p = new PChain(connection,chain,layer,linkLayer,x,y);
		setSaveEnabled(true);
	}
	
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
	
	public void updateSaveStatus() {
		boolean res  = false;
		Iterator  iter = layer.getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if(obj instanceof PModule) { 
				res = true;
				break;
			}
		}
		setSaveEnabled(res);
	}	
	
	public void save(String name,String desc) {	
		ChainManager manager = connection.getChainManager();
		Chain chain  = manager.createChain(name,desc);
		
		//populate chains
		addNodes(manager,chain);
		
		// links
		addLinks(manager,chain);
		// commit chain
		
		connection.commitTransaction();
		
		// create a chain info and add to chains
		
		connection.addChain(chain);
		
		// add this to the library
		libraryCanvas.drawChain(chain);
		libraryCanvas.scaleToSize();
	}
	
	private void addNodes(ChainManager manager,Chain chain) {
		PNode node;
		PModule mod;
		CNode chainNode;
				
		// iterate over layer, adding a node for each PModule
		Iterator iter = layer.getChildrenIterator();
		while (iter.hasNext()) {
			node = (PNode) iter.next();
			if (node instanceof PModule) {
				mod = (PModule) node;
				chainNode =  (CNode) manager.addNode(chain,mod.getModule());
			 	mod.setNode(chainNode);
			}
		}
	}
	
	private void addLinks(ChainManager manager,Chain chain) {
		PNode node;
		PParamLink link;
		
		System.err.println("adding links");
		Iterator iter = linkLayer.linkIterator();
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
				System.err.println("adding link...");
				manager.addLink(chain,fromNode,fromOutput,toNode,toInput);
			}
		}
	}
	
	public void setLibraryCanvas(PChainLibraryCanvas libraryCanvas) {
		this.libraryCanvas = libraryCanvas;
	}
 }