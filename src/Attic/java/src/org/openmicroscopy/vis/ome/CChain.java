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
import java.util.HashSet;
import java.util.Vector;
import java.util.Iterator;
import java.util.List;

 public class CChain extends RemoteChain {
	
	static {
		RemoteObjectCache.addClass("OME::AnalysisChain",CChain.class);
	}
	
	private static final int CROSSING_ITERATIONS=5;
	private static final double DELTA=0.1;
	private boolean orderChanged = false;
	private Layering layering  = new Layering();
	
	public CChain() {
		super();
	}
	
	public CChain(RemoteSession session,String reference) {
		super(session,reference);
	}
	
	
	public void layout() {
	//	System.err.println("Laying out..."+getName());
		initNodes();
	//	System.err.println("nodes initialized");
		layerNodes();
	//	System.err.println("nodes layered");
		makeProper();
	//	System.err.println("GRAPHS HAVE BEEN MADE PROPER");
		//dumpLayers();
		reduceCrossings();
		//System.err.println("CROSSINGS REDUCED");
		//dumpLayers(); 
	}
	
	
	// this is an ugly thing to have to do, but we have to - can't call
	// buildLinkLists in the constructor for each node...
	private void initNodes() {
		List nodes = getNodes();
		Iterator iter = nodes.iterator();
		while (iter.hasNext()) {
			CNode node = (CNode) iter.next();
	//		System.err.println("building link lists for "+node);
	//		System.err.println(" ..."+node.getModule().getName());
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

		CNode node  = null;

		CNode succ;
		
		do {
			Iterator iter = nodes.iterator();
			while (iter.hasNext()) {
				ok = true;
				node = (CNode) iter.next();
					
				if (node.hasLayer())
					continue;
				
				//System.err.println("finding successors for "+
				//		node.getModule().getName());	
				//System.err.println("...."+node);
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
					node.setLayer(currentLayer);
					layering.addToLayer(currentLayer,node);
					numAssigned++;
				}
			}
			currentLayer++;	
		} while (numAssigned < nodeCount);
	}
	
	
	// make the layout proper - insert additional nodes on paths 
	// that skip  levels .. ie., paths between levels l_i and l_j where j>i+1...
	private void makeProper() {
		int count = layering.getLayerCount();
		// for top (source) level and every level except for the last 2
		// (any outlinks from level 1 already go to only level 0, by
		// definition.
		for (int i = count-1; i>1; i--)
			makeProperLayer(i);
	}
	
	private void makeProperLayer(int i) {
		CNode node;
		//	System.err.println("working on layer "+i);
		try {
			Iterator iter = layering.layerIterator(i);
			while (iter.hasNext()) {
				node = (CNode) iter.next();
				makeProperNode(node,i);		
			}
		}
		catch (Exception e) { }
	}
	
	private void makeProperNode(CNode node,int i) {
		HashSet newLinks = new HashSet();
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
		HashSet newLinks) {
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
			
			CLink semanticLink = link.getSemanticLink();
			// make this node point to "to"
			CLayoutLink dummyOutLink = new CLayoutLink(semanticLink,dummy,to);
			dummy.addSuccLink(dummyOutLink);
			
			// make node point to new node
			CLayoutLink newOutLink = new CLayoutLink(semanticLink,node,dummy);
			
			dummy.addPredLink(newOutLink);
			
			// add new link to links.
			newLinks.add(newOutLink);
			
			// remove successor from node
			// don't need to do this, as we set the successors of this node
			// en masse 
			
			// adjust predecessors for to
			to.removePredLink(link);
			to.addPredLink(dummyOutLink);
			
			// add dummy to next layer.
			layering.addToLayer(i-1,dummy);
			
			// adjust the semantic link to put dummy in between "from" and "to".
			// invariant is that "from" is directly before "to", so just put it
			//after "from"
			semanticLink.addIntermediate(node,dummy);
		}
	}
	
	private void reduceCrossings() {
		// first entry in layers is bottom layer (1 or zero)
		
		assignPosFromLayer(0);
		int count=1;
		
		for (int i =0;  i < CROSSING_ITERATIONS; i++) {
			orderChanged = false;
			
			// reduce successor crossings
			/*while (iter.hasNext()) { 11/10/03 hsh
				Vector layer = (Vector) iter.next();
				crossingReduction(layer,false);
			}*/
			for (count = 1; count < layering.getLayerCount(); count++) {
				crossingReduction(count,false);
			}
			
			//for (int curLayer = layers.size()-2; curLayer >=0; curLayer--) {
			for (int curLayer = layering.getLayerCount()-2; 
				curLayer>=0;curLayer--) {
				//Vector layer  = (Vector) layers.elementAt(curLayer);
				//crossingReduction(layer,false); 11/10/03 hsh
				crossingReduction(curLayer,true);
			}
			//stop if no changes
			if (!orderChanged)
				break;
		}
	}
	
	private void crossingReduction(int layerNumber,boolean pred) {
		try {
			// Iterator iter = layer.iterator(); 11/10/03 hsh
		//	System.err.println("crossing reduction - layer "+layerNumber);
			Iterator iter = layering.layerIterator(layerNumber);
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
					baryCenter = calcBaryCenter(adjs);
				else
					baryCenter = 0.0;
				node.setPosInLayer(baryCenter); 
			}
			sortLayerByPos(layerNumber);
			assignPosFromLayer(layerNumber);
		}
		catch(Exception e) {
			System.err.println("exception caught!"); 
		}
	}
	
	private double calcBaryCenter(Collection adjs) {
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
	
	
	private void sortLayerByPos(int layerNumber) {
		try {
			int n = layering.getLayerSize(layerNumber);
		
			for (int i = 1; i < n; i++) {
				CNode node = layering.getNode(layerNumber,i);
				for (int j = i-1; j >=0; j--) {
					CNode prev = layering.getNode(layerNumber,j);
					
					if (prev.getPosInLayer() >= node.getPosInLayer()) {
						layering.setNode(layerNumber,j+1,prev);
						layering.setNode(layerNumber,j,node);
						orderChanged = true;
					}
				}
			}
		}
		catch(Exception e) {
		}
	}
	
	private void assignPosFromLayer(int layerNumber) {
		Iterator iter = layering.layerIterator(layerNumber);
		double pos = 0.0;
		
		try {
			//System.err.println("assigning position from layer "+layerNumber);
			while (iter.hasNext()) {
				CNode node = (CNode) iter.next();
				node.setPosInLayer(pos);
				pos +=1.0;
			}
		} 
		catch(Exception e) {
			System.err.println("exception!");
		}
	}
	
	public Layering getLayering() {
		return layering;
	}
	
	
	// stub code...
	private void dumpLayers() {
		System.err.println("Chain is "+getName());
		int count = layering.getLayerCount();
		for (int i =0; i < count; i++) {
			System.err.println("Layer "+i);
			Iterator iter = layering.layerIterator(i);
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
 

	public class Layering {
		// the vector that holds the abstract nodes
		private Vector layers = new Vector();
	
		// vector that holds the piccolo instatations of the nodes
		private Vector nodes = new Vector();
		// and a vector for their x positions
		private Vector xpositions = new Vector();
		
		Layering() {
		}
	
		private void addLayer(Vector layer) {
			layers.addElement(layer);		
		}
	
		public void addToLayer(int layerNumber,CNode node) {
			if (layerNumber > layers.size()-1) { // if we haven't created this layer yet
				for (int i = layers.size(); i <= layerNumber; i++) {
					Vector  v = new Vector();
					layers.add(v);
				}
			}
			Vector v = (Vector) layers.elementAt(layerNumber);
			v.add(node);
		}
	
		public int getLayerCount() {
			return layers.size();
		}

		private Vector getLayer(int i) {
			if (i < layers.size()) {
				Vector v = (Vector) layers.elementAt(i);
				return v;
			}
			else
				return null;
		}
	
		public Iterator layerIterator(int i) {
			return getLayer(i).iterator();
		}
	
		public int getLayerSize(int layerNumber) {
			return getLayer(layerNumber).size();
		}
	
		public CNode getNode(int layerNumber,int n) {
			Vector v = getLayer(layerNumber);
			CNode node = (CNode) v.elementAt(n);
			return node;
		}
	
		public void setNode(int layerNumber,int n,CNode node) {
			Vector v = getLayer(layerNumber);
			v.setElementAt(node,n);
		}
	} 
 }