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
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PCamera;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.ModuleInfo;
import org.openmicroscopy.Module;
import java.awt.dnd.DropTargetListener;
import java.awt.dnd.DropTargetDragEvent;
import java.awt.dnd.DropTargetEvent;
import java.awt.dnd.DropTargetDropEvent;
import java.awt.dnd.DropTarget;
import java.awt.dnd.DnDConstants;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.Transferable;
import java.awt.geom.Point2D;
import java.util.List;

/** 
 * Extends PCanvas to provide functionality necessary for a piccolo canvas.<p> 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PChainCanvas extends PCanvas implements DropTargetListener {
	
	private Connection connection=null;
	private int modCount;
	private PLayer layer;
	
	private float x,y;
	
	private PLayer linkLayer;
	private PChainEventHandler handler;
	private DropTarget dropTarget = null;
	
	public PChainCanvas(Connection c) {
		super();
		this.connection  = c;
		layer = getLayer();
	
		removeInputEventListener(getPanEventHandler());
		linkLayer = new PLayer();
		getCamera().addLayer(linkLayer);
		linkLayer.moveToFront();
		handler = new PChainEventHandler(this,linkLayer);
		addInputEventListener(handler);
		dropTarget = new DropTarget(this,this);
		

		final PCamera camera = getCamera();
	       
		camera.addInputEventListener(new PChainToolTipHandler(camera));
		
		
	}
	

	
	public void dragEnter(DropTargetDragEvent e) {
		System.err.println("drag enter canvas");
		removeInputEventListener(handler);
		e.acceptDrag (DnDConstants.ACTION_MOVE);
	
	}
	
	public void drop(DropTargetDropEvent e) {
		try {
			Transferable transferable =  e.getTransferable();
			System.err.println("got a drop on canvas");
			if (transferable.isDataFlavorSupported(DataFlavor.stringFlavor)) {
				e.acceptDrop(DnDConstants.ACTION_MOVE);
				String s = (String)transferable.getTransferData(
					DataFlavor.stringFlavor);
				System.err.println("just dropped "+s+" onto chain canvas.");
				e.getDropTargetContext().dropComplete(true);
				int id = Integer.parseInt(s);
				ModuleInfo mInfo = connection.getModuleInfo(id);
				System.err.println("module is "+mInfo.getModule().getName());
				Point2D loc = e.getLocation();
				createDroppedModule(mInfo,loc);
				addInputEventListener(handler);
			}
			else {
				System.err.println("string flavor not supported");
				clearDrop(e);
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
}