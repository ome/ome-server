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
 
 import org.openmicroscopy.vis.chains.Controller;
 import java.util.TreeMap;
 import java.util.List;
 import java.util.Iterator;
 import java.util.Collection;
 
/** 
 * <p>A class to handle the chains in the OME database
 * 
 * @author Harry Hochheiser
 * @version 1.1
 * @since OME2.1
 */

public class Chains {
	
	private TreeMap chains = new TreeMap();
	private Controller controller;
	
	public Chains(Controller controller,Connection connection) {
		
		this.controller = controller;
		CChain c;
		Integer id;
		
		List  cs= connection.loadChains();
		Iterator iter = cs.iterator();
		
		while (iter.hasNext()) {
			c = (CChain) iter.next();
			// load the executions for this chain
			c.loadExecutions(connection);
			controller.setStatusLabel("Chain.."+c.getName());
			id = new Integer(c.getID());
			chains.put(id,c);
		}
	}
	
	/**
	 * layout each of the {@link CChain} objects in the list
	 *
	 */
	public void layout() {
		CChain c;
		
		Iterator iter = chains.values().iterator();
		while (iter.hasNext()) {
			c = (CChain) iter.next();
			controller.setStatusLabel("Chain Layout.."+c.getName());
			//System.err.println("Laying out chain ..."+c.getName());
			c.layout();
		}
	}
	
	/**
	 * Add a chain to the list
	 * @param c the chain to be added
	 */
	public void addChain(CChain c) {
		Integer id = new Integer(c.getID());
		chains.put(id,c);
	}
	
	public Iterator iterator() {
		Collection values = chains.values();
		return values.iterator();
	}
	
	/**
	 * Get a chain by ID
	 * @param i the ID of the desired chain
	 * @return the chain
	 */
	public CChain getChain(int i) {
		return (CChain) chains.get(new Integer(i));
	}
	
	/**
	 *
	 * @return the number of chains in the list.
	 */
	public int size() {
		return chains.size();
	}
}
