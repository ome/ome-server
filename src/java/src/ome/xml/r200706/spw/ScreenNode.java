/*
 * ome.xml.r200706.spw.ScreenNode
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
 * Created by curtis via xsd-fu on 2008-05-23 11:22:11-0500
 *
 *-----------------------------------------------------------------------------
 */

package ome.xml.r200706.spw;

import ome.xml.DOMUtil;
import ome.xml.OMEXMLNode;
import ome.xml.r200706.ome.*;

import java.util.Vector;
import java.util.List;

import org.w3c.dom.Element;

public class ScreenNode extends OMEXMLNode
{
	// -- Constructors --

	/** Constructs a Screen node with an associated DOM element. */
	public ScreenNode(Element element)
	{
		super(element);
	}

	/**
	 * Constructs a Screen node with an associated DOM element beneath
	 * a given parent.
	 */
	public ScreenNode(OMEXMLNode parent)
	{
		this(parent, true);
	}

	/**
	 * Constructs a Screen node with an associated DOM element beneath
	 * a given parent.
	 */
	public ScreenNode(OMEXMLNode parent, boolean attach)
	{
		super(DOMUtil.createChild(parent.getDOMElement(),
		                          "SPW:Screen", attach));
	}

	// -- Screen API methods --
      
	// Virtual, inferred back reference Plate_BackReference
	public int getPlateCount()
	{
		return getReferringCount("Plate");
	}

	public List getPlateList()
	{
		return getReferringNodes("Plate");
	}
                                                    
	// Attribute
	public String getName()
	{
		return getStringAttribute("Name");
	}

	public void setName(String name)
	{
		setAttribute("Name", name);
	}
                                            
	// Attribute
	public String getProtocolDescription()
	{
		return getStringAttribute("ProtocolDescription");
	}

	public void setProtocolDescription(String protocolDescription)
	{
		setAttribute("ProtocolDescription", protocolDescription);
	}
                                            
	// Attribute
	public String getProtocolIdentifier()
	{
		return getStringAttribute("ProtocolIdentifier");
	}

	public void setProtocolIdentifier(String protocolIdentifier)
	{
		setAttribute("ProtocolIdentifier", protocolIdentifier);
	}
                                                    
	// Element which occurs more than once
	public int getReagentCount()
	{
		return getChildCount("Reagent");
	}

	public Vector getReagentList()
	{
		return getChildNodes("Reagent");
	}
                                        
	// Element which occurs more than once and is an OME XML "Ref"
	public int getPlateRefCount()
	{
		return getChildCount("PlateRef");
	}

	public Vector getPlatePlateRefList()
	{
		return getReferencedNodes("Plate", "PlateRef");
	}

	public Vector getPlateRefList()
	{
		return getChildNodes("PlateRef");
	}
                                        
	// Attribute
	public String getReagentSetDescription()
	{
		return getStringAttribute("ReagentSetDescription");
	}

	public void setReagentSetDescription(String reagentSetDescription)
	{
		setAttribute("ReagentSetDescription", reagentSetDescription);
	}
                                                    
	// Element which occurs more than once
	public int getScreenAcquisitionCount()
	{
		return getChildCount("ScreenAcquisition");
	}

	public Vector getScreenAcquisitionList()
	{
		return getChildNodes("ScreenAcquisition");
	}
                                                
	// Element which is not complex (has only a text node)
	public String getDescription()
	{
		return getStringCData("Description");
	}

	public void setDescription(String description)
	{
		setCData("Description", description);
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
                    
	// Attribute
	public String getReagentSetIdentifier()
	{
		return getStringAttribute("ReagentSetIdentifier");
	}

	public void setReagentSetIdentifier(String reagentSetIdentifier)
	{
		setAttribute("ReagentSetIdentifier", reagentSetIdentifier);
	}
                              
	// -- OMEXMLNode API methods --

	public boolean hasID()
	{
		return true;
	}
}

