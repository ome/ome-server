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

	/**
	 * Threshold below which we'll show the icon instead of the actual thumbnails.
	 */
	private static final double SCALE_THRESHOLD=.75;
		
	/**
	 * Parent node for thumbnails
	 */
	private PNode imagesNode = new PNode();
	
	/**
	 * An image that will take the place of thumbnails as we zoom out
	 */
	private PImage thumbnailNode = null;
	
	/**
	 * flag indicating when we are selected.
	 */
	private boolean selected = false;
	
	/**
	 * the halo
	 */
	private PThumbnailSelectionHalo zoomHalo = new PThumbnailSelectionHalo();
	
	
	/**
	 * A list of sizes of the rows
	 */
	private ArrayList rowSzs = new ArrayList();
	
	/**
	 * The row and column of the highlighted thumbnail
	 */
	private int highlightRow;
	private int highlightColumn;
	
	/**
	 * a cache of highlighted thumbnail, to avoid re-highlighting
	 */
	private PThumbnail currentHighlight;
	
	/**
	 * The event handler for the canvas that this node is on
	 */
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
	
	/**
	 * Add a thumbnail
	 * @param thumb
	 */
	public void addImage(PThumbnail thumb) {
		imagesNode.addChild(thumb);
	}
	
	/**
	 * Add the size of a new row
	 */
	public void setRowCount(int row,int sz) {
		rowSzs.add(row,new Integer(sz));
	}
	
	/**
	 * Iterator for all of the thumbnails
	 */
	public Iterator getImageIterator() {
		return imagesNode.getChildrenIterator();
	}
	
	
	/**
	 * When all of the thumbnails for the dataset have been added, 
	 * create an icon image add add it to this node.
	 * 
	 * @param width
	 * @param height
	 */
	public void completeImages() {
		PBounds b = imagesNode.getGlobalFullBounds();
		if (b.getWidth() > 0 && b.getHeight() > 0 &&
			imagesNode.getChildrenCount() > 200) {
			thumbnailNode = new PImage(imagesNode.toImage((int)b.getWidth(),
				(int) b.getHeight(),null),true);
			addChild(thumbnailNode);
			moveToBack(thumbnailNode);
		}
	}
	
	
	/**
	 * If there is no icon node, this node is selected, or we're zoomed in
	 * to a scale greater than SCALE_THRESHOLD, hide the icon image and show 
	 * individual thumbnails.
	 * 
	 * Otherwise, show the icon image.
	 *
	 */
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
	
	/**
	 * Turn the highlight on or off for a thumbnail at a given zoom level
	 * @param thumb the thumbnail to be highlighted (or not)
	 * @param v true if highlight on, else false
	 * @param level the zoom level
	 */
	public void highlightThumbnail(PThumbnail thumb,boolean v,int level) {
		int count = imagesNode.getChildrenCount();		
		int radius = getRadius(level);
		int size = radius*radius;
	
		zoomHalo.hide();
		
		if (v == false || count < size || radius <0) { 
			currentHighlight = null;
		}
		else  if (thumb != currentHighlight) {
			// only do this if I'm not already highlighted
			doHighlightThumbnail(thumb,radius);
			zoomHalo.show();
			currentHighlight = thumb;
		}
	}
	
	/**
	 * For zoom level i, the radius of the halo'd region will be 
	 * side/2^(level+2), where side=sqrt(# of thumbnails). This provides
	 * a roughly exponential decrease in the size of the halo with each zoom-in
	 *  
	 * @param level
	 * @return the radius for the halo at that level
	 */
	private int getRadius(int level) {
		int count = imagesNode.getChildrenCount();
		// find the number of items on each side
		double side = Math.sqrt(count);
		double denom = Math.pow(2,level+2);
		return (int) Math.floor(side/denom);
	}
	
	/** 
	 * To highlight a thumbail, get the bounds, make them local,
	 * and update the halo path
	 */
	private void doHighlightThumbnail(PThumbnail thumb,int radius) {
		// get index
		PBounds b  = getHaloBounds(thumb,radius);
		
		zoomHalo.setPathTo(b);
	}
	
	
	/**
	 * To get the halo bounds, find the index of the node and build 
	 * highlight bounds around it
	 * @param thumb
	 * @param radius
	 * @return bounds of the highlight of the given radius around thumb
	 */
	private PBounds getHaloBounds(PThumbnail thumb,int radius) {
		int index = imagesNode.indexOfChild(thumb);
		PBounds b = getHighlight(index,radius);
	
		return b;
	}
	
	/**
	 * A shortcut to get the size of a row
	 * @param i a row index
	 * @return # of items in row i.
	 */
	private int getRowSize(int i) {
		Integer v = (Integer) rowSzs.get(i);
		return v.intValue();
	}
	
	/**
	 * To build the highlight, iterate over the range implied by the radius
	 * and add everythin in that region
	 * 
	 * @param index
	 * @param radius
	 * @return halo bounds around item index of the given radius
	 */
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
		
		return b;
	}
	
	/**
	 * Find the row and column of the item being highlighted. 
	 * 
	 * @param index
	 */
	private void calculatePosition(int index) {
		int curRowSize;
		int curRow = 0;

		// since rows may be of different sizes, this isn't just simple
		// array indexing. iterate over rows until I find the index i'm looking
		// for 
		curRowSize =getRowSize(curRow);
		while (index >= curRowSize && curRow < rowSzs.size()) {
			index -= curRowSize;
			curRow++;
			curRowSize = getRowSize(curRow);
		}
		
		// set these vars to hold my current position
		highlightRow = curRow;
		highlightColumn = index; // whatever is left over is column
	}

	/**
	 * To add a position to the highlight, make sure the position is not out of
	 * bounds and then add it.
	 * @param b
	 * @param row
	 * @param col
	 */	
	private void addToHighlight(PBounds b,int row,int col) {
		if (row <0 || row >= rowSzs.size())
			return;
		
		int curRowSize = getRowSize(row);
		if (col <0 || col >= curRowSize)
			return;
		int index = getThumbIndex(row,col);
		PThumbnail thumb = (PThumbnail) imagesNode.getChild(index);
		PBounds tBounds = thumb.getFullBoundsReference();
		b.add(tBounds);
	}
	
	/**
	 * More or less the inverse of the 
	 * {@link #calculatePosition calculatePosition} call. find the position of 
	 * the item at row, col in the node's children
	 */
	private int getThumbIndex(int row,int col) {
		int index = 0;
		for (int i = 0; i < row; i++) {
			index +=getRowSize(i);
		}
		
		return index+col;
	}
	
	/**
	 * Zoom in to a thumbnail at a given level
	 * @param thumb
	 * @param level
	 * @return return the new level
	 */
	public int zoomInToHalo(PThumbnail thumb, int level) {
		
		// find the new radius
		double newRadius = getRadius(level+1);
		
		// calculate the current halo
	    calcZoomInHalo(thumb,level);
	    
	    //zoom to it.
		handler.animateToNode(zoomHalo);
		 
		// update the level, maxing out if the radius is >=0
	    int newLevel = level;
	    if (newRadius >=0) 
	    	newLevel++;
	    return newLevel;	
	 }
	
	/**
	 * Zoom out from a thumbnail at a given level
	 * @param thumb
	 * @param level
	 * @return the new level
	 */
	public int zoomOutOfHalo(PThumbnail thumb, int level) {
		// if level is zero, do nothing
		if (level == 0)
			return level;
		if (level <= 1) {
			// go to top level.
			PBufferedObject b = thumb.getBufferedParentNode();
			// zoom to the dataset
			handler.animateToBufferedObject(b);
		}
		else {
			// go up by two
			int upperLevel = level-2;
			calcZoomOutHalo(thumb,upperLevel);
			
			//and zoom in by one. net effect - zoom out oune
			handler.animateToNode(zoomHalo);
		}
		// adjust level
		level--;
		if (level < 0)
			level = 0;
		return level;		
	}
	
	/**
	 * Find the halo for zooming out. Don't do anything if radius is zero:
	 * there's no need. 
	 */
	private void calcZoomOutHalo(PThumbnail thumb, int level) {
		int radius = getRadius(level);
		if (radius > 0) {
			zoomHalo.hide();
			doHighlightThumbnail(thumb,radius);
		}
	}
	
	/**
	 * Find the halo for zooming in.
	 */
	private void calcZoomInHalo(PThumbnail thumb,int level) {
		int radius = getRadius(level);
		zoomHalo.hide();
		doHighlightThumbnail(thumb,radius);
	}
	
}
