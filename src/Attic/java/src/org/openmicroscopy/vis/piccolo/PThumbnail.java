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

public class PThumbnail extends PBufferedImage implements PBufferedNode, 
	PBrowserNodeWithToolTip {

	private final static String DEFAULT_LABEL="No Thumbnail";
	
	private CImage image;	
	
	
	private PPath highlightRect=null;
	
	
	public PThumbnail(CImage image) {
		super();
		this.image=image;
		BufferedImage imageData = image.getImageData();
		setImage(imageData);
		
		image.addThumbnail(this);
	}

	
	
	
	
	public PBounds getBufferedBounds() {
			PBounds b = getGlobalFullBounds();
			System.err.println("thumbnail global scale is "+getGlobalScale());
			return new PBounds(b.getX()-PConstants.SMALL_BORDER*getGlobalScale(),
				b.getY()-PConstants.SMALL_BORDER*getGlobalScale(),
				b.getWidth()+2*PConstants.SMALL_BORDER*getGlobalScale(),
				b.getHeight()+2*PConstants.SMALL_BORDER*getGlobalScale());
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
		
		//if (imageNode == null)
		//	return;
		if (v == true) {
			if (highlightRect == null)
				highlightRect = makeHighlight();
			addChild(highlightRect);
		//	System.err.println("highlighting image for "+image.getID());
		}
		else {
		//	System.err.println("unhighlighting image for "+image.getID());
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
	
	public PNode getFullToolTip() {
		//if (imageNode == null)
		//	return null;
		PNode n = new PNode();
		Image im = getImage();
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
	
	// pthumbnails will generally be held in PDatasetImageNodes, which
	// has a child node aboove the thumbnail and is then contained in a dataset. will fail gracefully otherwise
	
	public PBufferedNode getBufferedParentNode() {
		
		PNode parent=this.getParent();
		while (parent != null  && !(parent instanceof PBufferedNode))
			parent = parent.getParent();
		return (PBufferedNode) parent;
		
	}
}