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
import org.openmicroscopy.vis.ome.ChainInfo;
import org.openmicroscopy.vis.ome.NodeInfo;
import org.openmicroscopy.vis.ome.ModuleInfo;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.Chain;
import org.openmicroscopy.Chain.Link;
import org.openmicroscopy.Chain.Node;
import org.openmicroscopy.Module;
import org.openmicroscopy.Module.FormalInput;
import org.openmicroscopy.Module.FormalOutput;
import java.util.HashMap;
import java.util.Collection;
import java.util.List;
import java.util.Iterator;

public class PChain {

	private ChainInfo info;
	private Chain chain;
	private HashMap nodes = new HashMap(); 
	private float chainHeight = 0;
	
	

	private static float HGAP=10f;
	
	private float x=HGAP;
	
	
	public PChain(Connection connection,ChainInfo info, PLayer layer,
			PLinkLayer linkLayer,float y) {
		
		this.info = info;
		chain = info.getChain();
		
		Collection chainNodes = info.getNodes();
		Iterator iter = chainNodes.iterator();	
		while (iter.hasNext()) {
			NodeInfo ni = (NodeInfo) iter.next();
			drawNode(connection,ni.getNode(),layer,y);		
		}

		List links = chain.getLinks();
		iter = links.iterator();
		while (iter.hasNext()) {
			Link link = (Link) iter.next();
			drawLink(link,linkLayer);
		}
	}
	
	private void drawNode(Connection connection,Node node,PLayer layer,float y) {
		Module mod = node.getModule();
		ModuleInfo modInfo = connection.getModules().getModuleInfo(mod);
		PModule mNode = new PModule(connection,modInfo,x,y);
		modInfo.addModuleWidget(mNode);
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
		return x;
	}
}

