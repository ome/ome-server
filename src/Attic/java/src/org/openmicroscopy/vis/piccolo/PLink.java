/*
 * org.openmicroscopy.vis.piccolo.Link
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
import edu.umd.cs.piccolo.PNode;
import java.awt.BasicStroke;
import java.awt.geom.Point2D;
import java.awt.geom.Ellipse2D;
import java.awt.Color;


/** 
 * A Piccolo node for links between inputs and outputs. Link extends
 * PPath by adding facilities for tracking a series of points.
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PLink extends  PPath implements PNodeEventListener {
	
	public static final BasicStroke LINK_STROKE=
		new BasicStroke(2,BasicStroke.CAP_ROUND,BasicStroke.JOIN_ROUND);

	Point2D point = new Point2D.Float();
	
	private static final int HANDLE_SIZE=8;
	private static final int HANDLE_RADIUS= (int) (HANDLE_SIZE/2);
	
	public static final Color DEFAULT_COLOR=Color.black;
	public static final Color HIGHLIGHT_COLOR=Color.red;
	
	public static final float END_BULB=12;
	public static final float END_BULB_RADIUS = END_BULB/2;
	
	
	// note that "start" and "end" refer to where the _drawing_
	// started and ended, not to the direction of the link. 
	// thus, start might be an input and end an output (even 
	// though links go output-input) or vice-versa.
	private PFormalParameter start = null;
	private PFormalParameter end = null;
		
	// xs and ys for line
	float xstart,ystart;
	float xend,yend;
		
	public PLink() {		
		super();
		setStroke(LINK_STROKE);
		setPaint(DEFAULT_COLOR);
	}
	
	public void setStartParam(PFormalParameter start) {
	
		this.start = start;
		start.addNodeEventListener(this);
		setStartPoint();
	}
	
	public void setEndParam(PFormalParameter end) {
		this.end = end;
		if (start != null) {
			end.setLinkedTo(start,this);  
			start.setLinkedTo(end,this);
		}
		end.addNodeEventListener(this);
		setEndPoint();
	}

	private void setStartPoint() {
		getEndPointCoords(start);
		setStartCoords((float)point.getX(),(float) point.getY());
	}
	
	private void setEndPoint() {
		getEndPointCoords(end);
		setEndCoords((float) point.getX(),(float) point.getY());
	}
		
	private void getEndPointCoords(PFormalParameter p) {
		p.getLocator().locatePoint(point);
		p.localToGlobal(point);
	}

	
	public void setStartCoords(float x,float y) {
		xstart = x;
		ystart = y;
	}

	
	public void setEndCoords(float x,float y) {
		xend = x;
		yend = y;
		setLine();
	}
	
	private void setLine() {
		reset();
		moveTo(xstart,ystart);
		lineTo(xend,yend);	
		if ( start instanceof PFormalInput) {
			drawLinkEnd(xstart,ystart);
		}
		else {
			drawLinkEnd(xend,yend);
		}
	}

	
	private void drawLinkEnd(float x,float y) {
		Ellipse2D.Float bulb = new Ellipse2D.Float(x-END_BULB_RADIUS,
			y-END_BULB_RADIUS,END_BULB,END_BULB);
		append(bulb,false);
	}
	
	
	public void nodeChanged(PNodeEvent e) {
		PNode node =e.getNode();
		if (!(node instanceof PFormalParameter))
			return;
		if (node == start) {
			setStartPoint();
			setLine();
		}
		else if (node == end) 
			setEndPoint(); // setLine() call is implied.
	}		
	
	public void remove() {
		removeFromParent();
		start.clearLinkedTo(end);
		end.clearLinkedTo(start);
	}
	
	public void setSelected(boolean v) {
		if (v == true) {
			setStrokePaint(HIGHLIGHT_COLOR);
			setPaint(HIGHLIGHT_COLOR);
			moveToFront();
		}
		else {
			setStrokePaint(DEFAULT_COLOR);
			setPaint(DEFAULT_COLOR);
		}
		repaint();
	}
	
}
