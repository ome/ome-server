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
import org.openmicroscopy.remote.RemoteObjectCache;
import org.openmicroscopy.remote.RemoteSession;
import org.openmicroscopy.vis.piccolo.PModule;
import java.util.Collection;
import java.util.HashSet;
import java.util.Iterator;
 
 
 public class CNode extends Node {
	
	static {
		RemoteObjectCache.addClass("OME::AnalysisChain::Node",CNode.class);
	}
	private int layer = -1;
	private double posInLayer = 0.0;
	
	protected HashSet succLinks = new HashSet();
	protected HashSet predLinks = new HashSet();
	protected HashSet succs  = new HashSet();
	protected HashSet preds = new HashSet();
	
	private PModule displayModule;
	
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
		//System.err.println("building lists for "+getModule().getName());
		buildSuccessors();
		//System.err.println("# of succs iis "+succLinks.size());
		buildPredecessors();
		//System.err.println("# of preds iis "+predLinks.size());
	}
	private void buildSuccessors() {
	
		Collection outputs = getOutputLinks();
		Iterator iter = outputs.iterator();
		while (iter.hasNext()) {
			CLink link = (CLink)iter.next();
			CNode node = (CNode) link.getToNode();
			if (!succs.contains(node)) {
				//	add a layout link?
				succs.add(node);
				CLayoutLink layoutLink = new CLayoutLink(link);
				succLinks.add(layoutLink);
				node.addPredLink(layoutLink);
			}
		}
	}
	
	public Collection getSuccessors() {
		return succs;
	}
	
	private void buildPredecessors() {
		Collection inputs = getInputLinks();
		Iterator iter = inputs.iterator();
		while (iter.hasNext()) {
			CLink link = (CLink) iter.next();
			CNode node = (CNode) link.getFromNode();
			if (!preds.contains(node)) {
				preds.add(node);
				CLayoutLink layoutLink = new CLayoutLink(link);
				predLinks.add(layoutLink);
				node.addSuccLink(layoutLink);
			}
		}
	}
	
	public  Collection getPredecessors() {
		return preds;
	}
	
	public void removeSuccLink(CLayoutLink link) {
		if (succLinks != null) {
			succLinks.remove(link);
			succs.remove(link.getToNode());
		}
	}
	
	public void addSuccLink(CLayoutLink link) {
		CNode node = (CNode) link.getToNode();
		if (!succs.contains(node)) {
			succLinks.add(link);
			succs.add(node);
		}
	}
	
	public Iterator succLinkIterator() {
		return succLinks.iterator();
	}
	
	
	
	public void setSuccLinks(HashSet links) {
		succLinks = links;
	}
	
	
	
	public void removePredLink(CLayoutLink link) {
		if (predLinks != null) {
			predLinks.remove(link);
			preds.remove(link.getFromNode());
		}
	}
	
	public void addPredLink(CLayoutLink link) {
		CNode node = (CNode) link.getFromNode();
		if (!preds.contains(node)) {
			predLinks.add(link);
			preds.add(node);
		}
	}
	
	public Iterator predLinkIterator() {
		return predLinks.iterator();
	}
	
	public void setPModule(PModule mod) {
		displayModule = mod;
	}
	
	public PModule getPModule() {
		return displayModule;
	}
 }
 