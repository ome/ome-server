/*
 * ome.xml.r200802.ome.MicrobeamManipulationNode
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

public class MicrobeamManipulationNode extends OMEXMLNode
{
	// -- Constructors --

	/** Constructs a MicrobeamManipulation node with an associated DOM element. */
	public MicrobeamManipulationNode(Element element)
	{
		super(element);
	}

	/**
	 * Constructs a MicrobeamManipulation node with an associated DOM element beneath
	 * a given parent.
	 */
	public MicrobeamManipulationNode(OMEXMLNode parent)
	{
		this(parent, true);
	}

	/**
	 * Constructs a MicrobeamManipulation node with an associated DOM element beneath
	 * a given parent.
	 */
	public MicrobeamManipulationNode(OMEXMLNode parent, boolean attach)
	{
		super(DOMUtil.createChild(parent.getDOMElement(),
		                          "MicrobeamManipulation", attach));
	}

	// -- MicrobeamManipulation API methods --
                              
	// Element which is complex and is an OME XML "Ref"
	public ExperimenterNode getExperimenter()
	{
		return (ExperimenterNode)
			getReferencedNode("Experimenter", "ExperimenterRef");
	}

	public ExperimenterRefNode getExperimenterRef()
	{
		return (ExperimenterRefNode)
			getChildNode("ExperimenterRef", "ExperimenterRef");
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
                                                
	// Element which occurs more than once and is an OME XML "Ref"
	public int getROICount()
	{
		return getChildCount("ROIRef");
	}

	public Vector getROIList()
	{
		return getReferencedNodes("ROI", "ROIRef");
	}

	public Vector getROIRefList()
	{
		return getChildNodes("ROIRef");
	}
                                
	// Virtual, inferred back reference Experiment_BackReference
	public int getExperimentCount()
	{
		return getReferringCount("Experiment");
	}

	public List getExperimentList()
	{
		return getReferringNodes("Experiment");
	}
                                                        
	// Element which occurs more than once and is an OME XML "Ref"
	public int getLightSourceCount()
	{
		return getChildCount("LightSourceRef");
	}

	public Vector getLightSourceList()
	{
		return getReferencedNodes("LightSource", "LightSourceRef");
	}

	public Vector getLightSourceRefList()
	{
		return getChildNodes("LightSourceRef");
	}
                                                                
	// *** WARNING *** Unhandled or skipped property ID
      
	// -- OMEXMLNode API methods --

	public boolean hasID()
	{
		return true;
	}
}

