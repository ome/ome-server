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
 
 public class CLink extends Link {
	
	
     static {
     	RemoteObjectCache.addClass("OME::AnalysisChain::Link",CLink.class);
     }
	private Vector nodes = new Vector();
	
	public CLink() {
		super();
		init();
	}
	
	public CLink(RemoteSession session,String reference) {
		super(session,reference);
		init();
	}
	private void init() {
		nodes.add(getFromNode());
		nodes.add(getToNode());
	}
	
	public void addIntermediate(CNode prior,CNode newNode) {
		int index = nodes.indexOf(prior);	
		nodes.insertElementAt(newNode,index+1);
	}
	
	public CNode getIntermediateNode(int i) {
		return (CNode) nodes.elementAt(i);
	}
 }
