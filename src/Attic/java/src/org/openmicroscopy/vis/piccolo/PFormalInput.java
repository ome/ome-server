/*
 * org.openmicroscopy.vis.piccolo.PFormalInput
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

import org.openmicroscopy.Module.FormalParameter;
import org.openmicroscopy.SemanticType;
import org.openmicroscopy.vis.ome.Connection;
import edu.umd.cs.piccolo.util.PBounds;
import java.util.ArrayList;


/**
 * Nodes for displaying Formal Inputs to OME Modules
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.0
 */
public class PFormalInput extends PFormalParameter {
	
	/**
	 * Layout for the type onde
	 */
	public static final int TYPE_NODE_HORIZ_OFFSET = 0;
	
	public PFormalInput(PModule node,FormalParameter param, 
		Connection connection) {
		super(node,param,connection);
		
		// if I have a semantic type, add it to the lists of inputs with
		// this semantic type.
		
		if (param.getSemanticType()!=null)
			connection.addInput(param.getSemanticType(),this);
	
		if (typeNode != null)
			typeNode.setOffset(TYPE_NODE_HORIZ_OFFSET,
				PFormalParameter.TYPE_NODE_VERTICAL_OFFSET);	
	
		addTarget();
		updateBounds();
	}
	
	protected float getLinkTargetX() {
		PBounds b = labelNode.getFullBoundsReference();
		return (float) (b.getX() -PConstants.LINK_TARGET_SIZE);
	}
	
	
	/**
	 * For inputs, the corresponding list is a list of ModuleOutputs.
	 * Find the semantic type of the parameter associated with this widget,
	 * and then ask the canvas for the list of outputs with that semantic type.
	 * 
	 * @return a list of ModuleOutputs with the same semantic type as param.  
	 */
	public ArrayList getCorresponding() {
		SemanticType type = param.getSemanticType();
		if (type == null) 
			return null;
		
		return connection.getOutputs(type);
	}
	
	/**
	 * 
	 * any given input can only be connected to one output 
	 * (can't have values coming to an input from multiple places).
	 *
	 * @return true if this parameter is linked to anything at all. 
	 */
	public boolean isLinkedTo(PFormalParameter param) {
		return (linkedTo.size() > 0);
	}
	
	/**
	 * An input can only be an origin if there's noting linked to it.
	 * @return true if this paramter can be the origin of a new link. 
	 */ 
	public boolean canBeLinkOrigin() {
		return (linkedTo.size() == 0);
	}
}