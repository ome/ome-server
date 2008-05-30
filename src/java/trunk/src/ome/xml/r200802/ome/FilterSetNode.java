/*
 * ome.xml.r200802.ome.FilterSetNode
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
 * Created by curtis via xsd-fu on 2008-05-30 12:57:22-0500
 *
 *-----------------------------------------------------------------------------
 */

package ome.xml.r200802.ome;

import ome.xml.DOMUtil;
import ome.xml.OMEXMLNode;

import java.util.Vector;
import java.util.List;

import org.w3c.dom.Element;

public class FilterSetNode extends FilterSpecNode
{
	// -- Constructors --

	/** Constructs a FilterSet node with an associated DOM element. */
	public FilterSetNode(Element element)
	{
		super(element);
	}

	/**
	 * Constructs a FilterSet node with an associated DOM element beneath
	 * a given parent.
	 */
	public FilterSetNode(OMEXMLNode parent)
	{
		this(parent, true);
	}

	/**
	 * Constructs a FilterSet node with an associated DOM element beneath
	 * a given parent.
	 */
	public FilterSetNode(OMEXMLNode parent, boolean attach)
	{
		super(DOMUtil.createChild(parent.getDOMElement(),
		                          "FilterSet", attach));
	}

	// -- FilterSet API methods --
          
	// Attribute which is an OME XML "ID"
	public FilterNode getExFilterRef()
	{
		return (FilterNode)
			getAttrReferencedNode("Filter", "ExFilterRef");
	}
                                            
	// Attribute which is an OME XML "ID"
	public FilterNode getEmFilterRef()
	{
		return (FilterNode)
			getAttrReferencedNode("Filter", "EmFilterRef");
	}
                                        
	// Virtual, inferred back reference OTF_BackReference
	public int getOTFCount()
	{
		return getReferringCount("OTF");
	}

	public List getOTFList()
	{
		return getReferringNodes("OTF");
	}
                                                
	// Attribute which is an OME XML "ID"
	public DichroicNode getDichroicRef()
	{
		return (DichroicNode)
			getAttrReferencedNode("Dichroic", "DichroicRef");
	}
                                        
	// Virtual, inferred back reference LogicalChannel_BackReference
	public int getLogicalChannelCount()
	{
		return getReferringCount("LogicalChannel");
	}

	public List getLogicalChannelList()
	{
		return getReferringNodes("LogicalChannel");
	}
                                                                            
	// *** WARNING *** Unhandled or skipped property ID
      
	// -- OMEXMLNode API methods --

	public boolean hasID()
	{
		return true;
	}
}

