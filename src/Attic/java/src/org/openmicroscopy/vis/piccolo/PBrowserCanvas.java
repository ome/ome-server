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
		camera.addInputEventListener(new PBrowserCanvasToolTipHandler(camera));
		getCamera().animateViewToCenterBounds(getBufferedBounds(),true,0);
	
		allDatasets = connection.getDatasetsForUser();
		
	
	}
	
	
	
	
	private  double getArea(CDataset d) {
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
		
		totalArea = 0;
		Iterator iter = datasets.iterator();
		
		while (iter.hasNext()) {
			CDataset d = (CDataset) iter.next();
			double area = getArea(d);
			//System.err.println("dataset "+d.getName()+" area is "+area);
			totalArea += area;
		}
		System.err.println("total area is "+totalArea);
		
		screenHeight = getHeight();
		screenWidth = getWidth();
		screenArea = screenHeight*screenWidth;
		
		scaleFactor = Math.sqrt(screenArea/totalArea);
		System.err.println("scale factor is" +scaleFactor);
		screenHeight /= scaleFactor;
		screenWidth /= scaleFactor;
		System.err.println("scaled height is "+screenHeight);
		System.err.println("scaeld width is "+screenWidth);
		strips = doTreeMap(datasets);
	}

	private void doLayout(Collection datasets,boolean layoutDatasets) {
		if (datasets == null)
			return;
		layer.setScale(1.0);
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
					node.setOffset(0,0);
					node.layoutImages();
				}
				
				if (datasets.contains(node.getDataset())) {
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
	private double stripHeight = 0;
	private double oldHeight = 0;

	private Vector doTreeMap(Collection datasets) {
	
		oldAspectRatio = 0;
		newAspectRatio = 0;
		Vector strips = new Vector();
		Vector strip = new Vector();
		
		Iterator iter = datasets.iterator();
		CDataset d = null;
		
		PDataset node=null;
		
		System.err.println("***** DOING TREEMAP ****");
		while (iter.hasNext())  {
			d = (CDataset) iter.next();
			node = (PDataset) datasetWidgets.get(d);
		
			
			strip.add(node);
		
			// calc,update stats.
			getTreemapStripHeight(strip);
			
			System.err.println("STRIP: new aspect ratio is "+newAspectRatio);
			System.err.println(" old aspect ratio is "+oldAspectRatio);
			if (strip.size()>1 &&  newAspectRatio > oldAspectRatio) {
				// move it to next strip.
				System.err.println("-------");
				System.err.println("moving on to next strip");
				strip.remove(node);
				System.err.println("strip heiight is "+stripHeight);
				System.err.println("reverting to "+oldHeight);
				Iterator iter2 = strip.iterator();
				while (iter2.hasNext()) {
					PDataset ds = (PDataset) iter2.next();
					ds.revertWidth();
					ds.setHeight(oldHeight);
					System.err.println("dataset .."+ds.getDataset().getName()+", width is "+ds.getWidth());
					System.err.println("# of things in dataset..."+ds.getContentsArea());
					double ratio  = ds.getContentsArea()/totalArea;
					System.err.println("ratio of stuff ..."+ratio);
				}
				strips.add(strip);
				strip = new Vector();
				newAspectRatio = oldAspectRatio = 0;
				strip.add(node);
				oldHeight = 0;
				getTreemapStripHeight(strip);
			}
			// otherwise, keep what I've calculated.
				oldAspectRatio = newAspectRatio;
			System.err.println("-------");
		}
		System.err.println("last strip height is "+stripHeight);
		// set height of nodes in last strip
		iter = strip.iterator();
		while (iter.hasNext()) {
			PDataset ds  =(PDataset) iter.next();
			ds.setHeight(stripHeight);
		}
		strips.add(strip);
		// rescale
		
		iter = strips.iterator();
		while (iter.hasNext()) {
			Vector v = (Vector) iter.next();
			Iterator iter2= v.iterator();
			while (iter2.hasNext()) {
				PDataset p = (PDataset) iter2.next();
				p.scaleArea(scaleFactor);
			}
		}
		return strips;
	}
	
	private void  getTreemapStripHeight(Vector strip) {
		// get height
		
		double stripArea =0;
		Iterator iter = strip.iterator();
		while (iter.hasNext()) {
			PDataset node = (PDataset) iter.next();
			System.err.println("dataset .."+node.getDataset().getName()+" area "	
				+node.getContentsArea());
			double area = node.getContentsArea();
			stripArea += area;
		}
		
		System.err.println("strip area is "+stripArea);
		
		//double ratio = stripArea/screenWidth;
		oldHeight = stripHeight;
		//stripHeight = Math.ceil(ratio * screenHeight); // was getHeight());
		stripHeight = stripArea/screenWidth;
		System.err.println("strip height is "+stripHeight);
		// get width of each and update ratios;
		double width;
		int i =0;
		newAspectRatio = 0;
		iter = strip.iterator();
		while (iter.hasNext()) {
			PDataset node = (PDataset) iter.next();
			width = node.getContentsArea()/stripHeight;
			node.setWidth(width);
			if (width > stripHeight) 
				newAspectRatio += width/stripHeight;
			else 
				newAspectRatio += stripHeight/width;
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
	
	}
	
	public void selectionChanged(SelectionEvent e) {
		Collection sets = null;
		SelectionState state = e.getSelectionState();
		
		if (e.isEventOfType(SelectionEvent.SET_ROLLOVER_PROJECT)) {
			CProject rollover = state.getRolloverProject();
			if (rollover != null)
				sets = rollover.getDatasetSet();
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
			
			sets = state.getExecutedDatasets();
			TreeSet datasets;
			if (sets != null) {
				datasets = new TreeSet(sets);
			}
			else
				datasets = new TreeSet(allDatasets);
			displayDatasets(datasets,false);
		}
		else if (e.isEventOfType(SelectionEvent.SET_SELECTED_PROJECT)
			|| e.isEventOfType(SelectionEvent.SET_SELECTED_DATASET)) {
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