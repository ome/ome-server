/*
 * org.openmicroscopy.vis.piccolo.PChainLibraryEventHandler
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

import edu.umd.cs.piccolo.event.PBasicInputEventHandler;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.event.MouseEvent;

/** 
 * An event handler for the PChainLibraryCanvas. Generally works like 
 * a pan event handler, but can tell the canvas which item we're on.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PChainLibraryEventHandler extends  PBasicInputEventHandler {

	private PChainLibraryCanvas canvas;
	
	private int allButtonMask = MouseEvent.BUTTON1_MASK;
	
	private PModule lastEntered;
	
	/**
	 * A flag indicating that the previous event was a popup
	 * 
	 */
	private static boolean postPopup = false;
	
	public PChainLibraryEventHandler(PChainLibraryCanvas canvas) {
		super();
		this.canvas = canvas;	
	}
	
	/**
	 * When we click on the {@link PChainLibraryCanvas}, there are four 
	 * possibilities:
	 *  1) The post popup flag is set. In this case, the event is in artifact
	 * 		and should be ignored.
	 * 	2) we clicked on the camera. In that case, zoom to center 
	 * 		the contents of the canvas
	 *  3) We clicked on a {@link PBufferedNode}. More specifically, 
	 * 	    a {@link PModule} or a {@link PChainBox}. In this case, zoom
	 * 		to center the node.
	 *  4) We right clicked or control-clicked. Handle this like a popup. 
	 */
	public void mouseClicked(PInputEvent e) {
		
		if (postPopup == true) {
			postPopup = false;
			e.setHandled(true);
			return;
		}
		PNode node = e.getPickedNode();
		int mask = e.getModifiers() & allButtonMask;
		if (mask == MouseEvent.BUTTON1_MASK &&
			e.getClickCount() == 1) {
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
		else if (e.isControlDown() || (mask & MouseEvent.BUTTON3_MASK) ==1)
			handlePopup(e);
		else
			super.mouseClicked(e);
	}
	
	/**
	 * When the user presses the mouse on a {@link PChainBox}, tell the
	 * {@link PChainLibraryCanvas} which chain has been selected.
	 * Or, if it's a popup, handle it as such.
	 */
	public void mousePressed(PInputEvent e) {
		PNode node = e.getPickedNode();
		if (e.isPopupTrigger()) {
			handlePopup(e);
		}
		else if (node instanceof PChainBox) {
			PChainBox box = (PChainBox) node;
			//canvas.setSelectedChainID(box.getChainID());
			canvas.setSelectedChain(box.getChain());
		}
		else
			super.mousePressed(e);
	}
	
	/**
	 * When the mouse is released, tell the canvas that there is no longer
	 * a selected chain.
	 */
	public void mouseReleased(PInputEvent e) {
		if (e.isPopupTrigger()) {
			handlePopup(e);
		}
		else
			canvas.clearChainSelected();
	}
	
	/**
	 * When the mouse enters a PFormalParameter or a PModule, set corresponding
	 * items to be highlighted, according to the following rule:
	 * 		1) If necessary, Clear anything that had been highlighted 
	 * 				previously
	 * 		2) If the node that is entered is a formal parameter, set its
	 * 				corresponding parameters(parameters it can ink to)
	 * 				to be highlighted, along with all of the module widgets 
	 * 				for the containing module. 
	 * 		3)  if It is a module widget, set all outputs and inputs (from
	 * 				other modules) that might be linked to this module 
	 * 				to be highlighted. Also set all instances of this module
	 * 				to be highlighted.
	 * 
	 */
	public void mouseEntered(PInputEvent e) {
		PNode node = e.getPickedNode();
		//	System.err.println("entering "+node);
		
		// clear anything that was previously highlighted
		if (lastEntered != null)
			lastEntered.setParamsHighlighted(false);
			
		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
			param.setParamsHighlighted(true);
			PModule pmod = param.getPModule();
			pmod.setModulesHighlighted(true);
			e.setHandled(true);
		}
		else if (node instanceof PModule) {
			PModule pmod = (PModule) node;
			pmod.setAllHighlights(true);
			e.setHandled(true);
			lastEntered = pmod;
		}
		else {
			super.mouseEntered(e);
		}
	}
	
	/**
	 * When the mouse exits a node, set all of the modules and/or 
	 * parameters that correspond to no longer be selected. Note that leaving a 
	 * {@link PFormalParameter} might immediately and directly lead to
	 * entering a {@link PModule}, so a {@link mouseEntered()} call 
	 * might immediately follow.
	 * 
	 */
	public void mouseExited(PInputEvent e) {
		PNode node = e.getPickedNode();

		//System.err.println("exiting"+node);
		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
			param.setParamsHighlighted(false);
			PModule pmod = param.getPModule();
			pmod.setAllHighlights(false);
			e.setHandled(true);			
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
	
	/**
	 * To handle a popup, look at the parent of the node that the event was 
	 * on. If that parent is a bufferend node, zoom to center it.
	 * Or, if the parent is the camera, zoom to center it.
	 * Or, if the event was on the camera, zoom to center it.
	 */
	private void handlePopup(PInputEvent e) {
		postPopup = true;
		PNode node = e.getPickedNode();
		PNode p = node.getParent();
			
		if (p instanceof PBufferedNode) {
			PBufferedNode bn=(PBufferedNode) p;
			PBounds b = bn.getBufferedBounds();
			PCamera camera = canvas.getCamera();
			camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);		
		} else if (p instanceof PCamera || p == canvas.getLayer() ||
			node instanceof PCamera || node == canvas.getLayer()) {
			PBounds b = canvas.getBufferedBounds();
			PCamera camera = canvas.getCamera();
			camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
		}
		e.setHandled(true);	 
	}
	 
}