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
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PPaintContext;
import edu.umd.cs.piccolo.PCamera;
import org.openmicroscopy.ModuleCategory;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CModule;
import org.openmicroscopy.vis.ome.Modules;
import org.openmicroscopy.vis.dnd.ModuleSelection;
import java.util.Iterator;
import java.util.List;
import java.awt.Font;
import java.awt.geom.Point2D;
import java.util.Vector;
import java.awt.dnd.DragSourceAdapter;
import java.awt.dnd.DragSourceEvent;
import java.awt.dnd.DragGestureListener;
import java.awt.dnd.DragSource;
import java.awt.dnd.DnDConstants;
import java.awt.dnd.DragGestureEvent;




/** 
 * Extends PCanvas to provide functionality necessary for a piccolo canvas.<p> 
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
	
	// arbitrary extent for drawing things -we force it all into a 100x100
	// square. Later, we'll scale this to fit the window, whatever the
	// actual window size may be.
	private static final float CANVAS_EXTENT =100f;
	
	
	
	private DragSourceAdapter dragListener;
	private DragSource dragSource;

	private float VGAP=10f;
	private float NAME_INSET=20;
	
	
	private Connection connection;
	private Modules modules;

	
	private PLayer layer;

	private PModule selected;
		
	public PPaletteCanvas() {
		super();
		setDefaultRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setInteractingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setAnimatingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		removeInputEventListener(getPanEventHandler());
		removeInputEventListener(getZoomEventHandler());
		addInputEventListener(new PPaletteEventHandler(this));
		layer = getLayer();
		dragListener = new DragSourceAdapter() {
			public void dragExit(DragSourceEvent dse) {
			}
		};
		dragSource = new DragSource();
		dragSource.createDefaultDragGestureRecognizer(this,
				DnDConstants.ACTION_COPY,this);

		final PCamera camera = getCamera();
	       
		camera.addInputEventListener(new PPaletteToolTipHandler(camera));
		
		
	}
	
	/** 
	 * Populate the Canvas with nodes for each of the modules. 
 	 * This procedure is called when the Connection object has completed
 	 * loading the module information from the database.<p>
 	 * 
 	 
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
			connection.setStatusLabel("Arranging Modules.."+cat.getName());
			//System.err.pr(" Arranging modules in category..."+cat.getName());
			displayModulesByCategory(layer,cat);			
		}
		// do uncategorized.
		
	
		PCategoryBox  box = decorateCategory(layer);
		displayCategoryName(box,"Uncategorized");
		connection.setStatusLabel("Arranging Modules.. Uncategorized");
		iter = modules.uncategorizedModuleIterator();
		
		//System.err.pr("arranging uncategorized modules");
		while (iter.hasNext()) {
			CModule mod = (CModule) iter.next();
			displayModule(box,mod);
		} 
		
		arrangeChildren(box);
		
		//System.err.pr("arranging children of top layer ");
		arrangeChildren(layer);
		PBounds b = new PBounds();
		b = layer.getUnionOfChildrenBounds(b);
		//System.err.pr("layer bounds are "+b.getWidth()+","+b.getHeight());
		layer.setBounds(b);
		layer.repaint();
		
	}
	
	/*
	 * Add the modules that are children of this category, 
	 * recursively display the modules in subcategories, and call
	 * arrangeChildren() to layout the results.
	 */
	private void displayModulesByCategory(PNode parent,ModuleCategory cat) {
		// display all modules for this category
		List mods = cat.getModules();
		Iterator iter  = mods.iterator();
		
		PCategoryBox box = decorateCategory(parent);
		displayCategoryName(box,cat.getName());
		//System.err.println("displaying category..."+cat.getName());
		while (iter.hasNext()) {
			CModule mod = (CModule) iter.next();
			displayModule(box,mod);
		}
		
		// recursively iterate over children categories.
		List children = cat.getChildren();
		iter = children.iterator();
		while (iter.hasNext()) {
			ModuleCategory child = (ModuleCategory) iter.next();
			displayModulesByCategory(box,child);
						
		}
	
		arrangeChildren(box);
	}
	
	private PCategoryBox decorateCategory(PNode parent) {
		
		PCategoryBox box = new PCategoryBox();
		//System.err.println("creating category box "+box);
		//categoryLayer.addChild(box);
		parent.addChild(box);
		box.moveToBack();
		return box;
	}
	
	private void displayCategoryName(PCategoryBox box,String name) {
		if (name.compareTo("") !=0) {// if there is a name
		//System.err.println("next category at "+VGAP); //was y
			PText nameText = new PText(name);
			nameText.setFont(NAME_FONT);
			nameText.setPickable(false);
			box.addLabel(nameText);
			nameText.setScale(2);
			nameText.moveToFront();
			//System.err.println("translating name label to "+nameX+","+y);
			nameText.setOffset(PConstants.CATEGORY_LABEL_OFFSET_X,
				PConstants.CATEGORY_LABEL_OFFSET_Y);
		}
	}

	/** 
	 * Create a node for each module, add it to the canvas,
	 * update position of each one, and track maximum width - for
	 * layout of subsequent columns.<p>
	 * 
	 * @param box    The parent of this module
	 * @param module The module to be displayed.
	 */	
	private void displayModule(PCategoryBox box,CModule mod) {
		
		PModule mNode = new PModule(connection,mod);
		mod.addModuleWidget(mNode);
		box.addChild(mNode);
		mNode.setOffset(0,0);
	}	


	/*
	 * arrangeChildren() does a pseudo-treemap layout, attempting
	 * to put things in boxes such that we don't get absurdly bad aspect
	 * ratios. This isn't as nice or as efficient as treemap, but it's 
	 * simpler.
	 * 
	 */
	private void arrangeChildren(PNode node) {
	
		float height = 0;
		float width = 0;
		Iterator iter = node.getChildrenIterator();
		float y =TOP;
		Vector curStrip = new Vector();
		PBufferedNode box;
		double stripAspectRatio = 0;
		double newAspectRatio = 0;
		float x = LEFT+HGAP;
		float maxHeight = 0;
		float maxWidth =0;
		Object obj=null;
		PBounds b;
			
		if (node instanceof PCategoryBox) {
			PCategoryBox catBox = (PCategoryBox) node;
			y += catBox.getLabelHeight()+VGAP;
		}
		for (; ; ) {
			// get next item if i need  it.
			if (obj == null) {
				if (iter.hasNext()) {
					obj = iter.next();
					if (!(obj instanceof PBufferedNode)) {
						obj = null;
						continue;
					}
				}
				else
					break;
			}
			
			//add the next element in the list to a vector
			box = (PBufferedNode) obj;
			curStrip.add(box);
			//System.err.println("adding box...");
			// place the items in the current strip.
			
			Point2D pt = placeChildren(node,curStrip,y);
			
			
		
			// find out how high and wide the strip is.
			
			float ytemp = (float)pt.getY()+VGAP;// was y+(float)..
			//System.err.println("children placed. y is "+y+", ytemp is "+ytemp);
			//System.err.println("height is "+height);  
			if (ytemp-y > height) {// was -TOP
				height = ytemp-y; // height of whole thing  - was TOP
				//System.err.println("setting height to "+height);
			}
			if (pt.getX() > width)
				width = (float)pt.getX();
			newAspectRatio = calcAspectRatio(width,height);
			//System.err.println("new aspect ratio is "+newAspectRatio);
			// if we've increased the aspect ratio, that's no good.
			
			if (curStrip.size()>1 && newAspectRatio > stripAspectRatio) {
				//System.err.println("increased aspect ratio. Backing out...");
				
				// remove the last item from the strip.
				curStrip.remove(box);
				// do rest of strip without box
				pt = placeChildren(node,curStrip,y);
				//create a new strip and add curent box to it.
				curStrip.clear();
				// move onto the next line.
				y= (float)pt.getY()+VGAP;
				/*if (pt.getX() > width) {
					width = (float) pt.getX();
				}*/
				width =0;
			}	
			else { // it fits. move on.
				stripAspectRatio = newAspectRatio;
				obj = null;
			}
		}
		if (curStrip.size() > 0) {
			// place what's left over
			placeChildren(node,curStrip,y);
		}
		if (node instanceof PCategoryBox) {
			// adjust the size of the category box
			b = new PBounds();
			b = node.getUnionOfChildrenBounds(b);
			//System.err.println("finished with children. width is "+b.getWidth()
			//	+", height is "+b.getHeight());
			((PCategoryBox) node).setExtent(b.getWidth()+2*HGAP,b.getHeight()+4*VGAP);
		}
	} 
	
	private Point2D placeChildren(PNode parent,Vector v,float y) {
		float x = LEFT+HGAP;
		PBufferedNode node;
		Iterator iter = v.iterator();
		float maxHeight = 0;
		float childHeight = 0;
		float childWidth =0;
	
		// iterate through, placing nodes as need be.	
		while (iter.hasNext()) {
			node = (PBufferedNode) iter.next();
		//	System.err.println("placing something at "+x+","+y);
			//System.err.println("placing "+node);
			//System.err.println("at x="+x+", y="+y);
			node.setOffset(x,y);
		
			PBounds b = ((PNode) node).getBounds();
			//System.err.println("child height is "+childHeight);
			childHeight = (float) b.getHeight();
			childWidth = (float) b.getWidth();
		
			x += childWidth+HGAP;
			if (childHeight > maxHeight)
				maxHeight = childHeight;
		} 
		//System.err.println("max height is "+maxHeight);
		return new Point2D.Float(x-(LEFT+HGAP),y+maxHeight);
	}
	

	private double calcAspectRatio(float width,float height) {
		//System.err.println("calculating aspect ratio");
		//System.err.println("widht is "+width+", height is "+height);
		if (width > height) 
			return (double) width/height;
		else
			return (double) height/width;
	}
	
	public void scaleToSize() {

		
		PBounds b = getBufferedBounds();
		getCamera().animateViewToCenterBounds(b,true,0);
					
	}


	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX()-PConstants.BORDER,
			b.getY()-PConstants.BORDER,b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER); 
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
			ModuleSelection text = new ModuleSelection(id);
		//	System.err.println("dragging.module set module selection.."+id);
			dragSource.startDrag(event,DragSource.DefaultMoveDrop,text,dragListener);
		}
	}
	
	
	public void logout() {
		layer.removeAllChildren();
		//categoryLayer  = new PLayer();
		//layer.addChild(categoryLayer);
		//categoryLayer.moveToBack();
	}
}