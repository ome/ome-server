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

import org.openmicroscopy.SemanticType;
import edu.umd.cs.piccolo.event.PPanEventHandler;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.event.PInputEventFilter;
import edu.umd.cs.piccolo.PNode;
import java.awt.geom.Dimension2D;
import java.awt.geom.Point2D;
import java.awt.event.KeyEvent;
import java.util.Vector;
import java.util.Iterator;
import java.util.Collection;



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
	
	private static final int NOT_LINKING=1;
	private static final int LINKING_PARAMS=2;
	private static final int LINKING_MODULES=3;
	private int linkState = NOT_LINKING;
	
	// Store the last module parameter that we were in.
	private PFormalParameter lastParameterEntered;
	private PModule lastModuleEntered;
	private PLinkLayer linkLayer;
	
	
	private Point2D.Float linkStart = new Point2D.Float();
	
	private PFormalParameter linkOrigin;
	
	// The link I just clicked on to select
	private PParamLink selectedLink = null;
	
	// the link that I'm creating
	private PParamLink link;
	
	// the list of links I'm creating
	private Vector links = new Vector();
	
	private PModule selectedModule;
	private Collection activeModuleLinkParams;
	
	private boolean moduleLinksStartedAsInputs = false;
	
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
		Point2D pos = e.getPosition();
		if (linkState == LINKING_PARAMS) {
			link.setEndCoords((float) pos.getX(),(float) pos.getY());
		}
		else if (linkState == LINKING_MODULES) {
			Iterator iter = links.iterator();
			PParamLink lnk;
			while (iter.hasNext()) {
				lnk = (PParamLink) iter.next();
				lnk.setEndCoords((float) pos.getX(),(float) pos.getY());
			}
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
		
		if (node instanceof PFormalParameter && linkState == LINKING_MODULES 
				&& e.getClickCount() == 2) {
			System.err.println("finishing links because I clicked on a formal param");
			PFormalParameter p = (PFormalParameter) node;
			PModule mod = p.getPModule();
			finishModuleLinks(mod);
		}		
		else if (node instanceof PFormalParameter 
				&& linkState == NOT_LINKING) {
			System.err.println("starting a new param link");
			if (lastParameterEntered == null)
				mouseEntered(e);
			PFormalParameter param = (PFormalParameter) node;
			if (param.canBeLinkOrigin())
				startParamLink(param);
			e.setHandled(true);
		}
		
		else if (node instanceof PParamLink) { 
			System.err.println("pressed on param link");
			selectedLink = (PParamLink) node;
			selectedLink.setSelected(true);
			linkState = NOT_LINKING;	
		}
		else if (node instanceof PModule) {
			System.err.println("clicked on  a module");
			selectedModule = (PModule) node;
			selectedModule.addHandles();
			if (e.getClickCount() ==2) {
				if (linkState == NOT_LINKING)
					startModuleLinks(e);
				else if (linkState == LINKING_MODULES)
					finishModuleLinks((PModule) node);
			} 
		}
		else if (linkState == LINKING_MODULES) {
			System.err.println("linking modules. pressed.");
		 	if (e.getClickCount() ==2)
				cancelModuleLinks();
		
		}
		else if (linkState == LINKING_PARAMS) {
			System.err.println("mouse pressed in linking params");
			if (e.getClickCount() ==2) {
				cancelParamLink();
			}
			else if (lastParameterEntered != null)
				finishParamLink();
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
		
 	private void startParamLink(PFormalParameter param) {
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
	private void finishParamLink() {
		if (lastParameterEntered.isLinkable() == true) {
			//System.err.println("finishing link");
			link.setEndParam(lastParameterEntered);
			link.setPickable(true);
			linkLayer.completeLink(link);
			cleanUpParamLink();
		}
		else {
			//////System.err.println("trying to finish link, but end point is not linkable");
			cancelParamLink();
		}
		linkState = NOT_LINKING;
	}
	
	private void cancelParamLink() {
		//System.err.println("canceling link");
		link.removeFromParent();
		linkState = NOT_LINKING;
		link =null;
		cleanUpParamLink();
	}
	
	private void cleanUpParamLink() {
		linkOrigin.setParamsHighlighted(false);
		linkOrigin.decorateAsLinkStart(false);
		linkOrigin = null;
		lastParameterEntered = null;
	}
	
	private void startModuleLinks(PInputEvent e) {

		Point2D pos = e.getPosition();
		boolean isInput = selectedModule.isOnInputSide(pos);
		Collection inputs = selectedModule.getInputParameters();
		Collection outputs = selectedModule.getOutputParameters();
		if (isInput == true  || outputs.size() == 0) {
			System.err.println("building module links on input side");
			startModuleLinks(inputs);
			moduleLinksStartedAsInputs = true;
		}
		else { 
			System.err.println("building module links on output side");
			startModuleLinks(outputs); 
			moduleLinksStartedAsInputs = false;
		}
		linkState = LINKING_MODULES; 
	}
	
	private void startModuleLinks(Collection params) {
		activeModuleLinkParams = params;
	
		Iterator iter = params.iterator();
		while (iter.hasNext()) {
			PFormalParameter param = (PFormalParameter) iter.next();
			param.decorateAsLinkStart(true);
			PParamLink link = new PParamLink();
			linkLayer.addChild(link);
			link.setStartParam(param);
			link.setPickable(false);
			links.add(link);
		}
	}
	
	public void finishModuleLinks(PModule mod) {
		Collection c;
		
		// if I started as inputs, get outputs of this node.
		if (moduleLinksStartedAsInputs == true)
		 	c = mod.getOutputParameters();
		else 
		 	c = mod.getInputParameters();
		finishModuleLinks(c);
		links = new Vector();
		linkState = NOT_LINKING;
	}
	
	public void finishModuleLinks(Collection targets) {
		// ok, for each thing in the initial params, finish 
		//this link against targets
		Iterator iter = links.iterator();
		while (iter.hasNext()) {
			PParamLink lnk = (PParamLink) iter.next();
			finishAModuleLink(lnk,targets);
		}
	}	
	
	public void finishAModuleLink(PParamLink link,Collection targets) {
		PFormalParameter start = link.getStartParam();
		SemanticType startType = start.getSemanticType();
		
		Iterator iter = targets.iterator();
		PFormalParameter p;
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			SemanticType type = p.getSemanticType();
			if (startType == type) {
				// finish it 
				link.setEndParam(p);
				link.setPickable(true);
				linkLayer.completeLink(link);
				start.setParamsHighlighted(false);
				start.decorateAsLinkStart(false);
				return;
			}
		}
		// no matches. remove it.
		start.setParamsHighlighted(false);
		start.decorateAsLinkStart(false);
		link.removeFromParent();
	}
	
	
	
	
	
	public void cancelModuleLinks() {
		System.err.println("cancelling module links...");
		Iterator iter = links.iterator();
		while (iter.hasNext()) {
			PParamLink link = (PParamLink) iter.next();
			link.removeFromParent();
		}
		linkState = NOT_LINKING;
		cleanUpModuleLink();
	}
	
	public void cleanUpModuleLink() {
		Iterator iter = activeModuleLinkParams.iterator();
		while (iter.hasNext()) {
			PFormalParameter origin = (PFormalParameter) iter.next();
			origin.setParamsHighlighted(false);
			origin.decorateAsLinkStart(false);
		}
		links = new Vector();
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