/*
 * org.openmicroscopy.vis.piccolo.PThumbnail
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

import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.nodes.PImage;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.nodes.PPath;
import org.openmicroscopy.vis.ome.CImage;
import java.awt.image.BufferedImage;
import java.awt.Image;

/** 
 * A node for displaying a thumbnail of an OME IMAGe
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PThumbnail extends PImage implements PBufferedObject, 
	PBrowserNodeWithToolTip {

	private final static String DEFAULT_LABEL="No Thumbnail";
	
	private CImage image;	
	
	
	private PPath highlightRect=null;
	
	
	public PThumbnail(CImage image) {
		super();
		setAccelerated(true);
		this.image=image;
		BufferedImage imageData = image.getImageData();
		setImage(imageData);
		
		image.addThumbnail(this);
	}
	
	/**
	 * Buffered Bounds of the thumbnail, as required by {@link PBufferedObject}.
	 * Buffer must be scaled to
	 * account for scaling of the node
	 * 
	 * @return buffered bounds
	 */	
	public PBounds getBufferedBounds() {
		PBounds b = getGlobalFullBounds();
		return new PBounds(b.getX()-PConstants.SMALL_BORDER*getGlobalScale(),
			b.getY()-PConstants.SMALL_BORDER*getGlobalScale(),
			b.getWidth()+2*PConstants.SMALL_BORDER*getGlobalScale(),
			b.getHeight()+2*PConstants.SMALL_BORDER*getGlobalScale());
	}
	
	
	/**
	 * To turn the highlight for this image on or off, tell the associated
	 * {@link CImage} to highlight all of its thumbnails. This will cause
	 * thumbnails of this image in other datasets to be similarly highlighted.
	 * 
	 * @parm v true if highlighting, false if not.
	 */
	public void setHighlighted(boolean v) {
	
		
		// Show highlighted path.
		if (v == true) {
			if (highlightRect == null) 
				highlightRect = makeHighlight();
			addChild(highlightRect);
		}
		else {
			if (highlightRect != null && isAncestorOf(highlightRect))
					removeChild(highlightRect);
			highlightRect = null;
		}
		image.highlightThumbnails(v);
	}
	
	private PPath makeHighlight() {
		 PBounds b = getBounds();
		 PPath path = new PPath(b);
		 path.setStroke(PConstants.BORDER_STROKE);
		 path.setStrokePaint(PConstants.SELECTED_HIGHLIGHT_COLOR);
		 path.setPickable(false);
		 return path;
 	}

	/**
	 * The full tooltip for a thumbnail contains both a scaled version of the
	 * thumbnail image and the name of the image.
	 */
	public PNode getFullToolTip() {
		//if (imageNode == null)
		//	return null;
		PNode n = new PNode();
		Image im = getImage();
		PImage imNode = new PImage(im,false);
		n.addChild(imNode);
		PPath p = new PPath();
		//PText text  = new PText(image.getName());
		//text.setFont(PConstants.TOOLTIP_FONT);
		PNode text = getShortToolTip();
		p.addChild(text);
		n.addChild(p);
		p.moveToBack();
		p.setPathTo(text.getBounds());
		p.setPaint(PToolTipHandler.FILL_COLOR);
		p.setStrokePaint(PToolTipHandler.BORDER_COLOR);
		p.setBounds(p.getUnionOfChildrenBounds(null));
		p.setOffset(0.0,imNode.getHeight());
		n.setPickable(false);
		return n;
	}
	
	/**
	 * The shorter tooltip contains simply the name of the image.
	 */
	public PNode getShortToolTip() {
		PText text  = new PText(image.getName());
		text.setFont(PConstants.TOOLTIP_FONT);
		text.setPickable(false);
		return text;
	}
	
	/**
	 * To get the buffered parent node  for a thumbnail, go up the chain 
	 * of ancenstors until a {@link PBufferedObject} is found.
	 * 
	 * @return the first {@link PBufferedObject} in the ancestros, or null. 
	 */
	public PBufferedObject getBufferedParentNode() {
		
		PNode parent=this.getParent();
		while (parent != null  && !(parent instanceof PBufferedObject))
			parent = parent.getParent();
		return (PBufferedObject) parent;
		
	}
	
	/**
	 * These objects will generally be used as children of 
	 * {@link PDatasetImagesNode} objects.  However, they are grandchildren
	 * of the {@link PDatasetImagesNode} objects. Use this relationship to find our 
	 * way back to the {@link PDatasetImagesNode}
	 */
	public PDatasetImagesNode getDatasetImagesNode() {
		PNode parent = getParent();
		if (parent == null)
			return null;
	
		parent = parent.getParent();
		if (parent == null)
			return null; // case a also

		if (!(parent instanceof PDatasetImagesNode))
			return null; // case a, yet again
	
		PDatasetImagesNode pin = (PDatasetImagesNode) parent;
		return pin;
	}
	
 	/**
 	 * Called to turn the highlight of this thumbnail on or off. 
 	 * Finds the appropriate {@link PDatasetImagesNode} and calls 
 	 * the appropriate procedure for turning the highlight on or off.
 	 * @param v true if highlighted. else false.
 	 * @param level the magnification level of the canvas. 
 	 * 	See {@link PDatasetImagesNode}  for descriptions of these levels
 	 */
	public void setZoomingHalo(boolean v,int level) {
		//	ok. if I'm under a pdatasetimages node, setup the halo
		PDatasetImagesNode pin = getDatasetImagesNode();
		if (pin != null)
		 	pin.highlightThumbnail(this,v,level);
	} 	
	
	/**
	 *  Called on mouse events from {@link PBrowserEventHandler},
	 *  to set the highlight on this node and then the halo.
	 * @param v
	 * @param level
	 */
	public void setHighlightedWithHalo(boolean v,int level) {
		setHighlighted(v);
		setZoomingHalo(v,level);
	}
	
	/**
	 * When the user clicks on a thumbnail, the thumbnail will be zoomed to the 
	 * next greater level of magnification
	 * 
	 * @param The original level
	 * @return The zoom level after the zoom 
	 */
	public int zoomInToHalo(int level) {
		PDatasetImagesNode pin = getDatasetImagesNode();
		if (pin != null)
			return pin.zoomInToHalo(this,level);
		else 
			return level;
			
	}
	
	/**
	 * When the user right-clicks on a thumbnail, the thumbnail will be 
	 * zoomed to the next lower level of magnification
	 * 
	 * @param The original level
	 * @return The zoom level after the zoom 
	 */
	public int zoomOutOfHalo(int level) {
		PDatasetImagesNode pin = getDatasetImagesNode();
		if (pin != null)
			return pin.zoomOutOfHalo(this,level);
		else 
			return level;
		
	}
}