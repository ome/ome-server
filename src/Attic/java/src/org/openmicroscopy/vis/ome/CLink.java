/*
 * org.openmicroscopy.vis.chains.ome.CLink
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
import org.openmicroscopy.remote.RemoteChain.Link;
import org.openmicroscopy.remote.RemoteSession;
import org.openmicroscopy.remote.RemoteObjectCache;
import java.util.Vector;
 
/** 
 * <p>A {@link Link} subclass used to hold information about links in the chain
 * builder.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class CLink extends Link {
	
	
    static {
     	RemoteObjectCache.addClass("OME::AnalysisChain::Link",CLink.class);
     }
	
	/*
	 * A list of nodes that might include internal CLayoutNodes. This list is 
	 * needed to reconstruct the multiple points in a link that might be needed
	 * when doing an automated layout.
	 */
	private Vector nodes = new Vector();
	
	public CLink() {
		super();
		init();
	}
	
	public CLink(RemoteSession session,String reference) {
		super(session,reference);
		init();
	}
	/**
	 * A link has at least two nodes -the beginning and the end
	 *
	 */
	private void init() {
		nodes.add(getFromNode());
		nodes.add(getToNode());
	}
	
	/**
	 * Insert a node into the Link
	 * @param prior the new node should be inserted immediately after this node
	 * @param newNode the node to be inserted.
	 */
	public void addIntermediate(CNode prior,CNode newNode) {
		int index = nodes.indexOf(prior);	
		nodes.insertElementAt(newNode,index+1);
	}
	
	public CNode getIntermediateNode(int i) {
		return (CNode) nodes.elementAt(i);
	}
 }
