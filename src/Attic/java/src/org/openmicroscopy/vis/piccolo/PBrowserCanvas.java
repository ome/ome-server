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

import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PPaintContext;
import org.openmicroscopy.vis.chains.BrowserFrame;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.ome.CImage;
import java.util.List;
import java.util.Iterator;
import java.util.Vector;

/** 
 * A {@link PCanvas} for viewing images in a dataset
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PBrowserCanvas extends PCanvas implements PBufferedObject {
	
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
	
	
	/**
	 * The frame contaiing this canvas
	 */
	private BrowserFrame frame;
	
	
	private static float VGAP=10;
	private static float HGAP=10;
	
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
		addInputEventListener(new PModuleZoomEventHandler(this)); 
			
		
			// setup tool tips.
		final PCamera camera = getCamera();
		camera.addInputEventListener(new PImageToolTipHandler(camera));
		getCamera().setViewScale(INIT_SCALE);
	    
		drawImages();
	
	}
	
	public void setFrame(BrowserFrame frame) {
		this.frame = frame;
	}
	
	
	private void drawImages() {
		double x = HGAP;
		double y = 0;
		System.err.println("drawing iamges...");
		CDataset curDataset = connection.getDataset();
		List images = curDataset.getCachedImages();
		Iterator iter = images.iterator();	
		float maxHeight = 0;
		float maxWidth =0;
		Vector nodes = new Vector();
		
		//draw them
		while (iter.hasNext()) {
			CImage image = (CImage) iter.next();
			System.err.println("drawing image "+image.getID());
			PThumbnail thumb = new PThumbnail(image);
			layer.addChild(thumb);
			float height  = (float) thumb.getGlobalFullBounds().getHeight();
			float width = (float) thumb.getGlobalFullBounds().getWidth();
			
			if (height > maxHeight) 
				maxHeight = height;
			if (width > maxWidth) 
				maxWidth = width;
			nodes.add(thumb);
		}
		
		// space them
		maxHeight += VGAP;
		maxWidth+= HGAP;
		iter = nodes.iterator();
		int rowSz = (int) Math.sqrt(nodes.size());
		int i =0;
		while (iter.hasNext()) {
			PThumbnail thumb = (PThumbnail) iter.next();
			thumb.setOffset(x,y);
			if (i++ >= rowSz) {
				y += maxHeight; 
				x = HGAP;
				i = 0;
			}
			else 
				x+= maxWidth;
		}
	}
		
	
	
	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX()-PConstants.SMALL_BORDER,
			b.getY()-PConstants.SMALL_BORDER,
			b.getWidth()+2*PConstants.SMALL_BORDER,
			b.getHeight()+2*PConstants.SMALL_BORDER); 
	}
 }