/*
 * org.openmicroscopy.vis.piccolo.PParamLink
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



/** 
 * A Piccolo node for links between inputs and outputs. Link extends
 * PPath by adding facilities for tracking a series of points.
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PParamLink extends  PLink {
	

	Point2D point = new Point2D.Float();
		
	
	// note that "start" and "end" refer to where the _drawing_
	// started and ended, not to the direction of the link. 
	// thus, start might be an input and end an output (even 
	// though links go output-input) or vice-versa.
	private PFormalParameter start = null;
	private PFormalParameter end = null;
				
				
	public PParamLink() {
		super();
	}
	
	public PParamLink(PFormalInput in,PFormalOutput out) {
		super();
		//System.err.println("link between parameters");
		this.start = in;
		this.end = out;
		start.addNodeEventListener(this);
		end.addNodeEventListener(this);
		start.setLinkedTo(end,this);
		end.setLinkedTo(start,this);
		setStartPoint();
		setEndPoint();	
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
		//System.err.println("start of pparamlink is "+point.getX()+","+point.getY());
		setStartCoords((float)point.getX(),(float) point.getY());
	}
	
	private void setEndPoint() {
		getEndPointCoords(end);
		//System.err.println("end of pparamlink is "+point.getX()+","+point.getY());
		setEndCoords((float) point.getX(),(float) point.getY());
	}
		
	private void getEndPointCoords(PFormalParameter p) {
		Point2D paramCirclePoint = p.getLinkCenter();
		point.setLocation(paramCirclePoint);
		if (p instanceof PFormalInput) {
			Point2D offset = new 
				Point2D.Double(point.getX()-PConstants.LINK_BULB_RADIUS,
								point.getY());
			point.setLocation(offset);
		}
	}
	
	
	protected void setLine() {
		//double theta;
		Point2D first;
		Point2D second;
		
		if ( start instanceof PFormalInput) {
			// in this case, we started at the input and drew back to output
		//	System.err.println("went from end to start");
			first = (Point2D) points.get(1);
			second = (Point2D) points.get(0);	
		}
		else {
			int n = points.size();
			first = (Point2D) points.get(n-2);
			second = (Point2D) points.get(n-1);
		}
		//theta = getAngle((float) first.getX(),(float)first.getY(),
		//					(float)second.getX(),(float)second.getY());
		//System.err.println("ending link at "+second.getX()+","+second.getY());
		drawLinkEnd((float) second.getX(),(float)second.getY());
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
		super.remove();
		if (linkLayer != null)
			linkLayer.removeModuleLinks(this);
		clearLinks();
	}
		
	public void clearLinks() {
		start.clearLinkedTo(end);
		end.clearLinkedTo(start);
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
	
	public PLinkTarget getStartLinkTarget() {
		return start.getLinkTarget();
	}
	
	public PLinkTarget getEndLinkTarget() {
		return end.getLinkTarget();
	}
	
	public PFormalParameter getStartParam() {
		return start;
	}
	
	public PFormalParameter getEndParam() {
		return end;
	}
}
