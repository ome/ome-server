/*
 * ome.xml.r200706.ome.GroupNode
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
 * Created by curtis via xsd-fu on 2007-11-24 06:33:32-0600
 *
 *-----------------------------------------------------------------------------
 */

package ome.xml.r200706.ome;

import ome.xml.DOMUtil;
import ome.xml.OMEXMLNode;

import java.util.Vector;
import java.util.List;

import org.w3c.dom.Element;

public class GroupNode extends OMEXMLNode
{
	// -- Constructors --

	/** Constructs a Group node with an associated DOM element. */
	public GroupNode(Element element)
	{
		super(element);
	}

	/**
	 * Constructs a Group node with an associated DOM element beneath
	 * a given parent.
	 */
	public GroupNode(OMEXMLNode parent)
	{
		this(parent, true);
	}

	/**
	 * Constructs a Group node with an associated DOM element beneath
	 * a given parent.
	 */
	public GroupNode(OMEXMLNode parent, boolean attach)
	{
		super(DOMUtil.createChild(parent.getDOMElement(),
		                          "Group", attach));
	}

	// -- Group API methods --
      
	// Virtual, inferred back reference Dataset_BackReference
	public int getDatasetCount()
	{
		return getReferringCount("Dataset");
	}

	public List getDatasetList()
	{
		return getReferringNodes("Dataset");
	}
                                                                        
	// Element which is complex (has sub-elements)
	public ContactNode getContact()
	{
		return (ContactNode)
			getChildNode("Contact", "Contact");
	}
                                            
	// Element which is complex (has sub-elements)
	public LeaderNode getLeader()
	{
		return (LeaderNode)
			getChildNode("Leader", "Leader");
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
                                                                    
	// *** WARNING *** Unhandled or skipped property ID
      
	// -- OMEXMLNode API methods --

	public boolean hasID()
	{
		return true;
	}
}

