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
import org.openmicroscopy.ChainExecution;
import org.openmicroscopy.vis.chains.SelectionState;
import java.util.Collection;
import java.util.HashSet;
import java.util.HashMap;
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
public class CChain extends RemoteChain  {
	
	static {
		RemoteObjectCache.addClass("OME::AnalysisChain",CChain.class);
	}
	
	private static final int CROSSING_ITERATIONS=2;
	private static final double DELTA=0.1;
	private boolean orderChanged = false;
	
	private List chainExecutions;
	private HashMap datasetExecutions = new HashMap();
	 
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
	
	
	public void loadExecutions(Connection connection) {
		chainExecutions = connection.getChainExecutions(this);
		Iterator iter = chainExecutions.iterator();
		ChainExecution exec;
		CDataset ds;
		Vector v;
		
		
		while (iter.hasNext()) {
			exec = (ChainExecution) iter.next();
			ds = (CDataset) exec.getDataset();
			Object obj = datasetExecutions.get(ds);
			if (obj == null)  // no list
				v = new Vector();
			else // already an existing list
				v = (Vector) obj;
			v.add(exec);
			datasetExecutions.put(ds,v);
		}
	}
	
	public Collection getExecutions(CDataset d) {
		Vector v = (Vector) datasetExecutions.get(d);
		return v;
	}
	public boolean hasAnyExecutions() {
		if (chainExecutions == null) 
			return false;
		else
			return (chainExecutions.size() >0);
	}
	
	
	public void layout() {
		initNodes();
		layerNodes();
		makeProper();
		reduceCrossings();
		cleanupNodes();
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
	 * Iterate over the nodes, cleaning up auxiliary structures that are needed
	 * for layout
	 *
	 */
	private void cleanupNodes() {
			List nodes = getNodes();
			Iterator iter = nodes.iterator();
			while (iter.hasNext()) {
				CNode node = (CNode) iter.next();
				node.cleanupLinkLists();
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
		GraphLayoutNode node;
		//System.err.println("working on layer "+i);
		try {
			Iterator iter = layering.layerIterator(i);
			while (iter.hasNext()) {
				node = (GraphLayoutNode) iter.next();
				makeProperNode(node,i);		
			}
		}
		catch (Exception e) { 
			System.err.println("exception in makeProperLayer..");
			e.printStackTrace();
		}
	}
	
	/**
	 * Make a node in a layer proper, by making all of its links proper and 
	 * giving it a new set of successor links.
	 * 
	 * @param node the node to make proper
	 * @param i the layer for that node
	 * 
	 */
	private void makeProperNode(GraphLayoutNode node,int i) {
		HashSet newLinks = new HashSet();
		Iterator iter = node.succLinkIterator();
		CLayoutLink link;
		
		//System.err.println("making node proper: "+node.getName());
		//System.err.println("doing links..."); 
		while (iter.hasNext()) {
			//System.err.println("LINK: ");
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
	private void makeProperLink(GraphLayoutNode node,CLayoutLink link,int i,
		HashSet newLinks) {
		// we know node is at i.
		
		GraphLayoutNode to = (GraphLayoutNode) link.getToNode();
		//System.err.println("..link to "+to.getName());
		int toLayer = to.getLayer();
		if (toLayer == (i-1)) {
			// layer is correct
			newLinks.add(link);
		}
		else {
			// create new dummy node
			DummyNode dummy = new DummyNode();
			//System.err.println("node is "+dummy);
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
			//System.err.println("adding a dummy node at layer"+(i-1));
			//System.err.println("node is "+dummy);
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
			GraphLayoutNode node;
			Collection adjs;
			double baryCenter=0.0;
		
			while (iter.hasNext()) {
				node = (GraphLayoutNode) iter.next();
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
			GraphLayoutNode c = (GraphLayoutNode) iter.next();
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
				GraphLayoutNode node = layering.getNode(layerNumber,i);
				for (int j = i-1; j >=0; j--) {
					GraphLayoutNode prev = layering.getNode(layerNumber,j);
					
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
				GraphLayoutNode node = (GraphLayoutNode) iter.next();
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
	 * Set the layering to be null, so it can be gc'ed..
	 *
	 */
	 public void clearLayering() {
	 	layering = null;
	 }
	
	
	/**
	 * Debug code to print the layers.
	 *
	 */
	private void dumpLayers() {
//		System.err.println("Chain is "+getName());
		int count = layering.getLayerCount();
		for (int i =0; i < count; i++) {
			dumpLayer(i);
		}
	}
	
	private void dumpLayer(int i) {
		System.err.println("Layer "+i);
		Iterator iter = layering.layerIterator(i);
		while (iter.hasNext()) {
			GraphLayoutNode node = (GraphLayoutNode) iter.next();
			if (node instanceof DummyNode)
				System.err.println("....Node:  dummy");
			else {
				CNode n = (CNode) node;
				CModule mod = (CModule) n.getModule();
				if (mod != null)
					System.err.println("....Node: "+mod.getName());
				else
					System.err.println("non dummy w/out a module");
			}
			System.err.println("... position in layer is "+
				node.getPosInLayer());
		} 
	}
	
	
	public boolean hasExecutionsInSelectedDatasets(
			SelectionState selectionState) {
		CDataset selected = selectionState.getSelectedDataset();
		Collection datasets = selectionState.getActiveDatasets();
		
		// if no active datasets and nothing selected,
		//it's got an execution that's active if it's got any executions.
		boolean noSelections = (datasets == null || datasets.size() ==0)
			 && selected == null;

		// if nothing is selected, I have no executions
		if (noSelections == true)
			return false;
			//return (datasetExecutions.size() > 0);
	
		
		// two possibilites: 
		// 1) selected is not null. Then I must have an entry for it.
		// 2) selected is null. Then, I must have an entry for some dataset
		// that is in datasets.
	
		Collection datasetsWithExecutions =  
			new HashSet(datasetExecutions.keySet());
		
		if (selected != null) {
			return datasetsWithExecutions.contains(selected);
		} else { // selected is null
			// retain only things in the executions set that are in my
			// active set
			datasetsWithExecutions.retainAll(datasets);
			// true if anything is left.
			return (datasetsWithExecutions.size() >0);
		}
	}
	
	
	
	public Collection getCurrentDatasetExecutions(
			SelectionState selectionState) {
		Collection active = selectionState.getActiveDatasets();
		CDataset selected = selectionState.getSelectedDataset();
		Vector v;
		CDataset d;
		CDataset current = selectionState.getSelectedDataset();
		
		
		if ((active == null ||active.size() ==0) && selected == null) 
			return chainExecutions;	
		
		// two possibilities:
		//1) if selected != null, get executions for selected.
		if (selected != null) {
			v = (Vector) datasetExecutions.get(selected);
		}
		else { // 2) get executions for all things in active
			Collection keySet = datasetExecutions.keySet();
			keySet.retainAll(active);
			// now keysets is the set of datasets in active with executions.
			Iterator iter = keySet.iterator();
			v = new Vector();
			while (iter.hasNext()) {
				d = (CDataset) iter.next();
				Vector execs = (Vector) datasetExecutions.get(d);
				v.addAll(execs);
			}	
		}
		 
		return v;
	}
	
	

	public Collection getDatasetsWithExecutions() {
		return datasetExecutions.keySet();
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
		public void addToLayer(int layerNumber,GraphLayoutNode node) {
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
		public GraphLayoutNode getNode(int layerNumber,int n) {
			Vector v = getLayer(layerNumber);
			GraphLayoutNode node = (GraphLayoutNode) v.elementAt(n);
			return node;
		}
	
		/**
		 * Set the node in  a layer
		 * @param layerNumber the  layer number
		 * @param n position in the layer
		 * @param node node to place in thhe given layer
		 */
		public void setNode(int layerNumber,int n,GraphLayoutNode node) {
			Vector v = getLayer(layerNumber);
			v.setElementAt(node,n);
		}
	}


 }