/*
 * org.openmicroscopy.vis.piccolo.PResultEventHandler
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
import org.openmicroscopy.Module;
import org.openmicroscopy.Attribute;
import org.openmicroscopy.SemanticType;
import org.openmicroscopy.Module.FormalOutput;
import org.openmicroscopy.vis.ome.CChainExecution;
import java.awt.event.MouseEvent;
import java.util.List;
import java.util.Iterator;


/** 
 * An event handler for the result canvas
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PResultEventHandler extends  PPanEventHandler {

	private PResultCanvas canvas;
	
	private int allButtonMask = MouseEvent.BUTTON1_MASK;
	
	private PModule lastEntered;
	
	/**
	 * A flag indicating that the previous event was a popup
	 * 
	 */
	private static boolean postPopup = false;
	
	public PResultEventHandler(PResultCanvas canvas) {
		super();
		setAutopan(false);
		this.canvas = canvas;
		PInputEventFilter filter =getEventFilter();
		filter.acceptEverything();
		setEventFilter(filter);	
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
			else if (node instanceof PCamera && e.isShiftDown()) {
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
		else if (e.getPickedNode() instanceof PFormalOutput) {
			PFormalOutput outputNode = (PFormalOutput) e.getPickedNode();
			System.err.println("pressed on "+outputNode.getName());
			PModule modNode = outputNode.getPModule();
			FormalOutput output= (FormalOutput) 
				outputNode.getParameter();
			Module mod = modNode.getModule();
			System.err.println("Module name is "+mod.getName());
			CChainExecution exec = canvas.getChainExecution();
			List results = exec.getResults(mod,output);
			if (results.size() > 0)
				dumpOutputs(results);
			e.setHandled(true);
		}
		super.mousePressed(e);
	}
	
	private void dumpOutputs(List results) {
		System.err.println("getting results...");
		Iterator iter = results.iterator();
		Attribute att;
		while (iter.hasNext()) {
			att = (Attribute) iter.next();
			SemanticType type = att.getSemanticType();
			System.err.println(type.getName());
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
			super.mouseReleased(e);
		}
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
		System.err.println("handling popup...");
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
			PCamera camera = (canvas).getCamera();
			camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
		}
		e.setHandled(true);
	}
}