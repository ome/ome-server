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

import org.openmicroscopy.vis.ome.ModuleInfo;
import edu.umd.cs.piccolo.event.PPanEventHandler;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;
import java.util.ArrayList;
import java.util.Iterator;

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
			canvas.setSelected(p.getModule());
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
		
		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
			setParamsHighlighted(param,true);
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

		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
			setParamsHighlighted((PFormalParameter) param,false);
			e.setHandled(true);			
		}
		else
			super.mouseExited(e);
	}
		
	/** 
	 * To highlight link targets for a given PFormalParameter, get
	 * the list of "corresponding" ModuleParameters, and set each of those 
	 * to be linkable<p>
	 * @param param
	 * @param v
	 */
		
	private void setParamsHighlighted(PFormalParameter param, boolean v) {
			
		ArrayList list = param.getCorresponding();
	
		if (list == null)
			return;
		
		ModuleInfo source = param.getModuleInfo();
		
		PFormalParameter p;
		Iterator iter = list.iterator();
		
		PModule destModule;
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			
			if (v == true) {// when making things linkable
				// only make it linkable if we're not linked already
				// and we're not in the same module.
				if (!param.isLinkedTo(p) && source != p.getModuleInfo())
					p.setLinkable(v);
			}
			else // always want to clear linkable
				p.setLinkable(v);		
		}
	}
	
 }