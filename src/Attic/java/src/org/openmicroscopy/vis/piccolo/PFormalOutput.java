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
import javax.swing.SwingConstants;
import java.util.ArrayList;

/** 
 * Nodes for displaying module outputs.<p>
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PFormalOutput extends PFormalParameter {
	
	public PFormalOutput(PModule node,FormalParameter param,
		Connection connection) {
		super(node,param,connection);
		if (param.getSemanticType() != null)
			connection.addOutput(param.getSemanticType(),this);
		locator = new PParameterLocator(this,SwingConstants.EAST);
		updateBounds();  
	}
	
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
		updateBounds(); 
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
 	
 	public boolean isLinkedTo(PFormalParameter param) {
 		// i'm an output. so, I'm linked to param if
 		// 1) there is a direct link
 		boolean link = super.isLinkedTo(param);
 		// 2) or, param (an input) has anthing coming in
 		boolean inputLinked = param.isLinkedTo(this);
 		return (link || inputLinked);
 	}
}