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

 import java.util.Collection;
 import java.util.Vector;
 import java.util.HashSet;
 import java.util.Iterator;

 
 public class CNode extends Node {
	
	static {
		RemoteObjectCache.addClass("OME::AnalysisChain::Node",CNode.class);
	}
	private int layer = -1;
	private double posInLayer = 0.0;
	
	protected Vector succLinks = new Vector();
	protected Vector predLinks = new Vector();
	
 	public CNode() {
 		super(); 
 	}
 	
 	public CNode(RemoteSession session,String reference) {
 		super(session,reference);
 		//buildLinkLists();
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
	
	public void setPosInLayer(double p) {
		posInLayer = p;
	}
	
	public double getPosInLayer() {
		return posInLayer;
	}
	
	// we can't call "buildsuccessors" in the constructor. Doesn't work.
	// so, have a separate call
	
	public void buildLinkLists() {
		buildSuccessors();
		buildPredecessors();
	}
	private void buildSuccessors() {
	
		Collection outputs = getOutputLinks();
		Iterator iter = outputs.iterator();
		
		while (iter.hasNext()) {
			Link link = (Link)iter.next();
			CNode node = (CNode) link.getToNode();
			//	add a layout link?
			CLayoutLink layoutLink = new CLayoutLink(link);
			succLinks.add(layoutLink);
		}
	}
	
	public Collection getSuccessors() {
		HashSet succs = new HashSet();
		Iterator iter = succLinks.iterator();
		while (iter.hasNext()) {
			CLayoutLink link = (CLayoutLink) iter.next();
			CNode node = (CNode) link.getToNode();
			succs.add(node);
		}
		return succs;
	}
	
	private void buildPredecessors() {
		Collection inputs = getInputLinks();
		Iterator iter = inputs.iterator();
		while (iter.hasNext()) {
			Link link = (Link) iter.next();
			CLayoutLink layoutLink = new CLayoutLink(link);
			predLinks.add(layoutLink);
		
		}
	}
	
	public  Collection getPredecessors() {
		HashSet preds = new HashSet();
		Iterator iter = predLinks.iterator();
		while (iter.hasNext()) {
			CLayoutLink link = (CLayoutLink) iter.next();
			CNode node = (CNode) link.getToNode();
			preds.add(node);
		}
		return preds;
	}
	
	public void removeSuccLink(CLayoutLink link) {
		if (succLinks != null) {
			succLinks.remove(link);
		}
	}
	
	public void addSuccLink(CLayoutLink link) {
		succLinks.add(link);
	}
	
	public Iterator succLinkIterator() {
		return succLinks.iterator();
	}
	
	
	
	public void setSuccLinks(Vector links) {
		succLinks = links;
	}
	
	
	
	public void removePredLink(CLayoutLink link) {
		if (predLinks != null) {
			predLinks.remove(link);
		}
	}
	
	public void addPredLink(CLayoutLink link) {
		predLinks.add(link);
	}
	
	public Iterator predLinkIterator() {
		return predLinks.iterator();
	}
 }
 