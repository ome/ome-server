/*
 * org.openmicroscopy.vis.chains.ome.CNode
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
 
 package org.openmicroscopy.vis.ome;
 
 import org.openmicroscopy.remote.RemoteChain.Node;
 import org.openmicroscopy.remote.RemoteChain.Link;
 import org.openmicroscopy.remote.RemoteObjectCache;
 import org.openmicroscopy.remote.RemoteSession;
 import java.util.List;
 import java.util.Vector;
 import java.util.Iterator;
 import java.util.HashSet;
 
 public class CNode extends Node {
	
	private Vector succs = null;
	protected HashSet layoutLinks = new HashSet();
	static {
		RemoteObjectCache.addClass("OME::AnalysisChain::Node",CNode.class);
	}
	private int layer = -1;
	
 	public CNode() {
 		super(); 
 	}
 	
 	public CNode(RemoteSession session,String reference) {
 		super(session,reference);
 	
 	}
 	
	public void setLayer(int layer) {
		this.layer = layer;
	}
	
	public int getLayer() {
		return layer;
	}
	
	public boolean hasLayer() {
		return (!(layer == -1));
	} 
	
	private void buildSuccessors() {
	
		succs = new Vector();
		List outputs = getOutputLinks();
		Iterator iter = outputs.iterator();
		
		while (iter.hasNext()) {
			Link link = (Link)iter.next();
			CNode node = (CNode) link.getToNode();
			succs.add(node);
			//	add a layout link?
			buildLayoutLink(link);
		}
	}
	
	public List getSuccessors() {
		if (succs == null)
			buildSuccessors();
		return succs;
	}
	
	public void removeLayoutLink(Link link) {
		if (layoutLinks != null)
			layoutLinks.remove(link);
	}
	
	public void addLayoutLink(Link link) {
		layoutLinks.add(link);
	}
	
	public Iterator layoutLinkIterator() {
		return layoutLinks.iterator();
	}
	
	private void buildLayoutLink(Link link) {
		CNode from = (CNode) link.getFromNode();
		CNode to = (CNode) link.getToNode();
		CLayoutLink layoutLink = new CLayoutLink(from,to);
		layoutLinks.add(layoutLink);
	}
	
	public void setLayoutLinks(Vector links) {
		layoutLinks = new HashSet(links);
	}
 }
 