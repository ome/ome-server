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

import org.openmicroscopy.remote.RemoteModule.FormalParameter;
import org.openmicroscopy.SemanticType;
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
	
	public PFormalOutput(PModule node,FormalParameter param,PChainCanvas canvas) {
		super(node,param,canvas);
		if (param.getSemanticType() != null)
			canvas.addOutput(param.getSemanticType(),this);
		locator = new PParameterLocator(this,SwingConstants.EAST);
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
		return canvas.getInputs(type);
 	}
}