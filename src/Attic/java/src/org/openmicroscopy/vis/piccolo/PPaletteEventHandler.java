/*
 * org.openmicroscopy.vis.piccolo.PPaletteEventHandler
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

import edu.umd.cs.piccolo.event.PPanEventHandler;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;

/** 
 * An event handler for the PPaletteCanvas. Generally works like 
 * a pan event handler, but can tell the canvas which item we're on.
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PPaletteEventHandler extends  PPanEventHandler {
	
	private PPaletteCanvas canvas;
	
	public PPaletteEventHandler(PPaletteCanvas canvas) {
		super();
		this.canvas = canvas;		
	}
	
	public void mouseEntered(PInputEvent e) {
		PNode node = e.getPickedNode();
		if (node instanceof PModule) {
			PModule p = (PModule) node;
			canvas.setSelected(p.getModule());
			// do something
		}
		else
			canvas.setSelected(null);
	}
	
	public void mouseExited(PInputEvent e) {
		canvas.setSelected(null);
	}
 }