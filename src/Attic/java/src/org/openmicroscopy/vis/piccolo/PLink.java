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
	
	// degree for splines.
	private static final int DEGREE = 3;	
	protected ArrayList points  = new ArrayList();
	protected PPath bulb;
	
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
		buildBulb();
		addChild(targets);
		targets.setVisible(false);
		setPickable(true);
	}
		
	
	protected void buildBulb() {
	
		bulb = PPath.createEllipse(0,0,PConstants.LINK_BULB_SIZE,
			PConstants.LINK_BULB_SIZE);
		bulb.setPaint(DEFAULT_COLOR);
		addChild(bulb);
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
			line.setLine(pts[0],pts[1]);
			s= line;	
		}
		else if (size == 3) {
			quad.setCurve(pts[0],pts[1],pts[2]);
			s= quad;
					}
		else if (size > 3){
			//s = drawBSpline(pts);
			s = drawGeneralBSpline(pts);	
		}
		return s;
	}
	
	
	
	protected GeneralPath drawGeneralBSpline(Point2D pts[]) {
		GeneralPath p = new GeneralPath();
		int n = pts.length;
		float[] knots = buildKnotArray(n);
		boolean first = true;
		
		float x,y;
		
		dumpPoints(pts);
		int len = knots.length;
		float maxKnot = knots[len-DEGREE-3];
		float minKnot = knots[0];
		for (double t = (double) minKnot; t< maxKnot; t+=.3) {
		
			Point2D pt = getSplinePoint(t,knots,pts);
			if (first) {
				System.err.println("moving to "+pt.getX()+","+pt.getY());
				p.moveTo((float) pt.getX(),(float)pt.getY());
				first  = false;
			}
			else {
				p.lineTo((float) pt.getX(),(float)pt.getY());
				System.err.println("line to "+pt.getX()+","+pt.getY());
			}	
		}
	//	p.lineTo((float)pts[n-1].getX(),(float)pts[n-1].getY());
		return p;
	}
	
	private void dumpPoints(Point2D[] pts) {
		for (int i = 0; i < pts.length; i++ ) {
			System.err.println(i+") ("+pts[i].getX()+","+pts[i].getY()+")");
		}
	}
	
	private float[] buildKnotArray(int n) {
		int size = n+2*DEGREE;
		float[] knots  =new float[size];
		
		for (int i =0; i < size; i++) {
			if (i < DEGREE)
				knots[i]=0;
			else if (i >= n+DEGREE) 
				knots[i]=n-1;
			else 
				knots[i]= i-DEGREE;
		}
		
		for (int i = 0; i < size; i++ ) {
			System.err.println("knot "+i+"+ is "+knots[i]);
		}
		return knots;
	} 
	
	private Point2D getSplinePoint(double u,float[] knots,Point2D[] pts) {
		Point2D p = new Point2D.Double();
	
		int n = pts.length;
		double x=0,y=0;
		
		System.err.println("point for u ="+u);
		for (int i = 0; i< n; i++) {
			double cdb = coxDeBoor(i,DEGREE,u,knots);	
			System.err.println("cdb  of "+i+" is "+cdb);
			x +=cdb*pts[i].getX();
			y +=cdb*pts[i].getY();
		}
//		System.err.println("found spline point "+x+","+y);
		p.setLocation(x,y);
		return p;
	}
	
	private double coxDeBoor(int k, int d,double u,float[] knots){
		if (d == 0) {
			if (u >= knots[k] && u <knots[k+1])
				return 1;
			else
				return 0;
		}
		
		double sum = 0;
		double denom1 = knots[k+d]-knots[k];
		if (denom1 != 0)
			sum += (u-knots[k])/denom1*coxDeBoor(k,d-1,u,knots);
		double denom2  = knots[k+d+1]-knots[k+1];
		if (denom2 !=0) 
			sum += (knots[k+d+1]-u)/denom2*coxDeBoor(k+1,d-1,u,knots);
		return sum;
	}
	
	protected GeneralPath drawBSpline(Point2D[] pts) {
		int m = 50, n = pts.length;
		
				
		GeneralPath p = new GeneralPath();
		p.moveTo((float)pts[0].getX(),(float)pts[0].getY());
		n = pts.length;
		for (int i=1; i<n-2; i++) { 
			getPoints(p,pts[i-1],pts[i],pts[i+1],pts[i+2]);		 
		}	
		p.lineTo((float)pts[n-1].getX(),(float)pts[n-1].getY());
		return p;	
	
	}
	
	private void getPoints(GeneralPath p,Point2D p0,Point2D p1,Point2D p2,
		Point2D p3) {

		float p0x,p0y,p1x,p1y,p2x,p2y,p3x,p3y;
		float x,y,prevX=0,prevY=0;
			
		int iter=0;
				
		p3x=(float) ((-p0.getX()+3*(p1.getX()-p2.getX())+p3.getX())/6); 
		p3y=(float) ((-p0.getY()+3*(p1.getY()-p2.getY())+p3.getY())/6);
			  
		p2x=(float) ((p0.getX()-2*p1.getX()+p2.getX())/2);
		p2y=(float) ((p0.getY()-2*p1.getY()+p2.getY())/2);
		p1x=(float) ((p2.getX()-p0.getX())/2);
		p1y=(float) ((p2.getY()-p0.getY())/2);
		p0x=(float) ((p0.getX()+4*p1.getX()+p2.getX())/6);
		p0y=(float) ((p0.getY()+4*p1.getY()+p2.getY())/6);
		for (float t=0; t<=1; t+=0.02) {  
			x = ((p3x*t+p2x)*t+p1x)*t+p0x;
			y = ((p3y*t+p2y)*t+p1y)*t+p0y;
			if (iter == 0) {
				prevX=x;
				prevY=y;
				
			}
			else if (iter == 1) {
				p.quadTo(x,y,prevX,prevY);
			}
			else
				p.lineTo(x,y);
			iter++;
		}	
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
		
 	
	protected void drawLinkEnd(float x,float y) {
		bulb.setOffset(x-PConstants.LINK_BULB_RADIUS,
			y-PConstants.LINK_BULB_RADIUS);
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
			bulb.setPaint(HIGHLIGHT_COLOR);
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
		else
			bulb.setPaint(DEFAULT_COLOR);
		repaint();
	}
	
	public void setLinkLayer(PLinkLayer linkLayer) {
		this.linkLayer = linkLayer;
	}
}