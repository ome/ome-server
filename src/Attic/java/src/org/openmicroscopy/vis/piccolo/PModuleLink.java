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
 
 
/** 
 * A Piccolo node for links between between {@link PModule} objects. These 
 * links are shown when the magnification level is too low to show the 
 * individual links between parameters. Thus, this class of link is used for
 * semantic zooming.
 *
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */ 
 public class PModuleLink extends PLink {
 	
 	/**
 	 * The {@link PModule}s that are the start and end of this link. Unlike
 	 * {@link PLink}, objects of this class always have start being the output
 	 * and end being the input
 	 */
 	private PModule start;
 	
 	private PModule end;
 	
 
 	/**
 	 * Create the node in the appropriate layer, and establish listeners:
 	 * this link wants to hear from events at either end
 	 * @param layer
 	 * @param start
 	 * @param end
 	 */
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
	
	/**
	 * When this object gets a node changed event, call {@link setStartPoint()}
	 * or {@link setEndPoint}. The calls will look at the location of the 
	 * appropriate {@link PLinkTarget}. Since the {@PModule} has changed,
	 * the {@link PLinkTarget} will have changed, and therefore the 
	 * points will be updated as needed.
	 */
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
	
	
	/**
	 * Draw the end of the link at the appropriate point. Since the end of the 
	 * link is always the side that goes to an input, we just draw the link 
	 * end at the last point in the list. 
	 */	
	protected void setLine() {
			
		int n = points.size();
		Point2D end = (Point2D) points.get(n-1);
		drawLinkEnd((float) end.getX(),(float)end.getY());
	}
	
	protected PModule getStart() {
		return start;
	}
	
	protected PModule getEnd() { 
		return end;
	}
	
	/**
	 * Remove this link from the targets and from the {@link PLinkLayer}
	 */
	public void remove() {
		super.remove();
		getStartLinkTarget().setSelected(false);
		getEndLinkTarget().setSelected(false);
		if (linkLayer!= null)
			linkLayer.removeParamLinks(this);
	}
 }