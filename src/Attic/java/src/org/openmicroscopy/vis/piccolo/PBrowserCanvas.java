/*
 * org.openmicroscopy.vis.piccolo.PBrowserCanvas
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


import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.ome.CProject;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.chains.events.SelectionEvent;
import org.openmicroscopy.vis.chains.events.SelectionEventListener;
import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PPaintContext;
import java.util.Iterator;
import java.util.TreeSet;
import java.util.HashMap;
import java.util.Vector;
import java.util.Collection;
//import java.awt.event.ComponentAdapter;
//import java.awt.event.ComponentEvent;

/** 
 * A {@link PCanvas} for viewing images in a dataset 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PBrowserCanvas extends PCanvas implements PBufferedObject, 
		SelectionEventListener {
	
	/**
	 * The initial magnification of the  canvas
	 */
	private static float INIT_SCALE=1.0f;
	
	/**
	 * Database connection 
	 */
	private Connection connection=null;
	
	
	/**
	 * The layer for the canvas. 
	 */
	private PLayer layer;
	
		
	
	private static float VGAP=10;
	private static float HGAP=5;

	private double x,y;
	private double maxHeight = 0;
	
	private HashMap datasetWidgets = new HashMap();
	
	private Collection allDatasets;
	
	private PExecutionList executionList;
	
	private double totalArea = 0;
	private double scaleFactor;
	private double screenArea;
	private Vector strips;
	private double screenHeight = 0;
	private double screenWidth =0;
	
	private PDataset lastRolledOver = null;
	
	public PBrowserCanvas(Connection c) {
		super();
		this.connection  = c;
		layer = getLayer();
		
		
		setDefaultRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setInteractingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setAnimatingRenderQuality(PPaintContext.HIGH_QUALITY_RENDERING);
		setBackground(PConstants.CANVAS_BACKGROUND_COLOR);
		 
		
		//	remove handlers
		 removeInputEventListener(getZoomEventHandler());
		 removeInputEventListener(getPanEventHandler());
		 
		//	install custom event handler
		addInputEventListener(new PBrowserEventHandler(this)); 
			
		
			// setup tool tips.
		final PCamera camera = getCamera();
		camera.addInputEventListener(new PImageToolTipHandler(camera));
	//	getCamera().setViewScale(INIT_SCALE);
		getCamera().animateViewToCenterBounds(getBufferedBounds(),true,0);
	
		allDatasets = connection.getDatasetsForUser();
		
	
	}
	
	
	
	
	public double getArea(CDataset d) {
		if (d == null) 
			return 0;
		PDataset node;
		Object o = datasetWidgets.get(d);
		if (o != null) {
			node = (PDataset) o;
		}
		else {
			////System.err.println("creating new widget");
			node = new PDataset(d,connection);
			datasetWidgets.put(d,node);
		}
		if (node == null)
			return 0;
		node.clearWidths();
	//	node.calcArea();
		return node.getContentsArea();
	}
		
	
	
	public void displayDatasets(Collection datasets,final boolean v) {
		if (v== true)
			arrangeDisplay(datasets);
		doLayout(datasets,v);
		getCamera().animateViewToCenterBounds(getBufferedBounds(),true,
				PConstants.ANIMATION_DELAY);
	
	}
	
	// the guts of the dataset display thread
	
	private void arrangeDisplay(Collection datasets) {
		layer.removeAllChildren();
		if (datasets == null)
			return;
		//System.err.println("browser canvas. displaying datasets.");
		//System.err.println("width is "+getWidth()+", height is"+getHeight());
		
		totalArea = 0;
		Iterator iter = datasets.iterator();
		
		while (iter.hasNext()) {
			CDataset d = (CDataset) iter.next();
			double area = getArea(d);
			//System.err.println("dataset "+d.getID()+", area is "+area);
			totalArea += area;
		}
		
		//System.err.println("total area is "+totalArea);
		screenHeight = getHeight();
		screenWidth = getWidth();
		screenArea = screenHeight*screenWidth;
		//System.err.println("screen area is "+screenArea);
		
		scaleFactor = screenArea/totalArea;
		//System.err.println("scale factor is "+scaleFactor);
		strips = doTreeMap(datasets);
		// now, do the calculations
	}

	private void doLayout(Collection datasets,boolean layoutDatasets) {
		if (datasets == null)
			return;
		layer.setScale(1.0);
		System.err.println("in doLayout..");
		x = HGAP;
		y = 0;
		Iterator iter = strips.iterator();
		double maxHeight = 0;
		while (iter.hasNext()) {
			Vector strip = (Vector)iter.next();
			Iterator iter2 = strip.iterator();
			maxHeight = 0;
			while (iter2.hasNext()) {
				PDataset node = (PDataset) iter2.next();
				
				if (layoutDatasets == true) {
	//				System.err.println("laying out "+node.getDataset().getName());
					node.setOffset(0,0);
					node.layoutImages();
				}
				
				if (datasets.contains(node.getDataset())) {
					//System.err.println("laying out node "+node);
					//System.err.println(" at "+x+","+ y);
					node.setOffset(x,y);
					layer.addChild(node);
					x+= node.getGlobalFullBounds().getWidth();
					double height = node.getGlobalFullBounds().getHeight();
					if (height > maxHeight)
						maxHeight = height;
				}
				else {
					// not showing this node. remove it.
					// this way, it's not included in bounds.
					if (node.getParent() == layer)
						layer.removeChild(node);
				}	 
			}
			x =HGAP;
			y +=maxHeight;
		}
	}
	
	private double oldAspectRatio =0;
	private double newAspectRatio = 0;

	private Vector doTreeMap(Collection datasets) {
	
		//System.err.println("do treemap. dataset size is "+datasets.size());
		oldAspectRatio = 0;
		newAspectRatio = 0;
		Vector strips = new Vector();
		Vector strip = new Vector();
		
		Iterator iter = datasets.iterator();
		CDataset d = null;
		
		PDataset node=null;
		
		while (iter.hasNext())  {
			d = (CDataset) iter.next();
			//System.err.println("placing dataset "+d.getName()+" in treemap");
			node = (PDataset) datasetWidgets.get(d);
		
			
			// ok, do something with what is next.
			strip.add(node);
		
			// calc,update stats.
			getTreemapStripHeight(strip);
			
			//System.err.println("new aspect ratio is "+newAspectRatio);
			//System.err.println("old was..."+oldAspectRatio);
		
			
			if (strip.size()>1 &&  newAspectRatio > oldAspectRatio) {
				// move it to next strip.
				//System.err.println("moving to  anew strip...");
				strip.remove(node);
				Iterator iter2 = strip.iterator();
				while (iter2.hasNext()) {
					PDataset ds = (PDataset) iter2.next();
					ds.revertWidth();
				}
				strips.add(strip);
				strip = new Vector();
				newAspectRatio = oldAspectRatio = 0;
				strip.add(node);
				getTreemapStripHeight(strip);
			}
			// otherwise, keep what I've calculated.
				oldAspectRatio = newAspectRatio;
		}
		strips.add(strip);
		return strips;
	}
	
	private void  getTreemapStripHeight(Vector strip) {
		// get height
		//System.err.println("===getting treemap strip====");
		
		double stripArea =0;
		Iterator iter = strip.iterator();
		while (iter.hasNext()) {
			PDataset node = (PDataset) iter.next();
			double area = node.getContentsArea()*scaleFactor;
			//System.err.println("node scaled area is "+area);
			stripArea += area;
		}
		
		double ratio = stripArea/screenArea;
		double height = ratio * getHeight();
		//System.err.println(" strip area is "+stripArea);
		//System.err.println(" total area is "+screenArea);
		//System.err.println("ratio is "+ratio +" , height is "+height);
		// get width of each and update ratios;
		double width;
		int i =0;
		newAspectRatio = 0;
		iter = strip.iterator();
		while (iter.hasNext()) {
			PDataset node = (PDataset) iter.next();
			double area  =node.getContentsArea()*scaleFactor;
			width = area/height;
			//System.err.println("dataset  scaled area is "+area);
			//System.err.println("width is "+width);
			node.setWidth(width);
			if (width > height) 
				newAspectRatio += width/height;
			else 
				newAspectRatio += height/width;
			i++;
		}
		newAspectRatio = newAspectRatio/i;
	}
	
	
	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX()-PConstants.SMALL_BORDER,
			b.getY()-PConstants.SMALL_BORDER,
			b.getWidth()+2*PConstants.SMALL_BORDER,
			b.getHeight()+2*PConstants.SMALL_BORDER); 
	}
	
	
	
	public void displayAllDatasets() {
		TreeSet datasets= new TreeSet(connection.getDatasetsForUser());
		displayDatasets(datasets,true);
		
		// after initial display
		// revise when resized
     	/*addComponentListener(
				new ComponentAdapter() {
					public void componentResized(ComponentEvent e) {
						displayDatasets(true);
					}
				});*/
	}
	
	public void selectionChanged(SelectionEvent e) {
		Collection sets = null;
		SelectionState state = e.getSelectionState();
		
		if (e.isEventOfType(SelectionEvent.SET_ROLLOVER_PROJECT)) {
			CProject rollover = state.getRolloverProject();
			if (rollover != null)
				sets = rollover.getDatasetSet();
			//if (rollover != state.getSelectedProject() || rollover == null)
			//highlightDatasetsForProject(rollover);
			highlightDatasets(sets);
		}
		else if (e.isEventOfType(SelectionEvent.SET_ROLLOVER_DATASET)) {
			CDataset rolled = state.getRolloverDataset();
			highlightDataset(rolled);	 
		}
		else if (e.isEventOfType(SelectionEvent.SET_ROLLOVER_CHAIN)) {
				CChain chain = state.getRolloverChain();
				if (chain != null)
					sets = chain.getDatasetsWithExecutions();
				highlightDatasets(sets);	 
			}
		
		else if (e.isEventOfType(SelectionEvent.SET_SELECTED_CHAIN)) {
			// show only those that are for current project
			// and have executions for this chain
			System.err.println("browser canvas got selected chain");
			sets = state.getExecutedDatasets();
			TreeSet datasets;
			if (sets != null) {
				System.err.println("# of datasets..."+sets.size());
				datasets = new TreeSet(sets);
			}
			else
				datasets = new TreeSet(allDatasets);
			displayDatasets(datasets,false);
		}
		else if (e.isEventOfType(SelectionEvent.SET_SELECTED_PROJECT)
			|| e.isEventOfType(SelectionEvent.SET_SELECTED_DATASET)) {
			System.err.println("browser canvas selected dataset/project");
			updateProjectDatasetSelection(state);	
		}
	  
	}
	
	private void updateProjectDatasetSelection(SelectionState state) {
		CDataset selected = state.getSelectedDataset();
		TreeSet datasets;
		if (state.getSelectedProject() != null)
			//highlightDatasetsForProject(null);
			highlightDatasets(null);
		
		if (selected != null) {
			datasets = new TreeSet();
			datasets.add(selected);
		}
		else {
			Collection selections = state.getActiveDatasets();
			if (selections != null && selections.size() > 0) {
				datasets = new TreeSet(selections);
			}
			else {
				datasets = new TreeSet(allDatasets);
			}
		}	
		displayDatasets(datasets,false);
	}

	public int getEventMask() {
		return SelectionEvent.SET_SELECTED_DATASET | 
			SelectionEvent.SET_SELECTED_PROJECT | 
			SelectionEvent.SET_ROLLOVER_PROJECT |
			SelectionEvent.SET_ROLLOVER_DATASET | 
			SelectionEvent.SET_ROLLOVER_CHAIN |
			SelectionEvent.SET_SELECTED_CHAIN;
	}
		
	public void clearExecutionList() {
		if (executionList != null) {
			if (executionList.getParent() == layer)
				layer.removeChild(executionList);
			executionList = null;
		}
	}
	
	public void showExecutionList(PChainLabelText cl) {
		clearExecutionList();

		executionList = cl.getExecutionList();
		
		
		layer.addChild(executionList);
		
		PBounds b = cl.getGlobalFullBounds();
		executionList.setOffset(b.getX(),b.getY()+b.getHeight());
	}
	
	public void highlightDatasetsForProject(CProject p) {
		
		Iterator iter = layer.getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PDataset) {
				PDataset dNode = (PDataset) obj;
				CDataset d = dNode.getDataset();
				if (p != null && p.hasDataset(d)) {
					dNode.setHighlighted(true);
				}
				else
					dNode.setHighlighted(false);
			}
			else 
				System.err.println("browser canvas. child was "+obj);
		}
	}
	
	public void highlightDatasets(Collection c) {
		Iterator iter = layer.getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PDataset) {
				PDataset dNode = (PDataset) obj;
				CDataset d = dNode.getDataset();
				if (c != null && c.contains(d)) {
					dNode.setHighlighted(true);
				}
				else
					dNode.setHighlighted(false);
			}
			else 
				System.err.println("browser canvas. child was "+obj);
		}
	}
	
	public void highlightDataset(CDataset rolled) {
		if (lastRolledOver != null) { 
			lastRolledOver.setHighlighted(false);
			lastRolledOver = null;
		}
		
		if (rolled != null) {	
			lastRolledOver = rolled.getNode();
			lastRolledOver.setHighlighted(true);
		}		
	}
 }