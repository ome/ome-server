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
import java.lang.Math;
import java.awt.BasicStroke;
import java.awt.geom.Point2D;
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
	
	
		
	// xs and ys for line
	protected float xstart,ystart;
	protected float xend,yend;
	

	protected PPath arrow;
	
	// nodes used for selection indicators
	protected PPath select1;
	protected PPath select2;

    // the link layer that we're part of.
	protected PLinkLayer  linkLayer = null;
		
	public PLink() {		
		super();
		setStroke(LINK_STROKE);
		setPaint(DEFAULT_COLOR);
		buildArrow();
	}
		
	
	protected void buildArrow() {
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
	
	
	public void setStartCoords(float x,float y) {
		xstart = x;
		ystart = y;
	}

	public void setEndCoords(float x,float y) {
		xend = x;
		yend = y;
		setLine();
	}
	
	protected abstract void setLine();

	protected double getAngle(float xs,float ys,float xe,float ye) {
		double arctan = (double) (ye-ys)/(xe-xs);
		double angle = Math.atan(arctan);
		if (xe < xs)
			angle += Math.PI;
		return angle;
	}
	
	protected void drawLinkEnd(float x,float y,double theta) {
		arrow.setRotation(theta);
		arrow.setOffset(x,y); 
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
		 /*if (v == true) {
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
			moveToFront();
		}
		else {
			if (select1 != null)
				removeChild(select1);
			if (select2 != null)
				removeChild(select2);
			select1=select2=null;
		} */
		repaint();
	}
	
	public void setLinkLayer(PLinkLayer linkLayer) {
		this.linkLayer = linkLayer;
	}
}