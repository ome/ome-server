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
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.ome.CLayoutNode;
import org.openmicroscopy.Chain.Link;
import org.openmicroscopy.Chain.Node;
import org.openmicroscopy.Module.FormalInput;
import org.openmicroscopy.Module.FormalOutput;
import java.util.HashMap;
import java.util.List;
import java.util.Iterator;
import java.util.Vector;
import edu.umd.cs.piccolo.util.PBounds;

public class PChain {


	private CChain chain;
	private HashMap nodes = new HashMap(); 
	private float chainHeight = 0;
	private int maxLayerSize = 0;
	

	private static float HGAP=50f;
	private static float VGAP=50f;
	private float layerWidth;
	
	private float x=HGAP;
	private float y = 0;
	private float top=0;
	private float xInit;
	
	
	private static float DUMMY_HEIGHT = 50f;
	private static float DUMMY_WIDTH = 50f;
	private Vector nodeLayers  = new Vector();
	
	Object dummy = new Object();
	
	public PChain(Connection connection,CChain chain, PLayer layer,
			PLinkLayer linkLayer,float x,float y) {
		
		
		this.chain = chain;
		this.x = x;
		this.y =y;
		xInit = x;
		
		top =y;
		System.err.println("building chain for "+chain.getName());
		
		drawNodes(connection,layer);
		layoutNodes();
		drawLinks(linkLayer);	
	}
	
	public void drawNodes(Connection connection,PLayer layer) {
		int layers = chain.getLayerCount();
		
		System.err.println("drawing layers.."+layers);
		for (int i=layers-1; i >=0; i--) {
			System.err.println("drawing layer "+i);
			Vector v = drawLayer(connection,layer,i);
			// first element in nodelayers will be leftmost layer, etc.
			nodeLayers.add(v);
			float height = getLayerHeight(v);
			if (height > chainHeight)
				chainHeight=height;
		}
	}
	
	public Vector drawLayer(Connection connection,PLayer layer,
						int layerNumber) {
		
		Vector v = new Vector();
		System.err.println("layer # "+layerNumber);
		int layerSize = chain.getLayerSize(layerNumber);
		if (layerSize > maxLayerSize) 
			maxLayerSize = layerSize;
		
		for (int i =0; i < layerSize; i++) {
			System.err.println("..., node "+i);
			CNode node = chain.getLayerNode(layerNumber,i);
			//somehow draw it, and advance x as need be.
			Object obj = drawNode(connection,node,layer);
			v.add(obj);
		} 
		
		return v;
	}
	
	
	private Object drawNode(Connection connection,CNode node,PLayer layer) {
		
		float height = 0;
		Object result;
		if (node instanceof CLayoutNode)  {
			height= DUMMY_HEIGHT+VGAP;
			result = dummy;
		}
		else {
			System.err.println("drawing node "+node);
			CModule mod = (CModule) node.getModule();
			System.err.println("module is "+mod.getName());

			PModule mNode = new PModule(connection,mod);
			mod.addModuleWidget(mNode);
			layer.addChild(mNode);
			float nodeHeight = (float) mNode.getBounds().getHeight();
			height= nodeHeight+VGAP;
			nodes.put(node,mNode);
			result = mNode;
		}
		return result;
	}
	
	private void layoutNodes() {
		int layerCount = nodeLayers.size();
		for (int i = 0; i < layerCount; i++) {
			System.err.println("laying out layer "+i);
			Vector v = (Vector) nodeLayers.get(i);
			layerWidth = 0;
			layoutLayer(v);
			x += layerWidth+HGAP;
		}
	}
	
	private void layoutLayer(Vector v) {
		int size = v.size();
		
		// iterate out to find height
		float height = getLayerHeight(v);
		System.err.println("layer height is "+height);
		
		System.err.println("chain height is "+chainHeight);
		float remainder = chainHeight - height;
		System.err.println(" blank space is " +remainder);
		float delta = remainder/(size+1);
		System.err.println("inter-item blank space is "+delta);
		Iterator iter = v.iterator();
		y = top+VGAP;
		System.err.println("top is "+y);
		while (iter.hasNext()) {
			y +=delta;
			System.err.println("putting object at "+y);
			Object obj = iter.next();
			if (obj instanceof PModule) {
				PModule mod = (PModule) obj;
				System.err.println("module "+mod.getModule().getName());
				mod.setOffset(x,y);
				y+= (float) mod.getBounds().getHeight()+VGAP;
				if (mod.getBounds().getWidth() > layerWidth)
					layerWidth = (float) mod.getBounds().getWidth();
			}		
			else {
				System.err.println(" dummy node");
				y+=DUMMY_HEIGHT+VGAP;
				if (layerWidth < DUMMY_WIDTH)
					layerWidth = DUMMY_WIDTH;
			}
		}		
	}
	
	private float getLayerHeight(Vector v) {
		float total = 0;
		Iterator iter = v.iterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PModule) {
				total += (float) ((PModule) obj).getBounds().getHeight(); 
			}
			else // dummy node
				total +=DUMMY_HEIGHT;
			total +=VGAP;
		}
		return total;
	}
	
	public void drawLinks(PLinkLayer linkLayer) {
		List links = chain.getLinks();
		Iterator iter = links.iterator();
		while (iter.hasNext()) {
			Link link = (Link) iter.next();
			drawLink(link,linkLayer);
		}
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
		System.err.println("from module "+fromPMod.getModule().getName());
		System.err.println("to module " +toPMod.getModule().getName());
		
		PBounds b = toPMod.getGlobalFullBounds();
		System.err.println(" to module is  at "+b.getX()+","+b.getY());
		System.err.println("  width="+b.getWidth()+","+b.getHeight());
		
		/*	System.err.println("input id is "+input.getID());
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
	
	
}

