/*
 * org.openmicroscopy.vis.piccolo.PPaletteCanvas
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
import edu.umd.cs.piccolo.util.PBounds;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.ModuleInfo;
import java.util.Iterator;
import java.awt.dnd.DragSourceAdapter;
import java.awt.dnd.DragSourceEvent;
import java.awt.dnd.DragGestureListener;
import java.awt.dnd.DragSource;
import java.awt.dnd.DnDConstants;
import java.awt.dnd.DragGestureEvent;
import java.awt.datatransfer.StringSelection;



/** 
 * Extends PCanvas to provide funct?ionality necessary for a piccolo canvas.<p> 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PPaletteCanvas extends PCanvas implements DragGestureListener {
	
	private Connection connection;
	
	private static final float GAP=30f;
	private static final float TOP=20f;
	private static final int BORDER=20;
	
	private DragSourceAdapter dragListener;
	private DragSource dragSource;

	private float x,y;
	private float maxWidth = 0f;
	private float maxHeight = 0;
	
	private PLayer layer;
	
	private PModule selected;
	
	public PPaletteCanvas(Connection connection) {
		super();	
		removeInputEventListener(getPanEventHandler());
		addInputEventListener(new PPaletteEventHandler(this));
		layer = getLayer();
		this.connection = connection;
		// this draglistener doesn't do anything, but is needed to 
		// satisfy API.
		dragListener = new DragSourceAdapter() {
			public void dragExit(DragSourceEvent dse) {
			}
		};
		dragSource = new DragSource();
		dragSource.createDefaultDragGestureRecognizer(this,
			DnDConstants.ACTION_MOVE,this);
		populate();
	}
	
	/** 
	 * Populate the Canvas with nodes for each of the modules. 
	 * This procedure is called when the Connection object has completed
	 * loading the module information from the database.<p>
	 * 
	 * The canvas is populated in columns of 5 modules each.
	 * 
	 * @param connection The connection to the database.
	 * 
	 */
	
	private void populate() {
		
		x = 0;
		y = TOP;
		
		int i =0;
		Iterator iter = connection.getModuleIterator();
		while (iter.hasNext()) {
			ModuleInfo info = (ModuleInfo) iter.next();
			displayModule(info);
			i++;
			if ((i % 5) == 0) { // at the start of a new column 
				x += 100+maxWidth;
				y = TOP;
				maxWidth =0;
			}
		}
		System.err.println("final height is "+y);
		//getCamera().animateViewToIncludeBounds(layer.getFullBoundsReference(),0);
	}
	
	public void scaleToCenter(double scale) {
		PBounds b = layer.getFullBoundsReference();
		System.err.println("scaling to "+scale);
		getCamera().scaleView(scale);
		
	}

	/** 
	 * Create a node for each module, add it to the canvas,
	 * update position of each one, and track maximum width - for
	 * layout of subsequent columns.<p>
	 * 
	 * @param module The module to be displayed.
	 */	
	private void displayModule(ModuleInfo modInfo) {
		
		PModule mNode = new PModule(connection,modInfo,x,y);
		modInfo.addModuleWidget(mNode);
		float h = (float) mNode.getBounds().getHeight();
		y += h+GAP;
		layer.addChild(mNode);
		float nodeWidth = (float) mNode.getBounds().getWidth();
		if (nodeWidth > maxWidth)
			maxWidth=nodeWidth;
		if (y > maxHeight)
			maxHeight = y;
	}
	
	public int getPaletteWidth() {
		return (int) layer.getFullBoundsReference().getWidth()+BORDER;
	}
	
	public int getPaletteHeight() {
		return (int) maxHeight+BORDER;
	}
	
	public void setSelected(PModule module) {
		selected = module;
	}
	
	/**
	 * this is a bit of hackery - because we don't want to go through the 
	 * pain of making RemoteModules serializable, we package up the id of the
	 * module as a StringSelection and use it as the instance of Transferable
	 * needed to do the drag and drop. The receiver of the drop can unpackage it
	 * and identfy the module via the connection object.
	 * 
	 * @see java.awt.dnd.DragGestureListener#dragGestureRecognized(java.awt.dnd.DragGestureEvent)
	 */
	public void dragGestureRecognized(DragGestureEvent event) {
		if (selected != null) {
			selected.setModulesHighlighted(false);
			int id = selected.getModule().getID();
			String s = Integer.toString(id);
			StringSelection text = new StringSelection(s);
			System.err.println("dragging..."+s);
			dragSource.startDrag(event,DragSource.DefaultMoveDrop,text,dragListener);
		}
	}
}