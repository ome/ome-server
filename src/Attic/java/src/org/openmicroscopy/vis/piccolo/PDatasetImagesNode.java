/*
 * org.openmicroscopy.vis.piccolo.PDatasetImagesNode
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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

import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.nodes.PImage;
import edu.umd.cs.piccolo.util.PPaintContext;
import edu.umd.cs.piccolo.util.PBounds;
import java.util.Iterator;
import java.util.ArrayList;

/**
 * 
 * A node for images in a dataset. Renders either an image or the thumbnails, 
 * depending on the scale
 * @author <br>Harry Hochheiser &nbsp;&nbsp;&nbsp;
 * <A HREF="mailto:hsh@nih.gov">hsh@nih.gov</A>
 *
 *  @version 2.2
 * <small>
 * </small>
 * @since OME2.2
 */
public class PDatasetImagesNode extends PNode  {

	private static final double SCALE_THRESHOLD=.75;
		
	private PNode imagesNode = new PNode();
	private PImage thumbnailNode = null;
	private boolean selected = false;
	
	private PThumbnailSelectionHalo zoomHalo = new PThumbnailSelectionHalo();
	
	
	private ArrayList rowSzs = new ArrayList();
	
	private int highlightRow;
	private int highlightColumn;
	
	private PThumbnail currentHighlight;
	
	private PBrowserEventHandler handler;
	
	public PDatasetImagesNode() {
		super();	
		addChild(imagesNode);
		addChild(zoomHalo);
		zoomHalo.moveToFront();
		setPickable(true);
	}
	
	
	public void setHandler(PBrowserEventHandler handler) {
		this.handler = handler;
	}
	
	public void addImage(PThumbnail thumb) {
		imagesNode.addChild(thumb);
	}
	
	public void setRowCount(int row,int sz) {
		rowSzs.add(row,new Integer(sz));
	}
	
	public Iterator getImageIterator() {
		return imagesNode.getChildrenIterator();
	}
	
	
	public void completeImages(double width,double height) {
		PBounds b = imagesNode.getGlobalFullBounds();
		if (b.getWidth() > 0 && b.getHeight() > 0 &&
			imagesNode.getChildrenCount() > 200) {
			thumbnailNode = new PImage(imagesNode.toImage((int)b.getWidth(),
				(int) b.getHeight(),null),true);
			addChild(thumbnailNode);
			moveToBack(thumbnailNode);
		}
	}
	
	public void setScale(double scale) {
		super.setScale(scale);
	}
	
	public void paint(PPaintContext aPaintContext) {
		
		if (thumbnailNode == null || selected == true || 
			aPaintContext.getScale() > SCALE_THRESHOLD){
			if (thumbnailNode != null) {
				thumbnailNode.setVisible(false);
				thumbnailNode.setPickable(false);
			}
			imagesNode.setVisible(true);
			setPickable(true);
		}
		else {
			
			// show images node
			imagesNode.setVisible(false);
			if (thumbnailNode != null) {
				thumbnailNode.setVisible(true);
				thumbnailNode.setPickable(true);	
			}
			setPickable(false);
		}
		super.paint(aPaintContext);
	}
	
	public void setSelected(boolean v) {
		selected = v;
	}
	
	public void highlightThumbnail(PThumbnail thumb,boolean v,int level) {
		System.err.println("calling highlight thumbnail..."+thumb);
		System.err.println(" v is "+v+", level "+level);
		int count = imagesNode.getChildrenCount();		
		int radius = (int) Math.floor(getRadius(level));
		int size = radius*radius;
		
		System.err.println("count is "+count+", radius is "+radius);
		if (v == false || count < size || radius <1) { 
			zoomHalo.hide();
			currentHighlight = null;
		}
		else  { //if (thumb != currentHighlight) {
			System.err.println("doing halo @ level "+level);
			doHighlightThumbnail(thumb,radius);
			currentHighlight = thumb;
		}
	}
	
	public double getRadius(int level) {
		int count = imagesNode.getChildrenCount();
		// find the number of items on each side
		double side = Math.sqrt(count);
		double denom = Math.pow(2,level+2);
		return side/denom;
	}
	
	private void doHighlightThumbnail(PThumbnail thumb,int radius) {
		// get index
		
		int index = imagesNode.indexOfChild(thumb);
		PBounds b = getHighlight(index,radius);
		System.err.println("global bounds are "+b);
		globalToLocal(b);
		System.err.println("local bounds are "+b);
		zoomHalo.setPathTo(b);
	}
	
	private int getRowSize(int i) {
		Integer v = (Integer) rowSzs.get(i);
		return v.intValue();
	}
	
	private PBounds getHighlight(int index,int radius) {
		calculatePosition(index);
		PBounds b = new PBounds();
		
		//	build up bounds of zoomhalo
		int lowRow = highlightRow-radius;
		int highRow = highlightRow+radius;
		
		int lowCol = highlightColumn-radius;
		int highCol = highlightColumn+radius;
		
		for (int i = lowRow; i<=highRow; i++) {
			for (int j = lowCol; j <= highCol; j++) {
				addToHighlight(b,i,j);
			}
		}
		
		PBounds b2 = new PBounds(b.getX()-PThumbnailSelectionHalo.BORDER,b.getY()-PThumbnailSelectionHalo.BORDER,
			b.getWidth()+2*PThumbnailSelectionHalo.BORDER,b.getHeight()+2*PThumbnailSelectionHalo.BORDER);
		return b2;
		
	}
	
	private void calculatePosition(int index) {
		int curRowSize;
		int curRow = 0;

		
		curRowSize =getRowSize(curRow);
		while (index >= curRowSize && curRow < rowSzs.size()) {
			index -= curRowSize;
			curRow++;
			curRowSize = getRowSize(curRow);
		}
		highlightRow = curRow;
		highlightColumn = index; // whatever is left over is column
	}
	
	private void addToHighlight(PBounds b,int row,int col) {
		if (row <0 || row >= rowSzs.size())
			return;
		
		int curRowSize = getRowSize(row);
		if (col <0 || col >= curRowSize)
			return;
		int index = getThumbIndex(row,col);
		PThumbnail thumb = (PThumbnail) imagesNode.getChild(index);
		PBounds tBounds = thumb.getGlobalFullBounds();
		b.add(tBounds);
	}
	
	private int getThumbIndex(int row,int col) {
		int index = 0;
		for (int i = 0; i < row; i++) {
			index +=getRowSize(i);
		}
		
		return index+col;
	}
	
	public boolean hasVisibleHalo() {
		return zoomHalo.getVisible();
	}
	

	public PThumbnailSelectionHalo getHalo() {
		return zoomHalo;
	}
	
	public int zoomInToHalo(PThumbnail thumb, int level) {
		 System.err.println("zooming in .. level is "+level);
		 System.err.println("radius is..."+getRadius(level));
		 double newRadius = getRadius(level+1);
		 System.err.println("next radius is "+newRadius);
		 if (newRadius <1 && getRadius(level) >1) {
		 	handler.animateToBufferedNode(thumb);
		 }
		 else {
	     	calcZoomHalo(thumb,level);
		 	handler.animateToNode(zoomHalo);
		 }
	     // zoomIn
	     
	     System.err.println("new radius is "+newRadius);
	     int newLevel = level;
	     if (newRadius >=1)
	     	newLevel++;
	     System.err.println("new level is "+newLevel);
	     return newLevel;	
	   }
	
	public int zoomOutOfHalo(PThumbnail thumb, int level) {
		if (level == 0)
			return level;
		System.err.println("zooming out.. level is "+level);
		System.err.println("radius is "+getRadius(level));	
		if (level <= 1) {
			// go to top level.
			PBufferedNode b = thumb.getBufferedParentNode();
			// zoom to this.
			handler.animateToBufferedNode(b);
		}
		else if (getRadius(level) <= 1) {
			// innermost, go out by one
			calcZoomHalo(thumb,level-1);
			handler.animateToNode(zoomHalo);
			
		} else {
			// go down by two
			int upperLevel = level-2;
			calcZoomHalo(thumb,upperLevel);
			
			//and zoom in by one. net effect - zoom out oune
			handler.animateToNode(zoomHalo);
		}
		level--;
		if (level < 0)
			level = 0;
		calcZoomHalo(thumb,level);
		return level;		
	}
	
	public void calcZoomHalo(PThumbnail thumb, int level) {
		int radius = (int) Math.floor(getRadius(level));
		doHighlightThumbnail(thumb,radius);		
	}
	
}
