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
import edu.umd.cs.piccolo.util.PPaintContext;
import java.awt.BasicStroke;
import java.awt.geom.Point2D;
import java.awt.Color;
import java.util.ArrayList;
import java.awt.Graphics2D;
import java.awt.geom.QuadCurve2D;
import java.awt.geom.Line2D;
import java.awt.geom.GeneralPath;
import java.awt.Shape;
import java.awt.geom.Rectangle2D;

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
		new BasicStroke(1,BasicStroke.CAP_ROUND,BasicStroke.JOIN_ROUND);

	Point2D point = new Point2D.Float();
	
	protected static final int HIGHLIGHT_SIZE=8;
	protected static final int HIGHLIGHT_RADIUS=HIGHLIGHT_SIZE/2;
	
	public static final Color DEFAULT_COLOR=Color.black;
	public static final Color HIGHLIGHT_COLOR=Color.WHITE;
	
	public static final float END_BULB=12;
	public static final float END_BULB_RADIUS = END_BULB/2;
	

	
	protected ArrayList points  = new ArrayList();
	protected PPath arrow;
	
	protected Point2D pts[];
	
	
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
		setPickable(true);
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
	
	protected abstract void setLine();
	
	public void setPoint(int index,Point2D pt) {
		//System.err.println("setting point # "+index+", # of points is "+points.size());
		if (points.size() <= index) {
			points.add(index,pt);
		}
		else
			points.set(index,pt);
		updateBounds();
	}
	

	public void paint(PPaintContext aPaintContext) {
		Graphics2D g = aPaintContext.getGraphics();
		
		g.setStroke(LINK_STROKE);
		g.setPaint(DEFAULT_COLOR);
		
		Shape p = getLinkShape();
		if (p != null)
			g.draw(p);
	}
	
	private Shape getLinkShape() {
		Shape s=null;
		Line2D line  = new Line2D.Double();
		QuadCurve2D quad = new QuadCurve2D.Double();
				
		Point2D pts[] = (Point2D []) points.toArray(new Point2D[0]);
		int size = pts.length;
		if (size == 2) {
			System.err.println("painting link with line - 2 pts.");
			System.err.println("pt1 : "+pts[0].getX()+","+pts[0].getY());
			System.err.println("pt2 : "+pts[1].getX()+","+pts[1].getY());
			line.setLine(pts[0],pts[1]);
			s= line;	
		}
		else if (size == 3) {
			System.err.println("link with quad  - 3pts");
			quad.setCurve(pts[0],pts[1],pts[2]);
			s= quad;
					}
		else if (size > 3){
			System.err.println("spline...");
			s = drawBSpline(pts);	
		}
		return s;
	}
	
	
	// Based on sample code from "Computer Graphics for Java Programmers"
	// http://home.planet.nl/~ammerall/grjava.html.
	// I'm not aware of any restrictions on the use of this example code	
	
	protected GeneralPath drawBSpline(Point2D[] pts) {
		int m = 50, n = pts.length;
		
		float p0x,p0y,p1x,p1y,p2x,p2y,p3x,p3y;
		float x,y;
		
		GeneralPath p = new GeneralPath();
		p.moveTo((float)pts[0].getX(),(float)pts[0].getY());
		n = pts.length;
		for (int i=1; i<n-2; i++) { 
			  
			  p3x=(float) ((-pts[i-1].getX()+3*(pts[i].getX()-pts[i+1].getX())+
			  	pts[i+2].getX())/6); 
			  p3y=(float) ((-pts[i-1].getY()+3*(pts[i].getY()-pts[i+1].getY())+
			  	pts[i+2].getY())/6);
			  
			  p2x=(float) ((pts[i-1].getX()-2*pts[i].getX()+pts[i+1].getX())/2);
			  p2y=(float) ((pts[i-1].getY()-2*pts[i].getY()+pts[i+1].getY())/2);
			  p1x=(float) ((pts[i+1].getX()-pts[i-1].getX())/2);
			  p1y=(float) ((pts[i+1].getY()-pts[i-1].getY())/2);
		      p0x=(float) ((pts[i-1].getX()+4*pts[i].getX()+pts[i+1].getX())/6);
		      p0y=(float) ((pts[i-1].getY()+4*pts[i].getY()+pts[i+1].getY())/6);
		      
			  for (float t=0; t<=1; t+=0.02) {  
				x = ((p3x*t+p2x)*t+p1x)*t+p0x;
				y = ((p3y*t+p2y)*t+p1y)*t+p0y;
				p.lineTo(x,y);
			}
		}	
		p.lineTo((float)pts[n-1].getX(),(float)pts[n-1].getY());
		return p;
	}
	
	protected GeneralPath drawBezier(Point2D[] pts) {
		int m = 50, n = pts.length;
		double  p0x, p1x, p2x, p3x, p0y, p1y, p2y, p3y, x, y;
		
		GeneralPath p = new GeneralPath();
		p.moveTo((float)pts[0].getX(),(float)pts[0].getY());
		n = pts.length;
		for (int i=1; i<n-2; i+=4) { 
			  
			p0x=pts[i-1].getX();
			p0y=pts[i-1].getY();
			
			p1x=-3*pts[i-1].getX()+3*pts[i].getX();
			p1y=-3*pts[i-1].getY()+3*pts[i].getY();
			
			p2x = 3*pts[i-1].getX()-6*pts[i].getX()+3*pts[i+1].getX();
			p2y = 3*pts[i-1].getY()-6*pts[i].getY()+3*pts[i+1].getY();
			
			p3x=-pts[i-1].getX()+3*(pts[i].getX()-pts[i+1].getX())+
				pts[i+2].getX(); 
						  
			p3y=-pts[i-1].getY()+3*(pts[i].getY()-pts[i+1].getY())+
							pts[i+2].getY(); 
			
			for (float t=0; t<=1; t+=0.02) {  
				x = ((p3x*t+p2x)*t+p1x)*t+p0x;
				y = ((p3y*t+p2y)*t+p1y)*t+p0y;
				p.lineTo((float)x,(float)y);
			}
		}	
		p.lineTo((float)pts[n-1].getX(),(float)pts[n-1].getY());
		return p;
	}
	
	protected void updateBounds() {
		Shape s = getLinkShape();
		if (s != null) {
			Rectangle2D b = LINK_STROKE.createStrokedShape(s).getBounds2D();
			System.err.println("updating bounds of curve..");
			System.err.println(b.getX()+","+b.getY()+", width="+b.getWidth()
				+", height = "+b.getHeight());
			super.setBounds(b.getX(), b.getY(), b.getWidth(), b.getHeight());
		}
	}
	
	
	public boolean setBounds(double x,double y,double width,double height) {
		return false;
	}
	
	public boolean intersects(Rectangle2D aBounds) {
		return getLinkShape().intersects(aBounds);
	}
		
	/*protected double getAngle(float xs,float ys,float xe,float ye) {
		double angle = 0;de
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
		System.err.println("setting arrow to be at "+x+","+y);
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
		System.err.println(" setting a link to be selected..");
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