/*
 * org.openmicroscopy.vis.piccolo.PChainLibraryCanvas
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

import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.ChainInfo;
import org.openmicroscopy.vis.ome.Chains;
import org.openmicroscopy.vis.ome.Modules;
import org.openmicroscopy.vis.ome.ModuleInfo;
import org.openmicroscopy.Chain;
import org.openmicroscopy.Chain.Node;
import org.openmicroscopy.Chain.Link;
import org.openmicroscopy.Module;
import org.openmicroscopy.Module.FormalInput;
import org.openmicroscopy.Module.FormalOutput;
import java.util.Iterator;
import java.util.List;
import java.util.HashMap;


/** 
 * Extends PCanvas to provide functionality necessary for a piccolo canvas.<p> 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PChainLibraryCanvas extends PCanvas  {
	
	private static float VGAP=20f;
	private static float HGAP=10f;
	private Connection connection=null;
	private int modCount;
	private PLayer layer;
	
	private float x=HGAP;
	private float y=VGAP;
	
	private PLayer linkLayer;
	
	private float chainHeight= 0;
	private float chainWidth = 0;
	
	private Modules modules;
	
	private HashMap nodes;
	
	public PChainLibraryCanvas(Connection c) {
		super();
		this.connection  = c;
		layer = getLayer();
		linkLayer = new PLayer();
		getCamera().addLayer(linkLayer);
		linkLayer.moveToFront();
		populate();		
		
	}
	
	private void populate() {

	
		ChainInfo info;
		
		modules = connection.getModules();
		// get the chains.
		Chains chains = connection.getChains();
		
		Iterator iter = chains.iterator();
		
		// draw each of them.
		while (iter.hasNext()) {
			info = (ChainInfo) iter.next();
			drawChain(info);
		}
		
	}
	
	private void drawChain(ChainInfo info) {
		// draw the modules 
		chainHeight = 0;
		chainWidth = 0;
		Chain chain = info.getChain();
		nodes = new HashMap();
		
		PText name = new PText(chain.getName());
		layer.addChild(name);
		name.setOffset(x,y);
		chainHeight += name.getBounds().getHeight()+VGAP;
		y += VGAP+name.getBounds().getHeight();
		
		List nodes = chain.getNodes();
		Iterator iter = nodes.iterator();
		while (iter.hasNext()) {
			Node n = (Node) iter.next();
			drawNode(n);
		}
		
		List links = chain.getLinks();
		iter = links.iterator();
		while (iter.hasNext()) {
			Link link = (Link) iter.next();
			drawLink(link);
		}
		
 		y += chainHeight+VGAP;
		x= HGAP;
	}
	
	private void drawNode(Node node) {
		Module mod  = node.getModule();
		ModuleInfo modInfo = modules.getModuleInfo(mod);
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
	
	public void drawLink(Link link) {
		Node from = link.getFromNode();
		Node to = link.getToNode();
		
		PModule fromPMod = (PModule) nodes.get(from);
		PModule toPMod = (PModule) nodes.get(to);
		if (fromPMod == null || toPMod ==null) 
			return;
			
		System.err.println("getting both ends of link");
		
		FormalInput input = link.getToInput();
		FormalOutput output = link.getFromOutput();
		System.err.println("from module "+fromPMod.getModuleInfo().getModule().getName());
		System.err.println("to module " +toPMod.getModuleInfo().getModule().getName());
		
		System.err.println("input id is "+input.getID());
		System.err.println("output id is "+output.getID());
		
		PFormalInput inputPNode = toPMod.getFormalInputNode(input);
		PFormalOutput outputPNode = fromPMod.getFormalOutputNode(output);
		
		
		if (inputPNode != null && outputPNode != null) {
			PLink newLinkNode = new PLink(inputPNode,outputPNode);
			linkLayer.addChild(newLinkNode);
		}
		else
			System.err.println("failed to find input or output node for link"); 
	}
	
	public void scaleToSize() {
		getCamera().animateViewToCenterBounds(getBufferedBounds(),true,0);
	}
	
	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX(),b.getY(),b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER); 
	}
}