/*
 * org.openmicroscopy.vis.chains.ome.CLayoutLink
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
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
 
 package org.openmicroscopy.vis.ome;

 
 /*
	* This is mostly a placeholder that will allow me to distinguish between
	* real nodes in a graph (CNode objects) and dummy nodes that will
	* be created to aid in drawing. 
	*/

 public class CLayoutLink {
	
	private CNode toNode;
	private CNode fromNode;
	
	// the actual graph link that this dummy link is really part of.
	private CLink semanticLink;
	
	public CLayoutLink() {
		super();
	}
	
	public CLayoutLink(CLink semanticLink,CNode fromNode,CNode toNode) {
		this.semanticLink = (CLink) semanticLink;
		this.fromNode = fromNode;
		this.toNode = toNode;
	}
	
	public CLayoutLink(CLink link) {
		this.fromNode = (CNode) link.getFromNode();
		this.toNode = (CNode) link.getToNode();
		this.semanticLink = (CLink) link;
	}
 	
 	public CLink getSemanticLink() {
 		return semanticLink;
 	}
 	
	public CNode getToNode() {
		return toNode;
	}
	
	public CNode getFromNode() {
		return fromNode;
	}
	
	// we want this to throw an exception if we're ever setting it
	// to anything that can't be cast to be a CNode.
	public void setToNode(CNode node) {
		toNode =  node;
	}
	
	public void setFromNode(CNode node) {
		fromNode = node;
	}
}

 
 