/*
 * org.openmicroscopy.vis.chains.ome.Chains
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
 
 import java.util.TreeMap;
 import java.util.List;
 import java.util.Iterator;
 import java.util.Collection;
 import org.openmicroscopy.Chain;
 import org.openmicroscopy.Chain.Node;
 import org.openmicroscopy.Factory;
/** 
 * <p>A class to handle the chains in the OME database
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class Chains {
	
	private TreeMap chains = new TreeMap();
	
	public Chains(ConnectionWorker worker,Factory factory) {
		
		Chain c;
		Integer id;
		ChainInfo cInfo;
		
		List  cs= factory.findObjects("OME::AnalysisChain",null);
		Iterator iter = cs.iterator();
		
		while (iter.hasNext()) {
			c = (Chain) iter.next();
			System.err.println("Chain: "+c.getName());
			worker.setStatusLabel("Chain.."+c.getName());
			cInfo  = new ChainInfo(c);
			populateChain(cInfo);
			id = new Integer(c.getID());
			chains.put(id,cInfo);
		}
	}
	
	private void populateChain(ChainInfo cInfo) {

		Chain c = cInfo.getChain();
		List nodes = c.getNodes();
		Iterator iter = nodes.iterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			//System.err.println("trying to get a node from a chain.."+obj.getClass().getName());
			Node n = (Node) obj;
			cInfo.addNode(n);
		}
	}
	
	public void addChain(ChainInfo info) {
		Chain c = info.getChain();
		Integer id = new Integer(c.getID());
		chains.put(id,info);
	}
	
	public Iterator iterator() {
		Collection values = chains.values();
		return values.iterator();
	}
	
	public ChainInfo getChainInfo(int i) {
		return (ChainInfo) chains.get(new Integer(i));
	}
}
