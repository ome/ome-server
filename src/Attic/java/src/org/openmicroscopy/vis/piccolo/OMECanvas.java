/*
 * org.openmicroscopy.vis.piccolo.OMECanvas
 *
 * Copyright (C) 2003 Open Microscopy Environment
 * 		Massachusetts Institute of Technology,
 * 		National Institutes of Health,
 * 		University of Dundee
 * 
 * Author:  Harry Hochheiser <hsh@nih.gov>
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
 */

package org.openmicroscopy.vis.piccolo;

import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.remote.RemoteModule;

/** 
 * <p>Extends PCanvas to provide functionality necessary for a piccolo canvas. 
 * Currently doesn't have much functionality, but is also useful for isolating
 * piccolo contact from other code..<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class OMECanvas extends PCanvas{
	
	private Connection connection;
	private int modCount;
	private RemoteModule module;
	private PLayer layer;
	
	private static final float GAP=30f;
	private float top=20f;
	
	public OMECanvas() {
		super();
		layer = getLayer();
	}
	
	public void setConnection(Connection connection) {
		this.connection = connection;
		
		modCount = connection.moduleCount();
		module = connection.getModule(0);
		
		
		for (int i = 0; i < modCount; i++ ) {
			displayModule(connection.getModule(i),20);
		}
	}
	
	public void displayModule(RemoteModule module,float x) {
		System.err.println("displaying module "+module.getName());
		ModuleNode mNode = new ModuleNode(module,x,top);
		float h = (float) mNode.getBounds().getHeight();
		top += h+GAP;
		layer.addChild(mNode);
	}
}