/*
 * org.openmicroscopy.vis.piccolo.PChainEventHandler
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
import java.awt.geom.Dimension2D;
import java.awt.geom.Point2D;
import java.awt.event.KeyEvent;


/** 
 * An event handler for the PChainCanvas. This handler is responsible for 
 * (1) General panning of the scenegraph. (2) Dragging of the ModuleNodes
 * for positioning purposes. (3) Highlighting potential link targets upon
 * mouse over of a module input/output. (4) Click-drag interaction to support
 * linkage between inputs and outputs.<p>
 * 
 * In some cases we might prefer to do this via several small handlers. 
 * However, complexity and communication requirements make it better to do this 
 * all in one place. This is particularly true for goal (4), above, as 
 * a single handler allows us to easily communicate the identity of _both_ ends 
 * in a click-drag interaction.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PChainEventHandler extends  PPanEventHandler {
	
	private boolean dragging = false;
	
	// Store the last module parameter that we were in.
	private PFormalParameter lastParameterEntered;
	private PModule lastModuleEntered;
	private PLinkLayer linkLayer;
	
	private PParamLink link;
	private Point2D.Float linkStart = new Point2D.Float();
	private static final int NOT_LINKING=1;
	private static final int LINKING_PARAMS=2;
	private static final int LINKING_MODULES=3;
	private int linkState = NOT_LINKING;
	
	private PFormalParameter linkOrigin;
	
	private PParamLink selectedLink = null;
	private PModule selectedModule;

	
	public PChainEventHandler(PChainCanvas canvas,PLinkLayer linkLayer) {
		super();
		setAutopan(false);
		this.linkLayer = linkLayer;
		PInputEventFilter filter =getEventFilter();
		filter.setAcceptsKeyPressed(true);
		setEventFilter(filter);
		canvas.getRoot().getDefaultInputManager().
			setKeyboardFocus(this);		
	}
	
	/**
	 * If the drag event occurs on a module node, translate it. Otherwise,
	 * we follow default drag handling.
	 * 
	 */
	protected void drag(PInputEvent e) {
		PNode node = e.getPickedNode();
		
		//System.err.println("PChainEventHandler.drag()");
		// module nodes simply get translated.
		//System.err.println("in chain handler drag");
		if (node instanceof PModule) {
			if (linkState != LINKING_MODULES) {
				//System.err.println("translating a node");
				PModule mn = (PModule) node;
				Dimension2D delta = e.getDeltaRelativeTo(node);
				node.translate(delta.getWidth(),delta.getHeight());
				e.setHandled(true);
			}
		}
		else if (!(node instanceof PFormalParameter)){
			super.drag(e);
			e.setHandled(true);
		}
	}
	
	/**
	 * If we've entered a parameter node, store it as the "lastParameterEntered",
	 * and call setParamsHighlight() to light up the potential link
	 * targets. However, we only do this when we're not dragging. If we're
	 * already dragging, don't change the set of highlighted parameters.<p> 
	 * 
	 * Otherwise, clear lastParameterEntered and do the default.
	 * 
	 */
	public void mouseEntered(PInputEvent e) {
		PNode node = e.getPickedNode();
		
		if (node instanceof PFormalParameter) {
			lastParameterEntered = (PFormalParameter) node;
			//System.err.println("mouse entered last entered.."+
			//	lastParameterEntered.getName());
			if (linkState == NOT_LINKING) {
				PModule mod = lastParameterEntered.getPModule();
				mod.setParamsHighlighted(false);
				// must turn on params for this parameter _after_
				// we turn off all params for the module, 
				// or else turnning off params for the module
				// will undo what had just bee turned on.
				lastParameterEntered.setParamsHighlighted(true);
				mod.setModulesHighlighted(true);	
			}
			e.setHandled(true);
		}
		else if (node instanceof PModule && linkState == NOT_LINKING) {
			PModule mod = (PModule) node;
			mod.setAllHighlights(true);
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
	
		lastParameterEntered = null;
		//System.err.println("last parameter entered cleared");
		if (node instanceof PFormalParameter) {
			PFormalParameter param = (PFormalParameter) node;
			if (linkState == NOT_LINKING) {	
				param.setParamsHighlighted(false);
				PModule mod = param.getPModule();
				mod.setAllHighlights(false);
			}			
			e.setHandled(true);
		}
		else if (node instanceof PModule && linkState == NOT_LINKING) {
			PModule mod = (PModule) node;
			mod.setAllHighlights(false);
			e.setHandled(true);
		}
		else
			super.mouseExited(e);
	}
	
	
	
	public void mouseDragged(PInputEvent e) {
		//System.err.println("CHAIN HANDLER:got a drag event in chain canvas");
		mouseMoved(e);
		super.mouseDragged(e);	
	}
	
	public void mouseMoved(PInputEvent e) {
		if (linkState == LINKING_PARAMS) {
			Point2D pos = e.getPosition();
			link.setEndCoords((float) pos.getX(),(float) pos.getY());
		}

	}
	
	public void mousePressed(PInputEvent e) {
		PNode node = e.getPickedNode();
		
		//System.err.println("mouse pressed on "+node);
		
		// clear off what was selected.
		if (selectedLink != null) {
			selectedLink.setSelected(false);
			selectedLink = null;
		}
		if (selectedModule != null) {
			selectedModule.removeHandles();
			selectedModule = null;
		}
		
		if (node instanceof PFormalParameter && linkState != LINKING_PARAMS) {
			// works if I say == NOT_LINKING
	//		System.err.println("starting a new link");
			if (linkState  == LINKING_MODULES) {
				//do something appropriate here. 
			}
			if (lastParameterEntered == null)
				mouseEntered(e);
			PFormalParameter param = (PFormalParameter) node;
			if (param.canBeLinkOrigin())
				startLink(param);
			e.setHandled(true);
		}
		else if (node instanceof PParamLink) {
			//System.err.println("pressed on link");
			selectedLink = (PParamLink) node;
			selectedLink.setSelected(true);
			linkState = NOT_LINKING;	
		}
		else if (node instanceof PModule) {
			if (linkState == NOT_LINKING && e.getClickCount() ==2 ) {
				//System.err.println("setting link state to LINKING_MODULES");
				linkState = LINKING_MODULES;
			}
			selectedModule = (PModule) node;
			selectedModule.addHandles();
			//eventually, check link state. do one thing if not
			//linking and another if linkingmodules
		}
		else if (linkState == LINKING_PARAMS) {
			//System.err.println("mouse pressed and not linking");
			if (e.getClickCount() ==2) {
				cancelLink();
			}
			else if (lastParameterEntered != null)
				finishLink();
			/*else { assume all links have one end point and one start point
				System.err.println("extending link");
				Point2D pos = e.getPosition();
				link.addIntermediate((float) pos.getX(),(float) pos.getY());
			}*/
			e.setHandled(true);
		}
		else
			linkState =  NOT_LINKING;
		//	super.mousePressed(e);
	}
		
 	private void startLink(PFormalParameter param) {
		//System.err.println("mouse pressing and starting link");
		linkOrigin = param;
		linkOrigin.decorateAsLinkStart(true);
		link = new PParamLink();
		linkLayer.addChild(link);
		link.setStartParam(linkOrigin);
		link.setPickable(false);
		linkState = LINKING_PARAMS;			
 	}
		
	// this link ends at lastParameterEntered
	private void finishLink() {
		if (lastParameterEntered.isLinkable() == true) {
			//System.err.println("finishing link");
			link.setEndParam(lastParameterEntered);
			link.setPickable(true);
			linkLayer.completeLink(link);
			cleanUpLink();
		}
		else {
			//////System.err.println("trying to finish link, but end point is not linkable");
			cancelLink();
		}
		linkState = NOT_LINKING;
	}
	
	private void cancelLink() {
		//System.err.println("canceling link");
		link.removeFromParent();
		linkState = NOT_LINKING;
		link =null;
		cleanUpLink();
	}
	
	private void cleanUpLink() {
		linkOrigin.setParamsHighlighted(false);
		linkOrigin.decorateAsLinkStart(false);
		linkOrigin = null;
		lastParameterEntered = null;
	}
	
	
	
	
	public void keyPressed(PInputEvent e) {
		//System.err.println("a key was pressed ");
		if (e.getKeyCode() != KeyEvent.VK_DELETE)
			return;
			
		if (selectedLink != null) {
			selectedLink.remove();
			selectedLink = null;
		}
		else if (selectedModule != null) {
			selectedModule.remove();
			selectedModule = null;
		}
	}
	
}