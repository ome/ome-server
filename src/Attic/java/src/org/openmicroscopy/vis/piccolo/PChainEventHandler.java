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
 * linkage between inputs and outputs. (5) Zooming of the canvas. (6) Dragging 
 * internal points of a link, in order to change the actual path taken by the 
 * link.
 * 
 * In some cases we might prefer to do this via several small handlers. 
 * However, complexity and communication requirements make it better to do this 
 * all in one place. This is particularly true for goal (4), above, as 
 * a single handler allows us to easily communicate the identity of _both_ ends 
 * in a click-drag interaction.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PChainEventHandler extends  PPanEventHandler {
	
	/**
	 * This handler can be viewed as a state machine, with differing
	 * behavior dependent on the current state. 
	 */
	/**
	 * The user is currently not in a state that involves creation of a link 
	 * between two sets of paramters or two sets of modules.
	 */
	private static final int NOT_LINKING=1;
	/**
	 * The user is creating a link between two parameters.
	 */
	private static final int LINKING_PARAMS=2;
	
	/**
	 * The user is creating links between all matching parameters on two 
	 * modules.
	 */
	private static final int LINKING_MODULES=3;
	
	/** 
	 * The user is cancelling a link creation that is in process.
	 * 
	 */
	private static final int LINKING_CANCELLATION=4;
	
	/**
	 * The user is modifying an internal point in a link.
	 */
	private static final int LINK_CHANGING_POINT=5;

	
	/**
	 * The distance between links when multiple links between two modules
	 * are created.
	 */
	private static final int SPACING=6;
	
	/**
	 * Initially, the user is NOT_LINKING
	 */
	private int linkState = NOT_LINKING;
	
	/**
	 * The last parameter node and last module node that we entered
	 */
	private PFormalParameter lastParameterEntered;
	private PModule lastModuleEntered;
	
	/**
	 * The {@link PLinkSelectionTarget} that was selected to start the 
	 * process of modifying an internal point of a {@link PLink}
	 */
	private PLinkSelectionTarget selectionTarget;
	
	/** 
	 * The {@link PLayer} holding the links.
	 */
	private PLinkLayer linkLayer;
	
	/**
	 * The start of the a link in progress
	 */
	private Point2D.Float linkStart = new Point2D.Float();
	
	/**
	 * The origin of a link that is being created
	 */
	private PFormalParameter linkOrigin;
	
	/**
	 * The link that the user just clicked on to select
	 */ 
	private PLink selectedLink = null;
	
	/**
	 * The link that is currently being created
	 */
	private PParamLink link;
	
	/**
	 * When multiple links are being created, a list of the links in progress
	 */
	private Vector links = new Vector();
	
	/**
	 * The currently selected module
	 */
	private PModule selectedModule;
	
	/**
	 * The parameters that are part of a link between modules.
	 */
	private Collection activeModuleLinkParams;
	
	/**
	 * True if linkage betwen modules started from the formal inputs from one
	 * of the modules.
	 */
	private boolean moduleLinksStartedAsInputs = false;
	
	/**
	 * A filter for the mouse events of interest
	 */
	protected int allButtonMask = MouseEvent.BUTTON1_MASK |
					MouseEvent.BUTTON2_MASK | MouseEvent.BUTTON3_MASK;
	
	/**
	 * The {@link PCanvas} of interest
	 */
	private PChainCanvas canvas;
	
	/**
	 * This flag is set to be true immediately after a popup menu event, and
	 * is cleared immediately after that
	 */
	private boolean postPopup= false;
	
	
	public PChainEventHandler(PChainCanvas canvas,PLinkLayer linkLayer) {
		super();
		
		this.canvas = canvas;
		this.linkLayer = linkLayer;
		PInputEventFilter filter =getEventFilter();
		filter.acceptEverything();
		setEventFilter(filter);
		canvas.getRoot().getDefaultInputManager().
			setKeyboardFocus(this);
		setAutopan(false);		
	}
	
	/**
	 * There are three cases for handling drag events:
	 * 1. If the drag event occurs on a module node, translate it. 
	 * 2. If we are modifying a link, and the drag event is on a {@link
	 *     PLinkSelectionTarget}, translate that target
	 * 3. If we're not on a {@link PFormalParameter}, call super.drag() and 
	 * 	   set the event to be handled.
	 * Otherwise, pass on the event.
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
	 * If we've entered a parameter node, store it as the 
	 * "lastParameterEntered", to track the last parameter that the mouse 
	 * was in. If the handler's state is NOT_LINKING, this is a generic mouse
	 * over, so turn off all of the highlights for the module for that paraemter
	 * (this is needed to avoid leaving anything on from previous state),
	 * and turn on the highlighting for this parameter.
	 * 
	 * If we've entered a module andstate is NOT_LINKING, set the highlights
	 * for the module to be true
	 * 
	 * In general, we leave highlighting on while linking, in order to maintain
	 * the cues that the highlighting provides.
	 * 
	 * Otherwise, call the superclas shandler. 
	 
	 * 
	 */
	public void mouseEntered(PInputEvent e) {
		PNode node = e.getPickedNode();
		
		if (node instanceof PFormalParameter) {
			lastParameterEntered = (PFormalParameter) node;
			//System.err.println("mouse entered last entered.."+
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
	 * 
	 * As always, leave highlighting on if a link is being created. 
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
	
	
	/**
	 * mouseDragged() behavior is equivalent to mouseMoved() behavior.
	 */
	public void mouseDragged(PInputEvent e) {
	//	System.err.println("CHAIN HANDLER:got a drag event in chain canvas");
		mouseMoved(e);
		super.mouseDragged(e);
	}
	
	/**
	 * Two behaviors if the mouse is moved:
	 * 1) if the state is linking parameters, add a point to the link in progress
	 * 2) if the state is LINKING_MODULES, add a point to all of the links that 
	 * 		are in progress.
	 */
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
	
	/**
	 * Cases for mouse clicks:
	 * 
	 * 1) if the state is somethiung other than NOT_LINKING, ignore the event,
	 *  	possibly resetting state to NOT_LINKING
	 * 2) If {@link postPopup} is true, this click is the "residue" of a popup 
	 * 		mouse click. In this case, clear the flag and ignore the event.
	 * 3) Otherwise, zoom in one of three ways:
	 * 	a) If the shift key is down, center the canvas contents in the window
	 *  b) If the control key is down, or it's a right click, zoom out
	 *  c) Otherwise zoom in.
	 */
	public void mouseClicked(PInputEvent e) {
		// we only scale if we're not drawing a link.
		if (linkState != NOT_LINKING) {
			if (linkState == LINKING_CANCELLATION)
				linkState = NOT_LINKING;
			e.setHandled(true);
			return;
		}
		
		if (postPopup == true) {
			postPopup = false;
			e.setHandled(true);
			return;
		}
		
		PNode node = e.getPickedNode();
		int mask = e.getModifiers() & allButtonMask;
		if (! (node instanceof PCamera))
			return;
		
		if (e.isShiftDown()) {
			PBounds b = canvas.getBufferedBounds();
			canvas.getCamera().animateViewToCenterBounds(b,true,PConstants.ANIMATION_DELAY);
			e.setHandled(true);
		}
		else {
			double scaleFactor = PConstants.SCALE_FACTOR; 
			if (e.isControlDown() || ((mask & MouseEvent.BUTTON3_MASK)==1)) {
				scaleFactor = 1/scaleFactor;
			}
			zoom(scaleFactor,e);
			e.setHandled(true);
		}  
	} 
	
	/***
	 * Adjust the magnification around the point of the {@link PInputEvent}.
	 * @param scale how much to zoom
	 * @param e the event leading to the zoom
	 */
	private void zoom(double scale,PInputEvent e) {
		PCamera camera=canvas.getCamera();
		double curScale = camera.getScale();
		curScale *= scale;
		Point2D pos = e.getPosition();
		camera.scaleViewAboutPoint(curScale,pos.getX(),pos.getY());
		e.setHandled(true);
	}

	
	/***
	 * Several cases of what to do when we have a mouse pressed event
	 * 1) If it's a popup event, handle it and return
	 * 2) Clear out selectedLink, selectedModule, and selctionTarget if they
	 * 	are not null.
	 * 3) Call special purpose handlers based on the type of node set
	 * 4) Call handlers based on the current state. 
	 * 
	 * Thus, in the general case, two handlers may be callsed - one for the 
	 * type of node, and another for the current state
	 */
	public void mousePressed(PInputEvent e) {
		
		if (e.isPopupTrigger()) {
			//System.err.println("mouse pressed..");
			evaluatePopup(e);
			return;
		}
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
	
	/**
	 * If the press is on a link, and I'm not already in the process of 
	 * changing a link, make this link the newly selected link
	 * @param node
	 */
	private void mousePressedLink(PNode node) {
		if (linkState != LINK_CHANGING_POINT) {
			selectedLink = (PLink) node;
			selectedLink.setSelected(true);
			linkState = NOT_LINKING;
		}
	}
	
	/**
	 * If the mouse event is on a module, set it to be selected and add
	 * handles.
	 * @param node
	 */
	private void mousePressedModule(PNode node) {
		selectedModule = (PModule) node;
		selectedModule.addHandles();
	}
	
	/**
	 * If the press is on a {@link PLinkSelectionTarget}, set the selection
	 * target and set the associated link to be selected.
	 * @param node the node that was pressed
	 */
	private void mousePressedSelectionTarget(PNode node) {
		System.err.println("pressing on selection target..");
		selectionTarget = (PLinkSelectionTarget) node;
		selectionTarget.getLink().setSelected(true);
		linkState = LINK_CHANGING_POINT;
	}
	
	/** 
	 * If the mouse was pressed while parameters were being linked, there are 
	 * three possibilities:
	 * 	1) if the press was  double click, the link should be cancelled.
	 *  2) if the mouse press occurred on the canvas, add a point to the link.
	 *  3) If the mouse is in a formal parameters, finish the link.
	 * @param node the link that for the pressed event
	 * @param e the pressed event
	 */
	private void mousePressedLinkingParams(PNode node,PInputEvent e) {
		if (e.getClickCount() ==2) {
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
	
	/**
	 * If the mouse is presed while modules are being linked,
	 * Start by checking the number of clicks. If there are two, 
	 * finish the links if the target node is either a formal parameter or a 
	 * module.
	 * Otherwise, if the click is on the {@link PCamera}, add a point to each
	 * of the links that are in progress.
	 * 
	 * @param node the target of the mouse press
	 * @param e the mouse press event
	 */
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
	
	/**
	 * If the mouse is pressed while the state is NOT_LINKING, adjust 
	 * the highlights if needed, and start a link if appropriate. 
	 * If the target is a module and the user double-clicked, start module 
	 * links. These are the links that go between all possible inputs and 
	 * outputs for a pair of modules.
	 * 
	 * 
	 * Otherwise, if the target is a {@link PLinkSelectionTarget}, set 
	 * the state to be LINK_CHANGING_POINT.
	 * 
	 * @param node
	 * @param e
	 */
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
	
	/**
	 * If the mouse is pressed while the point is being changed, clear the 
	 * currently selected link if appropriate.
	 *  
	 * @param node
	 * @param e
	 */
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
	
	/***
	 * Start a new link between parameters
	 * @param param the origin of the new link
	 */
 	private void startParamLink(PFormalParameter param) {
		//System.err.println("mouse pressing and starting link");
		linkOrigin = param;
		link = new PParamLink();
		linkLayer.addChild(link);
		link.setStartParam(linkOrigin);
		link.setPickable(false);
		linkState = LINKING_PARAMS;			
 	}
		
	/**
	 * End the link curently in process at the link denoted by
	 * {@link lastParameterEntered}.
	 *
	 */
	private void finishParamLink() {
		if (lastParameterEntered.isLinkable() == true) {
			//System.err.println("finishing link");
			link.setEndParam(lastParameterEntered);
			link.setPickable(true);
			// add the {@link PModuleLink} between the modules
			linkLayer.completeLink(link);
			cleanUpParamLink();
		}
		else {
			//////System.err.println("trying to finish link, but end point is not linkable");
			cancelParamLink();
		}
		linkState = NOT_LINKING;
	}
	
	/**
	 * Cancel a lnk between parameters
	 *
	 */
	private void cancelParamLink() {
		//System.err.println("canceling link");
		link.removeFromParent();
		link =null;
		cleanUpParamLink();
	}
	
	/***
	 * Final cleanup of a parameter link. Called after {@link finishParamLink()}
	 * and {@link cancelParamLink()}
	 * 
	 *
	 */
	private void cleanUpParamLink() {
		linkOrigin.setParamsHighlighted(false);
		linkOrigin = null;
		lastParameterEntered = null;
	}
	
	/**
	 * Start all of the links between two modules. Identify which side the event
	 * was on (input and output), get the list of parameters associated with
	 * the start event, set moduleLinksStartedAsInputs to be true if appropriate,
	 * adn call {@link startModuleLinks}
 	 * @param e the mouse event that starts the links.
	 */
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
	
	/**
	 * To start module links for a list of parameters, iterate over the list, 
	 * creating a new PParamLink for each, and taking care of other bookkeeping
	 * @param params
	 */
	private void startModuleLinks(Collection params) {
		activeModuleLinkParams = params;
	
		Iterator iter = params.iterator();
		while (iter.hasNext()) {
			PFormalParameter param = (PFormalParameter) iter.next();
			PParamLink link = new PParamLink();
			linkLayer.addChild(link);
			link.setStartParam(param);
			link.setPickable(false);
			links.add(link);
		}
	}
	
	/** 
	 * to finis the links between modules, get the corresponding parameters for 
	 * the current module, and call finishModuleLinks on that list.
	 * @param mod
	 */
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
	
	/**
	 * Iterate through the list of end parameters and finish off each of the 
	 * links
	 * 
	 * @param targets the end points of the links in progress.
	 */
	public void finishModuleLinks(Collection targets) {
		// ok, for each thing in the initial params, finish 
		//this link against targets
		Iterator iter = links.iterator();
		while (iter.hasNext()) {
			PParamLink lnk = (PParamLink) iter.next();
			finishAModuleLink(lnk,targets);
		}
	}	
	
	/**
	 * To finish a module link, find the items in the target list that has the
	 * right semnatic type and complete the link. If there is no match, 
	 * remove the link
	 * @param link the link to be completed
	 * @param targets the list of potential endpoints
	 */
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
				return;
			}
		}
		// no matches. remove it.
		start.setParamsHighlighted(false);
		link.removeFromParent();
	}
	
	/**
	 * Cancel a set of module links in progress
	 *
	 */
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
	
	/**
	 * Bookkeeping clean-up after module links are finished or cancelled
	 *
	 */
	public void cleanUpModuleLink() {
		Iterator iter = activeModuleLinkParams.iterator();
		while (iter.hasNext()) {
			PFormalParameter origin = (PFormalParameter) iter.next();
			origin.setParamsHighlighted(false);
		}
		links = new Vector();
	}
	
	/** 
	 * A mouse-released event might indicate a popup event
	 */
	public void mouseReleased(PInputEvent e) {
		if (e.isPopupTrigger()) {
			System.err.println("mouse released");
			evaluatePopup(e);
		}
	}
	
	/**
	 * When a popup event occurs, call {@link zoom()} to zoom out one step.
	 * Also, set the {@link postPopup} flag to be true. This is needed to make 
	 * sure that any mouse clicks that also get executed do not get processed:
	 * they are artifactual and should be ignored.
	 *  
	 * @param e
	 */
	private void evaluatePopup(PInputEvent e) {
		//System.err.println("popup event"+e);
		double scaleFactor = 1/PConstants.SCALE_FACTOR;
		zoom(scaleFactor,e);
		e.setHandled(true);
		postPopup=true;
	}
	
	/** 
	 * If the user presses back-space or delete, delete the selected module 
	 * and/or link.
	 */
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