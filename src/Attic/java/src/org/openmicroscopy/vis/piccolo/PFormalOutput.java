/*
 * org.openmicroscopy.vis.piccolo.PFormalOutput
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
import org.openmicroscopy.vis.ome.Connection; 
import org.openmicroscopy.SemanticType;
import edu.umd.cs.piccolo.util.PBounds;
import java.util.ArrayList;



/** 
 * Nodes for displaying Formal Outputs
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PFormalOutput extends PFormalParameter {
	
	public PFormalOutput(PModule node,FormalParameter param,
		Connection connection) {
		super(node,param,connection);
		if (param.getSemanticType() != null)
			connection.addOutput(param.getSemanticType(),this);
		addTarget();
		updateBounds();  
	}
		
	/**
	 * Overrides call in {@link PNode} to right-align
	 * the text node and the type node
	 */	
	protected void layoutChildren() {
		if (typeNode != null) {
			//set type node offset. 
			PBounds typeBounds = typeNode.getFullBounds();
			//typeNode.localToParent(typeBounds);
			PBounds textBounds = textNode.getFullBounds();
			//textNode.localToParent(textBounds);
			
			if (textBounds.getWidth() > typeBounds.getWidth()) {
				double right = textBounds.getX()+textBounds.getWidth();
				int left = (int) (right - typeBounds.getWidth());
				typeNode.setOffset(left,TYPE_NODE_VERTICAL_OFFSET);
				textNode.setOffset(0,0);
			}
			else { // type is wider
				double right = typeBounds.getX()+typeBounds.getWidth();
				int left  = (int) (right- textBounds.getWidth());
				textNode.setOffset(left,0);
				typeNode.setOffset(0,TYPE_NODE_VERTICAL_OFFSET);
			}
		}
		setTargetPosition();
		updateBounds();
	}
	
	protected float getLinkTargetX() {
		PBounds b = labelNode.getFullBoundsReference();
		return (float) (b.getX()+b.getWidth());
	}
	
	/**
	 * For outputs, the corresponding list is a list of ModuleInputs.
	 * Find the semantic type of the parameter associated with this widget,
	 * and then ask the canvas for the list of inputs with that semantic type.
	 * 
	 * @return a list of ModuleInputs with the same semantic type as param.  
	 */
 	public ArrayList getCorresponding() {
		SemanticType type = param.getSemanticType();
		if (type == null)
			return null;
		return connection.getInputs(type);
 	}
 	
 	/**
 	 * An output is linked to another parameter if  there is a direct link
 	 * or, if param (an input) has anthing coming in
 	 * 
 	 * @param the second parameter 
 	 * @return true if this parameter is linked to param
 	 */
 	public boolean isLinkedTo(PFormalParameter param) {
 		
 		boolean link = super.isLinkedTo(param);
 		boolean inputLinked = param.isLinkedTo(this);
 		return (link || inputLinked);
 	}
}