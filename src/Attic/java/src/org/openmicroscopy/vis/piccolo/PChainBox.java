/*
 * org.openmicroscopy.vis.piccolo.PChainBox
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

import org.openmicroscopy.vis.ome.CChain;
import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.Color;


/** 
 * A subclass of {@link PCategoryBox} that is used to provide a colored 
 * background for {@link PChain} widgets in the {@link PChainLibraryCannvas}
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PChainBox extends PCategoryBox {
	
	/**
	 * The color for display of the lock icon
	 */
	private static final Color LOCK_ICON_COLOR= new Color(255,0,0,100);
	
	/**
	 * The size of an orthogonal side of the lock icon
	 */
	public static final int SIZE_LENGTH=50;
	
	/**
	 * The ID of the chain being stored
	 */
	private int chainID=0;
	
	private CChain chain;
	
	public PChainBox(CChain chain, float x, float y) {
		super(x,y);
		this.chain = chain;
		chainID = chain.getID();
	}
	
	/**
	 * 
	 * @return the ID of the chain stored in the box
	 */
	public int getChainID() {
		return chainID;
	}
	
	
	public void setExtent(double width,double height) {
		super.setExtent(width,height);
		// add a triangle in the corner.
		if (chain.getLocked()) {
			PBounds b = getFullBoundsReference();
			addLockIcon((float) (b.getX()+width),(float) b.getY());
		}
	}
		
	/**
	 * Add the icon indicating that the chain is locked
	 */
	private void addLockIcon(float x,float y) {
		PPath lock = new PPath();
		lock.setPaint(LOCK_ICON_COLOR);
		lock.moveTo(x,y);
		lock.lineTo(x-SIZE_LENGTH,y);
		lock.lineTo(x,y+SIZE_LENGTH);
		lock.lineTo(x,y);
		addChild(lock);
	}
}