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
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;
import org.openmicroscopy.ModuleCategory;
import org.openmicroscopy.Module;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.Modules;
import org.openmicroscopy.vis.ome.ModuleInfo;
import java.util.Iterator;
import java.util.List;
import java.awt.Font;
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
	
	private static final Font NAME_FONT = new Font("Helvetica",Font.PLAIN,24);
	
	
	private static final float HGAP=30f;
	private static final float TOP=20f;
	private static final float LEFT=20f;
	private static final int BORDER=20;
	
	
	
	private DragSourceAdapter dragListener;
	private DragSource dragSource;

	private float x=LEFT+HGAP;
	private float y= TOP;
	private float VGAP=20f;
	private float NAME_INSET=20;
	private float maxWidth = 0;
	private float maxHeight = 0;
	private float categoryWidth =0;
	
	private Connection connection;
	private Modules modules;

	
	private PLayer layer;
	private PLayer categoryLayer = new PLayer();
	private PModule selected;
	
	private int modCount = 0;
	
	public PPaletteCanvas() {
		super();
		removeInputEventListener(getPanEventHandler());
		addInputEventListener(new PPaletteEventHandler(this));
		layer = getLayer();
		layer.addChild(categoryLayer);
		categoryLayer.moveToBack();
		dragListener = new DragSourceAdapter() {
			public void dragExit(DragSourceEvent dse) {
			}
		};
		dragSource = new DragSource();
				dragSource.createDefaultDragGestureRecognizer(this,
					DnDConstants.ACTION_MOVE,this);
		
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
	public void setConnection(Connection connection) {
		
		this.connection = connection;
		modules = connection.getModules();
		
		// do it by categories
		Iterator iter = modules.rootCategoryIterator();
		while (iter.hasNext()) {
			ModuleCategory cat = (ModuleCategory) iter.next();
			displayModulesByCategory(cat);			
		}
		// do uncategorized.
		 				
		float top=y;
		displayCategoryName("");
		categoryWidth=0;
		iter = modules.uncategorizedModuleIterator();
		while (iter.hasNext()) {
			ModuleInfo info = (ModuleInfo) iter.next();
			displayModule(info);
		}
		// box up this row.
		newRow();
		float bottom = y;
		decorateCategory(top,bottom,categoryWidth);
		System.err.println("bottom y is "+y);
	}
	
	private void displayModulesByCategory(ModuleCategory cat) {
		// display all modules for this category
		List mods = cat.getModules();
		Iterator iter  = mods.iterator();
		
		float top = y;
		displayCategoryName(cat.getName());
		while (iter.hasNext()) {
			Module mod = (Module) iter.next();
			ModuleInfo info = modules.getModuleInfo(mod);
			displayModule(info);
		}
		
		// recursively iterate over children categories.
		List children = cat.getChildren();
		iter = children.iterator();
		while (iter.hasNext()) {
			ModuleCategory child = (ModuleCategory) iter.next();
			displayModulesByCategory(child);
		}

		//	make a new row
		newRow();
		
		//	do something to box up this row.
		float bottom =y;		
		decorateCategory(top,bottom,categoryWidth);
		System.err.println("bottom y is "+y);

		categoryWidth = 0;
	}
	
	private void decorateCategory(float top,float bottom,float width) {
		float height = bottom-top;
		
		PCategoryBox box = new PCategoryBox(LEFT,top,width,height);
		categoryLayer.addChild(box);
		box.moveToBack();
		
		y+= VGAP;
	}
	
	private void displayCategoryName(String name) {
		y+=VGAP;
		float nameX = LEFT+NAME_INSET;
		if (name.compareTo("") !=0) {// if there is a name
			PText nameText = new PText(name);
			nameText.setFont(NAME_FONT);
			nameText.setPickable(false);
			categoryLayer.addChild(nameText);
			nameText.moveToFront();
			System.err.println("translating name label to "+nameX+","+y);
			nameText.setOffset(nameX,y);
			y += nameText.getFullBoundsReference().getHeight();
			y+=VGAP;
		}
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
		float w = (float) mNode.getBounds().getWidth();
		x += w+HGAP;
		layer.addChild(mNode);
		float nodeHeight = (float) mNode.getBounds().getHeight();
		if (nodeHeight > maxHeight)
			maxHeight=nodeHeight;
		if (x > maxWidth)
			maxWidth = x;
		if (x > categoryWidth)
			categoryWidth = x;
			
		modCount++;
		if ((modCount % 4) == 0) { // at the start of a new column
			newRow();
		}
	}
	
	private void newRow() {
		modCount = 0;
		x = LEFT+HGAP;
		y += VGAP+maxHeight;
		maxHeight = 0;
	}

	
	public void scaleToSize(double width,double height) {
		
		double scale;
		
		PBounds b = layer.getGlobalFullBounds();
		
		
		double paletteHeight = b.getY()+b.getHeight();
		System.err.println("pallete height is "+paletteHeight);
		// I don't know why, but I need to pad the height somehow.
		paletteHeight+= 6*BORDER;	
		System.err.println("adjusted palette height is "+paletteHeight);
		double vertScale = height/paletteHeight;
		System.err.println("vert scale is "+vertScale);
		
		double paletteWidth = b.getX()+b.getWidth();
		double horizScale = width/paletteWidth;
		System.err.println("horiz scale is "+horizScale);
		if (horizScale < vertScale)
			scale = horizScale;
		else 
			scale = vertScale;
		System.err.println("scaling to "+scale);
		getCamera().scaleView(scale);
		
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
	
	
	public void logout() {
		layer.removeAllChildren();
		categoryLayer  = new PLayer();
		layer.addChild(categoryLayer);
		categoryLayer.moveToBack();
		x = LEFT+HGAP;
		y = TOP;
		maxWidth=maxHeight=0;
		getCamera().setViewScale(1.0);
	}
}