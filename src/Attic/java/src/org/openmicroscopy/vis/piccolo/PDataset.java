/*
 * org.openmicroscopy.vis.piccolo.PDataset
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

import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.ome.CImage;
import org.openmicroscopy.vis.ome.Connection;
import edu.umd.cs.piccolo.nodes.PText;
import java.util.Vector;
import java.util.List;
import java.util.Iterator;

/** 
 * A subclass of {@link PCategorBox} that is used to provide a colored 
 * background to the display of images in a dataest 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PDataset extends PGenericBox {
	
	private CDataset dataset;
	private Connection connection;
	
	private static float VGAP=10;
	private static float HGAP=5;

	private double x=HGAP;
	private double y=VGAP;
	private float maxHeight = 0;
	private PText nameLabel;
	
	public PDataset(CDataset dataset,Connection connection) {
		super();
		this.dataset = dataset;
		this.connection = connection;
		layoutImages();
	}
	
	public PDataset(float x,float y,CDataset dataset,Connection connection) {
		super(x,y);
		this.dataset = dataset;
		this.connection = connection;
		layoutImages();
	}

	private void layoutImages() {
		
		//	draw label
		//System.err.println("laying out dataset "+dataset.getName());
		 nameLabel = new PText(dataset.getName());
		 addChild(nameLabel);
		 int sz = dataset.getImageCount();

		if (sz > 20) {
			System.err.println("too many ..images..");
			displayDatasetSizeText(sz);
			return;
		}
		List images = dataset.getCachedImages(connection);
		Iterator iter = images.iterator();
		maxHeight = 0;
		float maxWidth = 0;
		Vector nodes = new Vector();
		
		nameLabel.setOffset(x,y);
		y+= nameLabel.getHeight()+VGAP;
		float height=0;
		float width =0;
		//draw them
		while (iter.hasNext()) {
			CImage image = (CImage) iter.next();
			PThumbnail thumb = new PThumbnail(image);
			addChild(thumb);
			height  = (float) thumb.getGlobalFullBounds().getHeight();
			width = (float) thumb.getGlobalFullBounds().getWidth();
		
			if (height > maxHeight) 
				maxHeight = height;
			if (width > maxWidth) 
				maxWidth = width;
			nodes.add(thumb);
		}
		
	//	System.err.println("laying out images. width is "+maxWidth);
	
		// space them
		maxHeight += VGAP;
		maxWidth+= HGAP;
		iter = nodes.iterator();
		int rowSz = (int) Math.sqrt(nodes.size());
		int i =0;
		double maxRowWidth=0;
		while (iter.hasNext()) {
			PThumbnail thumb = (PThumbnail) iter.next();
		
			thumb.setOffset(x,y);
			x += maxWidth;
			if (x > maxRowWidth)
				maxRowWidth = x;
			
			if (i++ >= rowSz) {
				// if we're at the end of the row by count and it's longer
				// than previous rows (don't want to stop a row
				// if it's got lots of narrow ones..
				y += maxHeight; 
				x = HGAP;
				i = 0;	
			}						
		}	
		// roll back y if we were just about to start a new row
		if (x== HGAP)
			y-=maxHeight;
			
		height =(float)(y+maxHeight-VGAP);
		
		maxRowWidth -= HGAP; // leave of the last horizontal space between nodes
		if (maxRowWidth < nameLabel.getWidth())
			maxRowWidth = nameLabel.getWidth();
		setExtent(maxRowWidth+PConstants.SMALL_BORDER,
			height+PConstants.SMALL_BORDER);
	}
	
	private void displayDatasetSizeText(int size) {
		PText text = new PText(size +" Images");
		addChild(text);
		text.setOffset(HGAP,y);
		y+= text.getHeight()+VGAP;
		double width =text.getWidth();
		if (nameLabel.getWidth() > width) {
			width = nameLabel.getWidth();
		}
		setExtent(width+2*HGAP,y);
	}
}
