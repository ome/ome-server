/*
 * org.openmicroscopy.vis.piccolo.PChainCanvas
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
import org.openmicroscopy.vis.ome.Connection;


/** 
 * Extends PCanvas to provide functionality necessary for a piccolo canvas.<p> 
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PChainCanvas extends PCanvas{
	
	private Connection connection=null;
	private int modCount;
	private PLayer layer;
	
	private float x,y;
	
	private PLayer linkLayer;
	
	public PChainCanvas() {
		super();
		layer = getLayer();
	
		removeInputEventListener(getPanEventHandler());
		linkLayer = new PLayer();
		getCamera().addLayer(linkLayer);
		linkLayer.moveToFront();
		addInputEventListener(new PChainEventHandler(this,linkLayer));
	}
	
	public  void setConnection(Connection connection) { 
		this.connection = connection;
	}	
}