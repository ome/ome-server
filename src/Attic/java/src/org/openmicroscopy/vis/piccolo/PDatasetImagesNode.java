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
import java.beans.PropertyChangeListener;
import java.beans.PropertyChangeEvent;

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
public class PDatasetImagesNode extends PNode implements PropertyChangeListener {

	private static final double SCALE_THRESHOLD=.75;
	
	private PNode imagesNode = new PNode();
	private PImage thumbnailNode = null;
	
	public PDatasetImagesNode() {
		super();	
		addPropertyChangeListener(PROPERTY_TRANSFORM,this);
		addChild(imagesNode);
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
			addChild(thumbnailNode);
		}
	}
	
	public void setScale(double scale) {
		super.setScale(scale);
		System.err.println("setting scale of datasetimagenode to "+scale);
	}
	
	public void paint(PPaintContext aPaintContext) {
		if (aPaintContext.getScale() < SCALE_THRESHOLD &&
			thumbnailNode != null) {
			// show images node
			System.err.println("showing thumbnail...");
			imagesNode.setVisible(false);
			thumbnailNode.setVisible(true);
		}
		else {
			System.err.println("showing individual images");
			if (thumbnailNode != null)
				thumbnailNode.setVisible(false);
			imagesNode.setVisible(true);
		}
		super.paint(aPaintContext);
	}
	
	public void propertyChange(PropertyChangeEvent evt) {
		System.err.println("transform changed. scale is "+getScale());
	}
}
