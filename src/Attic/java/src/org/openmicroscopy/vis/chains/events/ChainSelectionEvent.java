/*
 * org.openmicroscopy.vis.chains.events.ChainSelectionEvent
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


package org.openmicroscopy.vis.chains.events;
import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.ome.CChain;



/** 
 * An event that indicates that a dataset has been selected or deselected
 *
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class ChainSelectionEvent extends SelectionEvent {
	
	public static final int SELECTED = 1;
	public static final int DESELECTED=2;
	
	private CChain chain=null;
	private int status=0;
	
	// store state so this event always has a source that is non-null
	public ChainSelectionEvent(SelectionState state,CChain chain,int status) {
		super(state);
		this.chain = chain;
		this.status = status;
	}
	
	public CChain getChain() {
		return chain;
	} 		
	
	public int getStatus() {
		return status;
	}
}