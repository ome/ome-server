/*
 * org.openmicroscopy.vis.piccolo.PChain
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

import edu.umd.cs.piccolo.PLayer;
import org.openmicroscopy.vis.ome.CNode; // was NodeInfo
import org.openmicroscopy.vis.ome.CModule;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.Chain;
import org.openmicroscopy.Chain.Link;
import org.openmicroscopy.Chain.Node;
import org.openmicroscopy.Module.FormalInput;
import org.openmicroscopy.Module.FormalOutput;
import java.util.HashMap;
import java.util.Collection;
import java.util.List;
import java.util.Iterator;
//import java.util.Vector;

public class PChain {


	private Chain chain;
	private HashMap nodes = new HashMap(); 
	private float chainHeight = 0;
	
	

	private static float HGAP=10f;
	
	private float x=HGAP;
	private float xInit;
	
	
	public PChain(Connection connection,Chain chain, PLayer layer,
			PLinkLayer linkLayer,float x,float y) {
		
		
		this.chain = chain;
		this.x = x;
		xInit = x;
		
		Collection chainNodes = chain.getNodes();
		Iterator iter = chainNodes.iterator();	
		while (iter.hasNext()) {
			//NodeInfo ni = (NodeInfo) iter.next();
			//drawNode(connection,ni.getNode(),layer,y);
			CNode node = (CNode) iter.next();
			drawNode(connection,node,layer,y);		
		}

		List links = chain.getLinks();
		iter = links.iterator();
		while (iter.hasNext()) {
			Link link = (Link) iter.next();
			drawLink(link,linkLayer);
		}
		// a parallel structure that will eventually replace the simple loop 
		//above
		//layerNodes();
		//addDummyNodes();
		//reduceCrossings();
		//placeNodesVertically();
	}
	
	private void drawNode(Connection connection,CNode node,PLayer layer,float y) {
		CModule mod = (CModule) node.getModule();

		PModule mNode = new PModule(connection,mod,x,y);
		mod.addModuleWidget(mNode);
		float w = (float) mNode.getBounds().getWidth();
		x += w+HGAP;
		layer.addChild(mNode);
		float nodeHeight = (float) mNode.getBounds().getHeight();
		if (nodeHeight > chainHeight)
			chainHeight = nodeHeight;
		nodes.put(node,mNode);
	}
	
	private void drawLink(Link link,PLinkLayer linkLayer) {
		Node from = link.getFromNode();
		Node to = link.getToNode();

		PModule fromPMod = (PModule) nodes.get(from);
		PModule toPMod = (PModule) nodes.get(to);
			
		if (fromPMod == null || toPMod ==null) 
				return;
			
		//	System.err.println("getting both ends of link");
		
		FormalInput input = link.getToInput();
		FormalOutput output = link.getFromOutput();
		/*	System.err.println("from module "+fromPMod.getModuleInfo().getModule().getName());
			System.err.println("to module " +toPMod.getModuleInfo().getModule().getName());
		
			System.err.println("input id is "+input.getID());
			System.err.println("output id is "+output.getID()); */
		
		PFormalInput inputPNode = toPMod.getFormalInputNode(input);
		PFormalOutput outputPNode = fromPMod.getFormalOutputNode(output);
		
		
		if (inputPNode != null && outputPNode != null) {
			PParamLink newLinkNode = new PParamLink(inputPNode,outputPNode);
			linkLayer.addChild(newLinkNode);
			linkLayer.completeLink(newLinkNode);
		} 	
	}
	
	public float getHeight() { 
		return chainHeight;
	}
	
	public float getWidth() {
		return x-xInit;
	}
	
	/** 
	 * some code for computing a layered graph layout of this chain.
	 * Builds on chapter 9  of Graph Drawing (di Battista, et al.),
	 * and on GNU code from the Matrix Algorithm Simulation tool
	 * 
	 * 	http://www.cs.hut.fi/Research/Matrix/	      	   	
	 */
	/*
	private Vector layers = new Vector();
	
	public void layerNodes() {
		Chain chain  = info.getChain();
		List nodes = chain.getNodes();
		int numAssigned = 0, currentLayer = 0;
		boolean ok;
		int nodeCount = nodes.size();
		
		do {
				Vector layer = new Vector();
				
				Iterator iter = nodes.iterator();
				while (iter.hasNext()) {
					
					Node node = (Node) iter.next();
					
					// how do I get the info for the node
					if (node.hasLayer())
						continue;
								
								
						// reversed edges included here (no dummy nodes exist yet)
						VisualLayeredGraphComponent succs[] = c.getPseudoSuccs();

						for (int j = 0; j < succs.length; j++) {
							// succ = succs[j];

							if (!succ.hasLayer() || succ.getLayer() == currentLayer) {
								// this is not ok.
								ok = false;
								break;
							}
						}
                
						if (ok == true) {
							// no unassigned successors, so assign this node to
							// the current layer
							// Note.out(this, "layer "+currentLayer+" has node "+c);
							layer.addElement(c);
							c.setLayer(currentLayer);
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
	} */
}

