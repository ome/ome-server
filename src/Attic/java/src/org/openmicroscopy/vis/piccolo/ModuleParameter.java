/*
 * org.openmicroscopy.vis.piccolo.ModuleParameter
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
import edu.umd.cs.piccolox.util.PBoundsLocator;
import org.openmicroscopy.remote.RemoteModule.FormalParameter;
import org.openmicroscopy.SemanticType;
import javax.swing.event.EventListenerList;
import java.awt.Color;
import java.util.ArrayList;
import java.util.Vector;

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


public abstract class ModuleParameter extends PText implements 
	NodeEventListener{
	
	protected static final Color NORMAL_COLOR = Color.black;
	protected static final Color HIGHLIGHT_COLOR = Color.magenta;
	
	
	protected FormalParameter param;
	protected ChainCanvas canvas=null;
	protected ModuleNode node;
	private  Vector linkedTo = new Vector(); 
	
	// We assume a model that has Modules in a box, with inputs on
	// the left and outputs on the right. Thus, for inputs, the locator
	// will be on the west, and outputs will have the locator on the east.
	
	protected PBoundsLocator locator;
	protected boolean linkable;
	
	public ModuleParameter() {
		super();
	}
	
	public ModuleParameter(String s) {
		super(s);
	}
	
	public ModuleParameter(FormalParameter param) {
		super(param.getParameterName());
		this.param = param;
	}
	
	public ModuleParameter(ModuleNode node,FormalParameter param,
			ChainCanvas canvas) {
		super(param.getParameterName());
		this.canvas = canvas;
		this.param = param;
		this.node = node;
		node.addNodeEventListener(this);
	}
	
	public String getName() {
		return param.getParameterName();
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
			setPaint(HIGHLIGHT_COLOR);
		else
			setPaint(NORMAL_COLOR);
		repaint();
	}
	
	public boolean isLinkable() {
		return linkable;
	}
	
	
	public SemanticType getSemanticType() {
		return param.getSemanticType();
	}
	
	public ChainCanvas getCanvas() {
		return canvas;
	}
	
	public PBoundsLocator getLocator() {
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
	public void nodeChanged(NodeEvent e) {
		
		// if I'm listening to a node, and it's a parent, pass 
		// it along to whomever is listening to me.
		PNode node = e.getNode();
		if (isDescendentOf(node)) {
			fireStateChanged();
		}
	}
	
	
	private EventListenerList listenerList =
		new EventListenerList();
	
	public void addNodeEventListener(NodeEventListener nel) {
		listenerList.add(NodeEventListener.class,nel);
	}

	public void removeNodeEventListener(NodeEventListener nel) {
		listenerList.remove(NodeEventListener.class,nel);
	}
		
	public void fireStateChanged() {
		Object[] listeners  = listenerList.getListenerList();
		for (int i = listeners.length-2; i >=0; i -=2) {
			if (listeners[i]==NodeEventListener.class) {
				((NodeEventListener)listeners[i+1]).nodeChanged(
					new NodeEvent(this));
			}
		}
	}

	public ModuleNode getModuleNode() {
		return node;
	}
	
	public void setLinkedTo(ModuleParameter param) {
		linkedTo.add(param);
	}
	
	public void clearLinkedTo(ModuleParameter param) {
		linkedTo.remove(param);
	}
	
	public boolean isLinkedTo(ModuleParameter param) {
		return (linkedTo.indexOf(param)!=-1);
 	}
}