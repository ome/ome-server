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
import edu.umd.cs.piccolo.event.PInputEventFilter;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.event.MouseEvent;

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
	private PModule lastEntered;
	
	protected int allButtonMask = MouseEvent.BUTTON1_MASK;
	
	
	public PPaletteEventHandler(PPaletteCanvas canvas) {
		super();
		setEventFilter(new PInputEventFilter());
		setAutopan(false);
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
		}
		else {
			canvas.setSelected(null);
			super.mousePressed(e);
		}
	}
	
	public void mouseClicked(PInputEvent e) {
		PNode node = e.getPickedNode();
		int mask = e.getModifiers() & allButtonMask;
		if (mask == MouseEvent.BUTTON1_MASK &&
			e.getClickCount() == 2) {
			if (node instanceof PBufferedNode) {
				PBufferedNode cBox = (PBufferedNode) node;
				PBounds b = cBox.getBufferedBounds();
				PCamera camera = canvas.getCamera();
				// animate
				camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
				e.setHandled(true); 
			}
			else if (node instanceof PCamera) {
				PBounds b = canvas.getBufferedBounds();
				PCamera camera = canvas.getCamera();
				camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
				e.setHandled(true);
			}
			else
				super.mouseClicked(e);
		}
		else
			super.mouseClicked(e);
	}
	
	
	public void mouseReleased(PInputEvent e) {
		canvas.setSelected(null);
		super.mouseReleased(e);
	}
	
	public void mouseDragged(PInputEvent e) {
		 e.setHandled(true);
	} 
	
	public void mouseEntered(PInputEvent e) {
		PNode node = e.getPickedNode();
	//	System.err.println("entering "+node);
		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
	//		System.err.println("entered a formal parameter "+param.getName());
			if (lastEntered != null) {
	//			System.err.println("clearing highlights for parameters of "+lastEntered.getModule().getName());
				lastEntered.setParamsHighlighted(false);
			}
			param.setParamsHighlighted(true);
			PModule pmod = param.getPModule();
			pmod.setModulesHighlighted(true);
			e.setHandled(true);
		}
		else if (node instanceof PParameterNode) {
			if (lastEntered != null) {
	//			System.err.println("entered parameter node ");
	//			System.err.println("clearing highlights for parameters of "+lastEntered.getModule().getName());
				lastEntered.setParamsHighlighted(false);
			}
			e.setHandled(true);
		}
		else if (node instanceof PModule) {
			PModule pmod = (PModule) node;
			pmod.setAllHighlights(true);
			e.setHandled(true);
			System.err.println("saving last module entered: "+pmod.getModule().getName());
			lastEntered = pmod;
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

		System.err.println("exiting"+node);
		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
			param.setParamsHighlighted(false);
			PModule pmod = param.getPModule();
			pmod.setAllHighlights(false);
			e.setHandled(true);			
		}
		else if (node instanceof PParameterNode) {
			System.err.println("exited parameter node");
		}
		else if (node instanceof PModule) {
			PModule pmod = (PModule) node;
			pmod.setAllHighlights(false);
			e.setHandled(true);
			lastEntered = null;
		}
		else
			super.mouseExited(e);
	}
 }
