/*
 * org.openmicroscopy.vis.piccolo.PFormalParameter
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

import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.PNode;
//import edu.umd.cs.piccolo.PRoot;
import edu.umd.cs.piccolo.util.PPaintContext;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.ome.ModuleInfo;
import org.openmicroscopy.remote.RemoteModule.FormalParameter;
import org.openmicroscopy.SemanticType;
import javax.swing.event.EventListenerList;
import java.awt.Color;
import java.util.ArrayList;
import java.util.Vector;
import java.util.Iterator;
import java.awt.Graphics2D;

/** 
 * Nodes for displaying module inputs and outputs. Currently, all
 * module parameters are displayed as text, with decorations (color) to
 * indicate change of state. For example, the node will be painted in 
 * HIGHLIGHT_COLOR when it is a candidate for a link with another actively
 * selected parameter.<p>
 * 
 * Generally, there will be two subclasses of this class - one for inputs
 * and one for outputs.<p>
 * 
 * It's likely that this will become a more complicated widget as the 
 * application evolves.<p>
 * 
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */


public abstract class PFormalParameter extends PNode implements 
	PNodeEventListener{
	
	public static final Color NORMAL_COLOR = Color.black;
	public  static final Color HIGHLIGHT_COLOR = PModule.HIGHLIGHT_COLOR;
	
	
	protected FormalParameter param;
	protected Connection connection = null;
	protected PModule node;
	protected  Vector linkedTo = new Vector();
	protected Vector links = new Vector(); 
	
	
	// We assume a model that has Modules in a box, with inputs on
	// the left and outputs on the right. Thus, for inputs, the locator
	// will be on the west, and outputs will have the locator on the east.
	
	protected PParameterLocator locator;
	protected boolean linkable;
	
	private PText textNode;
	
	private boolean isLinkStart;
	
	public PFormalParameter() {
		super();
	}
	
	public PFormalParameter(FormalParameter param) {
		super();
		textNode = new PText(param.getParameterName());
		addChild(textNode);
		setChildrenPickable(false);
		setBounds(textNode.getFullBounds());
		//super(param.getParameterName());
		this.param = param;
	}
	
	public PFormalParameter(PModule node,FormalParameter param,
			Connection connection) {
		textNode = new PText(param.getParameterName());
		addChild(textNode);
		setChildrenPickable(false);
		setBounds(textNode.getFullBounds());			
		//super(param.getParameterName());
		this.connection = connection;
		this.param = param;
		this.node = node;
		node.addNodeEventListener(this);
	}
	
	public String getName() {
		return param.getParameterName();
	}
	
	public PModule getPModule() {
		return node;
	}
	
	public ModuleInfo getModuleInfo() {
		return getPModule().getModuleInfo();
	}
	
	/**
	 * A module parameter is said to be linkable if (1) it has the same
	 * semantic type as a currently selected parameter, and (2) it's position 
	 * (input vs. output) corresponds appropriately to that of the current 
	 * selection. Inputs can only link to outputs, and vice-versa.<p>
	 * 
	 * @param v
	 */
	public void setLinkable(boolean v) {
		linkable = v;
		if (v == true)
			textNode.setPaint(HIGHLIGHT_COLOR);
		else
			textNode.setPaint(NORMAL_COLOR);
		repaint();
	}
	
	public boolean isLinkable() {
		return linkable;
	}
	
	
	public FormalParameter getParameter() {
		return param;
	}
	
	public SemanticType getSemanticType() {
		return param.getSemanticType();
	}
	
	
	public PParameterLocator getLocator() {
		return locator;
	}
	
	
	/**
	 * Get a list of parameters that have the same semantic type
	 * as this one, but in the opposite position. If this is an input(output),
	 * get all of the outputs(inputs) with the same semantic type.<p>
	 * 
	 * @return A list of FormalParameters of the appropriate type and 
	 * 	corresponding position.
	 */
	public abstract ArrayList getCorresponding();

	/**
	 * some event handling code
	 */
	public void nodeChanged(PNodeEvent e) {
		
		// if I'm listening to a node, and it's a parent, pass 
		// it along to whomever is listening to me.
		PNode node = e.getNode();
		if (isDescendentOf(node)) {
			fireStateChanged();
		}
	}
	
	
	private EventListenerList listenerList =
		new EventListenerList();
	
	public void addNodeEventListener(PNodeEventListener nel) {
		listenerList.add(PNodeEventListener.class,nel);
	}

	public void removeNodeEventListener(PNodeEventListener nel) {
		listenerList.remove(PNodeEventListener.class,nel);
	}
		
	public void fireStateChanged() {
		Object[] listeners  = listenerList.getListenerList();
		for (int i = listeners.length-2; i >=0; i -=2) {
			if (listeners[i]==PNodeEventListener.class) {
				((PNodeEventListener)listeners[i+1]).nodeChanged(
					new PNodeEvent(this));
			}
		}
	}

	
	public void setLinkedTo(PFormalParameter param,PLink link) {
		linkedTo.add(param);
		links.add(link);
	}
	
	public void clearLinkedTo(PFormalParameter param) {
		linkedTo.remove(param);
	}
	
	public boolean isLinkedTo(PFormalParameter param) {
		return (linkedTo.indexOf(param)!=-1);
 	}
 	
 	public void decorateAsLinkStart(boolean v) {
 		isLinkStart = v;
 		repaint();
 	}
 	
 	public void paint(PPaintContext aPaintContext) {
 		super.paint(aPaintContext);
 		if (isLinkStart) {
 			Graphics2D g = aPaintContext.getGraphics();
			g.setPaint(HIGHLIGHT_COLOR);
			g.draw(textNode.getBounds());
 		}
 	}
 	
 	public void removeLinks() {
 		PLink link;
 		Iterator iter = links.iterator();
 		while (iter.hasNext()) {
 			link = (PLink)iter.next();
 			link.remove();
 		}
 		links = new Vector();
 		linkedTo = new Vector();
 	}
 	
	/** 
	 * To highlight link targets for a given PFormalParameter, get
	 * the list of "corresponding" ModuleParameters, and set each of those 
	 * to be linkable<p>
	 *
	 * @param v
	 */
		
	public void setParamsHighlighted(boolean v) {
			
		ArrayList list = getCorresponding();
	
		if (list == null)
			return;
		
		System.err.println("got the corresponding inputs for a parameter..");
	 	ModuleInfo source = getModuleInfo();
		
		PFormalParameter p;
		Iterator iter = list.iterator();
		
		PModule destModule;
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			
			if (v == true) {// when making things linkable
				// only make it linkable if we're not linked already
				// and we're not in the same module.
				if (!isLinkedTo(p) && source != p.getModuleInfo())
						p.setLinkable(v);
			}
			else // always want to clear linkable
				p.setLinkable(v);		
		}
	}
}