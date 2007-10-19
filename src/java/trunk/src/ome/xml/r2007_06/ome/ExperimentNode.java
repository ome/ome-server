/*
 * ome.xml.r2007_06.ome.ExperimentNode
 *
 *-----------------------------------------------------------------------------
 *
 *  Copyright (C) 2007 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee,
 *      University of Wisconsin-Madison
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
 *-----------------------------------------------------------------------------
 */

/*-----------------------------------------------------------------------------
 *
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by callan via xsd-fu on 2007-10-08 14:37:54+0100
 *
 *-----------------------------------------------------------------------------
 */

package ome.xml.r2007_06.ome;

import java.util.Vector;
import ome.xml.OMEXMLNode;
import org.w3c.dom.Element;

public class ExperimentNode extends OMEXMLNode
{
	// -- Constructor --
	
	public ExperimentNode(Element element)
	{
		super(element);
	}
	
	// -- Experiment API methods --
                          
	// Element which is complex and is an OME XML "Ref"
	public ExperimenterNode getExperimenter()
	{
		return (ExperimenterNode) 
			getReferencedNode("Experimenter", "ExperimenterRef");
	}
                            
	// Element which occurs more than once and is an OME XML "Ref"
	public int getMicrobeamManipulationCount()
	{
		return getChildCount("MicrobeamManipulationRef");
	}

	public Vector getMicrobeamManipulationList()
	{
		return getReferencedNodes("MicrobeamManipulation", "MicrobeamManipulationRef");
	}
                                    
	// Attribute
	public String getType()
	{
		return getStringAttribute("Type");
	}

	public void setType(String type)
	{
		setAttribute("Type", type);
	}
                                                                
	// *** WARNING *** Unhandled or skipped property ID
                            
	// Element which is not complex (has only a text node)
	public String getDescription()
	{
		return getStringCData("Description");
	}
                  
	// -- OMEXMLNode API methods --
	
	public boolean hasID()
	{
		return true;
	}
}
