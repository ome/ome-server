/*
 * org.openmicroscopy.vis.piccolo.PLinkSelectionTarget
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
import java.awt.geom.Point2D;

/** 
 * A Piccolo widget indicating a control point for a selected {@link PLink}
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */
public class PLinkSelectionTarget extends PLinkTarget {
	
	/**
	 * The {@link PLink} in question
	 */
	private PLink link;
	
	/**
	 * The index of this point in the {@link PLink}, from 0 to n-1 (inclusive),
	 * where n is the number of control points.
	 */
	private int index;
	
	
	public PLinkSelectionTarget(PLink link,int index) {
		super();
		this.link = link;
		this.index = index;
	}
	
	public PLink getLink() {
		return link;
	}
	
	public int getIndex() {
		return index;
	}
	
	/**
	 * When the selection is translated, the {@link PLink} containing this 
	 * control point is updated ton coontain the new control point. 
	 * The {@link PLink} is also redrawn
	 * 
	 * param x   the new coordinates of the control point 
	 * param y
	 */
	public void translate(double x,double y) {
		
		super.translate(x,y);
		Point2D pt = getOffset();
	//	System.err.println("new offset is "+pt.getX()+","+pt.getY());
		Point2D newPt = new Point2D.Float((float) pt.getX()+
			PLinkTarget.LINK_TARGET_HALF_SIZE,
			(float) pt.getY()+PLinkTarget.LINK_TARGET_HALF_SIZE);
		link.setPoint(index,newPt);
		link.setLine();
		link.setSelected(true);
		// adjust point in line
	}
	
}