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

/** 
 * <p>A subclass of {@link RemoteChain} that contains additional 
 * state needed for chain layout
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class CChain extends RemoteChain {
	
	static {
		RemoteObjectCache.addClass("OME::AnalysisChain",CChain.class);
	}
	
	private static final int CROSSING_ITERATIONS=5;
	private static final double DELTA=0.1;
	private boolean orderChanged = false;
	
	/** 
	 * A subsidiary object used to encapsulate information about the layering
	 */
	private Layering layering  = new Layering();
	
	public CChain() {
		super();
	}
	
	public CChain(RemoteSession session,String reference) {
		super(session,reference);
	}
	
	
	public void layout() {
		initNodes();
		layerNodes();
		makeProper();
		reduceCrossings();
	}
	
	
	/**
	 * Initalize each of the {@link CNode}s in the chain. This is an ugly 
	 * thing to have to do, but we have to - can't call
	 * buildLinkLists in the constructor for each node...
	 * 
	 */
	private void initNodes() {
		List nodes = getNodes();
		Iterator iter = nodes.iterator();
		while (iter.hasNext()) {
			CNode node = (CNode) iter.next();
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
	
	/**
	 * Assigns layers to each of the nodes by finding the longest path to each 
	 * node. Essentially goes through until it finds things that don't have any 
	 * successors that don't have layers, assigns them to the current layer, 
	 * continues until all nodes have been checked, and then moves onto the next
	 * layer
	 */
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
	
	
	/**
	 *  make the layout proper - insert additional nodes on paths 
	 *  that skip  levels .. ie., paths between levels l_i and l_j where j>i+1.
	 * 
	 */
	private void makeProper() {
		int count = layering.getLayerCount();
		// for top (source) level and every level except for the last 2
		// (any outlinks from level 1 already go to only level 0, by
		// definition.
		for (int i = count-1; i>1; i--)
			makeProperLayer(i);
	}
	
	/**
	 * Make a layer proper by examining each of the nodes in the layer
	 * @param i the layer to make proper
	 */
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
	
	/**
	 * Make a node in a layer proper, by making all of its links proper and 
	 * giving it a new set of successor links.
	 * 
	 * @param node the node to make proper
	 * @param i the layer for that node
	 * 
	 */
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
	
	/**
	 * Make a given link proper If the link does not got to the next layer,
	 * create a new dummy node. this node will be on level i-i and will go 
	 * between node and its original destination.
	 * Note that if the link between the dummy node and the original destination
	 * is not itself proper, this will be fixed when level i-1 is made proper,
	 * potentially by creating a nother dummy node.
	 * 
	 * @param node the origin of the link
	 * @param link the link to make proper
	 * @param i the layer of the original node
	 * @param newLinks the new successors of that node.
	 */
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
	
	/** 
	 * Reduce the crossings in the graph by iterating the layers, first
	 * going forwards and then backwards, repeating this up to 
	 * CROSSING_ITERATIONS times, and stopping if a given iteration does 
	 * not permute the nodes in the layer. 
	 *
	 */
	private void reduceCrossings() {
		
		// first entry in layers is bottom layer (1 or zero)
		
		assignPosFromLayer(0);
		int count=1;
		
		for (int i =0;  i < CROSSING_ITERATIONS; i++) {
			orderChanged = false;
			
			
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
	
	/**
	 * To reduce the crossings between two layers, uterate over the nodes in 
	 *  one layer. Calculate the barycenter of the nodes in the other layer,
	 * and assign the node the position equal to that barycenter.
	 * Then, sort the layer by position and assign positions to each node.
	 *  
	 * @param layerNumber the source layer to be adjusted
	 * @param pred true if layerNumber should be adjusted 
	 * 	relative to predecessors, false if successors should be used.
	 */
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
	
	/**
	 * The barycenter of the list of adjacent nodes is just the average of their
	 * positions
	 * @param adjs
	 * @return the barycenter of the adjacent nodes
	 */
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
	
	
	/**
	 * Sort the nodes in a layer, by position
	 * @param layerNumber the layer to be sorted.
	 */
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
	
	/**
	 * Assign positions to each node based on their position in the  sorted 
	 * 	ordering
	 * @param layerNumber the layer in question
	 */
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
	
	/**
	 * 
	 * @return the object containing the layering for the Chain
	 */
	public Layering getLayering() {
		return layering;
	}
	
	
	/**
	 * Debug code to print the layers.
	 *
	 */
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
 

	/**
	 * An auxiliary class to hold layering information
	 * 
	 * @author Harry Hochheiser
 	 * @version 2.1
 	 * @since OME2.1
 	 */
	public class Layering {
		/**
		 *  the vector that holds layers. Each layer will be a vector
		 */
		private Vector layers = new Vector();
	
		
		// and a vector for their x positions
		
		
		Layering() {
		}
	
		/**
		 * Add a new layer to the end of the layering
		 * @param layer the set of nodes in the new layer
		 */
		private void addLayer(Vector layer) {
			layers.addElement(layer);		
		}
	
		/**
		 * Add a node to a layer in the layering. If the layer
		 * doesn't exist, add it.
		 * 
		 * @param layerNumber the layer to which the node will be added.
		 * @param node the node to add
		 */
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
	
		/**
		 * 
		 * @return the number of layers
		 */
		public int getLayerCount() {
			return layers.size();
		}

		/** 
		 * 
		 * @param i a layer number
		 * @return layer number {@link i}, or null if that layer does not exist
		 */
		private Vector getLayer(int i) {
			if (i < layers.size()) {
				Vector v = (Vector) layers.elementAt(i);
				return v;
			}
			else
				return null;
		}
	
		/**
		 *
		 * @param i a layer number
		 * @return the iterator for that layer
		 */
		public Iterator layerIterator(int i) {
			return getLayer(i).iterator();
		}
	
		/**
		 * 
		 * @param layerNumber a layer number
		 * @return the number of nodes in layer {@link layerNumber}
		 */
		public int getLayerSize(int layerNumber) {
			return getLayer(layerNumber).size();
		}
	
		/**
		 * 
		 * @param layerNumber a layer number 
		 * @param n a node index
		 * @return the {@link n}th node from layer {@link layerNumber}
		 */
		public CNode getNode(int layerNumber,int n) {
			Vector v = getLayer(layerNumber);
			CNode node = (CNode) v.elementAt(n);
			return node;
		}
	
		/**
		 * Set the node in  a layer
		 * @param layerNumber the  layer number
		 * @param n position in the layer
		 * @param node node to place in thhe given layer
		 */
		public void setNode(int layerNumber,int n,CNode node) {
			Vector v = getLayer(layerNumber);
			v.setElementAt(node,n);
		}
	} 
 }