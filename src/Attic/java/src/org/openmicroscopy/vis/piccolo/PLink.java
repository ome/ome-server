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
import java.lang.Math;
import java.awt.BasicStroke;
import java.awt.geom.Point2D;
import java.awt.Color;
//import java.awt.geom.CubicCurve2D;



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
	
	private static final int HIGHLIGHT_SIZE=8;
	private static final int HIGHLIGHT_RADIUS=HIGHLIGHT_SIZE/2;
	
	public static final Color DEFAULT_COLOR=Color.black;
	public static final Color HIGHLIGHT_COLOR=Color.WHITE;
	
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
	

	private PPath arrow;
	
	// nodes used for selection indicators
	private PPath select1;
	private PPath select2;

		
	public PLink() {		
		super();
		setStroke(LINK_STROKE);
		setPaint(DEFAULT_COLOR);
		buildArrow();
	}
	public PLink(PFormalInput in,PFormalOutput out) {
		this.start = in;
		this.end = out;
		buildArrow();
		start.addNodeEventListener(this);
		end.addNodeEventListener(this);
		start.setLinkedTo(end,this);
		end.setLinkedTo(start,this);
		setStartPoint();
		setEndPoint();
		setStroke(LINK_STROKE);
		setPaint(DEFAULT_COLOR);
		
	}
	
	private void buildArrow() {
		arrow = new PPath();
		arrow.moveTo(0,0);
		float left = -12;
		float top = -5;
		arrow.lineTo(left,top);
		arrow.lineTo(left+4,0);
		float bottom = 5;
		arrow.lineTo(left,bottom);
		arrow.closePath();
		arrow.setPaint(DEFAULT_COLOR);
		addChild(arrow);
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
		Point2D paramCirclePoint = p.getCircleCenter();
		point.setLocation(paramCirclePoint);
		//p.getLocator().locatePoint(point);
		//p.localToGlobal(point);
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
		double theta;
		reset();
		moveTo(xstart,ystart);
		lineTo(xend,yend);
//		CubicCurve2D.Float curve  = 
//			new CubicCurve2D.Float(xstart,ystart,xstart+20,ystart-20,xend-20,yend+20,xend,yend);
//		setPathTo(curve);
			
		if ( start instanceof PFormalInput) {
			theta = getAngle(xend,yend,xstart,ystart);
			drawLinkEnd(xstart,ystart,theta);
		}
		else {
			theta = getAngle(xstart,ystart,xend,yend);
			drawLinkEnd(xend,yend,theta);
		}
	}

	private double getAngle(float xs,float ys,float xe,float ye) {
		double arctan = (double) (ye-ys)/(xe-xs);
		double angle = Math.atan(arctan);
		if (xe < xs)
			angle += Math.PI;
		return angle;
	}
	
	private void drawLinkEnd(float x,float y,double theta) {
	
		//arrow.setOffset(0,0);
		arrow.setRotation(theta);
		arrow.setOffset(x,y); 
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
			PPath select1 =PPath.createEllipse(xstart-END_BULB_RADIUS,
				ystart-HIGHLIGHT_RADIUS,HIGHLIGHT_SIZE,HIGHLIGHT_SIZE);
			addChild(select1);
			PPath select2 = PPath.createEllipse(xend-HIGHLIGHT_RADIUS, 
				yend-HIGHLIGHT_RADIUS,HIGHLIGHT_SIZE,HIGHLIGHT_SIZE);
			addChild(select2);
			select1.setStrokePaint(DEFAULT_COLOR);
			select2.setStrokePaint(DEFAULT_COLOR);
			select1.setPaint(HIGHLIGHT_COLOR);
			select2.setPaint(HIGHLIGHT_COLOR);
			//setStrokePaint(HIGHLIGHT_COLOR);
			//setPaint(HIGHLIGHT_COLOR);
			moveToFront();
		}
		else {
			if (select1 != null)
				removeChild(select1);
			if (select2 != null)
				removeChild(select2);
			select1=select2=null;
		}
		repaint();
	}
	
	public PFormalInput getInput() {
		if (start instanceof PFormalInput)
			return (PFormalInput) start;
		else
			return (PFormalInput) end;
	}
	
	public PFormalOutput getOutput() {
		if (start instanceof PFormalOutput)
				return (PFormalOutput) start;
			else
				return (PFormalOutput) end;
	}
	
}
