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
	
	public PDatasetImagesNode() {
		super();	
		addChild(imagesNode);
		setPickable(true);
	}
	
	public void addImage(PThumbnail thumb) {
		imagesNode.addChild(thumb);
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
			System.err.println("thumbnail node is "+thumbnailNode);
			addChild(thumbnailNode);
		}
	}
	
	public void setScale(double scale) {
		super.setScale(scale);
		System.err.println("setting scale of datasetimagenode to "+scale);
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
}
