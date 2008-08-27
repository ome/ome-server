/*
 * ome.xml.r200706.ome.InstrumentNode
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

package ome.xml.r200706.ome;

import ome.xml.DOMUtil;
import ome.xml.OMEXMLNode;

import java.util.Vector;
import java.util.List;

import org.w3c.dom.Element;

public class InstrumentNode extends OMEXMLNode
{
	// -- Constructors --

	/** Constructs a Instrument node with an associated DOM element. */
	public InstrumentNode(Element element)
	{
		super(element);
	}

	/**
	 * Constructs a Instrument node with an associated DOM element beneath
	 * a given parent.
	 */
	public InstrumentNode(OMEXMLNode parent)
	{
		this(parent, true);
	}

	/**
	 * Constructs a Instrument node with an associated DOM element beneath
	 * a given parent.
	 */
	public InstrumentNode(OMEXMLNode parent, boolean attach)
	{
		super(DOMUtil.createChild(parent.getDOMElement(),
		                          "Instrument", attach));
	}

	// -- Instrument API methods --
                      
	// Element which occurs more than once
	public int getLightSourceCount()
	{
		return getChildCount("LightSource");
	}

	public Vector getLightSourceList()
	{
		return getChildNodes("LightSource");
	}
                                            
	// Element which occurs more than once
	public int getDichroicCount()
	{
		return getChildCount("Dichroic");
	}

	public Vector getDichroicList()
	{
		return getChildNodes("Dichroic");
	}
                            
	// Virtual, inferred back reference Image_BackReference
	public int getImageCount()
	{
		return getReferringCount("Image");
	}

	public List getImageList()
	{
		return getReferringNodes("Image");
	}
                                                            
	// Element which occurs more than once
	public int getOTFCount()
	{
		return getChildCount("OTF");
	}

	public Vector getOTFList()
	{
		return getChildNodes("OTF");
	}
                                            
	// Element which occurs more than once
	public int getFilterCount()
	{
		return getChildCount("Filter");
	}

	public Vector getFilterList()
	{
		return getChildNodes("Filter");
	}
                                                        
	// Element which is complex (has sub-elements)
	public MicroscopeNode getMicroscope()
	{
		return (MicroscopeNode)
			getChildNode("Microscope", "Microscope");
	}
                                
	// Element which occurs more than once
	public int getObjectiveCount()
	{
		return getChildCount("Objective");
	}

	public Vector getObjectiveList()
	{
		return getChildNodes("Objective");
	}
                                            
	// Element which occurs more than once
	public int getDetectorCount()
	{
		return getChildCount("Detector");
	}

	public Vector getDetectorList()
	{
		return getChildNodes("Detector");
	}
                                                            
	// *** WARNING *** Unhandled or skipped property ID
                            
	// Element which occurs more than once
	public int getFilterSetCount()
	{
		return getChildCount("FilterSet");
	}

	public Vector getFilterSetList()
	{
		return getChildNodes("FilterSet");
	}
                      
	// -- OMEXMLNode API methods --

	public boolean hasID()
	{
		return true;
	}
}

