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

import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;
import java.awt.event.MouseEvent;

/** 
 * An event handler for the PChainLibraryCanvas. Generally works like 
 * a pan event handler, but can tell the canvas which item we're on.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PChainLibraryEventHandler extends  PModuleZoomEventHandler {

	private PChainLibraryCanvas canvas;
	
	private int allButtonMask = MouseEvent.BUTTON1_MASK;
	
	private PModule lastEntered;
	
	/**
	 * A flag indicating that the previous event was a popup
	 * 
	 */
	private static boolean postPopup = false;
	
	public PChainLibraryEventHandler(PChainLibraryCanvas canvas) {
		super(canvas);
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
	/*public void mouseClicked(PInputEvent e) {
		
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
	} */
	
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
	
}