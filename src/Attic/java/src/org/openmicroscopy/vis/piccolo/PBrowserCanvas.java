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
import org.openmicroscopy.vis.ome.events.DatasetSelectionEvent;
import org.openmicroscopy.vis.ome.events.DatasetSelectionEventListener;
import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PPaintContext;
import java.util.Iterator;
import java.util.TreeSet;
import java.util.HashMap;
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
	DatasetSelectionEventListener {
	
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
	
	private TreeSet datasets;
	private HashMap datasetWidgets = new HashMap();
		
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
		getCamera().setViewScale(INIT_SCALE);
	    
	
	}
	
	
	public void drawImages(CDataset d) {
		
		if (d== null)
			return;
		PDataset node;	
		System.err.println("drawing images for dataset "+d.getName());
		
		Object o = datasetWidgets.get(d);
		if (o != null) {
			node = (PDataset) o;
		}
		else {
			System.err.println("creating new widget");
			node = new PDataset(d,connection);
			datasetWidgets.put(d,node);
		}
		layer.addChild(node);
		node.setOffset(x,y);
		double height = node.getGlobalFullBounds().getHeight()+VGAP;
		if (height > maxHeight)
			maxHeight = height;	
		x+= node.getGlobalFullBounds().getWidth()+VGAP;
	}
		
	public void displayDatasets() {
		layer.removeAllChildren();
		Iterator iter = datasets.iterator();
		x = HGAP;
		y= 0;
		maxHeight = 0;
		
		int count = datasets.size();
		int rowSz = (int) Math.sqrt(count);
		int i = 0;
		while (iter.hasNext()) {
			CDataset d = (CDataset) iter.next();
			drawImages(d);
			if (i++ >= rowSz) {
				x=HGAP;
				y+=maxHeight;
				i=0;
			}
		}
		getCamera().animateViewToCenterBounds(getBufferedBounds(),true,
				PConstants.ANIMATION_DELAY);
	}
	
	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX()-PConstants.SMALL_BORDER,
			b.getY()-PConstants.SMALL_BORDER,
			b.getWidth()+2*PConstants.SMALL_BORDER,
			b.getHeight()+2*PConstants.SMALL_BORDER); 
	}
	
	public void datasetSelectionChanged(DatasetSelectionEvent e) {
		Collection selections = e.getDatasets();
		if (e.getSelectedDataset() != null) {
			datasets = new TreeSet();
			datasets.add(e.getSelectedDataset());
		}
		else {
			if (selections.size() > 0)
				datasets = new TreeSet(selections);
			else
				datasets = new TreeSet(connection.getDatasetsForUser());
		}	
		displayDatasets();
	}
 }