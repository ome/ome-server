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

import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.util.PBounds;
import org.openmicroscopy.vis.ome.CNode; // was NodeInfo
import org.openmicroscopy.vis.ome.CModule;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.vis.ome.CChain.Layering;
//import org.openmicroscopy.vis.ome.CLayoutNode;
import org.openmicroscopy.vis.ome.CLink;
import org.openmicroscopy.vis.ome.GraphLayoutNode;
import org.openmicroscopy.vis.ome.DummyNode;
import org.openmicroscopy.Module.FormalInput;
import org.openmicroscopy.Module.FormalOutput;
import java.util.List;
import java.util.Iterator;
import java.util.Vector;

/** 
 * A class for the rendering of a {@link CChain} from OME. Note that this 
 * is not a node in itself - it is simply a convenience class that holds 
 * the logic for rendering the components of a chain
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PChain extends PNode implements PBufferedObject {

	/**
	 * The Chain to be rendered
	 */
	private CChain chain;
	/*
	 * The Height of the chain
	 */
	private float chainHeight = 0;
	
	/** 
	 * The number of nodes in the layer with the most nodes.
	 */
	private int maxLayerSize = 0;
	
	/**
	 * The {@link Layering} describing the layout for this chain
	 */
	private Layering layering;
	
	/**
	 * Horizontal and verical gaps between layers and nodes (respectively)
	 */
	private static float HGAP=150f;
	private static float VGAP=100f;
	
	/**
	 * A vertical offset of curve components, chosen to improve aesthetics
	 */
	private static float CURVE_OFFSET=100f;
	
	/** 
	 * The width of the current layer
	 */ 
	private float layerWidth;
	
	/**
	 * Some parameters of the stateo f the display
	 */
	private float x=0;  /// was HGAP
	private float y = 0;
	private float top=0;
	private float xInit;
	
	/**
	 *A record of which nodes are in which layers
	 */
	private NodeLayers nodeLayers;
	
	private PBounds chainBounds= new PBounds();
	/**
	 * 
	 * @param connection the database connection
	 * @param chain		the chain to be drawn
	 * @param pickable  can the links be picked?
	 */
	public PChain(Connection connection,CChain chain,boolean pickable) {
		
		
		this.chain = chain;
		this.layering = chain.getLayering();
		//this.x = x;
		//this.y =y;
	//	xInit = x;
		
	//	top =y;
		
		PLinkLayer linkLayer = new PLinkLayer();
		linkLayer.setPickable(pickable);
		addChild(linkLayer);
		
		drawNodes(connection);
		layoutNodes();
		drawLinks(linkLayer);	
		//clear it out so it can be garbage-collected
		nodeLayers = null;
		linkLayer.moveToFront();
		
	}
		
	public PBounds getBufferedBounds() {
		PBounds b = getGlobalFullBounds();
		return new PBounds(b.getX()-PConstants.BORDER,
			b.getY()-PConstants.BORDER,
			b.getWidth()+2*PConstants.BORDER,
			b.getHeight()+2*PConstants.BORDER);
	}
	
	
	/**
	 * To draw the nodes, start at the highest numbered layer and continue 
	 * until we hit layer zero. Keep track of the height of thhe tallest layer
	 * The nodes in each layer will go into the {@link NodeLayers} object,
	 * which will contain the highest # layer first, etc.
	 * @param connection
	 */
	private void drawNodes(Connection connection) {
		
		int layers = layering.getLayerCount(); 
		nodeLayers = new NodeLayers(layers);
		
		for (int i=layers-1; i >=0; i--) {
			Vector v = drawLayer(connection,i);
			nodeLayers.addLayer(v,i);
			float height = getLayerHeight(v);
			if (height > chainHeight)
				chainHeight=height;
		}
	}
	
	/**
	 * To draw a layer, draw each of the nodes 
	 * @param connection
	 * @param layerNumber
	 * @return a list containing the nodes in the layer
	 */
	private Vector drawLayer(Connection connection,int layerNumber) {
		
		Vector v = new Vector();
		int layerSize=layering.getLayerSize(layerNumber);
		
		if (layerSize > maxLayerSize) 
			maxLayerSize = layerSize;
		
		for (int i =0; i < layerSize; i++) {
			GraphLayoutNode node = layering.getNode(layerNumber,i);
			//somehow draw it, and advance x as need be.
			Object obj = drawNode(connection,node);
			v.add(obj);
		} 
		
		return v;
	}
	
	/**
	 * Draw a node. If the node is a dummy layout node (instance of {@link
	 * CLayoutNode}, make it a {@link PLayoutModule}, but don't add it to
	 * the scenegraph. Otherwise, create a {@link PModule}, and add it. In 
	 * any case, return it so it gets included in the list of nodes for the 
	 * layer
	 * 
	 * @param connection
	 * @param node
	 * @param layer
	 * @return
	 */
	private Object drawNode(Connection connection,GraphLayoutNode node) {
		
		PModule mNode = null;
		if (node instanceof DummyNode)  {
			mNode = new PLayoutModule();
		}
		else { // must be a real cnode
			CModule mod = (CModule) ((CNode) node).getModule();

			mNode = new PModule(connection,mod);
			mod.addModuleWidget(mNode);
			addChild(mNode);
		}
		node.setPModule(mNode);
		return mNode;
	}
	
	/**
	 * To layout the nodes, start with the nodes in the first layer.
	 * Lay them out at the appropriate horizonal coordinate, move to the right
	 * by the width of the layer, and continue. Note the horizontal mid-point
	 * of each layer.
	 *
	 */
	private void layoutNodes() {
		int layerCount = layering.getLayerCount();
		for (int i = layerCount-1; i >= 0; i--) {
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
	
	/**
	 * To layout a layer, find the difference between the height of the layer
	 * and the height of the tallest layer. Lay the nodes in the layer out in 
	 * a manner that divides that difference into spaces betwen the nodes. 
	 * 
	 * Track the width of the widest module in the layer. This is where 
	 * it's useful to have {@link PLayoutModule} as a subclass of {@link
	 * PModule} - no special case-handling is required here.
	 * 
	 * @param v
	 */
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
			adjustVerticalExtents(mod.getGlobalFullBounds());
			y+= (float) mod.getHeight()+VGAP;
			if (mod.getBounds().getWidth() > layerWidth)
				layerWidth = (float) mod.getBounds().getWidth();
		}		
	}
	
	/**
	 * The height of a layer is just the sum of all of the modules in that
	 * layer, plus some spacing between each.
	 * @param v a layer
	 * @return the height of the layer
	 */
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
	
	/**
	 * Draw the links in the chain 
	 * 
	 * @param linkLayer the {@link PLayer} to add the links to
	 */
	public void drawLinks(PLinkLayer linkLayer) {
		List links = chain.getLinks();
		Iterator iter = links.iterator();
		while (iter.hasNext()) {
			CLink link = (CLink) iter.next();
			drawLink(link,linkLayer);
		}
	}
	
	
	/**
	 * To draw a link, we find the {@link CNode}s for the endpoints, 
	 * the {@llink PModule} for those nodes, and then the correspponding
	 * {@link PFormalParameter} instances.
	 * 
	 * We then create instances of {@link PParmLink} as needed, create the 
	 * module link between the two layers, and then adjust
	 * links that connect nodes in non-adjacent layers.
	 *  
	 * @param link the link to draw
	 * @param linkLayer the parent node
	 */
	private void drawLink(CLink link,PLinkLayer linkLayer) {
		CNode from = (CNode) link.getFromNode();
		CNode to = (CNode) link.getToNode();

		PModule fromPMod = from.getPModule();
		PModule toPMod = to.getPModule();
			
		if (fromPMod == null || toPMod ==null) 
				return;
			
		FormalInput input = link.getToInput();
		FormalOutput output = link.getFromOutput();
		
		
		PFormalInput inputPNode = toPMod.getFormalInputNode(input);
		PFormalOutput outputPNode = fromPMod.getFormalOutputNode(output);
		
		
		if (inputPNode != null && outputPNode != null) {
			PParamLink newLinkNode = new PParamLink(inputPNode,outputPNode);
			linkLayer.addChild(newLinkNode);
			// create the module link between the two modules
			PModuleLink modLink = linkLayer.completeLink(newLinkNode);
			if (from.getLayer() > (to.getLayer()+1))
				adjustLink(link,from,to,newLinkNode,modLink);
			adjustVerticalExtents(newLinkNode.getGlobalFullBounds());
			adjustVerticalExtents(modLink.getGlobalFullBounds());
		} 	
	}
	
	/**
	 * To adjust a link, add points for every layer between the layer of the 
	 * source and the layer of the destination. Thus, if the source is in layer 
	 * n, and the destination is in p, we adjust the link at n-1, n-2..p+1
	 * @param clink
	 * @param from
	 * @param to
	 * @param link
	 * @param modLink
	 */
	private void adjustLink(CLink clink,CNode from,CNode to,PParamLink link,
			PModuleLink modLink) {
		// remember, layer numbers go down as we get to leaves
		// j is the index of where in the PLink the new point is added.
		// the first new point goes at j=1, then j=2, etc
	
		for (int i = from.getLayer()-1, j = 1; i > to.getLayer();i--,j++) {
			adjustLink(clink,from,to,link,modLink,i,j);
		}
	}
	
	/**  
	 * Adjust a specific point on the links
	 * @param clink
	 * @param from
	 * @param to
	 * @param link
	 * @param modLink
	 * @param i i is the position in the layering (n...0)
	 * @param j index of the new point to be added. (1 for the first point,
	 * 	then 2, etc.
	 */
	private void adjustLink(CLink clink,CNode from,CNode to,
			PParamLink link, PModuleLink modLink,int i, int j) {
		
		
		//find appropriate node
		//System.err.println("...adjusting link at position "+j);
		GraphLayoutNode node = clink.getIntermediateNode(j);
		PModule mod = node.getPModule();
	
		float xpos = nodeLayers.getXPosition(i);//?
		
		// find y coordinate.
		float ypos = (float) mod.getY()+CURVE_OFFSET;
		// insert x,y into link somehow.
		link.insertIntermediatePoint(j,xpos,ypos);
		modLink.insertIntermediatePoint(j,xpos,ypos);
	}
	
	public double getHeight() { 
		//return chainHeight;
		return (float) chainBounds.getHeight()+VGAP;
	}
	
	public void adjustVerticalExtents(PBounds b) {
		chainBounds.add(b);
	}
	
	public double getWidth() {
		return x;
	}
	
	/**
	 * A convenience class that tracks the nodes in each layer,
	 * and the x position of each layer
	 * @author Harry Hochheiser
	 * @version 2.1
	 * @since 	OME2.1
	 */
	class NodeLayers {
		private Vector[] nodeLayers;
		private float[] layerXPositions;
		
		public NodeLayers(int size) {
			nodeLayers = new Vector[size];
			layerXPositions = new float[size];
		}
		
		public void addLayer(Vector v,int i) {
			nodeLayers[i]=v;
		}
		
		public Vector getLayer(int i) {
			return nodeLayers[i];
		}
		
		public void setXPosition(int i,float mid) {
			layerXPositions[i]=mid;
		}
		
		public float getXPosition(int i) {
			return layerXPositions[i];
		}
	}
}

