/*
 * org.openmicroscopy.vis.piccolo.PBrowserEventHandler
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

public class PBrowserEventHandler extends  PGenericZoomEventHandler {
	
	private int allButtonMask = MouseEvent.BUTTON1_MASK;
	
	/**
	 * A flag indicating that the previous event was a popup
	 * 
	 */
	private static boolean postPopup = false;
	
	public PBrowserEventHandler(PBrowserCanvas canvas) {
		super(canvas);
		this.canvas = canvas;	
	}
	
	public void mouseEntered(PInputEvent e) {
	//	System.err.println("got mouse entered in browser");
		PNode n = e.getPickedNode();
	//	System.err.println("node is "+n);
		if (n instanceof PThumbnail) {
			PThumbnail pt = (PThumbnail) n;
			pt.setHighlighted(true);
			e.setHandled(true);
		}
		super.mouseEntered(e);
	}
	
	public void mouseExited(PInputEvent e) {
		PNode n = e.getPickedNode();
		if (n instanceof PThumbnail) {
			PThumbnail pt = (PThumbnail) n;
			pt.setHighlighted(false);
			e.setHandled(true);
		}
		super.mouseExited(e);
	}	
	
	public void mouseReleased(PInputEvent e) {
		if (e.isPopupTrigger()) {
			handlePopup(e);
			e.setHandled(true);
		}
	}
	
	public void mousePressed(PInputEvent e) {
		mouseReleased(e);
	}
	
	public void mouseClicked(PInputEvent e) {
		super.mouseClicked(e);
		if (e.getPickedNode() instanceof PDataset) { 
			System.err.println("zooming in on dataset");
			PDataset d = (PDataset) e.getPickedNode();
			((PBrowserCanvas) canvas).setSelectedDataset(d.getDataset());
		}
	}
}