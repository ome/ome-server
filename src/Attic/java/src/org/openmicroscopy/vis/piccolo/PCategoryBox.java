/*
 * org.openmicroscopy.vis.piccolo.PCategoryBox
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

import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.geom.Rectangle2D;
import java.awt.Color;

/** 
 * A subclass of {@link PPath} that is used to provide a colored background
 * to various widgets in the Chain builder
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PCategoryBox extends PPath implements PBufferedNode {
	
	private static final Color CATEGORY_COLOR= new Color(204,204,255,100);
	
	private PText label = null;
	public PCategoryBox() {
		this(0,0,0,0);
	}
	
	public PCategoryBox(float x,float y) {
		this(x,y,0f,0f);
	}
	
	public PCategoryBox(float x,float y,float w,float h) {
		super();
		setPathTo(new Rectangle2D.Float(x,y,w,h));
		setStrokePaint(null);
		setPaint(CATEGORY_COLOR);
	}
	
	/**
	 * The bounds of a category box include a space of {@link PConstants.BORDER}
	 * around the box in all four directions. This buffer is needed for 
	 * appropriate scaling: using these bounds, we can zoom to center the node 
	 * without having it occupy the whole canvas.
	 * 
	 * @return the bounds of the box with the appropriate spacing buffer.
	 */
	public PBounds getBufferedBounds() {
		PBounds b = getFullBoundsReference();
		return new PBounds(b.getX()-PConstants.BORDER,
			b.getY()-PConstants.BORDER,
			b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER);
	}
	
	/**
	 * Set the size of the box
	 * @param width the new width
	 * @param height the new height
	 */
	public void setExtent(double width,double height) {
		PBounds b = getFullBoundsReference();
		reset();
		setPathTo(new PBounds(b.getX(),b.getY(),width,height));
	}
	
	/**
	 * Add a node containing a textual label
	 * @param label
	 */
	public void addLabel(PText label) {
		addChild(label);
		this.label = label;
	
	}
	
	public  float getLabelHeight() {
		if (label != null)
			return (float)label.getFullBoundsReference().getHeight();
		else
			return 0f;		
	}
} 