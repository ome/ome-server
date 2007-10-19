/*
 * ome.xml.r2007_06.ome.ExperimenterNode
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

public class ExperimenterNode extends OMEXMLNode
{
	// -- Constructor --
	
	public ExperimenterNode(Element element)
	{
		super(element);
	}
	
	// -- Experimenter API methods --
                      
	// Element which is not complex (has only a text node)
	public String getEmail()
	{
		return getStringCData("Email");
	}
                                        
	// Element which is not complex (has only a text node)
	public String getOMEName()
	{
		return getStringCData("OMEName");
	}
                                        
	// Element which is not complex (has only a text node)
	public String getFirstName()
	{
		return getStringCData("FirstName");
	}
                                        
	// Element which is not complex (has only a text node)
	public String getLastName()
	{
		return getStringCData("LastName");
	}
                                
	// Element which occurs more than once and is an OME XML "Ref"
	public int getGroupCount()
	{
		return getChildCount("GroupRef");
	}

	public Vector getGroupList()
	{
		return getReferencedNodes("Group", "GroupRef");
	}
                                                            
	// *** WARNING *** Unhandled or skipped property ID
                            
	// Element which is not complex (has only a text node)
	public String getInstitution()
	{
		return getStringCData("Institution");
	}
                  
	// -- OMEXMLNode API methods --
	
	public boolean hasID()
	{
		return true;
	}
}
