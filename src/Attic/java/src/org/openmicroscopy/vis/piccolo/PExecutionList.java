/*
 * org.openmicroscopy.vis.piccolo.PExecutionList
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
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
package org.openmicroscopy.vis.piccolo;

import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.util.PBounds;
import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.ome.CChain;
import org.openmicroscopy.ChainExecution;
import java.util.Collection;
import java.util.Iterator;


/** 
 * Node to hold list of chain executions
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PExecutionList extends PNode {
	
	private CDataset dataset;
	private CChain chain;
	public PExecutionList(CDataset dataset,CChain chain,double scale) {
		super();
		this.dataset = dataset;
		this.chain = chain;
		buildList(scale);
	}
	
	private void buildList(double scale) {
		// get the executions for the chain
		Collection execs = chain.getExecutions(dataset);
		Iterator iter = execs.iterator();
		
		double y = 0;
		// build an item for each one on the list.
		while (iter.hasNext()) {
			ChainExecution exec = (ChainExecution) iter.next();
			PExecutionText ptext = new PExecutionText(exec,scale);
			addChild(ptext);
			ptext.setOffset(0,y);
			PBounds b = ptext.getGlobalFullBounds();
			y+= b.getHeight();	
		}
		
		// set size, color, etc. of this  node.
		
	}
}
