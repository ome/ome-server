/*
 * org.openmicroscopy.vis.chains.ome.CChain
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

import org.openmicroscopy.remote.RemoteObjectCache;
import org.openmicroscopy.remote.RemoteChain;
import org.openmicroscopy.remote.RemoteSession;
import java.util.Collection;
import java.util.Vector;
import java.util.Iterator;
import java.util.List;

 public class CChain extends RemoteChain {
	
	static {
		RemoteObjectCache.addClass("OME::AnalysisChain",CChain.class);
	}
	
	private static final int CROSSING_ITERATIONS=5;
	private static final double DELTA=0.1;
	private Vector layers = new Vector();
	private boolean orderChanged = false;
	
	
	public CChain() {
		super();
	}
	
	public CChain(RemoteSession session,String reference) {
		super(session,reference);
	}
	
	
	public void layout() {
		System.err.println("Laying out..."+getName());
		initNodes();
		System.err.println("nodes initialized");
		layerNodes();
		System.err.println("nodes layered");
		dumpLayers();
		makeProper();
		System.err.println("GRAPHS HAVE BEEN MADE PROPER");
		dumpLayers();
		reduceCrossings();
		System.err.println("CROSSINGS REDUCED");
		dumpLayers(); 
	}
	
	
	// this is an ugly thing to have to do, but we have to - can't call
	// buildLinkLists in the constructor for each node...
	private void initNodes() {
		List nodes = getNodes();
		Iterator iter = nodes.iterator();
		while (iter.hasNext()) {
			CNode node = (CNode) iter.next();
			System.err.println("building link lists for "+node);
			System.err.println(" ..."+node.getModule().getName());
			node.buildLinkLists();
		}
	}
	/** 
	* some code for computing a layered graph layout of this chain.
	* Builds on chapter 9  of Graph Drawing (di Battista, et al.),
	* and on GNU code from the Matrix Algorithm Simulation tool
	* 
	* 	http://www.cs.hut.fi/Research/Matrix/	      	   	
	*/
	
	//layers is a vector of vectors. The first entry (@ index 0) is level 0,
	//etc. Level 0 is the base - the sinks. Level(size-1) is the top level -
	// the sources
	private void layerNodes() {
		List nodes = getNodes();
		int numAssigned = 0, currentLayer = 0;
		boolean ok= true;
		int nodeCount = nodes.size();

		CNode node;
		CNode succ;
		
		do {
			Vector layer = new Vector();
			Iterator iter = nodes.iterator();
			while (iter.hasNext()) {
				ok = true;
				node = (CNode) iter.next();
					
				if (node.hasLayer())
					continue;
				
				System.err.println("finding successors for "+
					node.getModule().getName());	
				System.err.println("...."+node);
				Collection succs = node.getSuccessors();	
						
					
				Iterator succIter = succs.iterator();	
				while (succIter.hasNext()) {
					succ = (CNode) succIter.next();

					if (!succ.hasLayer() || succ.getLayer() == currentLayer) {
						// this is not ok.
						ok = false;
						break;
					}
				}
                
				if (ok == true) {
					//no unassigned successors, so assign this node to
					// the current layer
					layer.addElement(node);
					node.setLayer(currentLayer);
					numAssigned++;
				}
			}
			
			if (layer.isEmpty()) {
				System.err.println("Cycle removal failed?");
			} else {
				// Switch to next (upper) layer
				currentLayer++;
				layers.addElement(layer);
			}
		} while (numAssigned < nodeCount);
	}
	
	
	// make the layout proper - insert additional nodes on paths 
	// that skip  levels .. ie., paths between levels l_i and l_j where j>i+1...
	private void makeProper() {
		int count = layers.size();
		// for top (source) level and every level except for the last 2
		// (any outlinks from level 1 already go to only level 0, by
		// definition.
		System.err.println("# of layers is "+count);
		for (int i = count-1; i>1; i--)
			makeProperLayer(i);
	}
	
	private void makeProperLayer(int i) {
		CNode node;
		System.err.println("working on layer "+i);
		Vector layer = (Vector) layers.get(i);
		Iterator iter = layer.iterator();
		while (iter.hasNext()) {
			node = (CNode) iter.next();
			makeProperNode(node,i);		
		}
	}
	
	private void makeProperNode(CNode node,int i) {
		Vector newLinks = new Vector();
		Iterator iter = node.succLinkIterator();
		CLayoutLink link;
		
		/* if (!(node instanceof CLayoutNode))
			System.err.println("making node proper: "+node.getModule().getName());
		else	
			System.err.println("making dummy node proper"); */
		while (iter.hasNext()) {
			link = (CLayoutLink) iter.next();
			makeProperLink(node,link,i,newLinks);
		}
		node.setSuccLinks(newLinks);
	}
	
	private void makeProperLink(CNode node,CLayoutLink link,int i,
		Vector newLinks) {
		// we know node is at i.
		
		CNode to = (CNode) link.getToNode();
		/*if (!(to instanceof CLayoutNode))
			System.err.println("..link to "+to.getModule().getName());
		else 
			System.err.println("... link to dummy node"); */
		int toLayer = to.getLayer();
		if (toLayer == (i-1)) {
			// layer is correct
			newLinks.add(link);
		}
		else {
			// create new node.
			CLayoutNode dummy = new CLayoutNode();
			// make this node point to "to"
			CLayoutLink dummyOutLink = new CLayoutLink(dummy,to);
			dummy.addSuccLink(dummyOutLink);
			
			// make node point to new node
			CLayoutLink newOutLink = new CLayoutLink(node,dummy);
			
			// add new link to links.
			newLinks.add(newOutLink);
			
			// remove successor from node
			// don't need to do this, as we set the successors of this node
			// en masse 
			
			// adjust predecessors for to
			to.removePredLink(link);
			to.addPredLink(dummyOutLink);
			
			// add dummy to next layer.
			Vector nextLayer = (Vector)layers.get(i-1);
			nextLayer.add(dummy);			
		}
	}
	
	private void reduceCrossings() {
		Iterator iter = layers.iterator();
		
		if (!iter.hasNext())
			return; // no layers
			
		// first entry in layers is bottom layer (1 or zero)
		assignPosFromLayer((Vector) iter.next());
		
		for (int i =0;  i < CROSSING_ITERATIONS; i++) {
			orderChanged = false;
			
			// reduce successor crossings
			while (iter.hasNext()) {
				Vector layer = (Vector) iter.next();
				crossingReduction(layer,false);
			}
			
			for (int curLayer = layers.size()-2; curLayer >=0; curLayer--) {
				Vector layer  = (Vector) layers.elementAt(curLayer);
				crossingReduction(layer,false);
			}
			//stop if no changes
			if (!orderChanged)
				break;
		}
	}
	
	private void crossingReduction(Vector layer,boolean pred) {
		Iterator iter = layer.iterator();
		CNode node;
		Collection adjs;
		double baryCenter=0.0;
		
		while (iter.hasNext()) {
			node = (CNode) iter.next();
			if (pred == true)
				adjs = node.getPredecessors();
			else
				adjs = node.getSuccessors();
			if (adjs.size()>0)
				baryCenter = calcBaryCenter(layer,adjs);
			else
				baryCenter = 0.0;
			node.setPosInLayer(baryCenter); 
		}
		sortLayerByPos(layer);
		assignPosFromLayer(layer);
	}
	
	private double calcBaryCenter(Vector layer,Collection adjs) {
		double center=0.0;
		int deg = adjs.size();
		int total =0;
		Iterator iter = adjs.iterator();
		while (iter.hasNext()) {
			CNode c = (CNode) iter.next();
			total += c.getPosInLayer(); 
		}
		center = total/deg;
		return center;
	}
	
	
	private void sortLayerByPos(Vector layer) {
		int n = layer.size();
		for (int i = 1; i < n; i++) {
			CNode node = (CNode) layer.elementAt(i);
			for (int j = i-1; j >=0; j--) {
				CNode prev = (CNode) layer.elementAt(j);
				if (prev.getPosInLayer() >= node.getPosInLayer()) {
					layer.setElementAt(prev,j+1);
					layer.setElementAt(node,j);
					orderChanged = true;
				}
			}
		}
	}
	
	private void assignPosFromLayer(Vector layer) {
		Iterator iter = layer.iterator();
		double pos = 0.0;
		
		while (iter.hasNext()) {
			CNode node = (CNode) iter.next();
			node.setPosInLayer(pos);
			pos +=1.0;
		}
	}
	
	public int getLayerCount() {
		return layers.size();
	}
	
	private Vector getLayer(int i) {
		if (i < layers.size())
			return (Vector) layers.elementAt(i);
		else
			return (Vector) null;
	}

	public int getLayerSize(int i) {
		Vector v = getLayer(i);
		if (v != null) {
			return v.size();
		}
		else 
			return -1;
	}
	
	public CNode getLayerNode(int i, int j) {
		CNode node = null;
		Vector v = getLayer(i);
		if (v != null) {
			node = (CNode) v.elementAt(j);
		}
		return node;
	}
	
	// stub code...
	private void dumpLayers() {
		System.err.println("Chain is "+getName());
		int count = layers.size();
		for (int i =0; i < count; i++) {
			System.err.println("Layer "+i);
			Vector layer = (Vector) layers.get(i);
			Iterator iter = layer.iterator();
			while (iter.hasNext()) {
				CNode node = (CNode) iter.next();
				if (node instanceof CLayoutNode)
					System.err.println("....Node:  dummy");
				else {
					CModule mod = (CModule) node.getModule();
					if (mod != null)
						System.err.println("....Node: "+mod.getName());
					else
						System.err.println("non dummy w/out a module");
				}
				System.err.println("... position in layer is "+
					node.getPosInLayer());
			} 
		}
	}
}