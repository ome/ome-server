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

public class PChain {


	private CChain chain;
	private HashMap nodes = new HashMap(); 
	private float chainHeight = 0;
	private float layerWidth =0;
	

	private static float HGAP=10f;
	private static float VGAP=20f;
	
	private float x=HGAP;
	private float y = 0;
	private float top=0;
	private float xInit;
	
	
	private static float DUMMY_HEIGHT = 20f;
	private static float DUMMY_WIDTH = 20f;
	
	
	public PChain(Connection connection,CChain chain, PLayer layer,
			PLinkLayer linkLayer,float x,float y) {
		
		
		this.chain = chain;
		this.x = x;
		this.y =y;
		xInit = x;
		
		top =y;
		System.err.println("building chain for "+chain.getName());
		/*Collection chainNodes = chain.getNodes();
		Iterator iter = chainNodes.iterator();	
		while (iter.hasNext()) {
			//NodeInfo ni = (NodeInfo) iter.next();
			//drawNode(connection,ni.getNode(),layer,y);
			CNode node = (CNode) iter.next();
			drawNode(connection,node,layer,y);		
		} */
		
		drawNodes(connection,layer);
		drawLinks(linkLayer);
		
	}
	
	public void drawNodes(Connection connection,PLayer layer) {
		int layers = chain.getLayerCount();
		
		System.err.println("drawing layers.."+layers);
		for (int i=layers-1; i >=0; i--) {
			System.err.println("drawing layer "+i);
			drawLayer(connection,layer,i);
		}
	}
	
	public void drawLayer(Connection connection,PLayer layer,int layerNumber) {
		
		layerWidth = 0;
		int layerSize = chain.getLayerSize(layerNumber);
		y = top;
		
		for (int i =0; i < layerSize; i++) {
			System.err.println("..., node "+i);
			CNode node = chain.getLayerNode(layerNumber,i);
			//somehow draw it, and advance x as need be.
			drawNode(connection,node,layer);
		}
		x+=layerWidth+HGAP;
		float height = y-top;
		if (height > chainHeight) 
			chainHeight = height;
		
	}
	
	public void drawLinks(PLinkLayer linkLayer) {
		List links = chain.getLinks();
		Iterator iter = links.iterator();
		while (iter.hasNext()) {
			Link link = (Link) iter.next();
			drawLink(link,linkLayer);
		}
	}
	
	
	private void drawNode(Connection connection,CNode node,PLayer layer) {
		
		if (node instanceof CLayoutNode)  {
			drawLayoutNode();
		}
		System.err.println("drawing node "+node);
		CModule mod = (CModule) node.getModule();

		PModule mNode = new PModule(connection,mod,x,y);
		mod.addModuleWidget(mNode);
		float w = (float) mNode.getBounds().getWidth();
		if (w > layerWidth)
			layerWidth = w;
		layer.addChild(mNode);
		float nodeHeight = (float) mNode.getBounds().getHeight();
		y+= nodeHeight+VGAP;
		nodes.put(node,mNode);
	}
	
	private void drawLayoutNode() {
		if (layerWidth < DUMMY_WIDTH)
			layerWidth = DUMMY_WIDTH;
		y+=DUMMY_HEIGHT+VGAP;
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
	
	
}

