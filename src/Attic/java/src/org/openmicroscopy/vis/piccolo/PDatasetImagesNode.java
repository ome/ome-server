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
import edu.umd.cs.piccolo.nodes.PPath;
import java.util.Iterator;
import java.util.ArrayList;
import java.awt.Color;

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
	private static final int HALO_RADIUS=1;
	
	private PNode imagesNode = new PNode();
	private PImage thumbnailNode = null;
	private boolean selected = false;
	
	private PPath zoomHalo = new PPath();
	
	
	private ArrayList rowSzs = new ArrayList();
	
	private int highlightRow;
	private int highlightColumn;
	
	public PDatasetImagesNode() {
		super();	
		addChild(imagesNode);
		addChild(zoomHalo);
		zoomHalo.setVisible(false);
		zoomHalo.setPickable(false);
		setPickable(true);
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
	
	public void highlightThumbnail(PThumbnail thumb,boolean v) {
		if (v == false) {
			zoomHalo.setVisible(false);
			zoomHalo.setPickable(false);
		}
		else {
			doHighlightThumbnail(thumb);
		}
	}
	
	private void doHighlightThumbnail(PThumbnail thumb) {
		// get index
		int index = imagesNode.indexOfChild(thumb);
		System.err.println("******************");
		System.err.println("highlighting thumbnail with halo..."+index);
		
		PBounds b = setHighlight(index);
		System.err.println("highlight bounds are "+b);		
		globalToLocal(b);
		zoomHalo.setPathTo(b);
		zoomHalo.setStrokePaint(Color.BLACK);
		zoomHalo.setVisible(true);
		zoomHalo.setPickable(true);
	}
	
	private int getRowSize(int i) {
		Integer v = (Integer) rowSzs.get(i);
		return v.intValue();
	}
	
	private PBounds setHighlight(int index) {
		calculatePosition(index);
		System.err.println("highlight is at "+highlightRow+","+highlightColumn);
		PBounds b = new PBounds();
		
		//	build up bounds of zoomhalo
		int lowRow = highlightRow-HALO_RADIUS;
		int highRow = highlightRow+HALO_RADIUS;
		
		int lowCol = highlightColumn-HALO_RADIUS;
		int highCol = highlightColumn+HALO_RADIUS;
		
		for (int i = lowRow; i<=highRow; i++) {
			for (int j = lowCol; j <= highCol; j++) {
				System.err.println("trying to add "+i+","+j);
				addToHighlight(b,i,j);
			}
		}
		
		return b;
		
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
		System.err.println("adding "+row+","+col);
		int index = getThumbIndex(row,col);
		System.err.println("index is "+index);
		PThumbnail thumb = (PThumbnail) imagesNode.getChild(index);
		PBounds tBounds = thumb.getGlobalFullBounds();
		System.err.println("boounds are "+tBounds);
		b.add(tBounds);
	}
	
	private int getThumbIndex(int row,int col) {
		int index = 0;
		for (int i = 0; i < row; i++) {
			index +=getRowSize(i);
		}
		
		return index+col;
	}
}
