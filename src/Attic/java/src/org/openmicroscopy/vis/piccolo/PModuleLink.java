/*
 * org.openmicroscopy.vis.piccolo.PModuleLink
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
 import edu.umd.cs.piccolo.PNode;
 import java.awt.geom.Point2D;
 import edu.umd.cs.piccolo.util.PBounds; 
 
 
 
 public class PModuleLink extends PLink {
 	
 	private PModule start;
 	private PModule end;
 	
 
 	
 	public PModuleLink(PLinkLayer layer,PModule start,PModule end) {
 		super();
 		setLinkLayer(layer);
 		this.start= start;
 		this.end = end;
 		
 		start.addNodeEventListener(this);
 		end.addNodeEventListener(this);
 		setStartPoint();
 		setEndPoint();
 	}
 	
 	public PLinkTarget getStartLinkTarget() {
 		return start.getOutputLinkTarget();
 	}
 	
 	public PLinkTarget getEndLinkTarget() {
 		return end.getInputLinkTarget();
 	}
 	
 	private void setStartPoint() {
 		Point2D point = getStartLinkTarget().getCenter();
 		PBounds b = start.getGlobalFullBounds();
 		setStartCoords((float) point.getX(),(float) point.getY()); 	
 	}
 	
	private void setEndPoint() {
		Point2D point = getEndLinkTarget().getCenter();
		setEndCoords((float) point.getX()-PConstants.LINK_BULB_RADIUS,
			(float) point.getY());
	}
	
	public void nodeChanged(PNodeEvent e) {
		PNode node = e.getNode();
		if (!(node instanceof PModule))
			return;
		if (node == start) {
			setStartPoint();
			setLine();
		}
		else if (node == end)
			setEndPoint();
	}
	
	public void setIntermediatePoint(float x,float y) {
		System.err.println("setting intermediate point in Module Link..");
		System.err.println("point # "+pointCount+" is "+x+","+y);
		super.setIntermediatePoint(x,y);
	}
		
	protected void setLine() {
			
		int n = points.size();
		Point2D start = (Point2D) points.get(n-2);
		Point2D end = (Point2D) points.get(n-1);
		
	//	double theta = getAngle((float) start.getX(),(float)start.getY(),
	//		(float)end.getX(),(float)end.getY());
		drawLinkEnd((float) end.getX(),(float)end.getY());
	}
	
	protected PModule getStart() {
		return start;
	}
	
	protected PModule getEnd() { 
		return end;
	}
	
	public void remove() {
		super.remove();
		getStartLinkTarget().setSelected(false);
		getEndLinkTarget().setSelected(false);
		if (linkLayer!= null)
			linkLayer.removeParamLinks(this);
	}
 }