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
import edu.umd.cs.piccolo.util.PBounds;
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

public class PDataset extends PCategoryBox {
	
	private CDataset dataset;
	private Connection connection;
	
	private static float VGAP=10;
	private static float HGAP=5;

	private double x=HGAP;
	private double y=VGAP;
	private float maxHeight = 0;
	
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
		List images = dataset.getCachedImages(connection);
		Iterator iter = images.iterator();
		maxHeight = 0;
		float maxWidth = 0;
		Vector nodes = new Vector();
		// draw label
		PText nameLabel = new PText(dataset.getName());
		addChild(nameLabel);
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
		// roll back y if we were just about to start a new row
		if (x== HGAP)
			y-=maxHeight;
			
		PBounds b = getFullBoundsReference();
		height =(float)(y+maxHeight-VGAP);
		
		setExtent(b.getWidth()+PConstants.SMALL_BORDER,
			height+PConstants.SMALL_BORDER);
	}
}
