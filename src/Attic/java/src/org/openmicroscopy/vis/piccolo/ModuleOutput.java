/*
 * org.openmicroscopy.vis.piccolo.ModuleOutput
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
import edu.umd.cs.piccolox.util.PBoundsLocator;
import java.util.ArrayList;

public class ModuleOutput extends ModuleParameter {
	
	public ModuleOutput(FormalParameter param,ChainCanvas canvas) {
		super(param,canvas);
		//System.err.println("adding output "+param.getParameterName());
		if (param.getSemanticType() != null)
			canvas.addOutput(param.getSemanticType(),this);
		locator = PBoundsLocator.createEastLocator(this);
	}
	
	//for outputs, the correpsonding items are inputs.
 	public ArrayList getCorresponding() {
		SemanticType type = param.getSemanticType();
		if (type == null)
			return null;
		return canvas.getInputs(type);
 	}
}