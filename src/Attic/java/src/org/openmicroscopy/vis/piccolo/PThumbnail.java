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
import edu.umd.cs.piccolo.util.PPickPath;
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

public class PThumbnail extends PNode implements PBufferedNode, 
	PBrowserNodeWithToolTip {

	private final static String DEFAULT_LABEL="No Thumbnail";
	
	private CImage image;	
	private PImage imageNode=null;
	private BufferedImage imageData;
	private PText label=null;
	
	private PPath highlightRect;
	
	
	public PThumbnail(CImage image) {
		super();
		this.image=image;
		imageData = image.getImageData();
		if (imageData != null) {
			imageNode = new PBufferedImage(imageData);
			addChild(imageNode);
		}
		else {
			label = new PText(image.getName());
			label.setFont(PConstants.THUMBNAIL_NAME_FONT);
			addChild(label);
		}
		image.addThumbnail(this);
	}
	/**
	 * @return
	 */
	public CImage getImageData() {
		return image;
	}
	
	public PBounds getGlobalFullBounds() {
		PBounds b  = super.getGlobalFullBounds();
		
		//if (label != null) {
		if (imageNode == null) {
			return new PBounds(b.getX(),b.getY(),50,50);
		}
		else {	
			return imageNode.getGlobalFullBounds();
		}
	}
	
	protected boolean pick(PPickPath pickPath) {
		if (imageNode != null) {
			PBounds b = imageNode.getFullBoundsReference();
			if (b.intersects(pickPath.getPickBounds())) 
				return true;
			else 
				return false;
		}
		else 
			return false;
	}
	
	
	public PBounds getBufferedBounds() {
			PBounds b = getGlobalFullBounds();
			return new PBounds(b.getX()-PConstants.SMALL_BORDER,
				b.getY()-PConstants.SMALL_BORDER,
				b.getWidth()+2*PConstants.SMALL_BORDER,
				b.getHeight()+2*PConstants.SMALL_BORDER);
	}
	
	// note that this only gets called when the imageData was initially null,
	// so we know that we don't have to check if label is null, etc.
	public void notifyImageComplete() {
//		System.err.println("image "+image.getID()+", is complete");
		removeAllChildren();
		imageData = image.getImageData();
		imageNode = new PBufferedImage(imageData);
		addChild(imageNode); 
	}
	
	public int compareTo(Object o) {
		if (o instanceof PBufferedNode) {
			PBufferedNode node = (PBufferedNode) o;
			double myArea = getHeight()*getWidth();
			PBounds bounds = node.getBufferedBounds();
			double nodeArea = bounds.getHeight()*bounds.getWidth();
			int res =(int) (myArea-nodeArea);
			return res;
		}
		else
			return -1;
	}
	
	public void setHighlighted(boolean v) {
		// no highlight if no image. 
		
		if (imageNode == null)
			return;
		if (v == true) {
			if (highlightRect == null)
				highlightRect = makeHighlight(imageNode);
			addChild(highlightRect);
		//	System.err.println("highlighting image for "+image.getID());
		}
		else {
		//	System.err.println("unhighlighting image for "+image.getID());
			if (highlightRect != null && isAncestorOf(highlightRect))
				removeChild(highlightRect);
		}
		image.highlightThumbnails(v);
	}
	
	private PPath makeHighlight(PImage imageNode) {
		PBounds b = imageNode.getFullBoundsReference();
		PPath path = new PPath(b);
		path.setStroke(PConstants.BORDER_STROKE);
		path.setStrokePaint(PConstants.SELECTED_HIGHLIGHT_COLOR);
		return path;
	}
	
	public PNode getFullToolTip() {
		if (imageNode == null)
			return null;
		PNode n = new PNode();
		Image im = imageNode.getImage();
		PImage imNode = new PImage(im,false);
		n.addChild(imNode);
		PPath p = new PPath();
		PText text  = new PText(image.getName());
		text.setFont(PConstants.TOOLTIP_FONT);
		p.addChild(text);
		n.addChild(p);
		p.moveToBack();
		p.setPathTo(text.getBounds());
		p.setPaint(PToolTipHandler.FILL_COLOR);
		p.setStrokePaint(PToolTipHandler.BORDER_COLOR);
		p.setBounds(p.getUnionOfChildrenBounds(null));
		p.setOffset(0.0,imNode.getHeight());
		return n;
	}
	
	public PNode getShortToolTip() {
		PText text  = new PText(image.getName());
		text.setFont(PConstants.TOOLTIP_FONT);
		return text;
	}
}