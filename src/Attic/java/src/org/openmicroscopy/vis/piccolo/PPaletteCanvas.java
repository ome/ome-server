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
import org.openmicroscopy.vis.chains.Controller;
import org.openmicroscopy.vis.chains.ModuleTreeNode;
import org.openmicroscopy.vis.chains.ModulePaletteFrame;
import org.openmicroscopy.vis.util.SwingWorker;
import java.util.Iterator;
import java.util.List;
import java.util.Collection;
import java.awt.Font;
import java.awt.geom.Point2D;
import java.util.Vector;
import java.awt.dnd.DragSourceAdapter;
import java.awt.dnd.DragSourceEvent;
import java.awt.dnd.DragGestureListener;
import java.awt.dnd.DragSource;
import java.awt.dnd.DnDConstants;
import java.awt.dnd.DragGestureEvent;
import java.util.TreeSet;



/** 
 * The {@link PCanvas} that holds the module palette 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PPaletteCanvas extends PCanvas implements DragGestureListener,
	PBufferedObject {
	
	/**
	 * Typeface for category names
	 */
	private static final Font NAME_FONT = new Font("Helvetica",Font.PLAIN,24);
	
	/**
	 * Some screen layout parameters
	 */
	private static final float HGAP=30f;
	private static final float TOP=20f;
	private static final float LEFT=20f;
	private static final float VGAP=10f;
	private static final float NAME_INSET=20;
	private static final String UNCAT_NAME="Uncategorized";
	
	/**
	 * Support for data transfer - dragging modules onto a {@link PChainCanvas}
	 */
	private DragSourceAdapter dragListener;
	private DragSource dragSource;
	
	/**
	 * The database connection
	 */
	private Connection connection;
	
	/** 
	 * The Modules in the database
	 */
	private Modules modules;

	/**
	 * The canvas scenegraph layer
	 */
	private PLayer layer;

	/** 
	 * The currently active {@link PModule}
	 */
	private PModule selected;
	
	/**
	 * The nodes in the module Tree that we build up as we go along
	 *
	 */
	private ModuleTreeNode treeNode = null;
	
	
	/**
	 * The event handler for this canvas
	 *
	 */
	private PPaletteEventHandler handler;
	
	/**
	 * the frame that this goes in
	 *
	 */
	private ModulePaletteFrame frame;
	
	
	public PPaletteCanvas(ModulePaletteFrame frame) {
		super();
		this.frame = frame;
		// set up rendering, colors, and event listeners
		setDefaultRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setInteractingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setAnimatingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setBackground(PConstants.CANVAS_BACKGROUND_COLOR);
		removeInputEventListener(getPanEventHandler());
		removeInputEventListener(getZoomEventHandler());
		handler = new PPaletteEventHandler(this);
		addInputEventListener(handler);
		layer = getLayer();
		
		// configure data transfer
		dragListener = new DragSourceAdapter() {
			public void dragExit(DragSourceEvent dse) {
			}
		};
		dragSource = new DragSource();
		dragSource.createDefaultDragGestureRecognizer(this,
				DnDConstants.ACTION_COPY,this);

		// set up tooltips.
		final PCamera camera = getCamera();
		camera.addInputEventListener(new PPaletteToolTipHandler(camera));
	}
	
	/** 
	 * Populate the Canvas with nodes for each of the modules. 
 	 * This procedure is called when the Connection object has completed
 	 * loading the module information from the database.<p>
 	 * Arrange the categorized modules first, followed by the uncategorized.
 	 * For the categorized modules, recurse as needed to handle subcategories
 	 * 
  	 * @param connection The connection to the database.
  	 * @param controller The application controller
  	 *  
 	 */
	public void populate(Connection connection,final Controller controller) {
		
		this.connection = connection;
		modules = connection.getModules();
		
		treeNode = new ModuleTreeNode();
		
		layer.setVisible(false);
		final SwingWorker worker = new SwingWorker() {
			
			public Object construct() {
				Iterator iter = modules.rootCategoryIterator();
					while (iter.hasNext()) {
					ModuleCategory cat = (ModuleCategory) iter.next();
					controller.setStatusLabel("Arranging Modules.."+cat.getName());
		
					displayModulesByCategory(layer,cat,treeNode);			
				}
	
				// do uncategorized.
				PCategoryBox  box = decorateCategory(layer,UNCAT_NAME);
				displayCategoryName(box,UNCAT_NAME);
				controller.setStatusLabel("Arranging Modules.. Uncategorized");
				iter = modules.uncategorizedModuleIterator();
	
				ModuleTreeNode uncatNode = new ModuleTreeNode("Uncategorized");
				treeNode.add(uncatNode);
	
				while (iter.hasNext()) {
					CModule mod = (CModule) iter.next();
					displayModule(box,mod,uncatNode);
				} 
	
				// arrange the uncategorized modules
				arrangeChildren(box);
	
				// arrange all of the categories
				arrangeChildren(layer);		
				return null;		
			}
			
			public void finished() {
				layer.setVisible(true);
				getCamera().animateViewToCenterBounds(layer.getGlobalFullBounds(),
					true,PConstants.ANIMATION_DELAY);
				controller.finishInitThread();
			}
		};
		worker.start();
	}
	
	/*
	 * Add the modules that are children of this category, 
	 * and recursively display the modules in subcategories, all the while 
	 * doing no layout on the results. After all of the modules in the category
	 * are displayed, call {@link arrangeChildren()} to layout the results.
	 * 
	 * @param parent the parent node that will old all of the modules
	 * @param cat the {@link ModuleCategory} that the nodes fit in.
	 * @param treeParent the {@link ModuleTreeNode} for the containing category
	 */
	private void displayModulesByCategory(PNode parent,ModuleCategory cat,
				ModuleTreeNode treeParent) {
		// display all modules for this category
		List mods = cat.getModules();
		Iterator iter  = mods.iterator();

		//decorate the category with a box.		
		PCategoryBox box = decorateCategory(parent,cat.getName());
		displayCategoryName(box,cat.getName());
		ModuleTreeNode catNode = new ModuleTreeNode(cat); // was .getName(),cat.getID());
		treeParent.add(catNode);

		// display the module in the box.
		while (iter.hasNext()) {
			CModule mod = (CModule) iter.next();
			displayModule(box,mod,catNode);
		}
		
		// recursively iterate over children categories.
		List children = cat.getChildren();
		iter = children.iterator();
		while (iter.hasNext()) {
			ModuleCategory child = (ModuleCategory) iter.next();
			displayModulesByCategory(box,child,catNode);
						
		}
		// arrnange everything.
		arrangeChildren(box);
	}
	
	/**
	 * Draw the box around the category
	 * @param parent the parent {@link PNode} that will hold this category box
	 * @return a new box that will go around the items in a category
	 */
	private PCategoryBox decorateCategory(PNode parent,String name) {
		
		PCategoryBox box = new PCategoryBox(name);
		//System.err.println("creating category box "+box);
		//categoryLayer.addChild(box);
		parent.addChild(box);
		box.moveToBack();
		return box;
	}
	
	/**
	 * Display the name of the category in a {@link PCategoryBox}
	 * @param box
	 * @param name
	 */
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
	 * and update the list of widgets for that module.
	 * 
	 * @param box    The parent of this module
	 * @param module The module to be displayed.
	 * @param catNode The tree node for the containing category
	 */	
	private void displayModule(PCategoryBox box,CModule mod,
		ModuleTreeNode catNode) {
		
		PModule mNode = new PModule(connection,mod);
		mod.addModuleWidget(mNode);
		box.addChild(mNode);
		mNode.setOffset(0,0);
		
		ModuleTreeNode modNode = new ModuleTreeNode(mod); // was .getName(),mod.getID());
		catNode.add(modNode);
		mod.setFrame(frame);
	}	

	public ModuleTreeNode getModuleTreeNode() {
		return treeNode;
	}
	
	/**
	 * Highlight a module, based on an event from the module {@link JTree}
	 * @param id the module id
	 */
	public void highlightModule(CModule module) {
		handler.highlightModules(module); 	
		
		Collection result = layer.getAllNodes();
		Iterator iter = result.iterator();
		while (iter.hasNext()) {
			PNode node = (PNode) iter.next();
			if (node instanceof PModule) {
				PModule mod = (PModule) node;
				if (mod.getModule() == module) {
					//	zoom in to it. 
					PBufferedNode cBox = (PBufferedNode) node;				
					PBounds b = cBox.getBufferedBounds();
					PCamera camera = getCamera();
					camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY); 
					return;
				}
			}
		}
		
	}
	
	public void highlightCategory(String name) {
		Collection result = layer.getAllNodes();
		Iterator iter = result.iterator();
		while (iter.hasNext()) {
			PNode node = (PNode) iter.next();
			if (node instanceof PCategoryBox) {
				PCategoryBox cb = (PCategoryBox)node;
				if (cb.getName().compareTo(name) ==0) {
						//	zoom in to it. 
					PBufferedNode cBox = (PBufferedNode) node;				
					PBounds b = cBox.getBufferedBounds();
					PCamera camera = getCamera();
					camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY); 
					return;
				}
			} 
		}
	}
	
	public void unhighlightModules() {
		handler.unhighlightModules();
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
		
		List children = node.getChildrenReference();
		TreeSet childrenTree = new TreeSet(children);
		Iterator iter = childrenTree.iterator();
		// as opposed to Iterator iter = node.getChildrenIterator();
		
		float y =TOP;
		Vector curStrip = new Vector();
		PBufferedNode box;
		//double stripAspectRatio = 0;
		//double newAspectRatio = 0;
		float x = LEFT+HGAP;
		float maxHeight = 0;
		float maxWidth =0;
		Object obj=null;
		PBounds b;
		double childrenCountRoot = Math.sqrt(node.getChildrenCount());
		
		//System.err.println("arranging children of "+node);
		// if the node is a categorybox, skip over the label	
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
			
			// place the items in the current strip.
			Point2D pt = placeChildren(curStrip,y);
			
			
		
			// find out how high and wide the strip is.
			float ytemp = (float)pt.getY()+VGAP;  
			if (ytemp-y > height) {
				height = ytemp-y; 
			}
			if (pt.getX() > width)
				width = (float)pt.getX();
			// calculate the aspect ratio
		//	newAspectRatio = calcAspectRatio(width,height);
			//System.err.println("new aspect ratio is "+newAspectRatio);
			//System.err.println("old was "+stripAspectRatio);
			// if we've increased the aspect ratio, that's no good.
			if (curStrip.size()>childrenCountRoot )  {  
				// remove the last item from the strip.
				curStrip.remove(box);
				// do rest of strip without that last box
				pt = placeChildren(curStrip,y);
				//create a new strip and add curent box to it.
				curStrip.clear();
				// move onto the next line.
				y= (float)pt.getY()+VGAP;
				
				width =0;
			}	
			else { // it fits. move on.
		//		stripAspectRatio = newAspectRatio;
				obj = null;
			}
		}
		if (curStrip.size() > 0) {
			// place what's left over
			placeChildren(curStrip,y);
		}
		if (node instanceof PCategoryBox) {
			// adjust the size of the category box
			b = new PBounds();
			b = node.getUnionOfChildrenBounds(b);
			((PCategoryBox) node).setExtent(b.getWidth()+2*HGAP,b.getHeight()+4*VGAP);
		}
	} 
	
	/**
	 * Place the nodes in a list in a row
	 * @param parent the parent node
	 * @param v a vector containing the nodes to place
	 * @param y the y-coordinate for the upper-left corner of each node.
	 * @return a point that contains the width of the row and 
	 * 		the y coordinate of the bottom of the row
	 */
	private Point2D placeChildren(Vector v,float y) {
		float x = LEFT+HGAP;
		PBufferedNode node;
		Iterator iter = v.iterator();
		float maxHeight = 0;
		float childHeight = 0;
		float childWidth =0;
	
		// iterate through, placing nodes as need be.	
		while (iter.hasNext()) {
			node = (PBufferedNode) iter.next();
			node.setOffset(x,y);
		
			PBounds b = ((PNode) node).getBounds();
			childHeight = (float) b.getHeight();
			childWidth = (float) b.getWidth();
		

			x += childWidth+HGAP;
			// track the height of the row
			if (childHeight > maxHeight)
				maxHeight = childHeight;
		} 
		
		// return a point that indicates how wide the row is and the 
		// y-coordinate of the bottom.
		return new Point2D.Float(x-(LEFT+HGAP),y+maxHeight);
	}
	
	/**
	 * 
	 * @param width
	 * @param height
	 * @return the aspect ratio: the larger of width/height and height/width
	 */
	private double calcAspectRatio(float width,float height) {

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
	 * @see java.awt.dnd.DragGestureListener#
	 * 	dragGestureRecognized(java.awt.dnd.DragGestureEvent)
	 */
	public void dragGestureRecognized(DragGestureEvent event) {
		if (selected != null) {
			selected.setModulesHighlighted(false);
			int id = selected.getModule().getID();
			ModuleSelection text = new ModuleSelection(id);
			dragSource.startDrag(event,DragSource.DefaultMoveDrop,
					text,dragListener);
		}
	}
}