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

import org.openmicroscopy.vis.ome.CModule;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.event.PInputEvent;
import java.awt.event.MouseEvent;



/** 
 * An event handler for the {@link PPaletteCanvas}. Generally works like 
 * a {@link PPanEventHandler, but can tell the canvas which item we're on.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PPaletteEventHandler extends  PModuleZoomEventHandler {
	
	/**
	 * The Canvas for which we are handling events
	 */
	private PPaletteCanvas canvas;
	
	/**
	 * The lat module node that was entered
	 */
	private PModule lastEntered;
	
	/**
	 * A Mask to select for left button events
	 */
	protected int allButtonMask = MouseEvent.BUTTON1_MASK;
	
	/**
	 * A flag that is set immediately after a popup event
	 * 
	 */
	private boolean postPopup = false;

	/** 
	 * The last ome module that was highlighted (from the jTree
	 */
	private CModule lastModule;
	
	public PPaletteEventHandler(PPaletteCanvas canvas) {
		super(canvas);
		this.canvas = canvas;		
	}
	
	/**
	 * When the mouse is pressed on a {@link PModule} or 
	 * {@link PFormalParameter}, tell the {@link PPaletteCanvas} to 
	 * note the associated {@link PModule} as being selected. This sets
	 * the stage for drag from the canvas. 
	 * 
	 */
	public void mousePressed(PInputEvent e) {
	
		if (e.isPopupTrigger()) {
			handlePopup(e);
			return;
		}
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
	
	
	
	/**
	 * Clear the selection of the current when the mouse is released. 
	 */
	public void mouseReleased(PInputEvent e) {
		if (e.isPopupTrigger()) {
			System.err.println("mouse released");
			handlePopup(e);
		}
		else {
			canvas.setSelected(null);
			super.mouseReleased(e);
		}
	}
	
	protected void unhighlightModules() {
		super.unhighlightModules();
		if (lastModule != null) {
			lastModule.setModulesHighlighted(false);	
			lastEntered = null;
		}
	}
	
	public void highlightModules(CModule module) {
		unhighlightModules();
		lastModule=module;
		lastModule.setModulesHighlighted(true);
	}
	
 }
