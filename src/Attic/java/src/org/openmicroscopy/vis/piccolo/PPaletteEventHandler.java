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
	private boolean selected = false;
	
	public PPaletteEventHandler(PPaletteCanvas canvas) {
		super();
		this.canvas = canvas;		
	}
	
	public void mousePressed(PInputEvent e) {
		PNode node = e.getPickedNode();
		if (node instanceof PModule || node instanceof PFormalParameter) {
			PModule p;
			if (node instanceof PFormalParameter)
				p = ((PFormalParameter) node).getPModule();
			else
			 	p = (PModule) node;
			canvas.setSelected(p);
			selected = true;
			System.err.println("pressed a mouse and selected a module");
		}
		else {
			System.err.println("pressed mouse and cleared module selected");
			selected = false;
			canvas.setSelected(null);
			super.mousePressed(e);
		}
	}
	
	
	public void mouseReleased(PInputEvent e) {
		System.err.println("released mouse and cleared module selected");
		selected = false;
		canvas.setSelected(null);
		super.mouseReleased(e);
	}
	
	public void mouseDragged(PInputEvent e) {
		//	don't pan if we've got something selected.
		 System.err.println("mouse dragged..in palette handler.");
		 if (selected == false) {
			 System.err.println("no selection..");
			 super.mouseDragged(e);
		 }
		 e.setHandled(true);
	} 
	
	public void mouseEntered(PInputEvent e) {
		PNode node = e.getPickedNode();
		System.err.println(" palette canvas. entering... "+node);
		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
			param.setParamsHighlighted(true);
			PModule pmod = param.getPModule();
			pmod.setModulesHighlighted(true);
			e.setHandled(true);
		}
		else if (node instanceof PModule) {
			PModule pmod = (PModule) node;
			pmod.setModulesHighlighted(true);
			e.setHandled(true);
		}
		else {
			super.mouseEntered(e);
		}
	}
	
	/**
	 * When we leave a node, we clear "lastParameterEntered" and 
	 * turn off any highlighting.
	 */
	public void mouseExited(PInputEvent e) {
		PNode node = e.getPickedNode();

		System.err.println(" palette canvas. exiting... "+node);
		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
			param.setParamsHighlighted(false);
			PModule pmod = param.getPModule();
			pmod.setModulesHighlighted(false);
			e.setHandled(true);			
		}
		else if (node instanceof PModule) {
			PModule pmod = (PModule) node;
			pmod.setModulesHighlighted(false);
			e.setHandled(true);
		}
		else
			super.mouseExited(e);
	}
 }