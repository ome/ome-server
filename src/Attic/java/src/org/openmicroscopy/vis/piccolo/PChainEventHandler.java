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
import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.geom.Dimension2D;
import java.awt.geom.Point2D;
import java.awt.event.KeyEvent;
import java.util.Vector;
import java.util.Iterator;
import java.util.Collection;
import java.awt.event.MouseEvent;



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
	private static final int LINKING_CANCELLATION=4;
	private static final int LINK_CHANGING_POINT=5;
	
	private static final double SCALE_FACTOR=1.2;
	
	private static final int SPACING=6;
	private int linkState = NOT_LINKING;
	
	// Store the last module parameter that we were in.
	private PFormalParameter lastParameterEntered;
	private PModule lastModuleEntered;
	
	private PLinkSelectionTarget selectionTarget;
	private PLinkLayer linkLayer;
	
	
	private Point2D.Float linkStart = new Point2D.Float();
	
	private PFormalParameter linkOrigin;
	
	// The link I just clicked on to select
	private PLink selectedLink = null;
	
	
	// the link that I'm creating
	private PParamLink link;
	
	// the list of links I'm creating
	private Vector links = new Vector();
	
	private PModule selectedModule;
	private Collection activeModuleLinkParams;
	
	private boolean moduleLinksStartedAsInputs = false;
	
	protected int allButtonMask = MouseEvent.BUTTON1_MASK |
					MouseEvent.BUTTON2_MASK | MouseEvent.BUTTON3_MASK;
	
	private PChainCanvas canvas;
	
	
	public PChainEventHandler(PChainCanvas canvas,PLinkLayer linkLayer) {
		super();
		setAutopan(false);
		this.canvas = canvas;
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
		
		if (node instanceof PModule) {
			if (linkState != LINKING_MODULES) {
				PModule mod = (PModule) node;
				Dimension2D delta = e.getDeltaRelativeTo(node);
				mod.translate(delta.getWidth(),delta.getHeight());
				e.setHandled(true);
			}
		}
		else if (linkState == LINK_CHANGING_POINT) {
			Dimension2D delta = e.getDeltaRelativeTo(node);
			if (node instanceof PLinkSelectionTarget) {
				PLinkSelectionTarget target = (PLinkSelectionTarget) node;
				target.translate(delta.getWidth(),delta.getHeight());
			}
			e.setHandled(true);
		}
		else if (!(node instanceof PFormalParameter) 
			&& linkState == NOT_LINKING){
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
	//	System.err.println("CHAIN HANDLER:got a drag event in chain canvas");
		mouseMoved(e);
		super.mouseDragged(e);
	}
	
	public void mouseMoved(PInputEvent e) {
		Point2D pos = e.getPosition();
		//System.err.println("mouse move on canvas..."+pos.getX()+","+pos.getY());
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
	
	public void mouseClicked(PInputEvent e) {
		
		
		// we only scale if we're not drawing a link.
		if (linkState != NOT_LINKING) {
			if (linkState == LINKING_CANCELLATION)
				linkState = NOT_LINKING;
			e.setHandled(true);
			return;
		}
		
		
		PNode node = e.getPickedNode();
		int mask = e.getModifiers() & allButtonMask;
		PCamera camera = canvas.getCamera();
		if (! (node instanceof PCamera))
			return;
		
		if (e.isShiftDown()) {
			PBounds b = canvas.getBufferedBounds();
			camera.animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
			e.setHandled(true);
		}
		else { 
			double scaleFactor  = PConstants.SCALE_FACTOR;	
			if (mask != MouseEvent.BUTTON1_MASK) {
			}
			else {
				scaleFactor = 1/scaleFactor;
			}
			double curScale = camera.getScale();
			curScale *= scaleFactor;
			Point2D pos = e.getPosition();
			camera.scaleViewAboutPoint(curScale,pos.getX(),pos.getY());
			e.setHandled(true);
		}  
	}

	
	public void mousePressed(PInputEvent e) {
		PNode node = e.getPickedNode();
		
		//System.err.println("mouse pressed on "+node+", state "+linkState);
		
		// clear off what was selected.
		if (selectedLink != null && linkState != LINK_CHANGING_POINT) {
		//	System.err.println("setting selected link to not be selected, in mousePressed");
			selectedLink.setSelected(false);
			selectedLink = null;
		}
		if (selectedModule != null) {
			selectedModule.removeHandles();
			selectedModule = null;
		}
		if (selectionTarget != null) {
			selectionTarget.getLink().setSelected(false);
			selectionTarget = null;
		}
		
		//first do things based on types of nodes
		// then do based on state
		if (node instanceof PLinkSelectionTarget)
			mousePressedSelectionTarget(node);
		else if (node instanceof PLink)
			mousePressedLink(node);
		else if (node instanceof PModule)
			mousePressedModule(node);

		if (linkState == LINKING_PARAMS)
			mousePressedLinkingParams(node,e);
		else if (linkState == LINKING_MODULES)
			mousePressedLinkingModules(node,e);
		else if (linkState == NOT_LINKING) 
			mousePressedNotLinking(node,e);		
		else if (linkState == LINK_CHANGING_POINT)
			mousePressedChangingPoint(node,e);
		else
			linkState = NOT_LINKING;
	}
	
	private void mousePressedLink(PNode node) {
		if (linkState != LINK_CHANGING_POINT) {
			selectedLink = (PLink) node;
			selectedLink.setSelected(true);
			linkState = NOT_LINKING;
		}
	}
	
	private void mousePressedModule(PNode node) {
		selectedModule = (PModule) node;
		selectedModule.addHandles();
	}
	
	private void mousePressedSelectionTarget(PNode node) {
		System.err.println("pressing on selection target..");
		selectionTarget = (PLinkSelectionTarget) node;
		selectionTarget.getLink().setSelected(true);
		linkState = LINK_CHANGING_POINT;
	}
	
	private void mousePressedLinkingParams(PNode node,PInputEvent e) {
		if (e.getClickCount() ==2) {
			System.err.println("double clicking to cancel link");
			cancelParamLink();
			linkState = LINKING_CANCELLATION;
		}
		else if (lastParameterEntered == null) { // we're on canvas.
			Point2D pos = e.getPosition();
			link.setIntermediatePoint((float) pos.getX(),(float) pos.getY());
		}
		else if (lastParameterEntered != null)
			finishParamLink();
		e.setHandled(true);
	}
	
	private void mousePressedLinkingModules(PNode node,PInputEvent e) {
		int count = e.getClickCount();
		
		if (count ==2) {
			if (node instanceof PFormalParameter) {
				PFormalParameter p = (PFormalParameter) node;
				PModule mod = p.getPModule();
				finishModuleLinks(mod);
			}
			else if (node instanceof PModule) {
				finishModuleLinks((PModule) node);
			}
			else
				cancelModuleLinks();
		}
		else if (node instanceof PCamera){ // single click on camera 
			//when linking modules..
			Iterator iter = links.iterator();
			Point2D pos = e.getPosition();
			PParamLink lnk;
			int size = links.size();
			float y = ((float) pos.getY()) - size/2*SPACING;
			while (iter.hasNext()) {
				lnk = (PParamLink) iter.next();
				lnk.setIntermediatePoint((float) pos.getX(),y);
				y += SPACING;
			}
		}
		e.setHandled(true);
	}
	
	private void mousePressedNotLinking(PNode node,PInputEvent e) {
		if (node instanceof PFormalParameter) {
			if (lastParameterEntered == null) 
				mouseEntered(e);
			PFormalParameter param = (PFormalParameter) node;
			if (param.canBeLinkOrigin())
				startParamLink(param);
		}
		else if (node instanceof PModule && e.getClickCount() ==2)
			startModuleLinks(e);
		else if (node instanceof PLinkSelectionTarget) {
			System.err.println("pressiing on target..");
			selectionTarget  = (PLinkSelectionTarget) node;
			linkState = LINK_CHANGING_POINT;
		}
		e.setHandled(true);
	}
	
	private void mousePressedChangingPoint(PNode node,PInputEvent e) {
		if (node instanceof PCamera)  {
			System.err.println("clearing link selection target...");
			linkState = NOT_LINKING;
			if (selectionTarget != null) {
				PLink link = selectionTarget.getLink();
				if (link != null)
					link.setSelected(false);
			}
		} 
		e.setHandled(true);
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
		//	System.err.println("building module links on input side");
			startModuleLinks(inputs);
			moduleLinksStartedAsInputs = true;
		}
		else { 
		//	System.err.println("building module links on output side");
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
		//System.err.println("cancelling module links...");
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
		int key = e.getKeyCode();
		if (key != KeyEvent.VK_DELETE && key != KeyEvent.VK_BACK_SPACE)
			return;
			
		if (selectedLink != null) {
			selectedLink.remove();
			selectedLink = null;
		}
		else if (selectedModule != null) {
			selectedModule.remove();
			selectedModule = null;
		}
		canvas.updateSaveStatus();
	}
	
}