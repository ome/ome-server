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
import org.openmicroscopy.vis.ome.CChain.Layering;
import org.openmicroscopy.vis.ome.CLayoutNode;
import org.openmicroscopy.vis.ome.CLink;
import org.openmicroscopy.Module.FormalInput;
import org.openmicroscopy.Module.FormalOutput;
import java.util.List;
import java.util.Iterator;
import java.util.Vector;
import edu.umd.cs.piccolo.util.PBounds;

public class PChain {


	private CChain chain;
	private float chainHeight = 0;
	private int maxLayerSize = 0;
	private Layering layering;
	

	private static float HGAP=150f;
	private static float VGAP=50f;
	private static float CURVE_OFFSET=100f;
	private float layerWidth;
	
	private float x=HGAP;
	private float y = 0;
	private float top=0;
	private float xInit;
	
	
	private NodeLayers nodeLayers;
	
	public PChain(Connection connection,CChain chain, PLayer layer,
			PLinkLayer linkLayer,float x,float y) {
		
		
		this.chain = chain;
		this.layering = chain.getLayering();
		this.x = x;
		this.y =y;
		xInit = x;
		
		top =y;
		
		drawNodes(connection,layer);
		layoutNodes();
		drawLinks(linkLayer);	
	}
	
	public void drawNodes(Connection connection,PLayer layer) {
		
		int layers = layering.getLayerCount(); 
		nodeLayers = new NodeLayers(layers);
		
		for (int i=layers-1; i >=0; i--) {
			Vector v = drawLayer(connection,layer,i);
			// first element in nodelayers will be leftmost layer, etc.
			nodeLayers.addLayer(v);
			float height = getLayerHeight(v);
			if (height > chainHeight)
				chainHeight=height;
		}
	}
	
	public Vector drawLayer(Connection connection,PLayer layer,
						int layerNumber) {
		
		Vector v = new Vector();
		int layerSize=layering.getLayerSize(layerNumber);
		
		if (layerSize > maxLayerSize) 
			maxLayerSize = layerSize;
		
		for (int i =0; i < layerSize; i++) {
			//System.err.println("..., node "+i);
			CNode node = layering.getNode(layerNumber,i);
			//somehow draw it, and advance x as need be.
			Object obj = drawNode(connection,node,layer);
			v.add(obj);
		} 
		
		return v;
	}
	
	
	private Object drawNode(Connection connection,CNode node,PLayer layer) {
		
		PModule mNode = null;
		if (node instanceof CLayoutNode)  {
			mNode = new PLayoutModule();
		}
		else {
			CModule mod = (CModule) node.getModule();

			mNode = new PModule(connection,mod);
			mod.addModuleWidget(mNode);
			layer.addChild(mNode);
		}
		node.setPModule(mNode);
		return mNode;
	}
	
	private void layoutNodes() {
		int layerCount = layering.getLayerCount();
		for (int i = 0; i < layerCount; i++) {
			Vector v=  nodeLayers.getLayer(i);
			// set the x position for the current layer
			float origX = x;
			layerWidth = 0;
			layoutLayer(v);
			x += layerWidth+HGAP;
			float mid = (origX+x)/2;
			nodeLayers.setXPosition(i,mid);
		}
	}
	
	private void layoutLayer(Vector v) {
		int size = v.size();
		
		// iterate out to find height
		float height = getLayerHeight(v);
		float remainder = chainHeight - height;
		float delta = remainder/(size+1);
		Iterator iter = v.iterator();
		y = top+VGAP;
		while (iter.hasNext()) {
			y +=delta;
			
			PModule mod = (PModule) iter.next();
			mod.setOffset(x,y);
			y+= (float) mod.getHeight()+VGAP;
			if (mod.getBounds().getWidth() > layerWidth)
				layerWidth = (float) mod.getBounds().getWidth();
		}		
	}
	
	private float getLayerHeight(Vector v) {
		float total = 0;
		Iterator iter = v.iterator();
		PModule mod;
		while (iter.hasNext()) {
			mod = (PModule) iter.next();
			total += (float) mod.getHeight()+VGAP;
		}
		return total;
	}
	
	public void drawLinks(PLinkLayer linkLayer) {
		List links = chain.getLinks();
		Iterator iter = links.iterator();
		while (iter.hasNext()) {
			CLink link = (CLink) iter.next();
			drawLink(link,linkLayer);
		}
	}
	
	
	private void drawLink(CLink link,PLinkLayer linkLayer) {
		CNode from = (CNode) link.getFromNode();
		CNode to = (CNode) link.getToNode();

		PModule fromPMod = from.getPModule();
		PModule toPMod = to.getPModule();
			
		if (fromPMod == null || toPMod ==null) 
				return;
			
		
		
		FormalInput input = link.getToInput();
		FormalOutput output = link.getFromOutput();
		
		PBounds b = toPMod.getGlobalFullBounds();
		
		
		PFormalInput inputPNode = toPMod.getFormalInputNode(input);
		PFormalOutput outputPNode = fromPMod.getFormalOutputNode(output);
		
		
		if (inputPNode != null && outputPNode != null) {
			PParamLink newLinkNode = new PParamLink(inputPNode,outputPNode);
			linkLayer.addChild(newLinkNode);
			PModuleLink modLink = linkLayer.completeLink(newLinkNode);
			if (from.getLayer() > (to.getLayer()+1))
				adjustLink(link,from,to,newLinkNode,modLink);
		} 	
	}
	
	private void adjustLink(CLink clink,CNode from,CNode to,PParamLink link,
			PModuleLink modLink) {
		// remember, layer numbers go down as we get to leaves
		for (int i = from.getLayer()-1, j = 1; i > to.getLayer();i--,j++) {
			adjustLink(clink,from,to,link,modLink,i,j);
		}
	}
	
	// i is the position in the layering (n...0), whereas j is the 
	// index of the new point to be added.
	private void adjustLink(CLink clink,CNode from,CNode to,
			PParamLink link, PModuleLink modLink,int i, int j) {
		
		
		//find appropriate node
		CNode node = clink.getIntermediateNode(j);
		PModule mod = node.getPModule();
	
		float xpos = nodeLayers.getXPosition(i);
		
		// find y coordinate.
		float ypos = (float) mod.getY()+CURVE_OFFSET;
		// insert x,y into link somehow.
		link.insertIntermediatePoint(j,xpos,ypos);
		modLink.insertIntermediatePoint(j,xpos,ypos);
	}
	
	public float getHeight() { 
		return chainHeight;
	}
	
	public float getWidth() {
		return x-xInit;
	}
	
	class NodeLayers {
		private Vector nodeLayers;
		private Vector layerXPositions;
		
		public NodeLayers(int size) {
			nodeLayers = new Vector(size);
			layerXPositions = new Vector(size);
		}
		
		public void addLayer(Vector v) {
			nodeLayers.add(v);
		}
		
		public Vector getLayer(int i) {
			return (Vector) nodeLayers.elementAt(i);
		}
		
		public void setXPosition(int i,float mid) {
			layerXPositions.add(i,new Float(mid));
		}
		
		public float getXPosition(int i) {
			Float val = (Float) layerXPositions.elementAt(i);
			return val.floatValue();
		}
	}
}

