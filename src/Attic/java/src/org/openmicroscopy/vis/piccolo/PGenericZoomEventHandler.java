/*
 * org.openmicroscopy.vis.piccolo.PGenericZoomEventHandler
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
import edu.umd.cs.piccolo.event.PBasicInputEventHandler;
import edu.umd.cs.piccolo.event.PInputEventFilter;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.event.MouseEvent;


/** 
 * An event handler superclass for the {@link PPaletteCanvas} and 
 * {@link PChainLibraryCanvas}. Handles zooming into and out of {@link Pmodule},
 *  and {@link PCategoryBox} instances.
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PGenericZoomEventHandler extends  PBasicInputEventHandler {
	
	/**
	 * The Canvas for which we are handling events
	 */
	protected PBufferedObject canvas;
	
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
	
	public PGenericZoomEventHandler(PBufferedObject canvas) {
		super();
		PInputEventFilter filter = new PInputEventFilter();
		filter.acceptEverything();
		setEventFilter(filter);
		this.canvas = canvas;		
	}
	
	
	

	/**
	 * If the mouse is clicked on a buffered node (either a 
	 * {@link PCategoryBox}, or a {@link PModule}, zoom to center it.
	 * If the mouse is clicked on the layer or on the {@link PCamera},
	 * zoom to center the entire canvas.
	 * 
	 * If we right click, zoom out to the parent of where we clicked.
	 */
	public void mouseClicked(PInputEvent e) {
		PNode node = e.getPickedNode();
		int mask = e.getModifiers() & allButtonMask;
		
		if (postPopup == true) {
			postPopup = false;
			e.setHandled(true);
			return;
		}
		if (mask == MouseEvent.BUTTON1_MASK && e.getClickCount() == 1) {
		
			if (e.isControlDown()) {
				handlePopup(e);	
			}
			else if (node instanceof PBufferedNode) {
				PBufferedNode cBox = (PBufferedNode) node;				
				PBounds b = cBox.getBufferedBounds();
				PCamera camera = ((PCanvas) canvas).getCamera();
				camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
				e.setHandled(true); 
			}
			else if (node instanceof PCamera || node == ((PCanvas) canvas).getLayer()) {
				PBounds b = canvas.getBufferedBounds();
				PCamera camera = ((PCanvas) canvas).getCamera();
				camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
				e.setHandled(true);
			}
			else
				super.mouseClicked(e);
		} 
		else if (e.isControlDown() || (mask & MouseEvent.BUTTON3_MASK)==1) {
			handlePopup(e);
		}
		else
			super.mouseClicked(e);
	}
	
	 
	
	
		
	/**
	 * unhighlight the modules..
	 */
	protected void unhighlightModules() {
		if (lastEntered != null)
			lastEntered.setParamsHighlighted(false);	
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
		
		unhighlightModules();
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
	
	
	
	/***
	 * Zoom out to the parent of the current node when we get a popup
	 */
	protected void handlePopup(PInputEvent e) {
		postPopup = true;
		PNode node = e.getPickedNode();
		PNode p = node.getParent();
		if (p instanceof PBufferedNode) {
			PBufferedNode bn=(PBufferedNode) p;
			PBounds b = bn.getBufferedBounds();
			PCamera camera = ((PCanvas) canvas).getCamera();
			camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);		
		} else if (p instanceof PCamera || p == ((PCanvas) canvas).getLayer() ||
					node instanceof PCamera || node == ((PCanvas) canvas).getLayer()) {
			PBounds b = canvas.getBufferedBounds();
			PCamera camera = ((PCanvas) canvas).getCamera();
			camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
		}
		e.setHandled(true);
	}
 }
