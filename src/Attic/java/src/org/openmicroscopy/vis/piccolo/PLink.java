/*
 * org.openmicroscopy.vis.piccolo.PLink
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
import java.util.ArrayList;



/** 
 * A Piccolo node for links between inputs and outputs. Link extends
 * PPath by adding facilities for tracking a series of points.
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public abstract class PLink extends  PPath implements PNodeEventListener {
	
	public static final BasicStroke LINK_STROKE=
		new BasicStroke(2,BasicStroke.CAP_ROUND,BasicStroke.JOIN_ROUND);

	Point2D point = new Point2D.Float();
	
	protected static final int HIGHLIGHT_SIZE=8;
	protected static final int HIGHLIGHT_RADIUS=HIGHLIGHT_SIZE/2;
	
	public static final Color DEFAULT_COLOR=Color.black;
	public static final Color HIGHLIGHT_COLOR=Color.WHITE;
	
	public static final float END_BULB=12;
	public static final float END_BULB_RADIUS = END_BULB/2;
	

	
	protected ArrayList points  = new ArrayList();
	protected PPath arrow;
	
	
	protected int pointCount = 0;	
	// nodes used for selection indicators
	protected PPath select1;
	protected PPath select2;

    // the link layer that we're part of.
	protected PLinkLayer  linkLayer = null;
	
	private PNode targets = new PNode();
		
	public PLink() {		
		super();
		setStroke(LINK_STROKE);
		setStrokePaint(DEFAULT_COLOR);
		buildArrow();
		addChild(targets);
		targets.setVisible(false);
	}
		
	
	protected void buildArrow() {
		arrow = new PPath();
		
		arrow.moveTo(0,0);
		float top = -5;
		float bottom = 5;
		arrow.lineTo(-4,top);
		arrow.lineTo(PConstants.ARROWHEAD_WIDTH,0);
		arrow.lineTo(-4,bottom);
		
		/*float left = -PConstants.ARROWHEAD_WIDTH;
		
		arrow.lineTo(left,top);
		arrow.lineTo(left-4,0);
		
		arrow.lineTo(left,bottom);*/
		arrow.closePath();
		arrow.setPaint(DEFAULT_COLOR);
		addChild(arrow);
	}
	
	
	public void setStartCoords(float x,float y) {

		setPoint(0,new Point2D.Float(x,y));
		if (pointCount == 0)
			pointCount =1;
	}

	public void setIntermediatePoint(float x,float y) {
		setPoint(pointCount++,new Point2D.Float(x,y)); 
		setEndCoords(x,y);
	}
	
	public void setEndCoords(float x,float y) {
		setPoint(pointCount,new Point2D.Float(x,y));
		setLine();
	}
	
	public void setPoint(int index,Point2D pt) {
		//System.err.println("setting point # "+index+", # of points is "+points.size());
		if (points.size() <= index) {
			points.add(index,pt);
		}
		else
			points.set(index,pt);
	}
	
	protected void setLine() {
		Point2D dummy[] = new Point2D[0];
		Point2D pts[] = (Point2D []) points.toArray(dummy);
		setPathToPolyline(pts);	
	}

	/*protected double getAngle(float xs,float ys,float xe,float ye) {
		double angle = 0;
		double arctan = 0;
		
		if (xe !=xs) {
			arctan = (double) (ye-ys)/(xe-xs);
			angle = Math.atan(arctan);
			if (xe < xs)
				 angle += Math.PI;	
		}
		// shouldn't have to do this, but there's a bug on Mac OS X java.
		if (angle > 0.8) {
			if (angle <0.85) 
				angle = 0.7;
			else if (angle < 0.9)
				angle = 1.0;
		}
		return angle;
	} */
 	
	protected void drawLinkEnd(float x,float y) {
		//System.err.println("setting arrow to be at "+x+","+y+", theta="+theta);
		Point2D pt = globalToLocal(new Point2D.Float(x,y));
		//arrow.setRotation(theta);
		arrow.setOffset(pt.getX(),pt.getY());
		invalidateFullBounds(); 
		
		repaint();
	}
	
	
	public abstract void nodeChanged(PNodeEvent e); 
	
	public void remove() {
		removeFromParent();
	}

	public abstract PLinkTarget getStartLinkTarget();
	
	public abstract PLinkTarget getEndLinkTarget();

	public void setSelected(boolean v) {
		PLinkTarget startTarget = getStartLinkTarget();
		PLinkTarget endTarget = getEndLinkTarget();
		startTarget.setSelected(v);
		endTarget.setSelected(v);
		targets.removeAllChildren();
		if (v == true) { // set up children 
			targets.setVisible(true);
			int count =  points.size();
			for (int i = 1; i < count-1; i++) {
				PLinkSelectionTarget t = new PLinkSelectionTarget(this,i);
				targets.addChild(t);
				Point2D pt = (Point2D) points.get(i);
				t.setOffset((float)pt.getX()-PLinkTarget.LINK_TARGET_HALF_SIZE,
					(float)pt.getY()-PLinkTarget.LINK_TARGET_HALF_SIZE);
				t.setSelected(v);
			}
		}
		repaint();
	}
	
	public void setLinkLayer(PLinkLayer linkLayer) {
		this.linkLayer = linkLayer;
	}
}