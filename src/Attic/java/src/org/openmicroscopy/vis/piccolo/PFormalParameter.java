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
import edu.umd.cs.piccolo.util.PBounds;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.Module;
import org.openmicroscopy.Module.FormalParameter;

import org.openmicroscopy.SemanticType;
import javax.swing.event.EventListenerList;
import java.util.ArrayList;
import java.util.Vector;
import java.util.Iterator;

import java.awt.geom.Point2D;


/** 
 * Nodes for displaying module inputs and outputs. Currently, all
 * module parameters are displayed as text, with decorations (color) to
 * indicate change of state. For example, the node will be painted in 
 * HIGHLIGHT_COLOR when it is a candidate for a link with another actively
 * selected parameter.<p>
 * 
 * Generally, there will be two subclasses of this class - one for inputs
 * and one for outputs - in other words, {@link PFormalInputs} and 
 * {@link PformalOutputs}.
 * 
 * It's likely that this will become a more complicated widget as the 
 * application evolves.<p>
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 *  
 */


public abstract class PFormalParameter extends PNode implements 
	PNodeEventListener, Comparable {
	
	/**
	 * Some generic display parameters
	 */
	public static final int TYPE_NODE_VERTICAL_OFFSET=12;
	public static final float TYPE_NODE_DEFAULT_SCALE=0.5f;
	
	/**
	 * The OME FormalParameter object that the node represents.
	 */
	protected FormalParameter param;
	
	/**
	 * Connection to the OME database
	 */
	protected Connection connection = null;
	
	/**
	 * The module containing this parameter
	 */
	protected PModule node;
	
	/**
	 * A list of {@link PFormalParameter} object that this one is linked to
	 */
	protected  Vector linkedTo = new Vector();
	
	/**
	 * A list of {@link PLinks} involving this parameter
	 */
	protected Vector links = new Vector();
	 
	 /**
	  * True if a link to this parameter can be added
	  */
	protected boolean linkable;
	
	/**
	 * The name of the parameter
	 */
	protected PText textNode;
	
	/**
	 * The semantic type of the parameter
	 */
	protected PText typeNode;
	
	/**
	 * The {@link PLinkTarget} associated with this parameter
	 */
	protected PLinkTarget target = null;
	
	/**
	 * A node containing the textual labels for the name 
	 * and semantic type
	 */
	protected PNode labelNode;
	
	/**
	 * 
	 * @param node The PModule containing this parameter
	 * @param param The OME Formal Parameter
	 * @param connection the database connection
	 */
	public PFormalParameter(PModule node,FormalParameter param,
			Connection connection) {
		super();
		
		this.connection = connection;
		this.param = param;
		this.node = node;
		
		setChildrenPickable(false);
		labelNode = new PNode();
		addChild(labelNode);
		
		textNode = new PText(param.getParameterName());
		textNode.setFont(PConstants.NAME_FONT);
		textNode.setPaint(PConstants.DEFAULT_TEXT_COLOR);
		labelNode.addChild(textNode);
		
		
		// add a semantic type label only if the type is not null
		SemanticType type = param.getSemanticType();
		if (type != null) {
			typeNode = new PText(type.getName());
			labelNode.addChild(typeNode);
			typeNode.setScale(TYPE_NODE_DEFAULT_SCALE);
			typeNode.setPaint(PConstants.DEFAULT_TEXT_COLOR);
			typeNode.setFont(PConstants.NAME_FONT);
		}						
		
		// this formal parameter will listen to any changes that happen to
		// the node.
		node.addNodeEventListener(this);
		
		
	}

	/**
	 * Add a {@link PLinkTarget}
	 *
	 */	
	protected void addTarget() {
		target = new PLinkTarget();
		addChild(target);
		target.setPickable(false);
		setTargetPosition();
	}
	
	protected void setTargetPosition() {
		PBounds b = labelNode.getFullBoundsReference();
		float x = getLinkTargetX();
		float y = (float) b.getY()+PConstants.LINK_TARGET_BUFFER;
		if (target == null)
			addTarget();
		target.setOffset(x,y);
	}
	
	/**
	 * For inputs, the target is to the left of the text node.
	 * For outptuts, it is on the right. 
	 * @return The x-coordinate of the link target.
	 */
	protected abstract float getLinkTargetX();
	
	public String getName() {
		return param.getParameterName();
	}
	
	public PModule getPModule() {
		return node;
	}
	
	public Module getModule() {
		return getPModule().getModule();
	}
	
	/**
	 * A module parameter is said to be linkable if (1) it has the same
	 * semantic type as a currently selected parameter, and (2) it's position 
	 * (input vs. output) corresponds appropriately to that of the current 
	 * selection. Inputs can only link to outputs, and vice-versa.<p>
	 * 
	 * @param v true if the parameter is linkable.
	 */
	public void setLinkable(boolean v) {
		linkable = v;
		if (v == true) {
			typeNode.setPaint(PConstants.HIGHLIGHT_COLOR);
			textNode.setPaint(PConstants.HIGHLIGHT_COLOR);
		}
		else {
			typeNode.setPaint(PConstants.DEFAULT_TEXT_COLOR);
			textNode.setPaint(PConstants.DEFAULT_TEXT_COLOR);
		}
		getPModule().setLinkableHighlighted(v);
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
	 * Notify objects that are interested in case of changes to the appropriate 
	 * node
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

	/**
	 * Update the state when this paramter is linked to another - 
	 *  add the other parameter, and the {@link PLink} to the appropriate 
	 *  lists, and indicate that the {@link PLinkTarget} is linked 
	 * @param param
	 * @param link
	 */
	public void setLinkedTo(PFormalParameter param,PParamLink link) {
		linkedTo.add(param);
		target.setLinked(true);
		links.add(link);
	}
	
	/**
	 * Inverse of {@link setLinkedTo()}
	 * @param param
	 */
	public void clearLinkedTo(PFormalParameter param) {
		linkedTo.remove(param);
		if (linkedTo.isEmpty())
			target.setLinked(false);
		target.setSelected(false);
	}
	
	/**
	 * This parameter is linked to another if the other is in this
	 * parameter's list of parameters that it is linked to
	 * @param param
	 * @return true if this parameter is linked to param, else false.
	 */
	public boolean isLinkedTo(PFormalParameter param) {
		return (linkedTo.indexOf(param)!=-1);
 	}
 	
 	
 	
 	public void removeLinks() {
 		PParamLink link;
 		Iterator iter = links.iterator();
 		while (iter.hasNext()) {
 			link = (PParamLink)iter.next();
 			link.remove();
 		}
 		links = new Vector();
 		linkedTo = new Vector();
 	}
 	
	/** 
	 * To highlight link targets for a given PFormalParameter, get
	 * the list of "corresponding" ModuleParameters (ie, inputs if this is 
	 * an output, and outputs if this is the input) of the same type, 
	 * and set each of those to be linkable<p>
	 *
	 * @param v
	 */
		
	public void setParamsHighlighted(boolean v) {
			
		ArrayList list = getCorresponding();
	
		if (list == null)
			return;
		
		
	 	Module source = getModule();
		
		PFormalParameter p;
		Iterator iter = list.iterator();
		
		while (iter.hasNext()) {
			p = (PFormalParameter) iter.next();
			
			if (v == true) {// when making things linkable
				// only make it linkable if we're not linked already
				// and we're not in the same module.
				if (!isLinkedTo(p) && source != p.getModule())
						p.setLinkable(v);
			}
			else // always want to clear linkable
				p.setLinkable(v);		
		}
	}

	/**
	 * Set the bounds to include the {@link PLinkTarget}
	 *
	 */
	public void updateBounds() {
		PBounds b = labelNode.getFullBounds();
		b.add(target.getFullBounds());
 		setBounds(new PBounds(b.getX(),b.getY(),b.getWidth(),
			b.getHeight()+PModule.PARAMETER_SPACING)); 
	}

	/**
	 * 
	 * By default, a parameter can be the origin of a link.	
	 */
	public boolean canBeLinkOrigin() {
		return true;
	}
	
	public float getLabelWidth() {
		return (float) labelNode.getFullBoundsReference().getWidth();	
	}
	
	public Point2D getLinkCenter() {
		PBounds b = target.getFullBoundsReference();
		float x = (float) (b.getX()+b.getWidth()/2);
		float y = (float) (b.getY()+b.getHeight()/2);
		Point2D.Float result = new Point2D.Float(x,y);
		localToGlobal(result);
		return result;
	}
	
	public PLinkTarget getLinkTarget() {
		return target;
	}
	
	/**
	 * {@link PFormalParameter} instances are placed on a {@link PModule}
	 * ordered by semantic type ID. This procedure implementes the 
	 * {@link Comparable} interface, so we can do the necessary sorting.  
	 */
	public int compareTo(Object o) {
		if (!(o instanceof PFormalParameter))
			return -1;
		PFormalParameter other =(PFormalParameter) o;
		
		// defaults
		int myID=-1;
		int otherID =-1;
		
		SemanticType myType = getSemanticType();
		if (myType != null)
			myID = myType.getID();
		SemanticType otherType = other.getSemanticType();
		if (otherType != null)
			otherID = otherType.getID();
		int diff =  myID-otherID;
		
		// if they're different, return this result
		if (diff != 0)
			return diff;
			
		// else, semantic types are the same, order by Ids.
		myID  = getParameter().getID();
		otherID = other.getParameter().getID();

		return (myID-otherID);
	}
}