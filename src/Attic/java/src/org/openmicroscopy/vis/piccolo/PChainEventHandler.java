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
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PNode;
import java.awt.geom.Dimension2D;
import java.awt.geom.Point2D;
import java.util.Iterator;
import java.util.ArrayList;
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
	private PLayer linkLayer;
	
	private PLink link;
	private Point2D.Float linkStart = new Point2D.Float();
	private static final int NOT_LINKING=1;
	private static final int LINKING_FIRST_POINT=2;
	private static final int LINKING_SUBSEQUENT_POINTS=2;
	private int linkState = NOT_LINKING;
	
	private PFormalParameter linkOrigin;
	
	private PLink selectedLink = null;
	
	public PChainEventHandler(PChainCanvas canvas,PLayer linkLayer) {
		super();
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
		
		// module nodes simply get translated.
		if (node instanceof PModule) {
			PModule mn = (PModule) node;
			Dimension2D delta = e.getDeltaRelativeTo(node);
			node.translate(delta.getWidth(),delta.getHeight());
			e.setHandled(true);
		}
		else if (!(node instanceof PFormalParameter)){
			// otherwise default handling, if it's not a parameter node.
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
		//	System.err.println("mouse entered last entered.."+
			//	lastParameterEntered.getName());
			if (linkState == NOT_LINKING) {
				setParamsHighlighted(lastParameterEntered,true);	
			}
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
		if (node instanceof PFormalParameter && linkState == NOT_LINKING) {
			setParamsHighlighted((PFormalParameter) node,false);			
			//lastParameterEntered = null;
		}
		else
			super.mouseExited(e);
	}
	
	
	
	public void mouseDragged(PInputEvent e) {
		mouseMoved(e);
		super.mouseDragged(e);	
	}
	
	public void mouseMoved(PInputEvent e) {
		if (linkState != NOT_LINKING) {
			Point2D pos = e.getPosition();
			link.setEndCoords((float) pos.getX(),(float) pos.getY());
		}
	}
	
	public void mousePressed(PInputEvent e) {
		PNode node = e.getPickedNode();
		
		System.err.println("mouse pressed on "+node);
		
		if (!(node instanceof PLink) && selectedLink != null) {
			selectedLink.setSelected(false);
			selectedLink = null;
		}
		
		if (node instanceof PFormalParameter && linkState == NOT_LINKING) {
	//		System.err.println("starting a new link");
			if (lastParameterEntered == null)
				mouseEntered(e);
			PFormalParameter param = (PFormalParameter) node;
			startLink(param);
			e.setHandled(true);
		}
		else if (node instanceof PLink) {
			System.err.println("pressed on link");
			if (selectedLink != null) {
				selectedLink.setSelected(false);
				selectedLink = null;
			}
			selectedLink = (PLink) node;
			selectedLink.setSelected(true);	
		}
		else if (linkState != NOT_LINKING) {
			if (e.getClickCount() ==2)
				cancelLink();
			else if (lastParameterEntered != null)
				finishLink();
			/*else { assume all links have one end point and one start point
				System.err.println("extending link");
				Point2D pos = e.getPosition();
				link.addIntermediate((float) pos.getX(),(float) pos.getY());
			}*/
			e.setHandled(true);
		}
		//else
		//	super.mousePressed(e);
	}
		
 	private void startLink(PFormalParameter param) {
		System.err.println("mouse pressing and starting link");
		linkOrigin = param;
		linkOrigin.decorateAsLinkStart(true);
		link = new PLink();
		linkLayer.addChild(link);
		link.setStartParam(linkOrigin);
		link.setPickable(false);
		linkState = LINKING_FIRST_POINT;			
 	}
		
	// this link ends at lastParameterEntered
	private void finishLink() {
		if (lastParameterEntered.isLinkable() == true) {
			System.err.println("finishing link");
			link.setEndParam(lastParameterEntered);
			link.setPickable(true);
			cleanUpLink();
		}
		else
			cancelLink();
		linkState = NOT_LINKING;
	}
	
	private void cancelLink() {
		System.err.println("canceling link");
		link.removeFromParent();
		linkState = NOT_LINKING;
		link =null;
		cleanUpLink();
	}
	
	private void cleanUpLink() {
		setParamsHighlighted(linkOrigin,false);
		linkOrigin.decorateAsLinkStart(false);
		linkOrigin = null;
		lastParameterEntered = null;
	}
	
	
	/** 
	 * To highlight link targets for a given PFormalParameter, get
	 * the list of "corresponding" ModuleParameters, and set each of those 
	 * to be linkable<p>
	 * @param param
	 * @param v
	 */
		
	private void setParamsHighlighted(PFormalParameter param, boolean v) {
			
		ArrayList list = param.getCorresponding();
	
		if (list == null)
			return;
		
		PModule sourceModule = param.getModuleNode();
		
		PFormalParameter p;
		Iterator iter = list.iterator();
		
		PModule destModule;
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			
			if (v == true) {// when making things linkable
				// only make it linkable if we're not linked already
				// and we're not in the same module.
				if (!param.isLinkedTo(p) && sourceModule != p.getModuleNode())
					p.setLinkable(v);
			}
			else // always want to clear linkable
				p.setLinkable(v);		
		}
	}
	
	public void keyPressed(PInputEvent e) {
		System.err.println("a key was pressed ");
		if (selectedLink != null && e.getKeyCode() ==KeyEvent.VK_DELETE) {
			selectedLink.removeFromParent();
			// clear who it's linked to
			selectedLink.clearConnections();
			selectedLink = null;
		}
	}

}