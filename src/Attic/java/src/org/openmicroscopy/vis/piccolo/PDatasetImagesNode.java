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
	
	private int maxLevel;
	
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
	
	
	
//	public void setScale(double scale) {
//		super.setScale(scale);
//	}
	
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
		int count = imagesNode.getChildrenCount();		
		int radius = getRadius(level);
		int size = radius*radius;
	
		zoomHalo.hide();
		
		if (v == false || count < size || radius <1) { 
			currentHighlight = null;
		}
		else  if (thumb != currentHighlight) {
			doHighlightThumbnail(thumb,radius);
			zoomHalo.show();
			currentHighlight = thumb;
		}
	}
	
	public int getRadius(int level) {
		int count = imagesNode.getChildrenCount();
		// find the number of items on each side
		double side = Math.sqrt(count);
		double denom = Math.pow(2,level+2);
		return (int) Math.floor(side/denom);
	}
	
	private void doHighlightThumbnail(PThumbnail thumb,int radius) {
		// get index
		PBounds b  = getHaloBounds(thumb,radius);
		
		globalToLocal(b);
		zoomHalo.setPathTo(b);
	}
	
	
	private PBounds getHaloBounds(PThumbnail thumb,int radius) {
		int index = imagesNode.indexOfChild(thumb);
		PBounds b = getHighlight(index,radius);
	
		return b;
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
		 double newRadius = getRadius(level+1);
		 if (getRadius(level) <1) { // didn't work when I also checked if next is >1
		 	handler.animateToBufferedNode(thumb);
		 }
		 else {
	     	calcZoomInHalo(thumb,level);
		 	handler.animateToNode(zoomHalo);
		 }
	     // zoomIn
	     
	     int newLevel = level;
	     if (newRadius >=0) 
	     	newLevel++;
	     return newLevel;	
	 }
	
	public int zoomOutOfHalo(PThumbnail thumb, int level) {
		if (level == 0)
			return level;
		if (level <= 1) {
			// go to top level.
			PBufferedNode b = thumb.getBufferedParentNode();
			// zoom to this.
			handler.animateToBufferedNode(b);
		}
		else {
			// go up by two
			int upperLevel = level-2;
			calcZoomOutHalo(thumb,upperLevel);
			
			//and zoom in by one. net effect - zoom out oune
			handler.animateToNode(zoomHalo);
		}
		level--;
		if (level < 0)
			level = 0;
		return level;		
	}
	
	// when zooming out, I don't want a highlight unless radius > 1
	public void calcZoomOutHalo(PThumbnail thumb, int level) {
		int radius = getRadius(level);
		if (radius > 1) {
			zoomHalo.hide();
			doHighlightThumbnail(thumb,radius);
		}
	}
	
	public void calcZoomInHalo(PThumbnail thumb,int level) {
		int radius = getRadius(level);
		zoomHalo.hide();
		doHighlightThumbnail(thumb,radius);
	}
	
}
